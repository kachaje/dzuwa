class ConceptSet < ActiveRecord::Base
  set_table_name :concept_set
  set_primary_keys :concept_id, :concept_set
  include Openmrs
     
  #belongs_to :set, :class_name => 'Concept', :foreign_key => 'concept_set'
  belongs_to :concept
  #has_many :concepts
  
  def before_create
    super
    @uuid = Concept.find_by_sql("SELECT UUID() uuid").first.uuid
    
    self.uuid = @uuid if !self.uuid?
  end
  
end
