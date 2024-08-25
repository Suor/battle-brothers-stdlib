local Packer = ::std.Packer;

local function assertPack(data, packed = null, older = null) {
    local dataPacked = ::std.Util.pack(data);
    if (packed) assertEq(dataPacked, Packer.magic + Packer.version + packed);
    local unpacked = ::std.Util.unpack(dataPacked);
    assertEq(data, unpacked);
    if (older) assertEq(data, ::std.Util.unpack(older));
}

// Primitives
assertPack(null, "_");
assertPack(true, "+");
assertPack(false, "-");

// Numbers
assertPack(7, ",7");
assertPack(42, ",Z");
assertPack(99, "#299", "@>1;299");  // Over char integer limit
assertPack(-3, ",-");
assertPack(-20, "#3-20", "@>1;3-20"); // Below char integer limit
assertPack(1.1, ".31.1");
assertPack(-0.0337, ".7-0.0337");
assertPack(0.000001, ".51e-06");

// Strings
assertPack("", "'0");
assertPack("hello", "'5hello");
assertPack("'", "'1'");
// A long string
assertPack("0123456789abcdefghiklmnopqurstuvqxyz0123456789abcdefghiklmnopqurstuvqxyz012345",
    "\"#2780123456789abcdefghiklmnopqurstuvqxyz0123456789abcdefghiklmnopqurstuvqxyz012345",
    "@>1\";2780123456789abcdefghiklmnopqurstuvqxyz0123456789abcdefghiklmnopqurstuvqxyz012345");

// Arrays
assertPack([], "[0", "@>1[,0");
assertPack(array(10), "[:__________", "@>1[,:__________");

assertPack(array(80, false),
        "[#280--------------------------------------------------------------------------------",
     "@>1[;280--------------------------------------------------------------------------------");
assertPack([null true false], "[3_+-", "@>1[,3_+-");
assertPack([1 2 3], "[3,1,2,3", "@>1[,3,1,2,3");

// Tables
assertPack({}, "{0", "@>1{,0");
assertPack({x = true}, "{1'1x+", "@>1{,1'1x+");
assertPack({a = 1, b = 2, c = 3}, null, "@>1{,3'1a,1'1b,2'1c,3");  // Order is not defined

// Non-string keys
local t = {}; t[true] <- "x";
assertPack(t, "{1+'1x", "@>1{,1+'1x");
local t = {}; t[1] <- 42;
assertPack(t, "{1,1,Z", "@>1{,1,1,Z");
local t = {}; t[0.5] <- 21;
assertPack(t, "{1.30.5,E", "@>1{,1.30.5,E");

// Nested
assertPack({x = {a = true}}, "{1'1x{1'1a+", "@>1{,1'1x{,1'1a+")
assertPack({x = [3 7]}, "{1'1x[2,3,7", "@>1{,1'1x[,2,3,7")
assertPack([{a = 7, b = null}, {a = "hi", c = false}],
       "[2{2'1a,7'1b_{2<1'2hi'1c-",
    "@>1[,2{,2'1a,7'1b_{,2<1'2hi'1c-")

// Cache
assertPack(["hello" "hello" "bye"], "[3'5hello<0'3bye", "@>1[,3'5hello<0'3bye")
assertPack(["hello" "bye" "hello"], "[3'5hello'3bye<1", "@>1[,3'5hello'3bye<1")
assertPack(["value", {key = 7}, {key = "value"}],
       "[3'5value{1'3key,7{1<0<1",
    "@>1[,3'5value{,1'3key,7{,1<0<1")

// Test full cache
local data = ["start"];
for (local i = '0'; i <= 'z'; i++) data.push(i.tochar())
for (local i = '0'; i <= 'z'; i++) data.push("@" + i.tochar())
assertPack(data)

// Done
print("Packer OK\n")
