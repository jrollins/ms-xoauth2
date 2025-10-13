
GIT_STATUS := $(shell git status --short -uno)

.PHONY: install
install:
	test -z "$(GIT_STATUS)"
	install ms-xoauth2 ~/bin/
