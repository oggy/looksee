module Looksee
  VERSION = [2, 1, 0]

  class << VERSION
    include Comparable

    def to_s
      join('.')
    end
  end
end
