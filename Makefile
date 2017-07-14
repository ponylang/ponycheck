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

#mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
#current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))

clean:
	rm -f test

run_test: test
	./test

test: $(DEPS) $(TEST_DEPS)
	CC=$(CC) $(PONYC) $(FLAGS) $(SRCDIR)/test


.PHONY: test
