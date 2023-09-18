dofile("!stdlib.nut");
local Str = std.Str, Re = std.Re, Debug = std.Debug;

function deepEq(a, b) {
    if (a == b) return true;
    if (typeof a != typeof b) return false;

    if (typeof a == "string" || typeof a == "integer" || typeof a == "float") {
        return a == b;
    } else if (typeof a == "array") {
        if (a.len() != b.len()) return false;
        foreach (i, x in a)
            if (!deepEq(x, b[i])) return false;
        return true
    }
    throw "Don't know how to compare " + typeof a;
}
function assertEq(a, b) {
    if (deepEq(a, b)) return;

    throw "assertEq failed:\na = " + Debug.pp(a) + "b = " + Debug.pp(b);
}


// Str
assert(Str.cutprefix("some_event", "some") == "_event")
assert(Str.cutprefix("some_event", "other") == "some_event")
assert(Str.cutsuffix("some_event", "_event") == "some")
assert(Str.cutsuffix("some_event", "_item") == "some_event")

assert(Str.replace("hi, there. Hi, hi, bye", "hi", "hello") == "hello, there. Hi, hello, bye")
assert(Str.replace("hi, there. Hi, hi, bye", "hi", "hello", 1) == "hello, there. Hi, hi, bye")
assert(Str.replace("ababa", "aba", "_") == "_ba")

// Re
// TODO: string first or pattern first???
assert(Re.find(" ([IVXLC]+)$", "Ivan IV") == "IV")
assert(Re.find(" [IVXLC]+$", "Ivan IV") == " IV")
assert(Re.find(" ([IVXLC]+)$", "Ivan IV Formidable") == null)
assert(Str.join("_", Re.find("^(\\w+) ([IVXLC]+)$", "Ivan IV")) == "Ivan_IV")

local versionRe = regexp("^(\\d+)(?:\\.(\\d+))?$")
assertEq(Re.find(versionRe, "2.15"), ["2", "15"])
assertEq(Re.find(versionRe, "2"), ["2", null])

assertEq(Re.all("\\w+", "hi, there"), ["hi", "there"])
assertEq(Re.all("(\\w+) = (\\d+)", "a = 12, xyz = 7"), [["a", "12"], ["xyz", "7"]])
assertEq(Re.all("a\\d", "a1a2a"), ["a1", "a2"])

assertEq(Re.replace("a\\d+", "x_", "a1a23a"), "x_x_a")
assertEq(Re.replace("_(\\d+)", (@(m) "." + (m.tointeger() + 1)), "_1_17_"), ".2.18_")
// Not supported yet, TODO: decide on the API
// assertEq(Re.replace("(\\w)(\\d+)", (@(m) m[0].toupper() + (m[1].tointeger() + 1)), "a1_b45"), "A2_B46")
// assertEq(Re.replace("(\\w)(\\d+)", (@(c, d) c.toupper() + (d.tointeger() + 1)), "a1_b45"), "A2_B46")


// Done
print("Tests passed\n")
