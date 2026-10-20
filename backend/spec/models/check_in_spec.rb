require "rails_helper"

RSpec.describe CheckIn do
  describe "#retry!" do
    it "resumes from key issuance when the PMS step already succeeded" do
      check_in = create(:check_in, :failed, pms_synced_at: 1.minute.ago)

      expect(check_in.retry!).to be(true)
      expect(check_in.reload).to have_attributes(status: "pms_synced", last_error: nil)
      expect(CheckIns::IssueDigitalKeyJob.jobs.size).to eq(1)
    end

    it "restarts from the PMS step when it never succeeded" do
      check_in = create(:check_in, :failed)

      check_in.retry!
      expect(check_in.reload).to be_pending
      expect(CheckIns::SyncToPmsJob.jobs.size).to eq(1)
    end

    it "refuses to retry a check-in that has not failed" do
      check_in = create(:check_in)

      expect(check_in.retry!).to be(false)
      expect(CheckIns::SyncToPmsJob.jobs).to be_empty
    end
  end

  describe "#mark_failed!" do
    it "never overrides a completed check-in" do
      check_in = create(:check_in, status: :key_issued)

      check_in.mark_failed!("late error")
      expect(check_in.reload).to be_key_issued
    end
  end
end
