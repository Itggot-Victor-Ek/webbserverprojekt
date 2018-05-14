class Main < Sinatra::Base
    enable :sessions

    before do
        login_paths = [/^\/user\/\S+/, '/reseplanerare']
        login_paths.each do |path|
            if path.match(request.path)
                unless session[:logged_in]
                    redirect '/login'
                end
                unless request.path == '/user/' + session[:username]
                    if session[:logged_in]
                        redirect "/user/#{session[:username]}"
                    end
                    redirect '/login'
                end
            end
        end
    end

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
        user = User.create( params['name'], params['username'], params['email'], params['password'], session)
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

    get '/logout' do
        session.destroy
        redirect '/'
    end

    get '/reseplanerare' do
        @user = session[:username]
        @stations = StationHandler.getAllStations
        session[:token] = Authorization.new.token
        slim :reseplanerare
    end

    post '/reseplanerare' do
        Route.add_for_user(session[:username], session[:token], params[:start_station], params[:stop_station], params[:date_and_time], params['recurring'], session)
        redirect "user/#{session[:username]}"
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
