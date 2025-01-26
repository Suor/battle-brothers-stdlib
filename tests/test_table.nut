local Table = ::std.Table;

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

assertEq(Table.filter({a = 1, b = 2}, @(_, v) v > 1), {b = 2})
assertEq(Table.filter({a = 1, b = 2}, @(k, _) k == "a"), {a = 1})

assertEq(Table.map({a = 1, b = 2}, @(k, v) [v k]), {[1]= "a", [2]= "b"})

local t = {a = 1, b = 2};
Table.apply(t, @(k, v) k + v);
assertEq(t, {a = "a1", b = "b2"})

assertEq(Table.mapKeys({a = 1, b = 2}, @(k, v) k + v), {a1 = 1, b2 = 2})
assertEq(Table.mapValues({a = 1, b = 2}, @(k, v) k + v), {a = "a1", b = "b2"})
assertEq(Table.mapValues({a = 1, b = 2}, @(_, v) v*2), {a = 2, b = 4})


print("Table OK\n")
