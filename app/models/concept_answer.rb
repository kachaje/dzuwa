class ConceptAnswer < ActiveRecord::Base
  set_table_name :concept_answer
  set_primary_key :concept_answer_id
  include Openmrs
   
  belongs_to :answer, :class_name => 'Concept', :foreign_key => 'answer_concept'
  belongs_to :drug, :class_name => 'Drug', :foreign_key => 'answer_drug'
  belongs_to :concept

  def name
    self.answer.name.name
  end
  
  def before_create
    super
    @uuid = Concept.find_by_sql("SELECT UUID() uuid").first.uuid
    
    self.uuid = @uuid if !self.uuid?
  end
  
end
