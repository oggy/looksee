module Looksee
  module ObjectMixin
    #
    # Define #ls as a shortcut for Looksee[self, *args].
    #
    # This is defined via method_missing to be less intrusive. pry 0.10, e.g.,
    # relies on Object#ls not existing.
    #
    def method_missing(name, *args)
      if name == :ls
        Looksee[self, *args]
      else
        super
      end
    end

    def respond_to?(name, include_private=false)
      super || name == :ls
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
