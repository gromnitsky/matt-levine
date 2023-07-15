require 'json'
require 'nokogiri'
require 'date'
require_relative './lib'

abort "Usage: #{$0} file.json" unless ARGV[0]

article = JSON.parse File.read ARGV[0]
article["summary"] = Nokogiri::HTML.fragment article["summary"]
article["body"] = Nokogiri::HTML.fragment article["body"]

article["footnotes"] = Nokogiri::HTML.fragment article["footnotes"]
article["footnotes"].css('div.footnote > p:first-child').each.with_index do |node, idx|
  node.prepend_child "#{idx+1}. "
end

puts <<END
<?xml version="1.0" encoding="utf-8"?>
<html xmlns="http://www.w3.org/1999/xhtml"
      xmlns:epub="http://www.idpf.org/2007/ops">
<head>
<title>#{e article["title"]}</title>
<meta name="author" content="#{e article["author"]}" />
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<style>
#{File.read __dir__ + "/style.css"}
</style>
</head>

<body>
<h1>#{article["title"]}</h1>
<div class="lead">#{article["summary"].to_xml}</div>
<p class="author"><time datetime="#{article["date"]}">#{article["date"]}</time>, #{article["author"]}</p>

#{article["body"].to_xml}

<h2 id="article_footnotes">Footnotes</h2>
#{article["footnotes"].to_xml}

<footer>
<hr />
<dl>
<dt>Source:</dt><dd><a href="#{article["url"]}">#{article["url"]}</a></dd>
<dt>Generated:</dt><dd>#{DateTime.now}</dd>
<dt>Generator environment:</dt>
<dd>
 <ul>
 <li>#{`uname -a`}</li>
 <li>#{e RUBY_DESCRIPTION}</li>
 </ul>
</dd>
</dl>
</footer>

</body>
</html>
END
