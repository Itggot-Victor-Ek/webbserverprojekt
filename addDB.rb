require 'sqlite3'
require "net/http"
require "uri"
require 'base64'
require 'json'
require 'httparty'

@db = SQLite3::Database.open('db/Västtrafik2.sqlite')
#@file = File.readlines('stopNames.txt')

def main

  @db.execute('DELETE FROM all_stops')

  #@file.each_with_index do |name, i|
    #name = name.encode('UTF-8')
  #  id = i + 1
  #  p name
  #  @db.execute('INSERT INTO all_stops VALUES (?,?)', [id,name])
  #end


  api_auth_header = {"Authorization" => "Bearer #{@token}"}
  url = "https://api.vasttrafik.se/bin/rest.exe/v2/location.allstops?format=json"
  json_body = HTTParty.get(url, headers: api_auth_header).body
  data_allstops = JSON.parse(json_body)['LocationList']['StopLocation']

  array = []

  data_allstops.each_with_index do |hash, i|
    name = hash['name']
    array << name
  end

  array = array.uniq

  array.each_with_index do |name,i|
    id = i + 1
    @db.execute('INSERT INTO all_stops VALUES (?,?)', [id,name])
  end
end

def get_token
    consumer_key = "VXiGD3igELfzYAQkVoJaKJXZewAa"
    consumer_secret = "N_51VglCPlf91Oj403HHkhsNUQYa"

    credentials = Base64.encode64("#{consumer_key}:#{consumer_secret}").gsub("\n", '')
    url = "https://api.vasttrafik.se:443/token"
    body = "grant_type=client_credentials&scope=<device_12345>"
    headers = {
      "Authorization" => "Basic #{credentials}",
      "Content-Type" => "application/x-www-form-urlencoded;charset=UTF-8"
    }
    r = HTTParty.post(url, body: body, headers: headers)
    bearer_token = JSON.parse(r.body)['access_token']
    @token = bearer_token
end

get_token
main
