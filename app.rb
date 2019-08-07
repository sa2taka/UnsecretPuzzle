require 'rubygems'
require 'sinatra'
require 'sinatra/base'
require 'sinatra/cookies'
require 'active_record'

require_relative './models'

class UnsecretPassword < Sinatra::Base
  helpers Sinatra::Cookies

  helpers do
    def user
      User.find_by(sessionid: cookies[:sessionid])
    end
  end

  get '/' do
    erb :top
  end

  get '/login' do
    if (sessionid = cookies['sessionid']) && User.find_by(sessionid: sessionid)
      redirect '/'
    end
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

  get '/mypage' do
    unless User.find_by(sessionid: cookies[:sessionid])
      redirect '/login'
    end
    erb :mypage
  end

  get '/register' do
    erb :register
  end

  post '/register' do
    if params[:name]&.empty? || params[:password]&.empty?
      @message = 'ユーザー名、パスワードは必須項目です'
      return erb :register
    end

    if User.exists?(id: params[:name])
      @message = 'すでに存在しているユーザー名です'
      return erb :register
    end

    user = User.create(params[:name], params[:password])
    cookies[:sessionid] = user.sessionid
    redirect '/mypage'
  end

  post '/logout' do
    cookies['sessionid'] = ''
    redirect '/'
  end
end