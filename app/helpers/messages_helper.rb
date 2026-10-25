module MessagesHelper
  # Claude answers in markdown. Rendered with HTML filtered out, so an answer
  # can set text in bold or list things, but never put markup into the page.
  MARKDOWN = Redcarpet::Markdown.new(
    Redcarpet::Render::HTML.new(filter_html: true, no_images: true, safe_links_only: true, hard_wrap: true),
    autolink: true, fenced_code_blocks: true, lax_spacing: true, no_intra_emphasis: true, strikethrough: true
  )

  def chat_markdown(text)
    tag.div(MARKDOWN.render(text.to_s).html_safe, class: "chat-text")
  end
end
