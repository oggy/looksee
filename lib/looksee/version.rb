module Looksee
  VERSION = [3, 1, 0]

  class << VERSION
    include Comparable

    def to_s
      join('.')
    end
  end
end
