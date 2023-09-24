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
