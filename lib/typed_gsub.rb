require "typed_gsub/version"
require "typed_gsub/gsub_runner"
require "yaml"
require "set"

module TypedGsub
  class Error < StandardError; end

  class << self
    DEFAULT_PATH_RULE = -> (path) {
      return false if path.start_with?("/usr/local/lib/ruby/") # How do I check initial $LOAD_PATH stuff?
      return false if defined?(Bundler) && path.start_with?(Bundler.bundle_path.to_s + "/")

      true
    }

    def record_runtime_type_info(path_rule = DEFAULT_PATH_RULE, &block)
      trace = TracePoint.new(:call) do |tp|
        c = caller_locations(2, 1).first
        method_source_absolute_path, method_source_lineno = tp.binding.source_location

        if DEFAULT_PATH_RULE.call(c.absolute_path)
          mutex.synchronize do
            db << {
              method_defined_class_name: tp.defined_class.to_s,
              method_name: tp.callee_id,
              method_source_absolute_path: method_source_absolute_path,
              method_source_lineno: method_source_lineno,
              caller_class_name: tp.self.class.name,
              caller_absolute_path: c.absolute_path,
              caller_lineno: c.lineno,
            }
          end
        end
      end

      trace.enable(&block)
    end

    def write_runtime_type_info_db(db_file_path)
      File.write(db_file_path, db.to_yaml)
    end

    def load_runtime_type_info_db(db_file_path)
      mutex.synchronize do
        @db = YAML.load_file(db_file_path)
      end
    end

    def gsub(&block)
      GsubRunner.new(db).run(&block)
    end

    private

    def mutex
      @mutex ||= Mutex.new
    end

    def db
      @db ||= Set.new
    end
  end
end
