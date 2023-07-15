def e s
  n = Nokogiri::XML::Node.new "dummy", Nokogiri::XML::Document.new
  n.encode_special_chars s
end
