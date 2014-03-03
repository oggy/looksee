module Looksee
  module ObjectMixin
    #
    # Shortcut for Looksee[self, *args].
    #
    def ls(*args)
      Looksee[self, *args]
    end

    def self.rename(name)  # :nodoc:
      name = name[:ls] if name.is_a?(Hash)
      alias_method name, :ls
      remove_method :ls
    end
  end

  #
  # Rename the #ls method, added to every object. Example:
  #
  #     rename :_ls
  #
  # This renames Looksee's #ls method to #_ls.
  #
  # For backward compatibility, the old-style invocation is also
  # supported. Please note this is deprecated.
  #
  #     rename :ls => :_ls
  #
  def self.rename(name)
    ObjectMixin.rename(name)
  end

  name = ENV['LOOKSEE_METHOD'] and
    rename name

  Object.send :include, ObjectMixin
end
