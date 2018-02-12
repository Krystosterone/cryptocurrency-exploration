require "rack/test"
require File.expand_path("../../node", __FILE__)

module SinatraRSpecMixin
  def app; Sinatra::Application; end
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  config.disable_monkey_patching!
  config.filter_run_when_matching :focus
  config.include Rack::Test::Methods
  config.include SinatraRSpecMixin
  config.order = :random
  config.shared_context_metadata_behavior = :apply_to_host_groups

  Kernel.srand config.seed
end
