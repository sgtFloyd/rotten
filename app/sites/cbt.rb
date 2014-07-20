class CBT
  include HTTParty
  base_uri $redis.hget(:cbt, :base_uri)

  def self.sources
    response = get('/browse.php', headers: {
      "Cookie" => $redis.hget(:cbt, :cookie)}
    )
    raise "Session Expired" if response.match('takelogin.php')
    require 'pry'; binding.pry
  end

private

  def self.reset_cookie
    response = get('/login.php')
    raise "CAPTCHA Required" if response.match('captcha')

    print 'Username: '; username = gets.strip
    print 'Password: '; password = gets.strip
    response = post('/takelogin.php', body: {
      username: username, password: password
    })
    cookie = response.request.options[:headers]['Cookie']
    $redis.hset :cbt, :cookie, cookie
    cookie
  end

end
