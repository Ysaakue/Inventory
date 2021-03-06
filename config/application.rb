require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "sprockets/railtie"
require "rails/test_unit/railtie"
require 'csv'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Inventory
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # Use delayed_job to asynchronous tasks
    config.active_job.queue_adapter = :delayed_job

    # Cors configurations
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource(
          '*',
          headers: :any,
          expose: ['access-token','client','uid'],
          methods: [:get, :patch, :put, :delete, :post, :options]
        )
      end
    end

    # Host and Port to redis
    # $redis = Redis.new(url: ENV["REDIS_URL"])

    #configure timezone
    config.time_zone = 'America/Fortaleza'
    
    # set locale language
    config.i18n.default_locale = :'pt-BR'
    config.i18n.available_locales = %w(pt-BR en)
  end
end
