CC ?= gcc
SRCDIR = ponycheck
PONYC ?= ponyc
DEPS = $(shell ls $(SRCDIR)/*.pony)

FLAGS ?=
ifneq (${DEBUG},)
    FLAGS += --debug
endif

TEST_PROGRAM = test
TEST_DEPS = $(shell ls $(SRCDIR)/test/*.pony)

run_test: test
	./test

clean:
	rm -f test


test: $(DEPS) $(TEST_DEPS)
	CC=$(CC) $(PONYC) $(FLAGS) $(SRCDIR)/test


.PHONY: test
