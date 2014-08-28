class WCD
  include HTTParty
  base_uri $redis.hget(:wcd, :base_uri)

  ROW_REGEX = /<tr class="group[^"]*?">.*?<\/tr>/m

  def self.items
    response = get("/#{$format}s.php", verify: false,
      headers: {'cookie' => $redis.hget(:wcd, :cookie)}
    )
    # raise "Session Expired" if response.match('login.php')
    response.scan(ROW_REGEX).slice_before{
      |row| row.match(/^<tr class="group">/)
    }.map{|group| Item.from_row_group(group)}.flatten
  end

  class Item < OpenStruct
    COL_REGEX = /<td.*?<\/td>/m
    CONTENT = />(.*?)</m

    def self.from_row_group(row_group)
      title, edition = row_group.shift.scan(COL_REGEX)[2].scan(CONTENT)[0..5].join.gsub(/\s+/, ' ').strip
      row_group.map do |row|
        if row.match(/^<tr class=".*?edition">/)
          edition = row.scan(CONTENT)[4].join.strip; nil
        else
          cols = row.scan(COL_REGEX)
          version = cols[0].scan(CONTENT)[7..-1].join.strip
          self.new(
            title: [title, edition, version].join(', '),
            link:  CGI.unescape_html([WCD.base_uri,'/',cols[0].scan(/<a.*?href="([^"]*?)".*?>/m)[0]].join),
            size:  cols[3].scan(CONTENT).join.to_bytes,
            total: cols[4].scan(CONTENT).join.to_i,
            up:    cols[5].scan(CONTENT).join.to_i,
            down:  cols[6].scan(CONTENT).join.to_i,
            date:  Time.parse(cols[2].scan(/title="([^"]*?)"/).join)
          )
        end
      end.compact
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
    $redis.hset(:wcd, :cookie, cookie)
    cookie
  end

end
