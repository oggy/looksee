require 'spec_helper'

describe Looksee::LookupPath do
  include TemporaryClasses

  describe "#entries" do
    use_test_adapter

    before do
      temporary_module :M
      temporary_class(:C) { include M }
      @object = Object.new
      Looksee.adapter.ancestors[@object] = [C, M]
      Looksee.adapter.set_methods(M, [:public1, :public2], [:protected1, :protected2], [:private1, :private2], [:undefined1, :undefined2])
      Looksee.adapter.set_methods(C, [:public1, :public2], [:protected1, :protected2], [:private1, :private2], [:undefined1, :undefined2])
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
      @lookup_path.entries[0].overridden?('public1').should == false
      @lookup_path.entries[1].overridden?('public1').should == true
    end
  end

  describe "#find" do
    before do
      temporary_module(:M) { def f; end }
      temporary_class(:C) { include M; def f; end }
      @object = C.new
    end

    it "should return the unoverridden UnboundMethod for the given method name" do
      lookup_path = Looksee::LookupPath.new(@object)
      method = lookup_path.find('f')
      method.owner.should == C
      method.name.should == :f
    end

    it "should find methods in included modules" do
      M.class_eval { def g; end }
      lookup_path = Looksee::LookupPath.new(@object)
      method = lookup_path.find('g')
      method.owner.should == M
      method.name.should == :g
    end

    it "should return nil if the method does not exist" do
      lookup_path = Looksee::LookupPath.new(@object)
      lookup_path.find('g').should be_nil
    end

    it "should return nil if the method has been undefined" do
      C.send(:undef_method, :f)
      lookup_path = Looksee::LookupPath.new(@object)
      lookup_path.find('f').should be_nil
    end
  end

  describe Looksee::LookupPath::Entry do
    it "should iterate over methods in alphabetical order" do
      temporary_class(:C)
      @object = C.new
      Looksee.adapter.stub(internal_public_instance_methods: [:a, :c, :b])
      @lookup_path = Looksee::LookupPath.new(@object)
      @lookup_path.entries.first.map{|name, visibility| name}.should == ['a', 'b', 'c']
    end
  end
end
