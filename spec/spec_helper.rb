$:.unshift File.expand_path('..', File.dirname(__FILE__))
ENV['LOOKSEE_METHOD'] = nil

require 'rspec'
require 'pry' unless ENV['CI']

require 'looksee'

require 'rbconfig'
require 'set'
require 'fileutils'

ROOT = File.expand_path('..', File.dirname(__FILE__))

Dir['spec/support/*.rb'].each do |path|
  require path
end

NATIVE_ADAPTER = Looksee.adapter

RSpec.configure do |config|
  config.extend TestAdapter::Mixin

  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end

  config.mock_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
end
