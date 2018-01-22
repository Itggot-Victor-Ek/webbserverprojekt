#Use bundler to load gems
require 'bundler'
require "net/http"
require "uri"
require 'base64'

#Load gems from Gemfile
Bundler.require

#Load the app
require_relative 'main'
require_relative 'models/authorization'

#Load models
#require_relative 'models/xxx'


#Make Slim NICE!
Slim::Engine.set_options pretty: true, sort_attrs: false

#Run the app
run Main
