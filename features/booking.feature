Feature: Book Patient for Operation
	As a logged in user
	I want to enter patient details
	So that I can book a surgeon, staff, operating room and surgical equipment for a patient's operation
	
	Scenario: Patient not Booked
	    Given a logged in user
		When I access the booking page
		Then I should be able to make a booking
		And notify all stakeholders
		
	Scenario: Patient Booked but Appointment not Possible
		Given I have a booked patient
		When the appointment is not possible
		Then I should be able to cancel the appointment
		And notify all stakeholders
