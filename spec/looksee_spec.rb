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
      result = Looksee.lookup_modules(object)
      # Singleton classes have no name ('' in <1.9, nil in 1.9+).  Use
      # the inspect string instead.
      names = result.map{|mod| mod.name.to_s.empty? ? mod.inspect : mod.name}
      names.select{|name| deterministic_module_name?(name)}
    end

    #
    # Return true if the given module name is of a module we can test
    # for.
    #
    # This excludes ruby version dependent modules, and modules tossed
    # into the hierarchy by testing frameworks.
    #
    def deterministic_module_name?(name)
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

      # Singleton classes of junk are junk.
      while name =~ /\A#<Class:(.*)>\z/
        name = $1
      end

      name !~ /\A(#{junk_patterns.join('|')})/
    end

    it "should contain an entry for each module in the object's lookup path" do
      temporary_module :Mod1
      temporary_module :Mod2
      temporary_class :Base
      temporary_class :Derived, :superclass => Base do
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
      temporary_class :C
      result = filtered_lookup_modules(C)
      result.should == %w'#<Class:C> #<Class:Object> Class Module Object Kernel'
    end

    it "should work for immediate objects" do
      filtered_lookup_modules(1).first.should == 'Fixnum'
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
      Looksee::LookupPath.expects(:for).with(object, {})
      lookup_path = Looksee.lookup_path(object)
    end

    it "should allow symbol arguments as shortcuts for true options" do
      object = Object.new
      Looksee.stubs(:default_lookup_path_options).returns({})
      Looksee::LookupPath.expects(:for).with(object, {:public => true, :overridden => true})
      Looksee.lookup_path(object, :public, :overridden)
    end

    it "should merge the default options, with the symbols, and the options hash" do
      object = Object.new
      Looksee.stubs(:default_lookup_path_options).returns({:public => false, :protected => false, :private => false})
      Looksee::LookupPath.expects(:for).with(object, {:public => false, :protected => true, :private => false})
      Looksee.lookup_path(object, :protected, :private, :private => false)
    end
  end

  describe "internal instance methods:" do
    def self.target_method(name)
      define_method(:target_method){name}
    end

    def self.it_should_list_methods_with_visibility(visibility)
      it "should return the list of #{visibility} instance methods defined directly on a class" do
        temporary_class :C
        replace_methods C, visibility => [:one, :two]
        Looksee.send(target_method, C).to_set.should == Set[:one, :two]
      end

      it "should return the list of #{visibility} instance methods defined directly on a module" do
        temporary_module :M
        replace_methods M, visibility => [:one, :two]
        Looksee.send(target_method, M).to_set.should == Set[:one, :two]
      end

      it "should return the list of #{visibility} instance methods defined directly on a singleton class" do
        temporary_class :C
        c = C.new
        replace_methods c.singleton_class, visibility => [:one, :two]
        Looksee.send(target_method, c.singleton_class).to_set.should == Set[:one, :two]
      end

      it "should return the list of #{visibility} instance methods defined directly on a class' singleton class" do
        temporary_class :C
        replace_methods C.singleton_class, visibility => [:one, :two], :class_singleton => true
        Looksee.send(target_method, C.singleton_class).to_set.should == Set[:one, :two]
      end

      # Worth checking as ruby keeps undef'd methods in method tables.
      it "should not return undefined methods" do
        temporary_class :C
        replace_methods C, visibility => [:removed]
        C.send(:undef_method, :removed)
        Looksee.send(target_method, C).to_set.should == Set[]
      end
    end

    def self.it_should_not_list_methods_with_visibility(visibility1, visibility2)
      it "should not return any #{visibility1} or #{visibility2} instance methods" do
        temporary_class :C
        replace_methods C, {visibility1 => [:a], visibility2 => [:b]}
        Looksee.send(target_method, C).to_set.should == Set[]
      end
    end

    describe ".internal_public_instance_methods" do
      target_method :internal_public_instance_methods
      it_should_list_methods_with_visibility :public
      it_should_not_list_methods_with_visibility :private, :protected
    end

    describe ".internal_protected_instance_methods" do
      target_method :internal_protected_instance_methods
      it_should_list_methods_with_visibility :protected
      it_should_not_list_methods_with_visibility :public, :private
    end

    describe ".internal_private_instance_methods" do
      target_method :internal_private_instance_methods
      it_should_list_methods_with_visibility :private
      it_should_not_list_methods_with_visibility :public, :protected
    end
  end
end

describe Looksee::LookupPath do
  include TemporaryClasses

  def stub_methods(mod, public, protected, private)
    Looksee.stubs(:internal_public_instance_methods   ).with(mod).returns(public)
    Looksee.stubs(:internal_protected_instance_methods).with(mod).returns(protected)
    Looksee.stubs(:internal_private_instance_methods  ).with(mod).returns(private)
  end

  describe "#entries" do
    it "should contain an entry for each module in the object's lookup path" do
      object = Object.new
      temporary_class :C
      temporary_class :D
      Looksee.stubs(:lookup_modules).with(object).returns([C, D])
      Looksee::LookupPath.for(object).entries.map{|entry| entry.module_name}.should == %w'C D'
    end
  end

  describe "grep" do
    it "should only include methods matching the given regexp" do
      temporary_class :C
      temporary_class :D
      stub_methods(C, ['axbyc', 'xy'], [], [])
      stub_methods(D, ['axbyc', 'xdy'], [], [])
      object = Object.new
      Looksee.stubs(:lookup_modules).with(object).returns([C, D])
      lookup_path = Looksee::LookupPath.for(object, :public => true, :overridden => true).grep(/x.y/)
      lookup_path.entries.map{|entry| entry.module_name}.should == %w'C D'
      lookup_path.entries[0].methods.to_set.should == Set['axbyc']
      lookup_path.entries[1].methods.to_set.should == Set['axbyc', 'xdy']
    end

    it "should only include methods including the given string" do
      temporary_class :C
      temporary_class :D
      stub_methods(C, ['axxa', 'axa'], [], [])
      stub_methods(D, ['bxxb', 'axxa'], [], [])
      object = Object.new
      Looksee.stubs(:lookup_modules).with(object).returns([C, D])
      lookup_path = Looksee::LookupPath.for(object, :public => true, :overridden => true).grep('xx')
      lookup_path.entries.map{|entry| entry.module_name}.should == %w'C D'
      lookup_path.entries[0].methods.to_set.should == Set['axxa']
      lookup_path.entries[1].methods.to_set.should == Set['axxa', 'bxxb']
    end
  end

  describe "#inspect" do
    before do
      Looksee.stubs(:default_lookup_path_options).returns({})
    end

    before do
      Looksee.stubs(:styles).returns(Hash.new{'%s'})
    end

    describe "contents" do
      before do
        temporary_module :M
        temporary_class :C do
          include M
        end
        @object = Object.new
        Looksee.stubs(:lookup_modules).with(@object).returns([C, M])
        stub_methods(C, ['public1', 'public2'], ['protected1', 'protected2'], ['private1', 'private2'])
        stub_methods(M, ['public1', 'public2'], ['protected1', 'protected2'], ['private1', 'private2'])
      end

      it "should show only public instance methods when only public methods are requested" do
        lookup_path = Looksee::LookupPath.for(@object, :public => true, :overridden => true)
        lookup_path.inspect.should == <<-EOS.demargin.chomp
          |C
          |  public1  public2
          |M
          |  public1  public2
        EOS
      end

      it "should show modules and protected instance methods when only protected methods are requested" do
        lookup_path = Looksee::LookupPath.for(@object, :protected => true, :overridden => true)
        lookup_path.inspect.should == <<-EOS.demargin.chomp
          |C
          |  protected1  protected2
          |M
          |  protected1  protected2
        EOS
      end

      it "should show modules and private instance methods when only private methods are requested" do
        lookup_path = Looksee::LookupPath.for(@object, :private => true, :overridden => true)
        lookup_path.inspect.should == <<-EOS.demargin.chomp
          |C
          |  private1  private2
          |M
          |  private1  private2
        EOS
      end

      it "should show modules with public and private instance methods when only public and private methods are requested" do
        lookup_path = Looksee::LookupPath.for(@object, :public => true, :private => true, :overridden => true)
        lookup_path.inspect.should == <<-EOS.demargin.chomp
          |C
          |  private1  private2  public1  public2
          |M
          |  private1  private2  public1  public2
        EOS
      end

      it "should show singleton classes as class names in brackets" do
        Looksee.stubs(:lookup_modules).with(C).returns([C.singleton_class])
        stub_methods(C.singleton_class, ['public1', 'public2'], [], [])
        lookup_path = Looksee::LookupPath.for(C, :public => true)
        lookup_path.inspect.should == <<-EOS.demargin.chomp
          |[C]
          |  public1  public2
        EOS
      end

      it "should handle singleton classes of singleton classes correctly" do
        Looksee.stubs(:lookup_modules).with(C.singleton_class).returns([C.singleton_class.singleton_class])
        stub_methods(C.singleton_class.singleton_class, ['public1', 'public2'], [], [])
        lookup_path = Looksee::LookupPath.for(C.singleton_class, :public => true)
        lookup_path.inspect.should == <<-EOS.demargin.chomp
          |[[C]]
          |  public1  public2
        EOS
      end

      it "should not show any blank lines if a module has no methods" do
        stub_methods(C, [], [], [])
        lookup_path = Looksee::LookupPath.for(@object, :public => true, :overridden => true)
        lookup_path.inspect.should == <<-EOS.demargin.chomp
          |C
          |M
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
        temporary_class :C
        Looksee.stubs(:lookup_modules).returns([C])
        stub_methods(C, ['public'], ['protected'], ['private'])
        lookup_path = Looksee::LookupPath.for(Object.new, :public => true, :protected => true, :private => true, :overridden => true)
        lookup_path.inspect.should == <<-EOS.demargin.chomp
          |\`C\'
          |  <private>  [protected]  {public}
        EOS
      end
    end

    describe "layout" do
      it "should wrap method lists at the configured number of columns, sorting vertically first, and aligning into a grid" do
        temporary_class :C
        Looksee.stubs(:lookup_modules).returns([C])
        stub_methods(C, %w'aa b c dd ee f g hh i', [], [])
        lookup_path = Looksee::LookupPath.for(Object.new, :public => true)
        lookup_path.inspect(:width => 20).should == <<-EOS.demargin.chomp
          |C
          |  aa  c   ee  g   i
          |  b   dd  f   hh
        EOS
      end

      it "should lay the methods of each module out independently" do
        temporary_class :A
        temporary_class :B
        Looksee.stubs(:lookup_modules).returns([A, B])
        stub_methods(A, ['a', 'long_long_long_long_name'], [], [])
        stub_methods(B, ['long_long_long', 'short'], [], [])
        lookup_path = Looksee::LookupPath.for(Object.new, :public => true)
        lookup_path.inspect.should == <<-EOS.demargin.chomp
          |A
          |  a  long_long_long_long_name
          |B
          |  long_long_long  short
        EOS
      end
    end
  end
end
