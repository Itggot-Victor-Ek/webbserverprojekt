class Main < Sinatra::Base

  enable :sessions

  get '/' do
    @authorization = Authorization.new
    slim :test
  end

  get '/home' do

    slim :home
  end

  get '/theo' do
    slim :theo
  end

end
