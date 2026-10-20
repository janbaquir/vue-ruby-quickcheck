module Api
  module V1
    module Staff
      class ArrivalsController < BaseController
        def index
          date = params[:date].present? ? Date.iso8601(params[:date]) : Time.zone.today
          reservations = Reservation.arriving_on(date)
            .includes(:guest, :room, :property, check_in: :digital_key)
            .order("rooms.number").references(:rooms)

          render json: {
            date:,
            summary: summarize(reservations),
            arrivals: reservations.map { |r| ReservationSerializer.new(r, staff: true).as_json }
          }
        rescue Date::Error
          render_error :bad_request, "date must be YYYY-MM-DD", status: :bad_request
        end

        private

        def summarize(reservations)
          statuses = reservations.map { |r| r.check_in&.status || "not_started" }
          { total: reservations.size }.merge(statuses.tally.symbolize_keys)
        end
      end
    end
  end
end
