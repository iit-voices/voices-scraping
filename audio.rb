File.open('mp3s.txt') do |f|
  f.each_line do |l|
    puts "#{l.strip.split("_").first}: '#{l.strip}',"
  end
end
