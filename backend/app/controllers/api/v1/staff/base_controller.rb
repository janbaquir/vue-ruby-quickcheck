module Api
  module V1
    module Staff
      class BaseController < ApplicationController
        before_action :authenticate_staff!

        private

        def authenticate_staff!
          expected = ENV.fetch("STAFF_API_TOKEN")
          provided = request.headers["X-Staff-Token"].to_s
          return if ActiveSupport::SecurityUtils.secure_compare(provided, expected)

          render_error :unauthorized, "Invalid staff token", status: :unauthorized
        end
      end
    end
  end
end
