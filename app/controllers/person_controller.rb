require "text"
class PersonController < ApplicationController

    def index
    
        # pagination start page
        if params[:start]
            @start = params[:start]
        else
            @start = 0
        end
        
        # pagination range
        if params[:limit]
            @limit = params[:limit]
        else
            @limit = 20
        end
        
        # search by alphabetical order
        if params[:letter]
            @letter = params[:letter]
        else
            @letter = "ALL"
        end
        
        if params[:origin]
            session[:origin] = params[:origin]
            @origin = params[:origin]
        else
            @origin = "/person/index"
        end
        
        if params[:title]
            session[:title] = params[:title]
            @title = params[:title]
        else
            @title = ""
        end
        
        @condition = "%"
        @field = "person_name.given_name"
        
        case @letter
        
            when "ALL"
                @condition = "%"
                
            when @letter.length > 1
                @condition = "%"
                
            else
                @condition = @letter + "%"
        end
        
        # order records by selected field
        if params[:order]
            case params[:order]
                when "id"
                    @order = "person_name.person_id"
                    @field = "person_name.family_name"
                    
                when "given_name"
                    @order = "person_name.given_name"
                    @field = "person_name.given_name"
                    
                when "family_name"
                    @order = "person_name.family_name"
                    @field = "person_name.family_name"
                   
                when "username"
                    @order = "users.username"
                    @field = "person_name.family_name"
                
                when "identifier"
                    @order = "patient_identifier.identifier"
                    @field = "person_name.family_name"
                
                else
                    @order = "person_name.family_name"
                    @field = "person_name.family_name"
            end
        else
            @order = "person_name.given_name"
            @field = "person_name.given_name"
        end
        
        # record type selection:
        # 1 => ALL
        # 2 => System Users
        # 3 => Patients
        if params[:record_type]
            @record_type = params[:record_type]
            case @record_type
            
               when "2"
                   @rec = "1"
                    
               when "3"
                   @rec = "0"
                    
               else
                   @rec = "%"
                    
            end   
            session[:record_type] = @record_type 
        else 
            if session[:record_type]            
                @record_type = session[:record_type]
                case @record_type
                
                   when "2"
                       @rec = "1"
                        
                   when "3"
                       @rec = "0"
                        
                   else
                       @rec = "%"
                        
                end      
            else
                @record_type = 1
                @rec = "%"
            end
        end       
        
        # record count
        @count = Person.find(:all, :include => [:names, ((@rec == "%")?({:patient => [:patient_identifiers]}):((@rec.to_i == 1)?(:user):({:patient => [:patient_identifiers]})))], :conditions => ["person.voided = ? AND COALESCE(person_name.given_name,'') <> ? AND " + @field + " LIKE ? AND person_name.preferred LIKE ?", false, "", @condition, @rec], :order => @order).length
        
        # current record container
        @person = Person.find(:all, :include => [:names, ((@rec == "%")?({:patient => [:patient_identifiers]}):((@rec.to_i == 1)?(:user):({:patient => [:patient_identifiers]})))], :conditions => ["person.voided = ? AND COALESCE(person_name.family_name,'') <> ? AND " + @field + " LIKE ? AND person_name.preferred LIKE ?", false, "", @condition, @rec], :order => @order, :limit => @start.to_s + ", " + @limit.to_s)

         # record array of current actual names
         @names = Array.new
         @users = Array.new
         @identifiers = Array.new
         @enc = {}
         
         @person.each{ |p|
            @names.push p.names
            if @rec.to_i == 1
                @users.push p.user
            else
                @identifiers.push p.patient
                if p.patient.encounters.length > 0
                    @enc[p.person_id] = p.patient.encounters.length
                end                    
            end
         }

    end
    
    def new
        if params[:viewer]
            if params[:viewer] == "false"
                @viewer = "none"
            else
                @viewer = "block"
            end
        end
        
        if params[:record_type]
            @record_type = params[:record_type]
        else
            @record_type = "1"
        end
        
        if params[:origin]
            session[:origin] = params[:origin]
        end
        
        if params[:title]
            session[:title] = params[:title]
            @title = params[:title]
        else
            @title = ""
        end
        
    end
    
    def new_prof  
        if params[:viewer]
            if params[:viewer] == "false"
                @viewer = "none"
            else
                @viewer = "block"
            end
        end
        
        if params[:record_type]
            @record_type = params[:record_type]
        else
            @record_type = "4"
        end      
    end
    
    def create_prof
        
        re = /^(\w+)/
        
        str = re.match(params[:person][:family_name])
        
        @record_type = params[:record_type]
        
        unless str
            flash[:error] = 'Please enter a valid last name at least ' + params[:person_name][:family_name]
            render :action => 'new_prof'
            return
        end
        
        @person = Person.new(:gender => params[:person][:gender])
        
        @uuid = Person.find_by_sql("SELECT UUID() uuid").first
        
        @person.uuid = @uuid.uuid
       
        if @person.save
            @person_name = PersonName.new(:prefix => params[:person][:title], :given_name => params[:person][:given_name], :family_name => params[:person][:family_name])
            
            @person_id = @person.person_id
            
            @person_name.person_id = @person_id
            
            @uuid = PersonName.find_by_sql("SELECT UUID() uuid").first
            
            @person_name.uuid = @uuid.uuid
            
            @person_name.preferred = 1
            
            unless @person_name.save                
                flash[:notice] = 'OOps! Person name was not created!.'
                render :action => 'new_prof'
                return
            end
            
            if params[:person][:contact].strip.length > 0
                @person_attributes = PersonAttribute.new()
                @person_attributes.person_id = @person_id
                @person_attributes.value = params[:person][:contact]
                @person_attributes.person_attribute_type_id = 8
                @person_attributes.voided = 0
                
                @uuid = PersonAttribute.find_by_sql("SELECT UUID() uuid").first
                
                @person_attributes.uuid = @uuid.uuid
                
                unless @person_attributes.save                
                    flash[:notice] = 'OOps! Person mobile was not created!.'
                    render :action => 'new_prof'
                    return
                end
            end
            
            case params[:record_type]                
                when "4"
                    @role = "SURGEON"                    
                when "5"
                    @role = "INTERN"                                          
            end
            
            @username = ""
            
            if params[:person][:given_name].strip.length == 0
                params[:person][:given_name] = params[:person][:family_name]
            end
            
            0.upto(2){|p| @username += params[:person][:given_name][p].chr}
            
            0.upto(2){|p| @username += params[:person][:family_name][p].chr}

            @system_id = params[:person][:family_name][0].chr.upcase + params[:person][:given_name][0].chr.upcase + "-" + @person_id.to_s
            
            @user = User.new(:user_id => @person_id, :system_id => @system_id, :username => @username.downcase, :password => @username.downcase, :creator => session[:user_id], :date_created => DateTime.now)
            
            if @user.save    
                if @role        
                    user_role=UserRole.new
                    user_role.role = @role
                    user_role.user_id=@user.user_id
                    user_role.save
                end
                
                flash[:notice] = 'User was successfully created.'
                
                session[:show_person_id] = @person_id
                
                if @role
                    redirect_to :action => 'show'
                else
                    session[:user_edit] = @person_id
     
                    redirect_to(:controller => "user", :action => 'show')
                end
            else
                flash[:notice] = 'OOps! User was not created!.'
                render(:controller => "user", :action => 'new')
            end
        end
                
    end
    
    def edit
        if params[:record_type]
            @record_type = params[:record_type]
        else
            @record_type = "1"
        end
        
        if params[:origin]
            session[:origin] = params[:origin]
        end
        
        @result = ""
        
        if params[:selectId]
            session[:user_edit] = params[:selectId]
            
            @result = Person.find(params[:selectId], :include => [:names], :conditions => ["person.voided = ? AND COALESCE(person_name.given_name,'') <> ?", false, ""], :order => "person_name.given_name")        
        end        
    end
    
    def update
        session[:record_type] = params[:record_type]
        
        @person = Person.find(params[:person][:person_id])
        @person_name = PersonName.find(params[:person_name][:person_name_id])
        @person_address = PersonAddress.find(params[:person_address][:person_address_id])
        #@person_attributes = PersonAttribute.find(params[:person_attribute][:person_attribute_id])
        
        if params[:estimate].strip.length > 0
            params[:person][:birthdate] = Date.today - (eval(params[:estimate]) * 365)
            params[:person][:birthdate_estimated] = 1
        else
            params[:person][:birthdate_estimated] = 0
        end
        
        if @person.update_attributes(params[:person]) && @person_name.update_attributes(params[:person_name]) && @person_address.update_attributes(params[:person_address]) 
        
            @person_attributes = PersonAttribute.find(:all, :conditions => ["person_id = ?",params[:person][:person_id]]).first
            
            if @person_attributes
                @person_attributes.update_attributes(:value => params[:person_attribute][:value])
            else
                @person_attributes = PersonAttribute.new()
                @person_attributes.person_id = @person.person_id
                @person_attributes.value = params[:person_attribute][:value]
                @person_attributes.person_attribute_type_id = 8
                @person_attributes.voided = 0
                
                @uuid = PersonAttribute.find_by_sql("SELECT UUID() uuid").first
                
                @person_attributes.uuid = @uuid.uuid
                
                @person_attributes.save      
            end
            
            flash[:notice] = 'User was successfully updated.'
            # redirect_to :action => session[:origin] rescue 'index'
            if session[:origin]
                re = /\/(\w+)\/(\w+(\/)?(\w+))/
                
                url = re.match(session[:origin])
                
                redirect_to(:controller => url[1], :action => url[2]) rescue redirect_to :action => 'index'
            else
                redirect_to :action => 'index'
            end
            
        else
        
            if params[:person][:person_id]
                @result = Person.find(params[:person][:person_id], :include => [:names], :conditions => ["person.voided = ? AND COALESCE(person_name.given_name,'') <> ?", false, ""], :order => "person_name.given_name")        
            end   
            flash[:notice] = "OOps! User was not updated!."
            render :action => 'edit'
            
        end
    end
  
    def checkDigit(idWithoutCheckdigit)

        @idWithoutCheckdigit = idWithoutCheckdigit.strip.upcase
        
        @i = 0
        @sum = 0    
        
        @idWithoutCheckdigit.upcase.reverse.scan(/\w/) { |p|
        
            @digit = p.unpack("c").to_s.to_i - 48        
            
            @weight = 0
            
            if @i % 2 == 0
                
                @weight = (2 * @digit) - ((@digit / 5) * 9)
                
            else
                
                @weight = @digit
                
            end
            
            @sum += @weight
            
            @i += 1
        
        }
        
        @sum = @sum.abs + 10
        
        return (10 - (@sum%10)) % 10

    end
   
    def create
        session[:record_type] = params[:record_type]
        
        re = /^(\w+)/
        
        str = re.match(params[:person_name][:family_name])
        
        unless str
            flash[:error] = 'Please enter a valid last name at least ' + params[:person_name][:family_name]
            @record_type = params[:record_type]
            render :action => 'new'
            return
        end
        
        @person = Person.new(params[:person])
        
        if params[:estimate].strip.length > 0
            @person.birthdate = Date.today - (eval(params[:estimate]) * 365)
            @person.birthdate_estimated = 1
        else
            @person.birthdate_estimated = 0
        end
        
        @uuid = Person.find_by_sql("SELECT UUID() uuid").first
        
        @person.uuid = @uuid.uuid
       
        if @person.save
            @person_name = PersonName.new(params[:person_name])
            @person_name.person_id = @person.person_id
            
            @uuid = PersonName.find_by_sql("SELECT UUID() uuid").first
            
            @person_name.uuid = @uuid.uuid
            
            if params[:record_type]
                case params[:record_type]
                    
                    when "1"
                        @person_name.preferred = 0
                        
                    when "2"
                        @person_name.preferred = 1
                        
                    else
                        @person_name.preferred = 0
                        
                end                       
            end
            
            unless @person_name.save                
                flash[:notice] = 'OOps! Person name was not created!.'
                render :action => 'new'
                return
            end
            
            @person_address = PersonAddress.new(params[:person_address])
            @person_address.person_id = @person.person_id
            
            @uuid = PersonAddress.find_by_sql("SELECT UUID() uuid").first
            
            @person_address.uuid = @uuid.uuid
            
            unless @person_address.save                
                flash[:notice] = 'OOps! Person address was not created!.'
                render :action => 'new'
                return
            end
            
            @person_attributes = PersonAttribute.new()
            @person_attributes.person_id = @person.person_id
            @person_attributes.value = params[:person_attribute][:value]
            @person_attributes.person_attribute_type_id = 8
            @person_attributes.voided = 0
            
            @uuid = PersonAttribute.find_by_sql("SELECT UUID() uuid").first
            
            @person_attributes.uuid = @uuid.uuid
            
            unless @person_attributes.save                
                flash[:notice] = 'OOps! Person mobile was not created!.'
                render :action => 'new'
                return
            end
            
            # flash[:error] = params[:record_type]
            
            # problems with user numbers so I resort to add dummy user accounts for patients
            @user = User.new(:creator => session[:user_id], :date_created => DateTime.now)
            
            @user.save
            
            if params[:record_type]
                if params[:record_type] == "3" || params[:record_type] == "1"
                    @patient = Patient.new
                    @patient.patient_id = @person.person_id
                    @patient.tribe = 1
                    @patient.creator = session[:user_id]
                    @patient.date_created = Time.now
                    
                    if @patient.save
                        @patient_identifier = PatientIdentifier.new
                        @patient_identifier.patient_id = @patient.patient_id
                        
                        identifier = @patient.patient_id.to_s + @person_name.given_name.scan(/^\w/)[0].upcase + @person_name.family_name.scan(/^\w/)[0].upcase
                        
                        @patient_identifier.identifier = "#{identifier}-#{checkDigit(identifier)}"  
                        @patient_identifier.identifier_type = 1
                        @patient_identifier.location_id = 1
                        @patient_identifier.creator = session[:user_id]
                        @patient_identifier.date_created = Time.now
                        
                        # @uuid = PatientIdentifier.find_by_sql("SELECT UUID() uuid").first.uuid
                        
                        # @person_identifier.uuid = @uuid
                        
                        unless @patient_identifier.save
                            flash[:notice] = 'OOps! Patient identifier was not created!.'
                            render :action => 'new'
                        return
                        end
                    else
                        flash[:notice] = 'OOps! Patient record was not created!.'
                        render :action => 'new'
                        return
                    end
                end                       
            end
            
            flash[:notice] = 'Person was successfully created.'
            # redirect_to(:controller => "patient", :action => "menu")
            # redirect_to :action => session[:origin] rescue 'index'
            if session[:origin]
                re = /\/(\w+)\/(\w+(\/)?(\w+))/
                
                url = re.match(session[:origin])
                
                redirect_to(:controller => url[1], :action => url[2])
            else
                session[:show_person_id] = @person.person_id
                redirect_to :action => 'show'
            end
        else
            flash[:notice] = 'OOps! Person was not created!.'
            render :action => 'new'
        end
    end
    
    def destroy
    end
    
    def show   
        if session[:show_person_id]
            @user = Person.find(session[:show_person_id])
        end    
    end

    def search_names
    end
    
    def search
    
        if params[:search]
            @names = PersonName.find(:all, :conditions => ["(UPPER(given_name) LIKE ? OR UPPER(family_name) LIKE ?) AND person_name.preferred = ?", "%" + params[:search].upcase + "%", "%" + params[:search].upcase + "%", 0], :order => "given_name")
        else
            @names = PersonName.find(:all, :conditions => ["person_name.preferred = ?", 0])
        end
        
        render :text => "<option>" + @names.map{|p| "#{p.given_name} #{p.family_name}"} .join("</option><option>") + "</option>"
        
    end
    
    def search_surg
    
        if params[:search]
            @names = PersonName.find(:all, :include => [{:person => [{:user => [:user_roles]}]}], :conditions => ["(UPPER(given_name) LIKE ? OR UPPER(family_name) LIKE ? OR UPPER(prefix) LIKE ?) AND person_name.preferred = ? AND user_role.role = ?", "%" + params[:search].upcase + "%", "%" + params[:search].upcase + "%", "%" + params[:search].upcase + "%", 1, "Surgeon"], :order => "prefix")
        else

            @names = PersonName.find(:all, :include => [{:person => [{:user => [:user_roles]}]}], :conditions => ["person_name.preferred = ? AND user_role.role = ?", 1, "Surgeon"], :order => "prefix")

        end
        
        render :text => "<option>" + @names.map{|p| "#{p.prefix} #{p.given_name} #{p.family_name} (#{p.person.user.system_id})"} .join("</option><option>") + "</option>"
        
    end
    
    def search_intern
    
        if params[:search]
            @names = PersonName.find(:all, :include => [{:person => [{:user => [:user_roles]}]}], :conditions => ["(UPPER(given_name) LIKE ? OR UPPER(family_name) LIKE ? OR UPPER(prefix) LIKE ?) AND person_name.preferred = ? AND UPPER(user_role.role) = ?", "%" + params[:search].upcase + "%", "%" + params[:search].upcase + "%", "%" + params[:search].upcase + "%", 1, "INTERN"], :order => "prefix")
        else

            @names = PersonName.find(:all, :include => [{:person => [{:user => [:user_roles]}]}], :conditions => ["person_name.preferred = ? AND UPPER(user_role.role) = ?", 1, "INTERN"], :order => "prefix")

        end
        
        render :text => "<option>" +  @names.map{|p| "#{p.prefix.strip} #{p.given_name.strip} #{p.family_name}  (#{p.person.user.system_id})" + ((p.person.personattributes.length>0)?" - (#{p.person.personattributes.first.value})":"")} .join("</option><option>") + "</option>"
        
    end
    
    def search_dob
        @name = params[:search].split(" ")
        
        @result = Person.find(:first, :include => [:names], :conditions => ["UPPER(person_name.given_name) LIKE ? AND UPPER(person_name.family_name) LIKE ? AND person_name.preferred = ?", @name[0].strip + "%", @name[1].strip + "%", 0])
        
        @tmpdob = ((Date.today - @result.birthdate).to_i / 365)
                                                
        if @tmpdob <= 3 
            @dob = ""
            
            @tmpmob = ((Date.today - @result.birthdate).to_i / 30)
             
            if @tmpmob == 0
                @tmpmob = ((Date.today - @result.birthdate).to_i % 30)
                @mob = @tmpmob.to_s + " days"
            else                                                    
                @mob = @tmpmob.to_s + " mths"
            end
        else
            @dob = "#{ ((@tmpdob>0)?(@tmpdob.to_s):"") }"
            @mob = ""
        end
                                                
        #render :text =>  ((Date.today - @result.birthdate).to_i / 365)
        render :text =>  "#{@dob}#{@mob}, #{@result.patient.patient_identifiers.first.identifier rescue ""}"
    end
end
