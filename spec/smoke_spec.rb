# frozen_string_literal: true

require "spec_helper"

describe PgLocksMonitor do
  describe "snapshot!" do
    it "works" do
      expect {
        PgLocksMonitor.snapshot!
      }.not_to raise_error
    end
  end
end
