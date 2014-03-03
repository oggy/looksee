require 'spec_helper'

describe Looksee::Columnizer do
  describe ".columnize" do
    def columnize(strings, width)
      Looksee::Columnizer.columnize(strings, width)
    end

    it "should an empty string if there are no strings to display" do
      columnize([], 5).should == ''
    end

    it "should render all strings on one line separated and indented by two spaces if they fit" do
      columnize(['one', 'two'], 10).should == "  one  two\n"
    end

    it "should not wrap a string if it longer than the width" do
      columnize(['looooooong'], 5).should == "  looooooong\n"
    end

    it "should render a string on the next line if there's not enough room" do
      columnize(['a', 'looooooong'], 5).should == "  a         \n  looooooong\n"
    end

    it "should present 12 3-char strings 4 per line, sorted vertically, when the width is 20" do
      strings = ['aaa', 'bbb', 'ccc', 'ddd', 'eee', 'fff',
        'ggg', 'hhh', 'iii', 'jjj', 'kkk', 'lll']
      columnize(strings, 20).should == <<-EOS.gsub(/^ *\|/, '')
        |  aaa  ddd  ggg  jjj
        |  bbb  eee  hhh  kkk
        |  ccc  fff  iii  lll
      EOS
    end

    it "should leave the last column short if there aren't enough strings to fill it" do
      strings = ['aaa', 'bbb', 'ccc', 'ddd', 'eee', 'fff',
        'ggg', 'hhh', 'iii', 'jjj', 'kkk']
      columnize(strings, 20).should == <<-EOS.gsub(/^ *\|/, '')
        |  aaa  ddd  ggg  jjj
        |  bbb  eee  hhh  kkk
        |  ccc  fff  iii
      EOS
    end

    it "should pad out strings that are shorter than their column" do
      columnize(['aa', 'b', 'c', 'dd'], 8).should == <<-EOS.gsub(/^ *\|/, '')
        |  aa  c 
        |  b   dd
      EOS
    end
  end
end
