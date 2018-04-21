require 'nokogiri'
require 'yaml'
# Use ActiveSupport's hash extensions
require 'active_support/core_ext/hash'

# Hash of cities with erroneous &#195 entities, and their fixes:
@corrected_cities = {
  'Andrych&#195;w, Poland': 'Andrychów, Poland',
  'Ath&#195;nai, Greece': 'Athênai, Greece',
  'August&#195;w, Poland': 'Augustów, Poland',
  'B&#195;rgermoor, Germany': 'Börgermoor, Germany',
  'Castell&#195; d Emp&#195;ries, Spain': 'Castelló d\'Empúries, Spain',
  'Chorz&#195;w, Poland': 'Chorzów, Poland',
  'Dąbrowa G&#195;rnicza, Poland': 'Dąbrowa Górnicza, Poland',
  'G&#195;rlitz, Germany': 'Görlitz, Germany',
  'Jan&#195;w Lubelski, Poland': 'Janów Lubelski, Poland',
  'Kisv&#195;rda, Hungary': 'Kisvárda, Hungary',
  'Krak&#195;w, Poland': 'Kraków, Poland',
  'L&#195;dź, Poland': 'Łódź, Poland',
  'M&#195;hldorf am Inn, Germany': 'Mühldorf am Inn, Germany',
  'M&#195;nchen, Germany': 'München, Germany',
  'N&#195;rnberg, Germany': 'Nürnberg, Germany',
  'P&#195;rigueux, France': 'Périgueux, France',
  'Ravensbr&#195;ck, Germany': 'Ravensbrück, Germany',
  'Saint-&#195;tienne, France': 'Saint-Étienne, France',
  'Stasz&#195;w, Poland': 'Staszów, Poland',
  'Sz&#195;kesfeh&#195;rv&#195;r, Hungary': 'Székesfehérvár, Hungary',
  'Terez&#195;n, Czechoslovakia': 'Terezín, Czechoslovakia',
  'Thessalon&#195;ki, Greece': 'Thessaloníki, Greece',
  'Tomasz&#195;w Mazowiecki, Poland': 'Tomaszów Mazowiecki, Poland',
  'Was&#195;w, Poland': 'Wąsów, Poland'
}

# Hash of months keyed to leading-zero numeric values
@month_numbers = {
  january: "01",
  february: "02",
  march: "03",
  april: "04",
  may: "05",
  june: "06",
  july: "07",
  august: "08",
  september: "09",
  october: "10",
  november: "11",
  december: "12"
}

def iso_date(str)
  # For a date like "September 24, 1945": remove the comma, split at spaces
  arr_date = str.gsub(/,/,'').split(" ")
  # Output ISO date string YYYY-MM-DD
  "#{arr_date[2]}-#{@month_numbers[arr_date[0].downcase.to_sym]}-#{arr_date[1]}"
end

# Take a seconds value and conver it to an HH:MM:SS.DDD time-marker
def time_marker(seconds)
  t = seconds.to_s.split(".")
  "#{Time.at(t[0].to_i).utc.strftime("%H:%M:%S")}.#{t[1]}"
end

# Conversely, take an HH:MM:SS.DDD time-marker and convert it to a string of seconds
def time_seconds(marker)
  t = marker.split(":")
  seconds = t.last.to_f
  # Handle hours, if necessary
  if t.length == 3
    seconds += t[0].to_f * 60 * 60
    seconds += t[1].to_f * 60
  else
    seconds += t[0].to_f * 60
  end
  seconds.to_s
end

Record = Struct.new(:legacy_identifier, :name, :nationality)
@file = "#{ENV['HOME']}/Voices/voices.iit.edu/_scrape/interviewee/interviewee?doc=sochamiH"
@doc = File.open(@file) do |f|
  Nokogiri::HTML(f)
end
puts @doc.css("#content h1")
@interviewee = Record.new
@interviewee.legacy_identifier = @file.split('=').last
@interviewee.name = @doc.css("#content h1 text()").to_s.strip
puts @interviewee.name
@interviewee.nationality = @doc.css("ul.bio .nationality text()").to_s.strip

record_hash = { 'interviewee': @interviewee.to_h.stringify_keys }
puts record_hash.stringify_keys.to_yaml

File.open("#{@interviewee.legacy_identifier}.yml",'w') do |f|
  f.write(record_hash.stringify_keys.to_yaml)
end
