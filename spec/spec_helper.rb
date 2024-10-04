# frozen_string_literal: true

require "rubygems"
require "bundler/setup"
require_relative "../lib/pg-locks-monitor"

pg_version = ENV["PG_VERSION"]

port = if pg_version == "11"
    "5432"
  elsif pg_version == "12"
    "5433"
  elsif pg_version == "13"
    "5434"
  elsif pg_version == "14"
    "5435"
  elsif pg_version == "15"
    "5436"
  elsif pg_version == "16"
    "5437"
  else
    "5432"
  end

ENV["DATABASE_URL"] ||= "postgresql://postgres:secret@localhost:#{port}/pg-locks-monitor-test"

RSpec.configure do |config|
  Rails = {}

  config.before(:each) do
    # Mock Rails and its logger
    logger_double = double("Logger")
    allow(logger_double).to receive(:info)
    allow(Rails).to receive(:logger).and_return(logger_double)
  end

  config.before(:suite) do
    ActiveRecord::Base.establish_connection(ENV["DATABASE_URL"])
    conn = RailsPgExtras.connection
    conn.execute("CREATE TABLE IF NOT EXISTS pg_locks_monitor_users (id SERIAL PRIMARY KEY, name VARCHAR(255) NOT NULL);")
    conn.execute("INSERT INTO pg_locks_monitor_users (name) VALUES ('Alice');")
    conn.execute("INSERT INTO pg_locks_monitor_users (name) VALUES ('Bob');")
  end

  config.after(:suite) do
    conn = RailsPgExtras.connection
    conn.execute("DROP TABLE IF EXISTS pg_locks_monitor_users;")
  end
end
