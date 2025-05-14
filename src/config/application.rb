require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module App
  class Application < Rails::Application
    config.load_defaults 8.0
    config.autoload_lib(ignore: %w[assets tasks])
    config.time_zone = "Tokyo"
    # config.eager_load_paths << Rails.root.join("extras")
    config.i18n.default_locale = :ja
  end
end
