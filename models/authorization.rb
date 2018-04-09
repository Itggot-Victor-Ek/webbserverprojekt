class Authorization
    attr_accessor :trips, :token
    def initialize
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

        api_auth_header = { 'Authorization' => "Bearer #{bearer_token}" }
        url = 'https://api.vasttrafik.se/bin/rest.exe/v2/trip?originId=9021014003180000&destId=9021014003220000&time=16%3A30&format=json'
        json_body = HTTParty.get(url, headers: api_auth_header).body
        @trips = [JSON.parse(json_body)['TripList']['Trip']]
          #
          # url = "https://api.vasttrafik.se/bin/rest.exe/v2/departureBoard?id=9021014003180000&date=2018-01-25&time=17%3A00&useTram=0&direction=9021014003220000&format=json"
          # json_body = HTTParty.get(url, headers: api_auth_header).body
          # #@data << JSON.parse(json_body)['DepartureBoard']['Departure'][0]
      end
end
