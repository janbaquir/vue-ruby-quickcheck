module CheckIns
  class SyncToPmsJob
    include IntegrationJob

    def perform(check_in_id)
      check_in = CheckIn.find(check_in_id)
      return unless check_in.pending?

      with_failure_handling(check_in) do
        Integrations::PmsClient.new.check_in(check_in)
        IssueDigitalKeyJob.perform_async(check_in.id) if check_in.mark_pms_synced!
      end
    end
  end
end
