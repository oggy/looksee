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
# and overridden methods.  They're all colored, which makes showing
# overridden methods not such a strange idea.
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
    # * +:overridden+ - include methods overridden by subclasses
    #
    # The default (if options is nil or omitted) is [:public].
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
    # Default: <tt>{:public => true, :protected => true, :overridden => true}</tt>
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
    # * :overridden
    #
    # The values are format strings.  They should all contain a single
    # "%s", which is where the name is inserted.
    #
    # Default:
    #
    #       {
    #         :module     => "\e[1;37m%s\e[0m",
    #         :public     => "\e[1;32m%s\e[0m",
    #         :protected  => "\e[1;33m%s\e[0m",
    #         :private    => "\e[1;31m%s\e[0m",
    #         :overridden => "\e[1;30m%s\e[0m",
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

  self.default_lookup_path_options = {:public => true, :protected => true, :overridden => true}
  self.default_width = 80
  self.styles = {
    :module     => "\e[1;37m%s\e[0m",
    :public     => "\e[1;32m%s\e[0m",
    :protected  => "\e[1;33m%s\e[0m",
    :private    => "\e[1;31m%s\e[0m",
    :overridden => "\e[1;30m%s\e[0m",
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
      entries.map{|e| e.inspect(options)}.join
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
      # :private, :protected, or :overridden).
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
        styled_module_name << "\n" << Columnizer.columnize(styled_methods, options[:width])
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

  module Columnizer
    class << self
      #
      # Arrange the given strings in columns, restricted to the given
      # width.  Smart enough to ignore content in terminal control
      # sequences.
      #
      def columnize(strings, width)
        return '' if strings.empty?

        num_columns = 1
        layout = [strings]
        loop do
          break if layout.first.length <= 1
          next_layout = layout_in_columns(strings, num_columns + 1)
          break if layout_width(next_layout) > width
          layout = next_layout
          num_columns += 1
        end

        pad_strings(layout)
        rectangularize_layout(layout)
        layout.transpose.map do |row|
          '  ' + row.compact.join('  ')
        end.join("\n") << "\n"
      end

      private  # -----------------------------------------------------

      def layout_in_columns(strings, num_columns)
        strings_per_column = (strings.length / num_columns.to_f).ceil
        (0...num_columns).map{|i| strings[i*strings_per_column...(i+1)*strings_per_column] || []}
      end

      def layout_width(layout)
        widths = layout_column_widths(layout)
        widths.inject(0){|sum, w| sum + w} + 2*layout.length
      end

      def layout_column_widths(layout)
        layout.map do |column|
          column.map{|string| display_width(string)}.max || 0
        end
      end

      def display_width(string)
        # remove terminal control sequences
        string.gsub(/\e\[.*?m/, '').length
      end

      def pad_strings(layout)
        widths = layout_column_widths(layout)
        layout.each_with_index do |column, i|
          column_width = widths[i]
          column.each do |string|
            padding = column_width - display_width(string)
            string << ' '*padding
          end
        end
      end

      def rectangularize_layout(layout)
        return if layout.length == 1
        height = layout[0].length
        layout[1..-1].each do |column|
          column.length == height or
            column[height - 1] = nil
        end
      end
    end
  end
end

require 'looksee/wirble_compatibility'
