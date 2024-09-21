local Packer = ::std.Packer, Packer1 = ::std.Packer1, Packer2 = ::std.Packer2, Util = ::std.Util;

local function assertPack(data, packed, ...) {
    local dataPacked = Util.pack(data);
    local bl = dataPacked.len();
    if (packed) assertEq(dataPacked, Packer.magic + Packer.version + packed);
    local unpacked = Util.unpack(dataPacked);
    assertEq(data, unpacked);

    local byVersion = {}
    foreach (older in vargv) {
        assertEq(data, Util.unpack(older));
        local v = older[2] - '0';
        byVersion[v] <- older;
    }

    foreach (packer in [Packer2 Packer1]) {
        local pprev = packer.pack(data);
        if (packer.version in byVersion) {
            assertEq(pprev, byVersion[packer.version])
        }
        assertEq(data, packer.unpack(pprev));
        assertEq(data, Packer.unpack(pprev)); // Check that latest packer will unpack it
    }

    // print("\n")
    // print("data = " + ::std.Debug.pp(data))
    // print("v3 " + dataPacked + "\n");
    // print("v2 " + Packer2.pack(data) + "\n");
    // print("v1 " + Packer1.pack(data) + "\n");
    // print("\n");
}

// Primitives
assertPack(null, "~", "@>1_");
assertPack(true, "+");
assertPack(false, "-");

// Numbers
assertPack(7, ",7");
assertPack(42, ",Z");
assertPack(89, "!/3", "@>2#289", "@>1;289");  // Over char integer limit
assertPack(-3, ",-");
assertPack(-20, "!p1", "@>2#3-20", "@>1;3-20"); // Below char integer limit
assertPack(-15, "!u1", "@>2#3-15", "@>1,!");    // v1 lcint
assertPack(-12, ",$", "@>1,$");       // v2 lcint
assertPack(6341, "!zz")
assertPack(6342, "#46342")
assertPack(-1227, "!$$")
assertPack(-1228, "#5-1228")
assertPack(1.1, ".31.1");
assertPack(-0.0337, ".7-0.0337");
assertPack(0.000001, ".51e-06");

// Strings
assertPack("", "'0");
assertPack("hello", "'5hello");
assertPack("'", "'1'");
// A long string
local lstr = "_0123456789abcdefghiklmnopqurstuvqxyz0123456789abcdefghiklmnopqurstuvqxyz012345";
assertPack(lstr, "'!%3" + lstr, "@>2\"#279" + lstr, "@>1\";279" + lstr);

// Arrays
assertPack([], "]0", "@>2[0", "@>1[,0");
// Use ; here to check conflict with v1 integer op code
assertPack(array(11), "];~~~~~~~~~~~", "@>2[;~~~~~~~~~~~", "@>1[,;___________");

assertPack(array(74, false), // max cint
    "]z--------------------------------------------------------------------------",
 "@>2[z--------------------------------------------------------------------------")
assertPack(array(80, false), // over cint
        "]!&3--------------------------------------------------------------------------------",
     "@>2[#280--------------------------------------------------------------------------------",
     "@>1[;280--------------------------------------------------------------------------------");
assertPack([null true false], "]3~+-", "@>2[3~+-", "@>1[,3_+-");

// Vectors of cint
assertPack([1 2 3], "]3,123", "@>1[,3,1,2,3");
assertPack([1 null 3], "]3,1~3", "@>1[,3,1_,3");
assertPack([null null 3], "]3~~,3", "@>2[3~~,3", "@>1[,3__,3"); // bail out in v2: no gain
assertPack([0 47], "]2,0_", "@>1[,2,0,_");         // check null op not confusing with cint 47
assertPack([3 100], "]2,3!:3", "@>2[2,3#3100");    // bail out: out of cint

// Vectors of sstring
assertPack(["a" "b"], "]2'1a1b", "@>2[2'1a'1b");
assertPack(["a"], "]1'1a", "@>2[1'1a");

// Vectors of ref
assertPack([["a" "b"], ["b" "a" "b"]], "]2]2'1a1b3*010", "@>2[2[2'1a'1b]3*010");
assertPack([["a" "b"], ["b" "a" null]], "]2]2'1a1b3*01~", "@>2[2[2'1a'1b]3*01~");
assertPack([["a" "b"], ["b" "a" "c"]], "]2]2'1a1b3*01'1c", "@>2[2[2'1a'1b[3*0*1'1c"); // no ref
assertPack([["a" "b"], ["b" "a" {}]], "]2]2'1a1b3*01|{0", "@>2[2[2'1a'1b[3*0*1{0"); // type switch

// Mixed vectors
assertPack([1 2 3 100 200 300 0, -1, -2, 9999], "]:,123!:3G4T5,0/.#49999");
assertPack(["a" "b" "c" "a" "a" "b" "d" "a" "d"], "]9'1a1b1c*221'1d*30");

// Vectors of arrays, tables
assertPack([[], [1], [], [1 2]], "]4]01,102,12")
assertPack([{}, {a = 1}, {a = 2}, {a = 3}], "]4{01'1a,1}0203")
assertPack([{}, {}, {a = 1}, {a = 2}, {}, {a = 3}], "]6{001'1a,1}02{0}03")
assertPack([{}, {}, {a = 1}, {a = 2}, {}], "]5{001'1a,1}02{0")

// Tables
assertPack({}, "{0", "@>1{,0");
assertPack({x = true}, "{1'1x+", "@>1{,1'1x+");
assertPack({a = 1, b = 2, c = 3}, null);  // Order is not defined
assertPack({a = "a"}, "{1'1a*0")

// Non-string keys
local t = {}; t[true] <- "x";
assertPack(t, "{1+'1x", "@>1{,1+'1x");
local t = {}; t[1] <- 42;
assertPack(t, "{1,1,Z", "@>1{,1,1,Z");
local t = {}; t[0.5] <- 21;
assertPack(t, "{1.30.5,E", "@>1{,1.30.5,E");

// Structs
assertPack([{a = 1}, {a = 2}], "]2{1'1a,1}02", "@>2[2{1'1a,1}02");
assertPack([{a = 1, b = 2}, {b = 5, a = 7}], "]2{2'1a,1'1b,2}075", "@>2[2{2'1a,1'1b,2}075");
assertPack([{a = 1}, {a = null}, {a = 2}], "]3{1'1a,1}0~02", "@>2[3{1'1a,1}0~}02");
assertPack([{a = null}, {a = 1}, {a = 2}], "]3{1'1a~}0,102", "@>2[3{1'1a~}0,1}02");

// Structs: cint
assertPack([{a = 1}, {a = true}, {a = false}], "]3{1'1a,1}0|+0-", "@>2[3{1'1a,1}0|+}0-");
assertPack([{a = 1}, {a = -5}, {a = false}], "]3{1'1a,1}0+0|-", "@>2[3{1'1a,1}0+}0|-");  // -5 in cint is +
assertPack([{a = 1}, {a = false}], "]2{1'1a,1}0|-", "@>2[2{1'1a,1}0|-");
assertPack([{a = 1}, {a = -2}], "]2{1'1a,1}0.", "@>2[2{1'1a,1}0.");  // -2 in cint is .
assertPack([{a = 1}, {a = 0.5}], "]2{1'1a,1}0|.30.5", "@>2[2{1'1a,1}0|.30.5");
assertPack([{a = 1.0}, {a = 1}], "]2{1'1a.11}0,1", "@>2[2{1'1a.11}0,1");
assertPack([{a = 1}, {a = ""}], "]2{1'1a,1}0|'0", "@>2[2{1'1a,1}0|'0");
assertPack([{a = 1}, {a = lstr}], "]2{1'1a,1}0|'!%3" + lstr, "@>2[2{1'1a,1}0|\"#279" + lstr);
assertPack([{a = 1}, {a = []}], "]2{1'1a,1}0|]0", "@>2[2{1'1a,1}0|[0");
assertPack([{a = 1}, {a = [7 7 7]}], "]2{1'1a,1}0|]3,777", "@>2[2{1'1a,1}0|]3,777");
assertPack([{a = "hi"}, {a = 1}, {a = "hi"}], "]3{1'1a'2hi}0|,10|*0", "@>2[3{1'1a'2hi}0|,1}0|*0"); // cint -> ref
assertPack([{a = 1}, {a = {}}], "]2{1'1a,1}0|{0", "@>2[2{1'1a,1}0|{0");
assertPack([{a = 1}, {a = {a = 2}}], "]2{1'1a,1}0|}02", "@>2[2{1'1a,1}0|}02");  // cint -> struct, also nested

// Structs: irregular
assertPack([{a = 1, b = 2}, {a = 7}, {a = 10, b = -1}],
    "]3{2'1a,1'1b,21*1,7}1:/",
 "@>2[3{2'1a,1'1b,2{1*1,7}1:/");

// Structs: medium integers
assertPack([{a = 1}, {a = 100}, {a = 101}], "]3{1'1a,1}0!:30;3", "@>2[3{1'1a,1}0#3100}03101");
assertPack([{a = 100}, {a = 1}], "]2{1'1a!:3}0,1", "@>2[2{1'1a#3100}0,1");
assertPack([{a = 100}, {a = "hi"}], "]2{1'1a!:3}0|'2hi", "@>2[2{1'1a#3100}0|'2hi"); // mint -> sstring
assertPack([{a = 100}, {a = 100.0}], "]2{1'1a!:3}0|.3100", "@>2[2{1'1a#3100}0.3100"); // mint -> float

// Structs: long integers
assertPack([{a = 1}, {a = 9999}, {a = 9991}], "]3{1'1a,1}0#49999049991");
assertPack([{a = 9999}, {a = 1}], "]2{1'1a#49999}0,1");
assertPack([{a = 100}, {a = 9999}], "]2{1'1a!:3}0#49999");
assertPack([{a = 9999}, {a = 100}], "]2{1'1a#49999}0!:3");
assertPack([{a = 9999}, {a = "hi"}], "]2{1'1a#49999}0|'2hi");    // integer -> sstring
assertPack([{a = 9999}, {a = 999.9}], "]2{1'1a#49999}0.5999.9"); // integer -> float

// Structs: bools
assertPack([{a = false}, {a = true}, {a = false}], "]3{1'1a-}0+0-");
assertPack([{a = false}, {a = null}, {a = false}], "]3{1'1a-}0~0-");
assertPack([{a = false}, {a = 5}], "]2{1'1a-}0,5");

// Structs: strings
assertPack([{a = "hi"}, {a = "bye"}, {a = "bye"}, {a = "z"}],
    "]4{1'1a'2hi}03bye0*00'1z",
 "@>2[4{1'1a'2hi}03bye}0*0}0'1z");
assertPack([{a = lstr}, {a = lstr}, {a = lstr + "_"}, {a = "z"}, {a = lstr + "~"}],
    "]5{1'1a'!%3" + lstr + "}0*00'!&3" + lstr + "_01z0!&3" + lstr + "~",
 "@>2[5{1'1a\"#279" + lstr + "}0*0}0\"#280" + lstr + "_}0'1z}0\"#280" + lstr + "~");
assertPack([{a = lstr}, {a = 100}],
    "]2{1'1a'!%3" + lstr + "}0|!:3",
 "@>2[2{1'1a\"#279" + lstr + "}0|#3100");  // lstring -> integer

// Structs: nested
assertPack([{a = 1, b = {c = "hi"}}, {a = 5, b = {c = "bye"}}, {a = null, b = {c = "hi"}}],
    "]3{2'1a,1'1b{1'1c'2hi}05}13bye0~1*1",
 "@>2[3{2'1a,1'1b{1'1c'2hi}05|}13bye}0~1*1");
assertPack([{a = null, b = null}, {a = {a = 1, b = 2}, b = {a = "x", b = "y"}}],
    "]2{2'1a~'1b~}0}0,1,2|}0|'1x|'1y",
 "@>2[2{2'1a~'1b~}0}0,1,2|}0|'1x|'1y");

assertPack([{a = "foo"}, {a = "bar"}],
    "]2{1'1a'3foo}03bar",
 "@>2[2{1'1a'3foo}03bar");
assertPack([{a = "foo"}, {a = "foo"}], // change op because of ref
    "]2{1'1a'3foo}0*0",
 "@>2[2{1'1a'3foo}0*0");
assertPack([{a = "foo"}, {a = "foo"}, {a = "bar"}],  // change op twice
    "]3{1'1a'3foo}0*00'3bar",
 "@>2[3{1'1a'3foo}0*0}0'3bar");

// Structs: arrays and vectors
assertPack([{a = []}, {a = null}], "]2{1'1a]0}0~", "@>2[2{1'1a[0}0~");
assertPack([{a = [7 7]}, {a = [8 8]}], "]2{1'1a]2,77}02,88", "@>2[2{1'1a]2,77}02,88");
assertPack([{a = [7 7]}, {a = "a"}], "]2{1'1a]2,77}0|*0", "@>2[2{1'1a]2,77}0|*0"); // vector -> ref
assertPack([{a = [7 7]}, {a = [null 1]}], null, "@>2[2{1'1a]2,77}0|[2~,1"); // vector -> array v2
assertPack([{a = [7 7]}, {a = [1 "a"]}], "]2{1'1a]2,77}0|[2,1*0"); // vector -> array v3
assertPack([{a = [null 1]}, {a = [7 7]}], null, "@>2[2{1'1a[2~,1}0|]2,77"); // array -> vector v2
assertPack([{a = [1 "a"]}, {a = [7 7]}], "]2{1'1a[2,1*0}0|]2,77"); // array -> vector v3
assertPack([{a = [null 1]}, {a = array(45)}],
    "]2{1'1a]2~,1}0]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
 "@>2[2{1'1a[2~,1}0]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");  // 45is cint ]

// Nested
assertPack({x = {a = true}}, "{1'1x{1'1a+", "@>1{,1'1x{,1'1a+")
assertPack({x = [3 7]}, "{1'1x]2,37", "@>1{,1'1x[,2,3,7")
assertPack([{a = 7, b = null}, {a = "hi", c = false}],
    "]2{2'1a,7'1b~2*1'2hi'1c-",
 "@>1[,2{,2'1a,7'1b_{,2<1'2hi'1c-")

// Cache
assertPack(["hello" "hello" "bye"],
    "]3'5hello*0'3bye",
 "@>2[3'5hello*0'3bye",
 "@>1[,3'5hello<0'3bye");
assertPack(["hello" "bye" "hello"],
    "]3'5hello3bye*1",
 "@>2[3'5hello'3bye*1",
 "@>1[,3'5hello'3bye<1")
assertPack(["value", {key = 7}, {key = "value"}],
       "[3'5value{1'3key,7}0|*1", // tests cint -> ref
    "@>1[,3'5value{,1'3key,7{,1<0<1")

// Test full cache
local data = ["start"];
for (local i = '0'; i <= 'z'; i++) data.push(i.tochar())
for (local i = '0'; i <= 'z'; i++) data.push("@" + i.tochar())
assertPack(data, null)

// Broken if we depend on table iteration order
local broken = "@>2[3{5'8BattleId,1';TargetClass'Bbarbarian_champion':TargetName'@Barbarian Chosen'6Injury'Bdeep_abdominal_cut'3Day,1}038direwolf8Direwolf:broken_leg3}07<caravan_hand<Caravan Hand7cut_arm4";
local ubroken = Util.unpack(broken);
assertPack(ubroken, null);

// Done
print("Packer OK\n")
