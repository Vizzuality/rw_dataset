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

ActiveRecord::Schema.define(version: 20160520110354) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "citext"
  enable_extension "uuid-ossp"

  create_table "datasets", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid     "dateable_id"
    t.string   "dateable_type"
    t.string   "name"
    t.integer  "format",          default: 0
    t.string   "data_path"
    t.string   "attributes_path"
    t.integer  "row_count"
    t.integer  "status",          default: 0
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.jsonb    "tags",            default: []
    t.index ["dateable_id", "dateable_type"], name: "index_datasets_on_connector_and_connector_type", unique: true, using: :btree
    t.index ["tags"], name: "index_datasets_on_tags", using: :gin
  end

  create_table "json_connectors", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.integer  "connector_provider",         default: 0
    t.string   "parent_connector_url"
    t.uuid     "parent_connector_id"
    t.string   "parent_connector_type"
    t.integer  "parent_connector_provider"
    t.string   "parent_connector_data_path"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.index ["connector_provider"], name: "index_json_connectors_on_connector_provider", using: :btree
  end

  create_table "rest_connectors", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.integer  "connector_provider", default: 0
    t.string   "connector_url"
    t.string   "table_name"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.index ["connector_provider"], name: "index_rest_connectors_on_connector_provider", using: :btree
  end

end
