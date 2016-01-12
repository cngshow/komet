require 'test_helper'

class EtsDashboardControllerTest < ActionController::TestCase
  test "should get metadata" do
    get :metadata
    assert_response :success
  end

end
