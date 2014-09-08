module LineLearn
  module Scores
    class Stopwatch

      SMALL_PENALTY = 1.0
      LARGE_PENALTY = 6.0

      attr_reader :times

      def initialize
        @times = []
        @start = Time.now.to_f
        @penalties = 0.0
      end

      def click
        @start, old = Time.now.to_f, @start
        @times << @start - old + @penalties
        @penalties = 0.0
      end

      def add(penalty)
        @penalties += penalty.is_a?(Symbol) ? Stopwatch.const_get(penalty) : penalty
      end

      def dummy_click
        @times << 9.7 * rand * rand
                + (rand(7) == 0 ? Stopwatch::SMALL_PENALTY : 0)
                + (rand(17) == 0 ? Stopwatch::LARGE_PENALTY : 0)
        @start = Time.now.to_f
        @penalties = 0.0
      end

    end
  end
end
