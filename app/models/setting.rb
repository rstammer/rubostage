# What is set once for the whole stage, kept as key and value. For now that
# is only the songs folder: where every song lands as live.rb and NOTES.md.
class Setting < ApplicationRecord
  class Invalid < StandardError; end

  validates :key, presence: true, uniqueness: true

  def self.songs_root
    value = find_by(key: "songs_root")&.value
    value ? Pathname(value) : Rails.application.config.x.songs_root
  end

  def self.songs_root=(path)
    dir = expand(path)
    raise Invalid, "Den Ordner #{dir} gibt es nicht." unless dir.directory?
    raise Invalid, "In #{dir} kann rubostage nicht schreiben." unless dir.writable?

    find_or_initialize_by(key: "songs_root").update!(value: dir.to_s)
  end

  def self.expand(path)
    Pathname(File.expand_path(path.to_s.strip))
  end
end
