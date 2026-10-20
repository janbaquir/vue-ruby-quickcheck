class Guest < ApplicationRecord
  encrypts :passport_number

  has_many :reservations, dependent: :restrict_with_error

  validates :first_name, :last_name, presence: true

  with_options on: :check_in do
    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :nationality, presence: true, format: { with: /\A[A-Z]{2}\z/, message: "must be a 2-letter country code" }
    validates :address, presence: true
    # Required for foreign nationals under Japan's Hotel Business Act.
    validates :passport_number, presence: true, if: :foreign_national?
  end

  def foreign_national?
    nationality.present? && nationality != "JP"
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def masked_passport_number
    passport_number.presence && "•••••#{passport_number.last(3)}"
  end
end
