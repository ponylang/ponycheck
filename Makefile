CC ?= gcc
SRCDIR = src/ponycheck
PROGRAM = ponycheck
PONYC ?= ponyc
DEPS = $(shell ls $(SRCDIR)/*.pony)

FLAGS ?=
ifneq (${DEBUG},)
    FLAGS += "--debug"
endif

TEST_PROGRAM = test
TEST_DEPS = $(shell ls $(SRCDIR)/test/*.pony)

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))

$(PROGRAM): $(DEPS)
	CC=$(CC) $(PONYC) $(FLAGS) $(SRCDIR)

run: $(PROGRAM)
	./$(PROGRAM)

clean:
	rm -f $(PROGRAM) $(TEST_PROGRAM)

run_test: $(PROGRAM) $(TEST_PROGRAM)
	./$(TEST_PROGRAM)

$(TEST_PROGRAM): $(TEST_DEPS)
	CC=$(CC) $(PONYC) $(SRCDIR)/test


.PHONY: test
