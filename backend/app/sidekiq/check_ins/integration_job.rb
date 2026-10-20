module CheckIns
  module IntegrationJob
    extend ActiveSupport::Concern

    MAX_RETRIES = 6

    included do
      include Sidekiq::Job
      sidekiq_options queue: :integrations, retry: MAX_RETRIES

      # Short backoff on purpose: the guest is standing at the door.
      sidekiq_retry_in { |count, _exception| (2**(count + 1)) + rand(3) }

      sidekiq_retries_exhausted do |job, exception|
        CheckIn.find_by(id: job["args"].first)&.mark_failed!(exception.message)
      end
    end

    private

    def with_failure_handling(check_in)
      yield
    rescue Integrations::PermanentError => e
      check_in.mark_failed!(e.message)
    end
  end
end
