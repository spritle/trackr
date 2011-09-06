require 'rho/rhocontroller'
require 'helpers/browser_helper'

class ActivityController < Rho::RhoController
  include BrowserHelper

  #GET /Activity
  def index
    @activities = Activity.find(:all)
    @menu = {"View Projects" => "/app/Project/"}
    render
  end

  # GET /Activity/{1}
  def show
    @activity = Activity.find(@params['id'])
    if @activity
      render :action => :show
    else
      redirect :action => :index
    end
  end

  # GET /Activity/new
  def new
    @activity = Activity.new
    render :action => :new
  end

  # GET /Activity/{1}/edit
  def edit
    @activity = Activity.find(@params['id'])
    if @activity
      render :action => :edit
    else
      redirect :action => :index
    end
  end

  # POST /Activity/create
  def create
    @activity = Activity.new(@params['activity'])
    @activity.save
    redirect :action => :index
  end

  # POST /Activity/{1}/update
  def update
    @activity = Activity.find(@params['id'])
    @activity.update_attributes(@params['activity']) if @activity
    redirect :action => :index
  end

  # POST /Activity/{1}/delete
  def delete
    @activity = Activity.find(@params['id'])
    @activity.destroy if @activity
    redirect :action => :index
  end

 def activity_feed
   if System.has_network
    Rho::AsyncHttp.get(
      :url => 'http://www.pivotaltracker.com/services/v3/activities?limit=10',
      :headers => {'X-TrackerToken' => Rho::RhoConfig.Token},
      :callback => (url_for :action => :activity_callback),
      :callback_param => "" )
   else
     redirect :index
   end
 end

  def activity_callback
    unless @params['body'].nil?
      xml_response = REXML::Document.new(@params['body'])
      Activity.delete_all
      xml_response.elements.each("*/activity") do |element|
        values = Hash.new
        values['author'] = element.elements['author'].text unless element.elements['author'].nil?
        values['projectid'] = element.elements['project_id'].text unless element.elements['project_id'].nil?
        values['description'] = element.elements['description'].text unless element.elements['description'].nil?
        values['author'] = element.elements['author'].text unless element.elements['author'].nil?
        @activity = Activity.new(values)
        @activity.save
      end
      WebView.navigate(url_for :action => :index)
    end unless @params['status'] == 'error'
  end

end
