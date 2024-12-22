# generates a makefile for downloading all articles

require 'nokogiri'
require 'date'

doc = Nokogiri::XML STDIN.read
items = doc.css('item').map do |n|
  {
    date: Date.parse(n.css('pubDate').text).to_s,
    link: n.css('link').text,
  }
end

def target(item, ext) = item[:date] + "/" + item[:date] + ext

puts <<END
curl := #{__dir__}/puppeteer-fetch-html
xhtml := #{items.map {|v| target v, '.xhtml' }.join(' ')}
all: $(xhtml)
END

items.each do |v|
  puts "#{target v, '.raw'}:"
  puts "\t$(mkdir)"
  puts "\t$(curl) '#{v[:link]}' > $@"
  puts "\t" + '@[ "`wc -c < $@`" -gt 200000 ] || { echo invalid responce; exit 1; }'
end
