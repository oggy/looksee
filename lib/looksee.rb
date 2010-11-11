require "rbconfig"
require File.dirname(__FILE__) + "/../ext/looksee/looksee.#{Config::CONFIG['DLEXT']}"

module Looksee
  class << self
    #
    # Return a collection of methods that +object+ responds to,
    # according to the options given.  The following options are
    # recognized:
    #
    # * +:public+ - include public methods
    # * +:protected+ - include protected methods
    # * +:private+ - include private methods
    # * +:undefined+ - include undefined methods (see Module#undef_method)
    # * +:overridden+ - include methods overridden by subclasses
    #
    # The default (if options is nil or omitted) is given by
    # #default_lookup_path_options.
    #
    def lookup_path(object, *options)
      normalized_options = Looksee.default_lookup_path_options.dup
      hash_options = options.last.is_a?(Hash) ? options.pop : {}
      options.each do |option|
        normalized_options[option] = true
      end
      normalized_options.update(hash_options)
      LookupPath.for(object, normalized_options)
    end

    #
    # The default options passed to lookup_path.
    #
    # Default: <tt>{:public => true, :protected => true, :undefined =>
    # true, :overridden => true}</tt>
    #
    attr_accessor :default_lookup_path_options

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

  self.default_lookup_path_options = {:public => true, :protected => true, :undefined => true, :overridden => true}
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
  autoload :VERSION, 'looksee/version'
end

require 'looksee/wirble_compatibility'
