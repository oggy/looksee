require 'spec'
require 'mocha'
require 'looksee'

Spec::Runner.configure do |config|
  config.mock_with :mocha
end

class Object
  #
  # Return this object's singleton class.
  #
  def singleton_class
    class << self; self; end
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
