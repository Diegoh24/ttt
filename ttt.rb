# ttt
require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "yaml"
require "bcrypt"

configure do
  enable :sessions
  set :session_secret, "super secret"
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data",__FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def create_account(user, pass)
  bcrypt_password = BCrypt::Password.create(pass).to_s
  users = load_game_data

  users[user] = {password: bcrypt_password, games: [] }

  users_path = File.join(data_path, "players.yml")
  File.open(users_path, 'w') do |file|
    file.write(Psych.dump_stream(users))
  end
end

def load_game_data
  path = ENV["RACK_ENV"] == 'test' ? "../test/players.yml" : "../data/players.yml"
  open_credentials_path = File.expand_path(path, __FILE__)
  YAML.load_file(open_credentials_path)
end

def player_exists?(player)
  players = load_game_data
  players.keys.any?(player)
end

def valid_credentials?(user, password)
  users = load_game_data

  if users.key?(user)
    bcrypt_password = BCrypt::Password.new(users[user][:password])
    bcrypt_password == password
  end
end

def require_signed_in_user
  return if session[:username]
  session[:message] = "You must be signed in to do that"
  redirect "/signin"
end

def save_game_results
  game_data = load_game_data
  user = session[:username]
  game_data[user][:games] << session[:game]

  game_data_path = File.join(data_path, "players.yml")
  File.open(game_data_path, 'w') do |file|
    file.write(Psych.dump_stream(game_data))
  end
end

def winning_lines
[[1, 2, 3], [4, 5, 6], [7, 8, 9]] +
[[1, 4, 7], [2, 5, 8], [3, 6, 9]] +
[[1, 5, 9], [3, 5, 7]]
end

helpers do
  def marker(square)
    if marked?(square)
      player_squares.include?(square) ? "X" : "O"
    else
      board_full? || winner? ? "" : "Pick Square"
    end
  end

  def marked_squares
    player_squares + computer_squares
  end

  def player_squares
    session[:game][:squares]
  end

  def computer_squares
    session[:game][:computer_squares]
  end

  def marked?(square)
    marked_squares.include?(square)
  end

  def user_marks(square)
    session[:game][:squares] << square
  end

  def computer_marks_square
    unmarked_square = (1..9).to_a.reject { |square| marked?(square) }.sample
    session[:game][:computer_squares] << unmarked_square
  end

  def end_game
    if board_full? || winner?
      save_game_results
      redirect "/end"
    end
  end

  def board_full?
    (1..9).all? { |square| marked?(square) }
  end

  def winner
    if player_squares.include?(winning_line.first)
      session[:username]
    else
      "Computer"
    end
  end

  def winning_line
    winning_lines.any? do |line|
      return line if line.all? { |square| player_squares.include?(square) } ||
                     line.all? { |square| computer_squares.include?(square) }
    end
  end
end

# ROUTES ---

# home page, redirects to sign in
get "/" do
  redirect "/signin" unless session[:username]
  redirect "/game"
end

# sign in page
get "/signin" do
  erb :signin
end

# sign up form
get "/users/signup" do
  erb :signup
end

# submit sign up form
post "/users/signup" do
  username = params[:username]
  password = params[:password]

  if player_exists?(username)
    session[:message] = "Username already in use. Please pick a different player name"
    erb :signup
  else
    create_account(username, password)
    session[:message] = "Your account has been created. Log in to play"
    redirect "/"
  end
end

# submit sign in form
post "/signin" do
  username = params[:username]
  password = params[:password]

  if valid_credentials?(username, password)
    session[:message] = "Welcome #{username}"
    session[:username] = username
    redirect "/game"
  else
    session[:message] = "Invalid credentials"
    status 422
    erb :signin
  end
end

# main game page
get "/game" do
  require_signed_in_user
  erb :main_page
end

# submit player start form
post "/board/playerstart" do
  require_signed_in_user
  session[:game] = {squares: [], computer_squares: []}

  erb :board
end

# submit computer start form
post "/board/computerstart" do
  session[:game] = {squares: [], computer_squares: []}

  computer_marks_square

  erb :board
end

# load the board template
get "/board" do
  require_signed_in_user
  erb :board
end

# load the board after the game is over
get "/end" do
  require_signed_in_user
  erb :gameover
end

# mark a square on the board
get "/board/:square" do
  require_signed_in_user
  square = params[:square].to_i

  if marked?(square)
    session[:message] = "Square is already marked! Pick another square."
    redirect "/board"
  end

  user_marks(square)
  end_game if game_over?

  computer_marks_square
  end_game if game_over?

  erb :board
end

# submit sign out form button, signs use out
post "/signout" do
  require_signed_in_user
  session.delete :username
  session.delete :game
  session[:message] = "You have been signed out"
  redirect "/"
end

# show user game history
get "/game_history" do
  require_signed_in_user
  @games = load_game_data[session[:username]][:games]
  erb :game_logs
end

# show game results of game x
get "/game_history/:id" do
  require_signed_in_user
  game_id = params[:id].to_i
  games = load_game_data[session[:username]][:games]
  session[:game] = games[game_id]
  session[:history] = true

  erb :gameover
end

# invalid url
not_found do
  "That page was not found"
end