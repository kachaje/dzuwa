class TestController < ApplicationController
    helper :send_doc
    include SendDocHelper

    def test
        render (:text => "testing", :layout => "menu")
    end
    
    def test_report
        send_doc(
            render_to_string(:layout => false),
            '', 
            'test',
            'Test Report', 
            'pdf')
    end

end
