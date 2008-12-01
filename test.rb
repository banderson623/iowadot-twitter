#!ruby
require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'chronic'
 
class RoadCondition
  attr_accessor :label,:location, :description, :date
  def type
    @label.split('-').first.strip
  end
  
  def road
    @label.split('-').last.strip
  end
  
  def nice_date
    @date.strftime("%m/%d/%Y %I:%M%p")
  end
  
  def older_than?(some_date)
    # puts "comparing #{date} to #{some_date}"
    return date < some_date
  end
  
  def to_s
    "#{type.upcase} on #{location}. #{description}"
  end
end 

conditions=[]

last_update = Chronic.parse('yesterday at 10pm')
puts "last update: #{last_update} #{last_update.class}"

# http://www.511ia.org/default.asp?area=IA_statewide&display=all&date=&textOnly=true
# http://www.511ia.org/default.asp?display=all&area=IA_Central&date=&textOnly=True
# File.readlines('test.html').to_s
doc = Hpricot(open("http://www.511ia.org/default.asp?display=all&area=IA_Central&date=&textOnly=True"))
table_rows = (doc/"table/tr").reject{|r| r.attributes['class'].nil? || r.attributes['class'] == 'spacer'};
# table_rows = table_rows[0..250]
# table_rows.each{|r| puts r.attributes['class']}

i=0
while(i < (table_rows.size - 1)) do
  # puts i
    rc = RoadCondition.new
    rc.label = (table_rows[i]/"td/font/b").inner_html.strip
    rc.location = (table_rows[i+1]/"td/font/b").inner_html.strip
    rc.description = (table_rows[i+1]/"td/font/*")[2].to_s.strip
    rc.date = Chronic.parse((table_rows[i+1]/"td/font/*").last.to_s.gsub('last updated','').strip, :context => :past)
    conditions << rc
  i+=2
end

# puts conditions.inspect

# puts conditions[1].type
conditions = conditions.reject{|c| c.older_than?(last_update)}

conditions.each do |c|
  puts c.to_s
end


