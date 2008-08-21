require 'sequencing_grammar_parser'

# TODO: turn into some real unit tests

PARSER = SequencingGrammarParser.new

def parse input
  puts "PARSING: #{input}"
  output = PARSER.parse input
  if output
    puts 'success'
  else
    puts 'failure'
  end
  puts output
  puts
  return output
end

parse '[2 c4] 3 (4.0 (6)*3)*2'
parse '[2 c#+4] 3 (4.0 6*3)*2'
parse '[fb3 c#+4]*3 (4.0*5 6*3)*2'
output = parse '[fb3 c#+4]*3 ((4.0 5*5)*5 6*3)*2'
output.start
puts "VALS="
while output.next? do
  puts output.next.inspect
end

parse ''
parse ' '
output = parse '(c4 5)*1.5 [3 4]*3'


output.start
puts "VALS="
while output.next? do
  puts output.next.inspect
end
