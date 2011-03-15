module Looksee
  VERSION = [1, 0, 1]

  class << VERSION
    include Comparable

    def to_s
      join('.')
    end
  end
end
