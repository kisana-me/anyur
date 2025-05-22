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
    config.action_view.field_error_proc = Proc.new do |html_tag, _instance|
      html_tag.html_safe
    end
    config.session_store :cookie_store,
      key: "_anyur",
      domain: :all,
      tld_length: 3,
      same_site: :strict,
      secure: Rails.env.production?,
      httponly: true
  end
end
