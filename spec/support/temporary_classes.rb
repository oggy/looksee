#
# Include these in example groups to add facilities to create
# temporary classes and modules, which are swept up at the end of each
# example.
#
# Call make_class('ClassName') or make_module('ModuleName') to create
# a temporary class, then access them with plain constants (ClassName,
# ModuleName).
#
module TemporaryClasses
  def self.included(mod)
    mod.before do
      @temporary_modules = []
    end

    mod.after do
      @temporary_modules.each do |mod|
        Object.send :remove_const, mod.name
      end
    end
  end

  #
  # Create a temporary class with the given name and superclass.
  #
  def temporary_class(name, options={}, &block)
    klass = Class.new(options[:superclass] || Object)
    Object.const_set(name, klass)
    klass.class_eval(&block) if block
    @temporary_modules << klass
    klass
  end

  #
  # Create a temporary module with the given name.
  #
  def temporary_module(name, &block)
    mod = Module.new
    Object.const_set(name, mod)
    mod.class_eval(&block) if block
    @temporary_modules << mod
    mod
  end

  #
  # Replace the methods of the given module with those named.
  #
  # +methods+ is a hash of visibilities to names.
  #
  # As Ruby's reflection on singleton classes of classes isn't quite
  # adequate, you need to provide a :class_singleton option when such
  # a class is given.
  #
  # e.g.:
  #
  #   replace_methods MyClass, :public => [:a, :b]
  #
  def add_methods(mod, options={})
    mod.module_eval do
      [:public, :protected, :private].each do |visibility|
        Array(options[visibility]).each do |name|
          define_method(name){}
          send visibility, name
        end
      end
    end
  end

  private  # ---------------------------------------------------------

  def all_instance_methods(mod)
    names =
      mod.public_instance_methods(false) +
      mod.protected_instance_methods(false) +
      mod.private_instance_methods(false)
  end
end
