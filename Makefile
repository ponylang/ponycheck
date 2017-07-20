CC ?= gcc
SRCDIR = ponycheck
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

run_test: test
	./test $(TESTFLAGS)

clean:
	rm -f test


test: $(DEPS) $(TEST_DEPS)
	CC=$(CC) $(PONYC) $(FLAGS) $(SRCDIR)/test


.PHONY: test
