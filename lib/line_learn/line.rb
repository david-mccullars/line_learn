module LineLearn
  class Line

    attr_reader :num, :character, :raw, :sentences

    def initialize(num, character, raw)
      @num = num
      @character = character
      @raw = raw
      @sentences = raw.split(/(?<=[.?!])\s+/).map do |sentence|
        sentence.gsub(/\s*\.\.\.\s*/, ' ... ').split(/\s+|-+/)
      end
    end

    def words
      @words ||= sentences.flatten
    end

    def speak
      character.speak(raw)
    end

    def to_s
      num.to_s
    end

  end
end
