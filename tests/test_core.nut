local Str = ::std.Str, Re = ::std.Re, Text = ::std.Text,
    Debug = ::std.Debug, Util = ::std.Util, Array = ::std.Array, Table = ::std.Table;

// Str
assert(Str.cutprefix("some_event", "some") == "_event")
assert(Str.cutprefix("some_event", "other") == "some_event")
assert(Str.cutsuffix("some_event", "_event") == "some")
assert(Str.cutsuffix("some_event", "_item") == "some_event")

assert(Str.replace("hi, there. Hi, hi, bye", "hi", "hello") == "hello, there. Hi, hello, bye")
assert(Str.replace("hi, there. Hi, hi, bye", "hi", "hello", 1) == "hello, there. Hi, hi, bye")
assert(Str.replace("ababa", "aba", "_") == "_ba")

// Re
assert(Re.find("Ivan IV", " ([IVXLC]+)$") == "IV")
assert(Re.find("Ivan IV", " [IVXLC]+$") == " IV")
assert(Re.find("Ivan IV Formidable", " ([IVXLC]+)$") == null)
assert(Re.test("Ivan IV Formidable", " ([IVXLC]+)$") == false)
assert(Str.join("_", Re.find("Ivan IV", "^(\\w+) ([IVXLC]+)$")) == "Ivan_IV")

local versionRe = regexp(@"^(\d+)(?:\.(\d+))?$")
assertEq(Re.find("2.15", versionRe), ["2", "15"])
assertEq(Re.find("2", versionRe), ["2", null])

assertEq(Re.all("hi, there", @"\w+"), ["hi", "there"])
assertEq(Re.all("a = 12, xyz = 7", @"(\w+) = (\d+)"), [["a", "12"], ["xyz", "7"]])
assertEq(Re.all("a1a2a", "a\\d"), ["a1", "a2"])

assertEq(Re.replace("a1a23a", @"a\d+", "x_"), "x_x_a")
assertEq(Re.replace("_1_17_", @"_(\d+)", (@(m) "." + (m.tointeger() + 1))), ".2.18_")
assertEq(Re.replace("a1_b45", @"(\w)(\d+)", (@(c, d) c.toupper() + (d.tointeger() + 1))), "A2_B46")

// Text
assertEq(Text.positive("good"), "[color=green]good[/color]")
assertEq(Text.negative("bad"), "[color=red]bad[/color]")
assertEq(Text.plural(1), "")
assertEq(Text.plural(2), "s")
assertEq(Text.plural(11), "s")
assertEq(Text.plural(21), "")
assertEq(Text.plural(1, "wolf", "wolves"), "wolf")
assertEq(Text.plural(2, "wolf", "wolves"), "wolves")
assertEq(Text.plural(11, "wolf", "wolves"), "wolves")
assertEq(Text.plural(21, "wolf", "wolves"), "wolf")

// Array
assertEq(Array.sum([]), 0)
assertEq(Array.sum([1 2 3]), 6)
assert(Array.sum([1.1 2.2 3.3]) - 6.6 < 0.01)

assertEq(Array.max([]), null)
assertEq(Array.min([]), null)
assertEq(Array.max([42]), 42)
assertEq(Array.min([42]), 42)
assertEq(Array.max([1 5 2 0 3]), 5)
assertEq(Array.min([1 5 2 0 3]), 0)
assertEq(Array.max(["b" "x" "a" "k"]), "x")
assertEq(Array.min(["b" "x" "a" "k"]), "a")
assertEq(Array.max(["ab" "xyz" "ijkl" "stu"], @(x) x.len()), "ijkl")
assertEq(Array.min(["ab" "xyz" "ijkl" "stu"], @(x) x.len()), "ab")

// Table
assertEq(Table.keys({}), [])
assertEq(Table.keys({a = 1}), ["a"])
assertEq(Table.values({a = 1}), [1])

local t = {}
assertEq(Table.extend(t, {a = 1}), {a = 1})
assertEq(t, {a = 1})
local t = {}
assertEq(Table.merge(t, {a = 1}), {a = 1})
assertEq(t, {})

local t = {a = 7, z = "hi"}
assertEq(Table.deepExtend(t, {a = [1], b = {c = 42}}), {a = [1], b = {c = 42}, z = "hi"})
assertEq(t, {a = [1], b = {c = 42}, z = "hi"})

// local t = {a = 7, z = "hi"}
// assertEq(Table.deepMerge(t, {a = [1], b = {c = 42}}), {a = [1], b = {c = 42}, z = "hi"})
// assertEq(t, {a = 7, z = "hi"})


// Rand
local Rand = std.Rand.using(::rng_new(1));  // set generator with a fixed seed
assertEq(Rand.index(10), 5);
assertEq(Rand.index(3, [4 2 1]), 1);
assertEq(Rand.choice(["a" "b" "c"]), "a");
assertEq(Rand.choice(["a" "b" "c"], [1 10 10]), "b");
assertEq(Rand.choices(3, ["a" "b" "c"]), ["b" "b" "a"]);
assertEq(Rand.choices(3, ["a" "b" "c"], [3 2 1]), ["c" "a" "a"]);
assertEq(Rand.take(3, ["a" "b" "c" "d" "e"]), ["c" "a" "e"]);
assertEq(Rand.take(3, ["a" "b" "c" "d" "e"], [1 2 3 0 0]), ["a" "c" "b"]);

// Util
assertEq(Util.clamp(7, 1, 10), 7);
assertEq(Util.clamp(-1, 1, 10), 1);
assertEq(Util.clamp(10.1, 1, 10), 10);
assertEq(Util.clamp(0.099, 0.1, 0.2), 0.1);

// Done
print("Core OK\n")
