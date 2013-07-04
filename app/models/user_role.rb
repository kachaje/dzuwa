# require "rubygems"
require "composite_primary_keys"
class UserRole < ActiveRecord::Base
  include Openmrs   
  
  set_table_name "user_role"
  belongs_to :roles, :class_name => "Role", :foreign_key => "role"
  belongs_to :user, :foreign_key => :user_id
  set_primary_keys :role, :user_id
end


### Original SQL Definition for user_role #### 
#   `user_id` int(11) NOT NULL default '0',
#   `role` varchar(50) NOT NULL default '',
#   PRIMARY KEY  (`role`,`user_id`),
#   KEY `user_role` (`user_id`),
#   CONSTRAINT `role_definitions` FOREIGN KEY (`role`) REFERENCES `role` (`role`),
#   CONSTRAINT `user_role` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`)
