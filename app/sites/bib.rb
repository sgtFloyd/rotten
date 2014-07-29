class BiB
  include HTTParty
  base_uri $redis.hget(:bib, :base_uri)

  ROW_REGEX = /<tr id="#{$format}-\d+".*?<\/tr>/m

  def self.items
    response = get("/#{$format}s",
      headers: {'Cookie' => $redis.hget(:bib, :cookie)}
    )
    raise "Session Expired" if response.match('loginform')
    response.scan(ROW_REGEX).map{|row| Item.from_row(row)}
  end

  def self.file(file_id)
    response = get("/#{$format}s/#{file_id}/download",
      headers: {'Cookie' => $redis.hget(:bib, :cookie)}
    )
    raise "Session Expired" if response.match('loginform')
    raise "Unsuccessful Request" unless response.success?
    response.body
  end

  class Item < OpenStruct
    COL_REGEX = /<td.*?>.*?<\/td>/m
    CONTENT = />(.*?)</m

    def self.from_row(row)
      cols = row.scan(COL_REGEX)
      self.new(
        title: cols[1].scan(/<a.*?>.*?<\/a>/m)[0..1].join(' - ').scan(CONTENT).join,
        link:  [ENV['BASE_URI'],'/files/bib/',row.scan(/id="#{$format}-(\d+)"/),'?auth=',ENV['AUTH_KEY']].join,
        size:  cols[4].scan(/[^,]*?,(.*?)<br/m).join.strip,
        total: cols[6].scan(CONTENT).join.strip.to_i,
        up:    cols[7].scan(CONTENT).join.strip.to_i,
        down:  cols[8].scan(CONTENT).join.strip.to_i,
        date:  Time.parse(cols[4].scan(/datetime="([^"]*?)"/m).join)
      )
    end
  end

private

  def self.reset_cookie
    response = get('/login')
    raise "CAPTCHA Required" if response.match('captcha')

    print 'Username: '; username = gets.strip
    print 'Password: '; password = gets.strip
    response = post('/login', body: {
      username: username, password: password, keeplogged: 1
    })
    cookie = response.request.options[:headers]['Cookie']
    $redis.hset(:bib, :cookie, cookie)
    cookie
  end

end
