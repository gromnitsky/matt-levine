require 'nokogiri'
require 'date'
require 'json'
require 'cgi'

def abort s; Kernel.abort "#{$0} error: #{s}"; end

doc = Nokogiri::HTML STDIN.read
data = doc.css('script[data-component-props="OverlayAd"]')&.inner_html
abort 'no script tag' if data.size == 0

article = JSON.parse data
author = article.dig("story", "authors", 0, "name") || abort('no author')
date = article.dig("story", "publishedAt") || abort('no date')
date = Date.parse date
title = article.dig("story", "headline") || abort('no title')
summary = article.dig("story", "summary") || abort('no summary')
url = article.dig("story", "url") || abort('no url')
url = "https://www.bloomberg.com" + url
body = article.dig("story", "body") || abort('no body')

body = Nokogiri::HTML5.fragment body
['div', 'aside', 'script', 'meta'].each {|query| body.css(query).remove}

def e s; CGI.escapeHTML s; end
mobi_maker = ENV['mobi_maker']&.strip&.size.to_i > 0 ? ENV['mobi_maker'] : '?'

# data from `article` comes already html escaped
puts <<END
<!doctype html>
<title>#{title}</title>
<meta name="author" content="#{author}">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
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
  margin-top: 2em;
}
dt { font-style: italic; }
</style>

<header>
<h1>#{title}</h1>
#{summary}
<p><time datetime="#{date}">#{date}</time>, #{author}</p>
</header>

#{body}

<footer>
<hr>
<dl>
<dt>Source:</dt><dd><a href="#{url}">#{url}</a></dd>
<dt>Generated:</dt><dd>#{DateTime.now}</dd>
<dt>Generator environment:</dt><dd>#{e RUBY_DESCRIPTION}</dd>
<dt>.mobi files maker:</dt><dd>#{e mobi_maker}</dd>
</dl>
</footer>
END
