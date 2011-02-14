class TestAdapter < Looksee::Adapter::Base
  def lookup_modules(object)
    ancestors[object]
  end

  def internal_public_instance_methods(mod)
    public_methods[mod]
  end

  def internal_protected_instance_methods(mod)
    protected_methods[mod]
  end

  def internal_private_instance_methods(mod)
    private_methods[mod]
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

  def set_methods(mod, public, protected, private, undefined)
    self.public_methods[mod] = public
    self.protected_methods[mod] = protected
    self.private_methods[mod] = private
    self.undefined_methods[mod] = undefined
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

  def public_methods
    @public_methods ||= Hash.new { |h, k| h[k] = [] }
  end

  def protected_methods
    @protected_methods ||= Hash.new { |h, k| h[k] = [] }
  end

  def private_methods
    @private_methods ||= Hash.new { |h, k| h[k] = [] }
  end

  def undefined_methods
    @undefined_methods ||= Hash.new { |h, k| h[k] = [] }
  end

  def source_locations
    @source_locations ||= {}
  end
end
