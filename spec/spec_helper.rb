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
      @temporary_names = []
    end

    mod.after do
      @temporary_names.each{|name| Object.send(:remove_const, name)}
    end
  end

  #
  # Create a temporary class with the given name.
  #
  # If a :super option is given (a class), that class is set as the
  # superclass.
  #
  # If an :include option is given (an Array of Modules), those
  # modules are included.
  #
  # If :public, :protected, or :private options are given (Arrays of
  # Symbols), empty methods are defined with the corresponding
  # visibility.
  #
  def make_class(name, options={})
    klass = Class.new(options[:super] || Object)
    set_temporary_module(name, klass, options)
  end

  #
  # Create a temporary module with the given name.
  #
  # If an :include option is given (an Array of Modules), those
  # modules are included, one at a time, in that order.
  #
  # If :public, :protected, or :private options are given (Arrays of
  # Symbols), empty methods are defined with the corresponding
  # visibility.
  #
  def make_module(name, options={})
    mod = Module.new
    set_temporary_module(name, mod, options)
  end

  def set_temporary_module(name, mod, options={})
    [:public, :protected, :private].each do |visibility|
      options[visibility] or
        next
      method_names = options[visibility]
      method_names.each{ |n| mod.define_method(n){} }
      mod.send(visibility, *method_names)
    end
    if options[:include]
      options[:include].each do |included|
        mod.send :include, included
      end
    end
    @temporary_names << name
    Object.const_set(name, mod)
  end
end
