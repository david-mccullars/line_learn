module LineLearn
  module Scores

    autoload :Stopwatch, 'line_learn/scores/stopwatch'

    attr_accessor :word_times

    def avg
      @avg ||= if word_times.empty?
                 0.0
               else
                 word_times.inject(0.0) { |sum, s| sum + s } / word_times.size
               end
    end

    def self.add_to(obj)
      obj.send :extend, self
      yield(stopwatch = Stopwatch.new)
      obj.word_times = stopwatch.times
      nil
    end

  end
end
