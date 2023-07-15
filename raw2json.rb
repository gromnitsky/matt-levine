require 'nokogiri'
require 'date'
require 'json'

def extract file
  doc = Nokogiri::HTML File.read file
  data = doc.css('script#__NEXT_DATA__')&.inner_html
  raise 'no script tag' if data.size == 0
  data = JSON.parse data

  IO.write("#{file}.DEBUG.json", data.to_json) if ENV["DEBUG"]

  article = data.dig("props", "pageProps")
  author = article.dig("story", "authors", 0, "name") || raise('no author')

  date = article.dig("story", "publishedAt") || raise('no date')
  date = Date.parse date

  title = article.dig("story", "headline") || raise('no title')

  summary = article.dig("story", "summary") || raise('no summary')
  summary = Nokogiri::HTML.fragment(summary)

  url = article.dig("story", "url") || raise('no url')

  body = article.dig("story", "body") || raise('no body')
  body = cnt_parse body["content"]

  footnotes = data.dig("props", "pageProps", "story", "footnotes", "content")&.first&.dig("content") || []
  footnotes = cnt_parse footnotes

  {
    author:, date:, title:, summary:, url:,
    body: body.join(""), footnotes: footnotes.join("")
  }
end

def footnote_number id
  m = id.match(/-(\d+)$/) || raise("invalid footnote id: #{id}")
  m[1]
end

def cnt_parse data
  r = []
  data.each do |chunk|
    case chunk["type"]
    when "paragraph"
      r.push "<p>"
      # RECURSION
      r.push cnt_parse chunk["content"]
      r.push "</p>"

    when "text"
      attrs = chunk["attributes"]
      r.push "<b>" if attrs&.dig("strong")
      r.push "<i>" if attrs&.dig("emphasis")
      r.push chunk["value"]
      r.push "</b>" if attrs&.dig("strong")
      r.push "</i>" if attrs&.dig("emphasis")

    when "heading"
      level = chunk.dig("data", "level") || raise('invalid heading level')
      # RECURSION
      text = cnt_parse chunk["content"]
      id = text.join("").gsub(/[^A-Za-z0-9_-]/, '_')
      r.push "<h#{level} id='#{id}'>"
      r.push text
      r.push "</h#{level}>"

    when "link"
      href = chunk.dig("data", "data-web-url") ||
             chunk.dig("data", "href") || raise('invalid link')
      r.push "<a href='#{href}'>"
      # RECURSION
      r.push cnt_parse chunk["content"]
      r.push "</a>"

    when "footnoteRef"
      id = chunk.dig("data", "identifier") || raise('invalid footnoteRef')
      number = footnote_number id
      r.push "<sup><a href='\##{id}'>#{number}</a></sup>"

    when "footnote"
      id = chunk.dig("data", "identifier") || raise('invalid footnote')
      r.push "<div class='footnote' id='#{id}'>"
      # RECURSION
      r.push cnt_parse chunk["content"]
      r.push "</div>"

    when "entity"
      href = chunk.dig("data", "link", "destination", "web") || raise("invalid entity (a link to another bloomberg article): #{chunk}")
      r.push "<a href='#{href}'>"
      # RECURSION
      r.push cnt_parse chunk["content"]
      r.push "</a>"

    when "quote"
      r.push "<blockquote>"
      # RECURSION
      r.push cnt_parse chunk["content"]
      r.push "</blockquote>"

    when "list"
      type = chunk.dig("subType") == "ordered" ? "ol" : "ul"
      r.push "<#{type}>"
      # RECURSION
      r.push cnt_parse chunk["content"]
      r.push "</#{type}>"

    when "listItem"
      r.push "<li>"
      # RECURSION
      r.push cnt_parse chunk["content"]
      r.push "</li>"

    when "media"
      photo = chunk.dig("data", "photo") || raise("invalid photo")
      ext = File.extname photo["src"]
      r.push "<img data-src='#{photo["src"]}' alt='#{photo["alt"]}' src='#{photo["id"]}#{ext}'>"

    when "br"
      r.push "<br>"

    # junk
    when "inline-recirc"
    when "inline-newsletter"
    when "ad"
    else
      fail "yo! unknown content type: #{chunk["type"]}"
    end
  end

  r.flatten
end

puts extract(ARGV[0]).to_json
