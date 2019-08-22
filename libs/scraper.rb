# -*- coding: utf-8 -*-
# frozen_string_literal: true

require 'selenium-webdriver'
require 'webdrivers'
require_relative '../models.rb'

class Scraper
  def self.scrape(top_level, id)
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-gpu')
    options.add_argument('--disable-dev-shm-usage')

    client = Selenium::WebDriver::Remote::Http::Default.new
    # どうやらtimeoutが効かない模様
    # ncではなくちゃんとしたHTTPサーバーならばOKだと思われる
    client.open_timeout = 30
    driver = Selenium::WebDriver.for :chrome, http_client: client, options: options
    driver.manage.timeouts.implicit_wait = 4

    driver.get(top_level.to_s)
    sleep 6
    driver.manage.add_cookie('name': 'sessionid', 'value': User.find('admin').sessionid)
    begin
      driver.get("#{top_level}/styles?id=#{id}&is_it_admin=!qazxsw2")
      sleep 2
    ensure
      driver.quit
    end
  end
end
