require 'cgi'
require_relative './lib'

article = extract(STDIN.read) rescue abort($!)
bodyfix! article

def e s; CGI.escapeHTML s; end
mobi_maker = ENV['mobi_maker']&.strip&.size.to_i > 0 ? ENV['mobi_maker'] : '?'

# data from `article` comes already html escaped
puts <<END
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<head>
<title>#{article[:title]}</title>
<meta name="author" content="#{article[:author]}" />
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
img { max-width: 100%; }

p {
  text-align: justify;
}
p:not([class]) {
  margin: 0;
  padding: 0;
}
p:not([class]) + p:not([class]) {
  text-indent: 1em;
}
.lead { margin: 1em 0 }
blockquote { margin: 1em 0 1em 1em; }
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
<dt>.mobi files maker:</dt><dd>#{e mobi_maker}</dd>
</dl>
</footer>

</body>
</html>
END
