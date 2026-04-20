# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'

Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Warden::Test::Helpers, type: :system
  config.include SystemHelpers, type: :system
  config.before(:suite) do
    Warden.test_mode!
  end
  config.before(:context, type: :system) do
    if ENV["SHOW_BROWSER"] == "1"
      driven_by(:visible_chrome)
    else
      driven_by(:rack_test)
    end
  end
  config.after(:each, type: :system) do
    if ENV["SHOW_BROWSER"] == "1"
      browser = VisibleChromeSession.browser

      if browser
        handles = browser.window_handles
        if handles.any?
          browser.switch_to.window(handles.first)
          handles.drop(1).each do |handle|
            browser.switch_to.window(handle)
            browser.close
          rescue StandardError
            nil
          end
          browser.switch_to.window(handles.first)
        end
      end
    end

    Capybara.reset_sessions!
    Warden.test_reset!
  end
  config.after(:suite) do
    VisibleChromeSession.cleanup! if ENV["SHOW_BROWSER"] == "1"
  end
  config.before(:each, type: :request) do
    allow_any_instance_of(ApplicationController).to receive(:basic_auth).and_return(true)
  end
  config.before(:each, type: :system) do
    allow_any_instance_of(ApplicationController).to receive(:basic_auth).and_return(true)
  end
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
