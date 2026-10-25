class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :sidebar_song, :sidebar_state, :sidebar_tab

  private

  # The song the sidebars are about: the one on the page, or else the one
  # last started, which the transport bar keeps at hand too.
  def sidebar_song
    return @sidebar_song if defined?(@sidebar_song)

    page = @song if @song&.persisted?
    page ||= Song.find_by(id: NowPlaying.started_song_id) if NowPlaying.started_song_id
    @sidebar_song = page if page&.ready?
  end

  # Drawn in or out, as the player left it. Kept in a cookie rather than in
  # the browser alone, so the page is drawn that way from the start.
  def sidebar_state(side)
    (cookies[:"sidebar_#{side}"] == "closed") ? "closed" : "open"
  end

  def sidebar_tab
    (cookies[:sidebar_tab] == "text") ? "text" : "songs"
  end
end
