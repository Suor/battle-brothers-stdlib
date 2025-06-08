::std.Tile <- {
    function iterAdjacent(_tile) {
        for (local i = 0; i < ::Const.Direction.COUNT; i++) {
            if (_tile.hasNextTile(i)) yield _tile.getNextTile(i);
        }
    }
    // Repeating code for performance reasons
    function listAdjacent(_tile) {
        local res = [];
        for (local i = 0; i < ::Const.Direction.COUNT; i++) {
            if (_tile.hasNextTile(i)) res.push(_tile.getNextTile(i));
        }
        return res;
    }
    function iterAdjacentActors(_tile) {
        foreach (tile in this.iterAdjacent(_tile)) {
            if (tile.IsOccupiedByActor) yield tile.getEntity();
        }
    }
    function listAdjacentActors(_tile) {
        local res = [];
        foreach (tile in this.iterAdjacent(_tile)) {
            if (tile.IsOccupiedByActor) res.push(tile.getEntity());
        }
        return res;
    }
}
