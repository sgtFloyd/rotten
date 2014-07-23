class GGn
  include HTTParty
  base_uri $redis.hget(:ggn, :base_uri)

  COL_REGEX = /<td.*?<\/td>/m

  def self.items
    response = get($redis.hget(:ggn, :browse_path), verify: false,
      headers: {'cookie' => $redis.hget(:ggn, :cookie)}
    )
    (response.scan(ROW_REGEX).map{|row| Item.from_row(row)} +
      response.scan(ALT_ROW_REGEX).map{|row| Item.from_alt_row(row)}
    ).sort_by(&:date).reverse
  rescue HTTParty::RedirectionTooDeep => e
    raise e.response.location.match('login.php') ? 'Session Expired' : e
  end

  class Item < OpenStruct
    CONTENT = />(.*?)</m

    def self.from_row(row)
      cols = row.scan(COL_REGEX)
      self.from_cols(cols[2..-1])
    end

    def self.from_alt_row(alt_row)
      cols = alt_row.scan(COL_REGEX)
      self.from_cols(cols)
    end

    def self.from_cols(cols)
      self.new(
        title: CGI.unescape_html(cols[0].scan(CONTENT).join.gsub(/\s+/, ' ').strip),
        link:  CGI.unescape_html([GGn.base_uri,'/',cols[0].scan(/<a.*?href="([^"]*?)".*?>/m)[0]].join),
        size:  cols[4].scan(CONTENT).join,
        total: cols[5].scan(CONTENT).join.to_i,
        up:    cols[6].scan(CONTENT).join.to_i,
        down:  cols[7].scan(CONTENT).join.to_i,
        date:  Time.parse(cols[2].scan(/title="([^"]*?)"/).join)
      )
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
