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

ActiveRecord::Schema[8.0].define(version: 5) do
  create_table "accounts", id: { type: :string, limit: 14 }, charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.string "name_id", default: "", null: false
    t.string "email", default: "", null: false
    t.string "roles", default: "", null: false
    t.boolean "email_verified", default: false, null: false
    t.text "cache", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.text "meta", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.text "settings", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.string "password_digest", default: "", null: false
    t.integer "status", limit: 1, default: 0, null: false
    t.boolean "deleted", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name_id"], name: "index_accounts_on_name_id", unique: true
    t.check_constraint "json_valid(`cache`)", name: "cache"
    t.check_constraint "json_valid(`meta`)", name: "meta"
    t.check_constraint "json_valid(`settings`)", name: "settings"
  end

  create_table "documents", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.string "name_id", default: "", null: false
    t.text "content", default: "", null: false
    t.text "cache", default: "", null: false
    t.text "meta", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.integer "status", limit: 1, default: 0, null: false
    t.boolean "deleted", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.check_constraint "json_valid(`meta`)", name: "meta"
  end

  create_table "profiles", id: { type: :string, limit: 24 }, charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "account_id", null: false
    t.string "service_id", null: false
    t.string "name", default: "", null: false
    t.text "settings", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.text "meta", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.integer "status", limit: 1, default: 0, null: false
    t.boolean "deleted", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_profiles_on_account_id"
    t.index ["service_id"], name: "index_profiles_on_service_id"
    t.check_constraint "json_valid(`meta`)", name: "meta"
    t.check_constraint "json_valid(`settings`)", name: "settings"
  end

  create_table "services", id: { type: :string, limit: 24 }, charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.text "description", default: "", null: false
    t.string "host", default: "", null: false
    t.string "callback", default: "", null: false
    t.text "meta", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.integer "status", limit: 1, default: 0, null: false
    t.boolean "deleted", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.check_constraint "json_valid(`meta`)", name: "meta"
  end

  create_table "sessions", id: { type: :string, limit: 24 }, charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "account_id", null: false
    t.string "name", default: "", null: false
    t.string "user_agent", default: "", null: false
    t.string "ip_address", default: "", null: false
    t.string "token_digest", default: "", null: false
    t.boolean "deleted", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_sessions_on_account_id"
  end

  add_foreign_key "profiles", "accounts"
  add_foreign_key "profiles", "services"
  add_foreign_key "sessions", "accounts"
end
