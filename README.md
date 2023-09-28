# Battle Brothers stdlib

Or just a thing to take the place of lacking Squirrel/Battle Brothers standard library. An assortment of various utils to help coding mods. 


## Usage

Currently is aimed to be bundled with your mod, so that people won't need to download an extra thing. To use it just copy `!!stdlib.nut` from here into `scripts/!!stdlib_mymod.nut`. Then:

```squirrel
// Make local aliases for std namespaces
local Rand = ::std.Rand, Re = ::std.Re, Str = ::std.Str, Text = ::std.Text, 
      Debug = ::std.Debug.with({prefix = "mymod: "});

// Choose a random weapon
local weapon = Rand.choice(["scramasax" "ancient/khopesh" "falchion"]);
actor.m.Items.equip(new("scripts/items/weapons/" + weapon));

// Same but with different weights
local weapon = Rand.choice(["scramasax" "ancient/khopesh" "falchion"], [4 2 1]);
...

// Dropping loot for a wolf
local n = 1 + Rand.poly(2, ::World.Assets.getExtraLootChance());
local items = Rand.choices(n, ["werewolf_pelt_item" "adrenaline_gland_item"], [70 30]);
foreach (item in items) {
    local loot = ::new("scripts/items/misc/" + item);
    loot.drop(_tile)
}

// Log that, accepts arbitrary nested data structure
Debug.log("loot for wolf", items);
// Will log "mymod: loot for wolf = [werewolf_pelt_item adrenaline_gland_item]"

// Roll weighted talent stars
foreach (i in Rand.take(3, [0 1 2 3 4 5 6 7], weights)) {
    local w = weights[i];
    _player.m.Talents[i] = Rand.choice([1 2 3], [60 30*w 10*w])
}

// Various str utils
local short = Str.cutprefix(name, "Ancient ");
if (Str.startswith("background.legends_", this.getID())) ...
Str.join("_", split(id, "."))

// Regexes
local romanNumber = Re.find(this.getName(), " ([IVXLC]+)$");
local versionNums = Re.all("1.4.25", @"\d+"); // ["1", "4", "25"]

// Patch tooltip text, add 5 to chance to hit, and make it green color
local tooltip = getTooltip();
tooltip[i].text = Re.replace(tooltip[i].text, 
    @"(\d+)(% chance to hit)", 
    @(x, end) Text.positive(x.tointeger() + 5) + end);
```

For a full list of things see below \[TO BE DONE\]. 


## Feedback

Any suggestions, bug reports, other feedback are welcome. The best place for it is this Github, i.e. just create an issue. You can also find me on Discord by **suor.hackflow** username.


## Docs

Note that all examples in this section assume namespaces are aliased locally, like `local Rand = ::std.Rand`. I find convenient to do so, but this is certainly not required, it's perfectly ok to just use `::std` namespace directly, i.e. `::std.Text.positive("+15%")`, which might make more sense if you only use it once or twice in a file. 


### String Utils

#### `Str.replace(str, old, new, [count])`

Replaces occurances of `old` in a given string by `new`. If `count` is passed, only the first `count` occurences are replaced.

#### `Str.startswith(str, prefix)`

Checks whether a string starts with a certain prefix. I.e. disable a skill if it's active:
```squirrel
if (Str.startswith("actives.", skill.getID())) skill.m.IsUsable = false;
```

#### `Str.endswith(str, suffix)`

Checks whether a string ends with a certain suffix. 
```squirrel
// Remove old +- chance to hit
local tooltip = getTooltip().filter(
    @(_, rec) rec.type != "text" || Str.endswith(rec.text, "chance to hit");
```

#### `Str.cutprefix(str, prefix)`

If a given string starts with `prefix` then returns the string with the prefix cut. Otherwise returns the whole string.

#### `Str.cutsuffix(str, suffix)`

If a given string ends with `suffix` then returns the string with the suffix cut. Otherwise returns the whole string.

#### `Str.join(sep, strings)`

Joins an array of strings into one using given separator. 
```squirrel
// Title case a sentence
Str.join(" ", split("hey there", " ").map(Str.capitalize))
```

### `Str.capitalize(str)`

Returns a copy of the string with its first character capitalized and the rest lowercased.


### Regular expressions

...
