class LocationController < ApplicationController

    def index
        # flash[:notice] = "Select hospital"
    end

    def list
        @locations = Location.find(:all, :conditions => ["UPPER(name) NOT LIKE ? AND COALESCE(parent_location,'') = ?","UNKNOWN LOCATION", ""])
    end
    
    def new_hospital    
    end
    
    def new_venue
    end
    
    def edit_hospital
        if params[:selectId]
            @location = Location.find(params[:selectId])
        else
            @location = Location.find(:all).last
        end
    end
    
    def edit_venue
        if params[:selectId]
            @location = Location.find(params[:selectId])
        else
            @location = Location.find(:all).last
        end
    end
    
    def update_hospital
        @location = Location.find(params[:location][:location_id])
        
        if @location.update_attributes(params[:location])
            flash[:notice] = "Updated #{params[:location][:name]}"
        else
            flash[:error] = "Updating #{params[:location][:name]} failed"
        end
        redirect_to :action => "list"
    end
    
    def update_venue
        @location = Location.find(params[:location][:location_id])
        
        if @location.update_attributes(params[:location])
            flash[:notice] = "Updated #{params[:location][:name]}"
        else
            flash[:error] = "Updating #{params[:location][:name]} failed"
        end
        redirect_to :action => "show"
    end
    
    def create_hospital
        @location = Location.new(params[:location])
        @uuid = Location.find_by_sql("SELECT UUID() uuid").first
        
        @location.uuid = @uuid.uuid
        
        if @location.save
            flash[:notice] = "Location #{params[:location][:name]} saved"
            redirect_to :action => "list"
        else
            flash[:error] = "Location #{params[:location][:name]} was not saved"
            redirect_to :action => "new_hospital"
        end
    end
    
    def create_venue
        if params[:location][:name].strip.length == 0
            flash[:error] = "Cannot save empty unit name"
            redirect_to :action => "new_vanue"
        end
        
        @location = Location.new()
        @uuid = Location.find_by_sql("SELECT UUID() uuid").first
        
        @location.uuid = @uuid.uuid
        
        @location.name = params[:location][:name]
        @location.description = params[:location][:description]
        @location.parent_location = params[:location][:location_id]
        
        if @location.save
            flash[:notice] = "Saved unit #{params[:location][:name]}"
            session[:parent_location] = @location.parent_location
            redirect_to :action => "show"
        else
            flash[:error] = "Could not save unit #{params[:location][:name]}"
            redirect_to :action => "new_venue"
        end
    end

    def show
        if params[:location_id]
            @venues = Location.find(:all, :conditions => ["parent_location = ?", params[:location_id]])         
        elsif params[:selectId]
            @venues = Location.find(:all, :conditions => ["parent_location = ?", params[:selectId]]) 
            session[:parent_location] = params[:selectId]
        elsif session[:parent_location]
            @venues = Location.find(:all, :conditions => ["parent_location = ?", session[:parent_location]])   
        end
    end
    
    def unit_usage
    end
    
    def unit_status
    end
    
    def add_appointment
    end
    
    def appointments
        if params[:selectId]
            @appointments = Encounter.find(:all, :include => [:type], :conditions => ["encounter_type.name = ? AND location_id = ? AND encounter.voided = ?", "APPOINTMENT", params[:selectId], 0])
            if @appointments.length <= 0
                @location = Location.find(params[:selectId])
            end                
        end 
    end
end
