class CreateCoreTables < ActiveRecord::Migration[8.0]
  def change
    create_table :properties do |t|
      t.string :name, null: false
      t.string :code, null: false, index: { unique: true }
      t.string :timezone, null: false, default: "Asia/Tokyo"
      t.timestamps
    end

    create_table :rooms do |t|
      t.references :property, null: false, foreign_key: true
      t.string :number, null: false
      t.string :lock_device_id, null: false, index: { unique: true }
      t.timestamps
    end
    add_index :rooms, [ :property_id, :number ], unique: true

    create_table :guests do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email
      t.string :phone
      t.string :nationality, limit: 2
      t.string :passport_number
      t.string :address
      t.timestamps
    end

    create_table :reservations do |t|
      t.references :property, null: false, foreign_key: true
      t.references :room, null: false, foreign_key: true
      t.references :guest, null: false, foreign_key: true
      t.string :confirmation_code, null: false, index: { unique: true }
      t.string :pms_reservation_id, null: false, index: { unique: true }
      t.date :arrival_date, null: false
      t.date :departure_date, null: false
      t.integer :adults, null: false, default: 1
      t.string :status, null: false, default: "booked"
      t.timestamps
    end
    add_index :reservations, :arrival_date
  end
end
