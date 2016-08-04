module Looksee
  module Adapter
    class Base
      #
      # Return the chain of classes and modules which comprise the
      # object's method lookup path.
      #
      def lookup_modules(object)
        modules = []
        klass = internal_class(object)
        while klass
          modules << klass
          klass = internal_superclass(klass)
        end
        modules
      end

      #
      # Return a description of the given module.
      #
      # This is used for the module labels in the Inspector output.
      #
      def describe_module(mod)
        num_brackets = 0
        object = mod
        while singleton_class?(object)
          num_brackets += 1
          object = singleton_instance(object)
        end

        if included_class?(mod) || object.is_a?(Module)
          description = module_name(object)
          if description.empty?
            is_class = real_module(object).is_a?(Class)
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

      def real_module(module_or_included_class)
        module_or_included_class
      end

      def internal_superclass(klass)
        raise NotImplementedError, "abstract"
      end

      def internal_class(object)
        raise NotImplementedError, "abstract"
      end

      def included_class?(object)
        raise NotImplementedError, "abstract"
      end

      def internal_public_instance_methods(mod)
        raise NotImplementedError, "abstract"
      end

      def internal_protected_instance_methods(mod)
        raise NotImplementedError, "abstract"
      end

      def internal_private_instance_methods(mod)
        raise NotImplementedError, "abstract"
      end

      def internal_undefined_instance_methods(mod)
        raise NotImplementedError, "abstract"
      end

      def singleton_class?(object)
        raise NotImplementedError, "abstract"
      end

      def singleton_instance(singleton_class)
        raise NotImplementedError, "abstract"
      end

      def module_name(mod)
        raise NotImplementedError, "abstract"
      end

      def source_location(method)
        method.is_a?(UnboundMethod) or
          raise TypeError, "expected UnboundMethod, got #{method.class}"
        method.source_location
      end
    end
  end
end
