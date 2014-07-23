class CBT
  include HTTParty
  base_uri $redis.hget(:cbt, :base_uri)

  ROW_REGEX = /#{$redis.hget :cbt, :row_regex}/m

  def self.items
    response = get($redis.hget(:cbt, :browse_path),
      headers: {'Cookie' => $redis.hget(:cbt, :cookie)}
    )
    raise "Session Expired" if response.match('takelogin.php')
    response.scan(ROW_REGEX).map{|row| Item.from_row(row)}
  end

  class Item < OpenStruct
    COL_REGEX = /<td class='.*?'>(.*?)<\/td>/m
    CONTENT = />(.*?)</m

    def self.from_row(row)
      cols = row.scan(COL_REGEX)
      self.new(
        title: cols[1][0].scan(CONTENT).join.gsub('&nbsp;', ' ').strip,
        link:  [CBT.base_uri,'/',cols[3][0].scan(/<a href='(.*?)'/m)[1]].join,
        size:  cols[6][0].scan(CONTENT).join,
        total: cols[7][0].scan(CONTENT).join.to_i,
        up:    cols[8][0].scan(CONTENT).join.to_i,
        down:  cols[9][0].scan(CONTENT).join.to_i,
        date:  Chronic.parse(cols[2].join)
      )
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
