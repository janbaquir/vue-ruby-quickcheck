module CheckIns
  class IssueDigitalKeyJob
    include IntegrationJob

    def perform(check_in_id)
      check_in = CheckIn.find(check_in_id)
      return unless check_in.pms_synced?

      with_failure_handling(check_in) do
        key = Integrations::LockClient.new.issue_key(check_in)

        CheckIn.transaction do
          check_in.digital_key || check_in.create_digital_key!(
            external_key_id: key.fetch("key_id"),
            access_code: key.fetch("access_code"),
            valid_from: key.fetch("valid_from"),
            valid_until: key.fetch("valid_until")
          )
          check_in.mark_key_issued!
          check_in.reservation.checked_in!
        end
      end
    end
  end
end
