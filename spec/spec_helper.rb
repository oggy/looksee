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
        Object.send :remove_const, mod.name
      end
    end
  end

  #
  # Create a temporary class with the given name and superclass.
  #
  def temporary_class(name, superclass=Object, &block)
    klass = Class.new(superclass)
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
end
