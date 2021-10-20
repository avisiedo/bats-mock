

.PHONY: test
test: test-unit

.PHONY: test-unit
test-unit:
	./test/libs/bats/bin/bats ./test/unit/mock.bats
