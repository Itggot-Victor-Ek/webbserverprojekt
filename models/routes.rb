require 'base64'
require 'sqlite3'
require 'httparty'
require 'json'
require 'pp'
class Route
    def self.add_for_user(_username, bearer_token, start_station, stop_station, _session)
        @db = SQLite3::Database.open('../db/Västtrafik.sqlite')
        bearer_token = bearer_token
        api_auth_header = { 'Authorization' => "Bearer #{bearer_token}" }
        start_station = URI.encode(start_station)
        stop_station = URI.encode(stop_station)

        url = "https://api.vasttrafik.se/bin/rest.exe/v2/location.name?input=#{start_station}&format=json"
        json_body = HTTParty.get(url, headers: api_auth_header).body
        start_station = JSON.parse(json_body)['LocationList']['StopLocation'][0]
        start_station_id = start_station['id']

        url = "https://api.vasttrafik.se/bin/rest.exe/v2/location.name?input=#{stop_station}&format=json"
        json_body = HTTParty.get(url, headers: api_auth_header).body
        stop_station = JSON.parse(json_body)['LocationList']['StopLocation'][0]
        stop_station_id = stop_station['id']

        url = "https://api.vasttrafik.se/bin/rest.exe/v2/trip?originId=#{start_station_id}&destId=#{stop_station_id}&format=json"
        json_body = HTTParty.get(url, headers: api_auth_header).body
        @legs = [JSON.parse(json_body)['TripList']['Trip']][0]
        # pp @legs
        @legs.each do |leg|
            leg.each do |data|
                Route.input_data(data)
            end
            @connection_id = nil
        end

        # pp @legs
    end

    def self.input_data(data)
        if !(data == ['valid', 'false'] || data == ['alternative', 'true'])
            @connection |= nil
            vehicle_type =      data[1][0].fetch('name', nil)
            type =              data[1][0].fetch('type', nil)
            direction =         data[1][0].fetch('direction', nil)
            origin_name =       data[1][0].fetch('Origin', nil).fetch('name',   nil)
            origin_track =      data[1][0].fetch('Origin', nil).fetch('track',  nil)
            origin_time =       data[1][0].fetch('Origin', nil).fetch('time',   nil)
            origin_date =       data[1][0].fetch('Origin', nil).fetch('date',   nil)
            destination_name =  data[1][0].fetch('Destination', nil).fetch('name',  nil)
            destination_track = data[1][0].fetch('Destination', nil).fetch('track', nil)
            destination_time =  data[1][0].fetch('Destination', nil).fetch('time',  nil)
            destination_date =  data[1][0].fetch('Destination', nil).fetch('date',  nil)
        end

        origin_id = @db.execute('SELECT id FROM all_stops WHERE stop_name IS ?', [origin_name])
        destination_id = @db.execute('SELECT id FROM all_stops WHERE stop_name IS ?', [destination_name])
        @db.execute('INSERT INTO departure (vehicle_type, type, direction, origin_name_id,
            origin_time, origin_date, origin_track, destination_name_id,
            destination_time, destination_date, destination_track, connection_id)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?)',[vehicle_type, type, direction,
            origin_id, origin_time, origin_date, origin_track, destination_id,
            destination_time, destination_date, destination_track, @connection_id])
        @connection_id = @db.execute('SELECT last_insert_rowid()') unless destination_name == nil
    end

    def self.for_user(username); end

    def self.remove_old_routes(username); end
end

consumer_key = 'VXiGD3igELfzYAQkVoJaKJXZewAa'
consumer_secret = 'N_51VglCPlf91Oj403HHkhsNUQYa'

credentials = Base64.encode64("#{consumer_key}:#{consumer_secret}").delete("\n")
url = 'https://api.vasttrafik.se:443/token'
body = 'grant_type=client_credentials&scope=<device_12345>'
headers = {
    'Authorization' => "Basic #{credentials}",
    'Content-Type' => 'application/x-www-form-urlencoded;charset=UTF-8'
}
r = HTTParty.post(url, body: body, headers: headers)
bearer_token = JSON.parse(r.body)['access_token']
@token = bearer_token

Route.add_for_user('t', bearer_token, "n\xC3\xB6dinge", "holmv\xC3\xA4gen", {})
