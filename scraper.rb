require 'scraperwiki'
require 'mechanize'

# Convert Ukrainian vote string to Popolo vote option string
def ua_vote_to_popolo_option(string)
  case string
  when "За"
    "yes"
  when "Проти"
    "no"
  when "Утрималися", "Утримався", "Утрималась"
    "abstain"
  when "Не голосували", "Не голосувала", "Не голосував"
    "not voting"
  when "Відсутні", "Відсутній", "Відсутня"
    "absent"
  else
    raise "Unknown vote option: #{string}"
  end
end

# TODO: ScraperWiki::sqliteexecute("BEGIN TRANSACTION")

agent = Mechanize.new

vote_event_url = "http://w1.c1.rada.gov.ua/pls/radan_gs09/ns_golos?g_id=3106"
puts "Fetching vote event page: #{vote_event_url}"
vote_event_page = agent.get(vote_event_url)

# TODO: Save vote_event data

# Vote results by faction
vote_event_page.search("#01 ul.fr > li").each do |faction|
  faction_name = faction.at(:b).inner_text

  faction.search(:li).each do |li|
    p vote = {
      # TODO: Fill out these values correctly, replacing "name"
      # vote_event_id: "vote-42",
      # voter_id: "john-q-public",
      name: li.at(".dep").text,
      option: ua_vote_to_popolo_option(li.at(".golos").text)
    }
    # TODO: ScraperWiki::save_sqlite([:vote_event_id, :voter_id], vote, :votes)
  end
end

# TODO: ScraperWiki::sqliteexecute("COMMIT")
