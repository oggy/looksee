require 'looksee/adapter/base'
require 'looksee/rbx'

module Looksee
  module Adapter
    class Rubinius < Base
      def internal_superclass(klass)
        klass.direct_superclass
      end

      def internal_class_to_module(internal_class)
        if internal_class.is_a?(::Rubinius::IncludedModule)
          internal_class.module
        else
          internal_class
        end
      end

      def internal_public_instance_methods(mod)
        mod.method_table.public_names
      end

      def internal_protected_instance_methods(mod)
        mod.method_table.protected_names
      end

      def internal_private_instance_methods(mod)
        mod.method_table.private_names
      end

      def internal_undefined_instance_methods(mod)
        names = []
        mod.method_table.each_entry do |entry|
          names << entry.name if entry.visibility.equal?(:undef)
        end
        names
      end

      def singleton_class?(object)
        object.is_a?(Class) && object.__metaclass_object__
      end

      def singleton_instance(singleton_class)
        singleton_class?(singleton_class) or
          raise TypeError, "expected singleton class, got #{singleton_class.class}"
        singleton_class.__metaclass_object__
      end

      def module_name(mod)
        mod.is_a?(Module) or
          raise TypeError, "expected module, got #{mod.class}"
        mod.__name__
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
