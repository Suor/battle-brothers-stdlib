::std.Array <- {
    function cat(aoa){
        local res = [];
        foreach (arr in aoa) res.extend(arr);
        return res
    }
    function concat(...){
        return ::std.Array.cat(vargv);
    }

    function all(arr, func) {
        foreach (item in arr) {
            if (!func(item)) return false;
        }
        return true;
    }
    function any(arr, func) {
        foreach (item in arr) {
            if (func(item)) return true;
        }
        return false;
    }
    function max(arr, key = null) {
        local choose = key ? @(a, b) key(a) >= key(b) ? a : b : @(a, b) a >= b ? a : b;
        return arr.reduce(choose);
    }
    function min(arr, key = null) {
        local choose = key ? @(a, b) key(a) <= key(b) ? a : b : @(a, b) a <= b ? a : b;
        return arr.reduce(choose);
    }
    function sum(arr) {
        local total = 0;
        foreach (x in arr) total += x;
        return total;
    }
    function count(arr, pred) {
        local n = 0;
        foreach (item in arr) if (pred(item)) n++;
        return n;
    }

    function without(arr, ...) {
        return arr.filter(@(_, v) vargv.find(v) == null);
    }
    function diff(arr1, arr2) {
        return arr1.filter(@(_, v) arr2.find(v) == null);
    }
    function intersect(arr1, arr2) {
        return arr1.filter(@(_, v) arr2.find(v) != null);
    }

    function first(arr, pred) {
        foreach (item in arr) {
            if (pred(item)) return item;
        }
        return null;
    }
    function findBy(arr, pred) {
        foreach (i, item in arr) {
            if (pred(item)) return i;
        }
    }
    // function zip(a1, a2) {
    // }

    // TODO: more efficient implementation
    function nlargest(_n, _arr, _key = null) {
        if (_n == 0) return [];
        if (_n == 1) return [::std.Array.max(_arr, _key)];

        local arr = clone _arr;
        if (_key) arr.sort(@(a, b) _key(b) <=> _key(a));
        else {
            arr.sort();
            arr.reverse();
        }
        return arr.len() < _n ? arr : arr.slice(0, _n);
    }
}
::std.Array.some <- ::std.Array.first;
