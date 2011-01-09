module Looksee
  module WirbleCompatibility
    class << self
      def wirble_loaded?
        Object.const_defined?(:Wirble) &&
          Wirble.is_a?(Module) &&
          Wirble.respond_to?(:colorize)
      end

      def wirble_colorizing?
        require 'irb'
        IRB::Irb.method_defined?(:non_color_output_value)
      end

      def hook_into_wirble_load
        unless Object.const_defined?(:Wirble)
          Object.const_set :Wirble, Module.new
        end
        Wirble.send :extend, WirbleLoadHook
      end

      def hook_into_wirble_colorize
        class << Wirble
          def colorize_with_looksee(*args)
            # If this gets called twice, Wirble will fuck up the
            # aliases.  Disable colorizing first to reset them.
            if WirbleCompatibility.hooked_into_irb_output_value?
              Wirble::Colorize.disable
            end
            colorize_without_looksee(*args)
            WirbleCompatibility.hook_into_irb_output_value
          end

          alias colorize_without_looksee colorize
          alias colorize colorize_with_looksee
        end
      end

      def hook_into_irb_output_value
        IRB::Irb.class_eval do
          def output_value_with_looksee
            case @context.last_value
            when Looksee::Inspector, Looksee::Help
              non_color_output_value
            else
              output_value_without_looksee
            end
          end

          alias output_value_without_looksee output_value
          alias output_value output_value_with_looksee
        end
      end

      def hooked_into_irb_output_value?
        IRB::Irb.method_defined?(:output_value_with_looksee)
      end

      def init
        #
        # How wirble is used:
        #
        #  * Wirble is required/loaded.  Defines Wirble module, with methods like Wirble.colorize.
        #  * Wirble.init is called.  Nothing interesting.
        #  * Wirble.colorize is called.  Hooks into IRB::Irb.output_value via an alias.
        #
        if !wirble_loaded?
          hook_into_wirble_load
        elsif !wirble_colorizing?
          hook_into_wirble_colorize
        else
          hook_into_irb_output_value
        end
      end
    end

    module WirbleLoadHook
      def singleton_method_added(name)
        if name == :colorize && !respond_to?(:colorize_with_looksee)
          WirbleCompatibility.hook_into_wirble_colorize
        end
        super
      end
    end
  end
end
