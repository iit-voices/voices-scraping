require 'nokogiri'
require 'yaml'
# Use ActiveSupport's hash extensions
require 'active_support/core_ext/hash'
require 'active_support/core_ext/string'
# Use sterile to generate typographers quotes, etc.
require 'sterile'

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

Interviewee = Struct.new(
  :identifier,
  :legacy_identifier,
  :name,
  :birthplace,
  :nationality,
  :gender,
  :locations ) do
  def file_name
    name.split(" ").join("-").parameterize
  end
end

Recording = Struct.new(:date,:location,:languages,:duration,:spools,:audio,:transcript,:translation)
Utterance = Struct.new(:who,:start,:end,:u)
Transcript = Struct.new(:language,:interview)



# Set a file pattern (temporary)
@files = "#{ENV['HOME']}/Voices/voices.iit.edu/voices.iit.edu/interviewee\?doc=*"
Dir.glob(@files).each do |file|
  # Open the file and parse it
  @doc = File.open(file) do |f|
    Nokogiri::HTML(f)
  end

  # Create an outer hash in service of the YAML structure
  record_hash = {
    'interviewee': {},
    'recording': {}
  }

  # Use a struct to build the record
  @interviewee = Interviewee.new
  @interviewee.legacy_identifier = file.split('=').last
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

  if @interviewee.locations[:invasion].match?(/Ã/)
    @interviewee.locations[:invasion] = @corrected_cities[@interviewee.locations[:invasion].to_sym]
  end
  if @interviewee.locations[:liberation][:location].match?(/Ã/)
    @interviewee.locations[:liberation][:location] = @corrected_cities[@interviewee.locations[:liberation][:location].to_sym]
  end

  @interviewee.identifier = @interviewee.file_name

  # Recording = Struct.new(:date,:location,:languages,:duration,:spools,:audio,:transcript,:translation)
  @recording = Recording.new

  @recording.date = iso_date(@doc.css('.recording_date text()').to_s.strip)
  @recording.location = @doc.css('li span.location text()').to_s.strip
  @recording.languages = @doc.css('.languages text()').to_s.strip.split(", ")
  # TODO: Use the 'mp3info' gem to extract the length of the actual MP3 file
  @recording.duration = time_marker(time_seconds(@doc.css('.duration text()').to_s.strip))
  # Split spools on a comma space
  @recording.spools = @doc.css('.spools text()').to_s.strip.split(", ")
  @recording.audio = { file: '', 'mime-type': 'audio/mp3' }
  # TODO: Pull audio file name from the transcript file
  # @recording.audio[:file] =

  @doc.css('#transcript a').each do |t|
    puts t['href'].strip
    @t = File.open("#{ENV['HOME']}/Voices/voices.iit.edu/voices.iit.edu/#{t['href'].strip}") do |f|
      Nokogiri::HTML(f)
    end

    @trans = Transcript.new
    # Grab the language from the last two letters in the file name
    @trans.language = t['href'].strip.slice(-2,2)
    # Create an array to hold each utterance in the interview
    @trans.interview = []
    @t.css('#content > ul + ul > li').each do |li|
      # TODO: Use the 'mp3info' gem to extract the length of the actual MP3 file; use that
      # on the metadata for the recording
      @u = Utterance.new
      @u.who = li.css('.who span text()').to_s.strip
      @u.start = time_marker(li.css('.utterance').attr('start')).to_s.strip
      # If there's a previous record, back up and set the end value to the current record's start
      # value
      if @trans.interview.length > 0
        @trans.interview.last[:end] = @u.start
      end
      @u.end = li.next
      # Subtitute ugly ` . . . ` ellipsis with `...`
      @u.u = li.css('.utterance text()').to_s.strip.smart_format.gsub(/\s\.\s\.\s\.\s?/,'...')
      # Add the utterance onto the end of the transcript array
      @trans.interview.push(@u.to_h)
    end

    if t.text.match?(/Transcript/)
      @recording.transcript = @trans.to_h.deep_stringify_keys
    else
      @recording.translation = @trans.to_h.deep_stringify_keys
    end

  end



  record_hash['interviewee'] = @interviewee.to_h.deep_stringify_keys
  record_hash['recording'] = @recording.to_h.deep_stringify_keys

  # Diagnostic line for CLI sanity checking
  # puts record_hash.deep_stringify_keys.to_yaml

  # Write the YAML file
  File.open("output/#{@interviewee.identifier}.yml",'w') do |f|
    f.write(record_hash.deep_stringify_keys.to_yaml)
  end
end
