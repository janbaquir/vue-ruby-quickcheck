class ReservationSerializer
  def initialize(reservation, staff: false)
    @reservation = reservation
    @staff = staff
  end

  def as_json(*)
    r = @reservation
    {
      id: r.id,
      confirmation_code: r.confirmation_code,
      status: r.status,
      arrival_date: r.arrival_date,
      departure_date: r.departure_date,
      adults: r.adults,
      check_in_open: r.check_in_open?,
      property: { name: r.property.name, timezone: r.property.timezone },
      room: { number: r.room.number },
      guest: {
        first_name: r.guest.first_name,
        last_name: r.guest.last_name,
        email: r.guest.email,
        phone: r.guest.phone,
        nationality: r.guest.nationality,
        address: r.guest.address,
        passport_number: r.guest.masked_passport_number
      },
      check_in: check_in_json(r.check_in)
    }
  end

  private

  def check_in_json(check_in)
    return nil unless check_in

    {
      id: check_in.id,
      status: check_in.status,
      terminal: check_in.terminal?,
      pms_synced_at: check_in.pms_synced_at,
      key_issued_at: check_in.key_issued_at,
      failed_at: check_in.failed_at,
      digital_key: check_in.digital_key&.as_json(only: %i[access_code valid_from valid_until])
    }.tap { |json| json[:last_error] = check_in.last_error if @staff }
  end
end
