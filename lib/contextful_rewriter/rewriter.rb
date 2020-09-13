require "parser/current"

module ContextfulRewriter
  class Rewriter < Parser::TreeRewriter
    def self.rewrite(path:, code:, target_line:, &block)
      ast = Parser::CurrentRuby.parse(code)
      buffer = Parser::Source::Buffer.new(path, source: code)
      Rewriter.new(target_line, &block).rewrite(buffer, ast)
    end

    def initialize(target_line, &block)
      @target_line = target_line
      @block = block
      @nesting = []
    end

    def on_send(node)
      if node.loc.line == @target_line
        @block.call(node, self)
      end

      super
    end

    def process(node)
      @nesting.push(node)
      super
      @nesting.pop
    end

    def nesting
      @nesting
    end

    def parent
      nesting[-2]
    end
  end
end
