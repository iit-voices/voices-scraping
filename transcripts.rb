require 'nokogiri'
require 'yaml'
# Use ActiveSupport's hash extensions
require 'active_support/core_ext/hash'
require 'active_support/core_ext/string'

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
  if str.length == 0
    "unknown"
  else
    # For a date like "September 24, 1945": remove the comma, split at spaces
    arr_date = str.gsub(/,/,'').split(" ")
    # Zero-pad single-digit days
    if arr_date[1].length == 1
      arr_date[1] = "0" + arr_date[1]
    end
    # Output ISO date string YYYY-MM-DD
    "#{arr_date[2]}-#{@month_numbers[arr_date[0].downcase.to_sym]}-#{arr_date[1]}"
  end
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

# Recording metadata is mostly in the biographical file
Recording = Struct.new(:date,:location,:languages,:duration,:spools,:audio,:transcript,:translation)
Utterance = Struct.new(:who,:start,:end,:u)
Transcript = Struct.new(:language,:interview)

# Set a file pattern (temporary)
@files = "#{ENV['HOME']}/Voices/voices.iit.edu/voices.iit.edu/interview?doc=sochamiH&display=sochamiH_en"

Dir.glob(@files).each do |file|
  # Open the file and parse it
  @doc = File.open(file) do |f|
    Nokogiri::HTML(f)
  end

  @trans = Transcript.new
  # Grab the language from the last two letters in the file name
  @trans.language = file.strip.slice(-2,2)
  # Create an array to hold each utterance in the interview
  @trans.interview = []
  @doc.css('#content > ul + ul > li').each do |li|
    # If there's a previous record, set its start as the end for the current record
    if @trans.interview.length > 0
      @trans.interview.last[:end] = @u.start
    end
    # TODO: Add an else condition to set the end of the last utterance to the recording length?
    @u = Utterance.new
    @u.who = li.css('.who span text()').to_s.strip
    @u.start = time_marker(li.css('.utterance').attr('start')).to_s.strip
    # Subtitute ugly ` . . . ` ellipsis with `...`
    @u.u = li.css('.utterance text()').to_s.strip.gsub(/\s\.\s\.\s\.\s?/,'...')
    # Add the utterance onto the end of the transcript array
    @trans.interview.push(@u.to_h)
  end

end

puts @trans.to_h.deep_stringify_keys.to_yaml
