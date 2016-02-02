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

ActiveRecord::Schema.define(version: 20160202190542) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "appointments", force: :cascade do |t|
    t.integer  "citation_id",         null: false
    t.string   "defendant_full_name"
    t.string   "room"
    t.string   "date"
    t.string   "time"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  add_index "appointments", ["citation_id"], name: "index_appointments_on_citation_id", using: :btree

  create_table "atlanta_citation_hearings", force: :cascade do |t|
    t.string   "citation_guid",  null: false
    t.datetime "appointment_at", null: false
    t.string   "room"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "atlanta_citation_hearings", ["citation_guid", "appointment_at"], name: "ach_composite_key", unique: true, using: :btree

  create_table "atlanta_citation_violations", force: :cascade do |t|
    t.string   "citation_guid",  null: false
    t.string   "violation_code", null: false
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "atlanta_citation_violations", ["citation_guid", "violation_code"], name: "acv_composite_key", unique: true, using: :btree

  create_table "atlanta_citations", force: :cascade do |t|
    t.string   "guid",                null: false
    t.string   "defendant_full_name"
    t.string   "location"
    t.boolean  "payable"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  add_index "atlanta_citations", ["guid"], name: "index_atlanta_citations_on_guid", unique: true, using: :btree

  create_table "atlanta_distinct_objects", primary_key: "min_object_id", force: :cascade do |t|
    t.string  "guid"
    t.string  "location"
    t.boolean "payable"
    t.string  "defendant"
    t.string  "date"
    t.string  "time"
    t.string  "room"
    t.string  "violation"
    t.string  "description"
    t.integer "object_count", limit: 8
    t.text    "object_ids"
    t.text    "endpoint_ids"
  end

  add_index "atlanta_distinct_objects", ["guid"], name: "guid_index", using: :btree
  add_index "atlanta_distinct_objects", ["violation"], name: "violation_index", using: :btree

  create_table "atlanta_endpoint_objects", force: :cascade do |t|
    t.integer "endpoint_id", null: false
    t.string  "date"
    t.string  "defendant"
    t.string  "location"
    t.string  "room"
    t.string  "time"
    t.string  "guid"
    t.string  "violation"
    t.string  "description"
    t.boolean "payable"
  end

  add_index "atlanta_endpoint_objects", ["endpoint_id"], name: "index_atlanta_endpoint_objects_on_endpoint_id", using: :btree

  create_table "atlanta_endpoints", force: :cascade do |t|
    t.date     "upload_date",          null: false
    t.datetime "requested_at"
    t.datetime "response_received_at"
    t.integer  "response_code"
    t.string   "string_encoding"
    t.integer  "row_count"
    t.datetime "extracted_at"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "atlanta_endpoints", ["upload_date"], name: "index_atlanta_endpoints_on_upload_date", unique: true, using: :btree

  create_table "atlanta_violations", force: :cascade do |t|
    t.string   "code",        null: false
    t.string   "description"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "atlanta_violations", ["code"], name: "index_atlanta_violations_on_code", unique: true, using: :btree

  create_table "citations", force: :cascade do |t|
    t.string   "guid"
    t.integer  "violation_id", null: false
    t.string   "location"
    t.boolean  "payable"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "citations", ["guid"], name: "index_citations_on_guid", using: :btree
  add_index "citations", ["violation_id"], name: "index_citations_on_violation_id", using: :btree

  create_table "data_urls", force: :cascade do |t|
    t.date     "upload_date",                     null: false
    t.datetime "requested_at"
    t.integer  "response_code"
    t.string   "string_encoding"
    t.integer  "row_count"
    t.boolean  "extracted",       default: false
    t.datetime "extracted_at"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  add_index "data_urls", ["upload_date"], name: "index_data_urls_on_upload_date", unique: true, using: :btree

  create_table "violations", force: :cascade do |t|
    t.string   "guid"
    t.string   "description"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "violations", ["guid"], name: "index_violations_on_guid", using: :btree

end
