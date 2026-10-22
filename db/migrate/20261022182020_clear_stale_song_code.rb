# Until now a song's code column held the plain groove from the moment it was
# wished for: no arrangement, no step reports. Songs now play the code they
# keep, so that stale copy has to go; each song builds its code on next play.
class ClearStaleSongCode < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE songs SET code = NULL"
  end

  def down
  end
end
