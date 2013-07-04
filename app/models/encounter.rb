class Encounter < ActiveRecord::Base
  set_table_name :encounter
  set_primary_key :encounter_id
  include Openmrs
   
  has_many :observations, :dependent => :destroy, :foreign_key => "encounter_id"
  belongs_to :type, :class_name => "EncounterType", :foreign_key => :encounter_type
  belongs_to :provider, :class_name => "User", :foreign_key => :provider_id
  belongs_to :patient
  belongs_to :location

  def before_create
    super
    @uuid = Concept.find_by_sql("SELECT UUID() uuid").first.uuid
    
    self.uuid = @uuid if !self.uuid?
  end
  
  def before_save    
    self.encounter_datetime = Time.now if self.encounter_datetime.blank?
    self.provider = User.current_user if self.provider.blank?
  end

  def encounter_type_name=(encounter_type_name)
    self.type = EncounterType.find_by_name(encounter_type_name)
    raise "#{encounter_type_name} not a valid encounter_type" if self.type.nil?
  end

  def name
    self.type.name rescue "N/A"
  end

  def to_s
    self.name + ": " + self.observations.collect{|observation| observation.to_s}.join("\n")
  end

  def self.count_by_type_for_date(date)  
    ActiveRecord::Base.connection.select_all("SELECT count(*) as number, encounter_type FROM encounter GROUP BY encounter_type")
    todays_encounters = Encounter.find(:all, :include => "type", :conditions => ["DATE(encounter_datetime) = ?",date])
    encounters_by_type = Hash.new(0)
    todays_encounters.each{|encounter|
      next if encounter.type.nil?
      encounters_by_type[encounter.type.name] += 1
    }
    encounters_by_type
  end

  def checklist_complete
    @enc_id = Observation.find(:first, :conditions => ["concept_id = 141 AND value_numeric = ?", self.encounter_id]).encounter_id rescue nil
    
    if @enc_id.nil?
        return false
    end
    
    @obs = Observation.find(:all, :conditions => ["concept_id IN (86, 87, 89, 142, 92, 95, 96, 98, 100, 101, 102, 104, 105, 109, 145, 117) AND encounter_id = ?", @enc_id])
    
    if @obs.length == 0
        return false
    end
    
    @arr = Array.new
    
    @obs.each{|o|
        case o.concept_id
            when 86
            
                if o.value_datetime.nil?
                    return false
                end
                
                @arr.push(o.concept_id)
                
                
            when 87
            
                if o.value_text.nil?
                    return false
                end
                
                if o.value_text.strip.length == 0
                    return false
                end
                
                @arr.push(o.concept_id)
                
                
            when 89
            
                if o.value_text.nil?
                    return false
                end
                
                if o.value_text.strip.length == 0
                    return false
                end
                
                @arr.push(o.concept_id)
                
                
            when 142
            
                if o.value_text.nil?
                    return false
                end
                
                if o.value_text.strip.length == 0
                    return false
                end
                
                @arr.push(o.concept_id)
                
                
            when 92
            
                if o.value_text.nil?
                    return false
                end
                
                if o.value_text.strip.length == 0
                    return false
                end
                
                @arr.push(o.concept_id)
                                
                
            when 95
            
                if o.value_boolean.nil?
                    return false
                end
                
                @arr.push(o.concept_id)
                
                
            when 96
            
                if o.value_text.nil?
                    return false
                end
                
                if o.value_text.strip.length == 0
                    return false
                end
                
                @arr.push(o.concept_id)
                
                
            when 98
            
                if o.value_text.nil?
                    return false
                end
                
                if o.value_text.strip.length == 0
                    return false
                end
                
                @arr.push(o.concept_id)
                
                
            when 100
            
                if o.value_text.nil?
                    return false
                end
                
                if o.value_text.strip.length == 0
                    return false
                end
                
                @arr.push(o.concept_id)
                
                
            when 101
            
                if o.value_datetime.nil?
                    return false
                end
                
                @arr.push(o.concept_id)
                
                
            when 102
            
                if o.value_datetime.nil?
                    return false
                end
                
                @arr.push(o.concept_id)
                
                
            when 104
            
                if o.value_text.nil?
                    return false
                end
                
                if o.value_text.strip.length == 0
                    return false
                end
                
                @arr.push(o.concept_id)
                
                
            when 105
            
                if o.value_text.nil?
                    return false
                end
                
                if o.value_text.strip.length == 0
                    return false
                end
                
                @arr.push(o.concept_id)
                
                
            when 109
            
                if o.value_text.nil?
                    return false
                end
                
                if o.value_text.strip.length == 0
                    return false
                end
                
                @arr.push(o.concept_id)
                
                 
            when 144
            
                if o.value_boolean.nil?
                    return false
                end
                
                @arr.push(o.concept_id)
                
                  
            when 145
            
                if o.value_boolean.nil?
                    return false
                end
                
                @arr.push(o.concept_id)
                
                
            when 117
            
                if o.value_text.nil?
                    return false
                end
                
                if o.value_text.strip.length == 0
                    return false
                end
                
                @arr.push(o.concept_id)
                
                
        end
        
    }
    return true
  end
end
