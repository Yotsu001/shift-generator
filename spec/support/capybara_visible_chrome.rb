require "capybara/rspec"
require "selenium/webdriver"
require "socket"
require "tmpdir"
require "fileutils"

module VisibleChromeSession
  class << self
    attr_accessor :browser, :profile_dir

    def cleanup!
      browser&.quit
    rescue StandardError
      nil
    ensure
      self.browser = nil
      return unless profile_dir

      FileUtils.rm_rf(profile_dir)
      self.profile_dir = nil
    end
  end
end

if ENV["SHOW_BROWSER"] == "1"
  Capybara.server_host = "0.0.0.0"
  Capybara.server_port = 4000
  Capybara.always_include_port = true

  private_ip = Socket.ip_address_list.find do |address|
    address.ipv4? && !address.ipv4_loopback? && !address.ipv4_multicast?
  end
  Capybara.app_host = "http://#{private_ip.ip_address}:#{Capybara.server_port}" if private_ip
end

Capybara.register_driver :visible_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  chrome_binary = ENV.fetch("CHROME_BIN", "/usr/bin/google-chrome")
  chrome_driver_path = ENV.fetch(
    "CHROMEDRIVER_BIN",
    File.expand_path("~/.cache/selenium/chromedriver/linux64/143.0.7499.40/chromedriver")
  )
  VisibleChromeSession.profile_dir ||= Dir.mktmpdir("capybara-visible-chrome-")

  options.binary = chrome_binary if File.exist?(chrome_binary)
  options.add_argument("--window-size=1400,1200")
  options.add_argument("--disable-search-engine-choice-screen")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--user-data-dir=#{VisibleChromeSession.profile_dir}")

  service = Selenium::WebDriver::Service.chrome(path: chrome_driver_path)
  driver = Capybara::Selenium::Driver.new(app, browser: :chrome, options: options, service: service)
  VisibleChromeSession.browser ||= driver.browser
  driver
end
