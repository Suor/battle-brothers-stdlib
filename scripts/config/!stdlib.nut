// Ensure only the latest version goes as ::std
local version = 2.3;
if ("std" in getroottable() && ::std.version >= version) return;

// Util is forward declared, so that others might use it, even things added later with extend.
// Hook is "imported" by some versions of Standout Enemies, but not used.
::std <- {version = version, Util = {}, Hook = {}};

::include("stdlib/array");
::include("stdlib/table");
::include("stdlib/str");
::include("stdlib/re");
::include("stdlib/rand");
::include("stdlib/debug");
::include("stdlib/actor");
::include("stdlib/player");
::include("stdlib/packer");
::include("stdlib/util");

local Text;
Text = ::std.Text <- {
    function colored(value, color) {
        return ::Const.UI.getColorized(value + "", color)
    }
    function positive(value) {return Text.colored(value, ::Const.UI.Color.PositiveValue)}
    function negative(value) {return Text.colored(value, ::Const.UI.Color.NegativeValue)}
    function damage(value) {return Text.colored(value, ::Const.UI.Color.DamageValue)}
    function ally(value) {return Text.colored(value, "#1e468f")}
    function enemy(value) {return Text.colored(value, "#8f1e1e")}

    // function signed(value) {
    //     return (value > 0 ? "+" : "") + value;
    // }
    function plural(value, ...) {
        if (vargv.len() != 0 && vargv.len() != 2)
            throw "Use Text.plural(num) or Text.plural(num, singular, plural)";
        local forms = vargv.len() == 2 ? vargv : ["" "s"];
        local p = abs(value);
        return p % 10 != 1 ? forms[1] : p % 100 / 10 == 1 ? forms[1] : forms[0];
    }
}
