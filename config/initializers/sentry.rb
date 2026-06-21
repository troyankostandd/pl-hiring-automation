if Rails.env.production?
  Sentry.init do |config|
    config.dsn = ENV['SENTRY_DSN']
    config.environment = Rails.env
    config.rails.tracing_enabled = true

    # Performance monitoring
    config.traces_sample_rate = 0.5

    # Error sampling
    config.sample_rate = 1.0

    # Ignore certain exceptions
    config.excluded_exceptions = []
  end
end
