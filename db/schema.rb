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

ActiveRecord::Schema[7.2].define(version: 2024_08_10_214712) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "locations", id: :integer, default: nil, force: :cascade do |t|
    t.text "name", null: false
    t.text "city", null: false
  end

  create_table "technicians", id: :integer, default: nil, force: :cascade do |t|
    t.text "name", null: false
  end

  create_table "work_orders", id: :integer, default: nil, force: :cascade do |t|
    t.integer "technician_id", null: false
    t.integer "location_id", null: false
    t.datetime "time", precision: nil, null: false
    t.integer "duration"
    t.float "price", null: false
  end

  create_table "workorders", id: :integer, default: nil, force: :cascade do |t|
    t.integer "technician_id", null: false
    t.integer "location_id", null: false
    t.datetime "date", precision: nil
    t.float "duration"
    t.float "price"
  end

  add_foreign_key "work_orders", "locations", name: "work_orders_location_id_fkey"
  add_foreign_key "work_orders", "locations", name: "work_orders_location_id_fkey1"
  add_foreign_key "work_orders", "technicians", name: "work_orders_technician_id_fkey"
  add_foreign_key "work_orders", "technicians", name: "work_orders_technician_id_fkey1"
end