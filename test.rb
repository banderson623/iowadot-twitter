#!ruby
require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'chronic'
require 'twitter'
require 'password'

class RoadCondition
  attr_accessor :label,:location, :description, :date, :color
  FROM = 'http://bit.ly/R0eg'
  def type
    @label.split('-').first.strip
  end
  
  def road
    @label.split('-').last.strip
  end
  
  def nice_date
    @date.strftime("%I:%M%p")
  end
  
  def level
    case @color
    when "FF0000"
      :red
    when "FF99FF"
      :purple
    when "FF9933"
      :orange
    when "FFFF00"
      :yellow
    when "0000FF"
      :blue
    end
  end
  
  def level_to_i
    case level
    when :red
      5
    when :orange
      4
    when :purple
      3
    when :blue
      2
    when :yellow
      1
    else
      0
    end
  end
  
  def older_than?(some_date)
    # puts "comparing #{date} to #{some_date}"
    return date < some_date
  end
    
  def to_s
    "#{type.upcase} on #{location}. #{description} (#{nice_date})"
  end
end 

conditions=[]

last_update = Chronic.parse('10400 minutes ago')
puts "last update: #{last_update} #{last_update.class}"

# http://www.511ia.org/default.asp?area=IA_statewide&display=all&date=&textOnly=true
# http://www.511ia.org/default.asp?display=all&area=IA_Central&date=&textOnly=True
# doc = Hpricot(File.readlines('test.html').to_s)
doc = Hpricot(open("http://www.511ia.org/default.asp?display=all&area=IA_Central&date=&textOnly=True"))

# Read how to produce the HTTP Request Header at:
#    http://www.ruby-doc.org/stdlib/libdoc/open-uri/rdoc/classes/OpenURI.html

table_rows = (doc/"table/tr").reject{|r| r.attributes['class'].nil? || r.attributes['class'] == 'spacer'};

i=0
while(i < (table_rows.size - 1)) do
  rc = RoadCondition.new
  rc.label = (table_rows[i]/"td/font/b").inner_html.strip
  rc.color = (table_rows[i]/"td").first.attributes['bgcolor']
  rc.location = (table_rows[i+1]/"td/font/b").inner_html.strip
  rc.description = (table_rows[i+1]/"td/font/*")[2].to_s.strip
  rc.date = Chronic.parse((table_rows[i+1]/"td/font/*").last.to_s.gsub('last updated','').strip, :context => :past)
  conditions << rc
  i+=2
end

conditions = conditions.reject{|c| c.older_than?(last_update) or c.level_to_i <= 3}

conditions.each do |c|
  puts c.to_s
  # Twitter::Base.new(TWITTER_EMAIL, TWITTER_PASSWORD).update(c.to_s)
end


