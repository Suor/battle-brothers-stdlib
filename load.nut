local STDLIB_DIR = getenv("STDLIB_DIR") || "";

dofile(STDLIB_DIR + "tests/mocks.nut", true);
dofile(STDLIB_DIR + "scripts/!mods_preload/!stdlib.nut", true);
