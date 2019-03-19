PONYC ?= ponyc
config ?= debug
ifdef config
  ifeq (,$(filter $(config),debug release))
    $(error Unknown configuration "$(config)")
  endif
endif

ifeq ($(config),debug)
	PONYC_FLAGS += --debug
endif

PONYC_FLAGS += -o build/$(config)
ALL: test

build/$(config)/test: ponycheck/*.pony ponycheck/test/*.pony .deps build/$(config)
	stable env ${PONYC} ${PONYC_FLAGS} ponycheck/test

build/$(config)/examples: PONYC_FLAGS += --bin-name=examples
build/$(config)/examples: ponycheck/*.pony examples/*.pony .deps build/$(config)
	stable env ${PONYC} ${PONYC_FLAGS} examples

build/$(config):
	mkdir -p build/$(config)

.deps:
	stable fetch

test: build/$(config)/test
	build/$(config)/test

examples: build/$(config)/examples
	build/$(config)/examples

clean:
	rm -rf build/$(config)

docs: PONYC_FLAGS += --pass=expr --docs-public --output=docs-tmp
docs:
	rm -rf docs-tmp
	${PONYC} ${PONYC_FLAGS} ponycheck
	cd docs-tmp/ponycheck-docs && mkdocs build
	rm -rf docs
	cp -R docs-tmp/ponycheck-docs/site docs
	rm -rf docs-tmp

.PHONY: examples clean test docs
