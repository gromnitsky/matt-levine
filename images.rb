# generates a makefile for downloading all images for a single article

abort "Usage: #{$0} file.raw" unless ARGV[0]

require_relative './lib'
article = extract File.read ARGV[0] rescue abort($!)
images = extract_img(article)

def target file; File.join File.dirname(ARGV[0]), file; end

puts <<END
curl := curl -sfL -H 'user-agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36'
images: #{images.map {|i| target i[:file]}.join(' ')}
.DELETE_ON_ERROR:
END

images.each do |img|
  puts target(img[:file]) + ":"
  puts "\t" + "$(curl) '#{img[:url]}' > $@"
end
