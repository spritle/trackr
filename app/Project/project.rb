# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
class Project
  include Rhom::PropertyBag
  set :source_id,1
  # Uncomment the following line to enable sync with Project.
  # enable :sync

  #add model specifc code here
end
