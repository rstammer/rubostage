class CreateSongMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :song_messages do |t|
      t.references :song, null: false, foreign_key: true
      t.string :role, null: false
      t.text :body, null: false
      t.timestamps
    end
  end
end
