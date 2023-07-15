# generates a makefile for downloading all images for a single article

require 'nokogiri'

abort "Usage: #{$0} file.xhtml" unless ARGV[0]

doc = Nokogiri::XML File.read ARGV[0]
images = doc.css('img[data-src]').map do |img|
  { url: img['data-src'], file: img['src'] }
end

def target file; File.join File.dirname(ARGV[0]), file; end

puts <<END
curl := curl -sfL -H 'user-agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36'
images: #{images.map {|i| target i[:file]}.join(' ')}
.DELETE_ON_ERROR:
END

images.each do |img|
  puts target(img[:file]) + ":"
  puts "\t" + "$(curl) '#{img[:url]}' > $@"
end
