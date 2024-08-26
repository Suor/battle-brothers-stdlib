// Packs arbitrary squirrel data structures to "human readable" strings and unpacks them.
// Contains only printable characters as long as passed data contains only printable strings.
// Can only pack primitive values, arrays and tables. Borks on functions, classes, instances, etc.
//
// Implements some optimizations:
//     - repeated strings won't be repeated verbatim if they close enough,
//     - TODO
local Packer;
Packer = ::std.Packer <- {
    magic = "@>" // A signature to separate our strings from random junk
    version = 2
    lchar = '!' - '0' // -16, lowest value for a "char integer"
    hchar = 'z' - '0' //  74, highest value for a "char integer"
    op = {
        "null": '~'  // Use char outside of cint range to work with vectors and structs
        "true": '+'
        "false": '-'
        cint = ','
        integer = '#' // Use negative cint so that it could not be confused with array/table len
        float = '.'
        sstring = "'"[0]
        lstring = '"'
        // TODO: op code for empty string? to not use ref for it, save 1 char.
        //       Downside is complicating vector packing code.
        array = '['
        vector = ']'  // typed array, nulls allowed
        table = '{'
        struct = '}'  // table with fixed keys and types
        ref = '<'
        alter = '|'
        // Out of cint:   {|}     unused: <space>
        // Negative cint: "#'+,-. unused: !$%&()*/
        // Positive cint  <[]     unused: _:;<=?@\^`
    }

    function pack(_data) {
        return magic + i2c(version) + _pack(_data, _cache());
    }
    function unpack(_text) {
        // Should start with magic + version
        local ml = magic.len();
        if (_text.len() < ml + 1 || _text.slice(0, ml) != magic || _text[ml] > hchar)
            throw "Broken pack string";
        local v = c2i(_text[ml]);
        if (v == 1)
            return ::std.Packer1._unpack(_stream(_text, ml + 1));
        if (v != version)
            throw "Don't know packed version " + v + ", here is " + version + ". Update stdlib?";
        return _unpack(_stream(_text, ml + 1));
    }

    function _pack(_val, _ctx) {
        local typ = type(_val);
        switch (typ) {
            case "null":
                return ops["null"];
            case "bool":
                return ops[_val.tostring()];
            case "integer":
                if (lchar <= _val && _val <= hchar) return ops.cint + i2c(_val);
            case "float":
                local s = _val.tostring();
                return ops[typ] + i2c(s.len()) + s;
            case "string":
                local ref = _ctx.ref(_val);
                if (ref != null) return ops.ref + i2c(ref);
                _ctx.add(_val);
                local n = _val.len();
                if (n <= hchar) return ops.sstring + i2c(n) + _val;
                return ops.lstring + _pack(n, _ctx) + _val;
            case "array":
                local n = _val.len();
                if (n == 0) return ops.array + i2c(0);

                // How many bytes we can save by using vector: only say op once instead of n times
                local vectorGain = n - 1;
                local vop = op["null"], vtext = "", i = 0;
                local xp, xop;
                foreach (x in _val) {
                    xp = _pack(x, _ctx);
                    xop = xp[0];
                    if (x == null) {
                        vectorGain--;
                        if (vectorGain <= 0) break;
                        vtext += xp; // Will conflict with lower if op.null is in the cint range
                    }
                    // Only do vectors with cint and refs with possible nulls for now.
                    // Reasons are - make it simple, usually not worth it for longer values.
                    else if (xop != op.cint && xop != op.ref) break;
                    else if (vop == op["null"]) vop = xop;
                    else if (xop != vop) break;

                    // Since these are cint and refs only xp = op + 1 cint char
                    vtext += xp.slice(1);
                    i++;
                }
                if (i == n) return ops.vector + vop.tochar() + _packlen(n, _ctx) + vtext;

                // We partially packed this as vector, but decided to bail out,
                // need to convert text to whatever array would look.
                // Thankfully we packed each x but last to exactly 1 char.
                local text = "";
                foreach (c in vtext) {
                    text += c == op["null"] ? ops["null"] : vop.tochar() + c.tochar();
                }
                // NOTE: it's important that we don't pack x again, because doing so to a string
                //       can make it a ref to itself. Same for collections containing strings.
                text += xp; i++;

                // Pack the rest in array way
                for (; i < n; i++) text += _pack(_val[i], _ctx);
                return ops.array + _packlen(n, _ctx) + text;
            case "table":
                local n = _val.len();
                local text = ops.table + _packlen(n, _ctx);
                foreach (k, v in _val) text += _pack(k, _ctx) + _pack(v, _ctx);
                return text;
            default:
                throw "Don't know how to pack " + typ;
        }
    }

    function _unpack(_in, _code = null) {
        local code = _code || _in.char();
        switch (code) {
            case op["null"]:
                return null;
            case op["true"]:
                return true;
            case op["false"]:
                return false;
            case op.cint:
                return c2i(_in.char());
            case op.integer:
            case op.float:
                local n = c2i(_in.char());
                return code == op.integer ? _in.read(n).tointeger() : _in.read(n).tofloat();
            case op.sstring:
            case op.lstring:
                local n = code == op.sstring ? c2i(_in.char()) : _unpack(_in);
                local str = _in.read(n);
                _in.cache.add(str);
                return str;
            case op.array:
                local n = _unpacklen(_in);
                local arr = array(n);
                for (local i = 0; i < n; i++) arr[i] = _unpack(_in);
                return arr;
            case op.vector:
                local vop = _in.char();
                local n = _unpacklen(_in);
                local arr = array(n);
                for (local i = 0; i < n; i++) {
                    local c = _in.char();
                    arr[i] = c == op["null"] ? null : (_in.back(), _unpack(_in, vop));
                }
                return arr;
            case op.table:
                local n = _unpacklen(_in);
                local t = {};
                for (local i = 0; i < n; i++) t[_unpack(_in)] <- _unpack(_in);
                return t;
            case op.ref:
                return _in.cache.get(c2i(_in.char()));
            default:
                throw format("Unknown op code '%s' (%i)", code.tochar(), code);
        }
    }

    function _packlen(n, _ctx) {
        return n <= hchar ? i2c(n) : _pack(n, _ctx)
    }
    function _unpacklen(_in) {
        local c = _in.char();
        return '0' <= c && c <= hchar ? c2i(c) : _unpack(_in, c);
    }

    function _stream(_text, _pos = 0) {
        local tlen = _text.len();
        return {
            cache = _cache()
            function char() {
                if (_pos >= tlen) throw "Unexpected end of packed string";
                local char = _text[_pos];
                _pos++;
                return char;
            }
            function back() {
                _pos--;
            }
            function read(n) {
                if (_pos + n > tlen) throw "Unexpected end of packed string";
                local buffer = _text.slice(_pos, _pos + n);
                _pos += n;
                return buffer;
            }
        }
    }
    function _cache() {
        local N = 64, pos = -1, full = false;
        local values = array(N), val2idx = {};
        return {
            function add(_val) {
                if (_val in val2idx) return;

                pos++;
                if (pos >= N) {pos = 0; full = true;}

                if (full) delete val2idx[values[pos]];
                values[pos] = _val;
                val2idx[_val] <- pos;
            }
            function ref(_val) {
                if (!(_val in val2idx)) return null;

                local idx = val2idx[_val];
                return pos >= idx ? pos - idx : N + pos - idx;
            }
            function get(_idx) {
                return values[(N + pos - _idx) % N];
            }
        }
    }

    function i2c(_i) {
        if (_i < lchar || _i > hchar) throw "Can't fit " + _i + " into char";
        return ('0' + _i).tochar();
    }
    function c2i(_c) {
        return _c - '0';
    }
}

// Keep it for backward compatibilty, do not mix with the newest version for simplicity and speed.
::std.Packer1 <- {
    version = 1
    lchar = '!' - '0' // -16, lowest value for a "char integer"
    hchar = 'z' - '0' //  74, highest value for a "char integer"
    op = {
        "null": '_'
        "true": '+'
        "false": '-'
        cint = ','
        integer = ';'
        float = '.'
        sstring = "'"[0]
        lstring = '"'
        array = '['
        table = '{'
        ref = '<'
        // unused special chars: `~!@#$%^&*()=}:>?]|\/
    }

    function _pack(_val, _ctx) {
        local typ = type(_val);
        switch (typ) {
            case "null":
                return ops["null"];
            case "bool":
                return ops[_val.tostring()];
            case "integer":
                if (lchar <= _val && _val <= hchar) return ops.cint + i2c(_val);
            case "float":
                local s = _val.tostring();
                return ops[typ] + i2c(s.len()) + s;
            case "string":
                local ref = _ctx.ref(_val);
                if (ref != null) return ops.ref + i2c(ref);
                _ctx.add(_val);
                local n = _val.len();
                if (n <= hchar) return ops.sstring + i2c(n) + _val;
                return ops.lstring + _pack(n, _ctx) + _val;
            case "array":
                local n = _val.len();
                // local text = ops.array + (n <= hchar ? i2c(n) : _pack(n, _ctx));
                local text = ops.array + _pack(n, _ctx);
                foreach (x in _val) text += _pack(x, _ctx);
                return text;
            case "table":
                local n = _val.len();
                local text = ops.table + _pack(n, _ctx);
                foreach (k, v in _val) text += _pack(k, _ctx) + _pack(v, _ctx);
                return text;
            default:
                throw "Don't know how to pack " + typ;
        }
    }

    function _unpack(_in) {
        local code = _in.char();
        switch (code) {
            case op["null"]:
                return null;
            case op["true"]:
                return true;
            case op["false"]:
                return false;
            case op.cint:
                return c2i(_in.char());
            case op.integer:
            case op.float:
                local n = c2i(_in.char());
                return code == op.integer ? _in.read(n).tointeger() : _in.read(n).tofloat();
            case op.sstring:
            case op.lstring:
                local n = code == op.sstring ? c2i(_in.char()) : _unpack(_in);
                local str = _in.read(n);
                _in.cache.add(str);
                return str;
            case op.array:
                local n = _unpack(_in);
                local arr = array(n);
                for (local i = 0; i < n; i++) arr[i] = _unpack(_in);
                return arr;
            case op.table:
                local n = _unpack(_in);
                local t = {};
                for (local i = 0; i < n; i++) t[_unpack(_in)] <- _unpack(_in);
                return t;
            case op.ref:
                return _in.cache.get(c2i(_in.char()));
            default:
                throw format("Unknown op code '%s' (%i)", code.tochar(), code);
        }
    }
}.setdelegate(Packer);

Packer.ops <- {};
foreach (k, v in Packer.op) Packer.ops[k] <- v.tochar();

::std.Packer1.ops <- {};
foreach (k, v in ::std.Packer1.op) ::std.Packer1.ops[k] <- v.tochar();
