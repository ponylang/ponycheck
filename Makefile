CC ?= gcc
SRCDIR=ponycheck

EXAMPLES_DIR = examples
PONYC ?= ponyc
DEPS = $(shell ls $(SRCDIR)/*.pony)

FLAGS ?=
TESTFLAGS ?=
ifneq (${DEBUG},)
    FLAGS += --debug
    #    TESTFLAGS += --verbose
endif

TEST_PROGRAM = test
TEST_DEPS = $(shell ls $(SRCDIR)/test/*.pony)

EXAMPLES_DEPS = $(shell ls $(EXAMPLES_DIR)/*.pony)

run_test: test
	./test $(TESTFLAGS)

clean:
	rm -f test


test: $(DEPS) $(TEST_DEPS)
	CC=$(CC) $(PONYC) $(FLAGS) $(SRCDIR)/test

docs: FLAGS += --pass=docs --docs --output=docs
docs: $(DEPS) $(TEST_DEPS)
	CC=$(CC) $(PONYC) $(FLAGS) $(SRCDIR)

examples: $(EXAMPLES_DEPS)
	cd examples && \
	    CC=$(CC) $(PONYC) $(FLAGS) . && \
	    ./examples

.PHONY: examples fetch
