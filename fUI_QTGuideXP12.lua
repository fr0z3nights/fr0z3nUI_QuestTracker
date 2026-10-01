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

local GI1 = ns.GuideHelpers.GOLD_ICON

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


	{key = "XP12:Q93010",	questID = 93012,	requireInLog = false, 	playerLevel = { "=",90,},	label = "Soridormi Skip(s)",		frameID = "list2",	hideDone = true, 	progress = {objectiveIndex = 0},																font = "lsm:Bazooka", size = 22, color = "ffe633", align = "center", list = "top", mapID = {2393}, },
--	Void Assaults
	{key = "XP12:C-3310",	showIf = { questInLogIDs = {94385,94386,} },							label = "Coffer Key Shards",        frameID = "list2",	hideDone = true, 	currencyID = { 3310, 1000, Y },							textInfo  = "$hv / 100 = 1 Key", 		font = "lsm:Bazooka", size = 16, color = "ffe633", align = "center", list = "top", pad = -4, },
	{questGroup = { questIDs = {94385,94386,},	status =
	{key = "XP12:Q-94385G",	questID = 94385,	requireInLog = false,	playerLevel = { "=",90},	label = "Void Assault Missing",		frameID = "list2",	hideDone = true,															labelComplete = "VAssault Done", 		font = "lsm:Bazooka", size = 16, color = "ffe633", align = "center", list = "top", pad =  4, }, children = {
	{key = "XP12:Q-94385",	questID = 94385,	requireInLog = true,	playerLevel = { "=",90}, 	label = "Eversong Assault",			frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1}, 																font = "lsm:Bazooka", size = 16, color = "ffe633", align = "center", list = "top", pad =  4, },
	{key = "XP12:Q-94386",	questID = 94386,	requireInLog = true,	playerLevel = { "=",90}, 	label = "Zul'Aman Assault",			frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},																font = "lsm:Bazooka", size = 16, color = "ffe633", align = "center", list = "top", pad =  4, }, }, } },
--	Tent Outside Bank
	--	Evergreen Weekly



	--	Lady Liadrin Fortnightly Quest(s)
	{questGroup = { questIDs = {93909,95842,93910,96727,95843,93892,93889,98232,93766,93769,93912,93767,93890,93913,94457,93911,},		status =
	{key = "XP12:QG93909",	questID = 93909, 	requireInLog = false, 	playerLevel = { "=",90}, 	label = "Liadrin Missing",			frameID = "list2",	hideDone = true,	labelComplete = "Liadrin Done",							questInfo = "Liadrin Missing",			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, }, children = {
	{key = "XP12:Q-93909",	questID = 93909,	requireInLog = true,	playerLevel = { "=",90},	label = "Liadrin Delves",			frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},						questInfo = "Liadrin Delves",			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, },
	{key = "XP12:Q-95842",	questID = 95842,	requireInLog = true,	playerLevel = { "=",90},	label = "Liadrin Void Assault",		frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},						questInfo = "Liadrin VoidAssault",		font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, },
	{key = "XP12:Q-93910",	questID = 93910,	requireInLog = true,	playerLevel = { "=",90},	label = "Liadrin Prey",				frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},						questInfo = "Liadrin Prey",				font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, },
	{key = "XP12:Q-96727",	questID = 96727,	requireInLog = true,	playerLevel = { "=",90},	label = "Liadrin Offworld",			frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},						questInfo = "Liadrin Offworld",			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, },
	{key = "XP12:Q-95843",	questID = 95843,	requireInLog = true,	playerLevel = { "=",90},	label = "Liadrin Ritual Site",		frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},						questInfo = "Liadrin Ritual Site",		font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, },
	{key = "XP12:Q-93892",	questID = 93892,	requireInLog = true,	playerLevel = { "=",90},	label = "Liadrin Stormarion",		frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},						questInfo = "Liadrin Stormarion",		font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, },
	{key = "XP12:Q-93889",	questID = 93889,	requireInLog = true,	playerLevel = { "=",90},	label = "Liadrin Slthri Soire",		frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},						questInfo = "Liadrin Slthri Soire",		font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, },
	{key = "XP12:Q-98232",	questID = 98232,	requireInLog = true,	playerLevel = { "=",90},	label = "Liadrin Atal'Utek",		frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},						questInfo = "Liadrin Atal'Utek",		font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, },
	{key = "XP12:Q-93766",	questID = 93766,	requireInLog = true,	playerLevel = { "=",90},	label = "Liadrin World Quest",		frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},						questInfo = "Liadrin World Quest",		font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, },
	{key = "XP12:Q-93769",	questID = 93769,	requireInLog = true,	playerLevel = { "=",90},	label = "Liadrin Housing",			frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},						questInfo = "Liadrin Housing",			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, },
	{key = "XP12:Q-93912",	questID = 93912,	requireInLog = true,	playerLevel = { "=",90},	label = "Liadrin Raid",				frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},						questInfo = "Liadrin Raid",				font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, },
	{key = "XP12:Q-93767",	questID = 93767,	requireInLog = true,	playerLevel = { "=",90},	label = "Liadrin Arcantina",		frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},						questInfo = "Liadrin Arcantina",		font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, },
	{key = "XP12:Q-93890",	questID = 93890,	requireInLog = true,	playerLevel = { "=",90},	label = "Liadrin Abundance",		frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},						questInfo = "Liadrin Abundance",		font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, },
	{key = "XP12:Q-93913",	questID = 93913,	requireInLog = true,	playerLevel = { "=",90},	label = "Liadrin World Boss",		frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},						questInfo = "Liadrin World Boss",		font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, },
	{key = "XP12:Q-94457",	questID = 94457,	requireInLog = true,	playerLevel = { "=",90},	label = "Liadrin Battleground",		frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},						questInfo = "Liadrin Battleground",		font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, },
	{key = "XP12:Q-93911",	questID = 93911,	requireInLog = true,	playerLevel =  {"=",90},	label = "Liadrin Dungeon",			frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},						questInfo = "Liadrin Dungeon",			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, }, }, } },
	--	Vereesa Fortnightly Quest(s)
	{questGroup = { questIDs = {98172,},		status =
	{key = "XP12:QG98172",	questID = 98172,	requireInLog = false,	playerLevel = { "=",90},	label = "Vereesa Missing",			frameID = "list2",	hideDone = true,	labelComplete = "Vereesa Done",							questInfo = "Vereesa Missing",			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, }, children = {
	{key = "XP12:Q-98172",	questID = 98172,	requireInLog = true,	playerLevel = { "=",90}, 	label = "Vereesa Delves",			frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},						questInfo = "Vereesa Delves",			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, }, }, } },
--	Other Quests
	{key = "XP12:Q96080",	questID = 96080,	requireInLog = false, 	playerLevel = { "=",90},	label = "Void Strike",				frameID = "list2",	hideDone = true,															questInfo = "Void Strike\n - Rutual Site and Void Incursion (Zygor)", },
--	Shows if item is in the player's inventory
	{key = "XP12:I273000",  item = {itemID = 273000, mustHave = true, showCount = false}, wbc=true,	label = "XC Undercoin",				frameID = "list2",	resting = true, 															itemInfo = "Corrosive Soul\n + Deposit in Warbank\n - Altar of Corrosion (8)\n - Exchangable for Undercoins" },
	{key = "XP12:I255826",  item = {itemID = 255826, mustHave = true, showCount = false}, wbc=true,	label = "XC Skyshards",				frameID = "list2",	resting = true,																itemInfo = "Mysterious Skyshards\n + Deposit in Warbank\n  - Mount? (500)" },
--	Catalyst Unbound Check
	{key = "XP12:A62871",   achevID = 62871, 	achevAC = "char",                                  label = "Catalyst Unbound",			frameID = "list2",	hideDone = true, 	currencyID = { 3465, 8, Y },		mapID = {2393}, 	textInfo  = "Catalyst ($hv)\nTier Set Achievement",	font = "lsm:Bazooka", size = 16, color = "b88fe6", align = "center", list = "top", pad = 3, },



--	Delve/World Quests (wqID = { questID, mapID }, wqGold = minimum gold reward required to show, {wqGold}/%wqg = reward text)
	--	Coiled Isle
	{key = "XP12:W-93669",	wqID = {93669,2512},	  wqGold = 500,		playerLevel = { "=",90},	label = "Coiled Isle WQ Gold",		frameID = "list2",	hideDone = true,										mapID = {2512}, 	questInfo = "WQ Coiled Isle  %wqg" .. GI1,	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XP12:W-94612",	wqID = {94612,2512},	  wqGold = 500,		playerLevel = { "=",90},	label = "Coiled Isle WQ Gold",		frameID = "list2",	hideDone = true,										mapID = {2512}, 	questInfo = "WQ Coiled Isle  %wqg" .. GI1,	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XP12:W-94996",	wqID = {94996,2512},	  wqGold = 500,		playerLevel = { "=",90},	label = "Coiled Isle WQ Gold",		frameID = "list2",	hideDone = true,										mapID = {2512}, 	questInfo = "WQ Coiled Isle  %wqg" .. GI1,	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XP12:W-95529",	wqID = {95529,2512},	  wqGold = 500,		playerLevel = { "=",90},	label = "Coiled Isle WQ Gold",		frameID = "list2",	hideDone = true,										mapID = {2512}, 	questInfo = "WQ Coiled Isle  %wqg" .. GI1,	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XP12:W-95990",	wqID = {95990,2512},	  wqGold = 500,		playerLevel = { "=",90},	label = "Coiled Isle WQ Gold",		frameID = "list2",	hideDone = true,										mapID = {2512}, 	questInfo = "WQ Coiled Isle  %wqg" .. GI1,	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XP12:S-95918",	wqID = {95918,2512},	  					playerLevel = { "=",90},	label = "Coiled Isle SA Gold",		frameID = "list2",	hideDone = true,										mapID = {2512}, 	questInfo = "SA Coiled Isle  1784" .. GI1,	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	--	Eversong Woods
	{key = "XP12:Q-97454",	questID = 97454,	requireInLog = false,	playerLevel = {">=",80},	label = "S2 Delve Refresher",		frameID = "list2",	hideDone = true,	progress = {objectiveIndex = 0},	mapID = {2393}, 	questInfo = "Silvermoon  Delve Refresh",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XP12:Q-93372",	questID = 93372,	requireInLog = true,	playerLevel = {">=",80}, 	label = "Silvermoon Delve Quest",	frameID = "list2",	hideDone = true,	progress = {objectiveIndex = 0},	mapID = {2393}, 	questInfo = "Silvermoon  Delver's Call",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XP12:Q-93384",	questID = 93384,	requireInLog = true,	playerLevel = {">=",80}, 	label = "Silvermoon Delve Quest",	frameID = "list2",	hideDone = true,	progress = {objectiveIndex = 0},	mapID = {2393}, 	questInfo = "Silvermoon  Delver's Call",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XP12:Q-93385",	questID = 93385,	requireInLog = true,	playerLevel = {">=",80}, 	label = "Silvermoon Delve Quest",	frameID = "list2",	hideDone = true,	progress = {objectiveIndex = 0},	mapID = {2393}, 	questInfo = "Silvermoon  Delver's Call",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XP12:Q-93386",	questID = 93386,	requireInLog = true,	playerLevel = {">=",80}, 	label = "Silvermoon Delve Quest",	frameID = "list2",	hideDone = true,	progress = {objectiveIndex = 0},	mapID = {2393}, 	questInfo = "Silvermoon  Delver's Call",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XP12:Q-93784",	questID = 93784,	requireInLog = true,	playerLevel = {">=",80}, 	label = "Silvermoon Delve Quest",	frameID = "list2",	hideDone = true,	progress = {objectiveIndex = 0},	mapID = {2393}, 	questInfo = "Silvermoon  Delver's Call",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XP12:W-92144",	wqID = {92144,2395},	  wqGold = 500,		playerLevel = { "=",90},	label = "Eversong WQ Gold",			frameID = "list2",	hideDone = true,															questInfo = "WQ Eversong  %wqg" .. GI1,		font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XP12:W-92146",	wqID = {92146,2395},	  wqGold = 500,		playerLevel = { "=",90},	label = "Eversong WQ Gold",			frameID = "list2",	hideDone = true,															questInfo = "WQ Eversong  %wqg" .. GI1,		font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XP12:W-92152",	wqID = {92152,2395},	  wqGold = 500,		playerLevel = { "=",90},	label = "Eversong WQ Gold",			frameID = "list2",	hideDone = true,															questInfo = "WQ Eversong  %wqg" .. GI1,		font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XP12:S-92139",	wqID = {92139,2395},	  					playerLevel = { "=",90},	label = "Eversong SA Gold",			frameID = "list2",	hideDone = true,															questInfo = "SA Eversong  1784" .. GI1,		font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	--	Harandar										ULSAWQ = true,	
	{key = "XP12:Q-93416",	questID = 93416,	requireInLog = true,	playerLevel = {">=",80}, 	label = "Harandar Delve Quest",		frameID = "list2",	hideDone = true,	progress = {objectiveIndex = 0},	mapID = {2413}, 	questInfo = "DQ Harandar  Delver's Call",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XP12:Q-93421",	questID = 93421,	requireInLog = true,	playerLevel = {">=",80}, 	label = "Harandar Delve Quest",		frameID = "list2",	hideDone = true,	progress = {objectiveIndex = 0},	mapID = {2413}, 	questInfo = "DQ Harandar  Delver's Call",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XP12:W-92062",	wqID = {92062,2413},	  wqGold = 500,		playerLevel = { "=",90},	label = "Harandar WQ Gold",			frameID = "list2",	hideDone = true,										mapID = {2413},		questInfo = "WQ Harandar  %wqg" .. GI1,		font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XP12:W-92583",	wqID = {92583,2413},	  wqGold = 500,		playerLevel = { "=",90},	label = "Harandar WQ Gold",			frameID = "list2",	hideDone = true,										mapID = {2413},		questInfo = "WQ Harandar  %wqg" .. GI1,		font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XP12:W-93053",	wqID = {93053,2413},	  wqGold = 500,		playerLevel = { "=",90},	label = "Harandar WQ Gold",			frameID = "list2",	hideDone = true,										mapID = {2413},		questInfo = "WQ Harandar  %wqg" .. GI1,		font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XP12:W-93071",	wqID = {93071,2413},	  wqGold = 500,		playerLevel = { "=",90},	label = "Harandar WQ Gold",			frameID = "list2",	hideDone = true,										mapID = {2413},		questInfo = "WQ Harandar  %wqg" .. GI1,		font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	--	Voidstorm
	{key = "XP12:Q-93427",	questID = 93427,	requireInLog = true,	playerLevel = {">=",80}, 	label = "Voidstorm Delve Quest",	frameID = "list2",	hideDone = true,	progress = {objectiveIndex = 0},	mapID = {"MVS"},	questInfo = "DQ Voidstorm  Delvers Call",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XP12:Q-93428",	questID = 93428,	requireInLog = true,	playerLevel = {">=",80}, 	label = "Voidstorm Delve Quest",	frameID = "list2",	hideDone = true,	progress = {objectiveIndex = 0},	mapID = {"MVS"},	questInfo = "DQ Voidstorm  Delvers Call",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XP12:W-87759",	wqID = {87759,2405},	  wqGold = 500,		playerLevel = { "=",90},	label = "Voidstorm WQ Gold",		frameID = "list2",	hideDone = true,										mapID = {"MVS"},	questInfo = "WQ Voidstorm  %wqg" .. GI1,	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XP12:W-88992",	wqID = {88992,2405},	  wqGold = 500,		playerLevel = { "=",90},	label = "Voidstorm WQ Gold",		frameID = "list2",	hideDone = true,										mapID = {"MVS"},	questInfo = "WQ Voidstorm  %wqg" .. GI1,	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XP12:W-89377",	wqID = {89377,2405},	  wqGold = 500,		playerLevel = { "=",90},	label = "Voidstorm WQ Gold",		frameID = "list2",	hideDone = true,										mapID = {"MVS"},	questInfo = "WQ Voidstorm  %wqg" .. GI1,	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XP12:W-92731",	wqID = {92731,2405},	  wqGold = 500,		playerLevel = { "=",90},	label = "Voidstorm WQ Gold",		frameID = "list2",	hideDone = true,										mapID = {"MVS"},	questInfo = "WQ Voidstorm  %wqg" .. GI1,	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XP12:W-93517",	wqID = {93517,2405},	  wqGold = 500,		playerLevel = { "=",90},	label = "Voidstorm WQ Gold",		frameID = "list2",	hideDone = true,										mapID = {"MVS"},	questInfo = "WQ Voidstorm  %wqg" .. GI1,	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	--	Zul'Aman
	{key = "XP12:Q-93409",	questID = 93409,	requireInLog = true,	playerLevel = {">=",80}, 	label = "Zul'Aman Delve Quest",		frameID = "list2",	hideDone = true,	progress = {objectiveIndex = 0},	mapID = {2437}, 	questInfo = "DQ Zul'Aman  Delvers Call",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XP12:Q-93410",	questID = 93410,	requireInLog = true,	playerLevel = {">=",80}, 	label = "Zul'Aman Delve Quest",		frameID = "list2",	hideDone = true,	progress = {objectiveIndex = 0},	mapID = {2437}, 	questInfo = "DQ Zul'Aman  Delvers Call",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XP12:W-91801",	wqID = {91801,2437},	  wqGold = 500,		playerLevel = { "=",90},	label = "Zul'Aman WQ Gold",			frameID = "list2",	hideDone = true,															questInfo = "WQ Zul'Aman  %wqg" .. GI1,		font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XP12:W-91810",	wqID = {91810,2437},	  wqGold = 500,		playerLevel = { "=",90},	label = "Zul'Aman WQ Gold",			frameID = "list2",	hideDone = true,															questInfo = "WQ Zul'Aman  %wqg" .. GI1,		font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom",  item = { itemID = 260890, required = { 1, N, Y, 1 }, showCount = false, }, },






}


bakedRules = ns.GuideHelpers.ExpandQuestGroups(bakedRules)
for i = 1, #bakedRules do
  local r = bakedRules[i]
  if type(r) == "table" and not r.questGroup then
    ns.GuideHelpers.NormalizeRule(r, EXPANSION_ID, EXPANSION_NAME)
    ns.rules[#ns.rules + 1] = r
  end
end
