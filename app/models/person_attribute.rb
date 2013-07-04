class PersonAttribute < ActiveRecord::Base
  include Openmrs
     
  set_table_name "person_attribute"
  set_primary_key "person_attribute_id"
  
  belongs_to :person, :foreign_key => :person_id
  belongs_to :attribute_type, :class_name => "PatientAttributeType", :foreign_key => :person_attribute_type_id
   
end
