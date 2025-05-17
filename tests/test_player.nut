local Player = ::std.Player;
local rng = ::std.rng

local player = {
    m = {
        Level = 1
        LevelUps = 1
        Attributes = []
        Talents = [0 2 0 2 0 3 0 0]
        Skills = {
            Skills = []
            function hasSkill(id) {return false}
            function add(item) {
                this.Skills.push(item)
            }
        }
    }
    function getName() {
        return "Hackflow"
    }
    function getSkills() {return this.m.Skills}
    function fillAttributeLevelUpValues(_amount, _maxOnly = false, _minOnly = false) {
        if (this.m.Attributes.len() == 0)
        {
            this.m.Attributes.resize(this.Const.Attributes.COUNT);

            for( local i = 0; i != this.Const.Attributes.COUNT; i = ++i )
            {
                this.m.Attributes[i] = [];
            }
        }

        for( local i = 0; i != this.Const.Attributes.COUNT; i = ++i )
        {
            for( local j = 0; j < _amount; j = ++j )
            {
                if (_minOnly)
                {
                    this.m.Attributes[i].insert(0, 1);
                }
                else if (_maxOnly)
                {
                    this.m.Attributes[i].insert(0, 3);
                }
                else
                {
                    this.m.Attributes[i].insert(0, 2);
                }
            }
        }
    }
    function getBackground() {
        return {
            function getNameOnly() {
                return "Hackflow"
            }
            function onChangeAttributes() {
                return {
                    Hitpoints = [-7, -7]
                    Bravery = [-7, -7]
                    Stamina = [0, 0]
                    Initiative = [15, 20]
                    MeleeSkill = [15, 18]
                    RangedSkill = [10, 10]
                    MeleeDefense = [0, 3]
                    RangedDefense = [10, 10]
                }
            }
            function getExcludedTalents() {
                return [
                    ::Const.Attributes.Initiative,
                    ::Const.Attributes.RangedSkill,
                    ::Const.Attributes.RangedDefense
                ]
            }
            function isUntalented() {return false}
        }
    }
}


// Talents
rng.reset(9);
Player.addTalents(player, 1);
assertEq(player.m.Talents, [0 2 0 2 0 3 1 0])

rng.reset(9);
Player.rerollTalents(player, 6, {excluded = "strict"});
assertEq(player.m.Talents, [2 2 1 0 1 0 3 0])

rng.reset(9);
Player.rerollTalents(player, 6, {excluded = "relaxed"});
assertEq(player.m.Talents, [1 1 2 0 1 0 2 1])

rng.reset(9);
Player.rerollTalents(player, 6, {excluded = "ignored"});
assertEq(player.m.Talents, [0 0 1 1 2 1 2 1])

rng.reset(9);
Player.rerollTalents(player, 6, {weighted = true, excluded = "strict"});
assertEq(player.m.Talents, [2 1 2 0 1 0 3 0])

rng.reset(9);
Player.rerollTalents(player, 6, {weighted = true, excluded = "relaxed"});
assertEq(player.m.Talents, [1 2 1 0 1 0 3 1])

rng.reset(9);
Player.rerollTalents(player, 6, {weighted = true, excluded = "ignored"});
assertEq(player.m.Talents, [0 0 1 1 1 1 2 3])
print("Player: talents OK\n");


// Traits
local function assertSkillsNum(num) {
    assertEq(player.getSkills().Skills.len(), num);
    player.getSkills().Skills = [];
}

Player.addTraits(player, 0)
assertSkillsNum(0)

rng.reset(6);
Player.addTraits(player, 1)
assertSkillsNum(1)

rng.reset(77);
Player.addTraits(player, 3)
assertSkillsNum(3)

// Stupid mode
rng.reset(97);
Player.addTraits(player, 1, {bad = false, stupid = true})
assertSkillsNum(4)
print("Player: traits OK\n");
