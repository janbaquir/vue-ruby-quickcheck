require "sidekiq/web"

Sidekiq.configure_server { |config| config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") } }
Sidekiq.configure_client { |config| config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") } }

Sidekiq::Web.use Rack::Auth::Basic, "Sidekiq" do |user, password|
  ActiveSupport::SecurityUtils.secure_compare(user, "staff") &&
    ActiveSupport::SecurityUtils.secure_compare(password, ENV.fetch("STAFF_API_TOKEN", ""))
end
