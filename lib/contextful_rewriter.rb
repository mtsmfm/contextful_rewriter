require "contextful_rewriter/version"
require "contextful_rewriter/runner"
require "contextful_rewriter/runtime_info_db"

module ContextfulRewriter
  class Error < StandardError; end

  class << self
    DEFAULT_PATH_RULE = -> (path) {
      return false if path.start_with?("/usr/local/lib/ruby/") # How do I check initial $LOAD_PATH stuff?
      return false if defined?(Bundler) && path.start_with?(Bundler.bundle_path.to_s + "/")

      true
    }

    def record_runtime_info(path_rule = DEFAULT_PATH_RULE, &block)
      RuntimeInfoDb.new.tap do |db|
        trace = TracePoint.new(:call) do |tp|
          c = caller_locations(2, 1).first
          method_source_absolute_path, method_source_lineno = tp.binding.source_location

          if path_rule.call(c.absolute_path)
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

        trace.enable(&block)
      end
    end

    def rewrite(runtime_info_db_path:, &block)
      Runner.new(RuntimeInfoDb.new(runtime_info_db_path)).run(&block)
    end
  end
end
