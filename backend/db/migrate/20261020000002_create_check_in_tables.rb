class CreateCheckInTables < ActiveRecord::Migration[8.0]
  def change
    create_table :check_ins do |t|
      t.references :reservation, null: false, foreign_key: true, index: { unique: true }
      t.string :status, null: false, default: "pending"
      t.uuid :idempotency_key, null: false, index: { unique: true }
      t.datetime :pms_synced_at
      t.datetime :key_issued_at
      t.datetime :failed_at
      t.text :last_error
      t.timestamps
    end
    add_index :check_ins, :status

    create_table :digital_keys do |t|
      t.references :check_in, null: false, foreign_key: true, index: { unique: true }
      t.string :external_key_id, null: false, index: { unique: true }
      t.string :access_code, null: false
      t.datetime :valid_from, null: false
      t.datetime :valid_until, null: false
      t.timestamps
    end

    create_table :integration_events do |t|
      t.references :check_in, foreign_key: true
      t.string :provider, null: false
      t.string :operation, null: false
      t.string :outcome, null: false
      t.integer :http_status
      t.integer :duration_ms
      t.text :error_message
      t.datetime :created_at, null: false
    end
    add_index :integration_events, [ :outcome, :created_at ]
  end
end
