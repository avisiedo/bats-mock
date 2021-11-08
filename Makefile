

.PHONY: test
test: test-unit

.PHONY: test-unit
test-unit:
	./test/libs/bats/bin/bats ./test/unit/mock.bats

.PHONY: submodule-update
submodule-update:
	git submodule update --remote
	git submodule sync --recursive