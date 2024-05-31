# -*- encoding: utf-8 -*-
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "pg_locks_monitor/version"

Gem::Specification.new do |s|
  s.name = "pg-locks-monitor"
  s.version = PgLocksMonitor::VERSION
  s.authors = ["pawurb"]
  s.email = ["contact@pawelurbanek.com"]
  s.summary = %q{ Observe PostgreSQL database locks obtained by a Rails application. }
  s.description = %q{ This gem allows to monitor and notify about PostgreSQL database locks which meet certain criteria. You can report locks which are held for a certain amount of time, or locks which are held by a certain query. }
  s.homepage = "http://github.com/pawurb/pg-locks-monitor"
  s.files = `git ls-files`.split("\n")
  s.test_files = s.files.grep(%r{^(spec)/})
  s.require_paths = ["lib"]
  s.license = "MIT"
  s.add_dependency "ruby-pg-extras"
  s.add_dependency "slack-notifier"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rufo"

  if s.respond_to?(:metadata=)
    s.metadata = { "rubygems_mfa_required" => "true" }
  end
end
