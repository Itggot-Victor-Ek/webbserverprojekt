class Main < Sinatra::Base

  enable :sessions
  use Rack::Recaptcha, :public_key => '6LeIxAcTAAAAAJcZVRqyHh71UMIEGNQ_MXjiZKhI', :private_key => '6LeIxAcTAAAAAGG-vFI1TnRWxMZNFuojJ4WifJWe'
  helpers Rack::Recaptcha::Helpers

  get '/' do
    @authorization = Authorization.new
    session[:token] = @authorization.token
    slim :test
  end

  get '/home' do

    slim :home
  end

  get '/register' do

    slim :register
  end

  post '/register' do
    user = User.create(params['name'], params['username'], params['email'], params['password'], session)
    redirect user.redirectURL
  end

  get '/user/:username' do
    @routes = Routes.get_route_for_user(session[:username])
    slim :user
  end

  get '/reseplanerare' do
    @user = session[:username]
    @stations = StationHandler.getAllStations
    slim :reseplanerare
  end

  post '/reseplanerare' do
    Routes.add_route_for_user(session[:username], session[:token], params[:start_station], params[:stop_station])

  end

  get '/theo' do
    slim :theo
  end

end
