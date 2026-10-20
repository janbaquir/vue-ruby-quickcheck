module Api
  module V1
    module GuestPortal
      class BaseController < ApplicationController
        before_action :authenticate_guest!

        private

        attr_reader :current_reservation

        def authenticate_guest!
          token = request.authorization.to_s.delete_prefix("Bearer ")
          @current_reservation = Reservation.find_by_guest_token(token)
          render_error :unauthorized, "Your session has expired. Please look up your booking again.", status: :unauthorized unless @current_reservation
        end

        def render_reservation(status: :ok)
          render json: { reservation: ReservationSerializer.new(current_reservation.reload).as_json }, status:
        end
      end
    end
  end
end
