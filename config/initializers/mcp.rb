# Where `claude -p` reaches the song tools: this app, on the port it serves,
# with a token only local processes can read. It is kept in tmp/, so the
# server, its jobs and a console all hold the same one.
Rails.application.config.x.app_url = ENV.fetch("APP_URL") { "http://127.0.0.1:#{ENV.fetch("PORT", 3000)}" }
Rails.application.config.x.mcp_token = ENV["MCP_TOKEN"].presence || begin
  path = Rails.root.join("tmp/mcp_token")
  unless path.exist?
    FileUtils.mkdir_p(path.dirname)
    File.write(path, SecureRandom.hex(24), perm: 0o600)
  end
  path.read.strip
end
