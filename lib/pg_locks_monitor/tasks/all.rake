# frozen_string_literal: true

require "pg-locks-monitor"
require "fileutils"

namespace :pg_locks_monitor do
  desc "Initialize a config file"
  task :init do
    file_path = "config/initializers/pg_locks_monitor.rb"
    if File.exist?(file_path)
      puts "#{file_path} config file has already been initialized!"
    else
      File.write(file_path, PgLocksMonitor::Configuration::DEFAULT_CONFIG_FILE)
      puts "Config file created at #{file_path}"
    end
  end

  desc "Check for currently active locks"
  task :snapshot do
    PgLocksMonitor.snapshot!
  end
end
