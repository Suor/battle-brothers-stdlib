# Battle Brothers stdlib

Or just a thing to take the place of lacking Squirrel/Battle Brothers standard library. An assortment of various utils to help coding mods. If you here first time I suggest starting from the [Usage](#usage) section.

<!-- MarkdownTOC autolink="true" levels="1,2,3" autoanchor="false" start="here" -->

- [Usage](#usage)
- [Feedback](#feedback)
- [API](#api)
    - [String Utils](#string-utils)
    - [Regular Expressions](#regular-expressions)
    - [Text Formatting](#text-formatting)
    - [Random Generator Helpers](#random-generator-helpers)
- [Index](#index)

<!-- /MarkdownTOC -->


# Usage

Currently is aimed to be bundled with your mod, so that people won't need to download an extra thing. To use it just copy `!!stdlib.nut` from here into `scripts/!!stdlib_mymod.nut`. Then:

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
// Will log "mymod: loot for wolf = [werewolf_pelt_item adrenaline_gland_item]"

// Roll weighted talent stars
foreach (i in Rand.take(3, [0 1 2 3 4 5 6 7], weights)) {
    local w = weights[i];
    _player.m.Talents[i] = Rand.choice([1 2 3], [60 30*w 10*w]);
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


# Feedback

Any suggestions, bug reports, other feedback are welcome. The best place for it is this Github, i.e. just create an issue. You can also find me on Discord by **suor.hackflow** username.


# API

Note that all examples here assume namespaces are aliased locally, like `local Rand = ::std.Rand`. I find convenient to do so, but this is certainly not required, it's perfectly ok to just use `::std` namespace directly, i.e. `::std.Text.positive("+15%")`, which might make more sense if you only use it once or twice in a file. 

> [!NOTE]  
> This is a long doc. Click the contents icon in the top left corner to bring up TOC or "README.md" header itself to jump to the start. May also use `Ctrl+F` to jump to whatever you are looking for quickly. There is also the [Index](#index) in the end.


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

#### `join(sep, strings)`

Joins an array of strings into one using given separator. 
```squirrel
// Title case a sentence
Str.join(" ", split("hey there", " ").map(Str.capitalize))
```

#### `replace(str, old, new, [count])`

Replaces occurances of `old` in a given string by `new`. If `count` is passed, only the first `count` occurences are replaced.


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


## Text Formatting

#### `positive(value)`, `negative(value)`, `damage(value)`

Wraps a given value into BBCode signifying something positive, negative or damage, i.e. green, red or red font color. Accepts any value, usually a string or a number:
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

#### `plural(num)`

Returns `"s"` if a given number should be pluralized:
```squirrel
format("Will heal in %i day%s", days, Text.plural(days))
```


## Random Generator Helpers

<!-- #### `int(a, b)`

Returns an integer from `a` to `b`, including these two numbers. Same as `Math.rand()` but see [`using()`](#using) below.
 -->
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

Randomly chooses on of the given options, if weights are passed then each option will be chosen with a probability proportional to its weight:
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

Returns a number of successful rolls of total `tries` ones, each having a given probability of success. This always returns an integer number from 0 to `tries` with an average value of `tries * prob`.
```squirrel
// Flip a coin 10 times
local count = Rand.poly(10, 0.5);

// Loose 3 medicine for around every fifth bro
local num = Rand.poly(::World.getPlayerRoster().getAll().len(), 0.2);
::World.Assets.addMedicine(-3 * num);
```

<!-- #### `using(gen)` -->


# Index

<!-- MarkdownTOC autolink="true" levels="2,3,4" autoanchor="false" start="top" -->

- [String Utils](#string-utils)
    - [`capitalize(str)`](#capitalizestr)
    - [`startswith(str, prefix)`](#startswithstr-prefix)
    - [`endswith(str, suffix)`](#endswithstr-suffix)
    - [`cutprefix(str, prefix)`](#cutprefixstr-prefix)
    - [`cutsuffix(str, suffix)`](#cutsuffixstr-suffix)
    - [`join(sep, strings)`](#joinsep-strings)
    - [`replace(str, old, new, [count])`](#replacestr-old-new-count)
- [Regular Expressions](#regular-expressions)
    - [`find(str, re)`](#findstr-re)
    - [`test(str, re)`](#teststr-re)
    - [`all(str, re)`](#allstr-re)
    - [`replace(str, re, repl)`](#replacestr-re-repl)
- [Text Formatting](#text-formatting)
    - [`positive(value)`, `negative(value)`, `damage(value)`](#positivevalue-negativevalue-damagevalue)
    - [`colored(value, color)`](#coloredvalue-color)
    - [`plural(num)`](#pluralnum)
- [Random Generator Helpers](#random-generator-helpers)
    - [`float([a, b])`](#floata-b)
    - [`chance(prob)`](#chanceprob)
    - [`choice(options, weights = null)`](#choiceoptions-weights--null)
    - [`choices(num, options, weights = null)`](#choicesnum-options-weights--null)
    - [`take(num, options, weights = null)`](#takenum-options-weights--null)
    - [`poly(tries, prob)`](#polytries-prob)

<!-- /MarkdownTOC -->
