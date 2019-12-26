module Looksee
  VERSION = [4, 2, 0]

  class << VERSION
    include Comparable

    def to_s
      join('.')
    end
  end
end
