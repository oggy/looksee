require 'rbconfig'

module Looksee
  module Adapter
    autoload :Base, 'looksee/adapter/base'
    autoload :MRI, File.dirname(__FILE__) + "/../../ext/mri/mri.#{Config::CONFIG['DLEXT']}"
    autoload :JRuby, 'looksee/looksee.jar'
    autoload :Rubinius, "looksee/adapter/rubinius"
  end
end
