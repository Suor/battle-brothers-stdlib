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

local EMPTY = {}, Debug;
Debug = ::std.Debug <- {
    // TODO: re filter?
    DEFAULTS = {
        level = "info"  // "warning", "error"
        html = true     // escape html tags and wrap in <pre>
        prefix = ""
        trace = false   // add "filename:lineno in func()"
        width = 100     // max line width in chars
        depth = 3       // max depth to show
        funcs = "count" // how functions should be shown: "count" | "full" | false
        filter = null   // only show keys containing this string
        repr = false    // concise reprs for actor, skill, tile
    }

    function log(_name, ...) {
        if (vargv.len() == 0) return _out(_name, EMPTY, DEFAULTS);
        _out(_name, vargv[0], _interpret(vargv.slice(1)));
    }
    function logRepr(_name, _data, ...) {
        _out(_name, _data, Util.extend(_interpret(vargv), {repr = true}));
    }
    function trace(_name, ...) {
        if (vargv.len() == 0) return _out(_name, EMPTY, _interpret([{trace = true}]));
        _out(_name, vargv[0], Util.extend(_interpret(vargv.slice(1)), {trace = true}));
    }

    // Pretty print a data structure
    function pp(data, ...) {
        return _pp(data, _interpret(vargv));
    }
    function repr(data, ...) {
        return _pp(data, Util.extend(_interpret(vargv), {repr = true}));
    }

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

    function _pp(data, _opts = {}, _level = 0, _prepend = "") {
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
                if (_opts.filter && _opts.filter(k, v)) {
                    vpp = _pp(v, Util.merge(_opts, {filter = null}), _level + 1, k + " = ")
                } else {
                    vpp = _pp(v, _opts, _level + 1, k + " = ");
                }
                if (_opts.filter && isEmpty(v, vpp) && !_opts.filter(k, v)) {
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
                local vpp = _pp(v, _opts, _level + 1);
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

    function _interpret(_optValues) {
        local opts = {};
        foreach (val in _optValues) {
            if (typeof val == "integer") opts.depth <- val;
            if (typeof val == "string") opts.filter <- val;
            if (typeof val == "table") Util.extend(opts, val);
        }
        if ("filter" in opts && typeof opts.filter == "string") {
            local substr = opts.filter;
            opts.filter = @(k, v) (k + "").find(substr) != null;
        }
        return opts.setdelegate(DEFAULTS);
    }

    function _out(_name, _data, _opts) {
        local s, trace = "";
        // if (_opts != DEFAULTS) _opts = Util.merge(DEFAULTS, _opts);

        if (_opts.trace) {
            local si = ::getstackinfos(3);
            trace = format("%s:%i in %s(): ", si.src, si.line, si.func == "unknown" ? "" : si.func);
        }

        if (_data == EMPTY) {
            local val = _opts.prefix + trace + _name;
            s = _opts.html ? Str.escapeHTML(val) : val;
        } else {
            local val = _pp(_data, _opts, 0, trace + (_name != EMPTY ? _name + " = " : ""));
            s = _opts.html ? "<pre>" + Str.escapeHTML(val) + "</pre>": val;
        }

        // Need to do this way in case somebody patches one of these
        local printers = {info = ::logInfo, warn = ::logWarning, warning = ::logWarning,
                          error = ::logError};
        printers[_opts.level](s);
    }

    // Create a new Debug with changed default options:
    //     local Debug = ::std.Debug.with({prefix: "my-module: ", width: 120});
    //     Debug.log("enemy", enemy);
    function with(_opts) {
        return Util.merge(this, {DEFAULTS = Util.merge(DEFAULTS, _opts)})
    }

    enabled = true
    function noop() {
        return {
            enabled = false
            DEFAULTS = DEFAULTS
            function pp(_data, _opts = {}, _level = 0, _prepend = "") {}
            function log(_name, ...) {}
            function logRepr(_name, _data, ...) {}
            function trace(_name, ...) {}
            function with(_opts) {return this}
            function noop() {return this}
        }
    }
}
// ::std.Debug = Debug.noop()

::std.debug <- function (_data, ...) {
    if (typeof _data == "string") Debug._out(_data, EMPTY, Debug._interpret(vargv));
    else Debug._out(EMPTY, _data, Debug._interpret(vargv));
}
// TODO: ::std.trace() ?
// TODO: rename Debug -> Log, .log -> .show, .logRepr -> .repr, .repr -> ???
//       or just .logRepr -> .repr, .repr -> ppRepr?
//       or .log -> .pp (and accept data struct as first arg too)
//          .logRepr -> .repr
