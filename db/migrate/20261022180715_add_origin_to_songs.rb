class AddOriginToSongs < ActiveRecord::Migration[8.1]
  def change
    add_column :songs, :origin, :string, null: false, default: "wish"
    change_column_null :songs, :request, true
  end
end
