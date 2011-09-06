require 'rho/rhocontroller'
require 'helpers/browser_helper'

class StoryController < Rho::RhoController
  include BrowserHelper

  def refresh
    delete_object(Iteration, @params["projectid"], @params["iteration"])
    delete_object(Story, @params["projectid"], @params["iteration"])
    delete_object(Comment, @params["projectid"], @params["iteration"])
    redirect :action => :get_stories, :query => { :projectid => @params["projectid"], :iteration => @params["iteration"] }
  end

  def delete_object (object, projectid, iteration)
     hash = object.find(:all, :conditions => {:projectid => projectid, :iteration => iteration})
     hash.each do |item|
       @object = object.find(item.object)
       @object.destroy if @object
     end
  end
  
  def get_stories
    @project = Project.find(@params["projectid"])
    projectid = @params["projectid"]
    iteration = @params["iteration"]
    Rho::RhoConfig.current_point_scale = @project.point_scale
    Rho::RhoConfig.current_project_id = projectid
    Rho::RhoConfig.current_iteration = iteration
    @stories = Story.find(:all, :conditions => {:projectid  => projectid, :iteration => iteration})
    if @stories == []
      if System.has_network    
        if iteration == "icebox"
          url = "https://www.pivotaltracker.com/services/v3/projects/#{projectid}/stories?filter=current_state%3Aunscheduled"
        else
          url = "https://www.pivotaltracker.com/services/v3/projects/#{projectid}/iterations/#{iteration}"
        end

        if @params["ssl"] == "true"
          ssl = true
        else
          ssl = false
        end
        Rho::AsyncHttp.get(
          :url => url,
          :headers => {'X-TrackerToken' => Rho::RhoConfig.Token},
          :callback => (url_for :action => :httpget_callback),
          :callback_param => "iteration=#{iteration}",
          :ssl_verify_peer => ssl)
        redirect :controller => "Settings", :action => :wait
      else
        Rho::RhoConfig.current_action = '1'
        redirect :index, :back => "/app/Story/index?projectid=#{projectid}&iteration=#{iteration}"
      end
    else
      Rho::RhoConfig.current_action = '1'
      redirect :index, :back => "/app/Story/index?projectid=#{projectid}&iteration=#{iteration}"
    end 
  end

  def httpget_callback
    if @params['status'] == 'error'
      redirect :controller => "Settings", :action => "login", :query => {:msg => @params['status'] }
    else
      if !@params['body'].nil?
        xml = REXML::Document.new(@params['body'])
        unless @params['iteration'] == "icebox"
          xml.elements.each("//iteration")  do |ite|
            iterations = Hash.new
            iterations['object'] = "%02d" % ite.elements['id'].text  unless ite.elements['id'].nil?
            iterations['projectid'] = Rho::RhoConfig.current_project_id if Rho::RhoConfig.current_project_id
            iterations['iteration'] = @params['iteration']  unless @params['iteration'].nil?
            iterations['number'] = "%02d" % ite.elements['number'].text  unless ite.elements['number'].nil?
            iterations['start'] = get_date(ite.elements['start'].text) unless ite.elements['number'].nil?
            iterations['finish'] = ite.elements['finish'].text unless ite.elements['number'].nil?

            estimate = 0
            ite.elements.each("stories/story") do |sto|
              stories = Hash.new
              stories['iteration'] = @params['iteration']  unless @params['iteration'].nil?
              stories['iteration_id'] = iterations['object']
              stories['name'] = sto.elements['name'].text unless sto.elements['name'].nil?
              stories['object'] = sto.elements['id'].text unless sto.elements['id'].nil?
              stories['projectid'] = Rho::RhoConfig.current_project_id if Rho::RhoConfig.current_project_id
              stories['story_type'] = sto.elements['story_type'].text unless sto.elements['story_type'].nil?
              stories['estimate'] = sto.elements['estimate'].text unless sto.elements['estimate'].nil?
              stories['current_state'] = sto.elements['current_state'].text unless sto.elements['current_state'].nil?
              stories['description'] = sto.elements['description'].text unless sto.elements['description'].nil?
              stories['requested_by'] = sto.elements['requested_by'].text unless sto.elements['requested_by'].nil?
              stories['owned_by'] = sto.elements['owned_by'].text unless sto.elements['owned_by'].nil?
              stories['created_at'] = "#{get_date(sto.elements['created_at'].text)}, #{sto.elements['created_at'].text[11,12]}" unless sto.elements['created_at'].nil?
              stories['accepted_at'] = "#{get_date(sto.elements['accepted_at'].text)}, #{sto.elements['accepted_at'].text[11,12]}" unless sto.elements['accepted_at'].nil?
              stories['labels'] = sto.elements['labels'].text unless sto.elements['labels'].nil?
              estimate = estimate.to_i + stories['estimate'].to_i unless stories['estimate'].nil? or stories['estimate'].to_i <= 0
              comment = 0

              sto.elements.each("*/note") do |n|
                notes = Hash.new
                notes['object'] = n.elements['id'].text unless n.elements['id'].nil?
                notes['text'] = n.elements['text'].text unless n.elements['text'].nil?
                notes['author'] = n.elements['author'].text unless n.elements['author'].nil?
                notes['noted_at'] = "#{get_date(n.elements['noted_at'].text)}, #{n.elements['noted_at'].text[11,12]}" unless n.elements['noted_at'].nil?
                notes['story_id'] = sto.elements['id'].text unless sto.elements['id'].nil?
                comment = comment.to_i + 1
                @comment = Comment.new(notes) unless notes.nil?
                @comment.save
              end
              stories['num_comments'] = comment
              @stories = Story.new(stories)
              @stories.save
            end
            iterations['points'] = estimate
            @iterations = Iteration.new(iterations) unless iterations.nil?
            @iterations.save
          end
        else
          xml.elements.each("//story") do |sto|
            stories = Hash.new
            stories['iteration'] = @params['iteration']  unless @params['iteration'].nil?
            stories['name'] = sto.elements['name'].text unless sto.elements['name'].nil?
            stories['object'] = sto.elements['id'].text unless sto.elements['id'].nil?
            stories['projectid'] = Rho::RhoConfig.current_project_id if Rho::RhoConfig.current_project_id
            stories['story_type'] = sto.elements['story_type'].text unless sto.elements['story_type'].nil?
            stories['estimate'] = sto.elements['estimate'].text unless sto.elements['estimate'].nil?
            stories['current_state'] = sto.elements['current_state'].text unless sto.elements['current_state'].nil?
            stories['description'] = sto.elements['description'].text unless sto.elements['description'].nil?
            stories['requested_by'] = sto.elements['requested_by'].text unless sto.elements['requested_by'].nil?
            stories['owned_by'] = sto.elements['owned_by'].text unless sto.elements['owned_by'].nil?
            stories['created_at'] = sto.elements['created_at'].text unless sto.elements['created_at'].nil?
            stories['accepted_at'] = sto.elements['accepted_at'].text unless sto.elements['accepted_at'].nil?
            stories['labels'] = sto.elements['labels'].text unless sto.elements['labels'].nil?
            comment = 0

            sto.elements.each("*/note") do |n|
              notes = Hash.new
              notes['object'] = n.elements['id'].text unless n.elements['id'].nil?
              notes['text'] = n.elements['text'].text unless n.elements['text'].nil?
              notes['author'] = n.elements['author'].text unless n.elements['author'].nil?
              notes['noted_at'] = "#{get_date(n.elements['noted_at'].text)}, #{n.elements['noted_at'].text[11,12]}" unless n.elements['noted_at'].nil?
              notes['story_id'] = sto.elements['id'].text unless sto.elements['id'].nil?
              comment = comment.to_i + 1
              @comment = Comment.new(notes) unless notes.nil?
              @comment.save
            end
            stories['num_comments'] = comment
            @stories = Story.new(stories)
            @stories.save
          end
        end
        
        Rho::RhoConfig.current_action = '1'
        WebView.navigate( url_for :controller => "Story", :action => :index )
      end
    end
  end

  #GET /Story
  def index
    @menu = {"Projects" => "/app/Project/create_tabbar", "Add story" => "/app/Story/new", "Logout" => "app/Settings/logout"}
    projectid = Rho::RhoConfig.current_project_id
    @project = Project.find(projectid)
    iteration = Rho::RhoConfig.current_iteration
    @iteration = iteration
    unless iteration == "icebox"  
      @iterations = Iteration.find(:all, :conditions => {:projectid  => projectid, :iteration => iteration})
      array_story = []
      @iterations.each do |ite|
        array_story << Story.find(:all, :conditions => {:iteration_id  => ite.number })
      end
      @stories = array_story.flatten
    else
      @stories = Story.find(:all, :conditions => {:projectid  => projectid, :iteration => iteration})
    end
    render :action =>:index, :back => "/app/Project/create_tabbar"
  end

  # GET /Story/{1}
  def show
    @menu = {"Stories" => "/app/Story/index"}
    Rho::RhoConfig.current_story_id = @params['id']
    @story = Story.find(@params['id'])
    Rho::RhoConfig.current_action = '0'
    if @story
      render :action => :show, :back => "/app/Story/index"
    else
      redirect :action => :index
    end
  end

  # GET /Story/new
  def new
    @menu = {"Cancel" => "/app/Story/index"}
    @story = Story.new
    @story.point_scale = Rho::RhoConfig.current_point_scale
    Rho::RhoConfig.current_action = '0'
    render :action => :new, :back => "/app/Story/index"
  end

  # GET /Story/{1}/edit
  def edit
    @menu = {"Cancel" => "/app/Story/show?id=#{Rho::RhoConfig.current_story_id}"}
    @story = Story.find(@params['id'])
    @story.point_scale = Rho::RhoConfig.current_point_scale
    if @story
      Rho::RhoConfig.current_action = '0'
      render :action => :edit, :back => "/app/Story/show?id=#{Rho::RhoConfig.current_story_id}"
    else
      redirect :action => :index
    end
  end

  # POST /Story/create
  def create
    @params["story"]["estimate"] = "-1" unless @params["story"]["story_type"] == "feature"
    projectid = Rho::RhoConfig.current_project_id
    params_story  =["name","story_type","estimate","description"]
    url = "https://www.pivotaltracker.com/services/v3/projects/#{projectid}/stories"
    Rho::AsyncHttp.post(
      :url => url,
      :body => "#{hash_to_xml('story',params_story,@params['story'])}",
      :headers => {'X-TrackerToken' => Rho::RhoConfig.Token, 'Content-type' => 'application/xml'},
      :callback => (url_for :action => :httppost_callback),
      :callback_param => "story_id=#{@params['id']}&iteration=#{Rho::RhoConfig.current_iteration}",
      :ssl_verify_peer => false)
    Rho::RhoConfig.current_action = '0'
    redirect :controller => "Settings", :action => :wait
  end

  def httppost_callback
    if @params['status'] == 'error'
      redirect :controller => "Settings", :action => "login", :query => {:msg => @params['status'] }
    else
      if !@params['body'].nil?
        xml = REXML::Document.new(@params['body'])
        xml.elements.each("//story") do |sto|
          stories = Hash.new
          stories['iteration'] = @params['iteration']  unless @params['iteration'].nil?
          stories['name'] = sto.elements['name'].text unless sto.elements['name'].nil?
          stories['object'] = sto.elements['id'].text unless sto.elements['id'].nil?
          stories['projectid'] = Rho::RhoConfig.current_project_id if Rho::RhoConfig.current_project_id
          stories['story_type'] = sto.elements['story_type'].text unless sto.elements['story_type'].nil?
          stories['estimate'] = sto.elements['estimate'].text unless sto.elements['estimate'].nil?
          stories['current_state'] = sto.elements['current_state'].text unless sto.elements['current_state'].nil?
          stories['description'] = sto.elements['description'].text unless sto.elements['description'].nil?
          stories['requested_by'] = sto.elements['requested_by'].text unless sto.elements['requested_by'].nil?
          stories['owned_by'] = sto.elements['owned_by'].text unless sto.elements['owned_by'].nil?
          stories['created_at'] = "#{get_date(sto.elements['created_at'].text)}, #{sto.elements['created_at'].text[11,12]}" unless sto.elements['created_at'].nil?
          stories['accepted_at'] = "#{get_date(sto.elements['accepted_at'].text)}, #{sto.elements['accepted_at'].text[11,12]}" unless sto.elements['accepted_at'].nil?
          stories['labels'] = sto.elements['labels'].text unless sto.elements['labels'].nil?
          stories['num_comments'] = 0
          @stories = Story.new(stories)
          @stories.save
        end
      end
    end
    WebView.navigate(url_for :action => :index )
  end

  # POST /Story/{1}/update
  def update
    @params["story"]["estimate"] = "-1" unless @params["story"]["story_type"] == "feature"
    id = @params['id']
    projectid = @params['story']['projectid']
    params_story = ["name","story_type","current_state","estimate","description"]
    url = "https://www.pivotaltracker.com/services/v3/projects/#{projectid}/stories/#{id}"
    Rho::AsyncHttp.post(
      :url => url,
      :body => "#{hash_to_xml('story',params_story,@params['story'])}",
      :headers => {'X-TrackerToken' => Rho::RhoConfig.Token, 'Content-type' => 'application/xml'},
      :callback => (url_for :action => :httpput_callback),
      :callback_param => "story_id=#{@params['id']}",
      :ssl_verify_peer => false,
      :http_command => "PUT")
    @story = Story.find(@params['id'])
    @story.update_attributes(@params['story']) if @story
    Rho::RhoConfig.current_action = '0'
    redirect :controller => "Settings", :action => :wait
  end

  def httpput_callback
    #WebView.navigate(url_for :action => :show, :query => { :id => Rho::RhoConfig.current_story_id } )
    WebView.navigate(url_for :action => :index )
  end

  # POST /Story/{1}/delete
  def delete
    story_id = Rho::RhoConfig.current_story_id
    projectid = Rho::RhoConfig.current_project_id
    url = "https://www.pivotaltracker.com/services/v3/projects/#{projectid}/stories/#{story_id}"
    Rho::AsyncHttp.post(
      :url => url,
      :headers => {'X-TrackerToken' => Rho::RhoConfig.Token, 'Content-type' => 'application/xml'},
      :callback => (url_for :action => :httpdelete_callback),
      :callback_param => "story_id=#{story_id}",
      :ssl_verify_peer => false,
      :http_command => "DELETE")    
    @story = Story.find(story_id)
    @story.destroy if @story
    Rho::RhoConfig.current_action = '0'
    redirect :controller => "Settings", :action => :wait
  end

  def httpdelete_callback
   WebView.navigate(url_for :action => :index )
  end

  def load_tab
    create_tabbar
    redirect :action=>:index
  end

  def create_tabbar
    ::NativeBar.create(Rho::RhoApplication::NOBAR_TYPE, [])
    tabs = [
      { :label => "Current", :action => url_for(:action => :get_stories, :query => { :projectid => @params["projectid"], :iteration => "current" } ) , :icon => "/public/images/tabs/current_btn.png", :reload => false},
      { :label => "Backlog", :action => url_for(:action => :get_stories, :query => { :projectid => @params["projectid"], :iteration => "backlog" } ), :icon => "/public/images/tabs/backlog_btn.png", :reload => false},
      { :label => "Icebox", :action => url_for(:action => :get_stories, :query => { :projectid => @params["projectid"], :iteration => "icebox" } ), :icon => "/public/images/tabs/icebox_btn.png", :reload => false},
      { :label => "Done", :action => url_for(:action => :get_stories, :query => { :projectid => @params["projectid"], :iteration => "done" } ), :icon => "/public/images/tabs/done_btn.png", :reload => false}]
    ::NativeBar.create(Rho::RhoApplication::TABBAR_TYPE, tabs)
    ::NativeBar.switch_tab(0)
  end
end