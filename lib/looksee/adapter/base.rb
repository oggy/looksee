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
    end
  end
end
