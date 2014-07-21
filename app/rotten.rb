require 'bundler'
Bundler.require

load '.env' if File.exists?('.env')
redistogo = URI.parse ENV['REDISTOGO_URL']
$redis = Redis.new(:host => redistogo.host,
                   :port => redistogo.port,
                   :password => redistogo.password)

require_relative 'sites/cbt.rb'

class RottenApp < Sinatra::Base

  get '/cbt.rss' do
    content_type 'text/xml'
    haml :rss, locals: {sources: CBT.sources}, :escape_html => true
  end

  run! if app_file == $0
end
