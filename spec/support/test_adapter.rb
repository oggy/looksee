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

  def singleton_class?(object)
    NATIVE_ADAPTER.singleton_class?(object)
  end

  def singleton_instance(object)
    NATIVE_ADAPTER.singleton_instance(object)
  end

  def module_name(object)
    NATIVE_ADAPTER.module_name(object)
  end

  def set_undefined_methods(mod, names)
    self.undefined_methods[mod] = names
  end

  def source_location(method)
    source_locations[[method.owner.name.to_s, method.name.to_s]]
  end

  def set_source_location(mod, method, location)
    source_locations[[mod.name.to_s, method.to_s]] = location
  end

  def ancestors
    @ancestors ||= Hash.new { |h, k| h[k] = [] }
  end

  def undefined_methods
    @undefined_methods ||= Hash.new { |h, k| h[k] = [] }
  end

  def source_locations
    @source_locations ||= {}
  end
end
