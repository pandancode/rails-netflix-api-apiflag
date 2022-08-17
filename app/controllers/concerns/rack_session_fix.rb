# ! There are several ways to resolve this issue:
# ! ActionDispatch::Request::Session::DisabledSessionError (Your application has sessions disabled. To write to the session you must first configure a session store):
# ! Implemented solution
# https://github.com/waiting-for-dev/devise-jwt/issues/235#issuecomment-1214414894
# This is the same implementation from this guiy:
# https://github.com/heartcombo/devise/issues/5443#issuecomment-1009779292

module RackSessionFix
  extend ActiveSupport::Concern
  class FakeRackSession < Hash
    def enabled?
      false
    end
  end
  included do
    before_action :set_fake_rack_session_for_devise
    private
    def set_fake_rack_session_for_devise
      request.env['rack.session'] ||= FakeRackSession.new
    end
  end
end
