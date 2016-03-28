# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160328082837) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "admin_users", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "admin_users", ["user_id"], name: "index_admin_users_on_user_id", using: :btree

  create_table "api_users", force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.string   "api_key"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.datetime "token_expires_at"
    t.integer  "user_id"
  end

  add_index "api_users", ["user_id"], name: "index_api_users_on_user_id", unique: true, using: :btree

  create_table "connector_rests", force: :cascade do |t|
    t.string   "connector_name",               null: false
    t.string   "connector_url",                null: false
    t.integer  "connector_format", default: 0, null: false
    t.string   "connector_path"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  create_table "datasets", force: :cascade do |t|
    t.jsonb    "table_columns"
    t.string   "table_name"
    t.integer  "format",        default: 1
    t.integer  "row_count"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.integer  "dateable_id"
    t.string   "dateable_type"
  end

  add_index "datasets", ["dateable_id", "dateable_type"], name: "index_datasets_on_connector_and_connector_type", unique: true, using: :btree

  create_table "favourites", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "favorable_id"
    t.string   "favorable_type"
    t.string   "uri",                        null: false
    t.string   "name"
    t.integer  "position",       default: 0, null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "favourites", ["user_id", "favorable_id", "favorable_type"], name: "index_favourites_on_user_id_and_favorable_id_and_favorable_type", unique: true, using: :btree
  add_index "favourites", ["user_id"], name: "index_favourites_on_user_id", using: :btree

  create_table "layers", force: :cascade do |t|
    t.integer  "widget_id"
    t.integer  "provider",   default: 0, null: false
    t.jsonb    "options",                null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "layers", ["widget_id"], name: "index_layers_on_widget_id", using: :btree

  create_table "manager_users", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "manager_users", ["user_id"], name: "index_manager_users_on_user_id", using: :btree

  create_table "rest_connector_params", force: :cascade do |t|
    t.integer  "connector_id"
    t.integer  "param_type",   default: 1
    t.string   "key_name"
    t.string   "value"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "rest_connector_params", ["connector_id"], name: "index_rest_connector_params_on_connector_id", using: :btree

  create_table "rest_connectors", force: :cascade do |t|
    t.string   "connector_name"
    t.string   "connector_url"
    t.integer  "connector_format",   default: 0
    t.string   "connector_path"
    t.integer  "connector_provider", default: 0
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.string   "attributes_path"
  end

  create_table "users", force: :cascade do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "organization"
    t.string   "email"
    t.string   "password_digest"
    t.boolean  "active",               default: true, null: false
    t.datetime "deactivated_at"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "authentication_token"
    t.datetime "token_expires_at"
    t.datetime "last_sign_in_at"
    t.datetime "current_sign_in_at"
    t.inet     "last_sign_in_ip"
    t.inet     "current_sign_in_ip"
    t.integer  "sign_in_count",        default: 0,    null: false
  end

  add_index "users", ["authentication_token"], name: "index_users_on_authentication_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree

  create_table "widgets", force: :cascade do |t|
    t.text     "title"
    t.text     "description"
    t.jsonb    "data",           default: {}
    t.jsonb    "chart",          default: {}
    t.text     "data_source"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.string   "slug"
    t.boolean  "verified",       default: false
    t.integer  "user_id"
    t.datetime "deactivated_at"
    t.boolean  "active",         default: true,  null: false
  end

  add_index "widgets", ["user_id"], name: "index_widgets_on_user_id", using: :btree

  add_foreign_key "admin_users", "users"
  add_foreign_key "api_users", "users"
  add_foreign_key "favourites", "users"
  add_foreign_key "layers", "widgets"
  add_foreign_key "manager_users", "users"
  add_foreign_key "widgets", "users"
end
