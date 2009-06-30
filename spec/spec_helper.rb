require 'spec'
require 'mocha'
require 'looksee'

Spec::Runner.configure do |config|
  config.mock_with :mocha
end

class Object
  #
  # Return this object's singleton class.
  #
  def singleton_class
    class << self; self; end
  end
end

class String
  #
  # Remove a left margin delimited by '|'-characters.  Useful for
  # heredocs:
  #
  def demargin
    gsub(/^ *\|/, '')
  end
end

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
        namespace = mod.name.split(/::/)
        basename = namespace.pop
        namespace.inject(Object) do |_namespace, _basename|
          _namespace.const_get(_basename)
        end.send(:remove_const, basename)
      end
    end
  end

  #
  # Create a temporary class with the given superclass.
  #
  def temporary_class(zuperclass=Object, &block)
    klass = Class.new(zuperclass)
    @temporary_modules << klass
    klass.class_eval(&block) if block
    klass
  end

  #
  # Create a temporary module with the given name.
  #
  def temporary_module(&block)
    mod = Module.new
    @temporary_modules << mod
    mod.module_eval(&block) if block
    mod
  end
end
