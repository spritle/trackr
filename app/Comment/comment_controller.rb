require 'rho/rhocontroller'
require 'helpers/browser_helper'

class CommentController < Rho::RhoController
  include BrowserHelper

  #GET /Comment
  def index
    @menu = {"Back " => "/app/Story/show?id=#{Rho::RhoConfig.current_story_id}", "Add comment" => "/app/Comment/new"}
    @comments = Comment.find(:all, :conditions => {:story_id => Rho::RhoConfig.current_story_id})
    render :action => :index, :back => "/app/Story/show?id=#{Rho::RhoConfig.current_story_id}"
  end

  # GET /Comment/{1}
  def show
    @comment = Comment.find(@params['id'])
    if @comment
      render :action => :show
    else
      redirect :action => :index
    end
  end

  # GET /Comment/new
  def new
    @menu = {"Cancel" => "/app/Comment/index"}
    @comment = Comment.new
    render :action => :new, :back => "/app/Comment/index"
  end

  # GET /Comment/{1}/edit
  def edit
    @comment = Comment.find(@params['id'])
    if @comment
      render :action => :edit
    else
      redirect :action => :index
    end
  end

  # POST /Comment/create
  def create
    projectid = Rho::RhoConfig.current_project_id
    story_id = Rho::RhoConfig.current_story_id
    params_comment = ["text","author","noted_at"]
    url = "https://www.pivotaltracker.com/services/v3/projects/#{projectid}/stories/#{story_id}/notes"
    Rho::AsyncHttp.post(
      :url => url,
      :body => "#{hash_to_xml('note',params_comment,@params['comment'])}",
      :headers => {'X-TrackerToken' => Rho::RhoConfig.Token, 'Content-type' => 'application/xml'},
      :callback => (url_for :action => :httppost_callback),
      :callback_param => "story_id=#{story_id}",
      :ssl_verify_peer => false)
    redirect :controller => "Settings", :action => :wait
  end

  def httppost_callback
    if @params['status'] == 'error'
      redirect :controller => "Settings", :action => "login", :query => {:msg => @params['status'] }
    else
      if !@params['body'].nil?
        xml = REXML::Document.new(@params['body'])
        xml.elements.each("//note") do |n|
          notes = Hash.new
          notes['object'] = n.elements['id'].text unless n.elements['id'].nil?
          notes['text'] = n.elements['text'].text unless n.elements['text'].nil?
          notes['author'] = n.elements['author'].text unless n.elements['author'].nil?
          notes['noted_at'] = "#{get_date(n.elements['noted_at'].text)}, #{n.elements['noted_at'].text[11,12]}" unless n.elements['noted_at'].nil?
          notes['story_id'] = @params['story_id']
          @comment = Comment.new(notes) unless notes.nil?
          @comment.save
          @story = Story.find(@params['story_id'])
          @story.num_comments = @story.num_comments.to_i + 1
          @story.update_attributes(@story) if @story
        end
      end
    end
    WebView.navigate( url_for :controller => "Story", :action => :index )
  end

  # POST /Comment/{1}/update
  def update
    @comment = Comment.find(@params['id'])
    @comment.update_attributes(@params['comment']) if @comment
    redirect :action => :index
  end

  # POST /Comment/{1}/delete
  def delete
    @comment = Comment.find(@params['id'])
    @comment.destroy if @comment
    redirect :action => :index
  end
end
