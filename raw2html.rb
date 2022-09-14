require 'nokogiri'
require 'date'
require 'json'
require 'cgi'

def abort s; Kernel.abort "#{$0} error: #{s}"; end

doc = Nokogiri::HTML STDIN.read
data = doc.css('script[data-component-props="OverlayAd"]')&.inner_html
abort 'no script tag' if data.size == 0

article = JSON.parse data rescue abort 'invalid json'
author = article.dig("story", "authors", 0, "name") || abort('no author')
date = article.dig("story", "publishedAt") || abort('no date')
date = Date.parse date rescue abort $!
title = article.dig("story", "headline") || abort('no title')
summary = article.dig("story", "summary") || abort('no summary')
url = article.dig("story", "url") || abort('no url')
url = "https://www.bloomberg.com" + url
body = article.dig("story", "body") || abort('no body')

body = Nokogiri::HTML5.fragment body

# 1. remove junk
['div:not(.image):not(.lazy-img)', 'aside', 'script', 'meta']
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

# 3. fix footnotes hierarchy
footnotes = Nokogiri::XML::NodeSet.new Nokogiri::HTML5::Document.new
ol = body.at_css('ol.noscript-footnotes')

ol.css('li > p').each.with_index do |p, idx|
  span = p.parent.css('span')
  if span
    span.remove
    a = p.parent.at_css('a[rel="footnote-ref"]').remove
    a.inner_html = '⤶'
    p.prepend_child "#{idx+1}. "
    p.prepend_child span
    p.add_child a
    p['class'] = 'footnote-text'
  end
  footnotes << p
end

ol.previous = '<div id="footnotes"><hr/></div>'
ol.remove
body.at_css('div#footnotes') << footnotes

def e s; CGI.escapeHTML s; end
mobi_maker = ENV['mobi_maker']&.strip&.size.to_i > 0 ? ENV['mobi_maker'] : '?'

# data from `article` comes already html escaped
puts <<END
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<head>
<title>#{title}</title>
<meta name="author" content="#{author}" />
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<style>
@media (min-width: 601px) {
  body {
    width: 600px;
    margin: 8px auto;
  }
}
.footnote { vertical-align: super; }
h1, h2, h3 { text-align: left; }
p { text-align: justify; }
footer {
  text-align: left;
  word-break: break-word;
}
dt { font-style: italic; }

p {
  text-align: justify;
}
p:not([class]) {
  margin: 0;
  padding: 0;
}
p:not([class]) + p:not([class]) {
  text-indent: 2em;
}
.lead { margin: 1em 0 }
blockquote { margin: 1em 0 1em 1em; }
</style>
</head>

<body>
<h1>#{title}</h1>
<div class="lead">#{summary}</div>
<p class="author"><time datetime="#{date}">#{date}</time>, #{author}</p>

#{body.to_xml}

<footer>
<hr />
<dl>
<dt>Source:</dt><dd><a href="#{url}">#{url}</a></dd>
<dt>Generated:</dt><dd>#{DateTime.now}</dd>
<dt>Generator environment:</dt><dd>#{e RUBY_DESCRIPTION}</dd>
<dt>.mobi files maker:</dt><dd>#{e mobi_maker}</dd>
</dl>
</footer>

</body>
</html>
END
