# Battle Brothers stdlib

Or just a thing to take the place of lacking Squirrel/Battle Brothers standard library. An assortment of various utils to help coding mods. If you here first time I suggest starting from the [Usage](#usage) section.

<!-- MarkdownTOC autolink="true" levels="1,2,3" autoanchor="false" start="here" -->

- [Usage](#usage)
- [Compatibility](#compatibility)
- [API](#api)
    - [String Utils](#string-utils)
    - [Regular Expressions](#regular-expressions)
    - [Text Formatting](#text-formatting)
    - [Random Generator Helpers](#random-generator-helpers)
    - [Array](#array)
    - [Table](#table)
    - [Actor](#actor)
    - [Player](#player)
    - [Tile](#tile)
    - [Debug Helpers](#debug-helpers)
    - [Dev Utils](#dev-utils)
    - [Other Utils](#other-utils)
- [Experimental](#experimental)
- [Feedback](#feedback)
- [Index](#index)

<!-- /MarkdownTOC -->


# Usage

Install it from [NexusMods][nexus-mods], or grab from here and zip. Then:

```squirrel
// Make local aliases for std namespaces
local Rand = ::std.Rand, Re = ::std.Re, Str = ::std.Str, Text = ::std.Text, 
      Debug = ::std.Debug.with({prefix = "mymod: "});

// Choose a random weapon
local weapon = Rand.choice(["scramasax" "ancient/khopesh" "falchion"]);
actor.m.Items.equip(::new("scripts/items/weapons/" + weapon));

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
// Will log mymod: loot for wolf = ["werewolf_pelt_item" "adrenaline_gland_item"]

// Roll weighted talent stars
foreach (i in Rand.take(3, [0 1 2 3 4 5 6 7], weights)) {
    local w = weights[i];
    _player.m.Talents[i] = Rand.choice([1 2 3], [60 30*w 10*w]);
}

// Add one more talent, but not in attributes excluded by background
Player.addTalents(_player, 1, {excluded = "strict"})

// Up 3 levels
Player.giveLevels(_player, 3);

// Give 2 good traits
Player.addTraits(_player, 2, {good = true, soso = false, bad = false});

// Check whether actor is ok, not null, dead, broken, is on map
if (!Actor.isValidTarget(_entity)) return null;

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

For a full list of things see below or jump to [Index](#index).

See also [Serialization for Humans](docs/savegames.md).


# Compatibility

Is compatible with everything. Does not modify the game only provides useful utilities. Is safe to add and remove at any time.

Additionally, stdlib is guaranteed to be backwards compatible, i.e. it is always safe to upgrade it to a newer version. This covers all the functions and their params documented here (except Dev Utils and experimental stuff), any pieces not metioned in this README may disappear or change. Also, the specific output of functions intended to be read by humans - several debug utils - are not covered by these guarantees.

stdlib does not depend on anything, however if [modhooks][] or [Modern Hooks][ModernHooks] are present then it will register itself, so you can declare a dependency like:
```squirrel
::mods_queue(mod.ID, "stdlib(>=2.5)", function () {
    // ... queued code goes here ...
})

// Or using Modern Hooks
mod.require("stdlib >= 2.5");
```


# API

Note that all examples here assume namespaces are aliased locally, like `local Rand = ::std.Rand`. I find convenient to do so, but this is certainly not required, it's perfectly ok to just use `::std` namespace directly, i.e. `::std.Text.positive("+15%")`, which might make more sense if you only use it once or twice in a file. 

> [!NOTE]  
> This is a long doc. Click the contents icon in the top right corner to bring up TOC or "README.md" header itself to jump to the start. May also use `Ctrl+F` to jump to whatever you are looking for quickly. There is also the [Index](#index) in the end.


## String Utils

#### `capitalize(str)`

Returns a copy of the string with its first character capitalized and the rest lowercased.

#### `startswith(str, prefix)`

Checks whether a string starts with a certain prefix. I.e. disable a skill if it's active:
```squirrel
if (Str.startswith("actives.", skill.getID())) skill.m.IsUsable = false;
```

#### `endswith(str, suffix)`

Checks whether a string ends with a certain suffix. 
```squirrel
// Remove old +- chance to hit
local tooltip = getTooltip().filter(
    @(_, rec) rec.type != "text" || Str.endswith(rec.text, "chance to hit");
```

#### `cutprefix(str, prefix)`

If a given string starts with `prefix` then returns the string with the prefix cut. Otherwise returns the whole string:
```squirrel
local short = Str.cutprefix(_entity.getName(), "Ancient ");
```

#### `cutsuffix(str, suffix)`

If a given string ends with `suffix` then returns the string with the suffix cut. Otherwise returns the whole string.

#### `split(sep, s, count = inf)`

Split a string with the given separator, up to `count` times:

```squirrel
Str.split(", ", "Hi, there, guys")     # ["Hi", "there", "guys"]
Str.split(", ", "Hi, there, guys", 1)  # ["Hi", "there, guys"]
```

#### `join(sep, strings)`

Joins an array of strings into one using given separator.
```squirrel
// Title case a sentence
Str.join(" ", split("hey there", " ").map(Str.capitalize))
```

#### `replace(str, old, new, [count])`

Replaces occurances of `old` in a given string by `new`. If `count` is passed, only the first `count` occurences are replaced.

#### `escapeHTML(str)`

Escapes symbols, which have special function in HTML. Handy to prepare a message for `::logInfo()` or sending to UI:

```squirrel
::logInfo("msg = " + Str.escapeHTML(msg)); // if you expect <, > or & in msg

// Note that using Debug.log() or std.debug() will do that for you automatically:
Debug.log("msg", msg);
std.debug("msg = " + msg);
```


## Regular Expressions

Note that in place of a regular expression argument all these functions accept both string and `regexp` object. If a string is passed it is wrapped with a `regexp()` call behind the scene. Also, I use verbatim string syntax to write regexes in all examples here as this allows to not escape a very common `\` symbol, i.e. `@"\w\.\d"` is the same as `"\\w\\.\\d"`.

#### `find(str, re)`

Find a match for `re` in a given string and return a match in a convenient form: if there is no captures in the regex then return a part of string matched, if there is a single capture return it's value, if there are several of them return an array of strings containing parts of string captured:
```squirrel
Re.find("v2.15", @"\d+\.\d+")     // "2.15"
Re.find("v2.15", @"v\d+\.\d+")    // "v2.15"
Re.find("v2.15", @"v(\d+\.\d+)")  // "2.15"
Re.find("v2.15", @"(\d+)\.(\d+)") // ["2", "15"]
``` 

Will always return `null` if no match is found. Note that both string and `regexp` object is accepted as second argument, so you may prepare a regexp for efficiency:
```squirrel
local toHitRe = regexp(@"([+-]?\d+)%? chance to hit"); // Put this outside of func/loop
local toHit = Re.find(rec.text, toHitRe).tointeger();
```

#### `test(str, re)`

Test if `re` matches a given string. Returns either `true` or `false`. 

#### `all(str, re)`

Find all matches of a regex in a given string and return an array of them in a convenient form, same one as in `find()` above:
```squirrel
Re.all("perk.mastery.sword", @"\w+") == ["perk", "mastery", "sword"]
Re.all("x = 12, y = 7", @"(\w+) = (\d+)") == [["x", "12"], ["y", "7"]]
```

If no matches found returns an empty array. 

#### `replace(str, re, repl)`

Finds and replaces all matches of `re` in a given string with `repl`. If `repl` is a function it is called to calculate a replacement string, all the captured substring are passed as arguments. 
```squirrel
// Nothing takes less than a week
Re.replace("takes 3 days", @"\d+ days?", "a week") == "takes a week"

// Mask numbers
Re.replace("v1.2.7", @"\d+", "X") == "vX.X.X"

// Colorize damage numbers
Re.replace(desc, "([+-]?\d+)", Text.damage)

// Colorize depending on context
Re.replace(desc, "(\d+)( bonus|fatigue)", function (num, what) {
    local colored = what == " bonus" ? Text.positive : Text.negative;
    return colored(num) + what;
})
```

#### `escape(str)`

Escapes `str` so it could be used as a part of regular expression matching it as is. Might be useful to construct regular expressions dynamically:

```squirrel
local name = bro.getName();
local re = regexp(Re.escape(name) + @".*?is hit for");
```


## Text Formatting

#### `positive(value)`, `negative(value)`, `damage(value)`, `ally(value)`, `enemy(value)`

Wraps a given value into BBCode signifying something positive, negative or whatever, i.e. green, red or another font color used by game in this context. Accepts any value, usually a string or a number:
```squirrel
// Basic usage
tooltip.push({..., text = Text.negative("Out of ammo")})

// Dynamically decide whether it's good or bad
local colored = bonus > 0 ? Text.positive : Text.negative;
text = "Has " + colored((bonus > 0 ? "+" : "") + bonus + "%") + " chance to hit"
```

In complex situations might be combined with the `format()` built-in:
```squirrel
local others = nimble && bf ? "Nimble and Battle Forged" :
               nimble ? "Nimble" : bf ? "Battle Forged" : null;
local hp = Text.positive(Math.round(100 * hpMult) + "%");
local armor = Text.positive(Math.round(100 * armorMult) + "%");
tooltip.push({
    ...
    text = format("Combined with %s you only receive %s damage to Hitpoints 
        and %s damage to Armor", others, hp, armor)
}
```

#### `colored(value, color)`

Same as above but may specify any color, usually with `#xxxxxx` hex notation:
```squirrel
Text.colored(bro.getName(), "#1e468f") + " hits ..."
```

#### `plural(num, [singular, plural])`

Returns `"s"` if a given number should be pluralized. In 3-argument form will return singular and plural form when appropriate:
```squirrel
format("Will heal in %i day%s", days, Text.plural(days))

"Chopped up " + Text.damage(kills) + Text.plural(kills, " wolf", " wolves"))
```


## Random Generator Helpers

#### `int(a, b)`

Returns an integer from `a` to `b`, including these two numbers. Same as `::Math.rand()` but see [`using()`](#usinggen) below.


#### `float([a, b])`

Returns a float number `x`, which satisfies `a <= x < b`. If used without params assumes `a = 0, b = 1`.

#### `chance(prob)`

Returns `true` with a given probability, which goes from 0 to 1.0:
```squirrel
// Every third guy with a decent armor, gets an upgrade
if (armor.getArmorMax() >= 95 && Rand.chance(0.333)) {
    armor.setUpgrade(::new("scripts/items/armor_upgrades/double_mail_upgrade"));
}
```

<!-- ### `index(n, weights = null)` -->

#### `choice(options, weights = null)`

Randomly chooses one of the given options, if weights are passed then each option will be chosen with a probability proportional to its weight:
```squirrel
// Play a random sound
local sound = Rand.choice(["curse_01.wav" "curse_02.wav"]);
::Sound.play("sounds/combat/mymod_" + sound, ::Const.Sound.Volume.Skill, actor.getPos());

// Half of the guys get throwing weapons, mostly axes
if (Rand.chance(0.5)) {
    local weapon = Rand.choice(["throwing_axe" "javelin"], [2 1]);
    this.m.Items.addToBag(::new("scripts/items/weapons/" + weapon));
}
```

#### `choices(num, options, weights = null)`

Makes an array of `num` random choices from the given options, each might be taken any number of times. Weights apply same as in `choice()` above.
```squirrel
// Add 3 random trade goods to the stash
foreach (name in Rand.choices(3, ["salt" "silk" "spices" "furs" "dies"])) {
    local item = ::new("scripts/items/trade/" + name + "_item");
    ::World.Assets.getStash().add(item);
}

// Roll two loaded dices
local rolls = Rand.choices(2, [1 2 3 4 5 6], [0.9 1 1 1 1 1.1]);
```

#### `take(num, options, weights = null)`

Choose `num` non-repeated random options from the given array. Basically same as `choices()` but with no repeats:
```squirrel
// Apply two completely random traits to a bro
foreach (trait in Rand.take(2, ::Const.CharacterTraits)) {
    bro.getSkills().add(::new(trait[1]));
}
```

<!-- #### `insert(arr, item, num = 1)` -->

#### `poly(tries, prob)`

Returns a number of successes from `tries` rolls, each having the given probability of success. This always returns an integer number from 0 to `tries` with an average value of `tries * prob`.
```squirrel
// Flip a coin 10 times
local count = Rand.poly(10, 0.5);

// Loose 3 medicine for around every fifth bro
local num = Rand.poly(::World.getPlayerRoster().getAll().len(), 0.2);
::World.Assets.addMedicine(-3 * num);
```

#### `using(gen)`

Create a new Rand with a replaced backend:
```squirrel
local Rand = ::std.Rand.using(::std.rng);
local Rand = ::std.Rand.using(::std.rng_new(seed));
... use it as usual ...
```

`::rng` and `::rng_new` are part of [Adam's hooks][modhooks]. The reason to use something else behind the scenes but `::Math.rand()`, is to not interfere with other random things happening, i.e. to not skew random seeds during party generation. Note that as long as you use `::Math.rand()` or stdlib's `Rand` functions without `using()` the results will be reproducible with save/load, if you don't want your random behavior follow that then this will be another reason to use a separate random generator.


## Array

#### `cat(arrays)`, `concat(...arrays)`

Concatenates all the passed arrays into a single one.
```squirrel
repl.acall(Array.concat([null], vargv))
```

#### `all(arr, func)`

Checks that `func` returns truthy values for all elements in a given array.
```squirrel
// Too early for this event
local bros = ::World.getPlayerRoster().getAll();
if (Array.all(bros, @(bro) bro.getLevel() < 6)) return;
```

#### `any(arr, func)`

Checks that `func` returns a truthy value for at least one element in a given array.

```squirrel
// Check whether any bros are wounded
local haveWounded = Array.any(bros, @(bro) bro.getHitpointsPct() < 1.0);

// Have a decent spare weapon
local stash = this.World.Assets.getStash().getItems();
Array.any(stash, @(item) item.isItemType(::Const.Items.ItemType.Weapon) && item.getValue() >= 1000);
```

#### `max(arr, key = null)`

Find a max element in a given array. If `key` is passed then calls it for each element to judje "how big is it".
```squirrel
// Find a bro with a highest pay
local expensiveOne = Array.max(bros, @(bro) bro.getDailyCost());

// Get the most valuable item in stash
local item = Array.max(stash, @(item) item.getValue());
```

#### `min(arr, key = null)`

Find a min element in a given array. If `key` is passed then calls it for each element to judje "how big is it".

#### `sum(arr)`

Sums the elements of an array, returns 0 for an empty one.
```squirrel
local talentScore = Array.sum(bro.getTalents());

// Get total weight of bagged items
local items = bro.getItems().getAllItemsAtSlot(::Const.ItemSlot.Bag);
local totalWeight = Array.sum(items.map(@(item) item.getStaminaModifier()));
```

## Table

#### `get(table, key, def = null)`

Returns the value for a key or a given default. Saves some typing, space and repetition comparing to ``... in ... ? ... : ...`:

```squirrel
local count = Table.get(this.m.EffectCounts, effectID, 0)
```

#### `keys(table)`

Returns an array of table keys.

#### `values(table)`

Returns an array of table values.

```squirrel
local weightsSum = Array.sum(Table.values(weights))
```

#### `pairs(table)`

Returns an array of `[key, value]` pairs.

#### `filter(table, func)`

Creates a table with key value pairs filtered by the given function:

```squirrel
// Drop non-positive chances
local options = Table.filter({...}, @(_, v) v > 0)

// Print out all flags
std.debug(Table.filter(bro.m, @(k, _) Str.startswith(k, "Is")))
```


#### `map(table, func)`

Transforms table keys and values creating a new table. E.g. here how we can flip a table:

```squirrel
Table.map(table, @(k, v) [v k])
```

#### `mapValues(table, func)`

Transforms table values creating a new table:

```squirrel
// Fix expected damage for split_man
hmod.hook("scripts/skills/actives/split_man", function (q) {
    q.getExpectedDamage = @(__original) function (_target) {
        return Table.mapValues(__original(_target), @(k, v) v * 1.5;
    }
}
```

#### `mapKeys(table, func)`

Transforms table values creating a new table.

#### `apply(table, func)`

Sets table values to a result of the given func:

```squirrel
// Double all damage in HitInfo record, not
Table.apply(hitinfo, @(k, v) Str.startswith(k, "Damage") ? v*2 : v)
```

#### `extend(dst, src)`

Extends `dst` table with key, value pairs from `src`. Any existing keys are overwritten. Returns the `dst` table.

#### `merge(table1, table2)`

Creates a new table with contents of given tables merged. For dup keys second table values are taken.
```squirrel
// Simulate named params
local defaults = {prefix = "> ", depth = 3};
function log(message, options = {}) {
    options = Table.merge(defaults, options);
    // ...
}
```

#### `setDefaults(dst, defaults)`

Fills in absent keys in `dst` with `defaults`. Useful to modify stuff inplace:
```squirrel
foreach (info in mod.PartyInfo) {
    Table.setDefaults(info, {Battles = 0, Kills = 0, Dead = false});
}
```

The only difference from `.extend()` is that missing keys are not overwritten here.

#### `deepExtend(dst, src)`

Same as `Table.extend()` but does it recursively, i.e. if `dst[key]` and `src[key]` are both tables then does this extension for those too. Might be used to fill in an empty struct with data:
```squirrel
this.m.data = {foo = 0, bar = {baz = 0}, quix = []};
Table.deepExtend(this.m.data, Util.unpack(::World.Flags.get("mymod")));
```

About this particular example, see more in [`Util.pack()`](#packdata) and in a special [piece on serialization](docs/savegames.md).


## Actor

#### `isAlive(actor)`

Checks whether actor is not null, alive and not dying.

#### `isValidTarget(actor)`

Same as above plus `isPlacedOnMap()`. The best thing to use on potential enemies and allies in AI code or skill targeting code. In most cases trying to operate with an entity not passing this will result in a crash.


## Player

#### `giveLevels(player, num)`

Give `num` levels to `player`. This adds XP and advances everything necessary.

#### `rerollTalents(player, num, opts = null)`

Rerolls talents, a.k.a. stars, for `player`. Clearing them and then adding them in `num` attributes. Available `opts` are:

- `probs` - probabilities for 1, 2 or 3 stars. Defaults to `[60 30 10]` as in vanilla.
- `weighted` - better chances to get talent in attributes favored by background. Plus higher chance to get 2 or 3 stars in those attributes too. The attributes not favored by background get talents rarer and have lower chances for more stars. Work on top of `probs`. Defaults to `false`.
- `excluded` - how to treat background exclusions:
    + "strict" - never get excluded talents,
    + "relaxed" - get any other first, then may get excluded (default),
    + "ignored" - completely ignore the excluded list.

```squirrel
// Roll 2 to 4 weighted talents for a player
Player.rerollTalents(_player, 2 + Rand.poly(2, 0.5), {weighted = true})

// Roll 3 talents with heightened probabilities for 2 and 3 stars
Player.rerollTalents(_player, 3, {probs = [35 40 25]})
```

#### `clearTalents(player)`

Remove all talents from `player`.

#### `addTalents(player, num, opts = null)`

Add `num` talents on top of whatever `player` already has. Won't give more stars in existing talents. `opts` work the same way as in [`Player.rerollTalents()`](#rerolltalentsplayer-num-opts--null).

#### `addTraits(player, num, opts = null)`

Give `num` random traits to `player`. Doesn't consult player's background or other traits' exclusions. `opts` are:

- `good` - add good traits, defaults to `true`
- `bad` - add bad traits, defaults to `true`
- `soso` - add so-so traits, defaults to `true`

```squirrel
// Add a couple of good or bad traits
Player.addTraits(_player, 2, {soso = false})
```

Returns a list of traits added, i.e. actual BB objects.

#### removePermanentInjury(_player[, _id])

Removes a permanent injury from the bro and returns it, if id is not passed then removes a random one. Correctly updates player visuals:

```squirrel
local injury = ::std.Player.removePermanentInjury(_player);
if (!injury) return;
// ... notify player
```


## Tile

#### `iterAdjacent(tile)`, `listAdjacent(tile)`

Iterates or lists tiles adjacent to the given one. Often helpful in AI or skill code to replace usual `for (local i = 0; i < ::Const.Direction.COUNT; ++i)` boilerplate:

```squirrel
foreach (tile in Tile.iterAdjacent(myTile)) {
    if (skill.onVerifyTarget(myTile, tile) && (score = scoreTile(tile)) > bestScore) {
        best = {tile = tile, score = score}
    }
}

// List version returns an array
local emptyTiles = Tile.listAdjacent(myTile).filter(@(t) !t.IsEmpty)
```

#### `iterAdjacentActors(tile)`, `listAdjacentActors(tile)`

Iterates or lists actors around the given tile.

```squirrel
// Count allies and enemies around
local allies = 0, enemies = 0;
foreach (actor in Tile.iterAdjacentActors(targetTile)) {
    if (actor.isAlliedWith(_entity)) allies++;
    else enemies++;
}
```


## Debug Helpers

#### `log(name, [value, options = {}])`

Log a passed value under a given name. If value is table or array then pretty print it. See [`Debug.pp()`](#ppdata-options--) below for details and options.

```squirrel
// Simply put out message with a proper prefix
Debug.log(message);

// Print out internals of _player with pretty indentation
Debug.log("bro", _player, {depth = 2});
// Will look like:
// bro = {
//     Level = 5
//     PerkPoints = 1
//     Talents = [0, 0, 0, 2, 0, 2, 0, 3]
//     ...
//     human = {
//         Body = 0
//         ...
//     }
// }

// Same as above (a shorthand)
Debug.log("bro", _player, 2);

// Only show keys that contain "Level"
Debug.log("bro", _player, "Level");
// bro = {m = {Level = 13, LevelUps = 0, LevelUpsSpent = 13, ...}, ...}

// Same but go deeper
Debug.log("bro", _player, {filter = "Level", depth = 4});
// bro = {
//     human = {
//         actor = {m = {LevelActionPointCost = 1, LevelFatigueCost = 4, MaxTraversibleLevels = 1, ...}, ...}
//         ...
//     }
//     m = {Level = 13, LevelUps = 0, LevelUpsSpent = 13, ...}
//     ...
// }
```

See also [`Debug.with()`](#withoptions)

#### `logRepr(name, value, options = {})`

Same as `Debug.log()` but uses concise representations for actors, skills and tiles.

```squirrel
// Print out easy to read list of targets and skills
options.push({target = best.Target, skill = s, score = best.Score});
Debug.logRepr("options", options);
```

#### `trace(name, value, options = {})`

Same as `Debug.log()` but will add current file, line number and function name.

#### `::std.debug(data, options = {})`

A quick way to pretty print data to a log. Same as above, but doesn't have name param and associated `<name> = ` prefix. Very handy in [Dev Console][dev-console]:

```squirrel
// Pretty print town's attributes, 1 is a shorthand for {depth = 1}
std.debug(town, 1)

// Show everything about perks in Skarbrand bro
std.debug(getBro("Skarbrand"), "Perk")

// Same but look deeper
std.debug(getBro("Skarbrand"), {filter = "Perk", depth = 7})
```

#### `pp(data, options = {})`

Formats data into a pretty printed string, i.e. with text wrapped and indented properly. Works on arbitrary nested structures. Has "named params" in a form of `options` table keys:

- `level` - "info", "warning" or "error", defaults to "info",
- `depth` - maximum depth to print, defaults to 3,
- `filter` - only show keys containing string or passing test and their values,
             if it's a func then it should be like `@(k, v) ...`,
- `prefix` - prepend each line with this, defaults to an empty string,
- `trace` - add "filename:lineno in func()", defaults to false,
- `html` - escape html tags and wrap in `<pre>`, defaults to true,
- `width` - assume this screen width in characters, defaults to 100,
- `funcs` - how to show functions in tables, defaults to "count", and might be set to:
    - "full" - prints "name = (function : 0x...)" for each function
    - "count" - print a total number of functions for table
    - false - skip functions
- `repr` - use concise representations for actors, skills and tiles, defaults to false

Note that HTML ignores whitespace by default so `::logInfo(Debug.pp(data))` will not show up pretty when you open log.html in your browser, see `Debug.log()` and `::std.debug()` above.

#### `repr(data, options = {})`

A shortcut for `Debug.pp()` with `repr` set to `true`.

#### `with(options)`

Set up a `Debug` copy with desired defaults:

```squirrel
// Set up a local refs
local Debug = ::std.Debug.with({prefix = "mymod: ", width = 80, depth = 2});
local Warn = Debug.with({level = "warning"});

// Use it as usual
Debug.log("params", params);
Debug.log("bro", this, {depth = 1}); // Can overwrite the new defaults same way
Debug.log("bro", this, 1);           // Same via a shortcut

// Debug.pp() is also affected
::logWarning("Failed to find a value " + value + " in " + Debug.pp(arr));

// Show warnings
Warn.log("Something bad happened");
Warn.logRepr("bad tile", tile);

// Set it up for a mod
::CoolMod <- {
    Name = ...
    ...
    Debug = ::std.Debug.with({prefix = "cool: ", ...})
}

// Use it anywhere in your mod
::CoolMod.Debug.log("talents", this.m.Talents);
```

#### `noop()`

A way to make a dummy Debug object, usable to switch off and on debugging in your mod.

```squirrel
// Set it up the mod, same as above
::CoolMod <- {
    ...
    Debug = ::std.Debug.with({prefix = "cool: ", ...})
}
// Use everywhere as
::CoolMod.Debug.log(...)

// Prepare to release, don't need debug outputs anymore, but don't want to remove/comment out them,
// so we change a single line like here:
::CoolMod <- {
    ...
    Debug = ::std.Debug.with({prefix = "cool: ", ...}).noop()
}

// Ready to debug again:
::CoolMod <- {
    ...
    Debug = ::std.Debug.with({prefix = "cool: ", ...})//.noop()
}
```


## Dev Utils

These are targeted to be used as helpers during debugging your game or mods via [Dev Console][dev-console]. Note that in Dev Console it will look like `std.Dev.doSomething()`, i.e. with all the prefixes.

**As such they are not covered by backward compatibility guarantees.** If you want to use something of this please contact me and I will consider moving it to an appropriate stable section.


#### `getLocation()`

Returns a nearest localtion.

#### `showLocation(_typeId)`

Uncovers location by its `TypeId`:

```squirrel
std.Dev.showLocation("location.witch_hut")
```

#### `getTown([_name])`

Returns a town with the given name or just a nearest one.

#### `rerollHires(_town = null)`

Rerolls hires in the specified town, or in a nearest town if that is not specified.

#### `fixItems()`

Fix all items on all bros and in stash.

#### `breakItems(_pct)`

Sets condition of all items on bros and in stash to specified percantage. I.e. `std.Dev.breakItems(0.5)` will set everything to the half of their condition.

#### `restoreRelations()`

Restore relations with some noble house. Can be called repeatedly to restore relations with more than one noble house.

#### `getEnemies(_name)`

Returns a list of enemies with a specified name, usable only during combat.

#### `fixCombat()`, `fixCombatEnd()`

Fixes the hang up during combat or when supposed to show combat result screen. This does not fix the underlying issue breaking it of cause, so side effects are unpredictable.


## Other Utils

#### `isNull(obj)`

Checks if obj is null or a null `WeakTableRef`

#### `isKindOf(obj, className)`

Checks if an object has the given `className`. Same as BB `isKindOf()` global but correctly works with `WeakTableRef`s.


#### `isIn(key, obj)`

Checks whether `obj` has the given key. Correctly handles `WeakTableRef`, delegation and BB `SuperName`s.

#### `getMember(obj, key)`

Gets key for a BB class instance, handling superclasses, delegates and weakrefs.

```squirrel
::mods_hookExactClass("items/weapons/named/named_goblin_heavy_bow", function (cls) {
    local randomizeValues = Util.getMember(cls, "randomizeValues");
    cls.randomizeValues <- function () {
        randomizeValues();
        this.m.FatigueOnSkillUse -= 3; // Make goblin named bows easier to use
    }
})
```

#### `clamp(value, min, max)`

Boxes a given value into `[min, max]` bounds.
```squirrel
this.m.Hitpoints = Util.clamp(this.m.Hitpoints + change, 0, this.m.HitpointsMax);
```

#### `round(value, ndigits = null)`

Rounds a number to `ndigits` precision after the decimal point. If `ndigits` is omitted, it returns the nearest integer. If `ndigits` is negative then the value is rounded to `10 ^ -ndigits`:

```squirrel
Util.round(23.167, 1)  // 23.2
Util.round(23.167)     // 23
Util.round(23.167, -1) // 20
```

#### `deepEq(a, b)`

Compares given two values recursively, i.e. tables and arrays are compared by their contents not referencial equality.

#### `pack(data)`

Packs arbitrary squirrel data structure into a "human readable" string. Contains only printable characters as long as passed data contains only printable strings. Can only pack primitive values, arrays and tables. Borks on functions, classes, instances, etc.

The intended use is savegame serialization, but who knows.

```squirrel
local onSerialize = cls.onSerialize;
cls.onSerialize = function (_out) {
    // Write to flags before save
    this.getFlags().set("mymod", Util.pack(this.m.MyMod))
    onSerialize(_out);
}
```

#### `unpack(data)`

Unpacks whatever was packed with `Util.pack()`.

```squirrel

local onDeserialize = cls.onDeserialize;
cls.onDeserialize = function(_out) {
    onDeserialize(_out);
    // Load from flags
    local packed = this.getFlags().get("mymod")
    if (packed) Table.extend(this.m.MyMod, Util.unpack(packed));
}

```

See more on serialization a [special piece on it](docs/savegames.md).


# Experimental

These things are coded and some even tested but not public yet, i.e. backward-compatibility is not guaranteed for them:

```squirrel
Table.getIn()
Array.findBy(), .some(), .nlargest()
Flags.*
Iter.*
Packer.* // but accessible via Util.pack() and .unpack()
Player.traitType()
Rand.index(), .insert(), .itake()
```


# Feedback

Any suggestions, bug reports, other feedback are welcome. The best place for it is this Github, i.e. just create an issue. You can also find me on Discord by **suor.hackflow** username.


# Index

<!-- MarkdownTOC autolink="true" levels="2,3,4" autoanchor="false" start="top" -->

- [String Utils](#string-utils)
    - [`capitalize(str)`](#capitalizestr)
    - [`startswith(str, prefix)`](#startswithstr-prefix)
    - [`endswith(str, suffix)`](#endswithstr-suffix)
    - [`cutprefix(str, prefix)`](#cutprefixstr-prefix)
    - [`cutsuffix(str, suffix)`](#cutsuffixstr-suffix)
    - [`split(sep, s, count = inf)`](#splitsep-s-count--inf)
    - [`join(sep, strings)`](#joinsep-strings)
    - [`replace(str, old, new, [count])`](#replacestr-old-new-count)
    - [`escapeHTML(str)`](#escapehtmlstr)
- [Regular Expressions](#regular-expressions)
    - [`find(str, re)`](#findstr-re)
    - [`test(str, re)`](#teststr-re)
    - [`all(str, re)`](#allstr-re)
    - [`replace(str, re, repl)`](#replacestr-re-repl)
    - [`escape(str)`](#escapestr)
- [Text Formatting](#text-formatting)
    - [`positive(value)`, `negative(value)`, `damage(value)`, `ally(value)`, `enemy(value)`](#positivevalue-negativevalue-damagevalue-allyvalue-enemyvalue)
    - [`colored(value, color)`](#coloredvalue-color)
    - [`plural(num, [singular, plural])`](#pluralnum-singular-plural)
- [Random Generator Helpers](#random-generator-helpers)
    - [`int(a, b)`](#inta-b)
    - [`float([a, b])`](#floata-b)
    - [`chance(prob)`](#chanceprob)
    - [`choice(options, weights = null)`](#choiceoptions-weights--null)
    - [`choices(num, options, weights = null)`](#choicesnum-options-weights--null)
    - [`take(num, options, weights = null)`](#takenum-options-weights--null)
    - [`poly(tries, prob)`](#polytries-prob)
    - [`using(gen)`](#usinggen)
- [Array](#array)
    - [`cat(arrays)`, `concat(...arrays)`](#catarrays-concatarrays)
    - [`all(arr, func)`](#allarr-func)
    - [`any(arr, func)`](#anyarr-func)
    - [`max(arr, key = null)`](#maxarr-key--null)
    - [`min(arr, key = null)`](#minarr-key--null)
    - [`sum(arr)`](#sumarr)
- [Table](#table)
    - [`get(table, key, def = null)`](#gettable-key-def--null)
    - [`keys(table)`](#keystable)
    - [`values(table)`](#valuestable)
    - [`pairs(table)`](#pairstable)
    - [`filter(table, func)`](#filtertable-func)
    - [`map(table, func)`](#maptable-func)
    - [`mapValues(table, func)`](#mapvaluestable-func)
    - [`mapKeys(table, func)`](#mapkeystable-func)
    - [`apply(table, func)`](#applytable-func)
    - [`extend(dst, src)`](#extenddst-src)
    - [`merge(table1, table2)`](#mergetable1-table2)
    - [`setDefaults(dst, defaults)`](#setdefaultsdst-defaults)
    - [`deepExtend(dst, src)`](#deepextenddst-src)
- [Actor](#actor)
    - [`isAlive(actor)`](#isaliveactor)
    - [`isValidTarget(actor)`](#isvalidtargetactor)
- [Player](#player)
    - [`giveLevels(player, num)`](#givelevelsplayer-num)
    - [`rerollTalents(player, num, opts = null)`](#rerolltalentsplayer-num-opts--null)
    - [`clearTalents(player)`](#cleartalentsplayer)
    - [`addTalents(player, num, opts = null)`](#addtalentsplayer-num-opts--null)
    - [`addTraits(player, num, opts = null)`](#addtraitsplayer-num-opts--null)
    - [removePermanentInjury\(_player\[, _id\]\)](#removepermanentinjury_player-_id)
- [Tile](#tile)
    - [`iterAdjacent(tile)`, `listAdjacent(tile)`](#iteradjacenttile-listadjacenttile)
    - [`iterAdjacentActors(tile)`, `listAdjacentActors(tile)`](#iteradjacentactorstile-listadjacentactorstile)
- [Debug Helpers](#debug-helpers)
    - [`log(name, [value, options = {}])`](#logname-value-options--)
    - [`logRepr(name, value, options = {})`](#logreprname-value-options--)
    - [`trace(name, value, options = {})`](#tracename-value-options--)
    - [`::std.debug(data, options = {})`](#stddebugdata-options--)
    - [`pp(data, options = {})`](#ppdata-options--)
    - [`repr(data, options = {})`](#reprdata-options--)
    - [`with(options)`](#withoptions)
    - [`noop()`](#noop)
- [Dev Utils](#dev-utils)
    - [`getLocation()`](#getlocation)
    - [`showLocation(_typeId)`](#showlocation_typeid)
    - [`getTown([_name])`](#gettown_name)
    - [`rerollHires(_town = null)`](#rerollhires_town--null)
    - [`fixItems()`](#fixitems)
    - [`breakItems(_pct)`](#breakitems_pct)
    - [`restoreRelations()`](#restorerelations)
    - [`getEnemies(_name)`](#getenemies_name)
    - [`fixCombat()`, `fixCombatEnd()`](#fixcombat-fixcombatend)
- [Other Utils](#other-utils)
    - [`isNull(obj)`](#isnullobj)
    - [`isKindOf(obj, className)`](#iskindofobj-classname)
    - [`isIn(key, obj)`](#isinkey-obj)
    - [`getMember(obj, key)`](#getmemberobj-key)
    - [`clamp(value, min, max)`](#clampvalue-min-max)
    - [`round(value, ndigits = null)`](#roundvalue-ndigits--null)
    - [`deepEq(a, b)`](#deepeqa-b)
    - [`pack(data)`](#packdata)
    - [`unpack(data)`](#unpackdata)

<!-- /MarkdownTOC -->

[nexus-mods]: https://www.nexusmods.com/battlebrothers/mods/676
[modhooks]: https://www.nexusmods.com/battlebrothers/mods/42
[ModernHooks]: https://www.nexusmods.com/battlebrothers/mods/685
[dev-console]: https://www.nexusmods.com/battlebrothers/mods/380
