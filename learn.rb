require 'highline/import'
require 'io/console'
require 'erb'
require 'fileutils'

#############################################################################################

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
    @color_map ||= begin
      color_map = {}
      bit_count_per_color = (Math.log(self.size / 3.0) / Math.log(2)).ceil
      bit_count_per_color = 1 if bit_count_per_color < 1
      self.keys.sort.each_with_index do |name, n|
        bits = sprintf("%0.#{3 * bit_count_per_color}b", n + 1).chars.each_slice(3)
        bits = 3.times.map { |i| bits.map { |a| a[i] } }
        rgb = bits.map do |v|
          v = v.join.to_i(2)
          v == 0 ? 0 : (255.0 - 200.0 * v / bit_count_per_color).to_i
        end
        color_map[name] = HighLine::Style.rgb(*rgb)
      end
      color_map
    end
  end

end

#############################################################################################

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

#############################################################################################

module Scores

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

#############################################################################################

class Line

  attr_reader :num, :character, :raw, :sentences

  def initialize(num, character, raw)
    @num = num
    @character = character
    @raw = raw
    @sentences = raw.split(/(?<=[.?!])\s+/).map do |sentence|
      sentence.gsub(/\s*\.\.\.\s*/, ' ... ').split(/\s+/)
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

#############################################################################################

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

#############################################################################################

class ScriptPractice

  BUCKET_SCALE = 10.0
  DELTA_SCALE = 3.7

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

  def normalize_and_adjust_scores(method)
    # PHASE 0:  sort score values
    values = lines_with_scores.map(&(method)).flatten.sort

    # PHASE 1:  bundle values into "buckets"
    buckets = values.map { |s| bucketize(s) }.uniq.sort

    # PHASE 2:  map differences in a relative manner
    differences = (buckets.size - 1).times.map { |i| buckets[i + 1] - buckets[i] }
    difference_map = Hash[differences.uniq.sort.each_with_index.to_a]

    # PHASE 3:  map values by difference map in a relative manner
    values_map = {}
    current, current_bucket, new_time = nil
    values.each do |t|
      prev, current = current, t
      prev_bucket, current_bucket = current_bucket, bucketize(t)
      new_time = if prev.nil?
                   0.0
                 elsif delta = difference_map[(current_bucket - prev_bucket).abs]
                   new_time + unbucketize(delta * DELTA_SCALE + 1)
                 else
                   new_time + current - prev
                 end
      values_map[current] = new_time
    end

    # PHASE 4:  normalize time map
    values_map.keys.each do |k|
      values_map[k] = 2.0 * values_map[k] / new_time
    end

    # PHASE 5:  create normalized/adjusted scores using new values map
    lines_with_scores.inject({}) do |map, line|
      new_values_for_line =
      case to_adjust = line.send(method)
      when Array
        to_adjust.map { |t| values_map[t] }
      when Float
        values_map[to_adjust]
      end
      map.merge! line => new_values_for_line
    end
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
    #@normalized_word_scores ||= normalize_and_adjust_scores(:word_times)
    @normalized_word_scores ||= normalize_scores(:word_times, WORD_RANGE)
  end

  def normalized_line_scores
    #@normalized_line_scores ||= normalize_and_adjust_scores(:avg)
    @normalized_line_scores ||= normalize_scores(:avg, LINE_RANGE)
  end

  def report
    FileUtils.mkdir_p 'reports'
    File.open("reports/#{File.basename script.file, '.txt'}.html", 'w') do |io|
      io.write ERB.new(DATA.read).result(binding).strip
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

#############################################################################################

if $0 == __FILE__
  practice = ScriptPractice.new(Dir[*ARGV].first)
  if ARGV.last == '--dummy'
    practice.learn(ARGV, :dummy_data => true)
  else
    practice.learn(ARGV, :skip_to => ARGV.last)
  end
  practice.report
end

__END__

<html>
<head>
<style>
td { font-size: 6pt; }
td.line_num { font-size: 10pt; }
tr.other_line { color: #DDDDDD; }
</style>
</head>
<body>
  <h1>Practice Report for <%= script.file %></h1>
  <h4><%= Time.now %></h4>
  <h2>TOTAL SCORE: <%= total_score.round(2) %></h2>
  <table>
    <% script.lines.each do |line| %>
      <% scored_line = (Scores === line) %>
      <tr
          class="<%= scored_line ? 'my' : 'other' %>_line"
          <% if scored_line %>
          style="background-color: <%= score_color_hex(normalized_line_scores[line]) %>"
          <% end %>
        >
        <td class="line_num"><%= line.num %></td>
        <td class="character"><%= line.character %></td>
        <% if scored_line %>
        <td class="line">
          <% line.words.zip(normalized_word_scores[line]).each do |word, s| %>
            <span style="font-size: <%= (6 + s * 12).round %>pt"><%= word %></span>
          <% end %>
        </td>
        <td class="score"><%= normalized_line_scores[line].round(2) %></td>
        <% else %>
        <td class="line" colspan="2"><%= line.raw %></td>
        <% end %>
      </tr>
    <% end %>
  </table>
</body>
</html>
