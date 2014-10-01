class Rack::PrxAuth
  module ControllerMethods
    def current_user
      if request.env['prx.auth']
        User.find_by(id: request.env['prx.auth'].user_id)
      else
        nil
      end
    end

    def user_logged_in?
      !!current_user
    end
  end
end
