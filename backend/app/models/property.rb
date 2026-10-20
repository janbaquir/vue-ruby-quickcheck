class Property < ApplicationRecord
  has_many :rooms, dependent: :destroy
  has_many :reservations, dependent: :destroy

  validates :name, :code, :timezone, presence: true
end
