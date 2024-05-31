# frozen_string_literal: true

class PgLocksMonitor::Railtie < Rails::Railtie
  rake_tasks do
    load "pg_locks_monitor/tasks/all.rake"
  end
end
