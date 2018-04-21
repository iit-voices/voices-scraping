require 'nokogiri'
require 'yaml'
# Use ActiveSupport's hash extensions
require 'active_support/core_ext/hash'

# Hash of cities with erroneous &#195 entities, and their fixes:
@corrected_cities = {
  'AndrychÃw, Poland': 'Andrychów, Poland',
  'AthÃnai, Greece': 'Athênai, Greece',
  'AugustÃw, Poland': 'Augustów, Poland',
  'BÃrgermoor, Germany': 'Börgermoor, Germany',
  'CastellÃ d EmpÃries, Spain': 'Castelló d\'Empúries, Spain',
  'ChorzÃw, Poland': 'Chorzów, Poland',
  'Dąbrowa GÃrnicza, Poland': 'Dąbrowa Górnicza, Poland',
  'GÃrlitz, Germany': 'Görlitz, Germany',
  'JanÃw Lubelski, Poland': 'Janów Lubelski, Poland',
  'KisvÃrda, Hungary': 'Kisvárda, Hungary',
  'KrakÃw, Poland': 'Kraków, Poland',
  'LÃdź, Poland': 'Łódź, Poland',
  'MÃhldorf am Inn, Germany': 'Mühldorf am Inn, Germany',
  'MÃnchen, Germany': 'München, Germany',
  'NÃrnberg, Germany': 'Nürnberg, Germany',
  'PÃrigueux, France': 'Périgueux, France',
  'RavensbrÃck, Germany': 'Ravensbrück, Germany',
  'Saint-Ãtienne, France': 'Saint-Étienne, France',
  'StaszÃw, Poland': 'Staszów, Poland',
  'SzÃkesfehÃrvÃr, Hungary': 'Székesfehérvár, Hungary',
  'TerezÃn, Czechoslovakia': 'Terezín, Czechoslovakia',
  'ThessalonÃki, Greece': 'Thessaloníki, Greece',
  'TomaszÃw Mazowiecki, Poland': 'Tomaszów Mazowiecki, Poland',
  'WasÃw, Poland': 'Wąsów, Poland'
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

Record = Struct.new(
  :legacy_identifier,
  :name,
  :birthplace,
  :nationality,
  :gender,
  :locations ) do
  def file_name
    name.split(" ").join("-").downcase
  end
end

# Set a single file (temporary)
@file = "#{ENV['HOME']}/Voices/voices.iit.edu/_scrape/interviewee/interviewee?doc=sochamiH"

# Open the file and parse it
@doc = File.open(@file) do |f|
  Nokogiri::HTML(f)
end

# Use a struct to build the record
@interviewee = Record.new
@interviewee.legacy_identifier = @file.split('=').last
@interviewee.name = @doc.css("#content h1 text()").to_s.strip
# Biographical Information
bio = @doc.css('ul.bio')
@interviewee.birthplace = bio.css(".birthplace text()").to_s.strip
# Check to see if birthplace contains Ã (parsed &#195;), pull location from corrected_cities
if @interviewee.birthplace.match?(/Ã/)
  @interviewee.birthplace = @corrected_cities[@interviewee.birthplace.to_sym]
end
@interviewee.nationality = bio.css(".nationality text()").to_s.strip
@interviewee.gender = bio.css(".gender text()").to_s.strip
@interviewee.locations = Hash.new
@interviewee.locations[:invasion] = bio.css(".location_at_time_of_german_invasion text()").to_s.strip
@interviewee.locations[:internments] = bio.css(".interned_at text()").to_s.strip.split(", ")
@interviewee.locations[:liberation] = Hash.new
@interviewee.locations[:liberation][:date] = iso_date(bio.css(".liberation_date text()").to_s.strip)
@interviewee.locations[:liberation][:location] = bio.css(".location_at_time_of_liberation text()").to_s.strip
@interviewee.locations[:liberation][:by] = bio.css(".liberated_by text()").to_s.strip

# Create an outer hash in service of the YAML structure
record_hash = { 'interviewee': @interviewee.to_h.deep_stringify_keys }

# Diagnostic line for CLI sanity checking
puts record_hash.deep_stringify_keys.to_yaml

# Write the YAML file
File.open("output/#{@interviewee.file_name}.yml",'w') do |f|
  f.write(record_hash.deep_stringify_keys.to_yaml)
end
