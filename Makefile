POD2HTML = pod2html --css "http://suika.fam.cx/www/style/html/pod.css" \
  --htmlroot "../.."

all: readme.html

readme.html: mkcommitfeed.pl
	$(POD2HTML) $< > $@.tmp
	sed 's/<\/head>/<link rel=feed type="application\/atom+xml" href=commitfeed-commit>/' $@.tmp > $@
	rm $@.tmp

install-example:
	cp mkcommitfeed-example /usr/local/bin/mkcommitfeed
	chmod ugo+x /usr/local/bin/mkcommitfeed

uninstall-example:
	rm /usr/local/bin/mkcommitfeed

## License: Public Domain.
## $Date: 2008/11/24 06:31:25 $
