class GGn
  include HTTParty
  base_uri $redis.hget(:ggn, :base_uri)

  ROW_REGEX = /<tr class="group_.*?">\s*<td colspan="3">.*?<\/tr>/m

  def self.items
    response = get($redis.hget(:ggn, :browse_path), verify: false,
      headers: {'cookie' => $redis.hget(:ggn, :cookie)}
    )
    response.scan(ROW_REGEX).map{|row| Item.from_row(row)}
  rescue HTTParty::RedirectionTooDeep => e
    raise e.response.location.match('login.php') ? 'Session Expired' : e
  end

private

  def self.reset_cookie # To be manually run from pry
    response = get('/login.php', verify: false)
    #raise "CAPTCHA Required" if response.match('captcha')
    print 'Username: '; username = gets.strip
    print 'Password: '; password = gets.strip

    # Using :limit => 1 causes an exception in HTTParty if the request
    # returns a 302. The pre-exception response has the cookie we want.
    post('/login.php', verify: false, limit: 1, body: {
      username: username, password: password, keeplogged: 1
    })
  rescue HTTParty::RedirectionTooDeep => e
    response = e.response
    raise "Login Failed" if response['location'].match('login')
    cookie = response['set-cookie'].split(/;|,/).select{|part|
             part.match(/__cfduid|PHPSESSID|session/)}.join(';')
    $redis.hset(:ggn, :cookie, cookie)
    cookie
  end

end
