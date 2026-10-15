class AddRiffTrackToSongs < ActiveRecord::Migration[8.1]
  def change
    add_column :songs, :riff_track, :json
  end
end
