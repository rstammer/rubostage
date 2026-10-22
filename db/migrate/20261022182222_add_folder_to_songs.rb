class AddFolderToSongs < ActiveRecord::Migration[8.1]
  def change
    add_column :songs, :folder, :string
    add_index :songs, :folder, unique: true
  end
end
