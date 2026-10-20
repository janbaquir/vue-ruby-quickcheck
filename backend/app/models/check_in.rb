class CheckIn < ApplicationRecord
  belongs_to :reservation
  has_one :digital_key, dependent: :destroy
  has_many :integration_events, dependent: :nullify

  enum :status, {
    pending: "pending",
    pms_synced: "pms_synced",
    key_issued: "key_issued",
    failed: "failed"
  }, default: :pending

  before_validation -> { self.idempotency_key ||= SecureRandom.uuid }, on: :create

  # Stable across retries so the provider deduplicates a request that
  # succeeded on their side but timed out on ours.
  def idempotency_key_for(step)
    "check-in-#{idempotency_key}-#{step}"
  end

  def mark_pms_synced!
    transition!(from: :pending, to: :pms_synced, pms_synced_at: Time.current)
  end

  def mark_key_issued!
    transition!(from: :pms_synced, to: :key_issued, key_issued_at: Time.current)
  end

  def mark_failed!(message)
    with_lock do
      next false if key_issued?
      update!(status: :failed, failed_at: Time.current, last_error: message.to_s.truncate(1000))
    end
  end

  def retry!
    retried = with_lock do
      next false unless failed?
      update!(status: pms_synced_at ? :pms_synced : :pending, failed_at: nil, last_error: nil)
    end
    enqueue_next_step if retried
    retried
  end

  def enqueue_next_step
    case status.to_sym
    when :pending then CheckIns::SyncToPmsJob.perform_async(id)
    when :pms_synced then CheckIns::IssueDigitalKeyJob.perform_async(id)
    end
  end

  def terminal?
    key_issued? || failed?
  end

  private

  def transition!(from:, to:, **attributes)
    with_lock do
      next false unless status.to_sym == from
      update!(status: to, **attributes)
    end
  end
end
