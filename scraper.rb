require 'scraperwiki'
require 'mechanize'
require 'open-uri'
require 'json'

# Convert Ukrainian vote string to Popolo vote option string
def ukrainian_vote_to_popolo_option(string)
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

def ukrainian_result_to_popolo(string)
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
  puts "Querying morph.io scraper, #{scraper_name}, for: #{query}"
  url = "https://api.morph.io/#{scraper_name}/data.json?key=#{ENV['MORPH_API_KEY']}&query=#{CGI.escape(query)}"
  JSON.parse(open(url).read)
end

def full_name_to_abbreviated(full_name)
  parts = full_name.split
  # On the site the last initial becomes a blank space if they don't have a middle name
  last_initial = parts[2] ? parts[2][0] : " "
  "#{parts[0]} #{parts[1][0]}.#{last_initial}."
end

def name_to_id(abbreviated_name, faction_name)
  # Special case for 2 people with the same abbreviated name
  # TODO: Remove this hardcoded exception
  if abbreviated_name == "Тимошенко Ю.В."
    case faction_name
    when 'Фракція політичної партії "Всеукраїнське об’єднання "Батьківщина"'
      "1792"
    when 'Фракція  Політичної партії "НАРОДНИЙ ФРОНТ"'
      "18141"
    else
      raise "Unknown faction for special case person #{abbreviated_name}: #{faction_name}"
    end
  else
    @name_ids ||= morph_scraper_query("openaustralia/ukraine_verkhovna_rada_deputies", "select name, id from 'data'")
    @name_ids.find { |r| full_name_to_abbreviated(r["name"]) == abbreviated_name }["id"]
  end
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
  start_date: DateTime.parse(vote_event_page.at(".head_gol").search(:br).first.next.text),
  result: ukrainian_result_to_popolo(vote_event_page.search(".head_gol font").last.text),
  source_url: vote_event_url
}
ScraperWiki::save_sqlite([:identifier], vote_event, :vote_events)

# Vote results by faction
vote_event_page.search("#01 ul.fr > li").each do |faction|
  faction_name = faction.at(:b).inner_text

  puts "Saving votes for faction: #{faction_name}"
  faction.search(:li).each do |li|
    voter_name = li.at(".dep").text.gsub("’", "'")
    puts "Saving vote by #{voter_name}..."

    voter_id = name_to_id(voter_name, faction_name)

    vote = {
      vote_event_id: vote_event_id,
      voter_id: voter_id,
      option: ukrainian_vote_to_popolo_option(li.at(".golos").text)
    }
    ScraperWiki::save_sqlite([:vote_event_id, :voter_id], vote, :votes)
  end
end

ScraperWiki::sqliteexecute("COMMIT")
