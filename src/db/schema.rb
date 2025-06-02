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

ActiveRecord::Schema[8.0].define(version: 8) do
  create_table "accounts", id: { type: :string, limit: 14 }, charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.string "name_id", default: "", null: false
    t.string "email", default: "", null: false
    t.boolean "email_verified", default: false, null: false
    t.string "roles", default: "", null: false
    t.string "password_digest", default: "", null: false
    t.string "stripe_customer_id", default: "", null: false
    t.text "cache", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.text "settings", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.text "meta", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.integer "status", limit: 1, default: 0, null: false
    t.boolean "deleted", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name_id"], name: "index_accounts_on_name_id", unique: true
    t.check_constraint "json_valid(`cache`)", name: "cache"
    t.check_constraint "json_valid(`meta`)", name: "meta"
    t.check_constraint "json_valid(`settings`)", name: "settings"
  end

  create_table "activity_logs", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "account_id", limit: 14, null: false
    t.string "action_name", default: "", null: false
    t.string "previous_value", default: "", null: false
    t.string "new_value", default: "", null: false
    t.datetime "changed_at", default: -> { "current_timestamp(6)" }, null: false
    t.string "change_reason", default: "", null: false
    t.text "meta", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_activity_logs_on_account_id"
    t.check_constraint "json_valid(`meta`)", name: "meta"
  end

  create_table "documents", id: { type: :string, limit: 14 }, charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.string "name_id", default: "", null: false
    t.string "summary", default: "", null: false
    t.text "content", default: "", null: false
    t.text "content_cache", default: "", null: false
    t.datetime "published_at"
    t.datetime "edited_at"
    t.text "cache", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.text "settings", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.text "meta", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.integer "status", limit: 1, default: 0, null: false
    t.boolean "deleted", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name_id"], name: "index_documents_on_name_id", unique: true
    t.check_constraint "json_valid(`cache`)", name: "cache"
    t.check_constraint "json_valid(`meta`)", name: "meta"
    t.check_constraint "json_valid(`settings`)", name: "settings"
  end

  create_table "inquiries", id: { type: :string, limit: 14 }, charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "account_id", limit: 14
    t.string "service_id", limit: 14
    t.string "subject", default: "", null: false
    t.string "summary", default: "", null: false
    t.text "content", default: "", null: false
    t.text "name", default: "", null: false
    t.string "email", default: "", null: false
    t.text "memo", default: "", null: false
    t.text "cache", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.text "settings", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.text "meta", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.integer "status", limit: 1, default: 0, null: false
    t.boolean "deleted", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_inquiries_on_account_id"
    t.index ["service_id"], name: "index_inquiries_on_service_id"
    t.check_constraint "json_valid(`cache`)", name: "cache"
    t.check_constraint "json_valid(`meta`)", name: "meta"
    t.check_constraint "json_valid(`settings`)", name: "settings"
  end

  create_table "personas", id: { type: :string, limit: 14 }, charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "account_id", limit: 14, null: false
    t.string "service_id", limit: 14, null: false
    t.string "name", default: "", null: false
    t.string "authorization_code_lookup", default: "", null: false
    t.string "authorization_code_digest", default: "", null: false
    t.datetime "authorization_code_expires_at"
    t.datetime "authorization_code_generated_at"
    t.string "access_token_lookup", default: "", null: false
    t.string "access_token_digest", default: "", null: false
    t.datetime "access_token_expires_at"
    t.datetime "access_token_generated_at"
    t.string "refresh_token_lookup", default: "", null: false
    t.string "refresh_token_digest", default: "", null: false
    t.datetime "refresh_token_expires_at"
    t.datetime "refresh_token_generated_at"
    t.text "scopes", size: :long, default: "[]", null: false, collation: "utf8mb4_bin"
    t.text "cache", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.text "settings", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.text "meta", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.integer "status", limit: 1, default: 0, null: false
    t.boolean "deleted", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["access_token_lookup"], name: "index_personas_on_access_token_lookup", unique: true
    t.index ["account_id"], name: "index_personas_on_account_id"
    t.index ["authorization_code_lookup"], name: "index_personas_on_authorization_code_lookup", unique: true
    t.index ["refresh_token_lookup"], name: "index_personas_on_refresh_token_lookup", unique: true
    t.index ["service_id"], name: "index_personas_on_service_id"
    t.check_constraint "json_valid(`cache`)", name: "cache"
    t.check_constraint "json_valid(`meta`)", name: "meta"
    t.check_constraint "json_valid(`scopes`)", name: "scopes"
    t.check_constraint "json_valid(`settings`)", name: "settings"
  end

  create_table "services", id: { type: :string, limit: 14 }, charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.string "name_id", default: "", null: false
    t.string "summary", default: "", null: false
    t.text "description", default: "", null: false
    t.text "description_cache", default: "", null: false
    t.string "host", default: "", null: false
    t.string "client_secret_lookup", default: "", null: false
    t.string "client_secret_digest", default: "", null: false
    t.datetime "client_secret_expires_at"
    t.datetime "client_secret_generated_at"
    t.text "redirect_uris", size: :long, default: "[]", null: false, collation: "utf8mb4_bin"
    t.text "scopes", size: :long, default: "[]", null: false, collation: "utf8mb4_bin"
    t.text "cache", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.text "settings", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.text "meta", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.integer "status", limit: 1, default: 0, null: false
    t.boolean "deleted", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name_id"], name: "index_services_on_name_id", unique: true
    t.check_constraint "json_valid(`cache`)", name: "cache"
    t.check_constraint "json_valid(`meta`)", name: "meta"
    t.check_constraint "json_valid(`redirect_uris`)", name: "redirect_uris"
    t.check_constraint "json_valid(`scopes`)", name: "scopes"
    t.check_constraint "json_valid(`settings`)", name: "settings"
  end

  create_table "sessions", id: { type: :string, limit: 14 }, charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "account_id", limit: 14, null: false
    t.string "name", default: "", null: false
    t.string "user_agent", default: "", null: false
    t.string "ip_address", default: "", null: false
    t.string "token_lookup", default: "", null: false
    t.string "token_digest", default: "", null: false
    t.datetime "token_expires_at"
    t.datetime "token_generated_at"
    t.text "meta", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.integer "status", limit: 1, default: 0, null: false
    t.boolean "deleted", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_sessions_on_account_id"
    t.check_constraint "json_valid(`meta`)", name: "meta"
  end

  create_table "subscriptions", id: { type: :string, limit: 14 }, charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "account_id", limit: 14, null: false
    t.string "stripe_subscription_id", default: "", null: false
    t.string "stripe_plan_id", default: "", null: false
    t.datetime "current_period_start"
    t.datetime "current_period_end"
    t.boolean "cancel_at_period_end", default: false
    t.datetime "canceled_at"
    t.datetime "trial_start_at"
    t.datetime "trial_end_at"
    t.text "cache", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.text "settings", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.text "meta", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.integer "status", limit: 1, default: 0, null: false
    t.boolean "deleted", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_subscriptions_on_account_id"
    t.index ["stripe_subscription_id"], name: "index_subscriptions_on_stripe_subscription_id", unique: true
    t.check_constraint "json_valid(`cache`)", name: "cache"
    t.check_constraint "json_valid(`meta`)", name: "meta"
    t.check_constraint "json_valid(`settings`)", name: "settings"
  end

  add_foreign_key "activity_logs", "accounts"
  add_foreign_key "inquiries", "accounts"
  add_foreign_key "inquiries", "services"
  add_foreign_key "personas", "accounts"
  add_foreign_key "personas", "services"
  add_foreign_key "sessions", "accounts"
  add_foreign_key "subscriptions", "accounts"
end
