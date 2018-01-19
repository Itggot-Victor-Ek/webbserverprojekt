class Main < Sinatra::Base

  enable :sessions

  post '/' do
    client = OAuth2::Client.new('VXiGD3igELfzYAQkVoJaKJXZewAa', 'N_51VglCPlf91Oj403HHkhsNUQYa', :site => 'https://api.vasttrafik.se/token')

    redirect client.auth_code.authorize_url(:redirect_uri => 'http://192.168.193.22:9292/index')
    #code = client.auth_code
    # => "https://example.org/oauth/authorization?response_type=code&client_id=client_id&redirect_uri=http://localhost:8080/oauth2/callback"

    #token = client.auth_code.get_token(code, :redirect_uri => 'http://192.168.193.22:9292/index', :headers => {'Authorization' => 'Basic'})
    #response = token.get('/api/resource', :params => { 'query_foo' => 'bar' })
    #response.class.name
  end

  get '/home' do

  end

  get '/' do

  end

  get '/theo' do
    slim :theo
  end

end
