require File.dirname(__FILE__)+'/spec_helper'

describe Cosy::Timeline do

  before(:each) do
    @timeline = Timeline.new
  end
  
  it 'should store arbitrary objects as an array under numeric keys' do
    @timeline[1] = :event
    @timeline[1].should == [:event]
    @timeline[1] = 'event 2'
    @timeline[1].should == ['event 2']
  end
  
  it 'should clear the events at a time index when assigned nil' do
    @timeline[1] = :event
    @timeline[1].should == [:event]
    @timeline[1] = nil
    @timeline[1].should == []
  end
  
  it 'should support the << operator' do
    @timeline[1] << :event
    @timeline[1].should == [:event]
    @timeline[1] << 'event 2'
    @timeline[1].should == [:event, 'event 2']
  end
  
  it 'should not accept non-numeric keys' do
    lambda { @timeline['a'] = 1 }.should raise_error
    lambda { @timeline[:a] = 1 }.should raise_error
    lambda { @timeline[Hash.new] = 1 }.should raise_error
  end
  
  it 'should keep time keys sorted' do
    @timeline[4] << :four
    @timeline[2] << :two
    @timeline[3] << :three
    @timeline[1] << :one
    @timeline.times.should == [1,2,3,4]
  end
  
  it 'should allow enumeration in sorted order' do
    @timeline[4] << :four
    @timeline[2] << :two
    @timeline[3] << :three
    @timeline[0] << :zero
    @timeline[1] << :one
    expected = [:zero, :one, :two, :three, :four]
    i = 0
    @timeline.each do |time,event|
      time.should == i
      event.should == [expected[i]]
      i += 1
    end
  end
  
  it 'should support find_all' do
    @timeline[0] << "a"
    @timeline[0] << "b"
    @timeline[1] << 0
    @timeline[100] << "c"
    @timeline[50] << :sym
    @timeline.find_all{|event| event.is_a? String }.should == ["a", "b", "c"]
  end
  
  it 'should have a string representation' do
    @timeline[0] << :zero
    @timeline[3] << :three
    @timeline[1] << :one
    @timeline[1] << :oneB
    
    (@timeline.to_s + "\n").should == 
<<TIMELINE_STRING
0 => [:zero]
1 => [:one, :oneB]
3 => [:three]
TIMELINE_STRING
  end
  
end
