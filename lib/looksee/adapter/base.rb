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

      if RUBY_VERSION >= '1.9.0'
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
