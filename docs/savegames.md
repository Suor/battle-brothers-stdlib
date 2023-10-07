# Serialization for Humans

Battle Brothers serialization have a notorious history of both breaking savegames and confusing modders. This is, however, doesn't need to be that hard, which I will show in this complete zero to hero serialization guide.

For a full story just continue reading, for TLDR jump [here](#tldr).

<!-- MarkdownTOC autolink="true" levels="2,3" autoanchor="false" start="top" -->

- [Battle Brothers and Savegames](#battle-brothers-and-savegames)
- [Flags](#flags)
- [Complex Structures](#complex-structures)
- [Migrations](#migrations)

<!-- /MarkdownTOC -->

## Battle Brothers and Savegames

Traditionally each Battle Brothers object is taught to write and read itself to and from a stream. In a simplified form this looks like:

```squirrel
this.player <- this.inherit("scripts/entity/tactical/human", {
    function onSerialize(_out) {
        _out.writeString(this.m.Name);
        _out.writeU8(this.m.Level);
        _out.writeF32(this.m.Mood);
        ...
    }

    function onDeserialize(_in) {
        this.m.Name = _in.readString();
        this.m.Level = _in.readU8();
        this.m.Mood = _in.readF32();
        ...
    }
}
```

This works, is efficient, but has a couple of downsides. The first one it's manual and requires writing repetitive code, which could get somewhat complicated if one needs to save nested arrays and/or tables. E.g. here is a section saving mood changes:

```squirrel
_out.writeU8(this.m.MoodChanges.len());
for (local i = 0; i != this.m.MoodChanges.len(); i = ++i) {
    _out.writeBool(this.m.MoodChanges[i].Positive);
    _out.writeString(this.m.MoodChanges[i].Text);
    _out.writeF32(this.m.MoodChanges[i].Time);
}
```

Plus similarly looking section to load it in `onDeserialize`. The second issue is adding stuff, i.e. say we just added drinking to the game, now we need to track last drink time for each bro, so we add:

```squirrel
function onSerialize(_out) {
    ...
    _out.writeF32(this.m.LastDrinkTime);
}

function onDeserialize(_in) {
    ...
    this.m.LastDrinkTime = _out.readF32();
}
```

This will change the savegame format though. If we now try to load an old savegame we will read float from where it was not written, we will probably read a start of serialization of the next object and get a random junk and also advance a position in the stream so that next object will bork when it tries to read itself. So old savegames won't be readable by a new version of the game and vice versa.

There is a partial solution: add a savegame version somewhere at the start of the file and mind it when loading a savegame. The devs did exactly that:

```squirrel
function onDeserialize(_in) {
    ...
    if (_in.getMetaData().getVersion() >= 37) {
        this.m.LastDrinkTime = _out.readF32();
    }
}
```

This will still mean that newer savegames cannot be loaded with an old version of the game. But at least upgrading the game won't break your campaign. Also older version of the game can see if version in a file is bigger than anything it knows about and disable loading that, this is grey savegames you see sometimes.

The third issue with this approach shows up when game development becomes non-linear, i.e. stops going from an older version to a newer one, but contains DLCs or mods that might advance things in different directions and might be both added and removed. In this case if two mods add something to savegame format and both advance the version it will obviously won't work.


## Flags

I guess the developers of the game ran into these issues themselves and eventually developed a subsystem to substep them. The solution was to add a key value "tag collection" both globally and to each object that requires such extensibility.

Let's say we are developing a mod called "mod_hunter", which will track the number of wolves killed, then we may just use something like:

```squirrel
::World.Flags.set("mod_hunter.wolvesKilled", 42);
::World.Flags.increment("mod_hunter.wolvesKilled");

local wolvesKilled = ::World.Flags.get("mod_hunter.wolvesKilled") || 0;
```

That works, does not require to mess with `onSerialize/onDeserialize`, does not break the savegame format, i.e. our mod will be safe to add or remove at any point and will be compatible with any other mods. For the latter we need to not clash the keys we are using, which is why I prepended the key above with our mod name.

So what about tracking number of killed wolves for each bro personally? It's easy - we might save them to particular player flags:

```squirrel
bro.m.Flags.set("mod_hunter.wolvesKilled", 17);
...
local wolvesKilled = bro.m.Flags.get("mod_hunter.wolvesKilled") || 0;
```

Or to put it together with [modhooks][]:

```squirrel
// Increment it upon each kill
::mods_hookExactClass("entity/tactical/actor", function (cls) {
    local onDeath = cls.onDeath;
    cls.onDeath = function (_killer, _skill, _tile, _fatalityType) {
        if (::isKindOf(this, "wolf") && ::isKindOf(_killer, "player")) {
            _killer.m.Flags.increment("mod_hunter.wolvesKilled");
        }
        return onDeath(_killer, _skill, _tile, _fatalityType)
    }
})

// Use it to show in a roster tooltip
::mods_hookExactClass("entity/tactical/player", function (cls) {
    local getRosterTooltip = cls.getRosterTooltip;
    cls.getRosterTooltip = function () {
        local tooltip = getRosterTooltip();
        local kills = this.m.Flags.get("mod_hunter.wolvesKilled") || 0;
        tooltip.push({
            id = 7
            type = "text"
            icon = "ui/icons/kills.png"
            text = "Killed " + ::Const.UI.getColorized(kills, ::Const.UI.Color.DamageValue)  + " wolves"
        })
        return tooltip;
    }
})
```

Note that flags are saved and loaded automatically, so you do not need to write any extra code for that. However, if you want to track many things or access them in many places it might get awkward to access flags all the time in this case you might want to only get/set flags on game load/save and otherwise work with normal table keys:

```squirrel
// in player.create()
this.m.mod_hunter_wolvesKilled <- 0; // The default value

// When need to increment
_killer.m.mod_hunter_wolvesKilled++;

// in getRosterTooltip()
local kills = this.m.mod_hunter_wolvesKilled; // Or use directly
```

And then write to flags just before serialization and read right after deserialization:
```squirrel
::mods_hookExactClass("entity/tactical/player", function (cls) {
    local onSerialize = cls.onSerialize;
    cls.onSerialize = function (_out) {
        this.m.Flags.set("mod_hunter_wolvesKilled", this.m.mod_hunter_wolvesKilled);
        onSerialize(_out);
    }

    local onDeserialize = cls.onDeserialize;
    cls.onDeserialize = function (_in) {
        onDeserialize(_in);
        this.m.mod_hunter_wolvesKilled = this.m.Flags.get("mod_hunter_wolvesKilled") || 0;
    }
})
```


## Complex Structures

Looking at the last example in the previous section and thinking about on how it will grow doesn't feel good. Unfortunately flags only support primitive types such as integer, float, string and bool so you cannot:

```squirrel
this.m.Flags.set("mod_hunter", {... everything you have ...});
```

There is a way though to handle complex structures without writing tedious and repetitive code using [stdlib][]:

```squirrel
this.m.Flags.set("mod_hunter", ::std.Util.pack(this.m.mod_hunter));

local packed = this.m.Flags.get("mod_hunter");
if (packed) this.m.mod_hunter = ::std.Util.unpack(packed);
```

As its name suggests `Util.pack()` packs an arbitrary data structure into a string, which might be saved to flags or put anywhere else you want. The full example with flags will be:

<a name="tldr"></a>
```squirrel
local Util = ::std.Util, Table = ::std.Table;

::mods_hookExactClass("entity/tactical/player", function (cls) {
    local create = cls.create;
    cls.create = function (_out) {
        create(_out);
        // Specify all the defaults together
        this.m.mod_hunter <- {wolves = 0, hyenas = 0, unholds = 0};
    }

    local onSerialize = cls.onSerialize;
    cls.onSerialize = function (_out) {
        this.m.Flags.set("mod_hunter", Util.pack(this.m.mod_hunter));
        onSerialize(_out);
    }

    local onDeserialize = cls.onDeserialize;
    cls.onDeserialize = function (_in) {
        onDeserialize(_in);
        local packed = this.m.Flags.get("mod_hunter");
        if (packed) Table.deepExtend(this.m.mod_hunter, Util.unpack(packed));
    }
})

// Then use as usual
local text = this.m.mod_hunter.hyenas + " hyenas killed";
if (...) _killer.m.mod_hunter.unholds++:
```

A couple of new things appeared here. The first one is the default structure initialized in `create()`, this is needed so that all the `this.m.mod_hunter.things` worked even if a player was created anew not only loaded from a savegame.

The second one is `Table.deepExtend()`, which copies key value pairs from the unpacked table into `this.m.mod_hunter`. Using simple `this.m.mod_hunter = Util.unpack(packed)` will also work, however, if we add any key, say `goblins` - may hunt those too, to our default structure then loading the old save created without goblin accounting will overwrite `this.m.mod_hunter` and will not have the `goblins` key anymore, which will either break our code or will force us to write some awkward checks like:
```squirrel
local goblinsKilled = "globlins" in this.m.mod_hunter ? this.m.mod_hunter.goblins : 0;
```

With `Table.deepExtend()` we won't need that, all the new values will be taken from the default structure. This will work as long as we only add keys though.


## Migrations

If the structure we use to store our mod data changes radically, i.e. an integer is replaced with an array or the whole thing is restructured then `Table.deepExtend()` won't be enough. In this case we can take a page from the devs playbook, i.e. add an integer version.

Say we now want not only to track kills but also cut heads and want to store it like this:

```squirrel
this.m.mod_hunter <- {
    v = 2 // to distinguish from previous structures
    kills = {wolves = 0, hyenas = 0, unholds = 0}
    heads = {wolves = 0, hyenas = 0, unholds = 0}
}
```

However, we already have savegames with the previous format. So upon loading we will need to transform the old format into new:

```squirrel
local packed = this.m.Flags.get("mod_hunter");
if (packed) {
    local mod_hunter = Util.unpack(packed);
    local version = "v" in mod_hunter ? mod_hunter.v : 1; // we didn't have this key before

    // Fail if savegame is newer than the module installed
    if (version > this.m.mod_hunter.v) throw "Need to upgrade mod_hunter to load this save";

    // Migrate the structure 1 to 2
    if (version < 2) {
        // Set .kills, the .heads key will be taken from defaults, we don't know anyway
        mod_hunter = {kills = mod_hunter};
    }

    Table.deepExtend(this.m.mod_hunter, mod_hunter);
}
```

Serializing code will stay the same, i.e. simply dump the struct. As shown here some new stuff will still be taken from defaults, since we don't have this data in the old save, this is expected.

If you break your format several times then you can just keep adding these `if (verions < ...) {...}` clauses, should be easy enough. Should also be rather rare, as you don't need it when simply adding a key - `Table.deepExtend()` will handle it for you.

I was focusing all examples on adding data to player, but you can attach to anything else having flags or use global ones, i.e. `World.Flags` exactly the same way.

<!-- ## Limitations -->
<!-- ... -->


[modhooks]: https://www.nexusmods.com/battlebrothers/mods/42
[stdlib]: https://www.nexusmods.com/battlebrothers/mods/676
