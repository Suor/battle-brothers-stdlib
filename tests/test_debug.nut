local Debug = ::std.Debug, Str = ::std.Str, Re = ::std.Re;

// Debug
local function stripPre(_s) {
    return Str.cutsuffix(Str.cutprefix(_s, "<pre>"), "\n</pre>")
}
local function clean(_s) {
    return stripPre(Re.replace(_s, @"0x0x[0-9a-f]+", "<hash>"))
}

Debug.log("message")
assertEq(Log.last, "message")
Debug.log("name", {a = 1})
assertEq(Log.last, "<pre>name = {a = 1}\n</pre>")
assertEq(Debug.enabled, true);

Debug.log("k", {a = {b = 1}}, {depth = 2})
assertEq(Log.last, "<pre>k = {a = {b = 1}}\n</pre>")
Debug.log("k", {a = {b = 1}}, {depth = 1})
assert(Re.test(Log.last, @"k = \{a = \(table : \S+\)\}"))

Debug.log("k", 1);
assertEq(Log.last, "<pre>k = 1\n</pre>")
Debug.log("k", {a = 1}, 1);
assertEq(Log.last, "<pre>k = {a = 1}\n</pre>")
Debug.log("k", {a = {b = 1}}, 1);
assert(Re.test(Log.last, @"k = \{a = \(table : \S+\)\}"))
Debug.log("k", {a = {b = 1}}, "x");
assertEq(Log.last, "<pre>k = {...}\n</pre>")
Debug.log("k", {a = {b = 1}}, "b");
assertEq(Log.last, "<pre>k = {a = {b = 1}}\n</pre>")
Debug.log("k", {a = {b = 1, d = 3}, c = 2}, "b");
assertEq(Log.last, "<pre>k = {a = {b = 1, ...}, ...}\n</pre>")
Debug.log("k", {a = {b = 1, d = 3}, c = 2}, "b", 1);
assertEq(Log.last, "<pre>k = {...}\n</pre>")
Debug.log("k", {a = {b = 1, d = 3}, c = 2}, "a", 1);
assertEq(clean(Log.last), "k = {a = (table : <hash>), ...}")

::std.debug({a = {b = 1, d = 3}, c = 2}, "a", 1);
assertEq(clean(Log.last), "{a = (table : <hash>), ...}")

// Debug.noop
Log.last = null;
Debug.noop().log("name", {a = 1});
assertEq(Log.last, null);
assertEq(Debug.noop().enabled, false);

// Done
print("Debug OK\n")
