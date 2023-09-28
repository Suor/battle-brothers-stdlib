Filters <- {
    function sign(str, value) {
        return (value > 0 ? "+" : "") + str;
    }
    function percent(str, value) {
        // or Math.round(100 * value) + "%" ???
        return str + "%"
    }
    function positive(str, value) {return Text.positive(str)}
    function negative(str, value) {return Text.negative(str)}
    function color(str, value) {
        return value > 0 ? Text.positive(str) : value < 0 ? Text.negative(str) : str;
    }
    function colorRev(str, value) {
        return value > 0 ? Text.negative(str) : value < 0 ? Text.positive(str) : str;
    }
    function plural(str, value) {return Text.plural(value)}
}

function render(_template, ...) {
    // "Gives {0|sign|percent|colored} hit chance"
    // "Will heal in {0} day{0|plural}"
    return Re.replace(_template, @"\{(\d+)((?:\|\w+)+)?\}", function (idx, filtersStr) {
        if (idx.tointeger() >= vargv.len())
            throw "Argument " + idx + " was not passed to Text.render()";
        local value = vargv[idx.tointeger()];
        local result = value;
        if (filtersStr != "") {
            local filters = split(filtersStr.slice(1), "|");
            foreach (f in filters) {
                if (!(f in Filters))
                    throw "Unknown filter \"" + f + "\" in Text.render()";
                result = Text._Filters[f](result, value)
            }
        }
        return result;
    })
}

// Still experimental
assertEq(Text._render("... {0|sign|percent|color} hc", 12), "... [color=green]+12%[/color] hc")
assertEq(Text._render("... {0|sign|percent|color} hc", -5), "... [color=red]-5%[/color] hc")
assertEq(Text._render("{0|colorRev}", -5), "[color=green]-5[/color]")
assertEq(Text._render("Lasts {.0} day{.0|plural}", 11), "Lasts 11 days")
assertEq(Text._render("Lasts {%0} day{%0|plural}", 11), "Lasts 11 days")
assertEq(Text._render("Lasts {_0} day{_0|plural}", 11), "Lasts 11 days")
assertEq(Text._render("Lasts {=0} day{=0|plural}", 11), "Lasts 11 days")
assertEq(Text._render("Lasts {0} day{0|plural} if more than {10%|negative} health lost", 11), "Lasts 11 days")
assertEq(Text._render("Lasts [0] day[0|plural]", 11), "Lasts 11 days")
assertEq(Text._render("Lasts {{0}} day{{0|plural}}", 11), "Lasts 11 days")
assertEq(Text._render("Lasts {{0}} day{{0}|plural}", 11), "Lasts 11 days")
assertEq(Text._render("Lasts {[0]} day{[0]|plural}", 11), "Lasts 11 days")
assertEq(Text._render("Lasts {} day{.0|plural}", 21), "Lasts 21 day")
assertEq(Text._render("Get {1%|positive} damage for each {3|negative} fatigue", 1, 5),
        "Get [color=green]+1[/color] damage for each [color=red]5[/color] fatigue")

// assertEq(Text._render("Has {}| chance to hit", 12), "")
// assertEq(Text._render("Has {|sign|percent|color} chance to hit", 12), "")
// assertEq(Text._render("Has {.sign.percent.color} chance to hit", 12), "")
// assertEq(Text._render("Has {12%|positive} chance to hit", 12), "")
// assertEq(Text._render("Has {double rate|positive} chance to hit", 12), "")
// local bonus = 1, fat = 3;
// "Get [color=green]+1%[/color] damage for each [color=red]3[/color] fatigue")

// Text.render("Get {0|sign|percent|positive} damage for each {1|negative} fatigue", bonus, fat)
// Text.render("Get {bonus|percent}sign|positive} damage for each {fat|negative} fatigue")
// "Get " + Text(bonus).sign.percent.positive + " damage for each " + Text(fat).negative + " fatigue")
