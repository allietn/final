# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Database schema - this should reflect your domain model
DB.create_table! :projects do
  primary_key :id
  String :title
  String :description, text: true
  String :date
  String :time
  String :location
end
DB.create_table! :volunteer do
  primary_key :id
  foreign_key :project_id
  foreign_key :user_id
  Boolean :going
  String :comments, text: true
end
DB.create_table! :users do
  primary_key :id
  String :name
  String :email
  String :password
end

# Insert initial (seed) data
projects_table = DB.from(:projects)

projects_table.insert(title: "Plan a pizza party for Kellogg staff", 
                    description: "Help organize a pizza party to show Kellogg staff our appreciation.",
                    date: "June 30th",
                    time: "3:00PM CST",
                    location: "Kellogg Global Hub")

projects_table.insert(title: "Plant flowers around Evanston", 
                    description: "Join a group of Kellogg students to network and beautify our town.",
                    date: "July 4th",
                    time: "10:00AM CST",
                    location: "Evanston Target")