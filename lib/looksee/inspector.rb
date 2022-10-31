module Looksee
  class Inspector
    def initialize(lookup_path, options={})
      @lookup_path = lookup_path
      @visibilities = (vs = options[:visibilities]) ? vs.to_set : Set[]
      @filters = (fs = options[:filters]) ? fs.to_set : Set[]
      @width = options[:width] || ENV['COLUMNS'].to_i.nonzero? || Looksee.default_width
    end

    attr_reader :lookup_path
    attr_reader :visibilities
    attr_reader :filters

    #
    # Print the method lookup path of self. See the README for details.
    #
    def inspect
      lookup_path.entries.reverse.map do |entry|
        inspect_entry(entry)
      end.join("\n")
    end

    def pretty_print(pp)
      # In the default IRB inspect mode (pp), IRB assumes that an inspect string
      # that doesn't look like a bunch of known patterns is a code blob, and
      # formats accordingly. That messes up our color escapes.
      if Object.const_defined?(:IRB) && IRB.const_defined?(:ColorPrinter) && pp.is_a?(IRB::ColorPrinter)
        PP.instance_method(:text).bind(pp).call(inspect)
      else
        pp.text(inspect)
      end
    end

    #
    # Open an editor at the named method's definition.
    #
    # Uses Looksee.editor to determine the editor command to run.
    #
    # Only works for methods for which file and line numbers are
    # accessible.
    #
    def edit(name)
      Editor.new(Looksee.editor).edit(lookup_path.object, name)
    end

    private

    def inspect_entry(entry)
      string = styled_module_name(entry) << "\n"
      string << Columnizer.columnize(styled_methods(entry), @width)
      string.chomp
    end

    def styled_module_name(entry)
      Looksee.styles[:module] % Looksee.adapter.describe_module(entry.module)
    end

    def styled_methods(entry)
      pattern = filter_pattern
      show_overridden = @visibilities.include?(:overridden)
      entry.map do |name, visibility|
        next if !selected?(name, visibility)
        style = entry.overridden?(name) ? :overridden : visibility
        next if style == :overridden && !show_overridden
        Looksee.styles[style] % name
      end.compact
    end

    def filter_pattern
      strings = filters.grep(String)
      regexps = filters.grep(Regexp)
      string_patterns = strings.map{|s| Regexp.escape(s)}
      regexp_patterns = regexps.map{|s| s.source}
      /#{(string_patterns + regexp_patterns).join('|')}/
    end

    def selected?(name, visibility)
      @visibilities.include?(visibility) && name =~ filter_pattern
    end
  end
end
