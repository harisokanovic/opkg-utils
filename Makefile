UTILS = opkg-build opkg-unbuild opkg-make-index opkg.py opkg-list-fields \
	arfile.py opkg-buildpackage opkg-diff opkg-extract-file opkg-show-deps \
	opkg-compare-indexes update-alternatives

DESTDIR=
PREFIX=/usr/local
bindir=$(PREFIX)/bin

all:

install: 
	install -d $(DESTDIR)$(bindir)
	install -m 755 $(UTILS) $(DESTDIR)$(bindir)

.PHONY: install all
