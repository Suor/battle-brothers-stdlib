dofile("tests/mocks.nut", true);
dofile("scripts/!mods_preload/!stdlib.nut", true);
local Str = ::std.Str, Re = ::std.Re, Rand = ::std.Rand, Debug = ::std.Debug, Util = ::std.Util,
    Text = ::std.Text, Array = ::std.Array, Table = ::std.Table,
    Actor = ::std.Actor, Packer = ::std.Packer;

local function pprint(_val) {
    print(Debug.pp(_val))
}

// ... put your code here ...
