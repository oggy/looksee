module Looksee
  #
  # Represents the method lookup path of an object, as a list of
  # Entries.
  #
  class LookupPath
    def initialize(object)
      @object = object
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

    def find(name)
      entries.each do |entry|
        visibility = entry.methods[name] or
          next

        if visibility == :undefined
          return nil
        else
          return entry.module.instance_method(name)
        end
      end
      nil
    end

    #
    # Return a string showing the object's lookup path.
    #
    def inspect(options={})
      Inspector.new(self, options).inspect
    end

    private  # -------------------------------------------------------

    def create_entries
      seen = Set.new
      Looksee.adapter.lookup_modules(object).map do |mod|
        entry = Entry.new(mod, seen)
        seen += entry.methods.keys
        entry
      end
    end

    #
    # An entry in the LookupPath.
    #
    class Entry
      def initialize(mod, overridden)
        @module = mod
        @methods = find_methods
        @overridden = overridden
      end

      attr_reader :module, :methods

      def overridden?(name)
        @overridden.include?(name.to_s)
      end

      #
      # Yield each method in alphabetical order along with its
      # visibility (:public, :private, :protected, :undefined, or
      # :overridden).
      #
      def each(&block)
        @methods.sort.each(&block)
      end

      include Enumerable

      private  # -----------------------------------------------------

      def find_methods
        methods = {}
        [:public, :protected, :private, :undefined].each do |visibility|
          Looksee.adapter.send("internal_#{visibility}_instance_methods", @module).each do |method|
            methods[method.to_s] = visibility
          end
        end
        methods
      end
    end
  end
end
