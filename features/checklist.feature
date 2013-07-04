Feature: Fill Surgical Safety Checklist
	As a logged in user
	I want to access the surgical safety checklist
	So that I can add information for a coming operation
	
	Scenario: Before Induction of Anaesthesia
		Given I have a booked patient
		When I access a new checklist
		Then I should be able to fill in the first set of details
		
	Scenario: Before Skin Incission
		Given I have a booked patient with the initial checklist filled
		When I access checklist
		Then I should be able to fill in the second set of details
		
	Scenario: Before Patient Leaves Operating Room
		Given I have a booked patient with the first two datasets filled
		When I access checklist
		Then I should be able to fill in the last set of details
