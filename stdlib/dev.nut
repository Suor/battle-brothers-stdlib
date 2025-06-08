local Array = ::std.Array, Util = ::std.Util;

::std.Dev <- {
    function getLocation() {
        local locations = World.EntityManager.getLocations();
        local playerTile = this.World.State.getPlayer().getTile();
        local distance = 99999;
        ::loc <- null
        foreach (i, l in locations) {
            local d = l.getTile().getDistanceTo(playerTile);
            if (d < distance) {distance = d; ::loc = l}
        }
        return loc;
    }
    function showLocation(_typeId) {
        local locations = this.World.EntityManager.getLocations()
        foreach (location in locations) {
            if (location.getTypeID() == _typeId) {
                this.World.uncoverFogOfWar(location.getTile().Pos, 200);
                location.setDiscovered(true);
                location.getSprite("selection").Visible = true;
                location.setVisibleInFogOfWar(true)
                // TODO: move camera
            }
        }
    }

    function getTown(_name = null) {
        local towns = ::World.EntityManager.getSettlements();
        if (_name != null) {
            foreach(t in towns) if (t.getName() == _name) return t;
        }

        local playerTile = ::World.State.getPlayer().getTile();
        return Array.min(towns, @(t) t.getTile().getDistanceTo(playerTile));
    }
    function rerollHires(_town = null) {
        if (_town == null) _town = this.getTown();
        else if (typeof _town == "string") _town = ::getTown(_town);

        ::logInfo("Rerolling hires in " + _town.getName());
        _town.resetRoster()
        _town.updateRoster()
    }

    function fixItems() {
        this.breakItems(null);
    }
    function breakItems(_pct) {
        local function fixAll(items) {
            foreach (item in items) {
                local max = item.getConditionMax();
                item.setCondition(_pct == null ? max : (max * _pct).tointeger());
            }
        }
        foreach (bro in World.getPlayerRoster().getAll()) fixAll(bro.getItems().getAllItems())
        fixAll(Stash.getItems())
    }

    function restoreRelations() {
        local nobles = ::World.FactionManager.getFactionsOfType(::Const.FactionType.NobleHouse);
        foreach (noble in nobles) {
            local rel = noble.getPlayerRelation(), up = 50 - rel;
            if (up <= 0) continue;

            noble.addPlayerRelation(up, "You are getting better");
            foreach (s in noble.m.Settlements) {
                if (s.getFaction() != noble.m.ID) {
                    ::World.FactionManager.getFaction(s.getFaction()).addPlayerRelationEx(up * 0.5);
                }
            }
            break;
        }
    }

    // Combat
    function getEnemies(_name) {
        local ops = getBro().getAIAgent().getKnownOpponents();
        return ops.map(@(r) r.Actor).filter(@(_, a) a.getName() == _name);
    }
    function fixCombat() {
        ::Tactical.TurnSequenceBar.m.IsLocked = false;
        ::Tactical.TurnSequenceBar.initNextTurn(true);
    }
    function fixCombatEnd() {
        ::Tactical.State.m.TacticalCombatResultScreen.show();
    }
}
::std.Dev.getNearestTown <- ::std.Dev.getTown;
::std.Dev.getNearestLocation <- ::std.Dev.getLocation;
