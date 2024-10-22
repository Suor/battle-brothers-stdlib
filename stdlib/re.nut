local Re, Array = ::std.Array;
Re = ::std.Re <- {
    function find(str, re) {
        if (typeof re == "string") re = regexp(re);
        return Re._captureToValue(str, re.capture(str));
    }

    function test(str, re) {
        if (typeof re == "string") re = regexp(re);
        return re.capture(str) != null;
    }

    function all(str, re) {
        if (typeof re == "string") re = regexp(re);

        local res = [], pos = 0;
        while (pos < str.len()) {
            local c = re.capture(str, pos)
            if (c == null) break;
            res.push(Re._captureToValue(str, c));
            pos = c[0].end;
        }
        return res;
    }

    function replace(str, re, repl) {
        local count = 2147483647; // Maybe expose it in future
        if (typeof re == "string") re = regexp(re);

        local res = "", pos = 0, n = 0;
        while (n < count && pos < str.len()) {
            local c = re.capture(str, pos)
            if (c == null) break;
            n++;

            local replString = repl;
            if (typeof repl == "function") {
                local v = Re._captureToValue(str, c);
                replString = typeof v == "array" ? repl.acall(Array.concat([null], v)) : repl(v);
            }
            res += str.slice(pos, c[0].begin) + replString;
            pos = c[0].end;
        }
        return n > 0 ? res + str.slice(pos) : str;
    }

    function _captureToValue(str, capture) {
        if (capture == null) return null;

        local len = capture.len();
        if (len == 1 || len == 2) return Re._matchToStr(str, capture.top(), 0, str.len());
        local low = ::Math.max(capture[0].begin, 0);
        local high = ::Math.min(capture[0].end, str.len());
        return capture.slice(1).map(@(c) Re._matchToStr(str, c, low, high));
    }

    function _matchToStr(str, m, low, high) {
        local found = m.begin >= low && m.end >= low && m.begin <= high && m.end <= high;
        return found ? str.slice(m.begin, m.end) : null;
    }
}
