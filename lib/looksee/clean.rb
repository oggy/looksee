require "rbconfig"
require File.dirname(__FILE__) + "/../../ext/looksee/looksee.#{Config::CONFIG['DLEXT']}"

require 'set'

module Looksee
  class << self
    #
    # The default options passed to #ls.
    #
    # Default: <tt>[:public, :protected, :private, :undefined,
    # :overridden]</tt>
    #
    attr_accessor :default_specifiers

    #
    # The width to use for displaying output, when not available in
    # the COLUMNS environment variable.
    #
    # Default: 80
    #
    attr_accessor :default_width

    #
    # The default styles to use for the +inspect+ strings.
    #
    # This is a hash with keys:
    #
    # * :module
    # * :public
    # * :protected
    # * :private
    # * :undefined
    # * :overridden
    #
    # The values are format strings.  They should all contain a single
    # "%s", which is where the name is inserted.
    #
    # Default:
    #
    #       {
    #         :module     => "\e[1;37m%s\e[0m", # white
    #         :public     => "\e[1;32m%s\e[0m", # green
    #         :protected  => "\e[1;33m%s\e[0m", # yellow
    #         :private    => "\e[1;31m%s\e[0m", # red
    #         :undefined  => "\e[1;34m%s\e[0m", # blue
    #         :overridden => "\e[1;30m%s\e[0m", # black
    #       }
    #
    attr_accessor :styles

    #
    # Show a quick reference.
    #
    def help
      Help.new
    end

    #
    # Return the chain of classes and modules which comprise the
    # object's method lookup path.
    #
    def lookup_modules(object)
      modules = []
      klass = Looksee.internal_class(object)
      while klass
        modules << Looksee.internal_class_to_module(klass)
        klass = Looksee.internal_superclass(klass)
      end
      modules
    end
  end

  self.default_specifiers = [:public, :protected, :undefined, :overridden]
  self.default_width = 80
  self.styles = {
    :module     => "\e[1;37m%s\e[0m", # white
    :public     => "\e[1;32m%s\e[0m", # green
    :protected  => "\e[1;33m%s\e[0m", # yellow
    :private    => "\e[1;31m%s\e[0m", # red
    :undefined  => "\e[1;34m%s\e[0m", # blue
    :overridden => "\e[1;30m%s\e[0m", # black
  }

  autoload :LookupPath, 'looksee/lookup_path'
  autoload :Columnizer, 'looksee/columnizer'
  autoload :Help, 'looksee/help'
  autoload :VERSION, 'looksee/version'
end

require 'looksee/wirble_compatibility'
