# test must run before lint before it fetches the dependencies
.PHONY: all
all: test lint

.PHONY: lint
lint:
	@./.script/hack.sh lint

.PHONY: test
test:
	@./.script/hack.sh test
