module Looksee
  class LookupPath
    def initialize(entries)
      @entries = entries
    end

    #
    # List of Entry objects, each one representing a Module in the
    # lookup path.
    #
    attr_reader :entries

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
end
