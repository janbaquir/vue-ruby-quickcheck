module Integrations
  class HttpClient
    OPEN_TIMEOUT = 2
    READ_TIMEOUT = 5

    def initialize(base_url:, api_key:, provider:)
      @provider = provider
      @connection = Faraday.new(url: base_url) do |f|
        f.request :json
        f.response :json, content_type: /\bjson$/
        f.headers["Authorization"] = "Bearer #{api_key}"
        f.options.open_timeout = OPEN_TIMEOUT
        f.options.timeout = READ_TIMEOUT
      end
    end

    def post(path, body, idempotency_key:, operation:, check_in: nil)
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      response = nil
      error = nil

      begin
        response = @connection.post(path, body) { |req| req.headers["Idempotency-Key"] = idempotency_key }
        handle(response)
      rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
        error = TransientError.new("#{@provider} #{operation}: #{e.class.name.demodulize}")
        raise error
      rescue Error => e
        error = e.class.new("#{@provider} #{operation}: #{e.message}", http_status: e.http_status)
        raise error
      ensure
        record(operation:, check_in:, started:, response:, error:)
      end
    end

    private

    def handle(response)
      return response.body if response.success?

      message = "HTTP #{response.status} #{response.body.is_a?(Hash) ? response.body['error'] : nil}".strip
      error_class = response.status >= 500 || response.status == 429 ? TransientError : PermanentError
      raise error_class.new(message, http_status: response.status)
    end

    def record(operation:, check_in:, started:, response:, error:)
      IntegrationEvent.create!(
        provider: @provider,
        operation:,
        check_in:,
        outcome: outcome_for(error),
        http_status: response&.status || (error.respond_to?(:http_status) ? error.http_status : nil),
        duration_ms: ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round,
        error_message: error&.message
      )
    rescue StandardError => e
      Rails.logger.error("[integrations] failed to record event: #{e.message}")
    end

    def outcome_for(error)
      case error
      when nil then :success
      when PermanentError then :permanent_failure
      else :transient_failure
      end
    end
  end
end
