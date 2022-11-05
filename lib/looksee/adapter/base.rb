module Looksee
  module Adapter
    class Base
      #
      # Return the chain of classes and modules which comprise the
      # object's method lookup path.
      #
      def lookup_modules(object)
        start =
          begin
            singleton_class = (class << object; self; end)
            singleton_class unless has_no_methods?(singleton_class) && includes_no_modules?(singleton_class) && !(Class === object)
          rescue TypeError  # immediate object
          end
        start ||= Looksee.safe_call(Object, :class, object)
        Looksee.safe_call(Module, :ancestors, start)
      end

      #
      # Return a description of the given module.
      #
      # This is used for the module labels in the Inspector output.
      #
      def describe_module(mod)
        Module === mod or
          raise TypeError, "expected Module, got: #{mod.inspect}"
        num_brackets = 0
        object = mod
        while (instance = singleton_instance(object))
          num_brackets += 1
          object = instance
        end

        if object.is_a?(Module)
          description = module_name(object)
          if description.empty?
            is_class = Class === object
            description = "unnamed #{is_class ? 'Class' : 'Module'}"
          end
        else
          description = "#{module_name(object.class)} instance"
        end

        if num_brackets == 0
          description
        else
          "#{'['*num_brackets}#{description}#{']'*num_brackets}"
        end
      end

      def undefined_instance_methods(mod)
        if Module.method_defined?(:undefined_instance_methods)
          mod.undefined_instance_methods
        else
          internal_undefined_instance_methods(mod)
        end
      end

      def internal_undefined_instance_methods(mod)
        raise NotImplementedError, "abstract"
      end

      def has_no_methods?(mod)
        [:public, :protected, :private].all? do |visibility|
          Looksee.safe_call(Module, "#{visibility}_instance_methods", mod, false).empty?
        end && undefined_instance_methods(mod).empty?
      end

      def includes_no_modules?(klass)
        ancestors = Looksee.safe_call(Module, :ancestors, klass)
        ancestors.size == 1 ||
          klass.included_modules == klass.ancestors[1].included_modules
      end

      def singleton_instance(singleton_class)
        raise NotImplementedError, "abstract"
      end

      def module_name(mod)
        Looksee.safe_call(Module, :name, mod) || ''
      end
    end
  end
end
