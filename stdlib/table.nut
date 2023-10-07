::std.Table <- {
    function keys(data) { // Just .keys() in newer Squirrel
        local res = [];
        foreach (key, _ in data) res.push(key);
        return res;
    }
    function values(data) { // Just .values() in newer Squirrel
        local res = [];
        foreach (_, value in data) res.push(value);
        return res;
    }

    function extend(dst, src) {
        foreach (key, value in src) {
            dst[key] <- value
        }
        return dst;
    }
    function merge(t1, t2) {
        if (t1 == null) return t2;
        if (t2 == null) return t1; // weird behavior
        return this.extend(clone t1, t2);
    }
    function deepExtend(dst, src) {
        foreach (key, value in src) {
            if (typeof value == "table" && key in dst && typeof dst[key] == "table") {
                this.deepExtend(dst[key], value)
            } else {
                dst[key] <- value
            }
        }
        return dst;
    }
    // Q: should this be cloning everything, e.g. be share nothing with its arguments?
    // function deepMerge(t1, t2) {
    //     return this.deepExtend(this.deepExtend({}, t1), t2);
    // }

    // TODO:
    //    apply()
    //    map()
    //    filter()
    //    each()
    //    mapKeys()
    //    mapValues()
}
