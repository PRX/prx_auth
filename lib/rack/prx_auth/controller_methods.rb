class Rack::PrxAuth
  module ControllerMethods
    def current_user
      User.find(id: request.env['prx.auth'].user_id)
    end

    def user_logged_in?
      !!current_user
    end
  end
end
