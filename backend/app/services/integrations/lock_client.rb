module Integrations
  class LockClient
    def initialize(http: HttpClient.new(base_url: ENV.fetch("LOCK_BASE_URL"), api_key: ENV.fetch("MOCK_API_KEY"), provider: "smart_lock"))
      @http = http
    end

    def issue_key(check_in)
      reservation = check_in.reservation
      @http.post(
        "/locks/v1/keys",
        {
          lock_device_id: reservation.room.lock_device_id,
          valid_from: reservation.key_valid_from.iso8601,
          valid_until: reservation.key_valid_until.iso8601
        },
        idempotency_key: check_in.idempotency_key_for(:key),
        operation: "issue_key",
        check_in:
      )
    end
  end
end
