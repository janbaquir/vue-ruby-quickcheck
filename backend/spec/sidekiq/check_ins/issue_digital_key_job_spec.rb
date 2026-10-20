require "rails_helper"

RSpec.describe CheckIns::IssueDigitalKeyJob do
  let(:check_in) { create(:check_in, :pms_synced) }
  let(:key_response) do
    { key_id: "key_123", access_code: "482913", valid_from: 1.hour.ago.iso8601, valid_until: 2.days.from_now.iso8601 }
  end

  def perform = described_class.new.perform(check_in.id)

  context "when the lock vendor issues a key" do
    before { stub_request(:post, "http://lock.test/locks/v1/keys").to_return(status: 201, body: key_response.to_json, headers: { "Content-Type" => "application/json" }) }

    it "stores the key and completes the check-in" do
      perform

      expect(check_in.reload).to be_key_issued
      expect(check_in.digital_key).to have_attributes(external_key_id: "key_123", access_code: "482913")
      expect(check_in.reservation).to be_checked_in
    end

    it "requests access for the room's lock until departure" do
      perform
      expect(WebMock).to have_requested(:post, "http://lock.test/locks/v1/keys")
        .with(body: hash_including("lock_device_id" => check_in.reservation.room.lock_device_id))
    end

    it "is a no-op when run again" do
      2.times { perform }
      expect(WebMock).to have_requested(:post, "http://lock.test/locks/v1/keys").once
      expect(DigitalKey.count).to eq(1)
    end
  end

  context "when the lock vendor is unavailable" do
    before { stub_request(:post, "http://lock.test/locks/v1/keys").to_return(status: 504) }

    it "raises so Sidekiq retries" do
      expect { perform }.to raise_error(Integrations::TransientError)
      expect(check_in.reload).to be_pms_synced
    end
  end
end
