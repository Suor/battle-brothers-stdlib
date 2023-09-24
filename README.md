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

... To be filled in ...
