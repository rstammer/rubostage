require "rails_helper"

RSpec.describe "The song tools over MCP", type: :request do
  let(:song) { create(:song, :ready) }
  let(:token) { Rails.application.config.x.mcp_token }
  let(:body) { {jsonrpc: "2.0", id: 1, method: "tools/list"}.to_json }

  def call_mcp(headers = {}) = post(song_mcp_path(song), params: body, headers: {"Content-Type" => "application/json"}.merge(headers))

  it "serves the tools to a client with the token" do
    call_mcp("Authorization" => "Bearer #{token}")
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("result", "tools").size).to eq(SongTools.all.size)
  end

  it "turns away a client without it" do
    call_mcp("Authorization" => "Bearer wrong")
    expect(response).to have_http_status(:unauthorized)
  end

  it "takes a notification without an answer" do
    post song_mcp_path(song), params: {jsonrpc: "2.0", method: "notifications/initialized"}.to_json,
      headers: {"Content-Type" => "application/json", "Authorization" => "Bearer #{token}"}
    expect(response).to have_http_status(:accepted)
  end
end
