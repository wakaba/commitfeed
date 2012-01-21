#!/bin/sh
find -name ChangeLog | xargs cvs diff | grep "^\+" | sed -e "s/^\+//; s/^\+\+ .\//++ commitfeed\//" > .cvslog.tmp
cvs commit -F .cvslog.tmp $1 $2 $3 $4 $5 $6 $7 $8 $9 
mkcommitfeed \
    --file-name commitfeed-commit.en.atom.u8 \
    --feed-url http://suika.fam.cx/commitfeed/commitfeed-commit \
    --feed-title "CommitFeed ChangeLog diffs" \
    --feed-lang en \
    --feed-related-url "http://suika.fam.cx/commitfeed/readme" \
    --feed-license-url "http://suika.fam.cx/commitfeed/readme#license" \
    --feed-rights "This feed is free software; you can redistribute it and/or modify it under the same terms as Perl itself." \
    < .cvslog.tmp
cvs commit -m "" commitfeed-commit.en.atom.u8
rm .cvslog.tmp

## $Date: 2008/11/24 05:08:39 $
## License: Public Domain
