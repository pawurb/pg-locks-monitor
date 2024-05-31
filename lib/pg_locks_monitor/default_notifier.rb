# frozen_string_literal: true

require "slack-notifier"

module PgLocksMonitor
  class DefaultNotifier
    def self.call(locks_data)
      config = PgLocksMonitor.configuration

      if config.notify_logs && defined?(Rails)
        Rails.logger.info locks_data.to_s
      end

      if config.notify_slack
        slack_webhook_url = config.slack_webhook_url
        if slack_webhook_url.nil? || slack_webhook_url.strip.length == 0
          raise "Missing pg-locks-monitor slack_webhook_url config"
        end

        slack_channel = config.slack_channel
        if slack_channel.nil? || slack_channel.strip.length == 0
          raise "Missing pg-locks-monitor slack_channel config"
        end

        Slack::Notifier.new(
          slack_webhook_url,
          channel: slack_channel,
        ).ping JSON.pretty_generate(locks_data)
      end
    end
  end
end
