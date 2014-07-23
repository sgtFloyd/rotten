class GGn
  include HTTParty
  base_uri $redis.hget(:ggn, :base_uri)

  COL_REGEX = /<td.*?<\/td>/m

  def self.items
    response = get($redis.hget(:ggn, :browse_path), verify: false,
      headers: {'cookie' => $redis.hget(:ggn, :cookie)}
    )
    response.scan(ROW_REGEX).map{|row| Item.from_row(row)} +
      response.scan(ALT_ROW_REGEX).map{|row| Item.from_alt_row(row)}
  rescue HTTParty::RedirectionTooDeep => e
    raise e.response.location.match('login.php') ? 'Session Expired' : e
  end

  class Item < OpenStruct
    CONTENT = />(.*?)</m

    def self.from_row(row)
      cols = row.scan(COL_REGEX)
      self.new(
        title: cols[2].scan(CONTENT).join.gsub(/\s+/, ' ').strip,
        link:  [GGn.base_uri,'/',cols[2].scan(/<a.*?href="(.*?)".*?>/m)[0]].join,
        size:  cols[6].scan(CONTENT).join,
        total: cols[7].scan(CONTENT).join.to_i,
        up:    cols[8].scan(CONTENT).join.to_i,
        down:  cols[9].scan(CONTENT).join.to_i,
        date:  Time.parse(cols[4].scan(/title="(.*?)"/).join),
      )
    end

    def self.from_alt_row(alt_row)
    end
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
