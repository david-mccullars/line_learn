require 'highline/import'
require 'io/console'
require 'erb'
require 'fileutils'

require 'line_learn/version'

module LineLearn

  autoload :Character, 'line_learn/character.rb'
  autoload :CharacterSet, 'line_learn/character_set.rb'
  autoload :Line, 'line_learn/line.rb'
  autoload :Scores, 'line_learn/scores.rb'
  autoload :Script, 'line_learn/script'
  autoload :ScriptPractice, 'line_learn/script_practice.rb'

end
