require 'scraperwiki'
require 'mechanize'

agent = Mechanize.new

vote_event_url = "http://w1.c1.rada.gov.ua/pls/radan_gs09/ns_golos?g_id=3106"
vote_event_page = agent.get(vote_event_url)

# Vote results by faction
vote_event_page.search("#01 ul.fr > li").each do |faction|
  faction_name = faction.at(:b).inner_text

  faction.search(:li).each do |li|
    p record = {faction_name: faction_name,
       name: li.at(".dep").text,
       vote: li.at(".golos").text}
  end
end
