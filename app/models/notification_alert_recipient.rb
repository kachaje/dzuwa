class NotificationAlertRecipient < ActiveRecord::Base
  include Openmrs
    
  set_table_name "notification_alert_recipient"
  
  belongs_to :user, :foreign_key => :user_id
  belongs_to :notification_alert, :foreign_key => :alert_id
  
  set_primary_keys :alert_id, :user_id
  
end  
