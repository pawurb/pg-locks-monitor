# frozen_string_literal: true

require "spec_helper"

describe "PgLocksMonitor::Configuration" do
  it "has a default configuration" do
    config = PgLocksMonitor.configuration
    expect(config.monitor_locks).to eq true
    expect(config.monitor_blocking).to eq true
    expect(config.locks_min_duration_ms).to eq 200
    expect(config.blocking_min_duration_ms).to eq 100
    expect(config.notifier_class).to eq PgLocksMonitor::DefaultNotifier
  end

  it "can be configured" do
    PgLocksMonitor.configure do |config|
      config.monitor_locks = false
    end

    expect(PgLocksMonitor.configuration.monitor_locks).to eq false
  end
end
