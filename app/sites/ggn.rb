class GGn
  include HTTParty
  base_uri $redis.hget(:ggn, :base_uri)

  def self.items
    response = get('/browse.php', verify: false,
      headers: {'cookie' => $redis.hget(:ggn, :cookie)}
    )

    # raise "Session Expired" if response.match('login.php')
    # response.scan(ROW_REGEX).map{|row| Item.from_row(row)}
  end

private

  def self.reset_cookie # To be manually run from pry
    response = get('/login.php', verify: false)
    #raise "CAPTCHA Required" if response.match('captcha')
    print 'Username: '; username = gets.strip
    print 'Password: '; password = gets.strip

    # Figure out how to POST to HTTPS with HTTParty...
    uri = URI.parse(base_uri+'/login.php')
    options = {use_ssl: true, verify_mode: OpenSSL::SSL::VERIFY_NONE}
    response = Net::HTTP.start(uri.host, uri.port, options) do |http|
      http.request(Net::HTTP::Post.new(uri.request_uri).tap{|request|
        request.set_form_data(username: username, password: password)
      })
    end
    cookie = response['set-cookie'].split(/;|,/).select{|part|
             part.match(/__cfduid|PHPSESSID|session/)}.join(';')
    $redis.hset(:ggn, :cookie, cookie)
    cookie
  end

end
