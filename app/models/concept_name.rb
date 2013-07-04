class ConceptName < ActiveRecord::Base
  set_table_name :concept_name
  set_primary_key :concept_name_id
  include Openmrs
   
  belongs_to :concept
  
  def before_create
    super
    @uuid = Concept.find_by_sql("SELECT UUID() uuid").first.uuid
    
    self.uuid = @uuid if !self.uuid?
  end
  
end

