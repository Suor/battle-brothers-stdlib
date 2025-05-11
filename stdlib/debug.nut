local Util = ::std.Util, Str = ::std.Str;

local function joinLength(items, sepLen) {
    if (items.len() == 0) return 0;
    return Util.sum(items.map(@(s) s.len())) + (items.len() - 1) * sepLen;
}

local function indent(level, s) {
    return format("%"+ (level * 4) + "s", "") + s;
}

local function isTile(_obj) {
    return "__getTable" in _obj && "X" in _obj.__getTable && "Y" in _obj.__getTable;
}

local Debug;
Debug = ::std.Debug <- {
    // TODO: re filter?
    DEFAULTS = {prefix = "", width = 100, depth = 3, funcs = "count", filter = null, repr = false}

    reprs = {
        function actor(_a) {
            local s = _a.getName();
            if (_a.isPlacedOnMap()) s += " at " + tile(_a.getTile())
            return s;
        }
        function skill(_s) {return _s.ClassName}
        function tile(_t) {return _t.X + ", " + _t.Y}
    }
    function _guessType(_obj) {
        if (Util.isKindOf(_obj, "skill")) return "skill";
        else if (Util.isKindOf(_obj, "actor")) return "actor";
        else if (isTile(_obj)) return "tile";
    }

    // Pretty print a data structure. Options:
    //     width   max line width in chars
    //     depth   max depth to show
    //     funcs   how functions should be shown ("count" | "full" | false)
    //     filter  only show keys containing this string
    //     repr    concise reprs for actor, skill, tile
    // See option defaults above.
    function pp(data, _opts = {}, _level = 0, _prepend = "") {
        if (_level == 0) _opts = Util.merge(this.DEFAULTS, this._interpret([_opts]));

        local startln = (_level == 0 ? _opts.prefix + _prepend : "");
        local endln = (_level == 0 ? "\n" : "");

        local function ppCont(items, _level, start, end) {
            if (joinLength(items, 2) + _level * 4 + start.len() + end.len() + startln.len()
                    <= _opts.width) {
                return start + Str.join(", ", items) + end;
            } else {
                local lines = [start];
                lines.extend(items.map(@(item) indent(_level + 1, item)));
                lines.push(indent(_level, end));
                return Str.join("\n", lines);
            }
        }
        local function isEmpty(v, vpp) {
            return (typeof v != "table" || vpp == "{}" || vpp == "{...}")
                && (typeof v != "array" || vpp == "[]" || vpp == "[...]")
        }

        if (_opts.repr) {
            local type = _guessType(data);
            if (type != null) return startln + reprs[type](data) + endln;
        }

        local cls = null;
        if (typeof data == "instance") {
            cls = "instance";
            if (data instanceof ::WeakTableRef) {
                cls = "weakref";
                data = data.get();
            } else {
                // Turn instance into table if possible
                try {
                    local contents = {};
                    foreach (k, _ in data.getclass()) contents[k] <- data[k];
                    data = contents;
                } catch (exception) {
                    // do nothing
                }
            }
        }

        if (typeof data == "table") {
            if (_opts.filter && _level >= _opts.depth) return data.len() > 0 ? "{...}" : "{}";
            if ("pp" in data) return startln + data.pp + endln;
            if (_level >= _opts.depth) return startln + data + endln;

            local items = [], funcs = 0, skipped = 0;
            foreach (k, v in data) {
                if (typeof v == "function") {
                    funcs += 1;
                    if (_opts.funcs != "full") continue;
                }
                local vpp;
                if (_opts.filter && (k + "").find(_opts.filter) != null) {
                    vpp = Debug.pp(v, Util.merge(_opts, {filter = null}), _level + 1, k + " = ")
                } else {
                    vpp = Debug.pp(v, _opts, _level + 1, k + " = ");
                }
                if (_opts.filter && isEmpty(v, vpp) && (k + "").find(_opts.filter) == null) {
                    skipped++; continue;
                };
                items.push(k + " = " + vpp)
            }
            items.sort();
            if (skipped) items.push("...");
            if (_opts.funcs == "count" && funcs && !_opts.filter)
                items.push("(" + funcs + " function" + (funcs > 1 ? "s" : "") + ")");
            return startln + ppCont(items, _level, cls ? cls + " {" : "{", "}") + endln;
        } else if (typeof data == "array") {
            if (_opts.filter && _level >= _opts.depth - 1) return data.len() > 0 ? "[...]" : "[]";
            if (_level >= _opts.depth) return startln + data + endln;

            local items = [], skipped = 0;
            foreach (v in data) {
                local vpp = Debug.pp(v, _opts, _level + 1);
                if (_opts.filter && isEmpty(v, vpp)) {skipped++; continue;};
                items.push(vpp)
            }
            if (skipped) items.push("...");
            return startln + ppCont(items, _level, "[", "]") + endln;
        } else if (data == null) {
            return startln + "null" + endln;
        } else if (typeof data == "string") {
            return startln + "\"" + Str.replace(data, "\"", "\\\"") + "\"" + endln;
        } else {
            return startln + data + endln;
        }
    }

    function repr(data, _opts = {}) {
        return pp(data, Util.merge(_opts, {repr = true}));
    }

    function _interpret(_optValues) {
        local opts = {};
        foreach (val in _optValues) {
            if (typeof val == "integer") opts.depth <- val;
            if (typeof val == "string") opts.filter <- val;
            if (typeof val == "table") Util.extend(opts, val);
        }
        return opts;
    }

    function log(name, ...) {
        // data, _opts
        if (vargv.len() == 0) {
            ::logInfo(this.DEFAULTS.prefix + name);
            return;
        }
        local data = vargv[0];
        local opts = this._interpret(vargv.slice(1));
        ::logInfo("<pre>" + this.pp(data, opts, 0, name + " = ") + "</pre>");
    }

    function logRepr(_name, _val, ...) {
        local opts = this._interpret(vargv);
        opts.repr <- true;
        log(_name, _val, opts);
    }

    // Create a new Debug with changed default options:
    //     local Debug = ::std.Debug.with({prefix: "my-module: ", width: 120});
    //     Debug.log("enemy", enemy);
    function with(_opts) {
        return Util.merge(this, {DEFAULTS = Util.merge(this.DEFAULTS, _opts)})
    }

    enabled = true
    function noop() {
        return {
            enabled = false
            function pp(data, _opts = {}, _level = 0, _prepend = "") {}
            function log(name, ...) {}
        }
    }
}

::std.debug <- function (data, ...) {
    this.logInfo("<pre>" + Debug.pp(data, Debug._interpret(vargv)) + "</pre>")
}
