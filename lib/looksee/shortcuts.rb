=begin

Include this to pollute the standard ruby modules with handy aliases.
Perfect for your .irbrc, or for punching into your program to work out
what that +flazbot+ variable can do.

=end

require 'looksee'

class Object
  private  # ---------------------------------------------------------

  #
  # Alias for Looksee.lookup_path.
  #
  # (Added by Looksee.)
  #
  def lp(*args)
    Looksee.lookup_path(*args)
  end

  #
  # Run Looksee.lookup_path on an instance of the given class.
  #
  # (Added by Looksee.)
  #
  def lpi(klass, *args)
    Looksee.lookup_path(klass.allocate, *args)
  end

  public  # ----------------------------------------------------------

  #
  # Call Looksee.lookup_path on this object.
  #
  # (Added by Looksee.)
  #
  def lookup_path(*args)
    Looksee.lookup_path(self, *args)
  end

  #
  # Dump the lookup path to standard output, and return self.
  #
  # Good for stuffing in a call chain.
  #
  # (Added by Looksee.)
  #
  def dump_lookup_path(*args)
    p lookup_path(*args)
    self
  end
end

module Looksee
  #
  # Show a quick reference.
  #
  def self.help
    Help.new
  end

  class Help
    def inspect
      <<-EOS.gsub(/^ *\|/, '')
        |== Looksee Quick Reference
        |
        |  lp(object)
        |  object.lookup_path
        |    Print the method lookup path of \`object\'
        |
        |  lpi(klass)
        |    Print the method lookup path of an instance of \`klass\'.
        |
        |Add .grep(/pattern/) to restrict the methods listed:
        |
        |  lp(object).grep(/foo/)
        |
        |== Visibilities
        |
        |Methods are printed according to their visibility:
        |
        |#{style_info}
        |
        |Pass options to specify which visibilities to show:
        |
        |  lp(object, :private => true, :overridden => false)
        |  lp(object, :private        , :overridden => false)  # shortcut
      EOS
    end

    def style_info
      max_width = 0
      styles = [:public, :protected, :private, :undefined, :overridden]
      data = styles.map do |name|
        display_style = Looksee.styles[name] % name
        display_length = display_style.length
        max_width = display_length if display_length > max_width
        on = Looksee.default_lookup_path_options[name] ? 'on' : 'off'
        [display_style, on]
      end.map do |display_style, on|
        "  * #{display_style.ljust(max_width)}  (#{on} by default)"
      end.join("\n")
    end
  end
end
