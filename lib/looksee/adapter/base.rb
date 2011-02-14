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
          modules << internal_class_to_module(klass)
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

        if object.is_a?(Module)
          description = module_name(object)
          if description.empty?
            description = "unnamed #{object.is_a?(Class) ? 'Class' : 'Module'}"
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

      def internal_superclass(klass)
        raise NotImplementedError, "abstract"
      end

      def internal_class(object)
        raise NotImplementedError, "abstract"
      end

      def internal_class_to_module(internal_class)
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

      if RUBY_VERSION >= '1.9.0' || Looksee.ruby_engine == 'rbx'
        def source_location(method)
          method.is_a?(UnboundMethod) or
            raise TypeError, "expected UnboundMethod, got #{method.class}"
          method.source_location
        end
      else
        def source_location(method)
          raise NotImplementedError, 'abstract'
        end
      end
    end
  end
end
