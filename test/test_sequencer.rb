require 'test/unit'
require 'set'
cosy_root = File.expand_path(File.join(File.dirname(__FILE__), '/../lib/cosy'))
require File.join(cosy_root, 'sequencer/sequencer')


class TestSequencer < Test::Unit::TestCase
  include Cosy
  
  def sequence input
    seq = Sequencer.new(input)
    assert_not_nil(seq.tree, 
      "Failed to parse: #{input}\n" + 
      "(#{seq.parser.failure_line},#{seq.parser.failure_column}): #{seq.parser.failure_reason}")
    return seq
  end
  
  def assert_done seq
      assert_nil(seq.next)
  end
  
  def assert_seq_equals expected_values, seq_str
    seq = sequence seq_str
    expected_values.each do |expected|
      n = seq.next
      assert_not_nil(n)
      assert_equal expected,n
    end
    assert_done seq        
  end
  
  def assert_failure invalid_syntax
    seq = Sequencer.new(invalid_syntax)
    assert_nil(seq.tree, "Successfully parsed invalid syntax: #{invalid_syntax}")
    return nil
  end
  
  def test_single_element
    assert_seq_equals [1], '1'
  end
  
  def test_simple_sequence
    assert_seq_equals [1, 2], '1 2'
  end
  
  def test_single_chord
    assert_seq_equals [[1,2,3]], '[1 2 3]'
  end
  
  def test_numeric_chord_sequence
    assert_seq_equals [[1,2],[3,4],[5,6,7]], '[1 2] [3 4] [5 6 7]'
  end
  
  def test_chord_and_number_sequence
    assert_seq_equals [1, [2,3], 4, [5,6]], '1 [2 3] 4 [5 6]'
  end
  
  def test_repeated_sequence
    assert_seq_equals   [1,1],      '1*2'
    assert_seq_equals   [1,1,1],    '(1)*3'
    assert_seq_equals   [],         '1*0'
    assert_seq_equals   [],         '1*-1'
    assert_seq_equals   [1,2],      '(1 2)*1'
    assert_seq_equals   [1,2,1,2],  '(1 2)*2'
    assert_seq_equals   [],         '(1 2)*0'
    assert_seq_equals   [],         '(1 2)*-1'
  end
  
  def test_heterogenous_repeated_sequence
    assert_seq_equals [0,1,1,1,2,3,2,3], '0 1*3 (2 3)*2'
  end
  
  def test_repeated_sequence_with_eval_repetitions
    assert_seq_equals [1,2,1,2], '(1 2)*{8/4}'
  end
  
  def test_fractional_repetitions
    assert_seq_equals   [1,2,1,2,1],      '(1 2)*2.5'
  end
  
  def test_nested_repetitions
    assert_seq_equals [1,2,3,2,3,1,2,3,2,3], '(1 (2 3)*2)*2'
  end
  
  def test_limited_repeat_sequence
    assert_seq_equals   [1,1,1,1],    '1&4'
    assert_seq_equals   [1,1,1,1],    '(1)&4'
    assert_seq_equals   [],           '1&0'
    assert_seq_equals   [],           '1&-1'
    assert_seq_equals   [1,2,1,2],    '(1 2)&4'
    assert_seq_equals   [1,2,1,2,1],  '(1 2)&5'
    assert_seq_equals   [1,2,3,1],    '(1 2 3)&4'
    assert_seq_equals   [],           '(1 2)&0'
    assert_seq_equals   [],           '(1 2)&-1'    
  end
  
  def test_notes
    assert_seq_equals [60,65,67,68], 'C4 F4 G4 Ab4'      
  end
  
  def test_repeated_notes
    assert_seq_equals [60,65,65,65,67,68,67,68], 'C4 F4*3 (G4 Ab4)*2'      
  end
  
  def test_note_chord
     assert_seq_equals [[60,65,67,68]], '[C4 F4 G4 Ab4]'      
  end
  
  def test_chord_sequence
    assert_seq_equals [[60,65],[67,68]], '[C4 F4] [G4 Ab4]'
  end
  
  def test_repeated_chord
    assert_seq_equals [[60,65],[60,65]], '[C4 F4]*2'      
  end
  
  def test_simple_chain
    assert_seq_equals [[1,2]], '1:2'
    assert_seq_equals [[1,2,3]], '1:2:3'
  end
  
  def test_simple_chain_sequence
    assert_seq_equals [[1,2],[3,4,5]], '1:2 3:4:5'
  end
  
  def test_simple_choice
    seq = sequence '(1 | 2 | 3)'
    expected = [1,2,3]
    actual = Set.new
    100.times do
      seq.restart
      n = seq.next
      actual.add(n)
    end
    # may occasionally fail, since choices are random
    assert_equal(expected.to_set, actual)
    assert_done seq
  end
  
  def test_note_choice
    seq = sequence '(C4 | E4 | G4)'
    expected = [60,64,67]
    actual = Set.new
    100.times do
      seq.restart
      n = seq.next
      actual.add(n)
    end
    # may occasionally fail, since choices are random
    assert_equal(expected.to_set, actual)
    assert_done seq
  end
  
  def test_chord_choice
     seq = sequence '([C4 G4]| [D4 G4] | G4)'
     expected = [[60,67],[62,67],67]
     actual = Set.new
     100.times do
       seq.restart
       n = seq.next
       actual.add(n)
     end
     # may occasionally fail, since choices are random
     assert_equal(expected.to_set, actual)
     assert_done seq
   end
  
  def test_sequence_of_choices
    seq = sequence '(1 | 2 | 3) (C4|E4|G4)'
    expected1 = [1,2,3]
    expected2 = [60,64,67]
    actual = Set.new
    actual1 = Set.new
    actual2 = Set.new
    200.times do |n|
      seq.restart
      n = seq.next
      actual1.add(n)
      actual.add(n)
      n = seq.next
      actual2.add(n)
      actual.add(n)
    end
    # may occasionally fail, since choices are random
    assert_equal(expected1.to_set, actual1)
    assert_equal(expected2.to_set, actual2)
    assert_equal((expected1+expected2).to_set, actual)
    assert_done seq
  end
  
  def test_chain_secondary_list
    assert_seq_equals [[60,120],[60,240],65], 'c4:(s e) f4'
  end
  
  def test_complex_chain_same_length
    assert_seq_equals [[1,3],[2,4]], '(1 2):(3 4)'
  end
  
  def test_complex_chain_same_length_in_sequence
    assert_seq_equals [[1,3],[2,4],5], '(1 2):(3 4) 5'
  end
    
  def test_complex_chain_different_length
    assert_seq_equals [[1,3],[2,4],[1,5]], '(1 2):(3 4 5)'
    assert_seq_equals [[1,3,6],[2,4,7],[1,5,8],[2,3,9]], '(1 2):(3 4 5):(6 7 8 9)'     
  end
  
  def test_complex_chain_with_repetition
    assert_seq_equals [[1,3,6],[2,4,7],[1,5,8],[2,3,6]], '(1 2)*2:(3 4 5):(6 7 8)'     
    assert_seq_equals [[1,3,6],[2,4,7],[1,5,8],[2,3,6]], '(1 2):(3 4 5)&4:(6 7 8)'     
  end
  
  def test_invalid_sequence
    assert_failure '1.'
    assert_failure '1 2)*3'
    assert_failure 'asdf'
  end
  
      
  # complex choices
  # 'c4 ([c4 g4]*2 | [b2 b3 b4]*2)'
  # 'nested' choices
          
  # repeated chord
  
  # complex chains (1 2):(3 4)
  
  # nested chains?  (1:2  3:4):(5  6  7) should produce 1:2:5  3:4:6  1:2:7  

# rhythm, especially dotted and triplet rhythm

# full melodic (note, rhythm, velocity) sequence
  
end