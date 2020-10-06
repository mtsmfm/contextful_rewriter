require "contextful_rewriter/runtime_info_db"
require "contextful_rewriter/runner"

module ContextfulRewriter
  class Recorder
    # How do I check initial $LOAD_PATH stuff?
    RUBY_LIB_PATH = "/usr/local/lib/ruby/"
    BUNDLE_PATH = defined?(Bundler) ? Bundler.bundle_path.to_s + "/" : nil

    DEFAULT_PATH_RULE = -> (path) {
      return false unless path
      return false if path.start_with?(RUBY_LIB_PATH)
      return false if BUNDLE_PATH && path.start_with?(BUNDLE_PATH)

      true
    }

    def initialize(path_rule)
      @db = RuntimeInfoDb.new
      @path_rule = path_rule || DEFAULT_PATH_RULE
      @trace = TracePoint.new(:call) do |tp|
        c = caller_locations(2, 1).first
        method_source_absolute_path, method_source_lineno = tp.binding.source_location

        if @path_rule.call(c.absolute_path)
          @db << {
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

    def record(&block)
      start
      block.call
      stop
    end

    def start
      @trace.enable
    end

    def stop
      @trace.disable
    end

    def export(path)
      @db.export(path)
    end
  end
end
