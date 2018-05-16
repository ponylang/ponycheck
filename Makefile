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
	rm -f test $(EXAMPLES_DIR)/examples


test: $(DEPS) $(TEST_DEPS)
	CC=$(CC) $(PONYC) $(FLAGS) $(SRCDIR)/test

docs: FLAGS += --pass=docs --docs-public --output=docs-tmp
docs: $(DEPS) $(TEST_DEPS)
	rm -rf docs-tmp
	CC=$(CC) $(PONYC) $(FLAGS) $(SRCDIR)
	cd docs-tmp/ponycheck-docs && mkdocs build
	rm -rf docs
	cp -R docs-tmp/ponycheck-docs/site docs
	rm -rf docs-tmp

examples: $(EXAMPLES_DEPS)
	cd $(EXAMPLES_DIR) && \
	    CC=$(CC) $(PONYC) $(FLAGS) . && \
	    ./examples

.PHONY: examples fetch clean docs
