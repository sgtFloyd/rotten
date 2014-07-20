require 'bundler'
Bundler.require

load '.env' if File.exists?('.env')

class RottenApp < Sinatra::Base
  configure do
    redistogo = URI.parse ENV['REDISTOGO_URL']
    set :redis => Redis.new(:host => redistogo.host,
                            :port => redistogo.port,
                            :password => redistogo.password)
  end
  $redis = settings.redis

  get '/cbt.rss' do
    begin
      CBT.sources.each do # ...
      end
    rescue => e
    end
  end

  run! if app_file == $0
end

require_relative 'sites/cbt.rb'
