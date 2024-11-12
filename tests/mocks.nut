local STDLIB_DIR = getenv("STDLIB_DIR") || "";

function startswith(s, sub) {
    if (s.len() < sub.len()) return false;
    return s.slice(0, sub.len()) == sub;
}
::include <- function (script) {
    if (startswith(script, "stdlib")) script = STDLIB_DIR + script;
    return dofile(script + ".nut", true)
}
::new <- function (script) {
    return {}
}

::Math <- {
    minf = @(a, b) a <= b ? a : b
    maxf = @(a, b) a >= b ? a : b
    min = @(a, b) (a <= b ? a : b).tointeger()
    max = @(a, b) (a >= b ? a : b).tointeger()
    // round = @(x) floor(x + 0.5)
    // function rand(min, max) {
    //     min = floor(min);
    //     max = floor(max);
    //     return (min + floor(::rand() * (max - min + 0.99999) / RAND_MAX)).tointeger();
    // }
    // pow = pow
}

::Const <- {
    UI = {
        Color = {
            PositiveValue = "green"
            NegativeValue = "red"
        }
        function getColorized(str, color) {
            return "[color=" + color + "]" + str + "[/color]";
        }
    }
    Attributes = {
        Hitpoints = 0,
        Bravery = 1,
        Fatigue = 2,
        Initiative = 3,
        MeleeSkill = 4,
        RangedSkill = 5,
        MeleeDefense = 6,
        RangedDefense = 7,
        COUNT = 8
    }
}
::Const.CharacterTraits <- [
    [
        "trait.eagle_eyes",
        "scripts/skills/traits/eagle_eyes_trait"
    ],
    [
        "trait.short_sighted",
        "scripts/skills/traits/short_sighted_trait"
    ],
    [
        "trait.tough",
        "scripts/skills/traits/tough_trait"
    ],
    [
        "trait.strong",
        "scripts/skills/traits/strong_trait"
    ],
    [
        "trait.hesitant",
        "scripts/skills/traits/hesitant_trait"
    ],
    [
        "trait.quick",
        "scripts/skills/traits/quick_trait"
    ],
    [
        "trait.tiny",
        "scripts/skills/traits/tiny_trait"
    ],
    [
        "trait.cocky",
        "scripts/skills/traits/cocky_trait"
    ],
    [
        "trait.clumsy",
        "scripts/skills/traits/clumsy_trait"
    ],
    [
        "trait.fearless",
        "scripts/skills/traits/fearless_trait"
    ],
    [
        "trait.fat",
        "scripts/skills/traits/fat_trait"
    ],
    [
        "trait.dumb",
        "scripts/skills/traits/dumb_trait"
    ],
    [
        "trait.bright",
        "scripts/skills/traits/bright_trait"
    ],
    [
        "trait.drunkard",
        "scripts/skills/traits/drunkard_trait"
    ],
    [
        "trait.fainthearted",
        "scripts/skills/traits/fainthearted_trait"
    ],
    [
        "trait.bleeder",
        "scripts/skills/traits/bleeder_trait"
    ],
    [
        "trait.ailing",
        "scripts/skills/traits/ailing_trait"
    ],
    [
        "trait.determined",
        "scripts/skills/traits/determined_trait"
    ],
    [
        "trait.dastard",
        "scripts/skills/traits/dastard_trait"
    ],
    [
        "trait.deathwish",
        "scripts/skills/traits/deathwish_trait"
    ],
    [
        "trait.fragile",
        "scripts/skills/traits/fragile_trait"
    ],
    [
        "trait.insecure",
        "scripts/skills/traits/insecure_trait"
    ],
    [
        "trait.optimist",
        "scripts/skills/traits/optimist_trait"
    ],
    [
        "trait.pessimist",
        "scripts/skills/traits/pessimist_trait"
    ],
    [
        "trait.superstitious",
        "scripts/skills/traits/superstitious_trait"
    ],
    [
        "trait.brave",
        "scripts/skills/traits/brave_trait"
    ],
    [
        "trait.dexterous",
        "scripts/skills/traits/dexterous_trait"
    ],
    [
        "trait.sure_footing",
        "scripts/skills/traits/sure_footing_trait"
    ],
    [
        "trait.asthmatic",
        "scripts/skills/traits/asthmatic_trait"
    ],
    [
        "trait.iron_lungs",
        "scripts/skills/traits/iron_lungs_trait"
    ],
    [
        "trait.craven",
        "scripts/skills/traits/craven_trait"
    ],
    [
        "trait.greedy",
        "scripts/skills/traits/greedy_trait"
    ],
    [
        "trait.gluttonous",
        "scripts/skills/traits/gluttonous_trait"
    ],
    [
        "trait.spartan",
        "scripts/skills/traits/spartan_trait"
    ],
    [
        "trait.athletic",
        "scripts/skills/traits/athletic_trait"
    ],
    [
        "trait.brute",
        "scripts/skills/traits/brute_trait"
    ],
    [
        "trait.irrational",
        "scripts/skills/traits/irrational_trait"
    ],
    [
        "trait.clubfooted",
        "scripts/skills/traits/clubfooted_trait"
    ],
    [
        "trait.loyal",
        "scripts/skills/traits/loyal_trait"
    ],
    [
        "trait.disloyal",
        "scripts/skills/traits/disloyal_trait"
    ],
    [
        "trait.bloodthirsty",
        "scripts/skills/traits/bloodthirsty_trait"
    ],
    [
        "trait.iron_jaw",
        "scripts/skills/traits/iron_jaw_trait"
    ],
    [
        "trait.survivor",
        "scripts/skills/traits/survivor_trait"
    ],
    [
        "trait.impatient",
        "scripts/skills/traits/impatient_trait"
    ],
    [
        "trait.swift",
        "scripts/skills/traits/swift_trait"
    ],
    [
        "trait.night_blind",
        "scripts/skills/traits/night_blind_trait"
    ],
    [
        "trait.night_owl",
        "scripts/skills/traits/night_owl_trait"
    ],
    [
        "trait.paranoid",
        "scripts/skills/traits/paranoid_trait"
    ],
    [
        "trait.hate_greenskins",
        "scripts/skills/traits/hate_greenskins_trait"
    ],
    [
        "trait.hate_undead",
        "scripts/skills/traits/hate_undead_trait"
    ],
    [
        "trait.hate_beasts",
        "scripts/skills/traits/hate_beasts_trait"
    ],
    [
        "trait.fear_beasts",
        "scripts/skills/traits/fear_beasts_trait"
    ],
    [
        "trait.fear_undead",
        "scripts/skills/traits/fear_undead_trait"
    ],
    [
        "trait.fear_greenskins",
        "scripts/skills/traits/fear_greenskins_trait"
    ],
    [
        "trait.teamplayer",
        "scripts/skills/traits/teamplayer_trait"
    ],
    [
        "trait.weasel",
        "scripts/skills/traits/weasel_trait"
    ],
    [
        "trait.huge",
        "scripts/skills/traits/huge_trait"
    ],
    [
        "trait.lucky",
        "scripts/skills/traits/lucky_trait"
    ]
];


::Log <- {full = [], last = null}
::logInfo <- function(s) {
    // ::Log.full.push(s);
    ::Log.last = s;
}

class WeakTableRef {}
