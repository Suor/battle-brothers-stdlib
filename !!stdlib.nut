// DO NOT MODIFY THIS FILE
// TO USE PUT IT INTO scripts/ AND RENAME TO !!stdlib_yourmod.nut

// Alias things to make it easier for us inside. These are still global and accessible from outside
// Ensure only the latest version goes as ::std
local version = 1.43;
if ("std" in getroottable() && ::std.version >= version) return;
local std = ::std <- {version = version, Util = {}};

local function load(script) {
    return "dofile" in getroottable() ? dofile(script + ".nut", true) : ::include(script);
}
load("stdlib/array");
load("stdlib/table");
load("stdlib/debug");
load("stdlib/str");
load("stdlib/re");
load("stdlib/rand");
load("stdlib/util");

local Text;
Text = ::std.Text <- {
    function colored(value, color) {
        return ::Const.UI.getColorized(value + "", color)
    }
    function positive(value) {return Text.colored(value, ::Const.UI.Color.PositiveValue)}
    function negative(value) {return Text.colored(value, ::Const.UI.Color.NegativeValue)}
    function damage(value) {return Text.colored(value, ::Const.UI.Color.DamageValue)}
    // function ally(value) {return Text.colored(value, "#1e468f")}
    // function enemy(value) {return Text.colored(value, "#8f1e1e")}

    // function signed(value) {
    //     return (value > 0 ? "+" : "") + value;
    // }
    function plural(value) {
        local p = abs(value);
        return p % 10 != 1 ? "s" : p % 100 / 10 == 1 ? "s" : "";
    }
}
