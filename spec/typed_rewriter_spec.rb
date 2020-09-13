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

RSpec.describe TypedRewriter do
  around do |ex|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        ex.run
      end
    end
  end

  describe ".rewrite" do
    def run_ruby(path)
      system("ruby -r bundler/setup -r pry-byebug -I #{File.join(__dir__, '..', 'lib')} #{path}", exception: true)
    end

    describe "replacing {:foo.foo => 1} with {:foo => {$:foo => 1}}" do
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

      before do
        File.write('setup.rb', <<~RUBY)
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

        File.write('main.rb', main_code)

        File.write('foo_test.rb', <<~RUBY)
          require 'typed_rewriter'
          TypedRewriter.record_runtime_type_info do
            require_relative 'setup'
            require_relative 'main'
          end

          TypedRewriter.write_runtime_type_info_db('db.yml')
        RUBY

        run_ruby("foo_test.rb")

        TypedRewriter.load_runtime_type_info_db('db.yml')
      end

      subject do
        -> do
          TypedRewriter.rewrite do |node, data, rewriter|
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
