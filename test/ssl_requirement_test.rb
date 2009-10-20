require 'rubygems'
require 'actionpack'
require 'action_controller'
require 'action_controller/test_process'
require 'test/unit'
require "#{File.dirname(__FILE__)}/../lib/ssl_requirement"

ActionController::Base.logger = nil
ActionController::Routing::Routes.reload rescue nil

class SslRequirementController < ActionController::Base
  include SslRequirement
  
  ssl_required :a, :b
  ssl_allowed :c
  
  def a
    render :nothing => true
  end
  
  def b
    render :nothing => true
  end
  
  def c
    render :nothing => true
  end
  
  def d
    render :nothing => true
  end
  
  def set_flash
    flash[:foo] = "bar"
  end
end

class SslRequirementTest < ActionController::TestCase
  def setup
    @controller = SslRequirementController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  test "redirect to https preserves flash" do 
    get :set_flash
    get :b
    assert_response :redirect
    assert_equal "bar", flash[:foo]
  end
  
  test "not redirecting to https does not preserve the flash" do 
    get :set_flash
    get :d
    assert_response :success
    assert_nil flash[:foo]
  end
  
  test "redirect to http preserves flash" do 
    get :set_flash
    @request.env['HTTPS'] = "on"
    get :d
    assert_response :redirect
    assert_equal "bar", flash[:foo]
  end
  
  test "not redirecting to http does not preserve the flash" do 
    get :set_flash
    @request.env['HTTPS'] = "on"
    get :a
    assert_response :success
    assert_nil flash[:foo]
  end
  
  test "required without ssl" do 
    assert_not_equal "on", @request.env["HTTPS"]
    get :a
    assert_response :redirect
    assert_match %r{^https://}, @response.headers['Location']
    get :b
    assert_response :redirect
    assert_match %r{^https://}, @response.headers['Location']
  end
  
  test "required with ssl" do 
    @request.env['HTTPS'] = "on"
    get :a
    assert_response :success
    get :b
    assert_response :success
  end

  test "disallowed without ssl" do 
    assert_not_equal "on", @request.env["HTTPS"]
    get :d
    assert_response :success
  end

  test "disallowed with ssl" do 
    @request.env['HTTPS'] = "on"
    get :d
    assert_response :redirect
    assert_match %r{^http://}, @response.headers['Location']
  end

  test "allowed without ssl" do 
    assert_not_equal "on", @request.env["HTTPS"]
    get :c
    assert_response :success
  end

  test "allowed with ssl" do 
    @request.env['HTTPS'] = "on"
    get :c
    assert_response :success
  end
end
