module LineLearn
  class Character

    attr_reader :all, :name

    def initialize(all, name)
      @all = all
      @name = name
    end

    def color
      @color ||= all.color_map[name]
    end

    def speak(*line)
      print ' ' * (all.max_name_size - name.size)
      print $terminal.color(name, :underline)
      print ': '
      print $terminal.color(line.flatten.join(' '), color)
      puts
    end

    alias :to_s :name

  end
end
