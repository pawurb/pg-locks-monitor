# frozen_string_literal: true

module PgLocksMonitor
  class Configuration
    DEFAULT = {
      locks_limit: 5,
      monitor_locks: true,
      monitor_blocking: true,
      locks_min_duration_ms: 200,
      blocking_min_duration_ms: 100,
      notify_logs: true,
      notify_slack: false,
      slack_webhook_url: nil,
      slack_channel: nil,
      notifier_class: PgLocksMonitor::DefaultNotifier,
    }

    attr_accessor *DEFAULT.keys

    def initialize(attrs)
      DEFAULT.keys.each do |key|
        value = attrs.fetch(key) { DEFAULT.fetch(key) }
        public_send("#{key}=", value)
      end
    end

    DEFAULT_CONFIG_FILE = <<-CONFIG
# Configuration for pg-locks-monitor

PgLocksMonitor.configure do |config|
  config.locks_limit = #{DEFAULT[:locks_limit]}

  config.monitor_locks = #{DEFAULT[:monitor_locks]}
  config.monitor_blocking = #{DEFAULT[:monitor_blocking]}

  config.locks_min_duration_ms = #{DEFAULT[:locks_min_duration_ms]}
  config.blocking_min_duration_ms = #{DEFAULT[:blocking_min_duration_ms]}

  config.notify_logs = #{DEFAULT[:notify_logs]}

  config.notify_slack = #{DEFAULT[:notify_slack]}
  config.slack_webhook_url = "#{DEFAULT[:slack_webhook_url]}"
  config.slack_channel = "#{DEFAULT[:slack_channel]}"

  config.notifier_class = #{DEFAULT[:notifier_class]}
end
CONFIG
  end
end
