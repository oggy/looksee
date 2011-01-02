require 'set'

module Looksee
  class LookupPath
    def initialize(object, options={})
      @object = object
      @visibilities = (vs = options[:visibilities]) ? vs.to_set : Set[]
      @filters = (fs = options[:filters]) ? fs.to_set : Set[]
      @entries = create_entries
    end

    #
    # The object this lookup path represents.
    #
    attr_reader :object

    #
    # List of Entry objects, each one representing a Module in the
    # lookup path.
    #
    attr_reader :entries

    #
    # Set of visibilities to display.
    #
    attr_reader :visibilities

    #
    # Set of filters to use on method lists (Strings or Regexps).
    #
    attr_reader :filters

    #
    # Return a new LookupPath which only contains names matching the
    # given pattern.
    #
    def grep(pattern)
      dup.send(:add_filter, pattern)
    end

    def inspect(options={})
      options = normalize_inspect_options(options)
      entries.map{|e| e.inspect(options)}.join("\n")
    end

    private  # -------------------------------------------------------

    def add_filter(pattern)
      @filters += [pattern]
      @entries = create_entries
    end

    def create_entries
      seen = Set.new
      Looksee.lookup_modules(object).map do |mod|
        entry = Entry.new(mod, seen, @visibilities, @filters)
        seen.merge(entry.methods)
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
    class Entry
      def initialize(mod, overridden, visibilities, filters)
        @module = mod
        @visibilities = {}
        @methods = find_methods(overridden, visibilities, filters)
      end

      attr_reader :module, :methods, :visibilities

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
        string = styled_module_name << "\n" << Columnizer.columnize(styled_methods, options[:width] || Looksee.default_width)
        string.chomp
      end

      private  # -----------------------------------------------------

      def find_methods(overridden, visibilities, filters)
        methods = []
        include_overridden = visibilities.include?(:overridden)
        [:public, :protected, :private, :undefined].each do |visibility|
          visibilities.include?(visibility) or
            next
          Looksee.send("internal_#{visibility}_instance_methods", @module).map{|sym| sym.to_s}.each do |method|
            if filters.all?{|f| method[f]} && (include_overridden || !overridden.include?(method))
              methods << method
              @visibilities[method] = overridden.include?(method) ? :overridden : visibility
            end
          end
        end
        methods.sort!
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
end
