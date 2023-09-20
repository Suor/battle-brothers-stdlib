dofile("!stdlib.nut");
local Str = ::std.Str, Re = ::std.Re, Debug = ::std.Debug, Util = ::std.Util;


function assertEq(a, b) {
    if (Util.deepEq(a, b)) return;
    throw "assertEq failed:\na = " + Debug.pp(a) + "b = " + Debug.pp(b);
}

// Taken from modding hooks
::rng_new <- function(seed = 0)
{
  if(seed == 0) seed = (Time.getRealTimeF() * 1000000000).tointeger();
  return {
    x = seed, y = 234567891, z = 345678912, w = 456789123, c = 0,
    nextInt = function()
    {
      x += 1411392427;

      y = y ^ (y<<5);
      y = y ^ (y>>>7);
      y = y ^ (y<<22);

      local t = z + w + c;
      z  = w;
      c  = t >>> 31; // c = (signed)t < 0 ? 1 : 0
      w  = t & 0x7FFFFFFF;

      return (x + y + w) & 0x7FFFFFFF;
    },
    nextFloat = function()
    {
      return nextInt() / 2147483648.0;
    },
    next = function(a, b = null)
    {
      if(b == null)
      {
        if(a <= 0) throw "a must be > 0";
        return nextInt() % a + 1;
      }
      else
      {
        if(a > b) throw "a must be <= than b";
        return nextInt() % (b-a+1) + a;
      }
    }
  }
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

// Done
print("Tests OK\n")
