require 'rspec/matchers/built_in/change'

RSpec::Matchers::BuiltIn::ChangeToValue.prepend(Module.new do
  def expected
    @expected_after
  end

  def actual
    @change_details.actual_after
  end

  def diffable?
    true
  end
end)

RSpec.describe ContextfulRewriter do
  around do |ex|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        ex.run
      end
    end
  end

  describe ".rewrite" do
    def run_ruby(path)
      # TODO: use exception: true option when 2.5 is EOL
      # system("ruby -W0 -r bundler/setup -r pry-byebug -I #{File.join(__dir__, '..', 'lib')} #{path}", exception: true)
      system("ruby -W0 -r bundler/setup -r pry-byebug -I #{File.join(__dir__, '..', 'lib')} #{path}") || raise
    end

    before do
      File.write('setup.rb', setup_code)
      File.write('main.rb', main_code)

      File.write('test.rb', <<~RUBY)
        require 'contextful_rewriter'
        db = ContextfulRewriter.record_runtime_info do
          require_relative 'setup'
          require_relative 'main'
        end

        db.export('db.yml')
      RUBY

      run_ruby("test.rb")
    end

    describe "replacing Bar#foo with Bar#bar" do
      let(:setup_code) {
        <<~RUBY
          class Foo
            def foo
            end
          end

          class Bar
            def foo
            end
          end
        RUBY
      }

      let(:main_code) {
        <<~RUBY
          Foo.new.foo
          Bar.new.foo
        RUBY
      }

      subject do
        -> do
          ContextfulRewriter.rewrite(runtime_info_db_path: 'db.yml') do |node, data, rewriter|
            receiver, method_name, *args = node.children

            if data[:caller_class_name] == "Bar" && method_name == :foo
              rewriter.replace(node.loc.expression, "#{receiver.loc.expression.source}.bar")
            end
          end
        end
      end

      it {
        is_expected.to change { File.read('main.rb') }.to(<<~RUBY)
          Foo.new.foo
          Bar.new.bar
        RUBY
      }
    end

    describe "replacing {:foo.foo => 1} with {:foo => {$:foo => 1}}" do
      let(:setup_code) {
        <<~RUBY
          require 'json/add/symbol'
          class Symbol
            def foo(*)
            end
          end

          class Foo
            def foo
            end
          end
        RUBY
      }

      let(:main_code) {
        <<~RUBY
          {Foo.new.foo => 1}
          {:foo.foo => 1}
          {
            :foo.foo => 1
          }
          {:foo.foo(1) => 1}
          {:foo.as_json => 1}
        RUBY
      }

      subject do
        -> do
          ContextfulRewriter.rewrite(runtime_info_db_path: 'db.yml') do |node, data, rewriter|
            receiver, method_name, *args = node.children

            if data[:caller_class_name] == "Symbol" && method_name == :foo && args.size == 0
              parent_node = rewriter.parent
              if parent_node.type == :pair
                key, value = parent_node.children
                rewriter.replace(parent_node.loc.expression, "#{receiver.loc.expression.source} => {:$#{method_name} => #{value.loc.expression.source}}")
              else
                raise
              end
            end
          end
        end
      end

      it {
        is_expected.to change { File.read('main.rb') }.to(<<~RUBY)
          {Foo.new.foo => 1}
          {:foo => {:$foo => 1}}
          {
            :foo => {:$foo => 1}
          }
          {:foo.foo(1) => 1}
          {:foo.as_json => 1}
        RUBY
      }
    end
  end
end
