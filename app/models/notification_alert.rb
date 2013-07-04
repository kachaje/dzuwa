class NotificationAlert < ActiveRecord::Base
  include Openmrs
     
  set_table_name "notification_alert"
  
  has_one :user, :through => :notification_alert_recipient, :foreign_key => :user_id
  
  set_primary_key "alert_id"
  
  def after_create
    @alert_recipient = NotificationAlertRecipient.new()
    
    @alert_recipient.alert_id = self.alert_id
    
    @alert_recipient.user_id = self.user_id
    
    @alert_recipient.save
  end
  
  def after_update
    @alert_recipient = NotificationAlertRecipient.find(:all, :conditions => ["user_id = ? AND alert_id = ?", self.user_id, self.alert_id])
    
    @alert_recipient.update_attributes(:alert_read => self.alert_read)
     
  end
  
end  
