# frozen_string_literal: true

require "spec_helper"

describe PgLocksMonitor::DefaultNotifier do
  it "requires correct config if Slack notifications enabled" do
    expect {
      PgLocksMonitor::DefaultNotifier.call({})
    }.not_to raise_error
    PgLocksMonitor.configure do |config|
      config.notify_slack = true
    end

    expect {
      PgLocksMonitor::DefaultNotifier.call({})
    }.to raise_error(RuntimeError)
  end

  describe "Slack notification enabled" do
    before do
      PgLocksMonitor.configure do |config|
        config.notify_slack = true
        config.slack_webhook_url = "https://hooks.slack.com/services/123456789/123456789/123456789"
        config.slack_channel = "pg-locks-monitor"
      end
    end

    after do
      PgLocksMonitor.configure do |config|
        config.notify_slack = false
        config.slack_webhook_url = nil
        config.slack_channel = nil
      end
    end

    it "sends the Slack notification" do
      expect_any_instance_of(Slack::Notifier).to receive(:ping)
      PgLocksMonitor::DefaultNotifier.call({ locks: "data" })
    end
  end
end
