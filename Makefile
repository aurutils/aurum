PROGNM = aurum
PREFIX ?= /usr
SHRDIR ?= $(PREFIX)/share
BINDIR ?= $(PREFIX)/bin
LIBDIR ?= $(PREFIX)/lib
AURUM_LIB_DIR ?= $(LIBDIR)/$(PROGNM)
AURUM_VERSION ?= $(shell git describe --tags || true)
ifeq ($(AURUM_VERSION),)
AURUM_VERSION := 0.1
endif

.PHONY: shellcheck install aurum

aurum: aurum.in
	sed -e 's|AURUM_LIB_DIR|$(AURUM_LIB_DIR)|' \
	    -e 's|AURUM_VERSION|$(AURUM_VERSION)|' $< >$@

shellcheck:
	@shellcheck -x -f gcc -e 1071 '$(PROGNM)'

install: aurum
	@install -Dm755 '$(PROGNM)' -t '$(DESTDIR)$(BINDIR)'
	@install -Dm755 lib/*       -t '$(DESTDIR)$(AURUM_LIB_DIR)'
	@install -Dm644 man1/*      -t '$(DESTDIR)$(SHRDIR)/man/man1'
	@install -Dm644 LICENSE     -t '$(DESTDIR)$(SHRDIR)/licenses/$(PROGNM)'
	@install -Dm644 README.md   -t '$(DESTDIR)$(SHRDIR)/doc/$(PROGNM)'
