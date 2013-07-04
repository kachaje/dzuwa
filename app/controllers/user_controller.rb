class UserController < ApplicationController

  def login
    if request.get?
        session[:user_id]=nil
    else
        if session[:name]
            reset_session
            redirect_to(:action => "login")
        end
        
        @user=User.new(params[:user])
        logged_in_user=@user.try_to_login
        
        if logged_in_user
            reset_session
            session[:user_id] = logged_in_user.user_id
            session[:ip_address] = request.env['REMOTE_ADDR']         
            session[:name] = logged_in_user.name
            location = Location.find(params[:loc][:location_id]) rescue nil        
            flash[:error] = "Invalid Workstation Location" and return unless location
            
            session[:location_id] = nil
            session[:location_id] = location.id if location
            Location.current_location = location if location

            if logged_in_user.isSurgicalSecretary
                
                session[:user_type] = "SURGICAL SECRETARY"
                redirect_to(:controller => "encounters", :action => "appointment", :params => {:list_type => "booking"})
                
            elsif logged_in_user.isAnaestheticalSecretary || logged_in_user.isScrubNurse 
                       
                session[:user_type] = "SCRUB NURSE"
                redirect_to(:controller => "encounters", :action => "appointment", :params => {:list_type => "list"})
                
            elsif logged_in_user.isProvider
            
                session[:user_type] = "GENERAL"               
                redirect_to("/")
            
            else    
                
                session[:user_type] = "SCRUB NURSE"               
                redirect_to(:controller => "encounters", :action => "appointment", :params => {:list_type => "list"})
                
            end
        else
            flash[:error] = "Invalid username or password"
        end      
    end
  end          
  
  
 def health_centres
     redirect_to(:controller => "patient", :action => "menu")
     @health_centres = Location.find(:all,  :order => "name").map{|r|[r.name, r.location_id]}
 end 
 
 def list_clinicians
 	@clinician_role = Role.find_by_role("clinician").id
 	@clinicians = UserRole.find_all_by_role_id(@clinician_role)
 end
  
  def logout
   #if time is 4 o'oclock then send report on logout. 
    reset_session
    redirect_to(:action => "login")
  end

  def signup
    render :text => "Please sign up"
  end

  def remind_password
  end

  def try_to_log_in
    User.login(self.name, self.password)
  end

  def index
    @user=User.find(session[:user_id])
    @firstname= "@user.first_name"
    @secondName="@user.last_name"
       
    list
    return render(:action => 'list')
  end
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
#  verify :method => :post, :only => [ :destroy, :create, :update ],
        # :redirect_to => { :action => :list }
        
  def voided_list
      session[:voided_list] = false 
    # @user_pages, @users = paginate(:users, :per_page => 50,:conditions =>["voided=?",true])
    @users = User.find(:all, :conditions =>["voided=?",true])
      render :view => 'list'
  end
  
  def list
    session[:voided_list] = true
        
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
        @limit = 3
    end
    
    # record count
    @count = User.find(:all, :conditions =>["voided=?",false]).length
      
    @users = User.find(:all, :conditions =>["voided=?",false], :limit => @start.to_s + ", " + @limit.to_s)
      
 end

  def show
    unless session[:user_edit].nil?
     @user = User.find(session[:user_edit], :include => [{:person => :names}], :order => "users.date_created")
    else
     @user = User.find(:all, :include => [{:person => :names}], :order => "users.date_created").last
     session[:user_edit]=@user.user_id
    end  
  end

  def new
    @user = User.new
    if params[:selectId]
        @j = 0
        @i = 0
        @selectid = params[:selectId]
        @personname = Person.find(:all, :include => [:names], :conditions =>["person.voided = ? AND COALESCE(person_name.family_name,'') <> ? AND person_name.preferred = ?",false, "", 1], :order => "person_name.family_name").map{|p|[p.name, p.person_id]}
        
        @personname.each{|p|
            @i += 1
            if p[1].to_i == @selectid.to_i
                @j = @i - 1
            end
        }                        
    end
  end

  def create
       session[:user_edit] = nil
       
       @id = User.find(params[:user][:user_id]) rescue nil
       
       if @id
            #flash[:notice] = 'This User already exists'
        
            @user_first_name = params[:user][:first_name]
            @user_middle_name = params[:user][:middle_name]
            @user_last_name = params[:user][:last_name]
            @user_role = params[:user_role][:role]
            # @user_admin_role = params[:user_role_admin][:role]
            @user_name = params[:user][:username]
            redirect_to :action => 'new'
            return
       end
       
       @user = User.new(params[:user])

       @user.user_id = params[:user][:user_id] rescue nil
       
    if (params[:user][:password] != params[:user_confirm][:password])
      flash[:notice] = 'Password Mismatch'
    #  flash[:notice] = nil
       @user_first_name = params[:user][:first_name]
       @user_middle_name = params[:user][:middle_name]
       @user_last_name = params[:user][:last_name]
       @user_role = params[:user_role][:role]
       @user_admin_role = params[:user_role_admin][:role]
       @user_name = params[:user][:username]
       redirect_to :action => 'new'
      return
    end
      
    if @user.save
        user_role=UserRole.new
        user_role.role = Role.find_by_role(params[:user_role][:role]).role
        user_role.user_id=@user.user_id
        user_role.save
        
        flash[:notice] = 'User was successfully created.'
        redirect_to :action => 'show'
    else
        flash[:notice] = 'OOps! User was not created!.'
        render :action => 'new'
    end
  end

  def edit
    @user = User.find(session[:user_edit])
  end

  def update
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user])
       flash[:notice] = 'User was successfully updated.'
       redirect_to :action => 'show', :id => @user
    else
      flash[:notice] = "OOps! User was not updated!."
      render :action => 'edit'
    end
  end

  def destroy
    if params[:selectId]
       @destro = User.find(params[:selectId], :include => [{:person => :names}]).person.names.first 
       session[:user_edit] = User.find_by_user_id(params[:selectId])
    end
    
   unless request.get?
   @user = User.find(session[:user_edit])
    if @user.update_attributes(:voided => true, :void_reason => params[:user][:void_reason],:voided_by => session[:user_id],:date_voided => Time.now.to_s)
        @person = Person.find(session[:user_edit])

        if @person.update_attributes(:voided => true, :void_reason => params[:user][:void_reason],:voided_by => session[:user_id],:date_voided => Time.now.to_s)      
          flash[:notice]='User has successfully been removed.'
          redirect_to :action => 'voided_list'
        else
          flash[:notice]='User was not successfully removed'
          redirect_to :action => 'destroy'
        end
        
    else
      flash[:notice]='User was not successfully removed'
      redirect_to :action => 'destroy'
    end    
   end
  end
  
  def add_role
     unless params[:id].nil?
        @user = User.find(params[:id], :include => [{:person => :names}])
        session[:user_edit] = User.find_by_user_id(params[:id])
     else
        @user = User.find(:all, :include => [{:person => :names}]).last
     end
     
     unless request.get?
        user_role=UserRole.new
        user_role.role = Role.find_by_role(params[:user_role][:role]).role
        user_role.user_id=@user.user_id
        if user_role.save
            flash[:notice] = "You have successfuly added the role of #{params[:user_role][:role]}"
        else 
            flash[:error] = "The role of #{params[:user_role][:role]} already exists in the system for this user"
        end
        redirect_to :action => "show"
      else
      user_roles = UserRole.find_all_by_user_id(@user.user_id).collect{|ur|ur.role}
      all_roles = Role.find(:all).collect{|r|r.role}
      @roles = (all_roles - user_roles)
      @show_super_user = true if UserRole.find_all_by_user_id(@user.user_id).collect{|ur|ur.role != "superuser" }
   end
  end
  
  def delete_role
    if params[:selectId]
        @user = User.find(params[:selectId], :include => [{:person => :names}])    
    else
        @user = User.find(params[:id], :include => [{:person => :names}])    
    end
    
    unless request.post?
      @roles = UserRole.find_all_by_user_id(@user.user_id).collect{|ur|ur.role}
    else
        if !params[:selectId]
            role = Role.find_by_role(params[:user_role][:role]).role
            user_role =  UserRole.find_by_role_and_user_id(role,@user.user_id)  
            user_role.destroy
            flash[:notice] = "You have successfuly removed the role of #{params[:user_role][:role]}"
            redirect_to :action =>"show"
        else
            @roles = UserRole.find_all_by_user_id(@user.user_id).collect{|ur|ur.role}
        end
    end
  end
  
  def user_menu
    # render(:layout => "layouts/menu")
  end
 
  def search_user
   session[:user_edit] = nil
   unless request.get?
     if params[:selectId]
        session[:user_edit] = User.find_by_user_id(params[:selectId])
     else
        session[:user_edit] = User.find_by_user_id(params[:user][:username]).user_id
     end
     redirect_to :action =>"show"
   end
  end
  
  def change_password
    @user = User.find(params[:id])
   
    if params[:origin]
        session[:origin] = params[:origin]
        @origin = params[:origin]
    else
        @origin = ""
    end
        
    unless request.get? 
      if (params[:user][:password] != params[:user_confirm][:password])
        flash[:notice] = 'Password Mismatch'
        
        if params[:src]
            re = /\/(\w+)\/(\w+(\/)?(\w+))/
            
            url = re.match(params[:src])
            
            redirect_to(:controller => url[1], :action => url[2])
        else           
            redirect_to :action => 'new'
        end
                    
        return
      else
        if @user.update_attributes(params[:user])
            flash[:notice] = "Password successfully changed"
            if session[:origin] && session[:origin].length > 0
                re = /\/(\w+)\/(\w+(\/)?(\w+))/

                url = re.match(session[:origin])

                redirect_to(:controller => url[1], :action => url[2])
            else
              redirect_to :action => "show"
            end
                                  
          return
        else
          flash[:notice] = "Password change failed"  
        end    
      end
    end

  end
  
  def activities
    # Don't show tasks that have been disabled
    # @privileges = User.current_user.privileges.reject{|priv| GlobalProperty.find_by_property("disable_tasks").property_value.split(",").include?(priv.privilege)}
    # @activities = User.current_user.activities.reject{|activity| GlobalProperty.find_by_property("disable_tasks").property_value.split(",").include?(activity)}
    @privileges = User.current_user.privileges.reject{|priv| priv.privilege}
    @activities = User.current_user.activities.reject{|activity| activity}
  end
  
  def change_activities
    User.current_user.activities = params[:user][:activities]
    redirect_to(:controller => 'patient', :action => "menu")
  end
  
  def user_list
    @users = PersonName.find(:all, :conditions => ["preferred = ?",1])
    render(:layout => "layouts/menu")
    # respond_to do |format|
        # format.xml => { render :text => @users.to_xml }
        # format.pdf => { render_jasper_report :collection => @users }
        # format.html #default
    # end

  end
  
end
