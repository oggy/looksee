require "rbconfig"
require File.dirname(__FILE__) + "/../ext/looksee/looksee.#{Config::CONFIG['DLEXT']}"
require "looksee/version"

#
# Looksee lets you inspect the method lookup path of an object.  There
# are two ways to use it:
#
# 1. Keep all methods contained in the Looksee namespace:
#
#     require 'looksee'
#
# 2. Let it all hang out:
#
#     require 'looksee/shortcuts'
#
# The latter adds the following shortcuts to the built-in classes:
#
#   Object#lookup_path
#   Object#dump_lookup_path
#   Object#lp
#   Object#lpi
#
# See their docs.
#
# == Usage
#
# In irb:
#
#     require 'looksee/shortcuts'
#     lp some_object
#
# +lp+ returns a LookupPath object, which has +inspect+ defined to
# print things out pretty.  By default, it shows public, protected,
# undefined, and overridden methods.  They're all colored, which makes
# showing overridden methods not such a strange idea.
#
# Some examples of the other shortcuts:
#
#     lpi Array
#     some_object.lookup_path
#     foo.bar.baz.dump_lookup_path.and.more
#
# If you're being namespace-clean, you'll need to do:
#
#     require 'looksee'
#     Looksee.lookup_path(thing)  # like "lp thing"
#
# For a quick reference:
#
#     Looksee.help
#
# == Configuration
#
# Set these:
#
#     Looksee.default_lookup_path_options
#     Looksee.default_width
#     Looksee.styles
#
# See their docs.
#
module Looksee
  class << self
    #
    # Return a collection of methods that +object+ responds to,
    # according to the options given.  The following options are
    # recognized:
    #
    # * +:public+ - include public methods
    # * +:protected+ - include protected methods
    # * +:private+ - include private methods
    # * +:undefined+ - include undefined methods (see Module#undef_method)
    # * +:overridden+ - include methods overridden by subclasses
    #
    # The default (if options is nil or omitted) is given by
    # #default_lookup_path_options.
    #
    def lookup_path(object, *options)
      normalized_options = Looksee.default_lookup_path_options.dup
      hash_options = options.last.is_a?(Hash) ? options.pop : {}
      options.each do |option|
        normalized_options[option] = true
      end
      normalized_options.update(hash_options)
      LookupPath.for(object, normalized_options)
    end

    #
    # The default options passed to lookup_path.
    #
    # Default: <tt>{:public => true, :protected => true, :undefined =>
    # true, :overridden => true}</tt>
    #
    attr_accessor :default_lookup_path_options

    #
    # The width to use for displaying output, when not available in
    # the COLUMNS environment variable.
    #
    # Default: 80
    #
    attr_accessor :default_width

    #
    # The default styles to use for the +inspect+ strings.
    #
    # This is a hash with keys:
    #
    # * :module
    # * :public
    # * :protected
    # * :private
    # * :undefined
    # * :overridden
    #
    # The values are format strings.  They should all contain a single
    # "%s", which is where the name is inserted.
    #
    # Default:
    #
    #       {
    #         :module     => "\e[1;37m%s\e[0m", # white
    #         :public     => "\e[1;32m%s\e[0m", # green
    #         :protected  => "\e[1;33m%s\e[0m", # yellow
    #         :private    => "\e[1;31m%s\e[0m", # red
    #         :undefined  => "\e[1;34m%s\e[0m", # blue
    #         :overridden => "\e[1;30m%s\e[0m", # black
    #       }
    #
    attr_accessor :styles

    #
    # Return the chain of classes and modules which comprise the
    # object's method lookup path.
    #
    def lookup_modules(object)
      modules = []
      klass = Looksee.internal_class(object)
      while klass
        modules << Looksee.internal_class_to_module(klass)
        klass = Looksee.internal_superclass(klass)
      end
      modules
    end
  end

  self.default_lookup_path_options = {:public => true, :protected => true, :undefined => true, :overridden => true}
  self.default_width = 80
  self.styles = {
    :module     => "\e[1;37m%s\e[0m", # white
    :public     => "\e[1;32m%s\e[0m", # green
    :protected  => "\e[1;33m%s\e[0m", # yellow
    :private    => "\e[1;31m%s\e[0m", # red
    :undefined  => "\e[1;34m%s\e[0m", # blue
    :overridden => "\e[1;30m%s\e[0m", # black
  }

  class LookupPath
    attr_reader :entries

    def initialize(entries)
      @entries = entries
    end

    #
    # Create a LookupPath for the given object.
    #
    # Options may be given to restrict which visibilities are
    # included.
    #
    #   :public
    #   :protected
    #   :private
    #   :undefined
    #   :overridden
    #
    def self.for(object, options={})
      entries = entries_for(object, options)
      new(entries)
    end

    #
    # Return a new LookupPath which only contains names matching the
    # given pattern.
    #
    def grep(pattern)
      entries = self.entries.map do |entry|
        entry.grep(pattern)
      end
      self.class.new(entries)
    end

    def inspect(options={})
      options = normalize_inspect_options(options)
      entries.map{|e| e.inspect(options)}.join("\n")
    end

    private  # -------------------------------------------------------

    def self.entries_for(object, options)
      seen = {}
      Looksee.lookup_modules(object).map do |mod|
        entry = Entry.for(mod, seen, options)
        entry.methods.each{|m| seen[m] = true}
        entry
      end
    end

    def normalize_inspect_options(options)
      options[:width] ||= ENV['COLUMNS'].to_i.nonzero? || Looksee.default_width
      options
    end

    #
    # An entry in the LookupPath.
    #
    # Contains a module and its methods, along with visibility
    # information (public, private, etc.).
    #
    class Entry
      def initialize(mod, methods=[], visibilities={})
        @module = mod
        @methods = methods
        @visibilities = visibilities
      end

      def self.for(mod, seen, options)
        entry = new(mod)
        entry.initialize_for(seen, options)
        entry
      end

      attr_reader :module, :methods

      def initialize_for(seen, options)
        add_methods(Looksee.internal_public_instance_methods(@module).map{|sym| sym.to_s}   , :public   , seen) if options[:public   ]
        add_methods(Looksee.internal_protected_instance_methods(@module).map{|sym| sym.to_s}, :protected, seen) if options[:protected]
        add_methods(Looksee.internal_private_instance_methods(@module).map{|sym| sym.to_s}  , :private  , seen) if options[:private  ]
        add_methods(Looksee.internal_undefined_instance_methods(@module).map{|sym| sym.to_s}, :undefined, seen) if options[:undefined]
        @methods.sort!
      end

      def grep(pattern)
        methods = []
        visibilities = {}
        @methods.each do |name|
          if name[pattern]
            methods << name
            visibilities[name] = @visibilities[name]
          end
        end
        self.class.new(@module, methods, visibilities)
      end

      #
      # Return the name of the class or module.
      #
      # Singleton classes are displayed in brackets.  Singleton class
      # of singleton classes are displayed in double brackets.  But
      # you'd never need that, would you?
      #
      def module_name
        name = @module.to_s  # #name doesn't do singleton classes right
        nil while name.sub!(/#<Class:(.*)>/, '[\\1]')
        name
      end

      #
      # Yield each method along with its visibility (:public,
      # :private, :protected, :undefined, or :overridden).
      #
      def each
        @methods.each do |name|
          yield name, @visibilities[name]
        end
      end

      include Enumerable

      #
      # Return a nice, pretty string for inspection.
      #
      # Contains the module name, plus the method names laid out in
      # columns.  Pass a :width option to control the output width.
      #
      def inspect(options={})
        string = styled_module_name << "\n" << Columnizer.columnize(styled_methods, options[:width])
        string.chomp
      end

      private  # -----------------------------------------------------

      def add_methods(methods, visibility, seen)
        methods.each do |method|
          @methods << method
          @visibilities[method] = seen[method] ? :overridden : visibility
        end
      end

      def styled_module_name
        Looksee.styles[:module] % module_name
      end

      def styled_methods
        map do |name, visibility|
          Looksee.styles[visibility] % name
        end
      end
    end
  end

  autoload :Columnizer, 'looksee/columnizer'
end

require 'looksee/wirble_compatibility'
