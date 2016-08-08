class TestAdapter < Looksee::Adapter::Base
  module Mixin
    def use_test_adapter
      before { Looksee.adapter = TestAdapter.new }
      after { Looksee.adapter = NATIVE_ADAPTER }
    end
  end

  def lookup_modules(object)
    ancestors[object]
  end

  def internal_undefined_instance_methods(mod)
    undefined_methods[mod]
  end

  def singleton_instance(object)
    NATIVE_ADAPTER.singleton_instance(object)
  end

  def set_undefined_methods(mod, names)
    self.undefined_methods[mod] = names
  end

  def ancestors
    @ancestors ||= Hash.new { |h, k| h[k] = [] }
  end

  def undefined_methods
    @undefined_methods ||= Hash.new { |h, k| h[k] = [] }
  end
end
