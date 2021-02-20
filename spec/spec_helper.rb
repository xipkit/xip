# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'

require 'xip'
require 'sidekiq/testing'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

$redis = Redis.new
$services_yml = File.read(File.join(File.dirname(__FILE__), 'support', 'services.yml'))

RSpec.configure do |config|
  ENV['XIP_ENV'] = 'test'

  config.before(:each) do |example|
    Sidekiq::Testing.fake!

    Xip.load_services_config!($services_yml)
  end

  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true

    expectations.on_potential_false_positives = :nothing
  end
end
