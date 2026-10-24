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

ActiveRecord::Schema[8.1].define(version: 2026_10_24_123030) do
  create_table "settings", force: :cascade do |t|
    t.string "key", null: false
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "song_messages", force: :cascade do |t|
    t.integer "song_id", null: false
    t.string "role", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["song_id"], name: "index_song_messages_on_song_id"
  end

  create_table "songs", force: :cascade do |t|
    t.string "request"
    t.string "title"
    t.string "artist"
    t.string "key"
    t.integer "bpm"
    t.json "sheet"
    t.text "code"
    t.string "status", default: "pending", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "arrangement"
    t.string "arrangement_status", default: "none", null: false
    t.json "riff_track"
    t.string "origin", default: "wish", null: false
    t.string "folder"
    t.string "recording_status", default: "none", null: false
    t.text "lyrics"
    t.index ["folder"], name: "index_songs_on_folder", unique: true
  end

  add_foreign_key "song_messages", "songs"
end
