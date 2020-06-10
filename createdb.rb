# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Database schema - this should reflect your domain model
DB.create_table! :events do
  primary_key :id
  String :title
  String :description, text: true
  String :date
  String :location
end
DB.create_table! :rsvps do
  primary_key :id
  foreign_key :event_id
  Boolean :going
  String :name
  String :email
  String :comments, text: true
end

# Insert initial (seed) data
projects_table = DB.from(:projects)

projects_table.insert(title: "Pizza Party for Kellogg staff", 
                    description: "Help organize a pizza party to show Kellogg staff our appreciation.",
                    date: "June 30th",
                    location: "Kellogg Global Hub")

projects_table.insert(title: "Plant flowers around Evanston", 
                    description: "Join a group of Kellogg students to network and beautify over town.",
                    date: "July 4th",
                    location: "Kellogg Global Hub")
