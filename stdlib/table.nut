::std.Table <- {
    function get(table, key, def = null) {
        return key in table ? table[key] :  def;
    }
    function getIn(table, keys, def = null) {
        foreach (key in keys) {
            if (key in table) table = table[key];
            else return def;
        }
        return table;
    }

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

    function setDefaults(dst, defaults) {
        foreach (key, value in defaults) {
            if (!(key in dst)) dst[key] <- value
        }
    }

    function filter(_table, _func) {
        local res = {};
        foreach (k, v in _table) {
            if (_func(k, v)) res[k] <- v;
        }
        return res;
    }
    function map(_table, _func) {
        local res = {};
        foreach (k, v in _table) {
            local pair = _func(k, v);
            res[pair[0]] <- pair[1]
        }
        return res;
    }
    function apply(_table, _func) {
        foreach (k, v in _table) _table[k] <- _func(k, v);
    }
    function mapKeys(_table, _func) {
        local res = {};
        foreach (k, v in _table) res[_func(k, v)] <- v;
        return res;
    }
    function mapValues(_table, _func) {
        local res = {};
        foreach (k, v in _table) res[k] <- _func(k, v);
        return res;
    }
}
