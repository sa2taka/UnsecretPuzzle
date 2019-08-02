require 'rubygems'
require 'sinatra'
require 'sinatra/base'
require "sinatra/cookies"
require 'active_record'

class UnsecretPassword < Sinatra::Base
  helpers Sinatra::Cookies

  get '/' do
    erb :top
  end
end
