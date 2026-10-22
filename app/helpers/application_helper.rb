module ApplicationHelper
  # Symbols stamped into the footswitch caps, drawn on a 24 grid so they come
  # out the same size, which the Unicode arrows do not.
  FOOTSWITCH_ICONS = {
    play: '<path d="M8 5v14l11-7z"/>',
    stop: '<rect x="6" y="6" width="12" height="12" rx="1"/>',
    repeat: '<path d="M12 5a7 7 0 1 1-6.6 4.7" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round"/><path d="M3 4l6 1.5-4.5 4.5z"/>',
    next: '<path d="M5 5v14l9-7zM15 5h3v14h-3z"/>',
    end: '<path d="M12 4l8 9H4zM4 16h16v3H4z"/>',
    loop: '<path d="M7 8a4 4 0 1 0 0 8c2.2 0 3.4-1.8 5-4s2.8-4 5-4a4 4 0 1 1 0 8c-2.2 0-3.4-1.8-5-4s-2.8-4-5-4z" fill="none" stroke="currentColor" stroke-width="2.4"/>'
  }.freeze

  # The same symbols, small, for the buttons in the transport bar.
  def transport_icon(icon)
    tag.svg(FOOTSWITCH_ICONS.fetch(icon).html_safe, viewBox: "0 0 24 24", class: "size-3.5", fill: "currentColor", aria: {hidden: true})
  end

  def footswitch_cap(icon)
    tag.span(class: "footswitch-cap", aria: {hidden: true}) do
      tag.svg(FOOTSWITCH_ICONS.fetch(icon).html_safe, viewBox: "0 0 24 24", class: "size-6", fill: "currentColor")
    end
  end
end
