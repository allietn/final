# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "twilio-ruby"                                                                 #
require "geocoder"                                                                    #
require "bcrypt"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

projects_table = DB.from(:projects) 
volunteer_table = DB.from(:volunteer)
users_table = DB.from(:users)


before do
    # SELECT * FROM users WHERE id = session[:user_id]
    @current_user = users_table.where(:id => session[:user_id]).to_a[0]
    puts @current_user.inspect
end

# Home page (all projects)
get "/" do
    # before stuff runs
    @projects = projects_table.all
    view "projects"
end

# Show a single project
get "/projects/:id" do
    @users_table = users_table
    # SELECT * FROM projects WHERE id=:id
    @projects = projects_table.where(:id => params["id"]).to_a[0]
    # SELECT * FROM volunteer WHERE project_id=:id
    @volunteer = volunteer_table.where(:project_id => params["id"]).to_a
    # SELECT COUNT(*) FROM volunteer WHERE project_id=:id AND going=1
    @count = volunteer_table.where(:project_id => params["id"], :going => true).count
    # Geocoder/Google Maps API
    results = Geocoder.search(@projects[:location])
    @lat_long = results.first.coordinates.join(",")
    view "project"
end

# Form to create a new volunteer response
get "/projects/:id/volunteer/new" do
    @project = projects_table.where(:id => params["id"]).to_a[0]
    view "new_volunteer"
end

# Receiving end of new volunteer form
post "/projects/:id/volunteer/create" do
    volunteer_table.insert(:project_id => params["id"],
                       :going => params["going"],
                       :user_id => @current_user[:id],
                       :comments => params["comments"])
    @project = projects_table.where(:id => params["id"]).to_a[0]

    # read your API credentials from environment variables
    account_sid = ENV["TWILIO_ACCOUNT_SID"]
    auth_token = ENV["TWILIO_AUTH_TOKEN"]

    # set up a client to talk to the Twilio REST API
    client = Twilio::REST::Client.new(account_sid, auth_token)

    # send the SMS from your trial Twilio number to your verified non-Twilio number
    client.messages.create(
    from: "+12029320806", 
    to: "+17038672902",
    body: "Reminder: You have a volunteering event coming up :)")

    view "create_volunteer"
end

# Form to create a new user
get "/users/new" do
    view "new_user"
end

# Receiving end of new user form
post "/users/create" do
    puts params.inspect
    users_table.insert(:name => params["name"],
                       :email => params["email"],
                       :password => BCrypt::Password.create(params["password"]))
    view "create_user"
end

# Form to login
get "/logins/new" do
    view "new_login"
end

# Receiving end of login form
post "/logins/create" do
    puts params
    email_entered = params["email"]
    password_entered = params["password"]
    # SELECT * FROM users WHERE email = email_entered
    user = users_table.where(:email => email_entered).to_a[0]
    if user
        puts user.inspect
        # test the password against the one in the users table
        if BCrypt::Password.new(user[:password]) == password_entered
            session[:user_id] = user[:id]
            view "create_login"
        else
            view "create_login_failed"
        end
    else 
        view "create_login_failed"
    end
end

# Logout
get "/logout" do
    session[:user_id] = nil
    view "logout"
end
