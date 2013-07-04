class Inbox < ActiveRecord::Base
  set_table_name :inbox
  set_primary_key :id
  include Openmrs
    
end  
