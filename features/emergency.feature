Feature: Fill in Emergency Operation List
	As a logged in user
	I want to access the form
	So that I can register an emergency operation done
	
	Scenario: There Exists an Unregistered Emergency Operation
		Given I have and unregistered emergency operation
		When I access the registering form
		Then I should be able to register the emergency operation
