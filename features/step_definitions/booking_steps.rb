Given "a logged in user" do
  login_user("supuse", "supuse")
end

Given /^I have a booked patient$/ do
  get_patient_appointment(100)
end

When /^I access the booking page$/ do
  get '/encounters/appointment'
end

When /^the appointment is not possible$/ do
  get '/encounters/edit_appointment'
end

Then /^I should be able to make a booking$/ do
  get '/encounters/create_appointment'
end

Then /^I should be able to cancel the appointment$/ do
  get '/encounters/cancel_appointment'
end

Then /^notify all stakeholders$/ do
  get '/encounters/show'
end

