require 'bundler'
Bundler.require

load '.env' if File.exists?('.env')
redistogo = URI.parse ENV['REDISTOGO_URL']
$redis = Redis.new(:host => redistogo.host,
                   :port => redistogo.port,
                   :password => redistogo.password)

require_relative 'sites/cbt.rb'
require_relative 'sites/ggn.rb'

class RottenApp < Sinatra::Base

  before do
    error 401 unless params[:auth] == ENV['AUTH_KEY']
  end

  get '/cbt.rss' do
    content_type 'text/xml'
    haml :rss, locals: {items: CBT.items}, :escape_html => true
  end

  get '/ggn.rss' do
    content_type 'text/xml'
    haml :rss, locals: {items: GGn.items}, :escape_html => true
  end

  run! if app_file == $0
end
