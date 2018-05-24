.DEFAULT_GOAL = build
.PHONY: clean build install

prefix = $(DESTDIR)/usr/local
bindir = $(prefix)/bin

SCRIPT_BIN := phue

build: $(SCRIPT_BIN)

clean:
	$(RM) $(SCRIPT_BIN)

install: $(SCRIPT_BIN)
	install -m 0755 $(SCRIPT_BIN) $(bindir)/$(SCRIPT_BIN)
