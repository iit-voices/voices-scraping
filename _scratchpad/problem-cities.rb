
cities = <<~LIST
Thessalon&#195;ki, Greece
Ath&#195;nai, Greece
B&#195;rgermoor, Germany
M&#195;hldorf am Inn, Germany
Thessalon&#195;ki, Greece
M&#195;nchen, Germany
Stasz&#195;w, Poland
P&#195;rigueux, France
L&#195;dź, Poland
Thessalon&#195;ki, Greece
Thessalon&#195;ki, Greece
Sz&#195;kesfeh&#195;rv&#195;r, Hungary
Terez&#195;n, Czechoslovakia
Krak&#195;w, Poland
N&#195;rnberg, Germany
N&#195;rnberg, Germany
Terez&#195;n, Czechoslovakia
August&#195;w, Poland
Was&#195;w, Poland
L&#195;dź, Poland
Dąbrowa G&#195;rnicza, Poland
M&#195;nchen, Germany
L&#195;dź, Poland
Thessalon&#195;ki, Greece
Krak&#195;w, Poland
G&#195;rlitz, Germany
Thessalon&#195;ki, Greece
Ath&#195;nai, Greece
Chorz&#195;w, Poland
Andrych&#195;w, Poland
Krak&#195;w, Poland
Krak&#195;w, Poland
L&#195;dź, Poland
Kisv&#195;rda, Hungary
Jan&#195;w Lubelski, Poland
Jan&#195;w Lubelski, Poland
Castell&#195; d Emp&#195;ries, Spain
Terez&#195;n, Czechoslovakia
Saint-&#195;tienne, France
Ravensbr&#195;ck, Germany
Thessalon&#195;ki, Greece
Terez&#195;n, Czechoslovakia
Tomasz&#195;w Mazowiecki, Poland
Tomasz&#195;w Mazowiecki, Poland
L&#195;dź, Poland
LIST

city_array = cities.split(/\n/)

puts city_array.sort.uniq
