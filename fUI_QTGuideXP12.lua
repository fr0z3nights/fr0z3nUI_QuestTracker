local addonName, ns = ...

-- Expansion DB12 (Midnight)

ns.rules = ns.rules or {}

local EXPANSION_ID = 12
local EXPANSION_NAME = "Midnight"

local Y, N = true, false
local M = "mustHave"


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
local LIADRIN_QUEST_IDS = {93909, 95842, 93910, 96727, 95843, 93892, 93889, 98232, 93766, 93769, 93912, 93767, 93890, 93913, 94457, 93911}
local bakedRules = {

	{key = "XP12:94386",	questID = 94386,	requireInLog = false,	playerLevel = {">=",80,},	label = "Void Assault",		frameID = "bar1",	progress = { merge = { { questID = 94386, objectiveIndex = 1 }, { questID = 94385, objectiveIndex = 1 }, }, sep = " | ", requireAll = false, }, questInfo = "Void Assault", hideQID = {94386,94385,},},

	{key = "XP12:Q93010",	questID = 93012,	requireInLog = false, 	playerLevel = { "=",90,},	label = "Soridormi Skips",	frameID = "list2",	hideDone = true, progress = { objectiveIndex = 0 }, mapID = {2393},	size = 22, color = "ffe633", align = "center", },
--	Delve Quests                                                                                        										-- mapIDs: fUI_QTUsage.lua
	{key = "XP12:Q97454",	questID = 97454,	requireInLog = false,	playerLevel = {">=",80,},	label = "DQ S2",				frameID = "bar1",	hideDone = true,	progress = { objectiveIndex = 0 }, mapID = {2393}, },
	{key = "XP12:Q93372",	questID = 93372,	requireInLog = true,	playerLevel = {">=",80,}, 	label = "DQ Silvermoon",		frameID = "bar1",	hideDone = true,	progress = { objectiveIndex = 0 }, },
	{key = "XP12:Q93384",	questID = 93384,	requireInLog = true,	playerLevel = {">=",80,}, 	label = "DQ Silvermoon",		frameID = "bar1",	hideDone = true,	progress = { objectiveIndex = 0 }, },
	{key = "XP12:Q93385",	questID = 93385,	requireInLog = true,	playerLevel = {">=",80,}, 	label = "DQ Silvermoon",		frameID = "bar1",	hideDone = true,	progress = { objectiveIndex = 0 }, },
	{key = "XP12:Q93386",	questID = 93386,	requireInLog = true,	playerLevel = {">=",80,}, 	label = "DQ Silvermoon",		frameID = "bar1",	hideDone = true,	progress = { objectiveIndex = 0 }, },
	{key = "XP12:Q93784",	questID = 93784,	requireInLog = true,	playerLevel = {">=",80,}, 	label = "DQ Silvermoon",		frameID = "bar1",	hideDone = true,	progress = { objectiveIndex = 0 }, },
	{key = "XP12:Q93409",	questID = 93409,	requireInLog = true,	playerLevel = {">=",80,}, 	label = "DQ Zul'Aman",			frameID = "bar1",	hideDone = true,	progress = { objectiveIndex = 0 }, },
	{key = "XP12:Q93410",	questID = 93410,	requireInLog = true,	playerLevel = {">=",80,}, 	label = "DQ Zul'Aman",			frameID = "bar1",	hideDone = true,	progress = { objectiveIndex = 0 }, },
	{key = "XP12:Q93416",	questID = 93416,	requireInLog = true,	playerLevel = {">=",80,}, 	label = "DQ Harandar",			frameID = "bar1",	hideDone = true,	progress = { objectiveIndex = 0 }, },
	{key = "XP12:Q93421",	questID = 93421,	requireInLog = true,	playerLevel = {">=",80,}, 	label = "DQ Harandar",			frameID = "bar1",	hideDone = true,	progress = { objectiveIndex = 0 }, },
	{key = "XP12:Q93427",	questID = 93427,	requireInLog = true,	playerLevel = {">=",80,}, 	label = "DQ Voidstorm",			frameID = "bar1",	hideDone = true,	progress = { objectiveIndex = 0 }, },
	{key = "XP12:Q93428",	questID = 93428,	requireInLog = true,	playerLevel = {">=",80,}, 	label = "DQ Voidstorm",			frameID = "bar1",	hideDone = true,	progress = { objectiveIndex = 0 }, },
--	Lady Liadrin Quests
	{questGroup = { questIDs = {93909, 95842, 93910, 96727, 95843, 93892, 93889, 98232, 93766, 93769, 93912, 93767, 93890, 93913, 94457, 93911},
	status = {key = "XP12:Liadrin", questID = 93909, requireInLog = false, playerLevel = {"=",90,}, label = "Liadrin Quest Missing",frameID = "list2",	hideDone = true,	labelComplete = "Liadrin Done",	 size = 18, color = "ffe633", align = "center", list = "top"},
	children = {
	{key = "XP12:Q93909",	questID = 93909,	requireInLog = true,	playerLevel = {"=",90,},	label = "Liadrin Delves",		frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1}, size = 18, color = "ffe633", align = "center", list = "top"},
	{key = "XP12:Q95842",	questID = 95842,	requireInLog = true,	playerLevel = {"=",90,},	label = "Liadrin Void Assault",	frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1}, size = 18, color = "ffe633", align = "center", list = "top"},
	{key = "XP12:Q93910",	questID = 93910,	requireInLog = true,	playerLevel = {"=",90,},	label = "Liadrin Prey",			frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1}, size = 18, color = "ffe633", align = "center", list = "top"},
	{key = "XP12:Q96727",	questID = 96727,	requireInLog = true,	playerLevel = {"=",90,},	label = "Liadrin Offworld",		frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1}, size = 18, color = "ffe633", align = "center", list = "top"},
	{key = "XP12:Q95843",	questID = 95843,	requireInLog = true,	playerLevel = {"=",90,},	label = "Liadrin Ritual Sites",	frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1}, size = 18, color = "ffe633", align = "center", list = "top"},
	{key = "XP12:Q93892",	questID = 93892,	requireInLog = true,	playerLevel = {"=",90,},	label = "Liadrin Stormarion",	frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1}, size = 18, color = "ffe633", align = "center", list = "top"},
	{key = "XP12:Q93889",	questID = 93889,	requireInLog = true,	playerLevel = {"=",90,},	label = "Liadrin Slthri Soire",	frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1}, size = 18, color = "ffe633", align = "center", list = "top"},
	{key = "XP12:Q98232",	questID = 98232,	requireInLog = true,	playerLevel = {"=",90,},	label = "Liadrin Atal'Utek",	frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1}, size = 18, color = "ffe633", align = "center", list = "top"},
	{key = "XP12:Q93766",	questID = 93766,	requireInLog = true,	playerLevel = {"=",90,},	label = "Liadrin World Quests",	frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1}, size = 18, color = "ffe633", align = "center", list = "top"},
	{key = "XP12:Q93769",	questID = 93769,	requireInLog = true,	playerLevel = {"=",90,},	label = "Liadrin Housing",		frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1}, size = 18, color = "ffe633", align = "center", list = "top"},
	{key = "XP12:Q93912",	questID = 93912,	requireInLog = true,	playerLevel = {"=",90,},	label = "Liadrin Raid",			frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1}, size = 18, color = "ffe633", align = "center", list = "top"},
	{key = "XP12:Q93767",	questID = 93767,	requireInLog = true,	playerLevel = {"=",90,},	label = "Liadrin Arcantina",	frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1}, size = 18, color = "ffe633", align = "center", list = "top"},
	{key = "XP12:Q93890",	questID = 93890,	requireInLog = true,	playerLevel = {"=",90,},	label = "Liadrin Abundance",	frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1}, size = 18, color = "ffe633", align = "center", list = "top"},
	{key = "XP12:Q93913",	questID = 93913,	requireInLog = true,	playerLevel = {"=",90,},	label = "Liadrin World Boss",	frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1}, size = 18, color = "ffe633", align = "center", list = "top"},
	{key = "XP12:Q94457",	questID = 94457,	requireInLog = true,	playerLevel = {"=",90,},	label = "Liadrin Battleground",	frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1}, size = 18, color = "ffe633", align = "center", list = "top"},
	{key = "XP12:Q93911",	questID = 93911,	requireInLog = true,	playerLevel = {"=",90,},	label = "Liadrin Dungeons",		frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1}, size = 18, color = "ffe633", align = "center", list = "top"}, }, } },
	{key = "XP12:Q98172",	questID = 98172,	requireInLog = true,	playerLevel = {"=",90,}, 	label = "Xal'atath's Trail",	frameID = "list2",	hideDone = true,	progress = {objectiveIndex = 1}, size = 18, color = "ffe633", align = "center", list = "top"},
--	Shows if item is in the player's inventory
	{key = "XP12:I273000",  item = { itemID = 273000, mustHave = true, showCount = false, },		label = "XC Undercoin",		frameID = "list2",	resting = true, itemInfo = "Corrosive Soul in Bags\n + Deposit in Warbank\n  - Altar of Corrosion (8)\n  - Don't Exchange for Undercoins" },
	{key = "XP12:I255826",  item = { itemID = 255826, mustHave = true, showCount = false, },		label = "XC Undercoin",		frameID = "list2",	resting = true, itemInfo = "Mysterious Skyshards in Bags\n + Deposit in Warbank\n  - Mount? (500)" },


--complete = { all = { { questID = 91795 }, { questID = 87308 }, }, }, completeMode = "replace",},



}


bakedRules = ns.GuideHelpers.ExpandQuestGroups(bakedRules)
for i = 1, #bakedRules do
  local r = bakedRules[i]
  if type(r) == "table" and not r.questGroup then
    ns.GuideHelpers.NormalizeRule(r, EXPANSION_ID, EXPANSION_NAME)
    ns.rules[#ns.rules + 1] = r
  end
end
