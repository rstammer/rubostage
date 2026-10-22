class SettingsController < ApplicationController
  def show
    @songs_root = Setting.songs_root.to_s
  end

  def update
    Setting.songs_root = params[:songs_root]
    SongExport.mirror_all
    redirect_to settings_path, notice: "Songs landen jetzt in #{Setting.songs_root}."
  rescue Setting::Invalid => e
    @songs_root = params[:songs_root].to_s
    @error = e.message
    render :show, status: :unprocessable_content
  end
end
