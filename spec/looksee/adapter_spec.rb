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
      result = @adapter.lookup_modules(object).
        map { |mod| @adapter.describe_module(mod) }.
        select{ |description| deterministic_module?(description) }
    end

    #
    # Return true if the given module name is of a module we can test
    # for.
    #
    # This excludes ruby version dependent modules, and modules tossed
    # into the hierarchy by testing frameworks.
    #
    def deterministic_module?(description)
      junk_patterns = [
        # pollution from testing libraries
        'Mocha', 'Spec',
        # RSpec 2
        'RSpec::',
        # not sure what pulls these in
        'PP', 'JSON::Ext::Generator::GeneratorMethods::Object',
        # our own pollution
        'Looksee::ObjectMixin',
      ]
      pattern = /\b(#{junk_patterns.join('|')})\b/
      description !~ pattern
    end

    it "should contain an entry for each module in the object's lookup path" do
      temporary_module :Mod1
      temporary_module :Mod2
      temporary_class :Base
      temporary_class :Derived, :superclass => Base do
        include Mod1
        include Mod2
      end
      filtered_lookup_modules(Derived.new).should ==
        ['Derived', 'Mod2', 'Mod1', 'Base', 'Object', 'Kernel', 'BasicObject']
    end

    it "should contain an entry for the object's singleton class if it has methods" do
      object = Object.new
      def object.f; end

      filtered_lookup_modules(object).should ==
        ['[Object instance]', 'Object', 'Kernel', 'BasicObject']
    end

    it "should contain entries for singleton classes of all ancestors for class objects" do
      temporary_class :C
      filtered_lookup_modules(C).should ==
        ['[C]', '[Object]', '[BasicObject]', 'Class', 'Module', 'Object', 'Kernel', 'BasicObject']
    end

    it "should work for immediate objects" do
      if RUBY_VERSION >= "2.4.0"
        filtered_lookup_modules(1).first.should == 'Integer'
      else
        filtered_lookup_modules(1).first.should == 'Fixnum'
      end
    end
  end

  describe "internal instance methods:" do
    def self.target_method(name)
      define_method(:target_method){name}
    end

    describe ".internal_undefined_instance_methods" do
      if Looksee.ruby_engine == 'ruby' && RUBY_VERSION >= '2.3'
        it "just returns an empty array" do
          temporary_class :C
          add_methods C, undefined: [:f]
          @adapter.internal_undefined_instance_methods(C).should == []
        end
      else
        it "should return the list of undefined instance methods directly on a class" do
          temporary_class :C
          add_methods(C, undefined: [:f])
          @adapter.internal_undefined_instance_methods(C).should == [:f]
        end

        it "should return the list of undefined instance methods directly on a module" do
          temporary_module :M
          add_methods(M, undefined: [:f])
          @adapter.internal_undefined_instance_methods(M).should == [:f]
        end

        it "should return the list of undefined instance methods directly on a singleton class" do
          temporary_class :C
          c = C.new
          add_methods(c.singleton_class, undefined: [:f])
          @adapter.internal_undefined_instance_methods(c.singleton_class).should == [:f]
        end

        it "should return the list of undefined instance methods directly on a class' singleton class" do
          temporary_class :C
          add_methods(C.singleton_class, undefined: [:f])
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

        it "should handle the MRI allocator being undefined (e.g. Struct)" do
          struct_singleton_class = (class << Struct; self; end)
          @adapter.internal_undefined_instance_methods(struct_singleton_class).should == []
        end
      end
    end
  end

  describe "singleton_instance" do
    it "should return the instance of the given singleton class" do
      object = Object.new
      @adapter.singleton_instance((class << object; self; end)).should equal(object)
    end

    it "should return the instance of the given class singleton class" do
      klass = Class.new
      @adapter.singleton_instance((class << klass; self; end)).should equal(klass)
    end

    it "should return the instance of the given module singleton class" do
      mod = Module.new
      @adapter.singleton_instance((class << mod; self; end)).should equal(mod)
    end

    it "should return the instance of the given singleton class singleton class" do
      singleton_class = (class << Class.new; self; end)
      super_singleton_class = (class << singleton_class; self; end)
      @adapter.singleton_instance(super_singleton_class).should equal(singleton_class)
    end

    it "should return nil if the given object is just a class" do
      @adapter.singleton_instance(Class.new).should be_nil
    end

    it "should return nil if the given object is just a module" do
      @adapter.singleton_instance(Module.new).should be_nil
    end

    it "should return nil if the given object is just a object" do
      @adapter.singleton_instance(Object.new).should be_nil
    end

    it "should return nil if the given object is an immediate object" do
      @adapter.singleton_instance(nil).should be_nil
      @adapter.singleton_instance(true).should be_nil
      @adapter.singleton_instance(false).should be_nil
      @adapter.singleton_instance(1).should be_nil
      @adapter.singleton_instance(:hi).should be_nil
    end
  end

  describe "#describe_module" do
    it "should return the fully-qualified name of a module" do
      begin
        ::M = Module.new
        ::M::N = Module.new
        @adapter.describe_module(::M::N).should == 'M::N'
      ensure
        Object.send :remove_const, :M
      end
    end

    it "should return the fully-qualified name of a class" do
      begin
        ::M = Module.new
        ::M::N = Class.new
        @adapter.describe_module(::M::N).should == 'M::N'
      ensure
        Object.send :remove_const, :M
      end
    end

    it "should not be affected by overridding the module's #to_s or #name" do
      begin
        ::M = Module.new
        ::M::C = Class.new do
          def name
            'overridden'
          end
          def to_s
            'overridden'
          end
        end
        @adapter.describe_module(::M::C).should == 'M::C'
      ensure
        Object.send :remove_const, :M
      end
    end

    describe "for an unnamed class" do
      it "should describe the object as 'unnamed Class'" do
        @adapter.describe_module(Class.new).should == 'unnamed Class'
      end
    end

    describe "for an unnamed module" do
      it "should describe the object as 'unnamed Module'" do
        @adapter.describe_module(Module.new).should == 'unnamed Module'
      end
    end

    describe "for an included class of an unnamed module" do
      it "should describe the object as 'unnamed Module'" do
        klass = Class.new do
          include Module.new
        end
        mod = @adapter.lookup_modules(klass.new)[1]
        @adapter.describe_module(mod).should == 'unnamed Module'
      end
    end

    describe "for a singleton class of an object" do
      it "should describe the object in brackets" do
        begin
          ::M = Module.new
          ::M::C = Class.new
          object = M::C.new
          @adapter.describe_module(object.singleton_class).should == '[M::C instance]'
        ensure
          Object.send :remove_const, :M
        end
      end
    end

    describe "for a singleton class of a named class" do
      it "should return the class name in brackets" do
        begin
          ::M = Module.new
          ::M::C = Class.new
          @adapter.describe_module(M::C.singleton_class).should == '[M::C]'
        ensure
          Object.send :remove_const, :M
        end
      end
    end

    describe "for a singleton class of an unnamed class" do
      it "should describe the object as '[unnamed Class]'" do
        klass = Class.new
        @adapter.describe_module(klass.singleton_class).should == '[unnamed Class]'
      end
    end

    describe "for a singleton class of an unnamed module" do
      it "should describe the object as '[unnamed Module]'" do
        mod = Module.new
        @adapter.describe_module(mod.singleton_class).should == '[unnamed Module]'
      end
    end

    describe "for a singleton class of a singleton class" do
      it "should return the object's class name in two pairs of brackets" do
        begin
          ::M = Module.new
          ::M::C = Class.new
          klass = M::C.singleton_class.singleton_class
          @adapter.describe_module(klass).should == '[[M::C]]'
        ensure
          Object.send :remove_const, :M
        end
      end
    end

    it "should raise a TypeError if the argumeent is not a module" do
      lambda do
        @adapter.describe_module(Object.new)
      end.should raise_error(TypeError)
    end
  end
end
