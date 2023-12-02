::std.Array <- {
    function concat(...){
        local res = [];
        foreach (arr in vargv) res.extend(arr);
        return res
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

    function findBy(arr, pred) {
        foreach (i, item in arr) {
            if (pred(item)) return i;
        }
    }
    // function zip(a1, a2) {
    // }
}
