module Api
  module V1
    module Staff
      class IntegrationEventsController < BaseController
        def index
          events = IntegrationEvent.recent.includes(check_in: { reservation: :guest }).limit(50)
          events = events.failures if params[:failures_only] == "true"

          render json: {
            events: events.map do |e|
              e.as_json(only: %i[id provider operation outcome http_status duration_ms error_message created_at])
                .merge(confirmation_code: e.check_in&.reservation&.confirmation_code)
            end
          }
        end
      end
    end
  end
end
