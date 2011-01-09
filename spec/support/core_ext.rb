class Object
  #
  # Return this object's singleton class.
  #
  def singleton_class
    class << self; self; end
  end

  #
  # Return true if the given object include?-s this object.
  #
  def in?(object)
    object.include?(self)
  end
end

class String
  #
  # Remove a left margin delimited by '|'-characters.  Useful for
  # heredocs:
  #
  def demargin
    gsub(/^ *\|/, '')
  end
end
