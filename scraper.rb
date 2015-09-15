require 'scraperwiki'
require 'mechanize'

agent = Mechanize.new

vote_event_url = "http://w1.c1.rada.gov.ua/pls/radan_gs09/ns_golos?g_id=3106"
vote_event_page = agent.get(vote_event_url)
