class AddRecordingStatusToSongs < ActiveRecord::Migration[8.1]
  def change
    add_column :songs, :recording_status, :string, null: false, default: "none"
  end
end
