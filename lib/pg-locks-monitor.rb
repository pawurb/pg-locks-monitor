# frozen_string_literal: true

require "uri"
require "pg"
require "ruby-pg-extras"

module PgLocksMonitor
  def self.snapshot!
    locks = RubyPgExtras.locks(
      in_format: :hash,
    ).select do |lock|
      if (age = lock.fetch("age"))
        DurationHelper.parse_to_ms(age) > configuration.locks_min_duration_ms
      end
    end.select(&configuration.locks_filter_proc)
      .first(configuration.locks_limit)

    if locks.count > 0 && configuration.monitor_locks
      configuration.notifier_class.call(locks)
    end

    blocking = RubyPgExtras.blocking(in_format: :hash).select do |block|
      DurationHelper.parse_to_ms(block.fetch("blocking_duration")) > configuration.blocking_min_duration_ms
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

  class DurationHelper
    require "date"

    def self.parse_to_ms(duration_str)
      time = DateTime.strptime(duration_str, "%H:%M:%S.%N")
      hours = time.hour
      minutes = time.minute
      seconds = time.second
      nanoseconds = time.second_fraction * (10 ** 9)

      total_ms = (hours * 3600 * 1000) + (minutes * 60 * 1000) + (seconds * 1000) + (nanoseconds / 1_000_000).to_i

      total_ms
    end
  end
end

require "pg_locks_monitor/default_notifier"
require "pg_locks_monitor/configuration"
require "pg_locks_monitor/railtie" if defined?(Rails)
