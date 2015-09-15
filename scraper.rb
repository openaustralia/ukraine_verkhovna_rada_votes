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

def ua_result_to_popolo(string)
  case string
  when "Рішення прийнято"
    "pass"
  when "Рішення не прийнято"
    "fail"
  else
    raise "Unknown vote_event result: #{string}"
  end
end

# TODO: ScraperWiki::sqliteexecute("BEGIN TRANSACTION")

agent = Mechanize.new

base_url = "http://w1.c1.rada.gov.ua/pls/radan_gs09/ns_golos?g_id="
vote_event_id = "3106"
vote_event_url = base_url + vote_event_id
puts "Fetching vote event page: #{vote_event_url}"
vote_event_page = agent.get(vote_event_url)

vote_event = {
  # Setting this to what EveryPolitician is generating. Maybe it's wrong?
  organization_id: "legislature",
  identifier: vote_event_id,
  title: vote_event_page.at(".head_gol font").text.strip,
  # TODO: Do we need to worry about time zone?
  start_date: DateTime.parse(vote_event_page.at(".head_gol").search(:br).first.next.text),
  result: ua_result_to_popolo(vote_event_page.search(".head_gol font").last.text)
}
ScraperWiki::save_sqlite([:identifier], vote_event, :vote_events)

# Vote results by faction
vote_event_page.search("#01 ul.fr > li").each do |faction|
  faction_name = faction.at(:b).inner_text

  faction.search(:li).each do |li|
    vote = {
      vote_event_id: vote_event_id,
      # TODO: Replace name with this
      # voter_id: "john-q-public",
      name: li.at(".dep").text,
      option: ua_vote_to_popolo_option(li.at(".golos").text)
    }
    # TODO: ScraperWiki::save_sqlite([:vote_event_id, :voter_id], vote, :votes)
  end
end

# TODO: ScraperWiki::sqliteexecute("COMMIT")
