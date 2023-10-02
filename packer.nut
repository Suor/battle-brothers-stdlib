// Packs arbitrary squirrel data structures to "human readable" strings and unpacks them.
// Contains only printable characters as long as passed data contains only printable strings.
// Can only pack primitive values, arrays and tables. Borks on functions, classes, instances, etc.
local _pack, _unpack, i2c, c2i, op, ops;
local Packer;
Packer = ::Packer <- {
    magic = "@>" // A signature to separate our strings from random junk
    version = 1
    short = 'z' - '0' // 74, max value for a "short integer"
    op = {
        "null": '_'
        "true": '+'
        "false": '-'
        integer = ','
        float = '.'
        sstring = "'"[0]
        lstring = '"'
        array = '['
        table = '{'
        ref = '<'
        // unused special chars: `~!@#$%^&*()=};:">?]|\/
    }

    function pack(_data) {
        return Packer.magic + i2c(Packer.version) + _pack(_data, Packer._cache());
    }
    function unpack(_text) {
        // Should start with magic + version
        local ml = Packer.magic.len();
        if (_text.len() < ml + 1 || _text.slice(0, ml) != Packer.magic)
            throw "Broken pack string";
        local v = c2i(_text[ml]);
        if (v != Packer.version)
            throw "Don't know packed version " + v + ", here is " + Packer.version;
        return _unpack(Packer._stream(_text, ml + 1));
    }

    function _pack(_val, _ctx) {
        local typ = type(_val);
        switch (typ) {
            case "null":
                return ops["null"];
            case "bool":
                return ops[_val.tostring()];
            case "integer":
            case "float":
                local s = _val.tostring();
                return ops[typ] + i2c(s.len()) + s;
            case "string":
                local ref = _ctx.ref(_val);
                if (ref != null) return ops.ref + i2c(ref);
                _ctx.add(_val);
                local n = _val.len();
                if (n <= Packer.short) return ops.sstring + i2c(n) + _val;
                return ops.lstring + _pack(n, _ctx) + _val;
            case "array":
                local n = _val.len();
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
            case op.integer:
                local n = c2i(_in.char());
                return _in.read(n).tointeger();
            case op.float:
                local n = c2i(_in.char());
                return _in.read(n).tofloat();
            case op.sstring:
                local n = c2i(_in.char());
                local str = _in.read(n);
                _in.cache.add(str);
                return str;
            case op.lstring:
                local n = _unpack(_in);
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
                throw format("Unexpected op code '%s' (%i)", code.tochar(), code);
        }
    }

    function _stream(_text, _pos = 0) {
        local tlen = _text.len();
        return {
            cache = Packer._cache()
            function char() {
                if (_pos >= tlen) throw "Unexpected end of packed string";
                local char = _text[_pos];
                _pos++;
                return char;
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

    function _i2c(_i) {
        assert(_i <= Packer.short, "Integer too big for char");
        return ('0' + _i).tochar();
    }
    function _c2i(_c) {
        return _c - '0';
    }
}
op = Packer.op;
ops = Packer.ops <- {};
foreach (k, v in op) ops[k] <- v.tochar();

_pack = ::Packer._pack;
_unpack = ::Packer._unpack;
i2c = ::Packer._i2c;
c2i = ::Packer._c2i;
