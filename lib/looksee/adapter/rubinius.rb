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
    end
  end
end
