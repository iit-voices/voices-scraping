require 'nokogiri'
require 'yaml'
# Use ActiveSupport's hash and string extensions
require 'active_support/core_ext/hash'
require 'active_support/core_ext/string'
# Use sterile to generate typographers quotes, etc.
require 'sterile'

# Hash of cities with erroneous &#195 entities, and their fixes:
CORRECTED_CITIES = {
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
MONTH_NUMBERS = {
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

# Legacy identifiers keyed to MP3 files
MP3_FILES = {
  aIlmar: 'aIlmar_9-152A_SLP.mp3',
  bJ: 'bJ_9-23_SLP.mp3',
  bJanis: 'bJanis_9-152B_9-153A_SLP.mp3',
  barzilaiN: 'barzilaiN_9-21B_SLP.mp3',
  bassfreundJ: 'bassfreundJ_9-137B_9-138B_9-139_SLP.mp3',
  benmayorR: 'benmayorR_9-27_SLP.mp3',
  billiT: 'billiT_9-142A_SLP.mp3',
  bisenhausP: 'bisenhausP_9-3B_SLP.mp3',
  boguslaw: 'boguslaw_9-156A_SLP.mp3',
  bondyN: 'bondyN_9-60_9-61_SLP.mp3',
  borgman: 'borgman_frienhofferJ_9-85A_SLP.mp3',
  bramsonJ: 'bramsonJ_9-45B_9-46_9-48_SLP.mp3',
  braunA: 'braunA_9-133_9-134_SLP.mp3',
  breslauerA: 'breslauerA_9-90B_SLP.mp3',
  brinI: 'brinI_9-126B_9-127_SLP.mp3',
  buttonE: 'buttonE_9-26_SLP.mp3',
  buttonJ: 'buttonJ_9-25_SLP.mp3',
  czolopickiB: 'czolopickiB_9-4B_SLP.mp3',
  deutschJ: 'deutschJ_9-80_SLP.mp3',
  deutschY: 'deutschY_9-80_SLP.mp3',
  eisenbergK: 'eisenbergK_9-12B_9-13_SLP.mp3',
  epsteinN: 'epsteinN_9-95_9-96_9-104A_SLP.mp3',
  feneger: 'feneger_9-45A_SLP.mp3',
  ferberJ: 'ferberJ_9-117_SLP.mp3',
  ferdinanskV: 'ferdinanskV_9-153B_SLP.mp3',
  feuerO: 'feuerO_9-64_9-65_SLP.mp3',
  finkelN: 'finkelN_9-155A_SLP.mp3',
  franzH: 'franzH_9-136_SLP.mp3',
  freilichE: 'freilichE_9-40B_SLP.mp3',
  freilichF: 'freilichF_9-36_9-37_9-38_SLP.mp3',
  friedmanB: 'friedmanB_9-107B_9-108_SLP.mp3',
  frimL: 'frimL_9-156B_9-157_9-158A_SLP.mp3',
  frydmanH: 'frydmanH_9-29_9-30_9-31_9-32_SLP.mp3',
  gertnerA: 'gertnerA_9-77_9-78_9-79_SLP.mp3',
  goldwasserB: 'goldwasserB_9-24_SLP.mp3',
  golenJ: 'golenJ_9-160_9-161_9-162_SLP.mp3',
  grossJ: 'grossJ_9-19_SLP.mp3',
  gurmanovaR: 'gurmanovaR_9-51_9-52_9-53_SLP.mp3',
  gutmanE: 'gutmanE_9-124_9-125A_SLP.mp3',
  hamburgerL: 'hamburgerL_9-72_9-73A_SLP.mp3',
  heislerA: 'heislerA_9-81_SLP.mp3',
  herskovitzM: 'herskovitzM_9-9_9-10_SLP.mp3',
  hirschD: 'hirschD_9-74B_SLP.mp3',
  horowitzS: 'horowitzS_9-120_9-121A_SLP.mp3',
  isakovitchS: 'isakovitchS_9-7_SLP.mp3',
  jeanC: 'jeanC_9-57B_SLP.mp3',
  johlesM: 'johlesM_9-89_9-90A_SLP.mp3',
  joseph: 'joseph_9-158B_SLP.mp3',
  josephyK: 'josephyK_9-66_SLP.mp3',
  kahnJ: 'kahnJ_9-56A_SLP.mp3',
  kahnL: 'kahnL_9-57C_SLP.mp3',
  kahnM: 'kahnM_9-56B_9-57A_SLP.mp3',
  kaldoreG: 'kaldoreG_9-97_9-98_9-99_SLP.mp3',
  kaletskaA: 'kaletskaA_9-164B_9-165_9-166_SLP.mp3',
  kalnietisJ: 'kalnietisJ_9-142B_SLP.mp3',
  kestenbergJ: 'kestenbergJ_9-11_9-12A_SLP.mp3',
  kharchenkoI: 'kharchenkoI_9-143C_9-144A_SLP.mp3',
  kimmelmannA: 'kimmelmannA_9-83B_9-84_9-85B_9-86_9-87_9-91_9-92_SLP.mp3',
  kluverJ: 'kluverJ_9-132_SLP.mp3',
  krakowskiA: 'krakowskiA_9-5_SLP.mp3',
  kruegerE: 'kruegerE_9-109_SLP.mp3',
  kuechlerL: 'kuechlerL_9-114_9-115_SLP.mp3',
  leaD: 'leaD_9-41B_9-42_SLP.mp3',
  linikD: 'linikD_9-130A_SLP.mp3',
  lipschitzM: 'lipschitzM_9-21A_SLP.mp3',
  lukoseviciusV: 'lukoseviciusV_9-144C_9-145_SLP.mp3',
  marcusH: 'marcusH_9-128_9-129_SLP.mp3',
  marsonM: 'marsonM_9-6B_SLP.mp3',
  matznerJ: 'matznerJ_9-163_9-164A_SLP.mp3',
  meltzakR: 'meltzakR_9-119A_SLP.mp3',
  michelsonV: 'michelsonV_9-153C_9-154_SLP.mp3',
  milgramM: 'milgramM_9-40A_SLP.mp3',
  minskiJ: 'minskiJ_9-70_9-71_SLP.mp3',
  mizrachiM: 'mizrachiM_9-43B_SLP.mp3',
  moellerE: 'moellerE_9-135_SLP.mp3',
  monkF: 'monkF_9-111_9-112_9-113_SLP.mp3',
  moskovitzM: 'moskovitzM_9-6A_SLP.mp3',
  nehrichW: 'nehrichW_9-75_9-76_SLP.mp3',
  neimanC: 'neimanC_9-121B_SLP.mp3',
  neufeldH: 'neufeldH_9-20_SLP.mp3',
  nichthauserF: 'nichthauserF_9-15_9-16_SLP.mp3',
  odinetsD: 'odinetsD_9-168_9-169A_SLP.mp3',
  oleiskiJ: 'oleiskiJ_9-54_SLP.mp3',
  ostlandI: 'ostlandI_9-125B_9-126A_SLP.mp3',
  paulA: 'paulA_9-140B_9-141A_SLP.mp3',
  paulisA: 'paulisA_9-144B_SLP.mp3',
  piskorzB: 'piskorzB_9-102_9-103_SLP.mp3',
  preckerM: 'preckerM_9-41A_SLP.mp3',
  reichS: 'reichS_9-73B_9-74A_SLP.mp3',
  richardA: 'richardA_9-28_SLP.mp3',
  rosenfeldP: 'rosenfeldP_9-130B_9-131_SLP.mp3',
  rosenwasserI: 'rosenwasserI_9-62_9-63_SLP.mp3',
  rosetR: 'rosetR_9-4A_SLP.mp3',
  rudo: 'rudo_9-8_SLP.mp3',
  schachtN: 'schachtN_9-116A_SLP.mp3',
  schiverT: 'schiverT_9-110_SLP.mp3',
  schlaefrigF: 'schlaefrigF_9-67_9-68_SLP.mp3',
  schrameckA: 'schrameckA_9-55_SLP.mp3',
  schultzeC: 'schultzeC_9-136B_9-137A_SLP.mp3',
  schwarzfitterJ: 'schwarzfitterJ_9-93_9-94_SLP.mp3',
  serrasE: 'serrasE_9-34_9-35_SLP.mp3',
  shachnovskiL: 'shachnovskiL_9-3A_SLP.mp3',
  silberbartG: 'silberbartG_9-82_9-83A_SLP.mp3',
  skudaikieneB: 'skudaikieneB_9-143B_SLP.mp3',
  sochamiH: 'sochamiH_9-43A_SLP.mp3',
  sprecherM: 'sprecherM_9-147_9-148_SLP.mp3',
  stopnitskyU: 'stopnitskyU_9-122_9-123_SLP.mp3',
  stumachinL: 'stumachinL_9-118_SLP.mp3',
  suvalkaitisA: 'suvalkaitisA_9-143A_SLP.mp3',
  tcharnabrodaR: 'tcharnabrodaR_9-155B_9-155C_SLP.mp3',
  tcharnabrodaR: 'tcharnabrodaR_9-155B_9-156A_SLP.mp3',
  tichauerH: 'tichauerH_9-149_9-150_9-151_SLP.mp3',
  tischauerH: 'tischauerH_9-149_9-150_9-151_SLP.mp3',
  unikowskiI: 'unikowskiI_9-17_9-18_SLP.mp3',
  warsagerB: 'warsagerB_9-104B_9-106_9-107A_SLP.mp3',
  weinbergJ: 'weinbergJ_9-49_SLP.mp3',
  wilfJ: 'wilfJ_9-50_SLP.mp3',
  wolfI: 'wolfI_9-100_9-101_SLP.mp3',
  zeplitR: 'zeplitR_9-139B_9-140A_SLP.mp3',
  zgnilekB: 'zgnilekB_9-22_SLP.mp3',
  ziererE: 'ziererE_9-116B_SLP.mp3',
  zurilisS: 'zurilisS_9-141B_SLP.mp3'
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
    "#{arr_date[2]}-#{MONTH_NUMBERS[arr_date[0].downcase.to_sym]}-#{arr_date[1]}"
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
files = "#{ENV['HOME']}/Voices/voices.iit.edu/voices.iit.edu/interviewee\?doc=*"
Dir.glob(files).each do |file|
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
    @interviewee.birthplace = CORRECTED_CITIES[@interviewee.birthplace.to_sym]
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
    @interviewee.locations[:invasion] = CORRECTED_CITIES[@interviewee.locations[:invasion].to_sym]
  end
  if @interviewee.locations[:liberation][:location].match?(/Ã/)
    @interviewee.locations[:liberation][:location] = CORRECTED_CITIES[@interviewee.locations[:liberation][:location].to_sym]
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
  @recording.audio[:file] = MP3_FILES[@interviewee.legacy_identifier.to_sym]

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
      @u.u = li.css('.utterance text()').to_s.strip.gsub(/\s\.\s\.\s\.\s?/,'...').smart_format.gsub(/…/,'...')
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
