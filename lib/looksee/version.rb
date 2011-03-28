module Looksee
  VERSION = [1, 0, 2]

  class << VERSION
    include Comparable

    def to_s
      join('.')
    end
  end
end
