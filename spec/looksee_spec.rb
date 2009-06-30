require 'spec_helper'

describe Looksee do
  include TemporaryClasses

  describe ".lookup_modules" do
    #
    # Wrapper for the method under test.
    #
    # Filter out modules which are hard to test against, and returns
    # the list of module names.  #inspect strings are used for names
    # of singleton classes, since they have no name.
    #
    def filtered_lookup_modules(object)
      result = Looksee.lookup_modules(object).select{|mod| deterministic_module?(mod)}
      # Singleton classes have no name - use the inspect string instead.
      result.map{|mod| mod.name.empty? ? mod.inspect : mod.name}
    end

    #
    # Return true if the given module is something we can test for.
    #
    # This excludes ruby version dependent modules, and modules tossed
    # into the hierarchy by testing frameworks.
    #
    def deterministic_module?(mod)
      junk_patterns = [
        # pollution from testing libraries
        'Mocha', 'Spec',
        # RSpec adds this under ruby 1.8.6
        'InstanceExecHelper',
        # only in ruby 1.9
        'BasicObject',
        # something pulls this in under ruby 1.9
        'PP',
      ]
      mod.name !~ /\A\[*(#{junk_patterns.join('|')})/
    end

    it "should contain an entry for each module in the object's lookup path" do
      Mod1 = temporary_module
      Mod2 = temporary_module
      Base = temporary_class
      Derived = temporary_class(Base) do
        include Mod1
        include Mod2
      end
      filtered_lookup_modules(Derived.new) == %w'Derived Mod2 Mod1 Base Object Kernel'
    end

    it "contain an entry for the object's singleton class if it exists" do
      object = Object.new
      object.singleton_class

      result = filtered_lookup_modules(object)
      result.shift.should =~ /\A#<Class:\#<Object:0x[\da-f]+>>\z/
      result.should == %w"Object Kernel"
    end

    it "should contain entries for singleton classes of all ancestors for class objects" do
      C = temporary_class
      result = filtered_lookup_modules(C)
      result.should == %w'#<Class:C> #<Class:Object> Class Module Object Kernel'
    end
  end

  describe ".lookup_path" do
    it "should return a LookupPath object" do
      object = Object.new
      lookup_path = Looksee.lookup_path(object)
      lookup_path.should be_a(Looksee::LookupPath)
    end

    it "should return a LookupPath object for the given object" do
      object = Object.new
      Looksee.stubs(:default_lookup_path_options).returns({})
      Looksee::LookupPath.expects(:new).with(object, {})
      lookup_path = Looksee.lookup_path(object)
    end

    it "should allow symbol arguments as shortcuts for true options" do
      object = Object.new
      Looksee.stubs(:default_lookup_path_options).returns({})
      Looksee::LookupPath.expects(:new).with(object, {:public => true, :overridden => true})
      Looksee.lookup_path(object, :public, :overridden)
    end

    it "should merge the default options, with the symbols, and the options hash" do
      object = Object.new
      Looksee.stubs(:default_lookup_path_options).returns({:public => false, :protected => false, :private => false})
      Looksee::LookupPath.expects(:new).with(object, {:public => false, :protected => true, :private => false})
      Looksee.lookup_path(object, :protected, :private, :private => false)
    end
  end
end

describe Looksee::LookupPath do
  before do
    Looksee.default_lookup_path_options = {}
  end

  def stub_methods(mod, public, protected, private)
    mod.stubs(:public_instance_methods   ).returns(public)
    mod.stubs(:protected_instance_methods).returns(protected)
    mod.stubs(:private_instance_methods  ).returns(private)
  end

  include TemporaryClasses

  describe "#entries" do
    it "should contain an entry for each module in the object's lookup path" do
      object = Object.new
      C = temporary_class
      D = temporary_class
      Looksee.stubs(:lookup_modules).with(object).returns([C, D])
      Looksee::LookupPath.new(object).entries.map{|entry| entry.module_name}.should == %w'C D'
    end
  end

  describe "#inspect" do
    before do
      Mod1 = temporary_module
      Mod2 = temporary_module
      Base = temporary_class
      Derived = temporary_class Base do
        include Mod1
        include Mod2
      end
    end

    before do
      Looksee.stubs(:styles).returns(Hash.new{'%s'})
    end

    def first_lines(string, num)
      string.scan(/.*\n/).first(num).join
    end

    describe "contents" do
      before do
        [Derived, Mod2].each do |mod|
          stub_methods(mod, ['public1', 'public2'], ['protected1', 'protected2'], ['private1', 'private2'])
        end
      end

      it "should show only public instance methods when only public methods are requested" do
        lookup_path = Looksee::LookupPath.new(Derived.new, :public => true, :overridden => true)
        first_lines(lookup_path.inspect, 4).should == <<-EOS.demargin
          |Derived
          |  public1  public2
          |Mod2
          |  public1  public2
        EOS
      end

      it "should show modules and protected instance methods when only protected methods are requested" do
        lookup_path = Looksee::LookupPath.new(Derived.new, :protected => true, :overridden => true)
        first_lines(lookup_path.inspect, 4).should == <<-EOS.demargin
          |Derived
          |  protected1  protected2
          |Mod2
          |  protected1  protected2
        EOS
      end

      it "should show modules and private instance methods when only private methods are requested" do
        lookup_path = Looksee::LookupPath.new(Derived.new, :private => true, :overridden => true)
        first_lines(lookup_path.inspect, 4).should == <<-EOS.demargin
          |Derived
          |  private1  private2
          |Mod2
          |  private1  private2
        EOS
      end

      it "should show modules with public and private instance methods when only public and private methods are requested" do
        lookup_path = Looksee::LookupPath.new(Derived.new, :public => true, :private => true, :overridden => true)
        first_lines(lookup_path.inspect, 4).should == <<-EOS.demargin
          |Derived
          |  private1  private2  public1  public2
          |Mod2
          |  private1  private2  public1  public2
        EOS
      end

      it "should show singleton classes as class names in brackets" do
        stub_methods(Derived.singleton_class, ['public1', 'public2'], [], [])
        lookup_path = Looksee::LookupPath.new(Derived, :public => true)
        first_lines(lookup_path.inspect, 2).should == <<-EOS.demargin
          |[Derived]
          |  public1  public2
        EOS
      end

      it "should handle singleton classes of singleton classes correctly" do
        stub_methods(Derived.singleton_class.singleton_class, ['public1', 'public2'], [], [])
        lookup_path = Looksee::LookupPath.new(Derived.singleton_class, :public => true)
        first_lines(lookup_path.inspect, 2).should == <<-EOS.demargin
          |[[Derived]]
          |  public1  public2
        EOS
      end
    end

    describe "styles" do
      before do
        styles = {
          :module     => "`%s'",
          :public     => "{%s}",
          :protected  => "[%s]",
          :private    => "<%s>",
          :overridden => "(%s)",
        }
        Looksee.stubs(:styles).returns(styles)
      end

      it "should delimit each word with the configured delimiters" do
        stub_methods(Derived, ['public'], ['protected'], ['private'])
        stub_methods(Mod2, ['public', 'foo'], [], [])
        lookup_path = Looksee::LookupPath.new(Derived.new, :public => true, :protected => true, :private => true, :overridden => true)
        first_lines(lookup_path.inspect, 4).should == <<-EOS.demargin
          |\`Derived\'
          |  <private>  [protected]  {public}
          |\`Mod2\'
          |  {foo}  (public)
        EOS
      end
    end

    describe "layout" do
      it "should wrap method lists at the configured number of columns, sorting vertically first, and aligning into a grid" do
        stub_methods(Derived, %w'aa b c dd ee f g hh i', [], [])
        lookup_path = Looksee::LookupPath.new(Derived.new, :public => true)
        first_lines(lookup_path.inspect(:width => 20), 3).should == <<-EOS.demargin
          |Derived
          |  aa  c   ee  g   i
          |  b   dd  f   hh
        EOS
      end

      it "should lay the methods of each module out independently" do
        stub_methods(Derived, ['a', 'long_long_long_long_name'], [], [])
        stub_methods(Mod2, ['long_long_long', 'short'], [], [])
        lookup_path = Looksee::LookupPath.new(Derived.new, :public => true)
        first_lines(lookup_path.inspect, 4).should == <<-EOS.demargin
          |Derived
          |  a  long_long_long_long_name
          |Mod2
          |  long_long_long  short
        EOS
      end
    end
  end
end
