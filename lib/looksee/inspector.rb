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

    def inspect
      lookup_path.entries.reverse.map do |entry|
        inspect_entry(entry)
      end.join("\n")
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
