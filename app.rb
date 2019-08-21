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
      return erb :if_admin if User.find_by(sessionid: cookies[:sessionid]).id == 'admin' && params[:this_1s_4dmin_flag] != '!qazxsw2'
      erb :top
    else
      erb :introduction
    end
  end

  get '/rules' do
    erb :rule
  end

  get '/edit' do
    redirect '/login' unless User.find_by(sessionid: cookies[:sessionid])
    return erb :if_admin if User.find_by(sessionid: cookies[:sessionid]).id == 'admin' && params[:this_1s_4dmin_flag] != '!qazxsw2'

    erb :edit
  end

  post '/preview' do
    redirect '/login' unless User.find_by(sessionid: cookies[:sessionid])
    return erb :if_admin if User.find_by(sessionid: cookies[:sessionid]).id == 'admin' && params[:this_1s_4dmin_flag] != '!qazxsw2'

    @id = params[:id]
    @style = params[:style]
    @decoded_style = Base64.encode64(@style)
    erb :preview
  end

  post '/post' do
    redirect '/login' unless User.find_by(sessionid: cookies[:sessionid])
    return erb :if_admin if User.find_by(sessionid: cookies[:sessionid]).id == 'admin' && params[:this_1s_4dmin_flag] != '!qazxsw2'

    @style = Base64.decode64(params[:decoded_style])
    user = User.find_by(sessionid: cookies[:sessionid])
    id = Base64.urlsafe_encode64(Digest::SHA256.digest(Time.now.to_s + user.id))

    if @style.length > 10000
      redirect '/edit'
    end

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
    redirect '/login' unless User.find_by(sessionid: cookies[:sessionid])
    return erb :if_admin if User.find_by(sessionid: cookies[:sessionid]).id == 'admin' && params[:this_1s_4dmin_flag] != '!qazxsw2'

    redirect '/' unless Style.exists?(params[:id])
    style_record = Style.find(params[:id])
    @id = style_record.id
    @style = style_record.style

    erb :style
  end

  post '/proud' do
    redirect '/login' unless User.find_by(sessionid: cookies[:sessionid])
    return erb :if_admin if User.find_by(sessionid: cookies[:sessionid]).id == 'admin' && params[:this_1s_4dmin_flag] != '!qazxsw2'

    @id = params[:id]

    Thread.new { Scraper.scrape($top_level, @id) }.run
    erb :proud
  end

  get '/fix' do
    redirect '/login' unless User.find_by(sessionid: cookies[:sessionid])
    return erb :if_admin if User.find_by(sessionid: cookies[:sessionid]).id == 'admin' && params[:this_1s_4dmin_flag] != '!qazxsw2'

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

  get '/secret-puzzle-login' do
    if (sessionid = cookies['sessionid']) && User.find_by(sessionid: sessionid)
      redirect '/'
    end
    @message = ''
    erb :secret_puzzle
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

      return erb :flag if user.id == 'admin'

      redirect '/'
    else
      @message = 'ユーザー名またはパスワードが間違っています'
      return erb :login
    end
  end

  post '/secret-puzzle-login' do
    bin_array = Array.new(8) { Array.new(8, 0) }
    params[:sessionid].each do |s|
      x, y = s.split(',').map(&:to_i)
      bin_array[y][x] = 1
    end

    sessionid = bin_array.map { |b| b.join.to_i(2).to_s(16) }.join('_')
    user = User.find_by(sessionid: sessionid)
    if user.id == 'admin'
      return erb :flag
    elsif user
      cookies['sessionid'] = user.sessionid
      redirect '/'
    else
      @message = '秘密のパスワードが間違っています'
      return erb :secret_puzzle
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

    if params[:name].length > 16
      @message = 'ユーザー名は16文字以下である必要があります'
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
