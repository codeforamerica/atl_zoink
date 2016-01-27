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

ActiveRecord::Schema.define(version: 20160127005233) do

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
