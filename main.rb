class Main < Sinatra::Base

  enable :sessions
  use Rack::Recaptcha, :public_key => '6LeIxAcTAAAAAJcZVRqyHh71UMIEGNQ_MXjiZKhI', :private_key => '6LeIxAcTAAAAAGG-vFI1TnRWxMZNFuojJ4WifJWe'
  helpers Rack::Recaptcha::Helpers

  get '/' do
    @authorization = Authorization.new
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

    slim :user
  end

  get '/theo' do
    slim :theo
  end

end
