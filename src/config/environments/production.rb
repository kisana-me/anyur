require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{10.day.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.logger = Logger.new('log/production.log', 'daily')#ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!)

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  config.cache_store = :solid_cache_store

  # Replace the default in-process and non-durable queuing backend for Active Job.
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }

  # action_mailer
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default_url_options = { host: "anyur.com" }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    user_name: Rails.application.credentials.dig(:smtp, :user_name),
    password: Rails.application.credentials.dig(:smtp, :password),
    domain: "anyur.com",
    address: "smtp.gmail.com",
    port: 587,
    authentication: :plain,
    enable_starttls_auto: true
  }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Enable DNS rebinding protection and other `Host` header attacks.
  config.hosts = [
    "anyur.com"
  ]
  # Cloudflare IP Ranges(https://www.cloudflare.com/ips/)
  config.action_dispatch.trusted_proxies = [
    # IPv6
    IPAddr.new("2400:cb00::/32"),
    IPAddr.new("2606:4700::/32"),
    IPAddr.new("2803:f800::/32"),
    IPAddr.new("2405:b500::/32"),
    IPAddr.new("2405:8100::/32"),
    IPAddr.new("2a06:98c0::/29"),
    IPAddr.new("2c0f:f248::/32"),
    # IPv4
    IPAddr.new("103.21.244.0/22"),
    IPAddr.new("103.22.200.0/22"),
    IPAddr.new("103.31.4.0/22"),
    IPAddr.new("104.16.0.0/13"),
    IPAddr.new("104.24.0.0/14"),
    IPAddr.new("108.162.192.0/18"),
    IPAddr.new("131.0.72.0/22"),
    IPAddr.new("141.101.64.0/18"),
    IPAddr.new("162.158.0.0/15"),
    IPAddr.new("172.64.0.0/13"),
    IPAddr.new("173.245.48.0/20"),
    IPAddr.new("188.114.96.0/20"),
    IPAddr.new("190.93.240.0/20"),
    IPAddr.new("197.234.240.0/22"),
    IPAddr.new("198.41.128.0/17"),
  ]
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
