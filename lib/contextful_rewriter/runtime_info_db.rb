require "yaml"
require "set"

module ContextfulRewriter
  class RuntimeInfoDb
    def initialize(path = nil)
      @data =
        if path
          YAML.load_file(path)
        else
          Set.new
        end
    end

    def each(&block)
      @data.each(&block)
    end

    def export(path)
      File.write(path, @data.to_yaml)
    end

    def <<(new_data)
      mutex.synchronize do
        @data << new_data
      end
    end

    private

    def mutex
      @mutex ||= Mutex.new
    end
  end
end
