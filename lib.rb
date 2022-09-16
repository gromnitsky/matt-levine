require 'nokogiri'
require 'date'
require 'json'

def extract str
  doc = Nokogiri::HTML str
  data = doc.css('script[data-component-props="OverlayAd"]')&.inner_html
  raise 'no script tag' if data.size == 0

  article = JSON.parse data
  author = article.dig("story", "authors", 0, "name") || raise('no author')
  date = article.dig("story", "publishedAt") || raise('no date')
  date = Date.parse date
  title = article.dig("story", "headline") || raise('no title')
  summary = article.dig("story", "summary") || raise('no summary')
  url = article.dig("story", "url") || raise('no url')
  url = "https://www.bloomberg.com" + url
  body = article.dig("story", "body") || raise('no body')

  { author:, date:, title:, summary:, url:, body: Nokogiri::HTML.fragment(body)}
end

def bodyfix! article
  body = article[:body]

  # 1. remove junk
  ['div:not(.image):not(.lazy-img)', 'aside', 'script', 'meta', 'style']
    .each {|query| body.css(query).remove}

  # 2. remove all classes from all nodes except for <a> & <ol> & some p
  body.traverse do |node|
    if node.name == 'a' && node.classes.index('footnote')
      node['class'] = 'footnote'
    elsif node.name == 'ol' && node.classes.index('noscript-footnotes')
      node['class'] = 'noscript-footnotes'
    elsif node.name == 'p' && node.classes.index('news-rsf-contact-editor')
      node['class'] = 'news-rsf-contact-editor'
    else
      node.remove_class
    end
  end

  # 3. rearrange footnotes
  footnotes = Nokogiri::XML::NodeSet.new Nokogiri::HTML::Document.new
  ol = body.at_css('ol.noscript-footnotes')
  ol.css('li').each.with_index do |li, idx|
    span = li.css('span')
    p = li.css('p')
    if span
      span.remove
      p[0].prepend_child "#{idx+1}. "
      p[0].prepend_child span
    end

    a = li.at_css('a[rel="footnote-ref"]')
    if a
      a.remove
      a.inner_html = '⤶'
      p[-1].add_child a if a
    end

    p[0]['class'] = 'footnote-text'
    footnotes += p
  end
  ol.replace '<div id="footnotes"><hr></div>'
  body.at_css('div#footnotes') << footnotes

  # 4. images
  images = extract_img article
  body.css('img[data-native-src]').each.with_index do |img, idx|
    img['src'] = images[idx][:file]
  end

  # 5. headers
  body.css('h2').each.with_index do |h2, idx|
    h2['id'] = "header-#{idx}"
  end
end

def extract_img article
  article[:body].css('img[data-native-src]').map.with_index do |img, idx|
    {
      url: img['data-native-src'],
      file: idx.to_s + File.extname(img['data-native-src'])
    }
  end
end

def abort s; Kernel.abort "#{$0} error: #{s}"; end
