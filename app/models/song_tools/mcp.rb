# The song tools as an MCP server: JSON-RPC over HTTP, just the methods a
# tool-calling client needs. Tools that refuse answer with isError, so the
# model reads why and can try again.
class SongTools::Mcp
  PROTOCOL_VERSION = "2025-06-18"

  def initialize(song, toolbox: SongTools::Toolbox.new(song))
    @toolbox = toolbox
  end

  # The response to one JSON-RPC message, or nil for a notification.
  def handle(message)
    id = message["id"]
    return if id.nil?

    result = case message["method"]
    when "initialize" then initialize_result(message["params"].to_h)
    when "ping" then {}
    when "tools/list" then {tools: @toolbox.tools.map { |tool| describe(tool) }}
    when "tools/call" then call_tool(message["params"].to_h)
    else return {jsonrpc: "2.0", id: id, error: {code: -32601, message: "Method not found: #{message["method"]}"}}
    end
    {jsonrpc: "2.0", id: id, result: result}
  end

  private

  def initialize_result(params)
    {protocolVersion: params["protocolVersion"].presence || PROTOCOL_VERSION,
     capabilities: {tools: {}}, serverInfo: {name: "rubostage", version: "1"}}
  end

  def describe(tool)
    {name: tool.tool_name, description: tool.description, inputSchema: tool.input_schema}
  end

  def call_tool(params)
    text = @toolbox.run(params["name"], params["arguments"])
    {content: [{type: "text", text: text}], isError: false}
  rescue SongTools::Error => e
    {content: [{type: "text", text: e.message}], isError: true}
  end
end
