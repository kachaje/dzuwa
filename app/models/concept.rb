class Concept < ActiveRecord::Base
  set_table_name :concept
  set_primary_key :concept_id
  include Openmrs
   
  belongs_to :concept_class
  belongs_to :concept_datatype
  has_many :concept_answers do
    def limit(search_string)
      return self if search_string.blank?
      map{|concept_answer|
        concept_answer if concept_answer.name.match(search_string)
      }.compact
    end
  end

  has_many :concept_names
  has_one :name, :class_name => 'ConceptName'
  has_one :descript, :class_name => 'ConceptDescription'
  has_many :sets, :class_name => 'ConceptSet'   #, :foreign_key => 'concept_id'
  
  def before_create
    super
    @uuid = Concept.find_by_sql("SELECT UUID() uuid").first.uuid
    
    self.uuid = @uuid if !self.uuid?
  end
  
end
