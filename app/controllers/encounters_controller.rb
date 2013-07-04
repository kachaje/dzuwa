class EncountersController < ApplicationController
    helper :application
    include ApplicationHelper

    def appointment
    
        if params[:viewer]
            if params[:viewer] == "false"
                @viewer = "none"
            else
                @viewer = "block"
            end
        end
        
        if params[:list_type]
            if params[:list_type] == "list"
                @list_type = "list"
            elsif params[:list_type] == "booking"
                @list_type = "booking"
            end
        else
            @list_type = "booking"
        end
        
        @patients = PersonName.find(:all, :conditions => ["preferred <> ?", 1], :order => "person_name.family_name")
        
        if Location.current_location
            @loc = Location.current_location.location_id
        elsif params[:selectId]
            session[:location_id] = Location.find(params[:selectId]).parent_location
            @loc = params[:selectId]
        end
        
        @parent = session[:location_id]
        
        @ward_arr = Array.new
        
        @ward_arr.push(" ")
        
        Location.find(:all, :conditions => ["UPPER(description) LIKE ? AND parent_location = ?","%WARD%", session[:location_id]]).each{|p| @ward_arr.push(p.name)} 

        @locations = Location.find(:all, :conditions => ["COALESCE(parent_location,'') = ? AND NOT UPPER(description) LIKE ?", session[:location_id],"%WARD%"], :order => "name")
        
        @surgeons = PersonName.find(:all, :include => [{:person => [{:user => [:user_roles]}]}], :conditions => ["user_role.role = ?", "Surgeon"])
        
        @interns = PersonName.find(:all, :include => [{:person => [{:user => [:user_roles]}]}], :conditions => ["user_role.role = ?", "Intern"])
        
        @anaesthetists = PersonName.find(:all, :include => [{:person => [{:user => [:user_roles]}]}], :conditions => ["user_role.role = ?", "Anaesthetist"])
        
        if params[:encounter_id]
            @var = params[:encounter_id].scan(/(\d+)\,(\w+)\,(\d+)\,(\d+)/)            
            
            if @var
                @year = $1
                @mon = $2
                @day = $3
                @hr = $4
                
                @date = Time.utc(@year, @mon, @day, @hr)
            end
        end
        
        @theatre = ""
        
        if @list_type == "list"
            @date = Date.today.strftime("%Y-%m-%d")
        else
            @date = Date.tomorrow.strftime("%Y-%m-%d")
        end
        
        @start = "07:30"
        
        if !(params[:theatre] rescue nil).nil?
            @theatre = params[:theatre]
        end
            
        if params[:app]
        
            #if params[:location] # .strip.length > 0
                
                @theatre_id = Location.find(:first, :conditions => ["parent_location = ? AND UPPER(name) = ?",session[:location_id], params[:theatre].strip.upcase]).location_id
                
                d = params[:app][:date].strip.match(/^(\d{4})-(\d{2})-(\d{2})$/)
                
                @date = Time.utc($1, $2, $3).strftime("%Y-%m-%d")
                
                @encounters = Encounter.find(:all, :conditions => ["location_id = ? AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') = ? AND encounter_type = ?", @theatre_id, @date, 5])
                
            #else
            
                #@theatre_id = Location.find(:first, :conditions => ["parent_location = ? AND NOT UPPER(description) LIKE ?", session[:location_id], "%WARD%"], :order => "name").location_id
                
                #@date = Time.now.strftime("%Y-%m-%d")
                
                #@encounters = Encounter.find(:all, :conditions => ["location_id = ? AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') = ? AND encounter_type = ?", @theatre_id, @date, 5])
                
            #end
        
            if params[:app][:date]
               @date = params[:app][:date]
            end
            
            @su = Observation.find(:first, :conditions => ["concept_id = ? AND encounter_id = ?", 71, @encounters.first.encounter_id]).value_numeric.to_i rescue nil
            
            @in = Observation.find(:first, :conditions => ["concept_id = ? AND encounter_id = ?", 72, @encounters.first.encounter_id]).value_numeric.to_i rescue nil
              
            @start = Observation.find(:first, :conditions => ["concept_id = ? AND encounter_id = ?", 70, @encounters.first.encounter_id]).value_datetime.strftime("%H:%M") rescue "08:00"
               
            if @su
                p = PersonName.find(:first, :conditions => ["person_id = ?", @su])
                if p
                    @surg = "#{p.prefix rescue ""} #{p.given_name rescue ""} #{p.family_name rescue ""} (#{p.person.user.system_id rescue ""})"
                else
                    @surg = ""
                end
            else
                 @surg = ""
            end
            
            if @in
                p = PersonName.find(:first, :conditions => ["person_id = ?",@in])
                if p
                    @inter = "#{p.prefix rescue ""} #{p.given_name rescue ""} #{p.family_name rescue ""} (#{p.person.user.system_id rescue ""})"
                else
                    @inter = ""
                end
            else
                @inter = ""
            end
        else
            
                @theatre_id = Location.find(:first, :conditions => ["parent_location = ? AND NOT UPPER(description) LIKE ?", session[:location_id], "%WARD%"], :order => "name")
                
                if @list_type == "list"
                    @date = Date.today.strftime("%Y-%m-%d")
                else
                    @date = Date.tomorrow.strftime("%Y-%m-%d")
                end
        
                @encounters = Encounter.find(:all, :conditions => ["location_id = ? AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') = ? AND encounter_type = ?", @theatre_id.location_id, @date, 5])
                
                if params[:location]
                    @theatre = params[:location][:location_id]
                else
                    @theatre = @theatre_id.name
                end
                
                @su = Observation.find(:first, :conditions => ["concept_id = ? AND encounter_id = ?", 71, @encounters.first.encounter_id]).value_numeric.to_i rescue nil
                
                @in = Observation.find(:first, :conditions => ["concept_id = ? AND encounter_id = ?", 72, @encounters.first.encounter_id]).value_numeric.to_i rescue nil
               
                @start = "08:00"
               
                if @su
                    p = PersonName.find(:first, :conditions => ["person_id = ?", @su])
                    @surg = "#{p.prefix} #{p.given_name} #{p.family_name} (#{p.person.user.system_id})" rescue ""
                else
                     @surg = ""
                end
                
                if @in
                    p = PersonName.find(:first, :conditions => ["person_id = ?",@in])
                    @inter = "#{p.prefix} #{p.given_name} #{p.family_name} (#{p.person.user.system_id})" rescue ""
                else
                    @inter = ""
                end
        end
        
        @theatreId = @encounters.first.location_id rescue 0
    end

    def transferpatient
        @loc = params[:loc_id] rescue ""
        @enc = params[:encounter_id] rescue ""
        
        @encounter = Encounter.find(@enc)
        
        if @encounter.update_attributes(:location_id => @loc)
            @obs = Observation.find(:all, :conditions => ["encounter_id = ?", @enc])
            
            @obs.each{|o|
                o.update_attributes(:location_id => @loc)
            }
        end
        redirect_to :action => "appointment"
    end

    def make_appointment
        @fields = {}
        
        @name = params[:name].split(" ")
        
        if params[:ward].strip.length == 0
	        @fields["ward"] = 1
	    else
	        @fields["ward"] = Location.find(:first, :conditions => ["parent_location = ? AND UPPER(name) = ?",session[:location_id], params[:ward].strip.upcase]).location_id
	    end
	    
	    @fields["procedure"] = ConceptName.find(:first, :conditions => ["UPPER(name) = ?", params[:procedure].upcase]).concept_id rescue nil
	    
	    @fields["gaorla"] = params[:gaorla] rescue nil
        @fields["blood"] = params[:blood] rescue nil
        @fields["itu"] = ((params[:itu] == "true") ? 1 : 0) rescue nil
        @fields["comment"] = params[:comment] rescue nil
        @fields["chklist"] = ((params[:chklist] == "true") ? 1 : 0) rescue nil
        @fields["ocd"] = params[:ocd] rescue nil
        @fields["ocd2"] = params[:ocd2] rescue nil
        @fields["date"] = params[:date] rescue nil
        @fields["start"] = ((params[:start].strip.length > 0) ? (params[:start]) : "8:00")
        
        if params[:theatre].strip.length == 0
	        @theatre = 1
	    else
	        @theatre = Location.find(:first, :conditions => ["parent_location = ? AND UPPER(name) = ?",session[:location_id], params[:theatre].strip.upcase]).location_id
	    end
	    
	    if params[:surg].strip.length > 0
	        @surg = params[:surg].match(/(\w{2}-\d+|\w{1}-\d+)/)
	        
	        if @surg
                
                @fields["surg"] = PersonName.find(:first, :include => [{:person => [:user]}], :conditions => ["preferred = ? AND UPPER(users.system_id) = ?",1, $1]).person_id
            
            else
            
                @fields["surg"] = nil
                
            end
        else
            @fields["surg"] = nil
        end
        
	    if params[:intern].strip.length > 0
	        @intern = params[:intern].match(/\((\w{2}-\d+)\)/)
	        
	        if @intern
                
                @fields["intern"] = PersonName.find(:first, :include => [{:person => [:user]}], :conditions => ["preferred = ? AND UPPER(users.system_id) = ?",1, $1]).person_id
            
            else
            
                @fields["intern"] = nil
                
            end
        else
            @fields["intern"] = nil
        end
        
        # @fields["intern"] = params[:intern] rescue nil
        
        @encounter_id = params[:encounter_id] rescue nil
        @identifier = params[:identifier].strip
        
        if @encounter_id.strip.length > 0
        
            @person = Person.find(:first, :include => [{:patient => [:patient_identifiers]}], :conditions => ["patient_identifier.identifier = ?",@identifier]).person_id
            
            @encounter = Encounter.find(@encounter_id.strip)
                                   
            @encounter.update_attributes(:patient_id => @person, :location_id => @theatre)
            
            @encounter_id = @encounter.encounter_id
        
            @fields.each{|p|
            
                case p[0]
                
                    when "ward" 
                        @concept_id = ConceptName.find(:first, :conditions => ["UPPER(name) = ?", "WARD"]).concept_id
                          
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_numeric => p[1])
                        
                    when "procedure"     
                                                                    
                        @concept_id = ConceptName.find(:first, :conditions => ["UPPER(name) = ?", "PLANNED PROCEDURE"]).concept_id
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_coded => p[1])
                        
                    when "gaorla"
                                                        
                        @concept_id = ConceptName.find(:first, :conditions => ["UPPER(name) = ?", "GA OR LA"]).concept_id
                         
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_text => p[1])
                        
                    when "blood"
                                                        
                        @concept_id = ConceptName.find(:first, :conditions => ["UPPER(name) = ?", "BLOOD QUANTITY REQUIRED"]).concept_id
                         
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_numeric => p[1])
                        
                    when "itu"
                                                        
                        @concept_id = ConceptName.find(:first, :conditions => ["UPPER(name) = ?", "ITU BED BOOKED"]).concept_id
                         
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_boolean => ((p[1]=="true")?1:0))
                        
                    when "comment"
                                                        
                        @concept_id = ConceptName.find(:first, :conditions => ["UPPER(name) = ?", "COMMENTS"]).concept_id
                         
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_text => p[1])
                        
                    when "chklist"
                                                        
                        @concept_id = ConceptName.find(:first, :conditions => ["UPPER(name) = ?", "CHECKLIST COMPLETE"]).concept_id
                         
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_boolean => ((p[1]=="true")?1:0))
                        
                    when "ocd"
                                                        
                        @concept_id = ConceptName.find(:first, :conditions => ["UPPER(name) = ?", "OUTCOME CODE"]).concept_id
                         
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_text => p[1])
                        
                    when "ocd2"
                                                        
                        @concept_id = ConceptName.find(:first, :conditions => ["UPPER(name) = ?", "OUTCOME CODE CODE"]).concept_id
                         
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_numeric => p[1])
                        
                    when "date"
                                                        
                        @concept_id = ConceptName.find(:first, :conditions => ["UPPER(name) = ?", "APPOINTMENT DATE"]).concept_id
                         
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_datetime => p[1])
                        
                    when "start"
                                                        
                        @concept_id = ConceptName.find(:first, :conditions => ["UPPER(name) = ?", "PLANNED START TIME"]).concept_id
                         
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_datetime => p[1])
                        
                    when "surg"
                                                        
                        @concept_id = ConceptName.find(:first, :conditions => ["UPPER(name) = ?", "SURGEON"]).concept_id
                         
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_numeric => p[1])
                        
                    when "intern"
                                                    
                        @concept_id = ConceptName.find(:first, :conditions => ["UPPER(name) = ?", "INTERN"]).concept_id
                         
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_numeric => p[1])
                        
                end
                            
            }
                 
        else
        
            @person_id = Person.find(:first, :include => [{:patient => [:patient_identifiers]}], :conditions => ["patient_identifier.identifier = ?",@identifier]).person_id

            @encounter = Encounter.new(:encounter_type => 5, :patient_id => @person_id, :provider_id => session[:user_id], :location_id => @theatre, :encounter_datetime =>  @fields["date"], :creator => session[:user_id], :date_created => DateTime.now)
            
            if @encounter.save
                @encounter_id = @encounter.encounter_id;
                
                @fields.each{|p|
                    @obs = Observation.new()
                    case p[0]
                    
                        when "ward"   
                                                 
                            @obs.concept_id = ConceptName.find(:first, :conditions => ["UPPER(name) = ?", "WARD"]).concept_id
                            
                            @obs.value_numeric = p[1]
                            
                        when "procedure"     
                                                                        
                            @obs.concept_id = ConceptName.find(:first, :conditions => ["UPPER(name) = ?", "PLANNED PROCEDURE"]).concept_id
                            
                            @obs.value_coded = p[1]
                            
                        when "gaorla"
                                                            
                            @obs.concept_id = ConceptName.find(:first, :conditions => ["UPPER(name) = ?", "GA OR LA"]).concept_id
                            
                            @obs.value_text = p[1]
                            
                        when "blood"
                                                            
                            @obs.concept_id = ConceptName.find(:first, :conditions => ["UPPER(name) = ?", "BLOOD QUANTITY REQUIRED"]).concept_id
                            
                            @obs.value_numeric = p[1]
                            
                        when "itu"
                                                            
                            @obs.concept_id = ConceptName.find(:first, :conditions => ["UPPER(name) = ?", "ITU BED BOOKED"]).concept_id
                            
                            @obs.value_boolean = p[1]
                            
                        when "comment"
                                                            
                            @obs.concept_id = ConceptName.find(:first, :conditions => ["UPPER(name) = ?", "COMMENTS"]).concept_id
                            
                            @obs.value_text = p[1]
                            
                        when "chklist"
                                                            
                            @obs.concept_id = ConceptName.find(:first, :conditions => ["UPPER(name) = ?", "CHECKLIST COMPLETE"]).concept_id
                            
                            @obs.value_boolean = p[1]
                            
                        when "ocd"
                                                            
                            @obs.concept_id = ConceptName.find(:first, :conditions => ["UPPER(name) = ?", "OUTCOME CODE"]).concept_id
                            
                            @obs.value_text = p[1]
                            
                        when "ocd2"
                                                            
                            @obs.concept_id = ConceptName.find(:first, :conditions => ["UPPER(name) = ?", "OUTCOME CODE CODE"]).concept_id
                            
                            @obs.value_numeric = p[1]
                            
                        when "date"
                                                            
                            @obs.concept_id = ConceptName.find(:first, :conditions => ["UPPER(name) = ?", "APPOINTMENT DATE"]).concept_id
                            
                            @obs.value_datetime = p[1]
                            
                        when "start"
                                                            
                            @obs.concept_id = ConceptName.find(:first, :conditions => ["UPPER(name) = ?", "PLANNED START TIME"]).concept_id
                            
                            @obs.value_datetime = p[1]
                            
                        when "surg"
                                                            
                            @obs.concept_id = ConceptName.find(:first, :conditions => ["UPPER(name) = ?", "SURGEON"]).concept_id
                            
                            @obs.value_numeric = p[1]
                            
                        when "intern"
                                                        
                            @obs.concept_id = ConceptName.find(:first, :conditions => ["UPPER(name) = ?", "INTERN"]).concept_id
                            
                            @obs.value_numeric = p[1]
                            
                    end
                                
                    @obs.patient_id = @person_id
                    @obs.location_id = @theatre
                    @uuid = Observation.find_by_sql("SELECT UUID() uuid").first            
                    @obs.uuid = @uuid.uuid
                    @obs.obs_datetime = Date.today.strftime("%Y-%m-%d")
                    @obs.encounter_id = @encounter_id
                    
                    @obs.save
                } 
            end
            
        end
        
        render :text => @encounter_id;
    end
    
    def show    
        if params[:viewer]
            if params[:viewer] == "false"
                @viewer = "none"
            else
                @viewer = "block"
            end
        end
        
        if session[:patient_id]
            @patient = Patient.find(session[:patient_id], :include => [{:encounters => [:type]}])
        elsif params[:selectId]
            @patient = Patient.find(params[:selectId], :include => [{:encounters => [:type]}])   
        elsif params[:encounter_id]
            @patient = Patient.find(:all, :include => [{:encounters => [:type]}], :conditions => ["encounter.encounter_id = ?", params[:encounter_id]]).first
        else
            flash[:notice] = "No records found"
            redirect_to(:controller => "patients", :action => "index")
        end                        
    end
    
    def cancelled_appointments
    
        @patient = Patient.find(session[:patient_id], :include => [{:encounters => [:type]}], :conditions => ["encounter_type.name = ? AND encounter.voided = ?", "APPOINTMENT", 1]) rescue nil

    end 
    
    def theatre_list_pdf
        @pdf_theatre = params[:pdf_theatre]
        @pdf_date = params[:pdf_date]
        @pdf_parent = params[:pdf_parent]
        
        response = Encounter.find(:all, :include => [:location], :conditions => ["UPPER(location.name) = ? AND location.parent_location = ? AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') = ?", @pdf_theatre.upcase, @pdf_parent, @pdf_date])
        
        if response.length > 0
        
            pdf = TheatreList.render_pdf(:paper_orientation => :landscape, :theatre => @pdf_theatre, :date => @pdf_date, :parent => @pdf_parent)

            send_data pdf, :type => "application/pdf", :filename => "theatrelist_#{@pdf_theatre.downcase.gsub("-","_").gsub(" ","_")}_#{@pdf_date.gsub("-","_")}.pdf" 
        
        end
    end 
    
    def theatre_list_csv
        @pdf_theatre = params[:pdf_theatre]
        @pdf_date = params[:pdf_date]
        @pdf_parent = params[:pdf_parent]
        
        response = Encounter.find(:all, :include => [:location], :conditions => ["UPPER(location.name) = ? AND location.parent_location = ? AND DATE_FORMAT(encounter_datetime, '%Y-%m-%d') = ?", @pdf_theatre.upcase, @pdf_parent, @pdf_date])
        
        if response.length > 0
        
            csv = TheatreList.render_csv( :theatre => @pdf_theatre, :date => @pdf_date, :parent => @pdf_parent)

            send_data csv, :type => "application/csv", :filename => "theatrelist_#{@pdf_theatre.downcase.gsub("-","_").gsub(" ","_")}_#{@pdf_date.gsub("-","_")}.csv" 
        
        end
    end 
    
    def checklist
        if params[:encounter_id]
            @enc = Encounter.find(params[:encounter_id]) rescue nil
            
            if @enc
            
                @name = @enc.patient.person.name
                
                @age =  (Date.today - @enc.patient.person.birthdate).to_i / 365
     
                @id = @enc.patient.patient_identifiers.first.identifier
                
                @app_encounter_id = params[:encounter_id]
                
                @encounter_id = Observation.find(:all, :conditions => ["concept_id = ? AND value_numeric = ?", 141, @app_encounter_id]).first.encounter_id rescue nil
            
                if @app_encounter_id
                    @loc_id = Encounter.find(@app_encounter_id).location_id
                    
                    @loc = Location.find(@loc_id).name.strip
                    
                    if @loc.strip.length > 13
                        @loc = substr(@loc, 0, 10) + "..."
                    end
                end
            end
            
            if params[:viewer]
                if params[:viewer] == "false"
                    @viewer = "none"
                else
                    @viewer = "block"
                end
            end
        end
    end    
    
    def login
        @user=User.new(:username => params[:username], :password => params[:password])
        logged_in_user=@user.try_to_login
        
        if logged_in_user
            render :text => logged_in_user.system_id
        else
            render :text => ""
        end
    end
    
    def create_chklist_enc
        @fields = {}
        
        @fields["tintime"] = params[:tintime] rescue ""
        @fields["datetaken"] = params[:datetaken] rescue ""
        @fields["hb"] = params[:hb] rescue ""
        @fields["wcc"] = params[:wcc] rescue ""
        @fields["plts"] = params[:plts] rescue ""
        @fields["mps"] = params[:mps] rescue ""
        @fields["other"] = params[:other] rescue ""
        @fields["ts"] = params[:ts] rescue ""
        @fields["units"] = params[:units] rescue ""
        @fields["consent"] = params[:consent] rescue ""
        @fields["site"] = params[:site] rescue ""
        @fields["medic"] = params[:medic] rescue ""
        @fields["allergno"] = params[:allergno] rescue ""
        @fields["adrug"] = params[:adrug] rescue ""
        @fields["intern"] = params[:intern] rescue ""
        @fields["app_encounter_id"] = params[:app_encounter_id] rescue ""
        @fields["ate"] = params[:ate] rescue ""
        @fields["weight"] = params[:weight] rescue ""
        @fields["drank"] = params[:drank] rescue ""
        @fields["hr"] = params[:hr] rescue ""
        @fields["bp"] = params[:bp] rescue ""
        @fields["rr"] = params[:rr] rescue ""
        @fields["spo2"] = params[:spo2] rescue ""
        @fields["nurse"] = params[:nurse] rescue ""
        @fields["risk"] = params[:risk] rescue ""
        @fields["taco"] = params[:taco] rescue ""
        @fields["induction"] = params[:induction] rescue ""
        @fields["prepstart"] = params[:prepstart] rescue ""
        @fields["surg"] = params[:surg] rescue ""
        @fields["surgrev"] = params[:surgrev] rescue ""
        @fields["anaesthrev"] = params[:anaesthrev] rescue ""
        @fields["nurserev"] = params[:nurserev] rescue ""
        @fields["prophy"] = params[:prophy] rescue ""
        @fields["imaging"] = params[:imaging] rescue ""
        @fields["knife"] = params[:knife] rescue ""
        @fields["closure"] = params[:closure] rescue ""
        @fields["proc"] = params[:proc] rescue ""
        @fields["instrument"] = params[:instrument] rescue ""
        @fields["spec"] = params[:spec] rescue ""
        @fields["equipment"] = params[:equipment] rescue ""
        @fields["tout"] = params[:tout] rescue ""
        @fields["surgrecov"] = params[:surgrecov] rescue ""
        @fields["obsrecov"] = params[:obsrecov] rescue ""
        @fields["nbm"] = params[:nbm] rescue ""
        @fields["nextmed"] = params[:nextmed] rescue ""
        @fields["freqobs"] = params[:freqobs] rescue ""
        @fields["score"] = params[:score] rescue ""
        @fields["dest"] = params[:dest] rescue ""
        @fields["recovout"] = params[:recovout] rescue ""
        @fields["child"] = params[:child] rescue ""
        @fields["ivi"] = params[:ivi] rescue ""
        @fields["wrist"] = params[:wrist] rescue ""
        @fields["intro"] = params[:intro] rescue ""
        @fields["team"] = params[:team] rescue ""
        @fields["op"] = params[:op] rescue ""
        @fields["hospno"] = params[:hospno] rescue ""
                
        @enc = Encounter.find(params[:app_encounter_id])
        
        @encounter_id = ""
        
        if @enc
            @person_id = @enc.patient_id
            @theatre = @enc.location_id
            
            @encounter = Encounter.new(:encounter_type => 6, :patient_id => @person_id, :provider_id => session[:user_id], :location_id => @theatre, :encounter_datetime =>  DateTime.now, :creator => session[:user_id], :date_created => DateTime.now)
              
            if @encounter.save
                @encounter_id = @encounter.encounter_id;
                
                @fields.each{|p|
                
                    @obs = Observation.new()
                    case p[0]
                    
                        when "tintime"   
                                                 
                            @obs.concept_id = 85
                            
                            @obs.value_datetime = p[1]
                            
                        when "datetaken"     
                                                                        
                            @obs.concept_id = 86
                            
                            @obs.value_datetime = p[1]
                            
                        when "hb"
                                                            
                            @obs.concept_id = 87
                            
                            @obs.value_text = p[1]
                            
                        when "wcc"
                                                            
                            @obs.concept_id = 88
                            
                            @obs.value_text = p[1]
                            
                        when "plts"
                                                            
                            @obs.concept_id = 89
                            
                            @obs.value_text = p[1]
                            
                        when "mps"
                                                            
                            @obs.concept_id = 90
                            
                            @obs.value_text = p[1]
                            
                        when "other"
                                                            
                            @obs.concept_id = 91
                            
                            @obs.value_text = p[1]
                            
                        when "ts"
                                                            
                            @obs.concept_id = 92
                            
                            @obs.value_text = p[1]
                            
                        when "units"
                                                            
                            @obs.concept_id = 94
                            
                            @obs.value_numeric = p[1]
                              
                        when "consent"
                                                            
                            @obs.concept_id = 95
                            
                            @obs.value_boolean = p[1]
                            
                        when "site"
                                                            
                            @obs.concept_id = 96
                            
                            @obs.value_text = p[1]
                            
                        when "medic"
                                                            
                            @obs.concept_id = 97
                            
                            @obs.value_text = p[1]
                            
                        when "allergno"
                                                            
                            @obs.concept_id = 98
                            
                            @obs.value_text = p[1]
                            
                        when "adrug"
                                                            
                            @obs.concept_id = 99
                            
                            @obs.value_text = p[1]
                            
                        when "intern"
                                                        
                            @obs.concept_id = 100
                            
                            @obs.value_text = p[1]
                                 
                        when "ate"
                                                        
                            @obs.concept_id = 101
                            
                            @obs.value_datetime = p[1]
                                 
                        when "drank"
                                                        
                            @obs.concept_id = 102
                            
                            @obs.value_datetime = p[1]
                               
                        when "weight"
                                                        
                            @obs.concept_id = 103
                            
                            @obs.value_text = p[1]
                                   
                        when "hr"
                                                        
                            @obs.concept_id = 104
                            
                            @obs.value_text = p[1]
                                 
                        when "bp"
                                                        
                            @obs.concept_id = 105
                            
                            @obs.value_text = p[1]
                                 
                        when "rr"
                                                        
                            @obs.concept_id = 106
                            
                            @obs.value_text = p[1]
                                 
                        when "spo2"
                                                        
                            @obs.concept_id = 107
                            
                            @obs.value_text = p[1]
                                 
                        when "nurse"
                                                        
                            @obs.concept_id = 108
                            
                            @obs.value_text = p[1]
                                 
                        when "risk"
                                                        
                            @obs.concept_id = 109
                            
                            @obs.value_text = p[1]
                                 
                        when "taco"
                                                        
                            @obs.concept_id = 110
                            
                            @obs.value_text = p[1]
                                 
                        when "induction"
                                                        
                            @obs.concept_id = 111
                            
                            @obs.value_datetime = p[1]
                                 
                        when "prepstart"
                                                        
                            @obs.concept_id = 112
                            
                            @obs.value_datetime = p[1]
                                 
                        when "surg"
                                                        
                            @obs.concept_id = 113
                            
                            @obs.value_boolean = p[1]
                                 
                        when "surgrev"
                                                        
                            @obs.concept_id = 114
                            
                            @obs.value_boolean = p[1]
                                 
                        when "anaesthrev"
                                                        
                            @obs.concept_id = 115
                            
                            @obs.value_boolean = p[1]
                                 
                        when "nurserev"
                                                        
                            @obs.concept_id = 116
                            
                            @obs.value_boolean = p[1]
                                 
                        when "prophy"
                                                        
                            @obs.concept_id = 117
                            
                            @obs.value_text = p[1]
                                 
                        when "imaging"
                                                        
                            @obs.concept_id = 118
                            
                            @obs.value_text = p[1]
                                 
                        when "knife"
                                                        
                            @obs.concept_id = 119
                            
                            @obs.value_datetime = p[1]
                                 
                        when "closure"
                                                        
                            @obs.concept_id = 120
                            
                            @obs.value_datetime = p[1]
                                
                        when "proc"
                                                        
                            @obs.concept_id = 121
                            
                            @obs.value_boolean = p[1]
                                 
                        when "instrument"
                                                        
                            @obs.concept_id = 122
                            
                            @obs.value_boolean = p[1]
                                 
                        when "spec"
                                                        
                            @obs.concept_id = 123
                            
                            @obs.value_boolean = p[1]
                                 
                        when "equipment"
                                                        
                            @obs.concept_id = 124
                            
                            @obs.value_boolean = p[1]
                                 
                        when "tout"
                                                        
                            @obs.concept_id = 125
                            
                            @obs.value_datetime = p[1]
                                 
                        when "surgrecov"
                                                        
                            @obs.concept_id = 126
                            
                            @obs.value_boolean = p[1]
                                 
                        when "obsrecov"
                                                        
                            @obs.concept_id = 127
                            
                            @obs.value_boolean = p[1]
                                 
                        when "nbm"
                                                        
                            @obs.concept_id = 128
                            
                            @obs.value_datetime = p[1]
                                 
                        when "nextmed"
                                                        
                            @obs.concept_id = 129
                            
                            @obs.value_datetime = p[1]
                                 
                        when "freqobs"
                                                        
                            @obs.concept_id = 130
                            
                            @obs.value_text = p[1]
                                 
                        when "score"
                                                        
                            @obs.concept_id = 131
                            
                            @obs.value_text = p[1]
                                 
                        when "dest"
                                                        
                            @obs.concept_id = 132
                            
                            @obs.value_text = p[1]
                                 
                        when "recovout"
                                                        
                            @obs.concept_id = 133
                            
                            @obs.value_datetime = p[1]
                            
                        when "app_encounter_id"
                                                        
                            @obs.concept_id = 141
                            
                            @obs.value_numeric = p[1]
                            
                        when "child"
                                                        
                            @obs.concept_id = 142
                            
                            @obs.value_text = p[1]
                            
                        when "ivi"
                                                        
                            @obs.concept_id = 143
                            
                            @obs.value_text = p[1]
                            
                        when "wrist"
                                                        
                            @obs.concept_id = 144
                            
                            @obs.value_boolean = p[1]
                            
                        when "intro"
                                                        
                            @obs.concept_id = 145
                            
                            @obs.value_boolean = p[1]
                            
                        when "team"
                                                        
                            @obs.concept_id = 146
                            
                            @obs.value_boolean = p[1]
                            
                        when "op"
                                                        
                            @obs.concept_id = 147
                            
                            @obs.value_boolean = p[1]
                              
                        when "hospno"
                                                        
                            @obs.concept_id = 148
                            
                            @obs.value_text = p[1]
                            
                    end
                                
                    @obs.patient_id = @person_id
                    @obs.location_id = @theatre
                    @uuid = Observation.find_by_sql("SELECT UUID() uuid").first            
                    @obs.uuid = @uuid.uuid
                    @obs.obs_datetime = Date.today.strftime("%Y-%m-%d")
                    @obs.encounter_id = @encounter_id
                    
                    @obs.save
                    
                } 
            end
        end    
        
        render :text => @encounter_id rescue "";
        
    end
    
    def save_chklist_surgicals
        @fields = {}
        
        @fields["tintime"] = params[:tintime] rescue ""
        @fields["datetaken"] = params[:datetaken] rescue ""
        @fields["hb"] = params[:hb] rescue ""
        @fields["wcc"] = params[:wcc] rescue ""
        @fields["plts"] = params[:plts] rescue ""
        @fields["mps"] = params[:mps] rescue ""
        @fields["other"] = params[:other] rescue ""
        @fields["ts"] = params[:ts] rescue ""
        @fields["units"] = params[:units] rescue ""
        @fields["consent"] = params[:consent] rescue ""
        @fields["site"] = params[:site] rescue ""
        @fields["medic"] = params[:medic] rescue ""
        @fields["allergno"] = params[:allergno] rescue ""
        @fields["adrug"] = params[:adrug] rescue ""
        @fields["intern"] = params[:intern] rescue ""
        @fields["app_encounter_id"] = params[:app_encounter_id] rescue ""
        @fields["ate"] = params[:ate] rescue ""
        @fields["weight"] = params[:weight] rescue ""
        @fields["drank"] = params[:drank] rescue ""
        @fields["hr"] = params[:hr] rescue ""
        @fields["bp"] = params[:bp] rescue ""
        @fields["rr"] = params[:rr] rescue ""
        @fields["spo2"] = params[:spo2] rescue ""
        @fields["nurse"] = params[:nurse] rescue ""
        @fields["risk"] = params[:risk] rescue ""
        @fields["taco"] = params[:taco] rescue ""
        @fields["induction"] = params[:induction] rescue ""
        @fields["prepstart"] = params[:prepstart] rescue ""
        @fields["surg"] = params[:surg] rescue ""
        @fields["surgrev"] = params[:surgrev] rescue ""
        @fields["anaesthrev"] = params[:anaesthrev] rescue ""
        @fields["nurserev"] = params[:nurserev] rescue ""
        @fields["prophy"] = params[:prophy] rescue ""
        @fields["imaging"] = params[:imaging] rescue ""
        @fields["knife"] = params[:knife] rescue ""
        @fields["closure"] = params[:closure] rescue ""
        @fields["proc"] = params[:proc] rescue ""
        @fields["instrument"] = params[:instrument] rescue ""
        @fields["spec"] = params[:spec] rescue ""
        @fields["equipment"] = params[:equipment] rescue ""
        @fields["tout"] = params[:tout] rescue ""
        @fields["surgrecov"] = params[:surgrecov] rescue ""
        @fields["obsrecov"] = params[:obsrecov] rescue ""
        @fields["nbm"] = params[:nbm] rescue ""
        @fields["nextmed"] = params[:nextmed] rescue ""
        @fields["freqobs"] = params[:freqobs] rescue ""
        @fields["score"] = params[:score] rescue ""
        @fields["dest"] = params[:dest] rescue ""
        @fields["recovout"] = params[:recovout] rescue ""
        @fields["child"] = params[:child] rescue ""
        @fields["ivi"] = params[:ivi] rescue ""
        @fields["wrist"] = params[:wrist] rescue ""
        @fields["intro"] = params[:intro] rescue ""
        @fields["team"] = params[:team] rescue ""
        @fields["op"] = params[:op] rescue ""
        @fields["hospno"] = params[:hospno] rescue ""
        
        @encounter_id = params[:encounter_id]
        
        if @encounter_id
        
            params.each{|p|
            
                case p[0]
                    when "tintime"   
                                                     
                        @concept_id = 85
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_datetime => p[1])
                        
                    when "datetaken"     
                                                                    
                        @concept_id = 86
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_datetime => p[1])
                        
                    when "hb"
                                                        
                        @concept_id = 87
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_text => p[1])
                        
                    when "wcc"
                                                        
                        @concept_id = 88
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_text => p[1])
                        
                    when "plts"
                                                        
                        @concept_id = 89
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_text => p[1])
                        
                    when "mps"
                                                        
                        @concept_id = 90
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_text => p[1])
                        
                    when "other"
                                                        
                        @concept_id = 91
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_text => p[1])
                        
                    when "ts"
                                                        
                        @concept_id = 92
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_text => p[1])
                        
                    when "units"
                                                        
                        @concept_id = 94
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_text => p[1])
                        
                    when "consent"
                                                        
                        @concept_id = 95
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_boolean => ((p[1]=="true")?1:0))
                        
                    when "site"
                                                        
                        @concept_id = 96
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_text => p[1])
                        
                    when "medic"
                                                        
                        @concept_id = 97
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_text => p[1])
                        
                    when "allergno"
                                                        
                        @concept_id = 98
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_text => p[1])
                        
                    when "adrug"
                                                        
                        @concept_id = 99
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_text => p[1])
                        
                    when "intern"
                                                    
                        @concept_id = 100
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_text => p[1])
                       
                    when "ate"
                                                    
                        @concept_id = 101
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_datetime => p[1])
                                
                    when "drank"
                                                    
                        @concept_id = 102
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_datetime => p[1])
                                
                    when "weight"
                                                    
                        @concept_id = 103
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_text => p[1])
                                
                    when "hr"
                                                    
                        @concept_id = 104
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_text => p[1])
                                
                    when "bp"
                                                    
                        @concept_id = 105
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_text => p[1])
                                
                    when "rr"
                                                    
                        @concept_id = 106
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_text => p[1])
                                
                    when "spo2"
                                                    
                        @concept_id = 107
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_text => p[1])
                                
                    when "nurse"
                                                    
                        @concept_id = 108
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_text => p[1])
                                
                    when "risk"
                                                    
                        @concept_id = 109
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_text => p[1])
                             
                    when "taco"
                                                    
                        @concept_id = 110
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_text => p[1])
                             
                    when "induction"
                                                    
                        @concept_id = 111
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_datetime => p[1])
                             
                    when "prepstart"
                                                    
                        @concept_id = 112
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_datetime => p[1])
                             
                    when "surg"
                                                    
                        @concept_id = 113
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_boolean => ((p[1]=="true")?1:0))
                             
                    when "surgrev"
                                                    
                        @concept_id = 114
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_boolean => ((p[1]=="true")?1:0))
                             
                    when "anaesthrev"
                                                    
                        @concept_id = 115
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_boolean => ((p[1]=="true")?1:0))
                             
                    when "nurserev"
                                                    
                        @concept_id = 116
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_boolean => ((p[1]=="true")?1:0))
                              
                    when "prophy"
                                                    
                        @concept_id = 117
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_text => p[1])
                             
                    when "imaging"
                                                    
                        @concept_id = 118
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_text => p[1])
                             
                    when "knife"
                                                    
                        @concept_id = 119
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_datetime => p[1])
                             
                    when "closure"
                                                    
                        @concept_id = 120
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_datetime => p[1])
                             
                    when "proc"
                                                    
                        @concept_id = 121
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_boolean => ((p[1]=="true")?1:0))
                             
                    when "instrument"
                                                    
                        @concept_id = 122
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_boolean => ((p[1]=="true")?1:0))
                             
                    when "spec"
                                                    
                        @concept_id = 123
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_boolean => ((p[1]=="true")?1:0))
                                
                    when "equipment"
                                                    
                        @concept_id = 124
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_boolean => ((p[1]=="true")?1:0))
                             
                    when "tout"
                                                    
                        @concept_id = 125
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_datetime => p[1])
                             
                    when "surgrecov"
                                                    
                        @concept_id = 126
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_boolean => ((p[1]=="true")?1:0))
                             
                    when "obsrecov"
                                                    
                        @concept_id = 127
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_boolean => ((p[1]=="true")?1:0))
                             
                    when "nbm"
                                                    
                        @concept_id = 128
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_datetime => p[1])
                             
                    when "nextmed"
                                                    
                        @concept_id = 129
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_datetime => p[1])
                             
                    when "freqobs"
                                                    
                        @concept_id = 130
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_text => p[1])
                             
                    when "score"
                                                    
                        @concept_id = 131
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_text => p[1])
                             
                    when "dest"
                                                    
                        @concept_id = 132
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_text => p[1])
                             
                    when "recovout"
                                                    
                        @concept_id = 133
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_datetime => p[1])
                     
                    when "child"
                                                    
                        @concept_id = 142
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_text => p[1])
                     
                    when "ivi"
                                                    
                        @concept_id = 143
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_text => p[1])
                     
                    when "wrist"
                                                    
                        @concept_id = 144
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_boolean => ((p[1]=="true")?1:0))
                     
                    when "intro"
                                                    
                        @concept_id = 145
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_boolean => ((p[1]=="true")?1:0))
                     
                    when "team"
                                                    
                        @concept_id = 146
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_boolean => ((p[1]=="true")?1:0))
                     
                    when "op"
                                                    
                        @concept_id = 147
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_boolean => ((p[1]=="true")?1:0))
                     
                    when "hospno"
                                                    
                        @concept_id = 148
                        
                        @obs = Observation.find(:first, :conditions => ["encounter_id = ? AND  concept_id = ?",@encounter_id, @concept_id])
                        
                        @obs.update_attributes(:value_text => p[1])
                     
                end
                            
            }
        
        end
        
        render :text => @encounter_id rescue "";
    end
    
    def utilisation
        if params[:parent_location]
        session[:parent_location] = params[:parent_location]
        
        @parent_location = params[:parent_location]
        
        if params[:period]  # [:week] rescue nil
            @period_week = params[:period][:week]
        end
        
        if params[:location]    #[:unit]
            @period_unit = params[:location][:unit]
        end
        
        if params[:location]    #[:unit]
            @encounter = Encounter.find(:all, :include => [:type, :observations], :conditions => ["encounter.voided = ? AND encounter.location_id = ? AND UPPER(encounter_type.name) = ? AND ((DAYOFYEAR(obs.value_datetime) DIV 7) + ROUND((DAYOFYEAR(obs.value_datetime) % 7) * 0.1)) = ?",0, params[:location][:unit], "SURGICAL OPERATION", ((@period_week)?(@period_week):((Time.now.yday/7)+((Time.now.yday%7)*0.1).round))], :order => "obs.value_datetime")
        else
            @u = Location.find(:all, :conditions => ["COALESCE(parent_location,'') = ? AND NOT UPPER(description) LIKE ?", session[:parent_location], "%WARD%"], :order => "name").first
            
            if @u.nil?
                flash[:notice] = "No Records Found"
                redirect_to :action => "index"
                return
            end
            
            @encounter = Encounter.find(:all, :include => [:type, :observations], :conditions => ["encounter.voided = ? AND encounter.location_id = ? AND UPPER(encounter_type.name) = ? AND ((DAYOFYEAR(obs.value_datetime) DIV 7) + ROUND((DAYOFYEAR(obs.value_datetime) % 7) * 0.1)) = ?",0, @u.location_id, "SURGICAL OPERATION", ((@period_week)?(@period_week):((@period_week)?(@period_week):((Time.now.yday/7)+((Time.now.yday%7)*0.1).round)))], :order => "obs.value_datetime")
        end
        
        @units = Location.find(:all, :conditions => ["COALESCE(parent_location,'') = ? AND NOT UPPER(description) LIKE ?", session[:parent_location], "%WARD%"], :order => "name")
    
        # flash[:notice] = "View all Booked Appointments"
    end
  end
end
