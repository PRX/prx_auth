require 'rails/railtie'
require 'rack/prx_auth/controller_methods'
require 'rack/prx_auth'

class Rack::PrxAuth
  class Railtie < Rails::Railtie
    config.to_prepare do
      ApplicationController.send(:include, Rack::PrxAuth::ControllerMethods)
    end

    initializer 'rack-prx_auth.insert_middleware' do |app|
      app.config.middleware.insert_before ActionDispatch::ParamsParser, 'Rack::PrxAuth'
    end
  end
end
