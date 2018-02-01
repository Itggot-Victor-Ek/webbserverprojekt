class Routes
  def self.add_route_for_user(username, bearer_token, start_station, stop_station)
    bearer_token = bearer_token
    p bearer_token
    api_auth_header = {"Authorization" => "Bearer #{bearer_token}"}
    start_station = URI::encode(start_station)
    stop_station = URI::encode(stop_station)

    url = "https://api.vasttrafik.se/bin/rest.exe/v2/location.name?input=#{start_station}&format=json"
    json_body = HTTParty.get(url, headers: api_auth_header).body
    p json_body
    start_station = JSON.parse(json_body)['LocationList']['StopLocation'][0]
    start_station_id = start_station["id"]

    url = "https://api.vasttrafik.se/bin/rest.exe/v2/location.name?input=#{stop_station}&format=json"
    json_body = HTTParty.get(url, headers: api_auth_header).body
    stop_station = JSON.parse(json_body)['LocationList']['StopLocation'][0]
    stop_station_id = stop_station["id"]

    hour = Time.now.strftime('%H')
    minutes = Time.now.strftime('%M')
    date = Time.now.strftime('%Y-%m-%d')

    url = "https://api.vasttrafik.se/bin/rest.exe/v2/departureBoard?id=#{start_station_id}&date=2018-01-25&time=#{hour}%3A#{minutes}&direction=#{stop_station_id}&format=json"
    json_body = HTTParty.get(url, headers: api_auth_header).body
    data = JSON.parse(json_body)['DepartureBoard']['Departure'][0]
    depature_time = JSON.parse(json_body)['DepartureBoard']['Departure'][0]['time']
    buss_name = JSON.parse(json_body)['DepartureBoard']['Departure'][0]['name']

    db = SQLite3::Database.open('db/Västtrafik.sqlite')

    stop_id = db.execute('SELECT id FROM all_stops WHERE stop_name IS ?', [stop_station])[0]
    db.execute('INSERT INTO departure (time, busid, stopid) VALUES(?, ?, ?)', [depature_time,buss_name,stop_id])

  end

  def self.get_route_for_user(username)
    db = SQLite3::Database.open('db/Västtrafik.sqlite')
    return db.execute('SELECT * FROM depature')
  end
end
