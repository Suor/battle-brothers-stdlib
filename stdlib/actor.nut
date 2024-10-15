local Util = ::std.Util

::std.Actor <- {
    function isAlive(_actor) {
        return !Util.isNull(_actor) && _actor.isAlive() && !_actor.isDying();
    }
    function isValidTarget(_actor) {
        // Not using "this." to make it passable to map/filter/whatever
        return ::std.Actor.isAlive(_actor) && _actor.isPlacedOnMap();
    }
}
