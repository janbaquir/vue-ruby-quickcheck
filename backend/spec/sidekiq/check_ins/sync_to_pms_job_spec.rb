require "rails_helper"

RSpec.describe CheckIns::SyncToPmsJob do
  let(:check_in) { create(:check_in) }
  let(:pms_url) { "http://pms.test/pms/v1/reservations/#{check_in.reservation.pms_reservation_id}/check_in" }

  def perform = described_class.new.perform(check_in.id)

  context "when the PMS accepts the check-in" do
    before { stub_request(:post, pms_url).to_return(status: 200, body: { status: "IN_HOUSE" }.to_json, headers: { "Content-Type" => "application/json" }) }

    it "marks the check-in as synced and enqueues key issuance" do
      expect { perform }.to change(CheckIns::IssueDigitalKeyJob.jobs, :size).by(1)
      expect(check_in.reload).to be_pms_synced
    end

    it "sends a stable idempotency key" do
      perform
      expect(WebMock).to have_requested(:post, pms_url)
        .with(headers: { "Idempotency-Key" => check_in.idempotency_key_for(:pms), "Authorization" => "Bearer test-key" })
    end

    it "records a successful integration event" do
      expect { perform }.to change { check_in.integration_events.success.count }.by(1)
    end
  end

  context "when the PMS is temporarily unavailable" do
    before { stub_request(:post, pms_url).to_return(status: 503) }

    it "raises so Sidekiq retries, leaving the check-in pending" do
      expect { perform }.to raise_error(Integrations::TransientError)
      expect(check_in.reload).to be_pending
      expect(check_in.integration_events.last).to be_transient_failure
    end
  end

  context "when the PMS times out" do
    before { stub_request(:post, pms_url).to_timeout }

    it "treats it as transient" do
      expect { perform }.to raise_error(Integrations::TransientError)
    end
  end

  context "when the PMS rejects the check-in" do
    before { stub_request(:post, pms_url).to_return(status: 409, body: { error: "reservation is cancelled in PMS" }.to_json, headers: { "Content-Type" => "application/json" }) }

    it "fails the check-in without retrying" do
      expect { perform }.not_to raise_error
      expect(check_in.reload).to be_failed
      expect(check_in.last_error).to include("409", "cancelled")
    end
  end

  context "when the check-in is no longer pending" do
    let(:check_in) { create(:check_in, :pms_synced) }

    it "does nothing" do
      perform
      expect(WebMock).not_to have_requested(:post, /pms\.test/)
    end
  end

  describe "retries exhausted" do
    it "marks the check-in as failed" do
      described_class.sidekiq_retries_exhausted_block.call({ "args" => [ check_in.id ] }, Integrations::TransientError.new("pms check_in: HTTP 503"))
      expect(check_in.reload).to have_attributes(status: "failed", last_error: "pms check_in: HTTP 503")
    end
  end
end
