source "https://rubygems.org"

gem "rails", "~> 8.0"
gem "pg", "~> 1.1"
gem "puma"
gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "jbuilder"
gem "solid_cache"
gem "solid_queue"
gem "view_component", "~> 3.0"
gem "pagy", "~> 8.0"
gem "sentry-rails"
gem "bootsnap", require: false
gem "image_processing", "~> 1.2"
gem "tzinfo-data", platforms: %i[ windows jruby ]

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
end

group :test do
  gem "capybara"
  gem "cuprite"
  gem "shoulda-matchers"
end

group :development do
  gem "web-console"
end
