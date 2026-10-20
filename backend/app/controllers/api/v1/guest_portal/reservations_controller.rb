module Api
  module V1
    module GuestPortal
      class ReservationsController < BaseController
        def show
          render_reservation
        end
      end
    end
  end
end
