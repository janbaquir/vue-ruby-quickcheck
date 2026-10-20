class Reservation < ApplicationRecord
  GUEST_SESSION_TTL = 2.hours

  belongs_to :property
  belongs_to :room
  belongs_to :guest
  has_one :check_in, dependent: :destroy

  enum :status, { booked: "booked", checked_in: "checked_in", cancelled: "cancelled" }, default: :booked

  validates :confirmation_code, :pms_reservation_id, :arrival_date, :departure_date, presence: true
  validate :departure_after_arrival

  scope :arriving_on, ->(date) { where(arrival_date: date) }

  def self.find_for_guest(confirmation_code:, last_name:)
    joins(:guest)
      .where(confirmation_code: confirmation_code.to_s.strip.upcase)
      .where("LOWER(guests.last_name) = ?", last_name.to_s.strip.downcase)
      .first
  end

  def self.find_by_guest_token(token)
    find_signed(token, purpose: :guest_session)
  end

  def guest_token
    signed_id(purpose: :guest_session, expires_in: GUEST_SESSION_TTL)
  end

  def check_in_open?(today = Time.current.in_time_zone(property.timezone).to_date)
    booked? && today >= arrival_date && today < departure_date
  end

  def key_valid_from
    [ local_time(arrival_date, 15), Time.current ].min
  end

  def key_valid_until
    local_time(departure_date, 11)
  end

  private

  def local_time(date, hour)
    ActiveSupport::TimeZone[property.timezone].local(date.year, date.month, date.day, hour)
  end

  def departure_after_arrival
    return if arrival_date.blank? || departure_date.blank?
    errors.add(:departure_date, "must be after arrival date") if departure_date <= arrival_date
  end
end
