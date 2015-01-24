module Looksee
  module ObjectMixin
    #
    # Define #ls as a shortcut for Looksee[self, *args].
    #
    # This is defined via method_missing to be less intrusive. pry 0.10, e.g.,
    # relies on Object#ls not existing.
    #
    def method_missing(name, *args)
      if name == Looksee::ObjectMixin.inspection_method
        Looksee[self, *args]
      else
        super
      end
    end

    def respond_to_missing?(name, include_private=false)
      name == Looksee::ObjectMixin.inspection_method || super
    end

    class << self
      attr_accessor :inspection_method
    end
    self.inspection_method = ENV['LOOKSEE_METHOD'] || :ls
  end

  Object.send :include, ObjectMixin
end
