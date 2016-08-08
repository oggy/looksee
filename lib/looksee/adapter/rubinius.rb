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
    end
  end
end
