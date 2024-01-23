# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
* <h1>Leave Status Notification</h1>
<p>Dear <%= @employee.name %>,</p>
<p>Regarding your leave request: <%=@holiday.description%></br>from: <%=@holiday.start_date%>&nbsp; to:<%=@holiday.end_date%></p>
<p>Status: <%= @message %></p>
<p>Thank you.</p>        
    