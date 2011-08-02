require 'open-uri'
require 'json'

url = 'http://www.ucas.com/students/choosingcourses/choosinguni/map/'
html = open(url).read

universities = {}

cur, lat, lng = nil, nil
html.split("\n").each do |line|
  if line =~ %r[array_points\[(\d+)\] = \[\];]
    cur = $1
  elsif line =~ %r[array_points\[(\d+)\]\['(\w+)'\] = '(.+)']
    id, key, value = $1, $2, $3
    universities[id] ||= {}
    universities[id][key] = value
  elsif cur and line =~ %r[var lat = parseFloat\((.+)\);]
    universities[cur]['lat'] = $1
  elsif cur and line =~ %r[var lng = parseFloat\((.+)\);]
    universities[cur]['lng'] = $1
  end
end

puts universities.values.to_json
