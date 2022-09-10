require 'nokogiri'
require 'date'

ext = ARGV[0] || '.mobi'

doc = Nokogiri::XML STDIN.read
items = doc.css('item').map do |n|
  {
    date: Date.parse(n.css('pubDate').text).to_s,
    link: n.css('link').text,
  }
end

def target item, ext
  item[:date] + "/" + item[:date] + ext
end

puts <<END
curl := curl -sfL -H 'user-agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36'
all: #{items.map {|v| target v, ext }.join(' ')}
END

items.each do |v|
  puts "#{target v, '.raw'}:"
  puts "\t$(mkdir)"
  puts "\t$(curl) '#{v[:link]}' > $@"
end
