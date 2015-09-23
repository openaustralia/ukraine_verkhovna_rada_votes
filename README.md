# Ukraine Verkhovna Rada Votes

This is [a scraper that runs on morph.io](https://morph.io/openaustralia/ukraine_verkhovna_rada_votes) to collect details of every recorded vote in the Ukrainian parliament. It's intended to be used by a project to bring [They Vote For You](https://theyvoteforyou.org.au/) to Ukraine.

It saves data to morph.io in a flat format that can be converted easily into [Popolo](http://www.popoloproject.com/). You can use the little Sinatra proxy, [morph_popolo](https://github.com/openaustralia/morph_popolo) to do exactly that.

## Helpful URLs

All these URLs have obvious IDs you can change to get other pages:

* Calendar of sitting days: http://w1.c1.rada.gov.ua/pls/radan_gs09/ns_el_h
* That loads this via AJAX for each session (the `nom_s` parameter is the session number): http://w1.c1.rada.gov.ua/pls/radan_gs09/ns_el_l?nom_s=3&ss=3

* Plenary session day without votes: http://w1.c1.rada.gov.ua/pls/radan_gs09/ns_el_h2?data=01092015&nom_s=3
* Plenary session day with votes: http://w1.c1.rada.gov.ua/pls/radan_gs09/ns_el_h2?data=02092015&nom_s=3

* Vote event detail page: http://w1.c1.rada.gov.ua/pls/radan_gs09/ns_golos?g_id=3479
