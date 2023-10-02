local Array = ::std.Array, Table = ::std.Table, Packer = ::std.Packer, Util = ::std.Util;
Table.extend(Util, {
    // These are moved to appropriate namespaces, here for backwards compatibility
    concat = Array.concat
    keys = Table.keys
    merge = Table.merge
    extend = Table.extend
    all = Array.all
    any = Array.any
    sum = Array.sum

    // Shortcuts
    pack = Packer.pack
    unpack = Packer.unpack

    function clamp(value, min, max) {
        return value >= max ? max : value <= min ? min : value;
    }

    function deepEq(a, b) {
        if (a == b) return true;
        if (typeof a != typeof b) return false;

        if (typeof a == "string" || typeof a == "integer" || typeof a == "float") {
            return a == b;
        } else if (typeof a == "array") {
            if (a.len() != b.len()) return false;
            foreach (i, x in a)
                if (!Util.deepEq(x, b[i])) return false;
            return true
        } else if (typeof a == "table") {
            if (a.len() != b.len()) return false;
            foreach (k, v in a)
                if (!(k in b) || !Util.deepEq(v, b[k])) return false;
            return true
        }
        throw "Don't know how to compare " + typeof a;
    }
})
