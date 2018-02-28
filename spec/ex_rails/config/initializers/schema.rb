ActiveRecord::Schema.define do

  create_table "artists" do |t|
    t.string "name"
    t.string "genre"
    t.date "last_release"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end

