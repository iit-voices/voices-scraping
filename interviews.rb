require 'nokogiri'

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
  "January": "01",
  "February": "02",
  "March": "03",
  "April": "04",
  "May": "05",
  "June": "06",
  "July": "07",
  "August": "08",
  "September": "09",
  "October": "10",
  "November": "11",
  "December": "12"
}

def iso_date(str)
  # For a date like "September 24, 1945": remove the comma, split at spaces
  arr_date = str.gsub(/,/,'').split(" ")
  # Output ISO date string YYYY-MM-DD
  "#{arr_date[2]}-#{@month_numbers[arr_date[0].to_sym]}-#{arr_date[1]}"
end
