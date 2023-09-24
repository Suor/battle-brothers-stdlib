MOD_NAME = stdlib
SOURCES = !!stdlib.nut
DATA_DIR = ~/.local/share/Steam/steamapps/common/Battle\ Brothers/data/

SHELL := /bin/bash

test:
	squirrel tests/test.nut
