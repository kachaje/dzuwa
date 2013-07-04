Given /^no current user$/ do
  @username = nil
end

Given "a username '$username'" do |username|
  @username = username
end

Given "a password '$password'" do |password|
  @password = password
end

When /^the user accesses a page$/ do
  get "/"
end

When "the user logs in with username and password" do
  login_user(@username, @password)
end
  
Then /^should redirect to '\/user\/login'$/ do
  visit "/user/login"
end

Then "the login form should be shown again" do
  response.should render_template("user/login")
end

Then "should show message '$message'" do |message|
  response.should have_text(/#{message}/)  
end
