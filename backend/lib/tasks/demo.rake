namespace :demo do
  desc "Clear check-ins and re-seed so the demo can be run again"
  task reset: :environment do
    IntegrationEvent.delete_all
    DigitalKey.delete_all
    CheckIn.delete_all
    Reservation.update_all(status: "booked")
    Guest.update_all(email: nil, phone: nil, passport_number: nil, address: nil)
    Rake::Task["db:seed"].invoke
  end
end
