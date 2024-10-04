# frozen_string_literal: true

require "uri"
require "pg"
require "rails-pg-extras"
require "active_record"

module PgLocksMonitor
  def self.snapshot!
    locks = RailsPgExtras.locks(
      in_format: :hash,
    ).select do |lock|
      if (age = lock.fetch("age"))
        (ActiveSupport::Duration.parse(age).to_f * 1000) > configuration.locks_min_duration_ms
      end
    end.select(&configuration.locks_filter_proc)
      .first(configuration.locks_limit)

    if locks.count > 0 && configuration.monitor_locks
      configuration.notifier_class.call(locks)
    end

    blocking = RailsPgExtras.blocking(in_format: :hash).select do |block|
      if (age = block.fetch("blocking_duration"))
        (ActiveSupport::Duration.parse(age).to_f * 1000) > configuration.locks_min_duration_ms
      end
    end.select(&configuration.blocking_filter_proc)
      .first(configuration.locks_limit)

    if blocking.count > 0 && configuration.monitor_blocking
      configuration.notifier_class.call(blocking)
    end

    {
      locks: locks,
      blocking: blocking,
    }
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
