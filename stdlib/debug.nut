local Util = ::std.Util;

local function joinLength(items, sepLen) {
    if (items.len() == 0) return 0;
    return Util.sum(items.map(@(s) s.len())) + (items.len() - 1) * sepLen;
}

local function indent(level, s) {
    return format("%"+ (level * 4) + "s", "") + s;
}

local Debug;
Debug = ::std.Debug <- {
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
                lines.extend(items.map(@(item) indent(level + 1, item)));
                lines.push(indent(level, end));
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
        } else if (typeof data == "string") {
            return "\"" + Str.replace(data, "\"", "\\\"") + "\"" + endln;
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
}

// TODO: sort indexes
// TODO: add filter
::std.debug <- function(data, options = {}) {
    this.logInfo("<pre>" + Debug.pp(data, options) + "</pre>")
}
