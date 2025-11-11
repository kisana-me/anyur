class MarkdownRenderer
  def self.render(markdown_text, safe_render: false)
    text = markdown_text.to_s
    digest = Digest::SHA256.hexdigest(text)
    cache_key = [
      "markdown_renderer",
      "v1",
      safe_render ? "safe1" : "safe0",
      digest
    ].join(":")

    html = Rails.cache.fetch(cache_key) do
      options = {
        hard_wrap: true,
        with_toc_data: true,
        filter_html: safe_render
      }
      extensions = {
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
      }
      renderer = Redcarpet::Render::HTML.new(options)
      markdown = Redcarpet::Markdown.new(renderer, extensions)
      markdown.render(text)
    end

    html.to_s.html_safe
  end

  def self.render_toc(markdown_text)
    renderer = Redcarpet::Render::HTML_TOC.new(nesting_level: 6)
    markdown = Redcarpet::Markdown.new(renderer, space_after_headers: true)
    markdown.render(markdown_text || "").html_safe
  end

  def self.render_plain(markdown_text)
    html = render(markdown_text)
    ApplicationController.helpers.strip_tags(html)
  end
end
