require "./grabber"

puts "Download complete" if Grabber.new(ARGV[0], ARGV[1]).process
