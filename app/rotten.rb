require 'bundler'
Bundler.require

load '.env' if File.exists?('.env')
redistogo = URI.parse ENV['REDISTOGO_URL']
$redis = Redis.new(:host => redistogo.host,
                   :port => redistogo.port,
                   :password => redistogo.password)
$format = ENV['FORMAT']

require './app/core_ext.rb'
Dir['./app/sites/*.rb'].each &method(:require)
load '.filters.rb' if File.exists?('.filters.rb')

class RottenApp < Sinatra::Base
  before do
    pass if request.path == '/ping'
    error 401 unless params[:auth] == ENV['AUTH_KEY']
  end

  def rss(items)
    content_type 'text/xml'
    haml :rss, locals: {items: items}, :escape_html => true
  end

  get('/cbt.rss'){ rss CBT.items }
  get('/ggn.rss'){ rss GGn.items }
  get('/bib.rss'){ rss BiB.items }

  get '/files/bib/:id' do
    attachment "#{params[:id]}.#{$format}"
    BiB.file(params[:id])
  end

  get('/ping'){'PONG'}
  run! if app_file == $0
end
