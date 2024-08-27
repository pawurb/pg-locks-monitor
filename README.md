# PG Locks Monitor [![Gem Version](https://badge.fury.io/rb/pg-locks-monitor.svg)](https://badge.fury.io/rb/pg-locks-monitor) [![GH Actions](https://github.com/pawurb/pg-locks-monitor/actions/workflows/ci.yml/badge.svg)](https://github.com/pawurb/pg-locks-monitor/actions)

This gem allows to observe database locks generated by a Rails application. By default, locks data is not persisted anywhere in the PostgreSQL logs, so the only way to monitor it is via analyzing the transient state of the `pg_locks` metadata table. `pg-locks-monitor` is a simple tool that makes this process quick to implement and adjust to each app's individual requirements.

## Usage

`PgLocksMonitor` class provides a `snapshot!` method, which notifies selected channels about database locks that match configured criteria.

Start by adding the gem to your Gemfile:

```ruby
gem "pg-locks-monitor"
```

Then run `bundle install` and `rake pg_locks_monitor:init`. It creates a default configuration file with the following settings:

`config/initializers/pg_locks_monitor.rb`
```ruby
PgLocksMonitor.configure do |config|
  config.locks_limit = 5

  config.monitor_locks = true
  config.locks_min_duration_ms = 200

  config.monitor_blocking = true
  config.blocking_min_duration_ms = 100

  config.notify_logs = true

  config.notify_slack = false
  config.slack_webhook_url = ""
  config.slack_channel = ""

  config.notifier_class = PgLocksMonitor::DefaultNotifier
end
```

- `locks_limit` - specify the max number of locks to report in a single notification
- `notify_locks` - observe database locks even if they don't conflict with a different SQL query
- `locks_min_duration_ms` - notify about locks that execeed this duration threshold in milliseconds
- `notify_blocking` - observe database locks which cause other SQL query to wait from them to release
- `blocking_min_duration_ms` - notify about blocking locks that execeed this duration threshold in milliseconds
- `notify_logs` - send notifications about detected locks using `Rails.logger.info` method
- `notify_slack` - send notifications about detected locks to the configured Slack channel
- `slack_webhook_url` - webhook necessary for Slack notification to work
- `slack_channel` - the name of the target Slack channel
- `notifier_class` - customizable notifier class


## Testing the notification channels

Before enabling a recurring invocation of the `snapshot!` method, it's recommended to first manually trigger the notification to test the configured channels.

You can generate an _"artificial"_ blocking lock and observe it by running the following code in the Rails console:

```ruby
user = User.last

Thread.new do
  User.transaction do
    user.update(email: "email-#{SecureRandom.hex(2)}@example.com")
    sleep 5
    raise ActiveRecord::Rollback
  end
end

Thread.new do
  User.transaction do
    user.update(email: "email-#{SecureRandom.hex(2)}@example.com")
    sleep 5
    raise ActiveRecord::Rollback
  end
end

sleep 0.5
PgLocksMonitor.snapshot!
```

Please remember to adjust the update operation to match your app's schema.

As a result of running the above snippet, you should receive a notification about the acquired blocking database lock.

### Sample notification

Received notifications contain data helpful in debugging the cause of long lasting-locks.

And here's a sample blocking lock notification: 

```ruby
[
  {
    # PID of the process which was blocking another query
    "blocking_pid": 29,
    # SQL query blocking other SQL query
    "blocking_statement": "UPDATE \"users\" SET \"updated_at\" = $1 WHERE \"users\".\"id\" = $2 from/sidekiq_job:UserUpdater/",
    # the duration of blocking SQL query
    "blocking_duration": "PT0.972116S",
    # app that triggered the blocking SQL query
    "blocking_sql_app": "bin/sidekiq",

    # PID of the process which was blocked by another query
    "blocked_pid": 30,
    # SQL query blocked by other SQL query
    "blocked_statement": "UPDATE \"users\" SET \"last_active_at\" = $1 WHERE \"users\".\"id\" = $2 from/controller_with_namespace:UsersController,action:update/",
    # the duration of the blocked SQL query
    "blocked_duration": "PT0.483309S",
    # app that triggered the blocked SQL query
    "blocked_sql_app": "bin/puma"
  }
]
```

This sample blocking notification shows than a query originating from the `UserUpdater` Sidekiq job is blocking an update operation on the same user for the `UsersController#update` action. Remember to configure the [marginalia gem](https://github.com/basecamp/marginalia) to enable these helpful query source annotations.

Here's a sample lock notification:

```ruby
[
  {
    # PID of the process which acquired the lock
    "pid": 50,
    # name of affected table/index
    "relname": "users",
    # ID of the source transaction
    "transactionid": null,
    # bool indicating if the lock is already granted
    "granted": true,
    # type of the acquired lock
    "mode": "RowExclusiveLock",
    # SQL query which acquired the lock
    "query_snippet": "UPDATE \"users\" SET \"updated_at\" = $1 WHERE \"users\".\"id\" = $2 from/sidekiq_job:UserUpdater/",
    # age of the lock
    "age": "PT0.94945S",
    # app that acquired the lock
    "application": "bin/sidekiq"
  },
```

You can read [this blogpost](https://pawelurbanek.com/rails-postgresql-locks) for more detailed info on locks in the Rails apps.

## Background job config

This gem is intended to be used via a recurring background job, but it is agnostic to the background job provider. Here's a sample Sidekiq implementation:

`app/jobs/pg_locks_monitor_job.rb`
```ruby
require 'pg-locks-monitor'

class PgLocksMonitoringJob
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    PgLocksMonitor.snapshot!
  ensure
    if ENV["PG_LOCKS_MONITOR_ENABLED"]
      PgLocksMonitoringJob.perform_in(1.minute)
    end
  end
end
```

Remember to schedule this job when your app starts:
`config/pg_locks_monitor.rb`

```ruby
#... 

if ENV["PG_LOCKS_MONITOR_ENABLED"]
  PgLocksMonitoringJob.perform
end
```

A background job that schedules itself is not the cleanest pattern. So alternatively you can use [sidekiq-cron](https://github.com/sidekiq-cron/sidekiq-cron), [whenever](https://github.com/javan/whenever) or [clockwork](https://github.com/adamwiggins/clockwork) gems to trigger the `PgLocksMonitor.snapshot!` invocation periodically.

A recommended frequency of invocation depends on your app's traffic. From my experience, even 1 minute apart snapshots can provide a lot of valuable data, but it all depends on how often the locks are occurring in your Rails application.

## Custom notifier class

`PgLocksMonitor::DefaultNotifier` supports sending lock notifications with `Rails.logger` or to a Slack channel. If you want to use different notification channels you can define your custom notifier like that:

`config/initializers/pg_locks_monitor.rb`
```ruby
class PgLocksEmailNotifier
  def self.call(locks_data)
    LocksMailer.with(locks_data: locks_data).notification.deliver_now
  end
end

PgLocksMonitor.configure do |config|
  # ...

  config.notifier_class = PgLocksEmailNotifier
end

```

## Contributions

This gem is in a very early stage of development so feedback and PRs are welcome.
