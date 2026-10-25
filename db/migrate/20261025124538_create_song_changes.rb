class CreateSongChanges < ActiveRecord::Migration[8.1]
  def change
    create_table :song_changes do |t|
      t.references :song, null: false, foreign_key: true
      t.string :summary, null: false
      t.json :before, null: false
      t.datetime :undone_at
      t.timestamps
    end
  end
end
