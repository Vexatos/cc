local list = {
    [2] = "one",
    [3] = "two",
    [4] = "three",
    [5] = "four",
    [6] = "five",
    [7] = "six",
    [8] = "seven",
    [9] = "eight",
    [10] = "nine",
    [11] = "zero",
    [12] = "minus",
    [13] = "equals",
    [14] = "backspace",
    [15] = "tab",
    [16] = "q",
    [17] = "w",
    [18] = "e",
    [19] = "r",
    [20] = "t",
    [21] = "y",
    [22] = "u",
    [23] = "i",
    [24] = "o",
    [25] = "p",
    [26] = "leftBracket",
    [27] = "rightBracket",
    [28] = "enter",
    [29] = "leftCtrl",
    [30] = "a",
    [31] = "s",
    [32] = "d",
    [33] = "f",
    [34] = "g",
    [35] = "h",
    [36] = "j",
    [37] = "k",
    [38] = "l",
    [39] = "semiColon",
    [40] = "apostrophe",
    [41] = "grave",
    [42] = "leftShift",
    [43] = "backslash",
    [44] = "z",
    [45] = "x",
    [46] = "c",
    [47] = "v",
    [48] = "b",
    [49] = "n",
    [50] = "m",
    [51] = "comma",
    [52] = "period",
    [53] = "slash",
    [54] = "rightShift",
    [55] = "multiply",
    [56] = "leftAlt",
    [57] = "space",
    [58] = "capsLock",
    [59] = "f1",
    [60] = "f2",
    [61] = "f3",
    [62] = "f4",
    [63] = "f5",
    [64] = "f6",
    [65] = "f7",
    [66] = "f8",
    [67] = "f9",
    [68] = "f10",
    [69] = "numLock",
    [70] = "scollLock",
    [71] = "numPad7",
    [72] = "numPad8",
    [73] = "numPad9",
    [74] = "numPadSubtract",
    [75] = "numPad4",
    [76] = "numPad5",
    [77] = "numPad6",
    [78] = "numPadAdd",
    [79] = "numPad1",
    [80] = "numPad2",
    [81] = "numPad3",
    [82] = "numPad0",
    [83] = "numPadDecimal",
    [87] = "f11",
    [88] = "f12",
    [100] = "f13",
    [101] = "f14",
    [102] = "f15",
    [112] = "kana",
    [121] = "convert",
    [123] = "noconvert",
    [125] = "yen",
    [141] = "numPadEquals",
    [144] = "cimcumflex",
    [145] = "at",
    [146] = "colon",
    [147] = "underscore",
    [148] = "kanji",
    [149] = "stop",
    [150] = "ax",
    [156] = "numPadEnter",
    [157] = "rightCtrl",
    [179] = "numPadComma",
    [181] = "numPadDivide",
    [184] = "rightAlt",
    [197] = "pause",
    [199] = "home",
    [200] = "up",
    [201] = "pageUp",
    [203] = "left",
    [205] = "right",
    [207] = "end",
    [208] = "down",
    [209] = "pageDown",
    [210] = "insert",
    [211] = "delete",											
}

local keys = {}
for k, v in pairs( list ) do
	keys[v] = k
end

keys["return"] = keys.enter

function keys.getName(n)
	return list[n]
end

return keys
