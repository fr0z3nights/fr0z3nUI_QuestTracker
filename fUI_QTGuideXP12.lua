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
--   $caN -> {currency:above:N} (amount above N, e.g. $ca6)


-- item.required tuple keys:
--   item.required = { count, hideWhenAcquired, autoBuyEnabled, autoBuyMax }
local REQ_COUNT, REQ_HIDE, REQ_BUY_ON, REQ_BUY_MAX = 1, 2, 3, 4
local LIADRIN_QUEST_IDS = {93909, 95842, 93910, 96727, 95843, 93892, 93889, 98232, 93766, 93769, 93912, 93767, 93890, 93913, 94457, 93911}
local bakedRules = {

--	Silvermoon
	{key = "XP12:I-269862",	item = {itemID = 269862, mustHave = true, showCount = false},			label = "Great Vault Token",		frameID = "list2",																				itemInfo = "Great Vault Token", 			font = "lsm:Bazooka", size = 18, color = "ffe643", align = "center", list = "top", pad = 4, mapID = {2393}, },		
	{key = "XP12:Q93010",	questID = 93012,	requireInLog = false, 	playerLevel = { "=",90,},	label = "Soridormi Skip(s)",		frameID = "list2",	hideDone = true, 	progress = {objectiveIndex = 0},																	font = "lsm:Bazooka", size = 22, color = "ffe633", align = "center", list = "top", pad = 4, mapID = {2393}, },
--	{key = "XP12:Q-98016",	questID = 98016,	requireInLog = false, 	playerLevel = { "=",90,},	label = "Nebulous Voidcore",		frameID = "list2",	hideDone = true, 	progress = {objectiveIndex = 0},																	font = "lsm:Bazooka", size = 22, color = "ffe633", align = "center", list = "top", pad = 4, mapID = {2393}, },
	--	Void Assaults
	{key = "XP12:C-3310",	showIf = { questInLogIDs = {94385,94386,} },							label = "Coffer Key Shards",        frameID = "list2",	hideDone = true, 	currencyID = { 3310, 1000, Y },							textInfo  = "$hv / 100 = 1 Key", 			font = "lsm:Bazooka", size = 16, color = "ffe633", align = "center", list = "top", pad = -4, },
	{questGroup = { questIDs = {94385,94386,},	status =
	{key = "XP12:Q-94385G",	questID = 94385,	requireInLog = false,	playerLevel = { "=",90},	label = "Void Assault Missing",		frameID = "list2",	hideDone = true,															labelComplete = "VAssault Done", 			font = "lsm:Bazooka", size = 16, color = "ffe633", align = "center", list = "top", pad =  4, }, children = {
	{key = "XP12:Q-94385",	questID = 94385,	requireInLog = true,	playerLevel = { "=",90}, 	label = "Eversong Assault",			frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1}, 																	font = "lsm:Bazooka", size = 16, color = "ffe633", align = "center", list = "top", pad =  4, zygor = { "EVENTS\\Midnight (80-90)\\Eversong Woods Void Assaults",0,1,1 }, },
	{key = "XP12:Q-94386",	questID = 94386,	requireInLog = true,	playerLevel = { "=",90}, 	label = "Zul'Aman Assault",			frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},																	font = "lsm:Bazooka", size = 16, color = "ffe633", align = "center", list = "top", pad =  4, zygor = { "EVENTS\\Midnight (80-90)\\Zul'Aman Void Assaults"      ,0,1,1 }, }, }, } },
	--	Lady Liadrin Fortnightly Quest(s)		Tent Outside Bank
	{questGroup = { questIDs = {93909,95842,93910,96727,95843,93892,93889,98232,93766,93769,93912,93767,93890,93913,94457,93911,},		status =
	{key = "XP12:QG93909",	questID = 93909, 	requireInLog = false, 	playerLevel = { "=",90}, 	label = "Liadrin Missing",			frameID = "list2",	hideDone = true,	labelComplete = "Liadrin Done",							questInfo = "Liadrin Missing",				font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, }, children = {
	{key = "XP12:Q-93909",	questID = 93909,	requireInLog = true,	playerLevel = { "=",90},	label = "Liadrin Delves",			frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},						questInfo = "Liadrin Delves",				font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, },
	{key = "XP12:Q-95842",	questID = 95842,	requireInLog = true,	playerLevel = { "=",90},	label = "Liadrin Void Assault",		frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},						questInfo = "Liadrin VoidAssault",			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, },
	{key = "XP12:Q-93910",	questID = 93910,	requireInLog = true,	playerLevel = { "=",90},	label = "Liadrin Prey",				frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},						questInfo = "Liadrin Prey",					font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, },
	{key = "XP12:Q-96727",	questID = 96727,	requireInLog = true,	playerLevel = { "=",90},	label = "Liadrin Offworld",			frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},						questInfo = "Liadrin Offworld",				font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, },
	{key = "XP12:Q-95843",	questID = 95843,	requireInLog = true,	playerLevel = { "=",90},	label = "Liadrin Ritual Site",		frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},						questInfo = "Liadrin Ritual Site",			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, },
	{key = "XP12:Q-93892",	questID = 93892,	requireInLog = true,	playerLevel = { "=",90},	label = "Liadrin Stormarion",		frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},						questInfo = "Liadrin Stormarion",			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, },
	{key = "XP12:Q-93889",	questID = 93889,	requireInLog = true,	playerLevel = { "=",90},	label = "Liadrin Slthri Soire",		frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},						questInfo = "Liadrin Slthri Soire",			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, },
	{key = "XP12:Q-98232",	questID = 98232,	requireInLog = true,	playerLevel = { "=",90},	label = "Liadrin Atal'Utek",		frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},						questInfo = "Liadrin Atal'Utek",			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, },
	{key = "XP12:Q-93766",	questID = 93766,	requireInLog = true,	playerLevel = { "=",90},	label = "Liadrin World Quest",		frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},	itemCD = 230850, 	questInfo = "Liadrin World Quest %p\n$icd",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, },
	{key = "XP12:Q-93769",	questID = 93769,	requireInLog = true,	playerLevel = { "=",90},	label = "Liadrin Housing",			frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},						questInfo = "Liadrin Housing",				font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, },
	{key = "XP12:Q-93912",	questID = 93912,	requireInLog = true,	playerLevel = { "=",90},	label = "Liadrin Raid",				frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},						questInfo = "Liadrin Raid",					font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, },
	{key = "XP12:Q-93767",	questID = 93767,	requireInLog = true,	playerLevel = { "=",90},	label = "Liadrin Arcantina",		frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},						questInfo = "Liadrin Arcantina",			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, },
	{key = "XP12:Q-93890",	questID = 93890,	requireInLog = true,	playerLevel = { "=",90},	label = "Liadrin Abundance",		frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},						questInfo = "Liadrin Abundance",			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, },
	{key = "XP12:Q-93913",	questID = 93913,	requireInLog = true,	playerLevel = { "=",90},	label = "Liadrin World Boss",		frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},						questInfo = "Liadrin World Boss",			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, },
	{key = "XP12:Q-94457",	questID = 94457,	requireInLog = true,	playerLevel = { "=",90},	label = "Liadrin Battleground",		frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},						questInfo = "Liadrin Battleground",			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, },
	{key = "XP12:Q-93911",	questID = 93911,	requireInLog = true,	playerLevel =  {"=",90},	label = "Liadrin Dungeon",			frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},						questInfo = "Liadrin Dungeon",				font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, }, }, } },
	--	Vereesa Fortnightly Quest(s)			Tent Outside Bank
	{questGroup = { questIDs = {98172,},		status =
	{key = "XP12:QG98172",	questID = 98172,	requireInLog = false,	playerLevel = { "=",90},	label = "Vereesa Missing",			frameID = "list2",	hideDone = true,	labelComplete = "Vereesa Done",							questInfo = "Vereesa Missing",				font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, }, children = {
	{key = "XP12:Q-98172",	questID = 98172,	requireInLog = true,	playerLevel = { "=",90}, 	label = "Vereesa Delves",			frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 1},						questInfo = "Vereesa Delves",				font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4, }, }, } },
	{key = "XP12:Q96080",	questID = 96080,	requireInLog = false, 	playerLevel = { "=",90},	label = "Void Strike",				frameID = "list2",	hideDone = true,															questInfo = "Void Strike\n - Rutual Site and Void Incursion (Zygor)", },
	--	WarBank Items			Shows if item is in the player's inventory & if player has Warband Bank Control [WBC = ] for depositing
	{key = "XP12:I273000",  item = {itemID = 273000, mustHave = true, showCount = false}, wbc=true,	label = "XC Undercoin",				frameID = "list2",	resting = true, 															itemInfo = "Corrosive Soul\n + Deposit in Warbank\n - Altar of Corrosion (8)\n - Exchangable for Undercoins" },
	{key = "XP12:I255826",  item = {itemID = 255826, mustHave = true, showCount = false}, wbc=true,	label = "XC Skyshards",				frameID = "list2",	resting = true,																itemInfo = "Mysterious Skyshards\n + Deposit in Warbank\n  - Mount? (500)" },
	--	Catalyst Unbound Check
	{key = "XP12:A62871",   mapID = {2393}, 	achevID = 62871, 	achevAC = "char",		playerLevel = { "=",90},	label = "Catalyst Unbound",			frameID = "list2",	hideDone = true,	currencyID = { 3465, 8, Y },		textInfo  = "Catalyst S2 ($hv)\nTier Set Achievement",	font = "lsm:Bazooka", size = 16, color = "b88fe6", align = "center", pad = 3, },

--	Coiled Isle, The													(wqID = { questID, mapID }, wqGold = minimum gold reward required to show, {wqGold}/%wqg = reward text)S

	--	World Quest
	{key = "XP12:W-93669",	mapID = {2512}, 	wqID = {93669,2512},	  wqGold = 500,		playerLevel = {">=",80},	label = "Coiled Isle WQ Gold",		frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Coiled Isle WQ  %wqg" .. GI1,	font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:W-94572",	mapID = {2512}, 	wqID = {94572,2512},	  wqGold = 500,		playerLevel = {">=",80},	label = "Coiled Isle WQ Gold",		frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Coiled Isle WQ  %wqg" .. GI1,	font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:W-94574",	mapID = {2512}, 	wqID = {94574,2512},	  wqGold = 500,		playerLevel = {">=",80},	label = "Coiled Isle WQ Gold",		frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Coiled Isle WQ  %wqg" .. GI1,	font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:W-94612",	mapID = {2512}, 	wqID = {94612,2512},	  wqGold = 500,		playerLevel = {">=",80},	label = "Coiled Isle WQ Gold",		frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Coiled Isle WQ  %wqg" .. GI1,	font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:W-94996",	mapID = {2512}, 	wqID = {94996,2512},	  wqGold = 500,		playerLevel = {">=",80},	label = "Coiled Isle WQ Gold",		frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Coiled Isle WQ  %wqg" .. GI1,	font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:W-95449",	mapID = {2512}, 	wqID = {95449,2512},	  wqGold = 500,		playerLevel = {">=",80},	label = "Coiled Isle WQ Gold",		frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Coiled Isle WQ  %wqg" .. GI1,	font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:W-95453",	mapID = {2512}, 	wqID = {95453,2512},	  wqGold = 500,		playerLevel = {">=",80},	label = "Coiled Isle WQ Gold",		frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Coiled Isle WQ  %wqg" .. GI1,	font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:W-95529",	mapID = {2512}, 	wqID = {95529,2512},	  wqGold = 500,		playerLevel = {">=",80},	label = "Coiled Isle WQ Gold",		frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Coiled Isle WQ  %wqg" .. GI1,	font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:W-95990",	mapID = {2512}, 	wqID = {95990,2512},	  wqGold = 500,		playerLevel = {">=",80},	label = "Coiled Isle WQ Gold",		frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Coiled Isle WQ  %wqg" .. GI1,	font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	--	World Quest Special Assignment
	{key = "XP12:W-95918",	mapID = {2512}, 	wqID = {95918,2512},	  					playerLevel = {">=",80},	label = "Coiled Isle SA Gold",		frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Coiled Isle XQ  1784" .. GI1,	font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:W-95922",	mapID = {2512}, 	wqID = {95922,2512},	  					playerLevel = {">=",80},	label = "Coiled Isle SA Gold",		frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Coiled Isle XQ  1784" .. GI1,	font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },

--	Eversong Woods

	--	Abundance								/run local m=WorldMapFrame:GetMapID(); print("Map",m,C_Map.GetMapInfo(m).name)								/run for _,p in ipairs(C_AreaPoiInfo.GetEventsForMap(2413)) do local i=C_AreaPoiInfo.GetAreaPOIInfo(2413,p); print(p,i.name,i.isCurrentEvent) end
	{key = "XP12:C-3376XE",						questID = 89507, eventPOI = {8528,2395},	playerLevel = { "=",90}, 	label = "Abundant Eversong Chk",	frameID = "list2",	hideDone = false,	hideQID = 89507,					questInfo = "Use $ca6 Tokens Before",			font = "lsm:Bazooka", size = 13, color = "ffe633", align = "center", list = "top", pad = -7,	preferQuestInfoForTitle = true, showIf = {currencyID = {3376,7}}, hideIfAnyQuestInLog = {89507}, hideIfAnyQuestCompleted = true, },
	{key = "XP12:QG89507E",						questID = 89507, eventPOI = {8528,2395},	playerLevel = { "=",90},	label = "Abundant Eversong Miss",	frameID = "list2",	hideDone = true,	labelComplete = "Abundance Done",	questInfo = "Eversong Abundant Quest",			font = "lsm:Bazooka", size = 14, color = "ffe633", align = "center", list = "top", pad = 4,		requireInLog = false,		hideIfAnyQuestInLog = {89507}, }, -- complete = { any = { {questID = 89507}, {currencyID = {3376,7}} } }, completeMode = "replace", 
	{key = "XP12:Q-89507E",						questID = 89507, eventPOI = {8528,2395},	playerLevel = { "=",90}, 	label = "Abundant Eversong Offer",	frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 0},	questInfo = "Eversong Abundant 1784" .. GI1,	font = "lsm:Bazooka", size = 14, color = "ffe633", align = "center", list = "top", pad = 4,		requireInLog = true,		hideIfAnyQuestCompleted = true, questIDs = {89507}, },
	--	Delves
	{key = "XP12:Q-97454",	mapID = {2393}, 	questID = 97454,	requireInLog = false,	playerLevel = {">=",80},	label = "S2 Delve Refresher",		frameID = "list2",	hideDone = true,	progress = {objectiveIndex = 0},	questInfo = " - Silvermoon Delve Refresh",		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:Q-93372",	mapID = {2393}, 	questID = 93372,	requireInLog = true,	playerLevel = {">=",80}, 	label = "Silvermoon Delve Quest",	frameID = "list2",	hideDone = true,	progress = {objectiveIndex = 0},	questInfo = " - Silvermoon Delver's Call",		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:Q-93384",	mapID = {2393}, 	questID = 93384,	requireInLog = true,	playerLevel = {">=",80}, 	label = "Silvermoon Delve Quest",	frameID = "list2",	hideDone = true,	progress = {objectiveIndex = 0},	questInfo = " - Silvermoon Delver's Call",		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:Q-93385",	mapID = {2393}, 	questID = 93385,	requireInLog = true,	playerLevel = {">=",80}, 	label = "Silvermoon Delve Quest",	frameID = "list2",	hideDone = true,	progress = {objectiveIndex = 0},	questInfo = " - Silvermoon Delver's Call",		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:Q-93386",	mapID = {2393}, 	questID = 93386,	requireInLog = true,	playerLevel = {">=",80}, 	label = "Silvermoon Delve Quest",	frameID = "list2",	hideDone = true,	progress = {objectiveIndex = 0},	questInfo = " - Silvermoon Delver's Call",		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:Q-93784",	mapID = {2393}, 	questID = 93784,	requireInLog = true,	playerLevel = {">=",80}, 	label = "Silvermoon Delve Quest",	frameID = "list2",	hideDone = true,	progress = {objectiveIndex = 0},	questInfo = " - Silvermoon Delver's Call",		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	--	World Quest
	{key = "XP12:W-92140",						wqID = {92140,2395},	  wqGold = 500,		playerLevel = {">=",80},	label = "Eversong WQ Gold",			frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Eversong WQ  %wqg" .. GI1,		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:W-92144",						wqID = {92144,2395},	  wqGold = 500,		playerLevel = {">=",80},	label = "Eversong WQ Gold",			frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Eversong WQ  %wqg" .. GI1,		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:W-92146",						wqID = {92146,2395},	  wqGold = 500,		playerLevel = {">=",80},	label = "Eversong WQ Gold",			frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Eversong WQ  %wqg" .. GI1,		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:W-92152",						wqID = {92152,2395},	  wqGold = 500,		playerLevel = {">=",80},	label = "Eversong WQ Gold",			frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Eversong WQ  %wqg" .. GI1,		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:W-92153",						wqID = {92153,2395},	  wqGold = 500,		playerLevel = {">=",80},	label = "Eversong WQ Gold",			frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Eversong WQ  %wqg" .. GI1,		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:W-92195",						wqID = {92195,2395},	  wqGold = 500,		playerLevel = {">=",80},	label = "Eversong WQ Gold",			frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Eversong WQ  %wqg" .. GI1,		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	--	World Quest Special Assignment 
	{key = "XP12:W-92139",						wqID = {92139,2395},	  					playerLevel = {">=",80},	label = "Eversong SA Gold",			frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Eversong XQ  1784" .. GI1,		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:W-92145",						wqID = {92145,2395},	  					playerLevel = {">=",80},	label = "Eversong SA Gold",			frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Eversong XQ  1784" .. GI1,		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },

--	Harandar										ULSAWQ = true,	

	--	Abundance								/run local m=WorldMapFrame:GetMapID(); print("Map",m,C_Map.GetMapInfo(m).name)								/run for _,p in ipairs(C_AreaPoiInfo.GetEventsForMap(2413)) do local i=C_AreaPoiInfo.GetAreaPOIInfo(2413,p); print(p,i.name,i.isCurrentEvent) end
	{key = "XP12:C-3376XH",	mapID = {2413}, 	questID = 89507, eventPOI = {8527,2413},	playerLevel = { "=",90}, 	label = "Abundant Harandar Chk",	frameID = "list2",	hideDone = false,	hideQID = 89507,					questInfo = "Use $ca6 Tokens Before",			font = "lsm:Bazooka", size = 13, color = "ffe633", align = "center", list = "top", pad = -7,	preferQuestInfoForTitle = true, showIf = {currencyID = {3376,7}}, hideIfAnyQuestInLog = {89507}, hideIfAnyQuestCompleted = true, },
	{key = "XP12:QG89507H",	mapID = {2413}, 	questID = 89507, eventPOI = {8527,2413},	playerLevel = { "=",90},	label = "Abundant Harandar Miss",	frameID = "list2",	hideDone = true,	labelComplete = "Abundance Done",	questInfo = "Harandar Abundant Quest",			font = "lsm:Bazooka", size = 14, color = "ffe633", align = "center", list = "top", pad = 4,		requireInLog = false,		hideIfAnyQuestInLog = {89507}, }, -- complete = { any = { {questID = 89507}, {currencyID = {3376,7}} } }, completeMode = "replace", 
	{key = "XP12:Q-89507H",	mapID = {2413}, 	questID = 89507, eventPOI = {8527,2413},	playerLevel = { "=",90}, 	label = "Abundant Harandar Offer",	frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 0},	questInfo = "Harandar Abundant 1784" .. GI1,	font = "lsm:Bazooka", size = 14, color = "ffe633", align = "center", list = "top", pad = 4,		requireInLog = true,		hideIfAnyQuestCompleted = true, questIDs = {89507}, },
	--	Delves
	{key = "XP12:Q-93416",	mapID = {2413}, 	questID = 93416,	requireInLog = true,	playerLevel = {">=",80}, 	label = "Harandar Delve Quest",		frameID = "list2",	hideDone = true,	progress = {objectiveIndex = 0},	questInfo = " - Harandar Delver's Call",		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:Q-93421",	mapID = {2413}, 	questID = 93421,	requireInLog = true,	playerLevel = {">=",80}, 	label = "Harandar Delve Quest",		frameID = "list2",	hideDone = true,	progress = {objectiveIndex = 0},	questInfo = " - Harandar Delver's Call",		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	--	World Quests
	{key = "XP12:W-92062",	mapID = {2413},		wqID = {92062,2413},	  wqGold = 500,		playerLevel = {">=",80},	label = "Harandar WQ Gold",			frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Harandar WQ  %wqg" .. GI1,		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:W-92583",	mapID = {2413},		wqID = {92583,2413},	  wqGold = 500,		playerLevel = {">=",80},	label = "Harandar WQ Gold",			frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Harandar WQ  %wqg" .. GI1,		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:W-93053",	mapID = {2413},		wqID = {93053,2413},	  wqGold = 500,		playerLevel = {">=",80},	label = "Harandar WQ Gold",			frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Harandar WQ  %wqg" .. GI1,		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:W-93071",	mapID = {2413},		wqID = {93071,2413},	  wqGold = 500,		playerLevel = {">=",80},	label = "Harandar WQ Gold",			frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Harandar WQ  %wqg" .. GI1,		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },

--	Voidstorm						  MVS = Midnight Voidstorm Maps

	--	Abundance								/run local m=WorldMapFrame:GetMapID(); print("Map",m,C_Map.GetMapInfo(m).name)								/run for _,p in ipairs(C_AreaPoiInfo.GetEventsForMap(2413)) do local i=C_AreaPoiInfo.GetAreaPOIInfo(2413,p); print(p,i.name,i.isCurrentEvent) end
--	{key = "XP12:C-3376XH",						questID = 89507, eventPOI = {8527,2413},	playerLevel = { "=",90}, 	label = "Abundant Harandar Chk",	frameID = "list2",	hideDone = false,	hideQID = 89507,					questInfo = "Use $ca6 Tokens Before",			font = "lsm:Bazooka", size = 13, color = "ffe633", align = "center", list = "top", pad = -7,	preferQuestInfoForTitle = true, showIf = {currencyID = {3376,7}}, hideIfAnyQuestInLog = {89507}, hideIfAnyQuestCompleted = true, },
--	{key = "XP12:QG89507H",						questID = 89507, eventPOI = {8527,2413},	playerLevel = { "=",90},	label = "Abundant Harandar Miss",	frameID = "list2",	hideDone = true,	labelComplete = "Abundance Done",	questInfo = "Voidstorm Abundant Quest",			font = "lsm:Bazooka", size = 14, color = "ffe633", align = "center", list = "top", pad = 4,		requireInLog = false,		hideIfAnyQuestInLog = {89507}, }, -- complete = { any = { {questID = 89507}, {currencyID = {3376,7}} } }, completeMode = "replace", 
--	{key = "XP12:Q-89507H",						questID = 89507, eventPOI = {8527,2413},	playerLevel = { "=",90}, 	label = "Abundant Harandar Offer",	frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 0},	questInfo = "Voidstorm Abundant 1784" .. GI1,	font = "lsm:Bazooka", size = 14, color = "ffe633", align = "center", list = "top", pad = 4,		requireInLog = true,		hideIfAnyQuestCompleted = true, questIDs = {89507}, },
	--	Delves
	{key = "XP12:Q-93427",	mapID = {"MVS"},	questID = 93427,	requireInLog = true,	playerLevel = {">=",80}, 	label = "Voidstorm Delve Quest",	frameID = "list2",	hideDone = true,	progress = {objectiveIndex = 0},	questInfo = " - Voidstorm Delvers Call",		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:Q-93428",	mapID = {"MVS"},	questID = 93428,	requireInLog = true,	playerLevel = {">=",80}, 	label = "Voidstorm Delve Quest",	frameID = "list2",	hideDone = true,	progress = {objectiveIndex = 0},	questInfo = " - Voidstorm Delvers Call",		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	--	World Quest
	{key = "XP12:W-87759",	mapID = {"MVS"},	wqID = {87759,2405},	  wqGold = 500,		playerLevel = {">=",80},	label = "Voidstorm WQ Gold",		frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Voidstorm WQ  %wqg" .. GI1,		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:W-88679",	mapID = {"MVS"},	wqID = {88679,2405},	  wqGold = 500,		playerLevel = {">=",80},	label = "Voidstorm WQ Gold",		frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Voidstorm WQ  %wqg" .. GI1,		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:W-88992",	mapID = {"MVS"},	wqID = {88992,2405},	  wqGold = 500,		playerLevel = {">=",80},	label = "Voidstorm WQ Gold",		frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Voidstorm WQ  %wqg" .. GI1,		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:W-89347",	mapID = {"MVS"},	wqID = {89347,2405},	  wqGold = 500,		playerLevel = {">=",80},	label = "Voidstorm WQ Gold",		frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Voidstorm WQ  %wqg" .. GI1,		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:W-89377",	mapID = {"MVS"},	wqID = {89377,2405},	  wqGold = 500,		playerLevel = {">=",80},	label = "Voidstorm WQ Gold",		frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Voidstorm WQ  %wqg" .. GI1,		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:W-92731",	mapID = {"MVS"},	wqID = {92731,2405},	  wqGold = 500,		playerLevel = {">=",80},	label = "Voidstorm WQ Gold",		frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Voidstorm WQ  %wqg" .. GI1,		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:W-93517",	mapID = {"MVS"},	wqID = {93517,2405},	  wqGold = 500,		playerLevel = {">=",80},	label = "Voidstorm WQ Gold",		frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Voidstorm WQ  %wqg" .. GI1,		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:W-93524",	mapID = {"MVS"},	wqID = {93524,2405},	  wqGold = 500,		playerLevel = {">=",80},	label = "Voidstorm WQ Gold",		frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Voidstorm WQ  %wqg" .. GI1,		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:W-93579",	mapID = {"MVS"},	wqID = {93579,2405},	  wqGold = 500,		playerLevel = {">=",80},	label = "Voidstorm WQ Gold",		frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Voidstorm WQ  %wqg" .. GI1,		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:W-94425R",	mapID = {"MVS"},	wqID = {94425,2405},	  wqGold = 500,		playerLevel = {">=",80},	label = "Voidstorm WQ Gold",		frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Voidstorm WQ  %wqg" .. GI1,		font = "lsm:Bazooka", size = 14, color = "E0115F", align = "left", },
	--	World Quest - Special Assignment
	{key = "XP12:W-93438",	mapID = {"MVS"},	wqID = {93438,2405},	  					playerLevel = {">=",80},	label = "Voidstorm WQ Gold",		frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Voidstorm XQ  1784" .. GI1,		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },

--	Zul'Aman

	--	Abundance								/run local m=WorldMapFrame:GetMapID(); print("Map",m,C_Map.GetMapInfo(m).name)								/run for _,p in ipairs(C_AreaPoiInfo.GetEventsForMap(2413)) do local i=C_AreaPoiInfo.GetAreaPOIInfo(2413,p); print(p,i.name,i.isCurrentEvent) end
--	{key = "XP12:C-3376XH",						questID = 89507, eventPOI = {8527,2413},	playerLevel = { "=",90}, 	label = "Abundant Harandar Chk",	frameID = "list2",	hideDone = false,	hideQID = 89507,					questInfo = "Use $ca6 Tokens Before",			font = "lsm:Bazooka", size = 13, color = "ffe633", align = "center", list = "top", pad = -7,	preferQuestInfoForTitle = true, showIf = {currencyID = {3376,7}}, hideIfAnyQuestInLog = {89507}, hideIfAnyQuestCompleted = true, },
--	{key = "XP12:QG89507H",						questID = 89507, eventPOI = {8527,2413},	playerLevel = { "=",90},	label = "Abundant Harandar Miss",	frameID = "list2",	hideDone = true,	labelComplete = "Abundance Done",	questInfo = "Zul'Aman Abundant Quest",			font = "lsm:Bazooka", size = 14, color = "ffe633", align = "center", list = "top", pad = 4,		requireInLog = false,		hideIfAnyQuestInLog = {89507}, }, -- complete = { any = { {questID = 89507}, {currencyID = {3376,7}} } }, completeMode = "replace", 
--	{key = "XP12:Q-89507H",						questID = 89507, eventPOI = {8527,2413},	playerLevel = { "=",90}, 	label = "Abundant Harandar Offer",	frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 0},	questInfo = "Zul'Aman Abundant 1784" .. GI1,	font = "lsm:Bazooka", size = 14, color = "ffe633", align = "center", list = "top", pad = 4,		requireInLog = true,		hideIfAnyQuestCompleted = true, questIDs = {89507}, },
	--	Boss
	{key = "XP12:B-92123",	hideQID = 92128,	wqID = {92123,2437},	 uwqGold = 500,  	playerLevel = { "=",90},	label = "Zul'Aman World Boss",		frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Zul'Aman Boss  Weapon",			font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", questInfoUwqGold = "Zul'Aman Boss  %wqg" .. GI1, },
	--	Delves
	{key = "XP12:Q-93409",	mapID = {2437}, 	questID = 93409,	requireInLog = true,	playerLevel = {">=",80}, 	label = "Zul'Aman Delve Quest",		frameID = "list2",	hideDone = true,	progress = {objectiveIndex = 0},	questInfo = " - Zul'Aman Delvers Call",			font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:Q-93410",	mapID = {2437}, 	questID = 93410,	requireInLog = true,	playerLevel = {">=",80}, 	label = "Zul'Aman Delve Quest",		frameID = "list2",	hideDone = true,	progress = {objectiveIndex = 0},	questInfo = " - Zul'Aman Delvers Call",			font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	--	World Quest
	{key = "XP12:W-91801",						wqID = {91801,2437},	  wqGold = 500,		playerLevel = {">=",80},	label = "Zul'Aman WQ Gold",			frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Zul'Aman WQ  %wqg" .. GI1,		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:W-91803",						wqID = {91803,2437},	  wqGold = 500,		playerLevel = {">=",80},	label = "Zul'Aman WQ Gold",			frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Zul'Aman WQ  %wqg" .. GI1,		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },
	{key = "XP12:W-91810",						wqID = {91810,2437},	  wqGold = 500,		playerLevel = {">=",80},	label = "Zul'Aman WQ Gold",			frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Zul'Aman WQ  %wqg" .. GI1,		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", item = { itemID = 260890, required = { 1, N, Y, 1 }, showCount = false, }, },
	--	World Quest Special Assignment
	{key = "XP12:W-91796",						wqID = {91796,2437},						playerLevel = {">=",80},	label = "Zul'Aman SA Gold",			frameID = "list2",	hideDone = true,	zygorX = 1,							questInfo = " - Zul'Aman XQ  1784" .. GI1,		font = "lsm:Bazooka", size = 14, color = "ffe633", align = "left", },



--	OLD NEW IS MAP CHECKED		Abundance Weekly Quest(s)		Random Locations
--	{key = "XP12:C-3376X",	questID = 89507, 							playerLevel = { "=",90}, 	label = "Abundant Check",			frameID = "list2",	hideDone = false,															questInfo = "Use $ca6 Tokens Before",		font = "lsm:Bazooka", size = 13, color = "ffe633", align = "center", list = "top", pad = -7,	preferQuestInfoForTitle = true, showIf = {currencyID = {3376,7}}, hideIfAnyQuestInLog = {89507}, hideIfAnyQuestCompleted = true, },
--	{key = "XP12:QG89507",	questID = 89507,	requireInLog = false,	playerLevel = { "=",90},	label = "Abundant Missing",			frameID = "list2",	hideDone = true,	labelComplete = "Abundance Done",						questInfo = "Abundance Quest",				font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4,		hideIfAnyQuestInLog = {89507}, }, -- complete = { any = { {questID = 89507}, {currencyID = {3376,7}} } }, completeMode = "replace", 
--	{key = "XP12:Q-89507",	questID = 89507,	requireInLog = true,	playerLevel = { "=",90}, 	label = "Abundant Offerings",		frameID = "list2",	hideDone = false,	progress = {objectiveIndex = 0},						questInfo = "Abundant Offerings",			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top", pad = 4,		hideIfAnyQuestCompleted = true, questIDs = {89507}, },



}


bakedRules = ns.GuideHelpers.ExpandQuestGroups(bakedRules)
for i = 1, #bakedRules do
  local r = bakedRules[i]
  if type(r) == "table" and not r.questGroup then
    ns.GuideHelpers.NormalizeRule(r, EXPANSION_ID, EXPANSION_NAME)
    ns.rules[#ns.rules + 1] = r
  end
end
