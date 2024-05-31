# frozen_string_literal: true

require "spec_helper"

describe PgLocksMonitor::DefaultNotifier do
  before do
    # Mock Rails and its logger
    Rails = nil
    logger_double = double("Logger")
    allow(logger_double).to receive(:info)
    allow(Rails).to receive(:logger).and_return(logger_double)
  end

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

  it "sends the Slack notification if enabled" do
    PgLocksMonitor.configure do |config|
      config.notify_slack = true
      config.slack_webhook_url = "https://hooks.slack.com/services/123456789/123456789/123456789"
      config.slack_channel = "pg-locks-monitor"
    end

    expect_any_instance_of(Slack::Notifier).to receive(:ping)
    PgLocksMonitor::DefaultNotifier.call({ locks: "data" })
  end
end
