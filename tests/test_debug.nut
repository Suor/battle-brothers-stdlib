local Debug = ::std.Debug, Str = ::std.Str, Re = ::std.Re;

local last = null, prevLogInfo = ::logInfo;
::logInfo = function (_s) {last = _s}

// Debug
local function stripPre(_s) {
    return Str.cutsuffix(Str.cutprefix(_s, "<pre>"), "\n</pre>")
}
local function clean(_s) {
    return stripPre(Re.replace(_s, @"0x0x[0-9a-f]+", "<hash>"))
}

assertEq(Debug.pp({}), "{}\n")

Debug.log("message")
assertEq(last, "message")
Debug.log("name", {a = 1})
assertEq(last, "<pre>name = {a = 1}\n</pre>")
assertEq(Debug.enabled, true);

Debug.log("k", {a = {b = 1}}, {depth = 2})
assertEq(last, "<pre>k = {a = {b = 1}}\n</pre>")
Debug.log("k", {a = {b = 1}}, {depth = 1})
assert(Re.test(last, @"k = \{a = \(table : \S+\)\}"))

Debug.log("k", 1);
assertEq(last, "<pre>k = 1\n</pre>")
Debug.log("k", {a = 1}, 1);
assertEq(last, "<pre>k = {a = 1}\n</pre>")
Debug.log("k", {a = {b = 1}}, 1);
assert(Re.test(last, @"k = \{a = \(table : \S+\)\}"))
Debug.log("k", {a = {b = 1}}, "x");
assertEq(last, "<pre>k = {...}\n</pre>")
Debug.log("k", {a = {b = 1}}, "b");
assertEq(last, "<pre>k = {a = {b = 1}}\n</pre>")
Debug.log("k", {a = {b = 1, d = 3}, c = 2}, "b");
assertEq(last, "<pre>k = {a = {b = 1, ...}, ...}\n</pre>")
Debug.log("k", {a = {b = 1, d = 3}, c = 2}, "b", 1);
assertEq(last, "<pre>k = {...}\n</pre>")
Debug.log("k", {a = {b = 1, d = 3}, c = 2}, "a", 1);
assertEq(clean(last), "k = {a = (table : <hash>), ...}")

Debug.log("k", {a = {b = 1, d = 3}, c = 2}, {filter = @(k, v) v == 1});
assertEq(clean(last), "k = {a = {b = 1, ...}, ...}")

::std.debug({a = {b = 1, d = 3}, c = 2}, "a", 1);
assertEq(clean(last), "{a = (table : <hash>), ...}")

// Debug.noop
last = null;
Debug.noop().log("name", {a = 1});
assertEq(last, null);
assertEq(Debug.noop().enabled, false);

::logInfo = prevLogInfo;

// Done
print("Debug OK\n")
