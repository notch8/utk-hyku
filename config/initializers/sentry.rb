# frozen_string_literal: true

require 'sentry-rails'
require 'sentry-ruby'

Sentry.init do |config|
  config.dsn = ENV['SENTRY_DSN']
  config.environment = ENV['SENTRY_ENVIRONMENT']
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.enabled_environments = %w[utk-hyku-friends utk-hyku-production]
  config.debug = true
end