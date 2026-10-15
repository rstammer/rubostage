class CreateSongs < ActiveRecord::Migration[8.1]
  def change
    create_table :songs do |t|
      t.string :request, null: false
      t.string :title
      t.string :artist
      t.string :key
      t.integer :bpm
      t.json :sheet
      t.text :code
      t.string :status, null: false, default: "pending"
      t.text :error

      t.timestamps
    end
  end
end
