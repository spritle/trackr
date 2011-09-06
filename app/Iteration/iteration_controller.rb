require 'rho/rhocontroller'
require 'helpers/browser_helper'

class IterationController < Rho::RhoController
  include BrowserHelper

  #GET /Iteration
  def index
    @iterations = Iteration.find(:all)
    render
  end

  # GET /Iteration/{1}
  def show
    @iteration = Iteration.find(@params['id'])
    if @iteration
      render :action => :show
    else
      redirect :action => :index
    end
  end

  # GET /Iteration/new
  def new
    @iteration = Iteration.new
    render :action => :new
  end

  # GET /Iteration/{1}/edit
  def edit
    @iteration = Iteration.find(@params['id'])
    if @iteration
      render :action => :edit
    else
      redirect :action => :index
    end
  end

  # POST /Iteration/create
  def create
    @iteration = Iteration.new(@params['iteration'])
    @iteration.save
    redirect :action => :index
  end

  # POST /Iteration/{1}/update
  def update
    @iteration = Iteration.find(@params['id'])
    @iteration.update_attributes(@params['iteration']) if @iteration
    redirect :action => :index
  end

  # POST /Iteration/{1}/delete
  def delete
    @iteration = Iteration.find(@params['id'])
    @iteration.destroy if @iteration
    redirect :action => :index
  end
end
