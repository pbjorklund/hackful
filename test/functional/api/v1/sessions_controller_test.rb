require 'test_helper'
require 'rest_client'

class Api::V1::SessionsControllerTest < ActionController::TestCase
  #include Devise::TestHelpers

  def setup
    @comment = comments(:first)
    @post = posts(:first)
    @user = users(:david)
    @user.reset_authentication_token!
    @user.password = "test123"
    @user.password_confirmation = "test123"
    @user.save
  end

  def teardown
    @comemnt = nil
    @post = nil
    @user = nil
  end

  test "login and recieve auth_token" do
    #post "create", :format => :json, :user => {:email => @user.email, :password => @user.password}
    
    response_str = RestClient.post "http://localhost:3000/api/v1/sessions/login", 
      {:user => {:email => @user.email, :password => @user.password}}.to_json, 
      :content_type => :json, 
      :accept => :json

    session_json = JSON.parse(response_str)

    assert_equal @user.email, session_json["email"]
    assert_equal @user.name, session_json["name"]
    assert_equal @user.authentication_token, session_json["auth_token"]
    assert_response :success
  end

  test "try to login and fail" do
    post "create", 
      :format => :json, 
      :user => {:email => @user.email, :password => "WRONG PASSWORD"}
    session_json = JSON.parse(response.body)

    assert_equal false, session_json["success"]
    assert_response 401
  end

  test "logout with existing token" do
    post "create", 
      :format => :json, 
      :user => {:email => @user.email, :password => @user.password}
    
    session_json = JSON.parse(response.body)
    auth_token = session_json["auth_token"]
    assert !auth_token.nil?

    delete "destroy", :format => :json, :auth_token => auth_token
    destroy_session_json = JSON.parse(response.body)

    assert destroy_session_json["success"]
    assert_response :success
  end

  test "try to logout with expired token" do
    post "create", 
      :format => :json, 
      :user => {:email => @user.email, :password => @user.password}
    
    session_json = JSON.parse(response.body)
    auth_token = session_json["auth_token"]
    assert !auth_token.nil?
    
    @user.reset_authentication_token!
      
    delete "destroy", :format => :json, :auth_token => auth_token

    assert !destroy_session_json["success"]
    assert_response 401
  end
end
