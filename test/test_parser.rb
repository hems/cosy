require 'test/unit'
$:.unshift File.dirname(__FILE__)+'/../lib'
require 'cosy'

# These tests check that the grammar and parser accept 
# the input that they was designed to accept.

class TestParser < Test::Unit::TestCase
  include Cosy  
  PARSER = SequenceParser.new

  def parse input
    output = PARSER.parse(input)
    assert_not_nil(output, 
      "Failed to parse: #{input}\n" + 
      "(#{PARSER.failure_line},#{PARSER.failure_column}): #{PARSER.failure_reason}")
    return output
  end
  
  def assert_failure invalid_syntax
    assert_raises(RuntimeError) { PARSER.parse(invalid_syntax) }
  end


  
  def test_sequence
    seq = parse '0 1 2 3'
    assert_equal(SequenceNode, seq.class)
    assert_equal(4, seq.children.length)
    seq.children.each_with_index do |item,index|
      assert_equal(index, item.value)
    end
  end

  def test_chain
    seq = parse '0:1:2:3'
    assert_equal(ChainNode, seq.class)
    assert_equal(4, seq.children.length)    
    seq.children.each_with_index do |item,index|
      assert_equal(index, item.value)
    end
  end
  
  def test_parenthesized_sequence
    parse '(1 2 3)'
    parse '(1 2 3) '
    parse ' (1 2 3)'
    parse '(1 2 3 ) '
    parse '( 1 2 3)'
    parse ' ( 1   2  3 )    '
  end

  def test_parenthesized_sequence_then_unparen
    parse '(1 2) 3'
    parse ' ( 1  2 )   3 '
  end
  
  def test_non_parenthesized_sequence_then_paren
    parse '1 (2 3)'
    parse ' 1   ( 2  3 )  '
  end
      
  def test_seqeunce_of_parenthesized_sequences
    parse '(1 2 3) (4 5 6)'
    parse '  ( 1 2  3 )   ( 4  5  6 ) '
  end
  
 
  
  def test_repeated_sequence
    parse '1*2'
    parse '(1)*2'
    parse '(1 2)*2'
    parse '(1 2)*0'
    parse '(1 2)*-1'
  end
  
  def test_repeated_sequence_with_eval_repetitions
    parse '(1 2)*{8/4}'
    end

  def test_limited_repeat_sequence
    parse '1&4'
    parse '(1)&4'
    parse '(1 2)&4'
    parse '(1 2 3)&4'
  end
  
  def test_fractional_repeated_sequence
    parse '1*2.2'
    parse '(1)*2.20'
    parse '(1 2)*2.210'  
  end
  
  def test_sequence_of_repeated_sequences
    parse '(1 2)*2 (3 4)*2.5 (6 7 8)*20'
  end
  
  def test_sequence_of_parenthesized_and_repeated_sequences
    parse '(1 2)*2 (3 4) (6 7 8)*20'  
  end
  
  def test_chord_sequence
    parse '[1] [2] [3]'
    parse '[1 2 3] [4 5 6] [7 8 9]'
  end
  
  def test_repeated_chord
    parse '[1]*2'
    parse '[1 2]*2'
  end
  
  def test_repeated_chord_sequence
    parse '[1]*2 [3]'
    parse '[1 2]*2 [3] [4 5 6]*3.2'
  end

  def test_heterogonous_sequence
    parse '(c4 5)*1.5'
    parse '[3 4]*3'
    parse '(c4 5)*1.5 [3 4]*3'
    parse '[fb3 c#+4]*3 (4.0*5 6*3)*2'
    parse '[fb3 c#+4]*3 ((4.0 5*5)*5 6*3)*2'
    parse '[2 c4] 3 (4.0 (6)*3)*2'
    parse '[2 c#+4] 3 (4.0 6*3)*2'
  end
  


  def test_negative_duration_multiplier
    DURATION.keys.each_with_index do |dur,index|
      parse "-#{index}#{dur}"
      parse "-#{index}#{dur.upcase}" if dur.length == 1
    end
  end
  
  def test_negative_duration
    DURATION.keys.each_with_index do |dur,index|
      parse '-' + dur
      parse '-' + dur.upcase if dur.length == 1
    end  
  end

  def test_multiplier_triplet_dotted_durations
    %w{ .t  t. ..t .t. t.. tt. t.t .tt ..t.tt...t.t }.each_with_index do |mod,index|
      DURATION.keys.each do |dur|
        parse index.to_s + dur + 't' + mod
        parse index.to_s + dur.upcase + 't' + mod if dur.upcase == 1
      end
    end    
  end

 
  
  def test_interval
    INTERVAL_QUALITY.keys.each do |quality|
      for degree in 1..15 do
        parse "#{quality}#{degree}"
      end
    end
  end

  def test_element_chain
    parse '4:5:C4'
    parse 'C4:mf:q.'
    parse '[C4 E4]:fff'
    parse '(4 5):(6 7)'
  end
  
  def test_element_choice
    parse '4|5 | C4'
    parse 'C4|mf|q.'
    parse '[C4 E4]|fff'
    parse '(4 5)|(6 7)'
  end
  
  def test_foreach
    parse '(1 2)@(3 4)'
    parse '(1 $ 2)@(3 4)'
  end
  
  def test_multi_foreach
    parse '(1 2)@(3 4)@(5 6)'
  end
  
  def test_nested_foreach
    parse '((1 2)@(3 4))@(5 6)'
    parse '((1 $ 2 $$)@(3 4 $))@(5 6)'
  end

  def test_assign_variable
    parse '$X=1 2 3 4; $X'
    parse '$X=1 2 3 4; $Y=5; $X $Y'   
  end
  
  def test_label
    parse '#label:5'
    parse '#1:c:mf'
    parse '#env:[1 250 1 500 0 250]'
  end
  
  def test_parallel
    parse 'a == b'
  end

  def test_invalid_syntax
    assert_failure '1.'
    assert_failure '1 2)*3'
    assert_failure 'asdf'
  end   
end