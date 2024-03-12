## WARNING: POLLUTION. Custom region fold/unfold pollutes the undo/redo space

@tool
extends Object
class_name Settings


const COMMENT_BG_COLOR_UPDATE_COOLDOWN:float = 0.3

const MAX_COMMENT_BG_COLOR_LINE_COUNT = 30

const GREEN    = Color(0, 1 ,0, 0.04)
const DARK     = Color(0, 0, 0, 0.24)
const MIST     = Color(0, 0, 0, 0.125)
const TEAL     = Color(0, 1, 1, 0.06)
const INDIGO   = Color(0.5, 0.5, 1, 0.08)
const DEEPPINK = Color(1, 0.3, 0.6, 0.1)
const BLUE     = Color(0, 0.3, 0.9, 0.07)
const YELLOW   = Color(1, 1, 0.2, 0.07)
const RICE     = Color(1, 1, 0.8, 0.15)
const NAVY_BLUE = Color(0, 0, 0.5, 0.25) # TODO for folded lines?

#1#
const PLACEHOLDER_COLOR = DARK

## set in-line color code for each color
const PALETTE: Dictionary = {
	#1g#
	"g": GREEN,
	#1y#
	"y": YELLOW,
	#1t#
	"t": TEAL,
	#1i#
	"i": INDIGO,
	#1d#
	"d": DARK,
	#1m#
	"m": MIST,
	#1p#
	"p": DEEPPINK,
	#1b#
	"b": BLUE,
	#1r#
	"r": RICE
}
