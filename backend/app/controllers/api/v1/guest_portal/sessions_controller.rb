module Api
  module V1
    module GuestPortal
      class SessionsController < BaseController
        skip_before_action :authenticate_guest!

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
