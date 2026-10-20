require "rails_helper"

RSpec.describe "Guest check-in", type: :request do
  let(:reservation) { create(:reservation, guest: create(:guest, last_name: "Smith")) }
  let(:token) { reservation.guest_token }
  let(:auth) { { "Authorization" => "Bearer #{token}" } }
  let(:guest_params) do
    { first_name: "Emma", last_name: "Smith", email: "emma@example.com", nationality: "GB", address: "1 Baker St, London", passport_number: "GB1234567" }
  end

  describe "POST /api/v1/guest/session" do
    it "finds the booking regardless of case and whitespace" do
      post "/api/v1/guest/session", params: { confirmation_code: reservation.confirmation_code.downcase, last_name: " smith " }, as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include("token", "reservation")
    end

    it "does not reveal whether the code or the name was wrong" do
      post "/api/v1/guest/session", params: { confirmation_code: reservation.confirmation_code, last_name: "Jones" }, as: :json

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body.dig("error", "message")).to eq("We couldn't find a booking with those details.")
    end
  end

  describe "POST /api/v1/guest/check_in" do
    it "requires a guest token" do
      post "/api/v1/guest/check_in", params: { guest: guest_params }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "starts the check-in and hands off to the PMS sync job" do
      expect {
        post "/api/v1/guest/check_in", params: { guest: guest_params }, headers: auth, as: :json
      }.to change(CheckIn, :count).by(1).and change(CheckIns::SyncToPmsJob.jobs, :size).by(1)

      expect(response).to have_http_status(:accepted)
      expect(response.parsed_body.dig("reservation", "check_in", "status")).to eq("pending")
    end

    it "never returns the passport number" do
      post "/api/v1/guest/check_in", params: { guest: guest_params }, headers: auth, as: :json
      expect(response.body).not_to include("GB1234567")
    end

    it "is idempotent when submitted twice" do
      2.times { post "/api/v1/guest/check_in", params: { guest: guest_params }, headers: auth, as: :json }

      expect(CheckIn.count).to eq(1)
      expect(CheckIns::SyncToPmsJob.jobs.size).to eq(1)
    end

    it "requires a passport number for foreign nationals" do
      post "/api/v1/guest/check_in", params: { guest: guest_params.except(:passport_number) }, headers: auth, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "details")).to have_key("passport_number")
    end

    it "does not require a passport number for Japanese nationals" do
      post "/api/v1/guest/check_in", params: { guest: guest_params.except(:passport_number).merge(nationality: "JP") }, headers: auth, as: :json
      expect(response).to have_http_status(:accepted)
    end

    it "rejects check-in before the arrival date" do
      reservation.update!(arrival_date: Date.tomorrow, departure_date: Date.tomorrow + 2)
      post "/api/v1/guest/check_in", params: { guest: guest_params }, headers: auth, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(CheckIn.count).to eq(0)
    end
  end
end
