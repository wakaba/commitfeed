all:

install-example:
	cp mkcommitfeed-example /usr/local/bin/mkcommitfeed
	chmod ugo+x /usr/local/bin/mkcommitfeed

uninstall-example:
	rm /usr/local/bin/mkcommitfeed

## License: Public Domain.
## $Date: 2008/11/24 05:08:39 $
