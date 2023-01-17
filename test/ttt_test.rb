ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require "fileutils"

require_relative "../ttt"

class TicTacToeTest < MiniTest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def session
    last_request.env["rack.session"]
  end

  def user_session
    { "rack.session" => { username: 'testing' } }
  end

  def test_redirect_to_sign_in_page
    get "/"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Sign In"
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_view_sign_up_form
    get "/users/signup"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Sign Up"
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_submit_sign_up_form
    post "/users/signup", username: "testing", password: "testing"
    assert_equal 302, last_response.status
    assert_equal "Your account has been created. Log in to play", session[:message]
  end

  def test_submit_sign_in_form_and_sign_in_to_main_game_page
    post "/signin", username: "testing1", password: "testing"
    assert_equal 302, last_response.status
    assert_equal "Welcome testing1", session[:message]

    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Start Game"
  end

  def test_submit_sign_in_form_with_invalid_credentials
    post "/signin", username: "invalid", password: "invalid"
    assert_equal 422, last_response.status
    assert_equal "Invalid credentials", session[:message]

  end

  def test_ok
  end




  def teardown
    FileUtils.rm_rf(data_path)
  end
end
