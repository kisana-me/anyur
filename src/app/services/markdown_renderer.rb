class MarkdownRenderer
  def self.render(markdown_text)
    renderer = Redcarpet::Render::HTML.new(
      filter_html: false,
      hard_wrap: true,
      with_toc_data: true
    )
    markdown = Redcarpet::Markdown.new(renderer, extensions = {
      tables: true,
      fenced_code_blocks: true,
      disable_indented_code_blocks: true,
      autolink: true,
      strikethrough: true,
      lax_spacing: true,
      space_after_headers: true,
      superscript: true,
      underline: true,
      highlight: true,
      quote: true,
      footnotes: true
    })
    markdown.render(markdown_text || "")
  end
  def self.toc_render(markdown_text)
    renderer = Redcarpet::Render::HTML_TOC.new(nesting_level: 6)
    markdown = Redcarpet::Markdown.new(renderer, space_after_headers: true)
    markdown.render(markdown_text || "")
  end
end
