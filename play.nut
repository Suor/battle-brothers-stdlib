dofile("load.nut", true);
local Str = ::std.Str, Re = ::std.Re, Rand = ::std.Rand, Debug = ::std.Debug, Util = ::std.Util,
    Text = ::std.Text, Array = ::std.Array, Table = ::std.Table, Iter = ::std.Iter,
    Actor = ::std.Actor, Packer = ::std.Packer;

local function pprint(_val) {
    print(Debug.pp(_val))
}

// ... put your code here ...

// local x = {}.setdelegate({_get = @(k) @(...) null});

// pprint(x.onNewDay("hey"));

// local xs = [1 2 3].map(@(x) {a = x, b = x*x});
pprint(format("%d food", 3.123))
