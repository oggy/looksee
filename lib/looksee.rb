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
    def looksee(object, options=nil)
      classes = []
      klass = internal_class(object)
      while klass
        classes << internal_class_to_module(klass)
        klass = internal_superclass(klass)
      end
      LookupPath.new(classes, options)
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
    def initialize(modules, *options)
      @options = normalize_initialize_options(options)
      @modules = modules
    end

    def normalize_initialize_options(options)
      normalized_options = Looksee.default_options.dup
      hash_options = options.last.is_a?(Hash) ? options.pop : {}
      options.each do |option|
        normalized_options[option] = true
      end
      normalized_options.update(hash_options)
    end

    attr_reader :modules, :options

    def inspect(options={})
      options = normalize_inspect_options(options)
      data = inspect_data
      lines = layout(options[:width], data)
      lines.join("\n") << "\n"
    end

    def normalize_inspect_options(options)
      options[:width] ||= ENV['COLUMNS'].to_i.nonzero? || Looksee.default_width
      options
    end

    #
    # Return the entries to display.
    #
    # Return value is a structure of the following grammatical form:
    #
    #   [
    #     [styled module name, [method-entry, method-entry, ...]],
    #     [styled module name, [method-entry, method-entry, ...]],
    #     ...
    #   ]
    #
    # where each method-entry is a triple that contains:
    #
    #   [name, styled name, display width]
    #
    def inspect_data
      styles = Looksee.styles
      style_widths = Hash.new{|h,k| h[k] = display_width(styles[k] % '')}
      make_entry = lambda do |name, style_name|
        [name, styles[style_name] % name, style_widths[style_name] + name.length]
      end

      seen = {}
      @modules.map do |mod|
        entries = []
        [:public, :protected, :private].each do |access|
          next if !options[access]
          mod.send("#{access}_instance_methods", false).each do |name|
            name = name.to_s
            if seen[name]
              options[:shadowed] or
                next
              entries << make_entry.call(name, :shadowed)
            else
              entries << make_entry.call(name, access)
              seen[name] = true
            end
          end
        end
        mod_name = mod.to_s
        nil while mod_name.sub!(/#<Class:(.*)>/, '[\\1]')
        [styles[:module] % mod_name, entries.sort!]
      end
    end

    def display_width(string)
      # remove terminal control sequences
      string.gsub(/\e\[.*?m/, '').length
    end

    #
    # Return whether the modules should be on a separate line, and the
    # list of column widths to display the strings in.
    #
    def layout(width, data)
      lines = []
      data.map do |styled_module_name, method_entries|
        lines << styled_module_name
        lines.concat layout_methods(width, method_entries)
      end
      lines
    end

    def layout_methods(width, entries)
      num_columns = 1
      layout = [entries]
      loop do
        break if layout.first.length <= 1
        next_layout = layout_methods_in_columns(entries, num_columns + 1)
        break if layout_width(next_layout) > width
        layout = next_layout
        num_columns += 1
      end

      create_display_strings(layout)
      rectangularize_layout(layout)
      layout.transpose.map do |row|
        '  ' + row.compact.join('  ')
      end
    end

    def layout_methods_in_columns(entries, num_columns)
      entries_per_column = (entries.length / num_columns.to_f).ceil
      (0...num_columns).map{|i| entries[i*entries_per_column...(i+1)*entries_per_column] || []}
    end

    def layout_width(layout)
      widths = layout_column_widths(layout)
      widths.inject(0, :+) + 2*widths.length
    end

    def layout_column_widths(layout)
      widths = layout.map do |column|
        column.map{|entry| entry[2]}.max || 0
      end
    end

    def create_display_strings(layout)
      widths = layout_column_widths(layout)
      widths.length.times do |i|
        column_width = widths[i]
        layout[i].map! do |entry|
          padding = column_width - entry[2]
          entry[1] + ' '*padding
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
