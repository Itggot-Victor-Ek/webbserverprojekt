class Routes
  def self.add_route_for_user(username, bearer_token, start_station, stop_station, session)
    bearer_token = bearer_token
    api_auth_header = {"Authorization" => "Bearer #{bearer_token}"}
    station_name = stop_station
    start_station = URI::encode(start_station)
    stop_station = URI::encode(stop_station)

    url = "https://api.vasttrafik.se/bin/rest.exe/v2/location.name?input=#{start_station}&format=json"
    json_body = HTTParty.get(url, headers: api_auth_header).body
    start_station = JSON.parse(json_body)['LocationList']['StopLocation'][0]
    start_station_id = start_station["id"]

    url = "https://api.vasttrafik.se/bin/rest.exe/v2/location.name?input=#{stop_station}&format=json"
    json_body = HTTParty.get(url, headers: api_auth_header).body
    stop_station = JSON.parse(json_body)['LocationList']['StopLocation'][0]
    stop_station_id = stop_station["id"]

    hour = Time.now.strftime('%H')
    minutes = Time.now.strftime('%M')
    date = Time.now.strftime('%Y-%m-%d')
    date2 = Time.now.strftime('%Y-%m-%d-%H:%M')

    url = "https://api.vasttrafik.se/bin/rest.exe/v2/departureBoard?id=#{start_station_id}&date=2018-01-25&time=#{hour}%3A#{minutes}&direction=#{stop_station_id}&format=json"
    json_body = HTTParty.get(url, headers: api_auth_header).body

    if JSON.parse(json_body)['DepartureBoard'].to_s.include?('error')
      session[:bad_route] = true
      session[:bad_route_messege] = JSON.parse(json_body)['DepartureBoard']["errorText"]
      return '/reseplanerare'
    end

    db = SQLite3::Database.open('db/Västtrafik.sqlite')
<<<<<<< HEAD
    stopid = db.execute('SELECT id FROM all_stops WHERE stop_name IS ?', [station_name])[0]
    userid = db.execute('SELECT id FROM users WHERE username IS ?', [username])[0]
    i = 0
    JSON.parse(json_body)['DepartureBoard']['Departure'].each do |hash|
      if i < 5
        db.execute('INSERT INTO buses (name, input_date) VALUES (?,?)', [hash['name'], date2])
        busid = db.execute('SELECT id FROM buses WHERE name IS ? AND input_date IS ?', [hash['name'], date])[0]
        db.execute('INSERT INTO user_stop_relation (accountid, busid, stopid, input_date) VALUES (?,?,?,?)', [userid, busid, stopid, date])
        db.execute('INSERT INTO departure(time, busid, stopid, input_date) VALUES(?,?,?,?)', [hash["time"], busid, stopid, date])
=======
    stop_id = db.execute('SELECT id FROM all_stops WHERE stop_name IS ?', [station_name])[0]
    i = 0
    JSON.parse(json_body)['DepartureBoard']['Departure'].each do |hash|
      if i < 5
        db.execute('INSERT INTO departure(time, busid, stopid, input_date) VALUES(?, ?, ?, ?) WHERE NOT EXISTS(SELECT 1 FROM departure WHERE time IS ? AND busid IS ? AND stopid IS ?)', [hash["time"], hash["name"], stop_id, date, hash["time"], hash["name"], stop_id])
>>>>>>> 621be7109bd0b2a4d6dbab8372e590d698580093
      end
      i += 1
    end
    session[:bad_route] = false
    return '/user/test'
  end

  def self.get_route_for_user(username)
    db = SQLite3::Database.open('db/Västtrafik.sqlite')
    remove_old_routes(username)
<<<<<<< HEAD
    date = Time.now.strftime('%Y-%m-%d')
    accountid = db.execute('SELECT id FROM users WHERE username IS ?', [username])
    arr = []
    arr << db.execute('SELECT time FROM departure WHERE busid IN (SELECT id FROM buses WHERE id IN (SELECT busid FROM user_stop_relation WHERE accountid IS (SELECT id FROM users WHERE username IS ?)))', [username])
    arr << db.execute('SELECT name FROM buses WHERE id IN (SELECT busid FROM user_stop_relation WHERE accountid IS (SELECT id FROM users WHERE username IS ?))', [username])
    #result = db.execute('SELECT * FROM departure WHERE stopid IN (SELECT stopid FROM user_stop_relation WHERE accountid IS ? AND input_date > ?)',[accountid, date])
    pp arr
=======
    return db.execute('SELECT * FROM departure')
>>>>>>> 621be7109bd0b2a4d6dbab8372e590d698580093
  end

  def self.remove_old_routes(username)
    db = SQLite3::Database.open('db/Västtrafik.sqlite')
    elements = db.execute('SELECT * FROM departure')      #nytt namn på varibeln
    elements.each do |array|
      dates = array[4].split("-")
      minutes = array[1][3..-1]
      hours = array[1]
      date = Time.new(dates[0], dates[1], dates[2], hours, minutes)
      if Time.new() > date
        db.execute('DELETE FROM departure WHERE id IS ?', [array[0]])
      end
    end
  end
end
