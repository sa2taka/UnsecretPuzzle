# frozen_string_literal: true

require 'selenium-webdriver'
require 'webdrivers'
require_relative '../models.rb'

class Scraper
  def self.scrape(top_level, id)
    driver = Selenium::WebDriver.for :chrome
    driver.manage.timeouts.implicit_wait = 4
    driver.get(top_level.to_s)
    sleep 2
    driver.manage.add_cookie('name': 'sessionid', 'value': User.find('admin').sessionid)

    driver.get("#{top_level}/styles?id=#{id}")
    sleep 2
    driver.quit
  end
end
