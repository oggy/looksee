require 'spec'
require 'mocha'
require 'looksee'

require 'rbconfig'
require 'set'

Dir['spec/support/*'].each do |path|
  require path
end

NATIVE_ADAPTER = Looksee.adapter

Spec::Runner.configure do |config|
  config.mock_with :mocha
  config.before { Looksee.adapter = TestAdapter.new }
end

if RUBY_ENGINE == 'jruby'
  require 'jruby'
  JRuby.objectspace = true
end
