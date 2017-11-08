$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
RSPEC_ROOT = File.dirname(__FILE__)
GEM_ROOT = File.expand_path("..", RSPEC_ROOT)

require 'simplecov'
SimpleCov.root GEM_ROOT
SimpleCov.start do
  add_filter "/spec/"
  add_filter "/.bundle/"
end

require 'rspec'
require 'webmock/rspec'
require 'hubspot-ruby'
require 'vcr'
require "awesome_print"

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{RSPEC_ROOT}/support/**/*.rb"].each {|f| require f}

VCR.configure do |c|
  c.cassette_library_dir = "#{RSPEC_ROOT}/fixtures/vcr_cassettes"
  c.hook_into :webmock
  c.default_cassette_options = { :record => :once, :erb => true }
end

RSpec.configure do |config|
  config.mock_with :rr
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.filter_run wip: true
  config.run_all_when_everything_filtered = true

  config.after(:each) do
    Hubspot::Config.reset!
  end

  config.around(:each, live: true) do |example|
    VCR.turn_off!
    WebMock.disable!
    example.run
    WebMock.enable!
    VCR.turn_on!
  end

  config.extend CassetteHelper
  config.extend TestsHelper
end
