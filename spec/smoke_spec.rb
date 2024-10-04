# frozen_string_literal: true

require "spec_helper"

describe PgLocksMonitor do
  def spawn_update
    Thread.new do
      conn = RailsPgExtras.connection
      conn.execute("
        BEGIN;
        UPDATE pg_locks_monitor_users SET name = 'Updated';
        select pg_sleep(2);
        COMMIT;
        ")
    end
  end

  describe "snapshot!" do
    it "works" do
      expect {
        PgLocksMonitor.snapshot!
      }.not_to raise_error
    end

    it "returns correct locks data" do
      spawn_update
      spawn_update
      result = PgLocksMonitor.snapshot!
      expect(result.fetch(:locks).count).to eq(0)
      expect(result.fetch(:blocking).count).to eq(0)

      sleep 1

      result = PgLocksMonitor.snapshot!
      expect(result.fetch(:locks).count).to eq(5)
      expect(result.fetch(:blocking).count).to eq(1)
    end
  end
end
