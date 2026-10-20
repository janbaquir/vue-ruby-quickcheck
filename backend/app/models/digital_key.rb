class DigitalKey < ApplicationRecord
  belongs_to :check_in

  validates :external_key_id, :access_code, :valid_from, :valid_until, presence: true
end
