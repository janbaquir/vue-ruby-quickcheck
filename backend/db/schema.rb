# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_10_20_000002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "check_ins", force: :cascade do |t|
    t.bigint "reservation_id", null: false
    t.string "status", default: "pending", null: false
    t.uuid "idempotency_key", null: false
    t.datetime "pms_synced_at"
    t.datetime "key_issued_at"
    t.datetime "failed_at"
    t.text "last_error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["idempotency_key"], name: "index_check_ins_on_idempotency_key", unique: true
    t.index ["reservation_id"], name: "index_check_ins_on_reservation_id", unique: true
    t.index ["status"], name: "index_check_ins_on_status"
  end

  create_table "digital_keys", force: :cascade do |t|
    t.bigint "check_in_id", null: false
    t.string "external_key_id", null: false
    t.string "access_code", null: false
    t.datetime "valid_from", null: false
    t.datetime "valid_until", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["check_in_id"], name: "index_digital_keys_on_check_in_id", unique: true
    t.index ["external_key_id"], name: "index_digital_keys_on_external_key_id", unique: true
  end

  create_table "guests", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email"
    t.string "phone"
    t.string "nationality", limit: 2
    t.string "passport_number"
    t.string "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "integration_events", force: :cascade do |t|
    t.bigint "check_in_id"
    t.string "provider", null: false
    t.string "operation", null: false
    t.string "outcome", null: false
    t.integer "http_status"
    t.integer "duration_ms"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.index ["check_in_id"], name: "index_integration_events_on_check_in_id"
    t.index ["outcome", "created_at"], name: "index_integration_events_on_outcome_and_created_at"
  end

  create_table "properties", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.string "timezone", default: "Asia/Tokyo", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_properties_on_code", unique: true
  end

  create_table "reservations", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.bigint "room_id", null: false
    t.bigint "guest_id", null: false
    t.string "confirmation_code", null: false
    t.string "pms_reservation_id", null: false
    t.date "arrival_date", null: false
    t.date "departure_date", null: false
    t.integer "adults", default: 1, null: false
    t.string "status", default: "booked", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["arrival_date"], name: "index_reservations_on_arrival_date"
    t.index ["confirmation_code"], name: "index_reservations_on_confirmation_code", unique: true
    t.index ["guest_id"], name: "index_reservations_on_guest_id"
    t.index ["pms_reservation_id"], name: "index_reservations_on_pms_reservation_id", unique: true
    t.index ["property_id"], name: "index_reservations_on_property_id"
    t.index ["room_id"], name: "index_reservations_on_room_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.string "number", null: false
    t.string "lock_device_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lock_device_id"], name: "index_rooms_on_lock_device_id", unique: true
    t.index ["property_id", "number"], name: "index_rooms_on_property_id_and_number", unique: true
    t.index ["property_id"], name: "index_rooms_on_property_id"
  end

  add_foreign_key "check_ins", "reservations"
  add_foreign_key "digital_keys", "check_ins"
  add_foreign_key "integration_events", "check_ins"
  add_foreign_key "reservations", "guests"
  add_foreign_key "reservations", "properties"
  add_foreign_key "reservations", "rooms"
  add_foreign_key "rooms", "properties"
end
