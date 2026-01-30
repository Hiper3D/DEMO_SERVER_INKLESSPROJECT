# frozen_string_literal: true

require 'active_support/core_ext/integer/time'
require 'active_support/core_ext/string'

Rails.backtrace_cleaner.remove_silencers!

Rails.application.configure do
  # Code is not reloaded between requests.
  config.enable_reloading = false

  config.public_file_server.headers = {
    'cache-control' => 'public, s-maxage=31536000, max-age=15552000',
    'Expires' => 1.year.from_now.to_fs(:rfc822)
  }

  # Eager load code on boot.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Background jobs
  config.active_job.queue_adapter = :sidekiq

  # Serve static files
  config.public_file_server.enabled = true

  # Active Storage
  config.active_storage.service =
    if ENV['S3_ATTACHMENTS_BUCKET'].present?
      :aws_s3
    elsif ENV['GCS_BUCKET'].present?
      :google
    elsif ENV['AZURE_CONTAINER'].present?
      :azure
    else
      :disk
    end

  config.active_storage.resolve_model_to_route =
    :rails_storage_proxy if ENV['ACTIVE_STORAGE_PUBLIC'] != 'true'

  config.active_storage.service_urls_expire_in =
    ENV.fetch('PRESIGNED_URLS_EXPIRE_MINUTES', '240').to_i.minutes

  # SSL (behind Caddy / reverse proxy)
  config.assume_ssl = ENV['FORCE_SSL'].present? && ENV['FORCE_SSL'] != 'false'
  config.force_ssl  = ENV['FORCE_SSL'].present? && ENV['FORCE_SSL'] != 'false'

  # Logging
  config.log_level = :info
  config.log_tags  = [:request_id]
  config.cache_store = :memory_store

  config.action_mailer.perform_caching = false
  config.action_mailer.raise_delivery_errors = false

  if ENV['SMTP_ADDRESS']
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: ENV.fetch('SMTP_ADDRESS', nil),
      port: ENV.fetch('SMTP_PORT', 587),
      domain: ENV.fetch('SMTP_DOMAIN', nil),
      user_name: ENV.fetch('SMTP_USERNAME', nil),
      password: ENV.fetch('SMTP_PASSWORD', nil),
      authentication: ENV.fetch('SMTP_PASSWORD', nil).present? ?
        ENV.fetch('SMTP_AUTHENTICATION', 'plain') : nil,
      enable_starttls_auto: ENV['SMTP_ENABLE_STARTTLS_AUTO'] != 'false'
    }.compact
  end

  # I18n
  config.i18n.fallbacks = true

  # Deprecations
  config.active_support.report_deprecations = false

  # Logger
  config.log_formatter = Logger::Formatter.new
  logger           = ActiveSupport::Logger.new($stdout)
  logger.formatter = config.log_formatter
  config.logger    = ActiveSupport::TaggedLogging.new(logger)

  # Encryption
  encryption_secret =
    ENV['ENCRYPTION_SECRET'].presence ||
    Digest::SHA256.hexdigest(ENV['SECRET_KEY_BASE'].to_s)

  config.active_record.encryption = {
    primary_key: encryption_secret.first(32),
    deterministic_key: encryption_secret.last(32),
    key_derivation_salt: Digest::SHA256.hexdigest(encryption_secret)
  }

  ActiveRecord::Encryption.configure(**config.active_record.encryption)

  # DB
  config.active_record.dump_schema_after_migration = false

  # Lograge
  config.lograge.enabled = true
  config.lograge.base_controller_class = ['ActionController::API', 'ActionController::Base']
  config.lograge.formatter = ->(data) { data.except(:path, :location).to_json }

  config.lograge.custom_payload do |controller|
    params =
      begin
        controller.request.try(:params) || {}
      rescue StandardError
        {}
      end

    resource =
      controller.instance_variable_get(:@submitter) ||
      controller.instance_variable_get(:@submission) ||
      controller.instance_variable_get(:@template) ||
      controller.instance_variable_get(:@record)

    current_user = controller.instance_variable_get(:@current_user)

    {
      host: controller.request.host,
      fwd: controller.request.remote_ip,
      params: {
        id: params[:id],
        template_id: params[:template_id],
        submission_id: params[:submission_id],
        submitter_id: params[:submitter_id],
        sig: (params[:signed_uuid] || params[:signed_id]).to_s.split('--').first,
        slug: (
          params[:slug] ||
          params[:submitter_slug] ||
          params[:submission_slug] ||
          params[:submit_form_slug] ||
          params[:template_slug]
        ).to_s.first(5)
      }.compact_blank,
      uid: current_user&.id,
      aid: current_user&.account_id,
      rid: resource&.id,
      raid: resource&.account_id
    }
  end

  # ==== FIX localhost redirect issue (FINAL) ====
  config.action_controller.default_url_options = {
    host: "bflsign.bc-pl.com",
    protocol: "https"
  }

  config.action_mailer.default_url_options = {
    host: "bflsign.bc-pl.com",
    protocol: "https"
  }
end
