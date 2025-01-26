dofile("load.nut", true);
local Str = ::std.Str, Re = ::std.Re, Rand = ::std.Rand, Debug = ::std.Debug, Util = ::std.Util,
    Text = ::std.Text, Array = ::std.Array, Table = ::std.Table, Packer = ::std.Packer;

local function pprint(_val) {
    print(Debug.pp(_val))
}

local function assertPack(data, packed = null, older = null) {
    local dataPacked = Util.pack(data);
    local unpacked = Util.unpack(dataPacked);
}


for (local n = 0; n < 2000; n++) {
    // assertPack([], "[0", "@>1[,0");
    // // Use ; here to check conflict with v1 integer op code
    // assertPack(array(11), "[;~~~~~~~~~~~", "@>1[,;___________");

    // assertPack(array(74, false), // max cint
    //     "[z--------------------------------------------------------------------------")
    // assertPack(array(80, false), // over cint
    //         "[#280--------------------------------------------------------------------------------",
    //      "@>1[;280--------------------------------------------------------------------------------");
    // assertPack([null true false], "[3~+-", "@>1[,3_+-");

    // // Vectors of cint
    // assertPack([1 2 3], "]3,123", "@>1[,3,1,2,3");
    // assertPack([1 null 3], "]3,1~3", "@>1[,3,1_,3");
    // assertPack([null null 3], "[3~~,3", "@>1[,3__,3"); // bail out: no gain
    // assertPack([0 47], "]2,0_", "@>1[,2,0,_");        // check null op not confusing with cint 47
    // assertPack([3 100], "[2,3#3100");                  // bail out: out of cint

    // // Vectors of ref
    // assertPack([["a" "b"], ["b" "a" "b"]], "[2[2'1a'1b]3*010");
    // assertPack([["a" "b"], ["b" "a" null]], "[2[2'1a'1b]3*01~");
    // assertPack([["a" "b"], ["b" "a" "c"]], "[2[2'1a'1b[3*0*1'1c"); // bail out: no ref
    // assertPack([["a" "b"], ["b" "a" {}]], "[2[2'1a'1b[3*0*1{0");   // bail out: wrong type

    assertPack(array(100, 1))
}
