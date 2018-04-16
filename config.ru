#Use bundler to load gems
require 'bundler'
require "net/http"
require "uri"
require 'base64'
require 'json'
require 'pp'

#Load gems from Gemfile
Bundler.require

#Load the app
require_relative 'main'

#Load models
dir = Dir.glob("models/*.rb")
dir.map { |x| require_relative "#{x}" }


#Make Slim NICE!
Slim::Engine.set_options pretty: true, sort_attrs: false

#Run the app
run Main
