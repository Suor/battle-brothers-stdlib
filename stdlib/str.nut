local Str;
Str = ::std.Str <- {
    function replace(str, old, new, count = 2147483647) {
        local res = "", pos = 0, n = 0;
        while (n < count && pos < str.len()) {
            local next = str.find(old, pos);
            if (next == null) break;
            n++;
            res += str.slice(pos, next) + new;
            pos = next + old.len();
        }
        return n > 0 ? res + str.slice(pos) : str;
    }

    function startswith(s, sub) {
        if (s.len() < sub.len()) return false;
        return s.slice(0, sub.len()) == sub;
    }
    function endswith(s, sub) {
        if (s.len() < sub.len()) return false;
        return s.slice(-sub.len()) == sub;
    }
    function cutprefix(s, sub) {
        return Str.startswith(s, sub) ? s.slice(sub.len()) : s;
    }
    function cutsuffix(s, sub) {
        return Str.endswith(s, sub) ? s.slice(0, -sub.len()) : s;
    }

    function split(sep, s, count = 2147483647) {
        local parts = [], seplen = sep.len(), n = 0, prev = 0, pos;
        while (n < count && (pos = s.find(sep, prev))) {
            parts.push(s.slice(prev, pos));
            prev = pos + seplen;
            n++;
        }
        parts.push(s.slice(prev))
        return parts;
    }
    function join(sep, lines) {
        local s = "";
        foreach (i, line in lines) {
            if (i > 0) s += sep;
            s += line;
        }
        return s;
    }

    function capitalize(str) {
        if (str == "") return str;
        return str.slice(0, 1).toupper() + str.slice(1);
    }
    // Q: should we only capitalize after space, ",." whatever?
    // function title(str) {
    //     return Re.replace(str, "[a-zA-Z]+", @(w) Str.capitalize(w));
    // }
}
