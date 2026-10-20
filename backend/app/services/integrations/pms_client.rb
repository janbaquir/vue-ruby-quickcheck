module Integrations
  class PmsClient
    def initialize(http: HttpClient.new(base_url: ENV.fetch("PMS_BASE_URL"), api_key: ENV.fetch("MOCK_API_KEY"), provider: "pms"))
      @http = http
    end

    def check_in(check_in)
      reservation = check_in.reservation
      @http.post(
        "/pms/v1/reservations/#{reservation.pms_reservation_id}/check_in",
        {
          room_number: reservation.room.number,
          guest: {
            first_name: reservation.guest.first_name,
            last_name: reservation.guest.last_name,
            nationality: reservation.guest.nationality
          }
        },
        idempotency_key: check_in.idempotency_key_for(:pms),
        operation: "check_in",
        check_in:
      )
    end
  end
end
