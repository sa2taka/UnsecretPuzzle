# frozen_string_literal: true

require 'selenium-webdriver'
require 'webdrivers'
require_relative '../models.rb'

class Scraper
  def self.scrape(top_level, id)
    client = Selenium::WebDriver::Remote::Http::Default.new
    # どうやらtimeoutが効かない模様
    # ncではなくちゃんとしたHTTPサーバーならばOKだと思われる
    client.timeout = 5
    driver = Selenium::WebDriver.for :chrome, http_client: client
    driver.manage.timeouts.implicit_wait = 4
    driver.get(top_level.to_s)
    sleep 6
    driver.manage.add_cookie('name': 'sessionid', 'value': User.find('admin').sessionid)

    driver.get("#{top_level}/styles?id=#{id}&this_1s_4dmin_flag=!qazxsw2")
    sleep 2
  ensure
    driver.quit
  end
end
