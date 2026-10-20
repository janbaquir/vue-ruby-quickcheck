property = Property.find_or_create_by!(code: "SKR-SHIBUYA") do |p|
  p.name = "Sakura Stay Shibuya"
  p.timezone = "Asia/Tokyo"
end

rooms = (301..308).to_h do |number|
  room = property.rooms.find_or_create_by!(number: number.to_s) { |r| r.lock_device_id = "lock-shibuya-#{number}" }
  [ number, room ]
end

today = Time.current.in_time_zone(property.timezone).to_date

[
  { code: "QC1001", pms: "PMS-88120", room: 301, nights: 2, guest: { first_name: "Yuki", last_name: "Tanaka", nationality: "JP" } },
  { code: "QC1002", pms: "PMS-88121", room: 302, nights: 3, guest: { first_name: "Emma", last_name: "Smith", nationality: "GB" } },
  { code: "QC1003", pms: "PMS-88122", room: 303, nights: 1, guest: { first_name: "Miguel", last_name: "Santos", nationality: "PH" } },
  { code: "QC1004", pms: "PMS-88123", room: 304, nights: 4, guest: { first_name: "Ji-woo", last_name: "Kim", nationality: "KR" } },
  # Cancelled in the PMS only: check-in is rejected with a 409 (permanent failure path).
  { code: "QC1005", pms: "CXL-88124", room: 305, nights: 2, guest: { first_name: "Liam", last_name: "Brown", nationality: "AU" } }
].each do |data|
  reservation = Reservation.find_or_initialize_by(confirmation_code: data[:code])
  reservation.guest ||= Guest.new(data[:guest])
  reservation.assign_attributes(
    property:,
    room: rooms.fetch(data[:room]),
    pms_reservation_id: data[:pms],
    arrival_date: today,
    departure_date: today + data[:nights],
    adults: 2
  )
  reservation.save!
end

puts "Seeded #{Reservation.count} reservations arriving #{today}"
