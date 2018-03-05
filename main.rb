class Main < Sinatra::Base
    enable :sessions
    use Rack::Recaptcha, public_key: '6LeIxAcTAAAAAJcZVRqyHh71UMIEGNQ_MXjiZKhI', private_key: '6LeIxAcTAAAAAGG-vFI1TnRWxMZNFuojJ4WifJWe'
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
        Route.remove_old_routes(session[:username])
        @routes = Route.for_user(session[:username])
        slim :user
    end

    get '/login' do
        slim :login
    end

    post '/login' do
        user = User.login(params['name'], params['password'], session)
        redirect user.redirectURL
    end

    get '/reseplanerare' do
        @user = session[:username]
        @stations = StationHandler.getAllStations
        slim :reseplanerare
    end

    post '/reseplanerare' do
        route_redirect = Route.add_for_user(session[:username], session[:token], params[:start_station], params[:stop_station], session) # gör till objekt
        redirect '/user/theo'
    end

    get '/token' do
        @authorization = Authorization.new
        session[:token] = @authorization.token
        session[:username] = 'test'
        redirect '/user/test'
    end

    get '/theo' do
        slim :theo
    end
end
