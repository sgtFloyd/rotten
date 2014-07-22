class GGn
  include HTTParty
  base_uri $redis.hget(:ggn, :base_uri)

  def self.sources
    # response = get('/browse.php', headers: {
    #   "Cookie" => $redis.hget(:ggn, :cookie)
    # })
    # raise "Session Expired" if response.match('login.php')
    # response.scan(ROW_REGEX).map{|row| Source.from_row(row)}
  end

private

  def self.reset_cookie # To be manually run from pry
    response = get('/login.php', verify: false)
    #raise "CAPTCHA Required" if response.match('captcha')

    print 'Username: '; username = gets.strip
    print 'Password: '; password = gets.strip

    # Figure out how to POST to HTTPS with HTTParty...
    uri = URI.parse(base_uri+"/login.php")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data(
      "username" => username, "password" => password
    )
    response = http.request(request)
    cookie = response['set-cookie']
  end

end
