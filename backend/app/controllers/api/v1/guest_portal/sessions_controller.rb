module Api
  module V1
    module GuestPortal
      class SessionsController < BaseController
        skip_before_action :authenticate_guest!
        rate_limit to: 10, within: 1.minute, only: :create, with: -> {
          render_error :too_many_requests, "Too many attempts. Please wait a minute and try again.", status: :too_many_requests
        }

        def create
          reservation = Reservation.includes(:guest, :room, :property).find_for_guest(
            confirmation_code: params.require(:confirmation_code),
            last_name: params.require(:last_name)
          )

          # Same response for unknown code and wrong name to avoid enumeration.
          return render_error :not_found, "We couldn't find a booking with those details.", status: :not_found unless reservation

          render json: { token: reservation.guest_token, reservation: ReservationSerializer.new(reservation).as_json }, status: :created
        end
      end
    end
  end
end
