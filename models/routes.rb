# require 'base64'
# require 'sqlite3'
# require 'httparty'
# require 'json'
# require 'pp'
class Route

    def self.add_for_user(_username, bearer_token, start_station, stop_station, _session)
        @db = SQLite3::Database.open('../db/Västtrafik.sqlite')

        # Set the token and encode the strings
        bearer_token = bearer_token
        api_auth_header = { 'Authorization' => "Bearer #{bearer_token}" }
        start_station = URI.encode(start_station)
        stop_station = URI.encode(stop_station)

        #getting the start station id
        url = "https://api.vasttrafik.se/bin/rest.exe/v2/location.name?input=#{start_station}&format=json"
        json_body = HTTParty.get(url, headers: api_auth_header).body
        start_station = JSON.parse(json_body)['LocationList']['StopLocation'][0]
        start_station_id = start_station['id']

        #getting the stop station id
        url = "https://api.vasttrafik.se/bin/rest.exe/v2/location.name?input=#{stop_station}&format=json"
        json_body = HTTParty.get(url, headers: api_auth_header).body
        stop_station = JSON.parse(json_body)['LocationList']['StopLocation'][0]
        stop_station_id = stop_station['id']

        #requst the route from the desired start and stop station
        url = "https://api.vasttrafik.se/bin/rest.exe/v2/trip?originId=#{start_station_id}&destId=#{stop_station_id}&format=json"
        json_body = HTTParty.get(url, headers: api_auth_header).body
        @legs = [JSON.parse(json_body)['TripList']['Trip']][0]
        #starting loop to store the relevant data
        @legs.each do |leg|
            leg.each do |data|
                Route.input_data(data, _username)
            end
            #set connection_id back to nil when the route has ended
            @connection_id = nil
        end
    end

    def self.input_data(data, _username)
        if !(data == ['valid', 'false'] || data == ['alternative', 'true'])
            data[1].each_with_index do |item, i|
                #Fetch all relevant data from the JSON body
                vehicle_type =      item.fetch('name', nil)
                type =              item.fetch('type', nil)
                direction =         item.fetch('direction', nil)
                origin_name =       item.fetch('Origin', nil).fetch('name',   nil)
                origin_track =      item.fetch('Origin', nil).fetch('track',  nil)
                origin_time =       item.fetch('Origin', nil).fetch('time',   nil)
                origin_date =       item.fetch('Origin', nil).fetch('date',   nil)
                destination_name =  item.fetch('Destination', nil).fetch('name',  nil)
                destination_track = item.fetch('Destination', nil).fetch('track', nil)
                destination_time =  item.fetch('Destination', nil).fetch('time',  nil)
                destination_date =  item.fetch('Destination', nil).fetch('date',  nil)

                #Input all data into the database
                origin_id = @db.execute('SELECT id FROM all_stops WHERE stop_name IS ?', [origin_name])
                destination_id = @db.execute('SELECT id FROM all_stops WHERE stop_name IS ?', [destination_name])
                @db.execute('INSERT INTO departure (vehicle_type, type, direction, origin_name_id,
                    origin_time, origin_date, origin_track, destination_name_id,
                    destination_time, destination_date, destination_track, connection_id)
                    VALUES (?,?,?,?,?,?,?,?,?,?,?,?)',[vehicle_type, type, direction,
                    origin_id, origin_time, origin_date, origin_track, destination_id,
                    destination_time, destination_date, destination_track, @connection_id])
                #Get the last id to be able to reference the full route
                @connection_id = @db.execute('SELECT last_insert_rowid()') unless destination_name == nil

                #if it's the starting station make a relation between the user and route
                if i == 0
                    user_id = @db.execute('SELECT id FROM users WHERE username IS ?', [_username])
                    @db.execute('INSERT INTO user_departure_relation (user_id, departure_id) VALUES(?,?)',[user_id, @connection_id])
                end
            end
        end
    end

    def self.for_user(username)
        
    end

    def self.remove_old_routes(username); end
end

# consumer_key = 'VXiGD3igELfzYAQkVoJaKJXZewAa'
# consumer_secret = 'N_51VglCPlf91Oj403HHkhsNUQYa'
#
# credentials = Base64.encode64("#{consumer_key}:#{consumer_secret}").delete("\n")
# url = 'https://api.vasttrafik.se:443/token'
# body = 'grant_type=client_credentials&scope=<device_12345>'
# headers = {
#     'Authorization' => "Basic #{credentials}",
#     'Content-Type' => 'application/x-www-form-urlencoded;charset=UTF-8'
# }
# r = HTTParty.post(url, body: body, headers: headers)
# bearer_token = JSON.parse(r.body)['access_token']
# @token = bearer_token
#
# Route.add_for_user('t', bearer_token, "n\xC3\xB6dinge", "holmv\xC3\xA4gen", {})
