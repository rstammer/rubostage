# The song tools for `claude -p`, served from the running app, where the
# playing state and the open pages' streams live. Only for a client that
# holds this process's token, which only the app hands out.
class McpController < ActionController::API
  before_action :authenticate

  def create
    song = Song.find(params[:song_id])
    response = SongTools::Mcp.new(song).handle(JSON.parse(request.raw_post))
    response ? render(json: response) : head(:accepted)
  rescue JSON::ParserError
    render json: {jsonrpc: "2.0", id: nil, error: {code: -32700, message: "Parse error"}}, status: :bad_request
  end

  private

  def authenticate
    given = request.authorization.to_s.delete_prefix("Bearer ")
    head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(given, Rails.application.config.x.mcp_token)
  end
end
