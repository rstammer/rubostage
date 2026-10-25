# What Claude may do with a song in the chat: read it, change the sheet,
# change the band. Each tool is plain Ruby with a name, a description and a
# JSON schema for its input, so any client can offer it — MCP for
# `claude -p` today, RubyLLM tools later. Changes go through SongChange and
# can be taken back.
module SongTools
  class Error < StandardError; end

  ALL = -> {
    [SongTools::GetSong, SongTools::EditSheet, SongTools::EditBand, SongTools::EditRiffs,
      SongTools::Rearrange, SongTools::Play, SongTools::Stop]
  }

  def self.all = ALL.call

  def self.find(name) = all.find { |tool| tool.tool_name == name }
end
