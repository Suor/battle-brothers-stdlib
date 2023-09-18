// Alias things to make it easier for us inside. These are still global and accessible from outside
// Ensure only the latest version goes as ::std
local version = 1.3;
if ("std" in getroottable() && ::std.version >= version) return;
local std = ::std <- {version = version};
local Str = std.Str <- {},
      Re = std.Re <- {},
      Util = std.Util <- {},
      Table = std.Table <- {},
      Array = std.Array <- {},
      Rand = std.Rand <- {},
      Debug = std.Debug <- {},
      Hook = std.Hook <- {};

// Since we use forward declarations we can't override, we should extend tables.
local function extend(dst, src) {
    foreach (key, value in src) {
        dst[key] <- value
    }
    return dst;
}

extend(Str, {
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
    function join(sep, lines) {
        local s = "";
        foreach (i, line in lines) {
            if (i > 0) s += sep;
            s += line;
        }
        return s;
    }
    function indent(level, s) {
        return format("%"+ (level * 4) + "s", "") + s;
    }
})

extend(Re, {
    function find(re, str) {
        if (typeof re == "string") re = regexp(re);
        return Re._captureToValue(str, re.capture(str));
    }

    function all(re, str) {
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

    function replace(re, repl, str) {
        local count = 2147483647; // Maybe expose it in future
        if (typeof re == "string") re = regexp(re);

        local res = "", pos = 0, n = 0;
        while (n < count && pos < str.len()) {
            local c = re.capture(str, pos)
            if (c == null) break;
            n++;

            local replString = repl
            if (typeof repl == "function") {
                local v = Re._captureToValue(str, c);
                if (typeof v != "string")
                    throw "Re.replace() with multible () and a callback not supported yet";
                replString = repl(v);
            }
            res += str.slice(pos, c[0].begin) + replString;
            pos = c[0].end;
        }
        return n > 0 ? res + str.slice(pos) : str;
    }

    function _captureToValue(str, capture) {
        if (capture == null) return null;

        local len = capture.len();
        if (len == 1 || len == 2) return Re._matchToStr(str, capture.top());
        return capture.slice(1).map(@(c) Re._matchToStr(str, c));
    }

    function _matchToStr(str, m) {
        local len = str.len();
        local found = m.begin >= 0 && m.end >= 0 && m.begin < len && m.end <= len;
        return found ? str.slice(m.begin, m.end) : null;
    }
})

extend(Table, {
    extend = extend
    function merge(t1, t2) {
        if (t1 == null) return t2;
        if (t2 == null) return t1;
        return extend(clone t1, t2);
    }

    function keys(data) {
        local res = [];
        foreach (key, _ in data) res.push(key);
        return res;
    }
})

extend(Array, {
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
})

extend(Util, {
    // These are moved to appropriate namespaces, here for backwards compatibility
    concat = Array.concat
    keys = Table.keys
    merge = Table.merge
    extend = extend
    all = Array.all
    any = Array.any

    function sum(arr) {
        return arr.reduce(@(a, b) a + b);
    }
})


// Higher level random helpers

extend(Rand, {
    function int(a, b) {
        return ::Math.rand(a ,b);
    }
    function float(a = null, b = null) {
        local r = this.int(0, 2147483647) / 2147483648.0;
        if (a == null && b == null) return r;
        return a + r * (b - a);
    }
    function range(from, to) {return this.float(from, to)}

    function chance(prob) {
        return this.float() < prob;
    }

    function choice(options, weights = null, _total = null) {
        if (_weights == null) return options[this.Math.rand(0, options.len() - 1)];

        local total = _total != null ? _total : Util.sum(weights);
        local roll = this.float() * total;
        for (local i = 0; i < weights.len(); i++) {
            roll -= weights[i];
            if (roll <= 0) return options[i];
        }
        return options.top(); // To be safe
    }
    function choices(num, options, weights = null) {
        local res = [];
        if (weights == null) {
            for (local i = 0; i < num; i++) res.push(this.choice(options));
        } else {
            local total = Util.sum(weights);
            for (local i = 0; i < num; i++) res.push(this.choice(options, weights, total));
        }
        return res;
    }
    function weighted(weights, options) { // Deprecated
        return this.choice(options, weights);
    }
    function take(num, options, _weights = null) {
        local N = options.len()
        local weights = _weights == null ? array(N, 1) : clone _weights;
        local total = Util.sum(weights);

        local indices = array(N);
        for (local i = 0; i < N; i++) indices[i] = i;

        local result = [];
        for (local done = 0; done < num; done++) {
            local i = this.choice(indices, weights, total);
            result.push(options[i]);
            total -= weights[i];
            weights[i] = 0;
        }
        return result;
    }

    function insert(arr, item, num = 1) {
        for (local i = 0; i < num; i++) {
            local index = this.int(0, arr.len());
            arr.insert(index, item);
        }
    }

    function poly(tries, prob) {
        if (prob <= 0 || tries < 1) return 0;

        local num = 0;
        for (local i = 0; i < tries; i++)
            if (this.chance(prob)) num++;
        return num;
    }

    // Create a new Rand with a replaced backend:
    //     local Rand = ::std.Rand.using(::rng);
    //     local Rand = ::std.Rand.using(::rng_new(seed));
    //     ... use it as usual ...
    function using(gen) {
        return Util.merge(this, {
            function int(a, b) {
                return a >= 0 ? gen.next(a, b) : a + gen.next(0, b - a)
            }
        })
    }
})


// Debug things

local function joinLength(items, sepLen) {
    if (items.len() == 0) return 0;
    return Util.sum(items.map(@(s) s.len())) + (items.len() - 1) * sepLen;
}

extend(Debug, {
    DEFAULTS = {prefix = "", width = 100, depth = 3, funcs = "count"}

    // Pretty print a data structure. Options:
    //     width   max line width in chars
    //     depth   max depth to show
    //     funcs   how functions should be shown ("count" | "full" | false)
    // See option defaults above.
    function pp(data, options = {}, level = 0) {
        local function ppCont(items, level, start, end) {
            if (joinLength(items, 2) <= options.width - level * 4 - 2) {
                return start + Str.join(", ", items) + end;
            } else {
                local lines = [start];
                lines.extend(items.map(@(item) Str.indent(level + 1, item)));
                lines.push(Str.indent(level, end));
                return Str.join("\n", lines);
            }
        }

        if (level == 0) options = Util.merge(Debug.DEFAULTS, options);
        if (level >= options.depth) return "" + data;  // More robust than .tostring()

        local endln = (level == 0 ? "\n" : "");

        if (typeof data == "instance") {
            try {

                data = data.getdelegate();
            } catch (exception) {
                // do nothing
            }
        }

        if (typeof data == "table") {
            if ("pp" in data) return data.pp;

            local items = [], funcs = 0;
            foreach (k, v in data) {
                if (typeof v == "function") {
                    funcs += 1;
                    if (options.funcs != "full") continue;
                }
                items.push(k + " = " + Debug.pp(v, options, level + 1))
            }
            if (options.funcs == "count" && funcs) items.push("(" + funcs + " functions)");
            return ppCont(items, level, "{", "}") + endln;
        } else if (typeof data == "array") {
            local items = data.map(@(item) Debug.pp(item, options, level + 1));
            return ppCont(items, level, "[", "]") + endln;
        } else if (data == null) {
            return "null" + endln;
        } else {
            return "" + data + endln;
        }
    }

    function log(name, data, options = {}) {
        this.logInfo("<pre>" + this.DEFAULTS.prefix + name + " = " + Debug.pp(data, options) + "</pre>");
    }

    // Create a new Debug with changed default options:
    //     local Debug = ::std.Debug.with({prefix: "my-module: ", width: 120});
    //     Debug.log("enemy", enemy);
    function with(options) {
        return Util.merge(this, {DEFAULTS = Util.merge(this.DEFAULTS, options)})
    }
})

std.debug <- function(data, options = {}) {
    this.logInfo("<pre>" + Debug.pp(data, options) + "</pre>")
}
