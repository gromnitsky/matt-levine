require 'cgi'
require_relative './lib'

article = extract(STDIN.read) rescue abort($!)
bodyfix! article

def e s; CGI.escapeHTML s; end

# data from `article` comes already html escaped
puts <<END
<?xml version="1.0" encoding="utf-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<head>
<title>#{article[:title]}</title>
<meta name="author" content="#{article[:author]}" />
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<style>
#{File.read __dir__ + "/style.css"}
</style>
</head>

<body>
<h1>#{article[:title]}</h1>
<div class="lead">#{article[:summary]}</div>
<p class="author"><time datetime="#{article[:date]}">#{article[:date]}</time>, #{article[:author]}</p>

#{article[:body].to_xml}

<footer>
<hr />
<dl>
<dt>Source:</dt><dd><a href="#{article[:url]}">#{article[:url]}</a></dd>
<dt>Generated:</dt><dd>#{DateTime.now}</dd>
<dt>Generator environment:</dt><dd>#{e RUBY_DESCRIPTION}</dd>
</dl>
</footer>

</body>
</html>
END
