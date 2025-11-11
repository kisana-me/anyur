module ApplicationHelper
  def full_title(t)
    (t.blank? ? "" : t + " | ") + "ANYUR"
  end

  def md_render(md, safe_render: false)
    ::MarkdownRenderer.render(md, safe_render: safe_render)
  end

  def md_render_toc(md)
    ::MarkdownRenderer.render_toc(md)
  end

  def md_render_plain(md)
    ::MarkdownRenderer.render_plain(md)
  end
end
