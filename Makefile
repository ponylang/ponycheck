CC ?= gcc
PROGRAM = ponycheck

DEPS = ponycheck.pony gen.pony

TEST_DEPS = test/*.pony

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))

$(PROGRAM): $(DEPS)
	echo "MAKE DIR $(current_dir)"
	CC=$(CC) ponyc --debug .

run: $(PROGRAM)
	./$(PROGRAM)

clean:
	rm -f $(PROGRAM) test/test

test: $(PROGRAM) test/test
	./test/test

test/test: $(TEST_DEPS)
	CC=$(CC) ponyc test -o test

.PHONY: test
