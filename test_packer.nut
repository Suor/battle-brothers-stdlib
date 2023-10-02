dofile("!!stdlib.nut", true);
dofile("tests/helpers.nut", true);
dofile("packer.nut", true);

local Str = ::std.Str, Re = ::std.Re, Text = ::std.Text,
    Debug = ::std.Debug, Util = ::std.Util, Array = ::std.Array;


local function assertPack(data, packed = null) {
    local dataPacked = ::Packer.pack(data);
    if (packed) assertEq(dataPacked, packed);
    local unpacked = ::Packer.unpack(dataPacked);
    assertEq(data, unpacked);
}

// Primitives
assertPack(null, "@>1_");
assertPack(true, "@>1+");
assertPack(false, "@>1-");

// Numbers
assertPack(7, "@>1,17");
assertPack(42, "@>1,242");
assertPack(1.1, "@>1.31.1");
assertPack(-0.0337, "@>1.7-0.0337");

// Strings
assertPack("", "@>1'0");
assertPack("hello", "@>1'5hello");
assertPack("'", "@>1'1'");
// A long string
assertPack("0123456789abcdefghiklmnopqurstuvqxyz0123456789abcdefghiklmnopqurstuvqxyz012345",
     "@>1\",2780123456789abcdefghiklmnopqurstuvqxyz0123456789abcdefghiklmnopqurstuvqxyz012345");

// Arrays
assertPack([], "@>1[,10");
assertPack(array(10), "@>1[,210__________");
assertPack([null true false], "@>1[,13_+-");
assertPack([1 2 3], "@>1[,13,11,12,13");

// Tables
assertPack({}, "@>1{,10");
assertPack({x = true}, "@>1{,11'1x+");
assertPack({a = 1, b = 2, c = 3});  // Order is not defined

// Non-string keys
local t = {}; t[true] <- "x";
assertPack(t, "@>1{,11+'1x");
local t = {}; t[1] <- 42;
assertPack(t, "@>1{,11,11,242");
local t = {}; t[0.5] <- 21;
assertPack(t, "@>1{,11.30.5,221");

// Nested
assertPack({x = {a = true}}, "@>1{,11'1x{,11'1a+")
assertPack({x = [3 7]}, "@>1{,11'1x[,12,13,17")
assertPack([{a = 7, b = null}, {a = "hi", c = false}], "@>1[,12{,12'1a,17'1b_{,12<1'2hi'1c-")

// Cache
assertPack(["hello" "hello" "bye"], "@>1[,13'5hello<0'3bye")
assertPack(["hello" "bye" "hello"], "@>1[,13'5hello'3bye<1")
assertPack(["value", {key = 7}, {key = "value"}], "@>1[,13'5value{,11'3key,17{,11<0<1")

// Test full cache
local data = ["start"];
for (local i = '0'; i <= 'z'; i++) data.push(i.tochar())
for (local i = '0'; i <= 'z'; i++) data.push("@" + i.tochar())
assertPack(data)

// Done
print("Tests OK\n")
