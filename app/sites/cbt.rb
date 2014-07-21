class CBT
  include HTTParty
  base_uri $redis.hget(:cbt, :base_uri)

  ROW_REGEX = /<tr class="(?:even|odd)">.*?<\/tr>/m
  def self.sources
    response = get('/browse.php', headers: {
      "Cookie" => $redis.hget(:cbt, :cookie)}
    )
    raise "Session Expired" if response.match('takelogin.php')
    response.scan(ROW_REGEX).map{|row| Source.from_row(row)}
  end

  class Source
    attr_accessor :row
    def self.from_row(row)
      self.row = row
    end

    def to_rss
    end
  end

private

  def self.reset_cookie # To be manually run from pry
    response = get('/login.php')
    raise "CAPTCHA Required" if response.match('captcha')

    print 'Username: '; username = gets.strip
    print 'Password: '; password = gets.strip
    response = post('/takelogin.php', body: {
      username: username, password: password
    })
    cookie = response.request.options[:headers]['Cookie']
    $redis.hset(:cbt, :cookie, cookie)
    cookie
  end

end
