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

def morph_scraper_query(scraper_name, query)
  url = "https://api.morph.io/#{scraper_name}/data.json?key=#{ENV['MORPH_API_KEY']}&query=#{CGI.escape(query)}"
  JSON.parse(open(url).read)
end

def full_name_to_abbreviated(full_name)
  parts = full_name.split
  # On the site the last initial becomes a blank space if they don't have a middle name
  last_initial = parts[2] ? parts[2][0] : " "
  "#{parts[0]} #{parts[1][0]}.#{last_initial}."
end

ScraperWiki::sqliteexecute("BEGIN TRANSACTION")

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

  puts "Fetching deputy IDs from morph.io for faction: #{faction_name}"
  name_ids = morph_scraper_query("openaustralia/ukraine_verkhovna_rada_deputies", "select name, id from 'data' where faction='#{faction_name}'")
  p name_ids # TODO: Remove debugging

  puts "Saving votes for faction: #{faction_name}"
  faction.search(:li).each do |li|
    voter_name = li.at(".dep").text.gsub("’", "'")
    puts "Saving vote by #{voter_name}..."

    # FIXME: This isn't working yet
    # The current problem I have is that we're not yet scraping historical faction data.
    # This means that the name/faction thing doesn't match up
    voter_id = name_ids.find { |r| full_name_to_abbreviated(r["name"]) == voter_name }["id"]

    vote = {
      vote_event_id: vote_event_id,
      voter_id: voter_id,
      option: ua_vote_to_popolo_option(li.at(".golos").text)
    }
    ScraperWiki::save_sqlite([:vote_event_id, :voter_id], vote, :votes)
  end
end

ScraperWiki::sqliteexecute("COMMIT")
