module LineLearn
  class CharacterSet < Hash

    def max_name_size
      @max_name_size ||= names.map(&:size).max
    end

    alias :names :keys

    alias :valid? :has_key?

    def [](name)
      super(name) or self[name] = Character.new(self, name)
    end

    def color_map
      @color_map ||= Hash[self.keys.sort.zip(styles[1..-1])]
    end

    private

    def styles
      @styles ||= style_bits.map do |bits|
        rgb = bits.map do |v|
          v = v.join.to_i(2)
          v == 0 ? 0 : (255.0 - 200.0 * v / bit_count_per_color).to_i
        end
        HighLine::Style.rgb(*rgb)
      end
    end

    def style_bits
      @style_bits ||= self.size.times.map do |n|
        bits = sprintf("%0.#{3 * bit_count_per_color}b", n + 1).chars.each_slice(3)
        3.times.map { |i| bits.map { |a| a[i] } }
      end
    end

    def bit_count_per_color
      @bit_count_per_color ||= begin
        v = (Math.log(self.size / 3.0) / Math.log(2)).ceil
        v < 1 ? 1 : v
      end
    end

  end
end
