ENV['LOOKSEE_METHODS'] = nil

require 'rspec'
require 'mocha'
require 'looksee'

require 'rbconfig'
require 'set'
require 'fileutils'

ROOT = File.dirname(File.dirname(__FILE__))

Dir['spec/support/*.rb'].each do |path|
  require path
end

NATIVE_ADAPTER = Looksee.adapter

RSpec.configure do |config|
  config.mock_with :mocha
  config.before { Looksee.adapter = TestAdapter.new }
end

if Looksee.ruby_engine == 'jruby'
  require 'jruby'
  JRuby.objectspace = true
end
