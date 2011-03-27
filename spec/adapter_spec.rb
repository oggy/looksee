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
      result.select{ |mod| deterministic_module?(mod) }
    end

    #
    # Return true if the given module name is of a module we can test
    # for.
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
        # RSpec 2
        'RSpec::',
        # only in ruby 1.9
        'BasicObject',
        # something pulls this in under ruby 1.9
        'PP',
        # our own pollution,
        'Looksee::Object',
      ]
      pattern = /\A(#{junk_patterns.join('|')})/

      # Singleton classes of junk are junk.
      if Looksee.ruby_engine == 'rbx'
        # Rubinius singleton class #inspect strings aren't formatted
        # like the others.
        while mod.respond_to?(:__metaclass_object__) && (object = mod.__metaclass_object__).is_a?(Class)
          mod = object
        end
        mod.name !~ pattern
      else
        name = mod.to_s
        while name =~ /\A#<Class:(.*)>\z/
          name = $1
        end
        name !~ pattern
      end
    end

    it "should contain an entry for each module in the object's lookup path" do
      temporary_module :Mod1
      temporary_module :Mod2
      temporary_class :Base
      temporary_class :Derived, :superclass => Base do
        include Mod1
        include Mod2
      end
      filtered_lookup_modules(Derived.new) == [Derived, Mod2, Mod1, Base, Object, Kernel]
    end

    it "should contain an entry for the object's singleton class if it exists" do
      object = Object.new
      object.singleton_class

      filtered_lookup_modules(object).should == [object.singleton_class, Object, Kernel]
    end

    it "should contain entries for singleton classes of all ancestors for class objects" do
      temporary_class :C
      filtered_lookup_modules(C).should == [C.singleton_class, Object.singleton_class, Class, Module, Object, Kernel]
    end

    it "should work for immediate objects" do
      filtered_lookup_modules(1).first.should == Fixnum
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

  describe "#singleton_class?" do
    it "should return true if the object is a singleton class of an object" do
      object = (class << Object.new; self; end)
      @adapter.singleton_class?(object).should be_true
    end

    it "should return true if the object is a singleton class of a class" do
      object = (class << Class.new; self; end)
      @adapter.singleton_class?(object).should be_true
    end

    it "should return true if the object is a singleton class of a singleton class" do
      object = (class << (class << Class.new; self; end); self; end)
      @adapter.singleton_class?(object).should be_true
    end

    it "should return false if the object is just a class" do
      object = Class.new
      @adapter.singleton_class?(object).should be_false
    end

    it "should return false if the object is just a module" do
      object = Module.new
      @adapter.singleton_class?(object).should be_false
    end

    it "should return false if the object is just an object" do
      object = Object.new
      @adapter.singleton_class?(object).should be_false
    end

    it "should return false if the object is TrueClass" do
      @adapter.singleton_class?(TrueClass).should be_false
    end

    it "should return false if the object is FalseClass" do
      @adapter.singleton_class?(FalseClass).should be_false
    end

    it "should return false if the object is NilClass" do
      @adapter.singleton_class?(NilClass).should be_false
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

    it "should raise a TypeError if the given object is just a class" do
      lambda do
        @adapter.singleton_instance(Class.new)
      end.should raise_error(TypeError)
    end

    it "should raise a TypeError if the given object is just a module" do
      lambda do
        @adapter.singleton_instance(Module.new)
      end.should raise_error(TypeError)
    end

    it "should raise a TypeError if the given object is just a object" do
      lambda do
        @adapter.singleton_instance(Object.new)
      end.should raise_error(TypeError)
    end
  end

  describe "#module_name" do
    it "should return the fully-qualified name of the given module" do
      ::M = Module.new
      M::N = Module.new
      begin
        @adapter.module_name(M::N).should == 'M::N'
      ensure
        Object.send :remove_const, :M
      end
    end

    it "should return the fully-qualified name of the given class" do
      ::M = Module.new
      M::C = Class.new
      begin
        @adapter.module_name(M::C).should == 'M::C'
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
        @adapter.describe_module(M::C).should == 'M::C'
      ensure
        Object.send :remove_const, :M
      end
    end

    it "should return an empty string for unnamed modules" do
      @adapter.module_name(Module.new).should == ''
    end

    it "should return an empty string for unnamed classes" do
      @adapter.module_name(Class.new).should == ''
    end

    it "should return an empty string for singleton classes" do
      object = Object.new
      @adapter.module_name((class << object; self; end)).should == ''
    end

    it "should raise a TypeError if the argumeent is not a module" do
      lambda do
        @adapter.module_name(Object.new)
      end.should raise_error(TypeError)
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
  end

  describe "#source_location" do
    def load_source(source)
      @tmp = "#{ROOT}/spec/tmp"
      @source_path = "#@tmp/c.rb"
      FileUtils.mkdir_p @tmp
      open(@source_path, 'w') { |f| f.print source }
      load @source_path
      @source_path
    end

    after do
      FileUtils.rm_rf @tmp if @tmp
      Object.send(:remove_const, :C) if Object.const_defined?(:C)
    end

    it "should return the file and line number the given method was defined on" do
      path = load_source <<-EOS.demargin
        |class C
        |  def f
        |  end
        |end
      EOS
      method = C.instance_method(:f)
      @adapter.source_location(method).should == [path, 2]
    end

    it "should work for methods defined via a block (MRI BMETHOD)" do
      path = load_source <<-EOS.demargin
        |class C
        |  define_method :f do
        |  end
        |end
      EOS
      method = C.instance_method(:f)
      @adapter.source_location(method).should == [path, 2]
    end

    it "should work for methods defined via a proc (MRI BMETHOD)" do
      path = load_source <<-EOS.demargin
        |class C
        |  f = lambda do
        |  end
        |  define_method :f, f
        |end
      EOS
      method = C.instance_method(:f)
      @adapter.source_location(method).should == [path, 2]
    end

    it "should work for methods defined via a UnboundMethod (MRI DMETHOD)" do
      path = load_source <<-EOS.demargin
        |class C
        |  def f
        |  end
        |  define_method :g, instance_method(:f)
        |end
      EOS
      method = C.instance_method(:g)
      @adapter.source_location(method).should == [path, 2]
    end

    it "should work for methods defined via a BoundMethod (MRI DMETHOD)" do
      path = load_source <<-EOS.demargin
        |class C
        |  def f
        |  end
        |  define_method :g, new.method(:f)
        |end
      EOS
      method = C.instance_method(:g)
      @adapter.source_location(method).should == [path, 2]
    end

    it "should work for methods whose visibility is overridden in a subclass (MRI ZSUPER)" do
      path = load_source <<-EOS.demargin
        |class C
        |  def f
        |  end
        |end
        |class D < C
        |  private :f
        |end
      EOS
      begin
        method = D.instance_method(:f)
        @adapter.source_location(method).should == [path, 2]
      ensure
        Object.send(:remove_const, :D)
      end
    end

    it "should work for aliases (MRI FBODY)" do
      path = load_source <<-EOS.demargin
        |class C
        |  def f
        |  end
        |  alias g f
        |end
      EOS
      method = C.instance_method(:g)
      @adapter.source_location(method).should == [path, 2]
    end

    it "should return nil for primitive methods (MRI CBODY)" do
      method = Array.instance_method(:size)
      @adapter.source_location(method).should == nil
    end

    it "should raise a TypeError if the argument is not an UnboundMethod" do
      path = load_source <<-EOS.demargin
        |class C
        |  def f
        |  end
        |end
      EOS
      lambda do
        @adapter.source_location(nil)
      end.should raise_error(TypeError)
    end
  end
end
