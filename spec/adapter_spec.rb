require 'spec_helper'

describe "Looksee.adapter" do
  include TemporaryClasses

  before do
    @adapter = NATIVE_ADAPTER
  end

  describe "#lookup_modules" do
    #
    # Filter out modules which are hard to test against, and returns
    # the list of module names.  #inspect strings are used for names
    # of singleton classes, since they have no name.
    #
    def filtered_lookup_modules(object)
      result = @adapter.lookup_modules(object)
      # Singleton classes have no name ('' in <1.9, nil in 1.9+).  Use
      # the inspect string instead.
      names = result.map{|mod| mod.name.nil? || mod.name.empty? ? mod.inspect : mod.name}
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
        # RSpec 2
        'RSpec::',
        # only in ruby 1.9
        'BasicObject',
        # something pulls this in under ruby 1.9
        'PP',
        # our own pollution,
        'Looksee::Object',
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
      if RUBY_ENGINE == 'rbx'
        result.shift.should =~ /\A#<Class: \#<Object:\d+>>\z/
      else
        result.shift.should =~ /\A#<Class:\#<Object:0x[\da-f]+>>\z/
      end
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

  describe "internal instance methods:" do
    def self.target_method(name)
      define_method(:target_method){name}
    end

    def self.it_should_list_methods_with_visibility(visibility)
      it "should return the list of #{visibility} instance methods defined directly on a class" do
        temporary_class :C
        replace_methods C, visibility => [:one, :two]
        @adapter.send(target_method, C).to_set.should == Set[:one, :two]
      end

      it "should return the list of #{visibility} instance methods defined directly on a module" do
        temporary_module :M
        replace_methods M, visibility => [:one, :two]
        @adapter.send(target_method, M).to_set.should == Set[:one, :two]
      end

      it "should return the list of #{visibility} instance methods defined directly on a singleton class" do
        temporary_class :C
        c = C.new
        replace_methods c.singleton_class, visibility => [:one, :two]
        @adapter.send(target_method, c.singleton_class).to_set.should == Set[:one, :two]
      end

      it "should return the list of #{visibility} instance methods defined directly on a class' singleton class" do
        temporary_class :C
        replace_methods C.singleton_class, visibility => [:one, :two], :class_singleton => true
        @adapter.send(target_method, C.singleton_class).to_set.should == Set[:one, :two]
      end

      # Worth checking as ruby keeps undef'd methods in method tables.
      it "should not return undefined methods" do
        temporary_class :C
        replace_methods C, visibility => [:removed]
        C.send(:undef_method, :removed)
        @adapter.send(target_method, C).to_set.should == Set[]
      end
    end

    def self.it_should_not_list_methods_with_visibility(visibility1, visibility2)
      it "should not return any #{visibility1} or #{visibility2} instance methods" do
        temporary_class :C
        replace_methods C, {visibility1 => [:a], visibility2 => [:b]}
        @adapter.send(target_method, C).to_set.should == Set[]
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

    describe ".internal_undefined_instance_methods" do
      it "should return the list of undefined instance methods directly on a class" do
        temporary_class :C
        C.send(:define_method, :f){}
        C.send(:undef_method, :f)
        @adapter.internal_undefined_instance_methods(C).should == [:f]
      end

      it "should return the list of undefined instance methods directly on a module" do
        temporary_module :M
        M.send(:define_method, :f){}
        M.send(:undef_method, :f)
        @adapter.internal_undefined_instance_methods(M).should == [:f]
      end

      it "should return the list of undefined instance methods directly on a singleton class" do
        temporary_class :C
        c = C.new
        c.singleton_class.send(:define_method, :f){}
        c.singleton_class.send(:undef_method, :f)
        @adapter.internal_undefined_instance_methods(c.singleton_class).should == [:f]
      end

      it "should return the list of undefined instance methods directly on a class' singleton class" do
        temporary_class :C
        C.singleton_class.send(:define_method, :f){}
        C.singleton_class.send(:undef_method, :f)
        @adapter.internal_undefined_instance_methods(C.singleton_class).should == [:f]
      end

      it "should not return defined methods" do
        temporary_class :C
        C.send(:define_method, :f){}
        @adapter.internal_undefined_instance_methods(C).should == []
      end

      it "should not return removed methods" do
        temporary_class :C
        C.send(:define_method, :f){}
        C.send(:remove_method, :f)
        @adapter.internal_undefined_instance_methods(C).should == []
      end
    end
  end
end
