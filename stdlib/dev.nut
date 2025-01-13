local Util = ::std.Util;

::std.Dev <- {
    function getNearestLocation() {
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
    function showLocaltion(_id) {
        local locations = this.World.EntityManager.getLocations()
        foreach (location in locations) {
            if (location.getID() == _id) {
                this.World.uncoverFogOfWar(location.getTile().Pos, 200);
                location.setDiscovered(true);
                location.getSprite("selection").Visible = true;
                location.setVisibleInFogOfWar(true)
                // TODO: move camera
            }
        }
    }

    function getNearestTown() {
        local towns = ::World.EntityManager.getSettlements();
        local playerTile = ::World.State.getPlayer().getTile();
        local town, distance = 99999;
        foreach (i, t in towns) {
            local d = t.getTile().getDistanceTo(playerTile);
            if (d < distance) {distance = d; town = t}
        }
        return town
    }
    function rerollHires(_town = null) {
        if (_town == null) _town = this.getNearestTown();
        else if (typeof _town == "string") _town = ::getTown();

        ::logInfo("Rerolling hires in " + _town.getName());
        _town.resetRoster()
        _town.updateRoster()
    }

    function fixItems() {
        local function fixAll(items) {
            foreach (item in items) item.setCondition(item.getConditionMax());
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
}
