class IntegrationEvent < ApplicationRecord
  belongs_to :check_in, optional: true

  enum :outcome, { success: "success", transient_failure: "transient_failure", permanent_failure: "permanent_failure" }

  scope :recent, -> { order(created_at: :desc) }
  scope :failures, -> { where(outcome: %w[transient_failure permanent_failure]) }
end
