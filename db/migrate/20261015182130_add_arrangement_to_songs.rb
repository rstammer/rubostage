class AddArrangementToSongs < ActiveRecord::Migration[8.1]
  def change
    add_column :songs, :arrangement, :json
    add_column :songs, :arrangement_status, :string, null: false, default: "none"
  end
end
