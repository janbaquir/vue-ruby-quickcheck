FactoryBot.define do
  factory :property do
    name { "Sakura Stay Shibuya" }
    sequence(:code) { |n| "PROP-#{n}" }
  end

  factory :room do
    property
    sequence(:number) { |n| (300 + n).to_s }
    sequence(:lock_device_id) { |n| "lock-#{n}" }
  end

  factory :guest do
    first_name { "Emma" }
    last_name { "Smith" }
  end

  factory :reservation do
    room
    property { room.property }
    guest
    sequence(:confirmation_code) { |n| "QC#{9000 + n}" }
    sequence(:pms_reservation_id) { |n| "PMS-#{n}" }
    arrival_date { Time.zone.today }
    departure_date { arrival_date + 2 }
  end

  factory :check_in do
    reservation

    trait :pms_synced do
      status { :pms_synced }
      pms_synced_at { Time.current }
    end

    trait :failed do
      status { :failed }
      failed_at { Time.current }
      last_error { "pms check_in: HTTP 503" }
    end
  end
end
