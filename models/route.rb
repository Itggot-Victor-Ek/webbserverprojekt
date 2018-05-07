class Route < BaseClass
    table_name "departures"
    columns(id: "integer", vehicle_type: "text", type: "text", direction: 'text',
            origin_name: "text", origin_time: "text", origin_date: "text",
            origin_track: "text", destination_name: 'text', destination_time: 'text',
            destination_date: 'text', destination_track: 'text', connection_id: 'text',
            parent_id: 'text', recurring: 'boolean')
    create_table(SQLite3::Database.open('db/Västtrafik.sqlite'), false)

    def self.add_for_user(_username, bearer_token, start_station, stop_station, date_and_time, recurring, _session)
        #This is a string since booleans crashed last time
        recurring = recurring != 'true'  ? 'false' : recurring

        #checks if the trip already exists
        private
        
        unless self.check_if_exists(_username, start_station, stop_station, date_and_time, _session)

            date = date_and_time.split(" ")[0]
            hours = date_and_time[-5..-4]
            minutes = date_and_time[-2..-1]

            # Set the token and encode the 'start' and 'end station' strings
            bearer_token = bearer_token
            api_auth_header = { 'Authorization' => "Bearer #{bearer_token}" }
            start_station = URI.encode(start_station)
            stop_station = URI.encode(stop_station)

            # getting the start station id
            url = "https://api.vasttrafik.se/bin/rest.exe/v2/location.name?input=#{start_station}&format=json"
            json_body = HTTParty.get(url, headers: api_auth_header).body
            start_station = JSON.parse(json_body)['LocationList']['StopLocation'][0]
            start_station_id = start_station['id']

            # getting the stop station id
            url = "https://api.vasttrafik.se/bin/rest.exe/v2/location.name?input=#{stop_station}&format=json"
            json_body = HTTParty.get(url, headers: api_auth_header).body
            stop_station = JSON.parse(json_body)['LocationList']['StopLocation'][0]
            stop_station_id = stop_station['id']

            # requst the route from the desired start and stop station
            url = "https://api.vasttrafik.se/bin/rest.exe/v2/trip?originId=#{start_station_id}&destId=#{stop_station_id}&date=#{date}&time=#{hours}%3A#{minutes}&format=json"
            json_body = HTTParty.get(url, headers: api_auth_header).body
            legs = [JSON.parse(json_body)['TripList']['Trip']][0]
            # starting loop to store the relevant data
            legs.each do |leg|
                @leg_id = @db.execute("SELECT id FROM #{@table_name} where id = (SELECT max(id) FROM #{@table_name})")

                #check if the table is empty, if so set id to 1
                if @leg_id.empty?
                    @leg_id = 1
                else
                    @leg_id = @leg_id[0][0].to_i + 1
                end

                leg.each do |data|
                    Route.input_data(data, _username, recurring)
                end
                # set connection_id back to nil when the route has ended
                @connection_id = nil
            end
        end
    end

    def self.input_data(data, _username, recurring)
        #skip some stupid values
        unless data == ["valid", "false"] || data == ["alternative", "true"]
            data[1].each_with_index do |item, i|
                # Fetch all relevant data from the JSON body
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

                insert({
                            vehicle_type: vehicle_type,
                            type: type,
                            direction: direction,
                            origin_name: origin_name,
                            origin_time: origin_time,
                            origin_date: origin_date,
                            origin_track: origin_track,
                            destination_name: destination_name,
                            destination_time: destination_time,
                            destination_date: destination_date,
                            destination_track: destination_track,
                            connection_id: @connection_id,
                            parent_id: @leg_id,
                            recurring: recurring
                            })

                # Get the last id to be able to reference the full route
                @connection_id = @db.execute('SELECT last_insert_rowid()').first.first unless destination_name.nil?

                # if it's the starting station make a relation between the user and route
                if i == 0
                    user_id = @db.execute('SELECT id FROM users WHERE username IS ?', [_username])
                    @db.execute('INSERT INTO user_departure_relation (user_id, departure_id) VALUES(?,?)', [user_id, @connection_id])
                end
            end
        end
    end

    def self.for_user(username)
        return @db.execute("SELECT * FROM #{@table_name} WHERE parent_id IN (SELECT departure_id FROM user_departure_relation WHERE user_id IN (SELECT id FROM users WHERE username IS ?))", [username])
    end

    def self.remove_old_routes(username)
        departures = @db.execute("SELECT * FROM #{@table_name}")

        departures.each do |departure|
          dates = departure[6].split("-")
          minutes = departure[5][3..-1]
          hours = departure[5][0..1]
          date = Time.new(dates[0], dates[1], dates[2], hours, minutes)

          if Time.new() > date
            @db.execute("DELETE FROM #{@table_name} WHERE parent_id IS ? AND recurring IS NOT 'true'", [departure[0]])
            @db.execute("DELETE FROM user_departure_relation WHERE departure_id IS (SELECT id FROM #{@table_name} id WHERE id IS ? AND recurring IS NOT 'true')", [departure[0]])
          end
        end
    end

    def self.check_if_exists(username, start_station, stop_station, date_and_time, session)
        trips = @db.execute("SELECT * FROM #{@table_name} WHERE origin_name IS ? AND datetime(origin_time) < datetime(?)", [start_station, date_and_time])
        connections = @db.execute('SELECT * FROM user_departure_relation WHERE user_id IS (SELECT id FROM users WHERE username IS ?)',[username])
        user_id = @db.execute('SELECT id FROM users WHERE username IS ?', [username])
        found_atleast_one_connection = false
        trips.each do |trip|
            found_connection = false
            connections.each do |connection|
                if connection[1] == trip[0]
                    found_connection = true
                    found_atleast_one_connection = true
                end
            end
            if !found_connection
                @db.execute('INSERT INTO user_departure_relation (user_id, departure_id) VALUES (?,?)', [user_id, trip[0]])
                found_atleast_one_connection = true
            end
        end
        return found_atleast_one_connection
    end
end
