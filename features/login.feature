Feature: Login
	As a user
	I want to login my details
	So that I can access medical records

	Scenario: User is not logged in
		Given no current user
		When the user accesses a page
		Then should redirect to '/user/login' 
		
	Scenario: User uses wrong password
    Given a username 'username'
    And a password 'wrongpassword'
    When the user logs in with username and password
    Then the login form should be shown again
    And should show message 'Invalid username or password'
