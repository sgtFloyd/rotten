require 'bundler'
Bundler.require

load '.env' if File.exists?('.env')
redistogo = URI.parse ENV['REDISTOGO_URL']
$redis = Redis.new(:host => redistogo.host,
                   :port => redistogo.port,
                   :password => redistogo.password)

Dir['./app/sites/*.rb'].each &method(:require)

class RottenApp < Sinatra::Base
  before do
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
    attachment "#{params[:id]}.#{ENV['FORMAT']}"
    BiB.file(params[:id])
  end

  run! if app_file == $0
end
