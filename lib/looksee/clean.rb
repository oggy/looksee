require "rbconfig"

require 'set'

module Looksee
  autoload :VERSION, 'looksee/version'
  autoload :Adapter, 'looksee/adapter'
  autoload :Columnizer, 'looksee/columnizer'
  autoload :Editor, 'looksee/editor'
  autoload :Help, 'looksee/help'
  autoload :Inspector, 'looksee/inspector'
  autoload :LookupPath, 'looksee/lookup_path'
  autoload :WirbleCompatibility, 'looksee/wirble_compatibility'

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
    # The editor command, used for Object#edit.
    #
    # This string should contain a "%f", which is replaced with the
    # file name, and/or "%l" which is replaced with the line number. A
    # "%%" is replaced with "%".
    #
    # If the LOOKSEE_EDITOR environment variable is set, it is used as
    # the default. Otherwise, we use the following heuristic:
    #
    # If EDITOR is set, we use that. If it looks like vi, emacs, or
    # textmate, we also append options to position the cursor on the
    # appropriate line. If EDITOR is not set, we use "vi +%l %f".
    #
    attr_accessor :editor

    #
    # The interpreter adapter.
    #
    # Encapsulates the interpreter-specific functionality.
    #
    attr_accessor :adapter

    #
    # Wrapper around RUBY_ENGINE that's always defined.
    #
    attr_accessor :ruby_engine

    #
    # Show a quick reference.
    #
    def help
      Help.new
    end
  end

  self.default_specifiers = [:public, :protected, :private, :undefined, :overridden]
  self.default_width = 80
  self.styles = {
    :module     => "\e[1;37m%s\e[0m", # white
    :public     => "\e[1;32m%s\e[0m", # green
    :protected  => "\e[1;33m%s\e[0m", # yellow
    :private    => "\e[1;31m%s\e[0m", # red
    :undefined  => "\e[1;34m%s\e[0m", # blue
    :overridden => "\e[1;30m%s\e[0m", # black
  }
  self.editor = ENV['LOOKSEE_EDITOR'] || ENV['EDITOR'] || 'vi'

  if Object.const_defined?(:RUBY_ENGINE)
    self.ruby_engine = RUBY_ENGINE
  else
    self.ruby_engine = 'ruby'
  end

  case ruby_engine
  when 'jruby'
    self.adapter = Adapter::JRuby.new
  when 'rbx'
    self.adapter = Adapter::Rubinius.new
  else
    self.adapter = Adapter::MRI.new
  end
end
