require "jasper-rails"

#Assumes you have a compiled index.jasper file in /app/views/people
class PeopleController < ApplicationController
    def index
      @people = PersonName.find(:all, :conditions => ["preferred = ?",1])
      respond_to do |format|
        # format.xml => { render :text => @people.to_xml }
        # format.xml{ render :text => @people.to_xml }
        format.pdf{ render_jasper_report :collection => @people }
        # format.html #default
        #render_jasper_report :collection => @people
      end
    end
    
    def user_list
        @users = PersonName.find(:all, :conditions => ["preferred = ?",1])
        render(:layout => "layouts/menu")
    end
    
    def doc
        t = Table("/root/rails/reports/ruport/foo.csv")
        grouping = Grouping(t,:by => "name")
        puts grouping.to_pdf
    end
    
end

