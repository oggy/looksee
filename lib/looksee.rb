require "rbconfig"
require File.dirname(__FILE__) + "/../ext/looksee/looksee.#{Config::CONFIG['DLEXT']}"
require "looksee/version"

module Looksee
  class << self
    #
    # Return a collection of methods that +object+ responds to,
    # according to the options given.  The following options are
    # recognized:
    #
    # :public - include public methods
    # :protected - include protected methods
    # :private - include private methods
    # :all - same as [:public, :protected, :private]
    # :overridden - include methods overridden by subclasses
    #
    # The default (if options is nil or omitted) is [:public].
    #
    # Here's how ruby lookup works:
    #
    #        class: ++++>
    #   superclass: ---->
    #
    #             +--------+
    #             | Kernel |
    #             +--------+
    #                 ^              +--------------+
    #                 |              |              |
    #             +--------+    +----------+        |
    #             | Object |+++>| <Object> |++++    |
    #             +--------+    +----------+   +    |
    #                 ^              ^         +    |
    #                 |              |         +    |
    #             +--------+    +----------+   +    |
    #             | Module |+++>| <Module> |++++    |
    #             +--------+    +----------+   +    |
    #                 ^              ^         +    |
    #                 |              |         +    |
    #             +--------+    +----------+   +    |
    #     +------>| Class  |+++>| <Class>  |++++    |
    #     |   +==>+--------+    +----------+   +    |
    #     |   +       ^              ^         +    |
    #     |   +       |              |         +    |
    #     |   +   +--------+    +----------+   +    |
    #     |   +   |   C    |+++>|   <C>    |++++    |
    #     |   +   +--------+    +----------+   +    |
    #     |   +                                +    |
    #     |   ++++++++++++++++++++++++++++++++++    |
    #     |                                         |
    #     +-----------------------------------------+
    #
    # Adapted from:
    #   * http://phrogz.net/RubyLibs/RubyMethodLookupFlow.png
    #   * http://www.hokstad.com/ruby-object-model.html
    #   * The rdoc for the Object class.
    #
    def lookup_path(object, *options)
      normalized_options = Looksee.default_options.dup
      hash_options = options.last.is_a?(Hash) ? options.pop : {}
      options.each do |option|
        normalized_options[option] = true
      end
      normalized_options.update(hash_options)
      LookupPath.new(object, normalized_options)
    end

    attr_accessor :default_options
    attr_accessor :default_width
    attr_accessor :styles
  end

  self.default_options = {:public => true, :protected => true, :shadowed => true}
  self.default_width = 80
  self.styles = {
    :module    => "\e[1;37m%s\e[0m",
    :public    => "\e[1;32m%s\e[0m",
    :protected => "\e[1;33m%s\e[0m",
    :private   => "\e[1;31m%s\e[0m",
    :shadowed  => "\e[1;30m%s\e[0m",
  }

  class LookupPath
    attr_reader :entries

    def initialize(object, options={})
      @entries = []
      seen = {}
      find_modules(object).each do |mod|
        entry = Entry.new(mod, seen, options)
        entry.methods.each{|m| seen[m] = true}
        @entries << entry
      end
    end

    def inspect(options={})
      options = normalize_inspect_options(options)
      entries.map{|e| e.inspect(options)}.join
    end

    private  # -------------------------------------------------------

    def find_modules(object)
      modules = []
      klass = Looksee.internal_class(object)
      while klass
        modules << Looksee.internal_class_to_module(klass)
        klass = Looksee.internal_superclass(klass)
      end
      modules
    end

    def normalize_inspect_options(options)
      options[:width] ||= ENV['COLUMNS'].to_i.nonzero? || Looksee.default_width
      options
    end

    #
    # An entry in the LookupPath.
    #
    # Contains a module and its methods, along with access
    # information (public, private, etc.).
    #
    class Entry
      def initialize(mod, seen, options)
        @module = mod
        @methods = []
        @accesses = {}
        add_methods(mod.public_instance_methods(false)   , :public   , seen) if options[:public   ]
        add_methods(mod.protected_instance_methods(false), :protected, seen) if options[:protected]
        add_methods(mod.private_instance_methods(false)  , :private  , seen) if options[:private  ]
        @methods.sort!
      end

      attr_reader :module, :methods

      def module_name
        name = @module.to_s  # #name doesn't do singleton classes right
        nil while name.sub!(/#<Class:(.*)>/, '[\\1]')
        name
      end

      def each
        @methods.each do |name|
          yield name, @accesses[name]
        end
      end

      include Enumerable

      def inspect(options={})
        styled_module_name << "\n" << Columnizer.columnize(styled_methods, options[:width])
      end

      private  # -----------------------------------------------------

      def add_methods(methods, access, seen)
        methods.each do |method|
          @methods << method
          @accesses[method] = seen[method] ? :shadowed : access
        end
      end

      def styled_module_name
        Looksee.styles[:module] % module_name
      end

      def styled_methods
        map do |name, access|
          Looksee.styles[access] % name
        end
      end
    end
  end

  module Columnizer
    class << self
      def columnize(strings, width)
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
        widths.inject(0, :+) + 2*layout.length
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
