Feature: Extract Reports
	As a user
	I want to extract reports from the system
	So that I can analyse the data collected
	
	Scenario: Logged in User Requests for Reports
		Given a logged in user
		When they try to access reports page
		Then they should be able to view reports
		And print them if they want to
