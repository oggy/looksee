module Looksee
  module ObjectMixin
    #
    # Shortcut for Looksee[self, *args].
    #
    def look(*args)
      Looksee[self, *args]
    end

    def self.rename(name)  # :nodoc:
      if name.is_a?(Hash)
        warning = "You have renamed Looksee's method with Looksee.rename(#{name.inspect}).\n\n" +
                  "Looksee now uses #look instead of #ls."
        if name[:ls].to_s == 'look'
          warn warning << " You can remove this customization."
        elsif name[:ls]
          warn warning << " Please rename with Looksee.rename(#{name[:ls].inspect}), or remove this customization."
        end
      elsif name.to_s == 'look'
        warn warning << " You can remove this customization."
      end

      name = name[:look] || name[:ls] if name.is_a?(Hash)
      alias_method name, :look
      remove_method :look
    end
  end

  #
  # Rename the #look method, added to every object. Example:
  #
  #     rename :_look
  #
  # This renames Looksee's #look method to #_look.
  #
  # For backward compatibility, the old-style invocation is also
  # supported. This is deprecated, and will shortly be removed.
  #
  #     rename :look => :_look
  #
  def self.rename(name)
    ObjectMixin.rename(name)
  end

  name = ENV['LOOKSEE_METHOD'] and
    rename name

  Object.send :include, ObjectMixin
end
