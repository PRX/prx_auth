require 'rails/railtie'

class Rack::PrxAuth
  class Railtie < Rails::Railtie
    config.to_prepare do |app|
      ApplicationController.send(:include, Rack::PrxAuth::ControllerMethods)
      app.middleware.insert_before ActionDispatch::ParamsParser, 'Rack::PrxAuth'
    end
  end
end
