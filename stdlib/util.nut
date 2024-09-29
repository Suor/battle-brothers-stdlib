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
    pack = Packer.pack.bindenv(Packer)
    unpack = Packer.unpack.bindenv(Packer)

    function clamp(value, min, max) {
        return value >= max ? max : value <= min ? min : value;
    }

    function isKindOf(_object, _className) {
        if (_object == null || _className == null) return false;
        if (typeof _object == "instance" && _object instanceof ::WeakTableRef) {
            if (_object.isNull()) return false;
            _object = _object.get();
        }
        return ::isKindOf(_object, _className);
    }

    function isIn(_key, _obj) {
        if (typeof _obj == "instance") {
            if (!(_obj instanceof ::WeakTableRef)) return _key in _obj;
            if (_obj.isNull()) return false;
            _obj = _obj.get();
        }
        while(_obj != null) {
            if (_key in _obj) return true;
            // If we do it in hooks, i.e. ::mods_hookExactClass() delegates might not be set yet
            _obj = "SuperName" in _obj ? _obj[_obj.SuperName] : _obj.getdelegate();
        }
        return false;
    }

    function getMember(_obj, _key) {
        // Make it strict for now: throw when unsure, might make it more permissive later
        if (typeof _obj == "instance") {
            if (_obj instanceof ::WeakTableRef) {
                if (_obj.isNull()) throw "Can't call getMember() on a null WeakTableRef";
                _obj = _obj.get();
            } else {
                throw "Can't call getMember() on a non-WeakTableRef instance";
            }
        }
        while (_obj != null) {
            if (_key in _obj) return _obj[_key];
            // If we do it in hooks, i.e. ::mods_hookExactClass() delegates might not be set yet
            _obj = "SuperName" in _obj ? _obj[_obj.SuperName] : _obj.getdelegate();
        }
        return null;
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
