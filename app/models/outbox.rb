class Outbox < ActiveRecord::Base
  set_table_name :outbox
  set_primary_key :id
  include Openmrs
     
end  
