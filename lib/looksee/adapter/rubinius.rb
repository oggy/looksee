require 'looksee/adapter/base'
require 'looksee/rbx'

module Looksee
  module Adapter
    class Rubinius < Base
      def internal_superclass(klass)
        klass.direct_superclass
      end

      def internal_public_instance_methods(mod)
        return [] if !mod.origin.equal?(mod)
        mod.method_table.public_names
      end

      def internal_protected_instance_methods(mod)
        return [] if !mod.origin.equal?(mod)
        mod.method_table.protected_names
      end

      def internal_private_instance_methods(mod)
        return [] if !mod.origin.equal?(mod)
        mod.method_table.private_names
      end

      def internal_undefined_instance_methods(mod)
        return [] if !mod.origin.equal?(mod)
        names = []
        mod.method_table.entries.each do |(name, method, visibility)|
          names << name if visibility.equal?(:undef)
        end
        names
      end

      def included_class?(object)
        object.is_a?(::Rubinius::IncludedModule)
      end

      def singleton_class?(object)
        object.is_a?(Class) && !!::Rubinius::Type.singleton_class_object(object)
      end

      def singleton_instance(singleton_class)
        singleton_class?(singleton_class) or
          raise TypeError, "expected singleton class, got #{singleton_class.class}"
        ::Rubinius::Type.singleton_class_object(singleton_class)
      end

      def module_name(mod)
        mod.is_a?(Module) or
          raise TypeError, "expected module, got #{mod.class}"

        if ::Rubinius::IncludedModule === mod
          if Class === mod.module
            "#{module_name(mod.module)} (origin)"
          else
            "#{module_name(mod.module)} (included)"
          end
        elsif ::Rubinius::Type.respond_to?(:module_name)
          ::Rubinius::Type.module_name(mod) || ''
        else
          mod.__name__
        end
      end

      def source_location(method)
        method.is_a?(UnboundMethod) or
          raise TypeError, "expected UnboundMethod, got #{method.class}"
        source_location = method.source_location and
          return source_location

        # #source_location doesn't always work. If it returns nil, try
        # a little harder.
        case (executable = method.executable)
        when ::Rubinius::BlockEnvironment::AsMethod
          method = executable.instance_variable_get(:@block_env).method
          [method.file.to_s, method.lines[1]]
        when ::Rubinius::DelegatedMethod
          executable.instance_variable_get(:@receiver).source_location
        end
      end
    end
  end
end
