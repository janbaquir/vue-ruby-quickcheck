require "rails_helper"

RSpec.describe "Staff API", type: :request do
  let(:headers) { { "X-Staff-Token" => "staff-token" } }

  it "rejects requests without a valid staff token" do
    get "/api/v1/staff/arrivals", headers: { "X-Staff-Token" => "wrong" }
    expect(response).to have_http_status(:unauthorized)
  end

  describe "GET /api/v1/staff/arrivals" do
    it "lists today's arrivals with a status summary" do
      create(:check_in, :failed)
      create(:reservation)

      get "/api/v1/staff/arrivals", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["arrivals"].size).to eq(2)
      expect(response.parsed_body["summary"]).to include("total" => 2, "failed" => 1, "not_started" => 1)
    end

    it "rejects a malformed date" do
      get "/api/v1/staff/arrivals", params: { date: "tomorrow" }, headers: headers
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "POST /api/v1/staff/check_ins/:id/retry" do
    it "re-enqueues a failed check-in" do
      check_in = create(:check_in, :failed)

      post "/api/v1/staff/check_ins/#{check_in.id}/retry", headers: headers

      expect(response).to have_http_status(:accepted)
      expect(CheckIns::SyncToPmsJob.jobs.size).to eq(1)
    end

    it "returns a conflict for a check-in that has not failed" do
      check_in = create(:check_in)

      post "/api/v1/staff/check_ins/#{check_in.id}/retry", headers: headers
      expect(response).to have_http_status(:conflict)
    end
  end
end
