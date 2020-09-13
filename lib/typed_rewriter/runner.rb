require "typed_rewriter/file_manager"
require "typed_rewriter/rewriter"

module TypedRewriter
  class Runner
    def initialize(db)
      @db = db
      @file_manager = FileManager.new
    end

    def run(&block)
      @db.each do |data|
        target_file_path = data[:caller_absolute_path]

        new_code = Rewriter.rewrite(
          path: target_file_path, code: @file_manager.read(target_file_path), target_line: data[:caller_lineno]
        ) {|node, rewriter|
          block.call(node, data, rewriter)
        }

        @file_manager.enque_change(target_file_path, new_code)
      end

      @file_manager.save
    end
  end
end
