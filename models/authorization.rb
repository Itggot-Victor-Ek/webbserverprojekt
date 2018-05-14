class Vasttrafik_authorization
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
        return bearer_token
      end
end
