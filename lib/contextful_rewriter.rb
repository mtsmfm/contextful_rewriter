require "contextful_rewriter/version"
require "contextful_rewriter/recorder"
require "contextful_rewriter/runner"
require "contextful_rewriter/runtime_info_db"

module ContextfulRewriter
  class Error < StandardError; end

  class << self
    def create_recorder(path_rule = nil)
      Recorder.new(path_rule)
    end

    def rewrite(runtime_info_db_path:, &block)
      Runner.new(RuntimeInfoDb.new(runtime_info_db_path)).run(&block)
    end
  end
end
