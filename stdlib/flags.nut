local Packer = ::std.Packer, Iter = ::std.Iter;
::std.Flags <- {
    ChunkMagic = "#@"
    ChunkLen = 64000 // Anything over 65535 will break a savegame
    function pack(_flags, _key, _data) {
        local packed = Packer.pack(_data);
        if (packed.len() <= ChunkLen) {
            _flags.set(_key, packed);
        } else {
            local n = 0;
            foreach (i, chunk in Iter.chunks(ChunkLen, packed)) {
                _flags.set(_key + ":" + i, chunk);
                n++;
            }
            _flags.set(_key, ChunkMagic + n);
        }
    }
    function unpack(_flags, _key) {
        local packed = _flags.get(_key);
        if (packed == false) return null;
        if (typeof packed != "string")
            throw "Expected packed string at key " + _key + ", got " + typeof packed;

        local magic = packed.len() <= ChunkMagic.len() ? null : packed.slice(0, 2);
        if (magic == Packer.magic) {
            local data = Packer.unpack(packed);
            _flags.remove(_key);
            return data;
        } else if (magic == ChunkMagic) {
            local n = packed.slice(ChunkMagic.len()).tointeger();
            local full = "";
            for (local i = 0; i < n; i++) full += _flags.get(_key + ":" + i);
            local data = Packer.unpack(full);
            for (local i = 0; i < n; i++) _flags.remove(_key + ":" + i);
            _flags.remove(_key);
            return data;
        } else {
            throw "Packed string at key " + _key + " does not start with a magic string";
        }
    }
}
