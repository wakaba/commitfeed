P2H = local/p2h
CURL = curl

all: build

local:
	mkdir -p local

$(P2H): local
	$(CURL) -sSfL https://raw.githubusercontent.com/manakai/manakai.github.io/master/p2h > $@
	chmod u+x $@

build: readme.html

readme.html: mkcommitfeed.pl $(P2H)
	$(P2H) "commitfeed" $< > $@

install-example:
	cp mkcommitfeed-example /usr/local/bin/mkcommitfeed
	chmod ugo+x /usr/local/bin/mkcommitfeed

uninstall-example:
	rm /usr/local/bin/mkcommitfeed

## License: Public Domain.
