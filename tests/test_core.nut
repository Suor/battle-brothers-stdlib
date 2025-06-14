local Str = ::std.Str, Re = ::std.Re, Text = ::std.Text, Iter = ::std.Iter,
    Util = ::std.Util, Array = ::std.Array, Table = ::std.Table;

// Str
assert(Str.cutprefix("some_event", "some") == "_event")
assert(Str.cutprefix("some_event", "other") == "some_event")
assert(Str.cutsuffix("some_event", "_event") == "some")
assert(Str.cutsuffix("some_event", "_item") == "some_event")

assert(Str.replace("hi, there. Hi, hi, bye", "hi", "hello") == "hello, there. Hi, hello, bye")
assert(Str.replace("hi, there. Hi, hi, bye", "hi", "hello", 1) == "hello, there. Hi, hi, bye")
assert(Str.replace("ababa", "aba", "_") == "_ba")

assertEq(Str.split(", ", "hi, there"), ["hi", "there"])
assertEq(Str.split(" ", "hi  there"), ["hi", "", "there"])
assertEq(Str.split("zyx", "hi, there"), ["hi, there"])
assertEq(Str.split(".", "a.b.c"), ["a", "b", "c"])
assertEq(Str.split(".", "a.b.c", 1), ["a", "b.c"])

assertEq(Str.escapeHTML("Hi<br>"), "Hi&lt;br&gt;")
assertEq(Str.escapeHTML("Hi&nbsp;"), "Hi&amp;nbsp;")

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

assertEq(Re.escape("hi, x."), @"hi, x\.")
assertEq(Re.escape("hi\nx"), @"hi\nx")
assertEq(Re.escape("hi\tx\r"), @"hi\tx\r")

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

// Iter
assertEq(Iter.toArray(Iter.chunks(2, "12345")), ["12" "34" "5"]);
assertEq(Iter.toArray(Iter.chunks(2, [1 2 3 4 5])), [[1 2], [3 4], [5]]);

// Rand
local Rand = std.Rand.using(::std.rng_new(1));  // set generator with a fixed seed
assertEq(Rand.index(10), 5);
assertEq(Rand.index(3, [4 2 1]), 1);
assertEq(Rand.choice(["a" "b" "c"]), "a");
assertEq(Rand.choice(["a" "b" "c"], [1 10 10]), "b");
assertEq(Rand.choices(3, ["a" "b" "c"]), ["b" "b" "a"]);
assertEq(Rand.choices(3, ["a" "b" "c"], [3 2 1]), ["c" "a" "a"]);
assertEq(Rand.take(3, ["a" "b" "c" "d" "e"]), ["c" "a" "e"]);
assertEq(Rand.take(3, ["a" "b" "c" "d" "e"], [1 2 3 0 0]), ["a" "c" "b"]);
assertEq(Rand.take(3, ["a" "b"], [0 1]), ["b" "a"]); // Check Iter.take() stops
assertEq(Rand.int(0, 100.5), 57) // Proper float handling

// Util
assertEq(Util.clamp(7, 1, 10), 7);
assertEq(Util.clamp(-1, 1, 10), 1);
assertEq(Util.clamp(10.1, 1, 10), 10);
assertEq(Util.clamp(0.099, 0.1, 0.2), 0.1);

assertEq(Util.round(1.1), 1);
assertEq(Util.round(1.6), 2);
assertEq(Util.round(1.11, 1), 1.1);
assertEq(Util.round(1.117, 2), 1.12);
assertEq(Util.round(123, -1), 120);
assertEq(Util.round(375, -2), 400);

// TODO: getMember()? isKindOf()?


// Done
print("Core OK\n")
