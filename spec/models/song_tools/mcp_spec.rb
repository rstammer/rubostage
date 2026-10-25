require "rails_helper"

RSpec.describe SongTools::Mcp do
  let(:song) { create(:song, :ready) }
  let(:mcp) { described_class.new(song) }

  def rpc(method, params = {}, id: 1) = mcp.handle({"jsonrpc" => "2.0", "id" => id, "method" => method, "params" => params})

  it "introduces itself as a server with tools" do
    result = rpc("initialize", {"protocolVersion" => "2025-06-18"})[:result]
    expect(result).to include(protocolVersion: "2025-06-18", capabilities: {tools: {}})
    expect(result[:serverInfo][:name]).to eq("rubostage")
  end

  it "lists the song tools with their schemas" do
    tools = rpc("tools/list")[:result][:tools]
    expect(tools.map { |tool| tool[:name] }).to eq(%w[get_song edit_sheet edit_band edit_riffs rearrange play stop])
    expect(tools.first).to include(:description, :inputSchema)
  end

  it "calls a tool and answers in text" do
    result = rpc("tools/call", {"name" => "get_song", "arguments" => {}})[:result]
    expect(result[:isError]).to be(false)
    expect(JSON.parse(result[:content].first[:text])["title"]).to eq("Starlight")
  end

  it "hands a tool's refusal back to the model as an error result" do
    result = rpc("tools/call", {"name" => "edit_band", "arguments" => {"summary" => "x", "sounds" => {"bass" => "kazoo"}}})[:result]
    expect(result[:isError]).to be(true)
    expect(result[:content].first[:text]).to include("kazoo")
  end

  it "answers notifications with nothing and unknown methods with an error" do
    expect(mcp.handle({"jsonrpc" => "2.0", "method" => "notifications/initialized"})).to be_nil
    expect(rpc("resources/list")[:error][:code]).to eq(-32601)
  end
end
