module LineLearn
  class Script

    attr_reader :file, :lines, :character_set

    def initialize(file=nil)
      @file = file || begin
        txt_files = Dir['*.txt']
        if txt_files.size == 1
          txt_files.first
        else
         choose *txt_files
        end
      end

      @character_set = CharacterSet.new

      @lines = File.read(@file).lines.each_with_index.map do |line, num|
        c, raw = line.split(/\s*:\s*/, 2).map(&:strip)
        Line.new(num, character_set[c], raw)
      end
    end

    def characters
      character_set.names
    end

    def valid_character?(name)
      character_set.valid?(name)
    end

    def introduce
      character_set.values.each do |c|
        c.speak "My name is #{c.name} with color #{c.color.rgb.inspect}"
      end
    end

  end
end
