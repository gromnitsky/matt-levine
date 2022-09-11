require 'nokogiri'
require 'date'

ext = ['.html', '.mobi'] + (ARGV[0] == 'send' ? ['.send'] : [])

doc = Nokogiri::XML STDIN.read
items = doc.css('item').map do |n|
  {
    date: Date.parse(n.css('pubDate').text).to_s,
    link: n.css('link').text,
  }
end

def target item, *ext
  ext.map {|v| item[:date] + "/" + item[:date] + v}.join ' '
end

puts <<END
curl := curl -sfL -H 'user-agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36'
all: #{items.map {|v| target v, *ext }.join(' ')}
END

items.each do |v|
  puts "#{target v, '.raw'}:"
  puts "\t$(mkdir)"
  puts "\t$(curl) '#{v[:link]}' > $@"
  puts "\t" + '@[ "`wc -c < $@`" -gt 200000 ] || { echo invalid responce; exit 1; }'
end
