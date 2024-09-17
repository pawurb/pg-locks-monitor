# frozen_string_literal: true

require "uri"
require "pg"

module PgLocksMonitor
  def self.snapshot!
    locks = RailsPgExtras.locks(
      in_format: :hash, args: {
        limit: configuration.locks_limit,
      },
    ).select do |lock|
      if (age = lock.fetch("age"))
        (ActiveSupport::Duration.parse(age).to_f * 1000) > configuration.locks_min_duration_ms
      end
    end

    if locks.present? && configuration.monitor_locks
      configuration.notifier_class.call(locks)
    end

    blocking = RailsPgExtras.blocking(in_format: :hash).select do |block|
      (ActiveSupport::Duration.parse(block.fetch("blocking_duration")).to_f * 1000) > configuration.blocking_min_duration_ms
    end

    if blocking.present? && configuration.monitor_blocking
      configuration.notifier_class.call(blocking)
    end
  end

  def self.configuration
    @configuration ||= Configuration.new(Configuration::DEFAULT)
  end

  def self.configure
    yield(configuration)
  end
end

require "pg_locks_monitor/default_notifier"
require "pg_locks_monitor/configuration"
require "pg_locks_monitor/railtie" if defined?(Rails)
