# test must run before lint before it fetches the dependencies
.PHONY: all
all: test lint docs

.PHONY: lint
lint:
	@./.script/hack.sh lint

.PHONY: test
test:
	@./.script/hack.sh test

.PHONY: docs
docs:
	@./.script/hack.sh docs

.PHONY: publish
publish: all
	@./.script/hack.sh publish
