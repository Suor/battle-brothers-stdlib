MOD_NAME = stdlib
SOURCES = stdlib scripts
DATA_DIR = ~/.local/share/Steam/steamapps/common/Battle\ Brothers/data/

SHELL := /bin/bash

.ONESHELL:
test:
	@if [[ -f "tests/test.nut" ]]; then
		TMP_FILE=$$(mktemp);
		squirrel tests/test.nut 2> >(tee "$$TMP_FILE" >&2);
		if [ -s "$$TMP_FILE" ]; then
			rm "$$TMP_FILE"
			exit 1
		fi
	fi

zip: check-compile test
	@LAST_TAG=$$(git tag | tail -1);
	MODIFIED=$$( git diff $$LAST_TAG --quiet $(SOURCES) || echo _MODIFIED);
	FILENAME=$(MOD_NAME)$$([[ "$$LAST_TAG" != "" ]] && echo _$$LAST_TAG || echo "")$${MODIFIED}.zip;
	zip --filesync -r "$${FILENAME}" $(SOURCES);

clean:
	@rm -f *_MODIFIED.zip;

install: check-compile test
	@set -e;
	FILENAME=$(DATA_DIR)$(MOD_NAME)_TMP.zip;
	zip --filesync -r "$${FILENAME}" $(SOURCES);

check-compile:
	@set -e
	find . -name \*.nut -print0 | xargs -0 -n1 squirrel -c && echo "Syntax OK"
	rm out.cnut
