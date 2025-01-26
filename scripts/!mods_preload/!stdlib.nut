// Here we set up things that goes after modhooks or Modern Hooks

// If Adam's hooks are present then register this, so that people could declare a dependency,
// if not available do the same with Modern Hooks
if ("mods_registerMod" in getroottable()) ::mods_registerMod("stdlib", ::std.version);
else if ("Hooks" in getroottable() && !::Hooks.hasMod("stdlib")) {
    ::Hooks.__unverifiedRegister("stdlib", ::std.version, "stdlib");
}

// Replace Adam's default random generator with ours. It does same, just want it to be the only one.
if ("rng" in getroottable()) ::rng <- ::std.rng;
