local Str = ::std.Str, Re = ::std.Re, Debug = ::std.Debug, Util = ::std.Util, Array = ::std.Array;

function assertEq(a, b) {
    if (Util.deepEq(a, b)) return;
    throw "assertEq failed:\na = " + Debug.pp(a) + "b = " + Debug.pp(b);
}
