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
      add_methods(
        M,
        public: [:pub1, :pub2],
        protected: [:pro1, :pro2],
        private: [:pri1, :pri2],
        undefined: [:und1, :und2],
      )
      add_methods(
        C,
        public: [:pub1, :pub2],
        protected: [:pro1, :pro2],
        private: [:pri1, :pri2],
        undefined: [:und1, :und2],
      )
      @lookup_path = Looksee::LookupPath.new(@object)
    end

    it "should contain an entry for each module in the object's lookup path" do
      @lookup_path.entries.map{|entry| entry.module}.should == [C, M]
    end

    it "should include methods of all visibilities, including overridden ones" do
      @lookup_path.entries[0].methods.should == {
        'pub1' => :public, 'pub2' => :public,
        'pro1' => :protected, 'pro2' => :protected,
        'pri1' => :private, 'pri2' => :private,
        'und1' => :undefined, 'und2' => :undefined,
      }
      @lookup_path.entries[1].methods.should == {
        'pub1' => :public, 'pub2' => :public,
        'pro1' => :protected, 'pro2' => :protected,
        'pri1' => :private, 'pri2' => :private,
        'und1' => :undefined, 'und2' => :undefined,
      }
    end

    it "should know which methods have been overridden" do
      @lookup_path.entries[0].overridden?('pub1').should == false
      @lookup_path.entries[1].overridden?('pub1').should == true
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

    unless RUBY_VERSION >= '2.3.0'
      it "should return nil if the method has been undefined" do
        add_methods(C, undefined: [:f])
        lookup_path = Looksee::LookupPath.new(@object)
        lookup_path.find('f').should be_nil
      end
    end
  end

  describe 'Looksee::LookupPath::Entry' do
    it "should iterate over methods in alphabetical order" do
      temporary_class(:C)
      add_methods(C, public: [:a, :c, :b])
      @lookup_path = Looksee::LookupPath.new(C.new)
      @lookup_path.entries.first.map{|name, visibility| name}.should == ['a', 'b', 'c']
    end
  end
end
