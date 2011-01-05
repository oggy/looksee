require 'spec_helper'

describe Looksee::LookupPath do
  include TemporaryClasses

  def stub_methods(mod, public, protected, private, undefined)
    Looksee.stubs(:internal_public_instance_methods   ).with(mod).returns(public)
    Looksee.stubs(:internal_protected_instance_methods).with(mod).returns(protected)
    Looksee.stubs(:internal_private_instance_methods  ).with(mod).returns(private)
    Looksee.stubs(:internal_undefined_instance_methods).with(mod).returns(undefined)
  end

  describe "#entries" do
    before do
      temporary_module :M
      temporary_class(:C) { include M }
      stub_methods(C, ['public1', 'public2'], ['protected1', 'protected2'], ['private1', 'private2'], ['undefined1', 'undefined2'])
      stub_methods(M, ['public1', 'public2'], ['protected1', 'protected2'], ['private1', 'private2'], ['undefined1', 'undefined2'])
      @object = Object.new
      Looksee.stubs(:lookup_modules).with(@object).returns([C, M])
      @lookup_path = Looksee::LookupPath.new(@object)
    end

    it "should contain an entry for each module in the object's lookup path" do
      @lookup_path.entries.map{|entry| entry.module}.should == [C, M]
    end

    it "should include methods of all visibilities, including overridden ones" do
      @lookup_path.entries[0].methods.should == {
        'public1'    => :public   , 'public2'    => :public,
        'protected1' => :protected, 'protected2' => :protected,
        'private1'   => :private  , 'private2'   => :private,
        'undefined1' => :undefined, 'undefined2' => :undefined,
      }
      @lookup_path.entries[1].methods.should == {
        'public1'    => :public   , 'public2'    => :public,
        'protected1' => :protected, 'protected2' => :protected,
        'private1'   => :private  , 'private2'   => :private,
        'undefined1' => :undefined, 'undefined2' => :undefined,
      }
    end

    it "should know which methods have been overridden" do
      @lookup_path.entries[0].overridden?('public1').should be_false
      @lookup_path.entries[1].overridden?('public1').should be_true
    end
  end

  describe Looksee::LookupPath::Entry do
    it "should iterate over methods in alphabetical order" do
      temporary_class(:C)
      stub_methods(C, ['a', 'c', 'b'], [], [], [])
      @object = Object.new
      Looksee.stubs(:lookup_modules).with(@object).returns([C])
      @lookup_path = Looksee::LookupPath.new(@object)
      @lookup_path.entries.size.should == 1
      @lookup_path.entries.first.map{|name, visibility| name}.should == ['a', 'b', 'c']
    end
  end
end
