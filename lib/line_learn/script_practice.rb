module LineLearn
  class ScriptPractice

    BUCKET_SCALE = 10.0
    DELTA_SCALE = 3.7

    REPORT_ERB = File.expand_path('../../report.erb', __FILE__)

    attr_reader :script

    def initialize(script_file=nil)
      @script = Script.new(script_file)
    end

    def lines
      script.lines
    end

    def lines_with_scores
      lines.select { |line| line.is_a? Scores }
    end

    def learn(characters, options={})
      characters = characters.select { |c| script.valid_character? c }.uniq.sort
      characters = [choose(*script.characters)] if characters.empty?

      lines.each do |line|
        if characters.include?(line.character.name) && line.num >= options[:skip_to].to_i
          Scores.add_to(line) do |stopwatch|
            line.sentences.each do |sentence|
              unless options[:dummy_data]
                capture(sentence, stopwatch)
              else
                sentence.each { stopwatch.dummy_click }
              end
            end
          end
        end
        line.speak
      end
      nil
    end

    def capture(words, stopwatch)
      print $terminal.color('>>> ', :bold)
      words = words.dup
      until words.empty?
        case attempt = read_word(words.first)
        when :help
          stopwatch.add(:LARGE_PENALTY)
          stopwatch.click
          print $terminal.color(words.shift, :on_blue)
        when :success
          stopwatch.click
          print $terminal.color(words.shift, :bold)
        else
          stopwatch.add(:SMALL_PENALTY)
          print $terminal.color(attempt, :on_red)
        end
        print ' '
      end
      puts
    end

    def read_word(expecting)
      expecting = expecting.gsub(/[^a-zA-Z0-9]/, '').downcase
      word = ''
      while !word.gsub(/[^a-zA-Z0-9]/, '').downcase.end_with?(expecting)
        case c = STDIN.getch
        when "\u0003"
          exit
        when "\x7F"
          word = word.chop
        when "\b", "\t"
          return :help
        when /\s/
          return word if word =~ /\S/
        else
          word << c
        end
      end
      return :success
    end

    def total_score
      lines_with_scores.map(&:word_times).flatten.inject(0.0) { |sum, t| sum + t }
    end

    def bucketize(v)
      (v * BUCKET_SCALE).round
    end

    def unbucketize(b)
      b / BUCKET_SCALE
    end

    WORD_RANGE = (1.0..10.0)
    LINE_RANGE = (0.5..5.0)

    def normalize_in_range(i, range)
      i = 
      if i <= range.begin
        range.begin
      elsif i >= range.end
        range.end
      else
        i
      end
      2.0 * (i - range.begin) / (range.end - range.begin)
    end

    def normalize_scores(method, range)
      lines_with_scores.inject({}) do |map, line|
        new_values_for_line =
        case to_adjust = line.send(method)
        when Array
          to_adjust.map { |t| normalize_in_range(t, range) }
        when Float
          normalize_in_range(to_adjust, range)
        end
        map.merge! line => new_values_for_line
      end
    end

    def normalized_word_scores
      @normalized_word_scores ||= normalize_scores(:word_times, WORD_RANGE)
    end

    def normalized_line_scores
      @normalized_line_scores ||= normalize_scores(:avg, LINE_RANGE)
    end

    def report
      FileUtils.mkdir_p 'reports'
      File.open("reports/#{File.basename script.file, '.txt'}.html", 'w') do |io|
        io.write ERB.new(File.read(REPORT_ERB)).result(binding).strip
      end
      puts "TOTAL: #{total_score.round(2)}"
      nil
    end

    def score_color_rgb(normalized_score)
      if normalized_score <= 1.0
        [(255.0 * normalized_score).round, 255, 0]
      else
        [255, (255.0 * (2.0 - normalized_score)).round, 0]
      end
    end

    def score_color_hex(normalized_score)
      score_color_rgb(normalized_score).map { |i| "%02x" % i }.join
    end

  end
end
