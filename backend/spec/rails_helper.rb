ENV["RAILS_ENV"] ||= "test"
ENV["PMS_BASE_URL"] = "http://pms.test"
ENV["LOCK_BASE_URL"] = "http://lock.test"
ENV["MOCK_API_KEY"] = "test-key"
ENV["STAFF_API_TOKEN"] = "staff-token"

require_relative "../config/environment"
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"
require "sidekiq/testing"
require "webmock/rspec"

Rails.root.glob("spec/support/**/*.rb").sort.each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

Sidekiq::Testing.fake!

RSpec.configure do |config|
  config.fixture_paths = [ Rails.root.join("spec/fixtures") ]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.include FactoryBot::Syntax::Methods
  config.before do
    Sidekiq::Job.clear_all
    Rails.cache.clear
  end
end
