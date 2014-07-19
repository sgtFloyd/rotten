require 'sinatra'

class RottenApp < Sinatra::Base
  get '/' do
    "Hello World!"
  end

  run! if app_file == $0
end