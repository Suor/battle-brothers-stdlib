::include <- function (script) {
    return dofile(script + ".nut", true)
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
}

::Log <- {full = [], last = null}
::logInfo <- function(s) {
    // ::Log.full.push(s);
    ::Log.last = s;
}

class WeakTableRef {}
