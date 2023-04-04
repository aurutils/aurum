PROGNM = aurum
PREFIX ?= /usr
SHRDIR ?= $(PREFIX)/share
BINDIR ?= $(PREFIX)/bin
AURUM_LIB_DIR ?= $(LIBDIR)/$(PROGNM)
AURUM_VERSION ?= $(shell git describe --tags || true)
ifeq ($(AURUM_VERSION),)
AURUM_VERSION := 0.1
endif

.PHONY: install

install:
	@install -Dm755 aurum     -t '$(DESTDIR)$(BINDIR)'
	@install -Dm644 man1/*    -t '$(DESTDIR)$(SHRDIR)/man/man1'
	@install -Dm644 LICENSE   -t '$(DESTDIR)$(SHRDIR)/licenses/$(PROGNM)'
	@install -Dm644 README.md -t '$(DESTDIR)$(SHRDIR)/doc/$(PROGNM)'
