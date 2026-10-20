class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound do
    render_error :not_found, "Not found", status: :not_found
  end

  rescue_from ActionController::ParameterMissing do |e|
    render_error :bad_request, e.message, status: :bad_request
  end

  private

  def render_error(code, message, status:, details: nil)
    render json: { error: { code:, message:, details: }.compact }, status:
  end
end
