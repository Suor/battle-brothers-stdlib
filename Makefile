MOD_NAME = stdlib
SOURCES = stdlib scripts
DATA_DIR = ~/.local/share/Steam/steamapps/common/Battle\ Brothers/data/

SHELL := /bin/bash

test:
	squirrel tests/test.nut

zip:
	LAST_TAG=$$(git tag | tail -1); \
	MODIFIED=$$( git diff $$LAST_TAG --quiet $(SOURCES) || echo _MODIFIED); \
	FILENAME=$(MOD_NAME)$$([[ "$$LAST_TAG" != "" ]] && echo _$$LAST_TAG || echo "")$${MODIFIED}.zip; \
	rm $${FILENAME}; \
	zip -r $${FILENAME} $(SOURCES)

install:
	FILENAME=$(MOD_NAME)_TMP.zip; \
	rm $${FILENAME}; \
	zip -r $${FILENAME} $(SOURCES); \
	cp $${FILENAME} $(DATA_DIR)$${FILENAME}; \
	rm $${FILENAME}
