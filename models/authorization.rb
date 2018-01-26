class Authorization
  attr_accessor :data
  def initialize
    consumer_key = "VXiGD3igELfzYAQkVoJaKJXZewAa"
    consumer_secret = "N_51VglCPlf91Oj403HHkhsNUQYa"

    credentials = Base64.encode64("#{consumer_key}:#{consumer_secret}").gsub("\n", '')
    url = "https://api.vasttrafik.se:443/token"
    body = "grant_type=client_credentials&scope=<device_12345>"
    headers = {
      "Authorization" => "Basic #{credentials}",
      "Content-Type" => "application/x-www-form-urlencoded;charset=UTF-8"
    }
    r = HTTParty.post(url, body: body, headers: headers)
    bearer_token = JSON.parse(r.body)['access_token']
    @token = bearer_token

    api_auth_header = {"Authorization" => "Bearer #{bearer_token}"}
    url = "https://api.vasttrafik.se/bin/rest.exe/v2/location.name?input=N%C3%B6dinge&format=json"
    json_body = HTTParty.get(url, headers: api_auth_header).body
    @data = [JSON.parse(json_body)['LocationList']['StopLocation']]

    url = "https://api.vasttrafik.se/bin/rest.exe/v2/departureBoard?id=9021014003180000&date=2018-01-25&time=17%3A00&useTram=0&direction=9021014003220000&format=json"
    json_body = HTTParty.get(url, headers: api_auth_header).body
    @data << JSON.parse(json_body)['DepartureBoard']['Departure'][0]

    url = "https://api.vasttrafik.se/bin/rest.exe/v2/location.allstops?format=json"
    json_body = HTTParty.get(url, headers: api_auth_header).body
    data_allstops = JSON.parse(json_body)
    p data_allstops


    #db = SQLite3::Database.open('db/Västtrafik.sqlite')
    #data_allstops.each_with_index do |hash,i|
    #  name = hash['name']
    #  id = i +1
    #  db.execute('INSERT INTO all_stops VALUES (?,?)',id,name)
    #end

  end

end
