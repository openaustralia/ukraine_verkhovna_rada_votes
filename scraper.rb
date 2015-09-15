require 'scraperwiki'
require 'mechanize'

# Convert Ukrainian vote string to Popolo vote option string
def ua_vote_to_popolo_option(string)
  case string
  when "За"
    "yes"
  when "Проти"
    "no"
  when "Утрималися"
    "abstain"
  when "Не голосували"
    "not voting"
  when "Відсутні"
    "absent"
  else
    raise "Unknown vote option: #{string}"
  end
end

agent = Mechanize.new

vote_event_url = "http://w1.c1.rada.gov.ua/pls/radan_gs09/ns_golos?g_id=3106"
puts "Fetching vote event page: #{vote_event_url}"
vote_event_page = agent.get(vote_event_url)

# TODO: Save vote_event data

# Vote results by faction
vote_event_page.search("#01 ul.fr > li").each do |faction|
  faction_name = faction.at(:b).inner_text

  faction.search(:li).each do |li|
    p record = {faction_name: faction_name,
       name: li.at(".dep").text,
       vote: li.at(".golos").text}
  end
end
