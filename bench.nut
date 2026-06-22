dofile("load.nut", true);
local Str = ::std.Str, Re = ::std.Re, Rand = ::std.Rand, Debug = ::std.Debug, Util = ::std.Util,
    Text = ::std.Text, Array = ::std.Array, Table = ::std.Table, Packer = ::std.Packer;

local function pprint(_val) {
    print(Debug.pp(_val))
}

local function iter(_n) {
    for (local i = 0; i < _n; i++) {
        yield i * i;
    }
}
local function arr(_n) {
    local res = [];
    for (local i = 0; i < _n; i++) {
        res.push(i * i);
    }
    return res;
}
local function toArr(_iter) {
    local res = [];
    foreach (e in _iter) res.push(e);
    return res;
}



for (local n = 0; n < 1000000; n++) {
    toArr(iter(6))
}
