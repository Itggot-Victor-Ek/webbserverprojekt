#Use bundler to load gems
require 'bundler'
require "net/http"
require "uri"
require 'base64'
require 'json'

#Load gems from Gemfile
Bundler.require

#Load the app
require_relative 'main'

#Load models
require_relative 'models/authorization'
require_relative 'models/users'
require_relative 'models/stationHandler'
require_relative 'models/routes'
#Make Slim NICE!
Slim::Engine.set_options pretty: true, sort_attrs: false

#Run the app
run Main
