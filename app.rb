# frozen_string_literal: false

require 'rubygems'
require 'sinatra'
require 'sinatra/base'
require 'sinatra/cookies'
require 'active_record'
require 'base64'
require 'digest/sha2'

require_relative './models'
require_relative './config.rb'
require_relative './libs/scraper'

$TARGET_HTML = <<~EOS
  <div class="top-level">
    <h1 class="title">タイトル</h1>
    <article class="posts-area">
      <article class="post">
        <h2 class="post-title">ポスト1</h2>
        <div class="post-content">
          <p>post, post and post.</p>
        </div>
      </article>
      <article class="post">
        <h2 class="post-title">ポスト2</h2>
        <div class="post-content">
          <p>get, get and get.</p>
        </div>
      </article>
    </article>
  </div>
EOS
$TARGET_HTML.strip!.freeze

$DEFAULT_STYLE = <<~EOS
  .top-level {

  }

  .posts-area {

  }

  .post {

  }

  .post-title {

  }

  .post-content {

  }
EOS
$DEFAULT_STYLE.strip!.freeze

class UnsecretPassword < Sinatra::Base
  helpers Sinatra::Cookies

  helpers do
    def user
      User.find_by(sessionid: cookies[:sessionid])
    end

    def html_safe(text)
      Rack::Utils.escape_html(text)
    end
  end

  get '/' do
    if (sessionid = cookies['sessionid']) && User.find_by(sessionid: sessionid)
      erb :top
    else
      erb :introduction
    end
  end

  get '/rules' do
    erb :rule
  end

  get '/edit' do
    erb :edit
  end

  post '/preview' do
    @id = params[:id]
    @style = params[:style]
    @decoded_style = Base64.encode64(@style)
    erb :preview
  end

  post '/post' do
    @style = Base64.decode64(params[:decoded_style])
    user = User.find_by(sessionid: cookies[:sessionid])
    id = Base64.urlsafe_encode64(Digest::SHA256.digest(Time.now.to_s + user.id))

    s = Style.new
    if Style.exists? params[:id]
      s = Style.find(params[:id])
    else
      s.id = id
      s.user_id = user.id
    end

    s.style = @style
    s.save

    redirect '/styles?id=' + s.id
  end

  get '/styles' do
    redirect '/' unless Style.exists?(params[:id])
    style_record = Style.find(params[:id])
    @id = style_record.id
    @style = style_record.style

    erb :style
  end

  post '/proud' do
    @id = params[:id]

    Thread.new { Scraper.scrape($top_level, @id) }.run
    erb :proud
  end

  get '/fix' do
    redirect '/' unless Style.exists?(params[:id])

    style_record = Style.find(params[:id])
    @id = style_record.id
    @style = style_record.style

    erb :edit
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
    redirect '/login' unless User.find_by(sessionid: cookies[:sessionid])
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
