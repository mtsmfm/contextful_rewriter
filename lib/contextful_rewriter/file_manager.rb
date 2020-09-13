module ContextfulRewriter
  class FileManager
    def read(path)
      map[path]
    end

    def enque_change(path, code)
      unless code == map[path]
        map[path] = code
        changed_file_paths << path
      end
    end

    def save
      changed_file_paths.each do |path|
        File.write(path, map[path])
      end
    end

    private

    def map
      @map ||= Hash.new do |hash, key|
        hash[key] = File.read(key)
      end
    end

    def changed_file_paths
      @changed_file_paths ||= Set.new
    end
  end
end
