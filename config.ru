# Run this with 'rackup -p 4567'

require 'bundler'
Bundler.require

require 'sinatra'

require './destination_app.rb'

run DestinationApp.new
