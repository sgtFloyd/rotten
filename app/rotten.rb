require 'bundler'
Bundler.require

load '.env' if File.exists?('.env')
redistogo = URI.parse ENV['REDISTOGO_URL']
$redis = Redis.new(:host => redistogo.host,
                   :port => redistogo.port,
                   :password => redistogo.password)

class RottenApp < Sinatra::Base

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
