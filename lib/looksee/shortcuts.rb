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

  #
  # Run Looksee.colors to return the current color mappings.
  #
  # (Added by Looksee.)
  #
  def lc
    Looksee.colors
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
