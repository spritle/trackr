require 'rho'
require 'rho/rhocontroller'
require 'rho/rhoerror'
require 'helpers/browser_helper'
require 'rexml/document'

class SettingsController < Rho::RhoController
  include BrowserHelper
  
  def index
    @menu = {}
    @msg = @params['msg']
    render :back => "/app/Project/create_tabbar"
  end

  def login
    @menu = {}
    @msg = @params['msg']
    if Rho::RhoConfig.Token == ''
      render :action => :login, :back => :close
    else
      redirect :controller => "Project" ,:action => :create_tabbar
    end
  end

  def do_login
    @menu = {}
    if !@params['token'].empty?
      @params['login'] = @params['token']
      @params['password'] = "nomatterpass"
    end
    if @params['login']
      begin
        Iteration.delete_all
        Story.delete_all
        Comment.delete_all
        Activity.delete_all
        Project.delete_all
        authenticate(@params['login'], @params['password'])
        render :action => :wait
      rescue Rho::RhoError => e
        @msg = e.message
        render :action => :login
      end
    else
      @msg = Rho::RhoError.err_message(Rho::RhoError::ERR_UNATHORIZED) unless @msg && @msg.length > 0
      render :action => :login
    end
  end
  
  def logout
    @menu = {}
    ::NativeBar.create(Rho::RhoApplication::NOBAR_TYPE, [])
    Rho::RhoConfig.Token = ''
    Rho::RhoConfig.current_project_id = ''
    Rho::RhoConfig.current_iteration = ''
    Rho::RhoConfig.current_point_scale = ''
    Rho::RhoConfig.current_login = '0'
    ::Rhom::Rhom.database_full_reset_and_logout
    @msg = "You have been logged out."
    render :action => :login, :back => :close
  end
  
  def reset
    render :action => :reset
  end
  
  def do_reset
    ::Rhom::Rhom.database_full_reset
    @msg = "Database has been reset."
    redirect :action => :index, :query => {:msg => @msg}
  end

  def authenticate(username, password)
    unless password == "nomatterpass"
      Rho::AsyncHttp.get(
        :url => 'https://www.pivotaltracker.com/services/v3/tokens/active',
        :authentication => {:type => :basic, :username => username, :password => password},
        :callback => (url_for :action => :httpget_callback),
        :callback_param => "username=#{username}&user_type=user",
        :ssl_verify_peer => false)
    else
      Rho::AsyncHttp.get(
        :url => 'https://www.pivotaltracker.com/services/v3/projects',
        :headers => {'X-TrackerToken' => username},
        :callback => (url_for :action => :httpget_callback),
        :callback_param => "username=#{username}&user_type=token",
        :ssl_verify_peer => false)
    end
    render :action => :wait
  end

  def get_res
    @@get_result
  end

  def get_error
    @@error_params
  end

  def httpget_callback
    puts "httpget_callback: #{@params}"
    unless @params['status'] == 'ok'
      @@error_params = @params
      WebView.navigate( url_for :action => :show_error )
    else
      @@get_result = @params['body']
      puts "@@get_result : #{@@get_result}"

      begin
        unless @@get_result == nil
          xml_response = REXML::Document.new(@@get_result)
          Rho::RhoConfig.Token = xml_response.root.elements["guid"].text if @params['user_type'] == "user"
          Rho::RhoConfig.Token = @params['username'] if @params['user_type'] == "token"
          Rho::RhoConfig.current_login = '1'
        end
      rescue Exception => e
        puts "Error: #{e}"
        Alert.show_popup("Error : #{e}")
        @@get_result = "Error: #{e}"
      end
      if System::get_property('platform') == 'Blackberry'
        WebView.navigate( url_for :controller => :Project, :action => :get_projects )
      else
        WebView.navigate( url_for :controller => :Project, :action => :load_tab )
      end
    end

  end

  def show_error
    @errors = get_error
    err_type = @errors['http_error'].to_i
    @msg = "Invalid username or password" if err_type == 401
    WebView.navigate( url_for :action => :login, :query => {:msg => @msg} )
  end

  def send_log
    Rho::RhoConfig.send_log
    Alert.show_popup "Thanks for sending the logs."
    redirect :controller => "Settings", :action => :index
  end

  def about
    @menu = {"Back " => :back}
    render :action => "about", :back => "/app/Settings/index"
  end

  def wait
    @menu = {}
  end

end
