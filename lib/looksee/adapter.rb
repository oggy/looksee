module Looksee
  module Adapter
    autoload :Base, 'looksee/adapter/base'
    autoload :MRI, "looksee/mri.#{Looksee::Config::CONFIG['DLEXT']}"
    autoload :JRuby, 'looksee/JRuby.jar'
    autoload :Rubinius, "looksee/adapter/rubinius"
  end
end
