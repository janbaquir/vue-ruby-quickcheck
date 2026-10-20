module Api
  module V1
    module GuestPortal
      class CheckInsController < BaseController
        def create
          result = CheckIns::Start.call(reservation: current_reservation, guest_attributes: guest_params)

          if result.success?
            render_reservation(status: :accepted)
          else
            render_error :validation_failed, "Please check the highlighted fields.", status: :unprocessable_content, details: result.errors
          end
        end

        private

        def guest_params
          params.require(:guest).permit(:first_name, :last_name, :email, :phone, :nationality, :passport_number, :address)
        end
      end
    end
  end
end
