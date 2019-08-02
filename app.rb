require 'rubygems'
require 'sinatra'
require 'sinatra/base'
require "sinatra/cookies"
require 'active_record'

require_relative './models'

class UnsecretPassword < Sinatra::Base
  helpers Sinatra::Cookies

  get '/' do
    erb :top
  end

  get '/login' do
    @message = ''
    erb :login
  end

  post '/login' do
    if params[:name]&.empty? || params[:password]&.empty?
      @message = 'ユーザー名またはパスワードが間違っています'
      return erb :login
    end

    user = User.new
    begin
      user = User.find(params[:name])
    rescue ActiveRecord::RecordNotFound => e
      @message = 'ユーザー名またはパスワードが間違っています'
      return erb :login
    end

    if user.authenticate(params[:password])
      cookies['sessionid'] = user.sessionid
      redirect '/'
    else
      @message = 'ユーザー名またはパスワードが間違っています'
      return erb :login
    end
  end
end
