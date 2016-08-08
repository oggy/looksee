require 'looksee/adapter/base'
require 'looksee/rbx'

module Looksee
  module Adapter
    class Rubinius < Base
      def internal_undefined_instance_methods(mod)
        return [] if !mod.origin.equal?(mod)
        names = []
        mod.method_table.entries.each do |(name, method, visibility)|
          names << name if visibility.equal?(:undef)
        end
        names
      end

      def singleton_instance(singleton_class)
        if Class === singleton_class && (instance = ::Rubinius::Type.singleton_class_object(singleton_class))
          instance
        else
          nil
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
