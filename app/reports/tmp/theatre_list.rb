class TheatreList < Ruport::Controller

  stage :list
  required_option :theatre, :date, :parent  
    
  def setup  
    conditions = " WHERE UPPER(t.name) = '#{options.theatre.upcase}' AND parent_location = #{options.parent} AND DATE_FORMAT(e.encounter_datetime, '%Y-%m-%d') = '#{options.date}'"
    
    self.data = Encounter.report_table_by_sql("SELECT CONCAT(given_name, ' ', family_name) name, 
                d.identifier, 
                FLOOR(DATEDIFF(NOW(), CONVERT(s.birthdate,DATE))/365) dob, 
                (SELECT CASE WHEN o.concept_id = 60 THEN (CASE WHEN CONVERT(COALESCE(o.value_numeric,0),UNSIGNED) > 0 THEN (SELECT name FROM location l WHERE l.location_id = CONVERT(o.value_numeric, UNSIGNED)) ELSE '' END) ELSE '' END FROM obs o WHERE o.encounter_id = e.encounter_id AND o.concept_id = 60) ward,
                CAPITALIZE((SELECT (SELECT name FROM concept_name n WHERE n.concept_id = o.value_coded) proc FROM obs o WHERE o.encounter_id = e.encounter_id AND o.concept_id = 61)) proc,
                (SELECT value_text FROM obs o WHERE o.concept_id = 62 AND o.encounter_id = e.encounter_id) gaorla,
                (SELECT (SELECT name FROM concept_name n WHERE n.concept_id = (SELECT answer_concept FROM concept_answer WHERE concept_id = o.value_coded)) FROM obs o where o.concept_id = 61 AND o.encounter_id = e.encounter_id) period,
                (SELECT value_numeric FROM obs o where o.concept_id = 63 AND o.encounter_id = e.encounter_id) blood,
                (SELECT CASE WHEN value_boolean = 1 THEN 'Yes' ELSE 'No' END FROM obs o where o.concept_id = 64 AND o.encounter_id = e.encounter_id) itu,
                (SELECT value_text FROM obs o WHERE o.concept_id = 65 AND o.encounter_id = e.encounter_id) comments,
                (SELECT CASE WHEN value_boolean = 1 THEN 'Yes' ELSE 'No' END FROM obs o where o.concept_id = 66 AND o.encounter_id = e.encounter_id) chklist,
                (SELECT CASE COALESCE(value_text,'') WHEN 'O' THEN 'Operated' WHEN 'C' THEN 'Cancelled' WHEN 'D' THEN 'Delayed' ELSE '' END FROM obs o WHERE o.concept_id = 67 AND o.encounter_id = e.encounter_id) ocd,
                (SELECT CASE COALESCE(value_numeric,'') WHEN 1 THEN 'Non-Medical' WHEN 2 THEN 'Anaesth Delay/Absence' WHEN 3 THEN 'Surg Delay/Absence' WHEN 4 THEN 'Lack of Blood' WHEN 5 THEN 'Not Fit' WHEN 6 THEN 'Inadequate Pre-op Preparation' WHEN 7 THEN 'Equipment Deficiencies' WHEN 8 THEN 'Time Overrun' WHEN 9 THEN 'Nursing Delay/Absence' WHEN 10 THEN 'Ward Delay' WHEN 11 THEN 'Not Needed' WHEN 12 THEN 'Emergency' ELSE '' END FROM obs o WHERE o.concept_id = 68 AND o.encounter_id = e.encounter_id) ocd2,
                (SELECT DISTINCT(name) FROM location l WHERE l.location_id = e.location_id) theatre,
                (SELECT DATE_FORMAT(value_datetime, '%b %e, %Y') FROM obs o WHERE concept_id = 69 AND o.encounter_id = e.encounter_id) appdate,
                (SELECT (SELECT CONCAT(prefix, ' ', given_name, ' ', family_name, ' (', system_id, ')') FROM person_name m LEFT OUTER JOIN users u ON u.user_id = m.person_id WHERE m.person_id = o.value_numeric) FROM obs o where concept_id = 71 AND o.encounter_id = e.encounter_id) surg,
                (SELECT (SELECT CONCAT(prefix, ' ', given_name, ' ', family_name, ' (', system_id, ')') FROM person_name m LEFT OUTER JOIN users u ON u.user_id = m.person_id WHERE m.person_id = o.value_numeric) FROM obs o where concept_id = 72 AND o.encounter_id = e.encounter_id) intern,
                (SELECT DATE_FORMAT(value_datetime, '%H:%i') FROM obs o where concept_id = 70 AND o.encounter_id = e.encounter_id) start,
                CASE (SELECT value_text FROM obs o WHERE o.encounter_id = e.encounter_id AND concept_id = 62) WHEN 'GA' THEN (SELECT (SELECT name FROM concept_name n WHERE n.concept_id = (SELECT answer_concept FROM concept_answer WHERE concept_id = o.value_coded)) FROM obs o where o.concept_id = 61 AND o.encounter_id = e.encounter_id) * 1.3 ELSE (SELECT (SELECT name FROM concept_name n WHERE n.concept_id = (SELECT answer_concept FROM concept_answer WHERE concept_id = o.value_coded)) FROM obs o where o.concept_id = 61 AND o.encounter_id = e.encounter_id) END duration
FROM encounter e
LEFT OUTER JOIN person_name p ON p.person_id = e.patient_id
LEFT OUTER JOIN patient_identifier d ON d.patient_id = e.patient_id
LEFT OUTER JOIN person s on s.person_id = e.patient_id
LEFT OUTER JOIN location t ON t.location_id = e.location_id" + conditions)
    
    data.rename_columns("name" => "Name", "identifier" => "Identifier", "dob" => "Age", "ward" => "WARD", "proc" => "PLANNED PROCEDURE", "gaorla" => "GA/LA", "period" => "EXPECTED SURGICAL DURATION (MINS)", "blood" => "BLOOD: HOW MUCH?", "itu" => "ITU Bed Booked?", "comments" => "Comments? Infected Weight if Paed", "chklist" => "Checklist Complete?", "ocd" => "Outcome O/C/D Code", "ocd2" => "Reason")    
  end

  formatter :html do
    build :list do
      output << textile("h3. Theatre List")
      output << data.to_html
    end
  end

  formatter :pdf do
    build :list do        
            tim = data.data.first["start"]
            mins = data.sigma("duration")
            
            hr  = tim.scan(/^(\d+)/)
            
            if hr
                hr = $1
            else
                hr = 0
            end

            mn = tim.scan(/(\d+)$/)

            if mn
                mn = $1
            else
                mn = 0
            end

            init = (hr.to_i * 60) + mn.to_i

            t = init + mins.to_i

            m = t % 60

            h = t / 60

            if h.to_i > 12 && hr.to_i < 13  # Cater for Lunch Hour
                h = h.to_i + 1
            end
                
            if h.to_i >= 24 
                h -= 24
            end

            if m.to_i < 10 
                m = "0" + m.to_s
            end

            if h.to_i < 10 
                h = "0" + h.to_s
            end

            tim = h.to_s + ":" + m.to_s
            
            pad(10) { add_text "Theatre List", :font_size => 24, :bold => true }

            pad(0) { add_text "" }

            draw_text("<b>Theatre:</b> <i>#{data.data.first["theatre"]}</i>", {:justification => :left, :font_size => 11})
            draw_text("<b>Date:</b> <i>#{data.data.first["appdate"]}</i>", { :justification => :center, :font_size => 11 })
            draw_text("<b>Planned Start Time:</b> <i>#{data.data.first["start"]}</i>", {:justification => :right, :font_size => 11})

            pad(10) { add_text "" }

            draw_text("<b>Operating Surgeon:</b> <i>#{data.data.first["surg"]}</i>", {:justification => :left, :font_size => 11})
            draw_text("<b>Intern (Name & Contact No):</b> <i>#{data.data.first["intern"]}</i>", {:justification => :right, :font_size => 11})

            pad(10) { add_text "" }

            draw_text("<b>First Patient Called at:</b> <i>#{data.data.first["start"]}</i>", {:justification => :left, :font_size => 11})

            draw_text("<b>Finish Time:</b> #{tim}", {:justification => :right, :font_size => 11})

            pad(18) { add_text "" }

            draw_table(data, :column_order => ["Name", "Identifier", "Age", "WARD", "PLANNED PROCEDURE", "GA/LA", "EXPECTED SURGICAL DURATION (MINS)", "BLOOD: HOW MUCH?", "ITU Bed Booked?", "Comments? Infected Weight if Paed", "Checklist Complete?", "Outcome O/C/D Code", "Reason"], 
            :column_options => {"Name" => {:width => 120, :heading => {:justification => :center}}, 
                                "Identifier" => {:heading => {:justification => :center}, :width => 55}, 
                                "Age" => {:heading => {:justification => :center}, :justification => :center, :width => 30}, 
                                "WARD" => {:heading => {:justification => :left}, :justification => :left, :width => 35}, 
                                "PLANNED PROCEDURE" => {:width => 100, :heading => {:justification => :center}}, 
                                "GA/LA" => {:heading => {:justification => :left}, :justification => :center, :width => 30}, 
                                "EXPECTED SURGICAL DURATION (MINS)" => {:heading => {:justification => :center}, :justification => :center, :width => 60}, 
                                "BLOOD: HOW MUCH?" => {:heading => {:justification => :left}, :justification => :center, :width => 30}, 
                                "ITU Bed Booked?" => {:heading => {:justification => :left}, :justification => :center, :width => 30}, 
                                "Comments? Infected Weight if Paed" => {:heading => {:justification => :center}, :justification => :left, :width => 80}, 
                                "Checklist Complete?" => {:heading => {:justification => :left}, :justification => :center, :width => 30}, 
                                "Outcome O/C/D Code" => {:heading => {:justification => :center}, :justification => :left, :width => 80}, 
                                "Reason" => {:heading => {:justification => :center}, :justification => :left, :width => 90} })
                                                                        
    end
  end

  formatter :csv do
    build :list do
      data.rename_columns("appdate" => "Appointment Date", "intern" => "Intern", "surg" => "Surgeon", "theatre" => "Theatre", "start" => "Planned Start Time", "duration" => "Actual Time")
      output << data.to_csv
    end
  end
end
