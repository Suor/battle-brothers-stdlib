// Here we set up things that goes after modhooks or Modern Hooks

// If Modern hooks are present then register this, so that people could declare a dependency,
// if not available do the same with Adam's mod_hooks.
if ("Hooks" in getroottable()) {
    if (!::Hooks.hasMod("stdlib")) ::Hooks.__unverifiedRegister("stdlib", ::std.version, "stdlib");
}
else if ("mods_registerMod" in getroottable()) ::mods_registerMod("stdlib", ::std.version);

// Replace Adam's default random generator with ours. It does same, just want it to be the only one.
if ("rng" in getroottable()) ::rng <- ::std.rng;
