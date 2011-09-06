require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'rexml/document'

class ProjectController < Rho::RhoController
  include BrowserHelper

  def load_tab
    create_tabbar
  end
  
  #GET /Project
  def get_projects
    @projects = Project.find(:all)
    if @projects == []
      if System.has_network
        redirect :controller => "Settings", :action => :wait
        Rho::AsyncHttp.get(
          :url => 'http://www.pivotaltracker.com/services/v3/projects',
          :headers => {'X-TrackerToken' => Rho::RhoConfig.Token},
          :callback => (url_for :action => :httpget_callback),
          :callback_param => "")
        redirect :controller => "Settings", :action => :wait
      else
       redirect :index, :back => :close
      end
    else
      redirect :index, :back => :close
    end
  end

  def httpget_callback
    if @params['status'] == 'error'
      redirect :controller => "Settings", :action => "login", :query => {:msg => @params['status'] }
    else
      if !@params['body'].nil?
        doc = REXML::Document.new(@params['body'])
        project_xml = REXML::XPath.each( doc, "//projects/project/" )
        Project.delete_all
        project_xml.each_with_index  do |pro,i|
          
          values = Hash.new
          values['name'] = pro.elements['name'].text if !pro.elements['name'].nil?
          values['object'] = pro.elements['id'].text if !pro.elements['id'].nil?
          values['current_velocity'] = pro.elements['current_velocity'].text if !pro.elements['current_velocity'].nil?
          values['point_scale'] = pro.elements['point_scale'].text if !pro.elements['point_scale'].nil?
          values['use_https'] = pro.elements['use_https'].text if !pro.elements['use_https'].nil?
          @projects = Project.new(values)
          @projects.save
        end
        WebView.navigate(url_for :action => :index, :back => :close)
      end
    end
  end

  def index
    @menu = {"Logout" => "app/Settings/logout"}
    @projects = Project.find(:all)
    render :back => :close
  end

  # GET /Project/{1}
  def show
    @project = Project.find(@params['id'])
    if @project
      render :action => :show
    else
      redirect :action => :index
    end
  end

  # GET /Project/new
  def new
    @project = Project.new
    render :action => :new
  end

  # GET /Project/{1}/edit
  def edit
    @project = Project.find(@params['id'])
    if @project
      render :action => :edit
    else
      redirect :action => :index
    end
  end

  # POST /Project/create
  def create
    @project = Project.create(@params['project'])
    redirect :action => :index
  end

  # POST /Project/{1}/update
  def update
    @project = Project.find(@params['id'])
    @project.update_attributes(@params['project']) if @project
    redirect :action => :index
  end

  # POST /Project/{1}/delete
  def delete
    @project = Project.find(@params['id'])
    @project.destroy if @project
    redirect :action => :index
  end

  def create_tabbar
    ::NativeBar.create(Rho::RhoApplication::NOBAR_TYPE, [])
    tabs = [{ :label => "My Projects", :action => '/app/Project/get_projects', :icon => "/public/images/tabs/project.png", :reload => false},
      { :label => "Settings", :action => '/app/Settings', :icon => "/public/images/tabs/settings.png", :reload => false}]
    ::NativeBar.create(Rho::RhoApplication::TABBAR_TYPE, tabs)
    ::NativeBar.switch_tab(0)
  end

end

#{ :label => "Activity feed", :action => '/app/Activity/activity_feed', :icon => "/public/images/tabs/activityfeed_btn.png", :reload => true},