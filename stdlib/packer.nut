// Packs arbitrary squirrel data structures to "human readable" strings and unpacks them.
// Contains only printable characters as long as passed data contains only printable strings.
// Can only pack primitive values, arrays and tables. Borks on functions, classes, instances, etc.
//
// Implements some optimizations:
//     - a compact form for small and medium integers
//     - repeated strings won't be repeated verbatim if they close enough,
//     - tables with same set of fields will be encoded to not repeat keys and value types,
//     - arrays with small integers or refs won't repeat type op code.
::std.Packer <- {
    magic = "@>" // A signature to separate our strings from random junk
    version = 3
    lchar = '$'
    hchar = 'z'
    lcint = '$' - '0' // -12, lowest value for a "char integer"
    hcint = 'z' - '0' //  74, highest value for a "char integer"
    mintB = 'z' - '$' + 1 // "medium integer" base
    lmint = -1227  // lowest value for "medium integer", same rate of neg to pos as cint
    hmint = ('z' - '$' + 1) * ('z' - '$' + 1) - 1 - 1227 // 6341, highest value for "medium integer"
    maxStructLen = 32
    op = {
        "null": '~'  // Use char outside of cint range to work with vectors and structs
        "true": '+'
        "false": '-'
        cint = '!'
        mint = '#'
        integer = '"'
        float = '.'
        string = "'"[0]
        array = '['
        vector = ']'  // running opcode array
        table = '{'
        struct = '}'  // running opcode table with known keys
        ref = '*'  // Use negative cint to be implicitly compatible with string
        alter = '|'
        // Out of cint:   !~"#{|} unused: <space>
        // Negative cint: +-,.'*  unused: $%&()/
        // Positive cint  []      unused: _:;<=?@\^`
        //
        // In v1 opcodes only shared space with other opcodes, so they just needed to be unique,
        // I chose all of them to be special chars for easier "human parsing" of packed strings.
        // Here opcodes sometimes share position with a first byte of enconding of some data type,
        // this enforces certain limitation on which symbols can be used as opcodes.
        //
        // Case 1: array and table lens.
        // These are packed as this in v2+:
        //     len <= 74 (hcint): op.array + cint (len) + data
        //         longer arrays: op.array + op.integer + cint (len of len) len.tostring() + data
        // This demands op.integer to be either out of cint or in negative cint space, to be not
        // confused with cint len, which may go from '0' to 'z' (hchar). So I moved op.integer to #
        //
        // Case 2: running opcode in vectors and structs.
        // This optimises for opcode repetition, so best case scenario same opcode over array or
        // repeating tables. However, we want to allow some type intermixture especially:
        //     - null with everything
        //     - cint, mint, integer, float
        //     - sstring, lstring, ref
        //     - table, struct and array, vector
        // This leads to several requirements:
        //     - null opcode needs to be out of cint, because cints often go right after an opcode.
        //       This is why I changed null to ~.
        //     - alter opcode needs to be out of cint for same reason
        //     - integer opcode being out of cint to save on alter op code when mixing these two.
        //       I moved it to negative cint before, now I moved lchar from ! to $. This shortened
        //       negative cint range but alowed this optimization.
        //     - since sstring, lstring and ref put positive cint after opcode their opcodes should
        //       be at least negative cint. So i moved ref opcode to *. Strictly speaking lstring
        //       may also have integer opcode after its own not positive cint, this is fine too.
        // Should note that not having really fixed types for struct keys allows us to reuse the
        // same struct record in cache, making it more efficient.
        //
        // This makes ascii printable chars in negative cint and especially outisde cint a scarce
        // resource :) Some things might be moved, i.e. table and struct opcodes may go to negative
        // cint at all, same for lstring. However, these have a nice ideomatic correspondense,
        // which I don't want to break.
    }
    function _init() {
        _initOps();

        singletons <- cset(op["null"], op["true"], op["false"]);

        // B in implicit[A] means B opcode cannot be confused with the first byte after A opcode.
        //
        // These sets could be widened to have less alter ops, but it will be possible to add this
        // later in a backward compatible manner - extra | doesn't stop unpacking. We, however, only
        // add things we think common enough to care about:
        //     - nulls should be mixable everywhere
        //     - cint, integer, float may go together (still need alter to float from cint)
        //     - various strings, including refs should also play nice together
        //     - table with struct, because one turn into other
        implicit <- {};
        _fillImplicit();
        foreach (_, c in op) {
            if (!(c in implicit)) implicit[c] <- {};
            implicit[c][op["null"]] <- true;
        }
    }
    function _initOps() {
        ops <- {};
        foreach (k, v in op) ops[k] <- v.tochar();
    }
    function _fillImplicit() {
        implicit[op.cint] <- cset(op.mint op.integer); // Can't add float because '.' is in cint
        implicit[op.mint] <- cset(op.cint op.integer); // Same
        implicit[op.integer] <- cset(op.cint op.mint op.float);
        implicit[op.float] <- cset(op.cint op.mint op.integer); // It works the other way around
        implicit[op.string] <- cset(op.ref);
        implicit[op.ref] <- cset(op.string);
        implicit[op.table] <- cset(op.struct);
        implicit[op.struct] <- cset(op.table);
    }
    function cset(...) {
        local s = {};
        foreach (c in vargv) s[c] <- true;
        return s;
    }

    function pack(_data) {
        return magic + i2c(version) + _pack(_data, {strings = _cache(), structs = _cache(true)});
    }
    function unpack(_text) {
        // Should start with magic + version
        local ml = magic.len();
        if (_text.len() < ml + 1 || _text.slice(0, ml) != magic
                || _text[ml] < '0' || _text[ml] > hchar)
            throw "Broken pack string: magic and version expected";

        local v = c2i(_text[ml]);
        if (!(v in ::std.Packers))
            throw "Don't know packed version " + v + ", here is " + version + ". Update stdlib?";

        local stream = _stream(_text, ml + 1);
        local data = ::std.Packers[v]._unpack(stream);
        if (!stream.eos()) throw "Found some junk in the end of packed string: " + stream.tail(32);
        return data;
    }

    function _pack(_val, _ctx) {
        local typ = type(_val);
        switch (typ) {
            case "null":
                return ops["null"];
            case "bool":
                return ops[_val.tostring()];
            case "integer":
                if (lcint <= _val && _val <= hcint) return ops.cint + i2c(_val);
                if (lmint <= _val && _val <= hmint) {
                    local u = _val - lmint;
                    return ops.mint + (u % mintB + lchar).tochar() + (u / mintB + lchar).tochar();
                }
            case "float":
                local s = _val.tostring();
                return ops[typ] + i2c(s.len()) + s;
            case "string":
                local ref = _ctx.strings.ref(_val);
                if (ref != null) return ops.ref + i2c(ref);
                _ctx.strings.add(_val);
                local n = _val.len();
                return ops.string + _packlen(n, _ctx) + _val;
            case "array":
                local n = _val.len();
                // use vector since they are more common, and so can save opcode in other vectors
                if (n == 0) return ops.vector + i2c(0);

                local itemsp = array(n);
                foreach (i, x in _val) itemsp[i] = _pack(x, _ctx);
                return _packVector(itemsp, _ctx) || _packArray(itemsp, _ctx);
            case "table":
                local n = _val.len();
                // Tables too big and the ones with non-string keys are unlikely to repeat, skip
                if (n == 0 || n > maxStructLen) return _packTable(_val, _ctx);

                // Try struct
                local cacheKey = Struct.keyFor(_val);
                if (cacheKey == null) return _packTable(_val, _ctx);

                local ref = _ctx.structs.ref(cacheKey);
                if (ref != null) {
                    local struct = _ctx.structs.get(ref);
                    local text = ops.struct + i2c(ref);
                    // NOTE: it seems like we apply changes to the struct after we use it, however,
                    //       same structs might be nested into this one, so _pack() call in there
                    //       might change types as we go here.
                    // This sounds really crazy but things appear to work since things happen in
                    // the same order here and in unpack.
                    foreach (i, k in struct.keys) {
                        local prevop = struct.ops[i], v = _val[k];
                        local vp = _pack(v, _ctx); // struct.ops[i] might change inside, so we save

                        text += _packRunning(prevop, vp);
                        if (v != null) struct.ops[i] = vp[0];
                    }
                    return text;
                }

                // Pack a table, record a new struct
                local text = ops.table + _packlen(n, _ctx);
                local struct = Struct.new();
                foreach (k, v in _val) {
                    local kp = _pack(k, _ctx), vp = _pack(v, _ctx);
                    text += kp + vp;
                    struct.add(k, vp[0])
                }
                _ctx.structs.add(cacheKey, struct);
                return text;
            default:
                throw "Don't know how to pack " + typ;
        }
    }

    function _packArray(_itemsp, _ctx) {
        local n = _itemsp.len();
        local text = ops.array + _packlen(n, _ctx);
        foreach (xp in _itemsp) text += xp;
        return text;
    }
    function _packTable(_val, _ctx) {
        local text = ops.table + _packlen(_val.len(), _ctx);
        foreach (k, v in _val) text += _pack(k, _ctx) + _pack(v, _ctx);
        return text;
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
            case op.mint:
                return (_in.char() - lchar) + (_in.char() - lchar) * mintB + lmint;
            case op.integer:
            case op.float:
                local n = c2i(_in.char());
                return code == op.integer ? _in.read(n).tointeger() : _in.read(n).tofloat();
            case op.string:
                local n = _unpacklen(_in);
                local str = _in.read(n);
                _in.cache.add(str);
                return str;
            case op.array:
                local n = _unpacklen(_in);
                local arr = array(n);
                for (local i = 0; i < n; i++) arr[i] = _unpack(_in);
                return arr;
            case op.vector:
                return _unpackVector(_in);
            case op.table:
                local n = _unpacklen(_in);
                local struct = n > 0 && n <= maxStructLen ? Struct.new() : null;
                local t = {};
                for (local i = 0; i < n; i++) {
                    local key = _unpack(_in), vop = _in.char();
                    if (struct && type(key) == "string") struct.add(key, vop); else struct = null;
                    t[key] <- _unpack(_in, vop);
                }
                // A table might be referenced as a struct later, record it if it fits the criteria
                if (struct) _in.structs.add(Struct.keyFor(t), struct);
                return t;
            case op.struct:
                local struct = _in.structs.get(c2i(_in.char()));
                local t = {};
                foreach (i, k in struct.keys) {
                    local unpacked = _unpackRunning(struct.ops[i], _in);
                    t[k] <- unpacked.v;
                    if (unpacked.v != null) struct.ops[i] = unpacked.vop;
                }
                return t;
            case op.ref:
                return _in.cache.get(c2i(_in.char()));
            default:
                throw format("Unknown op code '%s' (%i) at offset %i, tail: %s",
                             code.tochar(), code, _in.pos(), _in.tail(32));
        }
    }

    // Vector = array with "running opcode" like structs
    function _packVector(_itemsp, _ctx) {
        local n = _itemsp.len();
        // How many bytes we can save by using vector, will decrement this on adding each opcode
        local gain = n;
        local prevop = op["null"], text = "";
        foreach (vp in _itemsp) {
            local packed = _packRunning(prevop, vp);
            gain -= packed.len() - vp.len() + 1;
            if (gain < 0) return; // Bail out and pack as array no flashy

            text += packed;
            if (vp != ops["null"]) prevop = vp[0];
        }
        return ops.vector + _packlen(n, _ctx) + text;
    }
    function _unpackVector(_in) {
        local n = _unpacklen(_in);
        local arr = array(n);
        local prevop = op["null"]
        for (local i = 0; i < n; i++) {
            local unpacked = _unpackRunning(prevop, _in);
            arr[i] = unpacked.v;
            if (unpacked.v != null) prevop = unpacked.vop;
        }
        return arr;
    }

    function _packRunning(_prevop, _vp) {
        local vop = _vp[0];
        return _prevop in singletons    ? _vp :
               _prevop == vop           ? _vp.slice(1) : // Here we save our byte
               vop in implicit[_prevop] ? _vp : ops.alter + _vp;
    }
    function _unpackRunning(_prevop, _in) {
        local vop = _in.char();
        if (vop == op.alter) vop = _in.char();
        else if (!(_prevop in singletons) && !(vop in implicit[_prevop])) {
            // op didn't change, so prevop is our opcode, and vop was read from data
            vop = _prevop;
            _in.back();
        }
        return {vop = vop, v = _unpack(_in, vop)}
    }

    function _packlen(n, _ctx) {
        return n <= hcint ? i2c(n) : _pack(n, _ctx)
    }
    function _unpacklen(_in) {
        local c = _in.char();
        local n = '0' <= c && c <= hchar ? c2i(c) : _unpack(_in, c);
        if (type(n) != "integer" || n < 0) throw "Expected len, got " + n;
        return n;
    }

    Struct = {
        function keyFor(_table) {
            local cacheKey = "", keys = [];
            foreach (k, _ in _table) {
                if (type(k) != "string") return null; // Only allow string keys
                keys.push(k);
            }
            keys.sort()
            foreach (k in keys) cacheKey += k.len() + ":" + k;
            return cacheKey
        }
        function new() {
            return {
                keys = []
                ops = []
                function add(_key, _op) {keys.push(_key); ops.push(_op)}
            }
        }
    }

    function _stream(_text, _pos = 0) {
        local tlen = _text.len();
        return {
            cache = _cache()
            structs = _cache(true)
            function char() {
                if (_pos >= tlen) throw "Unexpected end of packed string";
                local char = _text[_pos];
                _pos++;
                return char;
            }
            function back() {_pos--}
            function read(n) {
                if (_pos + n > tlen) throw "Unexpected end of packed string";
                local buffer = _text.slice(_pos, _pos + n);
                _pos += n;
                return buffer;
            }
            function pos() {return _pos}
            function eos() {return _pos == tlen}
            function tail(_len = null) {
                return _len && tlen - _pos > _len ? _text.slice(_pos, _pos + _len - 3) + "..."
                                                  : _text.slice(_pos);
            }
        }
    }
    function _cache(_values = false) {
        local N = 64, pos = -1, full = false;
        local keys = array(N), values = _values ? array(N) : null, key2idx = {};
        return {
            function add(_key, _val = null) {
                if (_key in key2idx) return;

                pos++;
                if (pos >= N) {pos = 0; full = true;}

                if (full) delete key2idx[keys[pos]];
                keys[pos] = _key;
                if (_values) values[pos] = _val;
                key2idx[_key] <- pos;
            }
            function ref(_key) {
                if (!(_key in key2idx)) return null;

                local idx = key2idx[_key];
                return pos >= idx ? pos - idx : N + pos - idx;
            }
            function get(_ref) {
                local idx = (N + pos - _ref) % N;
                return _values ? values[idx] : keys[idx];
            }
        }
    }

    function i2c(_i) {
        if (_i < lcint || _i > hcint) throw "Can't fit " + _i + " into char";
        return ('0' + _i).tochar();
    }
    function c2i(_c) {
        return _c - '0';
    }
}

// Keep it for backward compatibilty, esp. testing it
::std.Packer2 <- {
    version = 2
    op = {
        "null": '~'
        "true": '+'
        "false": '-'
        cint = ','
        integer = '#'
        float = '.'
        sstring = "'"[0]
        lstring = '"'
        array = '['
        vector = ']'
        table = '{'
        struct = '}'
        ref = '*'
        alter = '|'
        // needed to call new _unpack
        mint = '!'
        string = "'"[0]
    }
    function _fillImplicit() {
        implicit[op.cint] <- cset(op.integer); // Can't add float because '.' is in cint
        implicit[op.integer] <- cset(op.cint op.float);
        implicit[op.float] <- cset(op.cint op.integer); // It works the other way around
        implicit[op.sstring] <- cset(op.lstring op.ref);
        implicit[op.lstring] <- cset(op.sstring op.ref);
        implicit[op.ref] <- cset(op.sstring op.lstring);
    }

    function _pack(_val, _ctx) {
        local typ = type(_val);
        switch (typ) {
            case "integer": // No mint here
                if (lcint <= _val && _val <= hcint) return ops.cint + i2c(_val);
                local s = _val.tostring();
                return ops[typ] + i2c(s.len()) + s;
            case "string":
                local ref = _ctx.strings.ref(_val);
                if (ref != null) return ops.ref + i2c(ref);
                _ctx.strings.add(_val);
                local n = _val.len();
                if (n <= hcint) return ops.sstring + i2c(n) + _val;
                return ops.lstring + _pack(n, _ctx) + _val;
            case "array":
                local n = _val.len();
                if (n == 0) return ops.array + i2c(0); // use vector op in v3
            default:
                return getdelegate()._pack.call(this, _val, _ctx);
        }
    }
    function _unpack(_in, _code = null) {
        local code = _code || _in.char();
        switch (code) {
            case op.mint:
                throw format("Unknown op code '%s' (%i)", code.tochar(), code);
            case op.sstring:
            case op.lstring:
                local n = code == op.sstring ? c2i(_in.char()) : _unpack(_in);
                local str = _in.read(n);
                _in.cache.add(str);
                return str;
        }
        return getdelegate()._unpack.call(this, _in, code);
    }

    // Vector (in v2) = array with same opcode with possible nulls mixed in.
    function _packVector(_itemsp, _ctx) {
        local n = _itemsp.len();
        // How many bytes we can save by using vector: only say op once instead of n times
        local gain = n - 1;
        local vop = op["null"], vtext = "", i = 0;
        local xp, xop;
        foreach (xp in _itemsp) {
            xop = xp[0];
            if (xop == op["null"]) {
                gain--; // null is one byte both in array and vector, so no 1 byte save here
                if (gain <= 0) return;
                vtext += xp;
            }
            // Only do vectors with cint and refs with possible nulls for now.
            // Reasons are - make it simple, usually not worth it for longer values.
            else if (xop != op.cint && xop != op.ref) return;
            else if (vop == op["null"]) vop = xop;
            else if (xop != vop) return;

            // Since these are cint and refs only xp = op + 1 cint char
            vtext += xp.slice(1);
        }
        // NOTE: putting n before vop makes vector interoperable in structs with many things
        return ops.vector + _packlen(n, _ctx) + vop.tochar() + vtext;
    }
    function _unpackVector(_in) {
        local n = _unpacklen(_in);
        local vop = _in.char();
        local arr = array(n);
        for (local i = 0; i < n; i++) {
            local c = _in.char();
            arr[i] = c == op["null"] ? null : (_in.back(), _unpack(_in, vop));
        }
        return arr;
    }
}.setdelegate(::std.Packer);

// Keep it for backward compatibilty, do not mix with the newest version for simplicity and speed.
::std.Packer1 <- {
    version = 1
    lcint = '!' - '0' // -15, lowest value for a "char integer"
    hcint = 'z' - '0' //  74, highest value for a "char integer"
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

    function pack(_data) {
        return magic + i2c(version) + _pack(_data, _cache());
    }

    function _pack(_val, _ctx) {
        local typ = type(_val);
        switch (typ) {
            case "null":
                return ops["null"];
            case "bool":
                return ops[_val.tostring()];
            case "integer":
                if (lcint <= _val && _val <= hcint) return ops.cint + i2c(_val);
            case "float":
                local s = _val.tostring();
                return ops[typ] + i2c(s.len()) + s;
            case "string":
                local ref = _ctx.ref(_val);
                if (ref != null) return ops.ref + i2c(ref);
                _ctx.add(_val);
                local n = _val.len();
                if (n <= hcint) return ops.sstring + i2c(n) + _val;
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
}.setdelegate(::std.Packer);

::std.Packer._init();
::std.Packer2._init();
::std.Packer1._initOps();

::std.Packers <- {[1] = ::std.Packer1, [2] = ::std.Packer2, [3] = ::std.Packer}
