CC ?= gcc
SRCDIR=ponycheck

EXAMPLES_DIR = examples
PONYC ?= ponyc
DEPS = $(shell ls $(SRCDIR)/*.pony)

FLAGS ?=
TESTFLAGS ?=
ifneq (${DEBUG},)
    FLAGS += --debug
    TESTFLAGS += --verbose
endif

TEST_PROGRAM = test
TEST_DEPS = $(shell ls $(SRCDIR)/test/*.pony)

EXAMPLE_DEPS = $(shell ls $(EXAMPLES_DIR)/*.pony)

run_test: test
	./test $(TESTFLAGS)

clean:
	rm -f test


test: $(DEPS) $(TEST_DEPS)
	CC=$(CC) $(PONYC) $(FLAGS) $(SRCDIR)/test

docs: FLAGS += --pass=docs --docs --output=docs
docs: $(DEPS) $(TEST_DEPS)
	CC=$(CC) $(PONYC) $(FLAGS) $(SRCDIR)

example: $(EXAMPLE_DEPS)
	cd examples && \
	    stable fetch && \
	    CC=$(CC) stable env $(PONYC) $(FLAGS)

.PHONY: fetch
