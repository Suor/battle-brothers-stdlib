local Util = ::std.Util, Rand = ::std.Rand.using(::std.rng);

::std.Player <- {
    Debug = false

    function giveLevels(_player, _num) {
        for (local i = 0; i < _num; i++) {
            local nextlevelXP = _player.getXPForNextLevel() - _player.m.XP;
            _player.m.XP += nextlevelXP;
            _player.m.CombatStats.XPGained += nextlevelXP;
            _player.updateLevel();
        }
        if (_num > 0) _player.getSkills().update();
    }

    // Attributes
    // Average values taken from character_background.buildAttributes(),
    // will use them to determine how much a change from onChangeAttributes() means.
    // Q: should I use level 11 expected instead? Then might not need special treatment for defense.
    AttributeBase = [55.0, 35.0, 95.0, 105, 52.0, 37.0, 2.5, 2.5]

    function rerollTalents(_player, _num, _opts = null) {
        this.clearTalents(_player);
        this.addTalents(_player, _num, _opts);
    }

    function clearTalents(_player) {
        _player.m.Talents = array(::Const.Attributes.COUNT, 0);
    }

    function addTalents(_player, _num, _opts = null) {
        _opts = Util.extend({
            weighted = false
            excluded = "relaxed"
            probs = [60 30 10] // Game default
        }, _opts || {})
        if (["strict" "relaxed" "ignored"].find(_opts.excluded) == null)
            throw "Use excluded = \"strict\", \"relaxed\" or \"ignored\", not " + _opts.excluded;

        local bg = _player.getBackground();
        if (this.Debug)
            ::logInfo("stdlib: addTalents " + _player.getName()
                + ", bg: " + (bg ? bg.getNameOnly() : "null"));

        local weights = _opts.weighted && bg ? this.calcAttributeWeights(bg)
                                             : array(::Const.Attributes.COUNT, 1);
        if (this.Debug) this.Debug.log("weights", weights);

        // Split excluded
        local indexes = [], iWeights = [], excluded = [], eWeights = [];
        local excludedTalents = bg && _opts.excluded != "ignored" ? bg.getExcludedTalents() : null;
        foreach (i, w in weights) {
            if (_player.m.Talents[i] > 0) continue; // Only adding new ones
            if (!excludedTalents || excludedTalents.find(i) == null) {
                indexes.push(i); iWeights.push(w);
            } else {
                excluded.push(i); eWeights.push(w);
            }
        }

        // Choose talents
        local chosen = Rand.take(_num, indexes, iWeights);
        if (_opts.excluded != "strict" && chosen.len() < _num) {
            chosen.extend(Rand.take(_num - chosen.len(), excluded, eWeights))
        }

        // Roll ralent stars
        local probsStr = array(8, "-");
        foreach (i in chosen) {
            local w = weights[i];
            local probs = clone _opts.probs;
            probs[2] *= w;           // 3 stars
            probs[1] *= (w + 1) / 2; // 2 stars
            _player.m.Talents[i] = Rand.choice([1 2 3], probs);
            if (this.Debug) {
                local psum = probs[0] + probs[1] + probs[2];
                probsStr[i] = Str.join(".", probs.map(@(p) ::Math.round(p * 100 / psum)));
            }
        }
        if (this.Debug) this.Debug.log("talents probs", Str.join(" ", probsStr));
        if (this.Debug) this.Debug.log("talents after", _player.m.Talents);
    }

    function calcAttributeWeights(_bg) {
        local weights = clone this.AttributeBase;
        foreach (k, v in _bg.onChangeAttributes()) {
            local i = ::Const.Attributes[k == "Stamina" ? "Fatigue" : k];
            local isDefense = k == "MeleeDefense" || k == "RangedDefense";
            local min = isDefense ? 0.8 : 0.5,
                  max = isDefense ? 1.5 : 3.0,
                  exp = i == 1 || i == 5 ? 3 : 4;
            weights[i] = Util.clamp(pow((v[0] + v[1]) * 0.5 / weights[i] + 1, exp), min, max);
        }

        // Make defense talents scale up slightly with attack talents
        for (local i = 6; i < 8; i++) {
            local attack = weights[i-2];
            if (attack > 1 && weights[i] > 0.001)
                weights[i] = ::Math.minf(2.0, weights[i] + ::Math.minf(0.5, attack * 0.5 - 0.5));
        }
        // only add one row at a time, do nothing if we are in non-veteran levels
        return weights;
    }

    // Traits
    BadTraitIds = [
        "trait.ailing"
        "trait.asthmatic"
        "trait.bleeder"
        "trait.clubfooted"
        "trait.clumsy"
        "trait.cocky"
        "trait.craven"
        "trait.dastard"
        "trait.disloyal"
        "trait.dumb"
        "trait.fainthearted"
        "trait.fear_beasts"
        "trait.fear_greenskins"
        "trait.fear_undead"
        "trait.fragile"
        "trait.gluttonous"
        "trait.greedy"
        "trait.hesitant"
        "trait.insecure"
        "trait.irrational"
        "trait.night_blind"
        "trait.pessimist"
        "trait.short_sighted"
        "trait.superstitious"
        // Legends
        "trait.legend_fear_nobles"
        "trait.legend_frail"
        "trait.legend_appetite_donkey"
        "trait.legend_fear_dark"
        "trait.legend_predictable"
        "trait.legend_slack"
        // Legends 18-
        "trait.fear_nobles"
        "trait.frail"
        "trait.predictable"
        "trait.slack"
    ]
    SosoTraitIds = [
        "trait.drunkard"
        "trait.fat"
        "trait.impatient"
        "trait.huge"
        "trait.tiny"
        "trait.paranoid"
        "trait.brute"
        // Legends
        "trait.legend_aggressive"
        "trait.legend_diurnal"
        "trait.legend_light"
        "trait.legend_double_tongued"
        // Legends 18-
        "trait.aggressive"
        "trait.light"
        "trait.double_tongued"
    ]
    function traitType(traitId) {
        if (this.SosoTraitIds.find(traitId) != null) return "SOSO";
        if (this.BadTraitIds.find(traitId) != null) return "BAD";
        return "GOOD";
    }
    function addTraits(_player, _num, _opts = null) {
        if (_num == 0) return [];

        _opts = Util.extend({
            good = true
            bad = true
            soso = true
            stupid = false
        }, _opts || {})

        local self = this;
        local pool = ::Const.CharacterTraits.filter(function (_, t) {
            if (!_opts.bad && self.BadTraitIds.find(t[0]) != null) return false;
            if (!_opts.soso && self.SosoTraitIds.find(t[0]) != null) return false;
            return !_player.getSkills().hasSkill(t[0]);
        });

        local added = 0, good = 0, notGood = 0, changes = [];
        foreach (trait in Rand.itake(pool)) {
            if (this.Debug) {
                local type = this.traitType(trait[0]);
                ::logInfo("stdlib: bro " + _player.getName() + " got " + trait[0] + " " + type);
            }
            local skill = ::new(trait[1]);
            _player.getSkills().add(skill);
            added++;
            changes.push(skill);
            // In stupid mode each bad or so-so trait must be compensated with a good one
            if (_opts.stupid) (this.traitType(trait[0]) == "GOOD") ? good++ : notGood++;
            if (added >= _num && (!_opts.stupid || good >= notGood && good >= _num)) break;
        }
        return changes;
    }

    function removePermanentInjury(_player, _id = null) {
        local injury;
        if (_id) injury = _player.getSkills().getSkillByID(_id);
        else {
            local injuries = _player.getSkills().query(::Const.SkillType.PermanentInjury);
            if (injuries.len() == 0) return;
            injury = Rand.choice(injuries).get(); // .query() returns weakrefs
        }
        if (!injury) return;

        _player.getSkills().remove(injury);

        _player.getSprite("permanent_injury_1").Visible = false;
        _player.getSprite("permanent_injury_2").Visible = false;
        _player.getSprite("permanent_injury_3").Visible = false;
        _player.getSprite("permanent_injury_4").Visible = false;
        _player.getSprite("permanent_injury_1").resetBrush();
        _player.getSprite("permanent_injury_2").resetBrush();
        _player.getSprite("permanent_injury_3").resetBrush();
        _player.getSprite("permanent_injury_4").resetBrush();
        _player.updateInjuryVisuals()

        return injury;
    }
}
