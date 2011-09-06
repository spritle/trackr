# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
class Story
  include Rhom::PropertyBag
  set :source_id,2
  # Uncomment the following line to enable sync with Story.
  # enable :sync

  #add model specifc code here
end
