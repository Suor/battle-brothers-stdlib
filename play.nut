dofile("load.nut", true);
local Str = ::std.Str, Re = ::std.Re, Rand = ::std.Rand, Debug = ::std.Debug, Util = ::std.Util,
    Text = ::std.Text, Array = ::std.Array, Table = ::std.Table, Iter = ::std.Iter,
    Actor = ::std.Actor, Packer = ::std.Packer;

local G = getroottable();
local function pprint(_val) {
    G.print(Debug.pp(_val))
}

// ... put your code here ...

local x = {a = 1}, z = x.a + 1;

pprint(z)
