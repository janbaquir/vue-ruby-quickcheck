module Api
  module V1
    module Staff
      class CheckInsController < BaseController
        def retry
          check_in = CheckIn.find(params[:id])
          return render_error :conflict, "Only failed check-ins can be retried", status: :conflict unless check_in.retry!

          render json: { reservation: ReservationSerializer.new(check_in.reservation.reload).as_json }, status: :accepted
        end
      end
    end
  end
end
