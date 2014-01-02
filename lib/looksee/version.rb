module Looksee
  VERSION = [2, 0, 0]

  class << VERSION
    include Comparable

    def to_s
      join('.')
    end
  end
end
