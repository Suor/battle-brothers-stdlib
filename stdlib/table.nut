::std.Table <- {
    function extend(dst, src) {
        foreach (key, value in src) {
            dst[key] <- value
        }
        return dst;
    }
    function merge(t1, t2) {
        if (t1 == null) return t2;
        if (t2 == null) return t1;
        return this.extend(clone t1, t2);
    }
    function keys(data) { // Just .keys() in newer Squirrel
        local res = [];
        foreach (key, _ in data) res.push(key);
        return res;
    }
    function values(data) { // Just .values() in newer Squirrel
        local res = [];
        foreach (key, _ in data) res.push(values);
        return res;
    }
    // TODO:
    //   deepExtend
    //   deepMerge
    // TODO:
    //    apply()
    //    map()
    //    filter()
    //    each()
    //    mapKeys()
    //    mapValues()
}
