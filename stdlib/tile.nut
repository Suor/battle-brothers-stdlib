::std.Tile <- {
    function iterAdjacent(_tile) {
        for (local i = 0; i < ::Const.Direction.COUNT; i++) {
            if (_tile.hasNextTile(i)) yield _tile.getNextTile(i);
        }
    }
    function iterAdjacentActors(_tile) {
        foreach (tile in this.iterAdjacent(_tile)) {
            if (tile.IsOccupiedByActor) yield tile.getEntity();
        }
    }
}
