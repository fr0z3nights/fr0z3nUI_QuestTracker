local addonName, ns = ...

-- Expansion DB12 (Midnight)

ns.rules = ns.rules or {}

local EXPANSION_ID = 12
local EXPANSION_NAME = "Midnight"

local Y, N = true, false


local WHITE = "ffffff"
local RED = "ff4040"
local ORANGE = "ff8c1a"
local YELLOW = "ffe633"
local GREEN = "33ff33"
local BLUE = "3399ff"
local PURPLE = "9933ff"
local CYAN = "33ffff"
local GREY = "bfbfbf"

-- Currency gates (optional):
--   item.currencyID = { currencyID, required }
-- Amount sources (Retail):
--   Character amount: C_CurrencyInfo.GetCurrencyInfo(id).quantity
--   Warband total: C_CurrencyInfo.GetAccountCharacterCurrencyData(id)
--     (requires RequestCurrencyDataForAccountCharacters() to be called earlier)
--   Transferability: C_CurrencyInfo.GetCurrencyInfo(id).isAccountTransferable
-- Notes:
--   If isAccountTransferable is true, the tracker gates using the warband total (falls back to a cached
--   account saved-variable snapshot if the live data isn't available yet).
-- Placeholders usable in itemInfo/textInfo/spellInfo:
--   {currency:name} {currency:req} {currency:char} {currency:wb} {currency} (gate amount)
-- Shorthand (DB convenience):
--   %p  -> {progress}
--   $rq -> {currency:req}
--   $nm -> {currency:name}
--   $hv -> {currency} (gate/have amount)
--   $ga -> {currency} (gate/have amount)
--   $cc -> {currency:char}
--   $wb -> {currency:wb}


-- item.required tuple keys:
--   item.required = { count, hideWhenAcquired, autoBuyEnabled, autoBuyMax }
local REQ_COUNT, REQ_HIDE, REQ_BUY_ON, REQ_BUY_MAX = 1, 2, 3, 4
local bakedRules = {

	{key = "XP12:94386",	questID = 94386,	requireInLog = false,	playerLevel = {">=",80,},	label = "Void Assault",		frameID = "bar1",	progress = { merge = { { questID = 94386, objectiveIndex = 1 }, { questID = 94385, objectiveIndex = 1 }, }, sep = " | ", requireAll = false, }, questInfo = "Void Assault", hideQID = {94386,94385,},},

	{key = "XP12:Q93010",	questID = 93012,	requireInLog = false, 	playerLevel = { "=",90,},	label = "Soridormi Skips",	frameID = "list2",	hideDone = true, progress = { objectiveIndex = 0 }, mapID = {2393},	size = 22, color = "ffe633", align = "center", },
--	Delvers Call Quests                                                                                        										-- mapIDs: fUI_QTUsage.lua
	{key = "XP12:Q97454",	questID = 97454,	requireInLog = false,	playerLevel = {">=",80,},	label = "DQ S2",			frameID = "bar1",	hideDone = true, progress = { objectiveIndex = 0 }, mapID = {2393}, },
	{key = "XP12:Q93372",	questID = 93372,	requireInLog = true,	playerLevel = {">=",80,}, 	label = "DQ Silvermoon",	frameID = "bar1",	hideDone = true, progress = { objectiveIndex = 0 }, },
	{key = "XP12:Q93384",	questID = 93384,	requireInLog = true,	playerLevel = {">=",80,}, 	label = "DQ Silvermoon",	frameID = "bar1",	hideDone = true, progress = { objectiveIndex = 0 }, },
	{key = "XP12:Q93385",	questID = 93385,	requireInLog = true,	playerLevel = {">=",80,}, 	label = "DQ Silvermoon",	frameID = "bar1",	hideDone = true, progress = { objectiveIndex = 0 }, },
	{key = "XP12:Q93386",	questID = 93386,	requireInLog = true,	playerLevel = {">=",80,}, 	label = "DQ Silvermoon",	frameID = "bar1",	hideDone = true, progress = { objectiveIndex = 0 }, },
	{key = "XP12:Q93409",	questID = 93409,	requireInLog = true,	playerLevel = {">=",80,}, 	label = "DQ Zul'Aman",		frameID = "bar1",	hideDone = true, progress = { objectiveIndex = 0 }, },
	{key = "XP12:Q93410",	questID = 93410,	requireInLog = true,	playerLevel = {">=",80,}, 	label = "DQ Zul'Aman",		frameID = "bar1",	hideDone = true, progress = { objectiveIndex = 0 }, },
	{key = "XP12:Q93421",	questID = 93421,	requireInLog = true,	playerLevel = {">=",80,}, 	label = "DQ Harandar",		frameID = "bar1",	hideDone = true, progress = { objectiveIndex = 0 }, },
	{key = "XP12:Q93428",	questID = 93428,	requireInLog = true,	playerLevel = {">=",80,}, 	label = "DQ Voidstorm",		frameID = "bar1",	hideDone = true, progress = { objectiveIndex = 0 }, },
--	Shows if item is in the player's inventory
	{key = "XP12:I273000",  item = { itemID = 273000, mustHave = true, showCount = false, },		label = "XC Undercoin",		frameID = "list2",	resting = true, itemInfo = "Corrosive Soul in Bags\n + Deposit in Warbank\n  - Altar of Corrosion (8)\n  - Don't Exchange for Undercoins" },
	{key = "XP12:I255826",  item = { itemID = 255826, mustHave = true, showCount = false, },		label = "XC Undercoin",		frameID = "list2",	resting = true, itemInfo = "Mysterious Skyshards in Bags\n + Deposit in Warbank\n  - Mount? (500)" },




--{label = "Cultist", frameID = "bar1", key = "12pxp:cultist:rare",
--questID = 91795, requireInLog = false, hideDone = false, showXWhenComplete = true,
--questInfo = "Cultist %p", playerLevel = { ">=", 20, },
--progress = { merge = { { questID = 91795, objectiveIndex = 1 }, { questID = 87308, objectiveIndex = 1 }, }, sep = " | ", requireAll = true, },
--complete = { all = { { questID = 91795 }, { questID = 87308 }, }, }, completeMode = "replace",},



}


for i = 1, #bakedRules do
  local r = bakedRules[i]
  if type(r) == "table" then
    ns.GuideHelpers.NormalizeRule(r, EXPANSION_ID, EXPANSION_NAME)
    ns.rules[#ns.rules + 1] = r
  end
end
