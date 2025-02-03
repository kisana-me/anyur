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

ActiveRecord::Schema[8.0].define(version: 1) do
  create_table "accounts", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "aid", default: "", null: false
    t.string "name", default: "", null: false
    t.string "name_id", default: "", null: false
    t.string "email", default: "", null: false
    t.boolean "email_verified", default: false, null: false
    t.text "cache", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.text "meta", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.text "settings", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.string "password_digest", default: "", null: false
    t.integer "status", limit: 1, default: 0, null: false
    t.boolean "deleted", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["aid"], name: "index_accounts_on_aid", unique: true
    t.index ["name_id"], name: "index_accounts_on_name_id", unique: true
    t.check_constraint "json_valid(`cache`)", name: "cache"
    t.check_constraint "json_valid(`meta`)", name: "meta"
    t.check_constraint "json_valid(`settings`)", name: "settings"
  end
end
