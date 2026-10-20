class Room < ApplicationRecord
  belongs_to :property
  has_many :reservations, dependent: :restrict_with_error

  validates :number, :lock_device_id, presence: true
end
