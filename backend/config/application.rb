require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"

Bundler.require(*Rails.groups)

module QuickCheck
  class Application < Rails::Application
    config.load_defaults 8.0
    config.autoload_lib(ignore: %w[assets tasks])
    config.api_only = true
    config.time_zone = "Asia/Tokyo"

    # Session middleware is only for Sidekiq::Web; the API is stateless.
    config.session_store :cookie_store, key: "_quickcheck_session"
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use config.session_store, config.session_options

    config.active_record.encryption.primary_key = ENV.fetch("AR_ENCRYPTION_PRIMARY_KEY", "dev-primary-key-not-for-production")
    config.active_record.encryption.deterministic_key = ENV.fetch("AR_ENCRYPTION_DETERMINISTIC_KEY", "dev-deterministic-key-not-for-prod")
    config.active_record.encryption.key_derivation_salt = ENV.fetch("AR_ENCRYPTION_KEY_DERIVATION_SALT", "dev-key-derivation-salt-not-for-prod")
  end
end
