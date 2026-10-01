local addonName, ns = ...

-- Expansion DBEV (Events)
-- Put event-specific baked rules in this file.

ns.rules = ns.rules or {}

local EXPANSION_ID = -2
local EXPANSION_NAME = "Events"

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
--   %sl -> {shoppingList}
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










	
-- Levelling Events

	{aura = { eventKind = "calendar", keywords = { "Winds of Mysterious Fortune" }, mustHave = true, rememberWeekly = true },
	label = "Winds of Mysterious Fortune", frameID = "list2", key = "event:winds-of-mysterious-fortune",
	textInfo = "Winds Mysterious Fortune\nGear & 20% Level Boost", size = 18, color = "1eff00", align = "center", levelGate = "leveling", hideDone = false, },

-- Darkmoon Faire

	{key = "XPEV:Darkmoon00", event = "Darkmoon", order = 00, label = "Darkmoon Faire", frameID = "list2", 
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "Darkmoon Faire", font = "lsm:Bazooka", size = 20, color = "6b21a8", align = "center", },

	{key = "XPEV:Darkmoon01", event = "Darkmoon", order = 01, label = "Darkmoon Adventurer's Guide", frameID = "list2", color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	itemInfo = "Darkmoon Adventurer's Guide\n- Hidden if in bags/bank", item = {itemID = 71634, includeBank = true, required = { 1, Y, N, 0 }, }, },

	{key = "XPEV:Darkmoon02", event = "Darkmoon", order = 02, label = "Darkmoon Game Tokens", frameID = "list2", color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	itemInfo = "Game Tokens", item = {itemID = 71083, showWhenBelow = 21, required = { 20, N, Y, 200 }, buy = {enabled = Y, min = 20, target = 100, max = 200, yieldItemID = 71083, yieldCount = 20, cheapestOf = { 78910, 78909, 78908, 78907, 78906, 78905 }, }, }, },

	{key = "XPEV:Darkmoon03", event = "Darkmoon", order = 03, label = "Pet Battle: Jeremy", frameID = "list2", color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "Pet Battle: Jeremy", questID = 32175, hideDone = true, },

	{key = "XPEV:Darkmoon04", event = "Darkmoon", order = 04, label = "Pet Battle: Christoph", frameID = "list2", color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "Pet Battle: Christoph", questID = 36471, hideDone = true, },

	-- Darkmoon Faire weekly profession quests  	Display gate: uses base profession skillLineIDs so these only show if you actually know the corresponding profession (more reliable than spellID lists).

	{key = "XPEV:Darkmoon05", event = "Darkmoon", order = 05, faction = "A", label = "Darkmoon: Alchemy", frameID = "list2", color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "Darkmoon: Alchemy\n%sl\n - Vendor Outside Portal", questID = 29506, profSID = 171, autoBuyShopping = false, shopping = { { itemID = 1645, required = 5, buy = false }, }, },

	{key = "XPEV:Darkmoon06", event = "Darkmoon", order = 06, faction = "H", label = "Darkmoon: Alchemy", frameID = "list2", color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "Darkmoon: Alchemy\n%sl\n - Vendor Lower Bluff", questID = 29506, profSID = 171, autoBuyShopping = false, shopping = { { itemID = 1645, required = 5, buy = false }, }, },

	{key = "XPEV:Darkmoon07", event = "Darkmoon", order = 07, label = "Darkmoon: Archaeology", frameID = "list2", color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "DMF: Archaeology\n - Fossil Fragments $hv/$rq", questID = 29507, profSID = 794, item = { itemID = 111245, currencyID = { 393, 15 }, required = { 20, N, Y, 200 }, }, showIf = { any = { { questInLog = 29507 }, { currencyID = { 393, 15 } }, }, }, },

	{key = "XPEV:Darkmoon08", event = "Darkmoon", order = 08, label = "Darkmoon: Blacksmithing", frameID = "list2", color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "DMF: Blacksmithing", questID = 29508, profSID = 164, },

	{key = "XPEV:Darkmoon09", event = "Darkmoon", order = 09, faction = "A", label = "Darkmoon: Cooking", frameID = "list2", color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "DMF: Cooking\n%sl\n - Vendor Outside Portal", questID = 29509, profSID = 185, autoBuyShopping = false, shopping = {{ itemID = 30817, required = 20, buy = false }, }, },

	{key = "XPEV:Darkmoon10", event = "Darkmoon", order = 10, faction = "H", label = "Darkmoon: Cooking", frameID = "list2", color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "DMF: Cooking\n%sl\n - Vendor Lower Bluff", questID = 29509, profSID = 185, autoBuyShopping = false, shopping = {{ itemID = 30817, required = 20, buy = false }, }, },

	{key = "XPEV:Darkmoon11", event = "Darkmoon", order = 11, label = "Darkmoon: Enchanting", frameID = "list2", color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "DMF: Enchanting", questID = 29510, profSID = 333, },

	{key = "XPEV:Darkmoon12", event = "Darkmoon", order = 12, label = "Darkmoon: Engineering", frameID = "list2", color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "DMF: Engineering", questID = 29511, profSID = 202, },

	{key = "XPEV:Darkmoon13", event = "Darkmoon", order = 13, label = "Darkmoon: Fishing", frameID = "list2", color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "DMF: Fishing", questID = 29513, profSID = 356, },

	{key = "XPEV:Darkmoon14", event = "Darkmoon", order = 14, label = "Darkmoon: Herbalism", frameID = "list2", color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "DMF: Herbalism", questID = 29514, profSID = 182, },

	{key = "XPEV:Darkmoon15", event = "Darkmoon", order = 15, faction = "A", label = "Darkmoon: Inscription", frameID = "list2", color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "DMF: Inscription\n%sl\n - Vendor Outside Portal", questID = 29515, profSID = 773, autoBuyShopping = false, shopping = { { itemID = 39354, required = 10, buy = false }, }, },

	{key = "XPEV:Darkmoon16", event = "Darkmoon", order = 16, faction = "H", label = "Darkmoon: Inscription", frameID = "list2", color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "DMF: Inscription\n%sl\n - Vendor Thunder Bluff", questID = 29515, profSID = 773, autoBuyShopping = false, shopping = { { itemID = 39354, required = 10, buy = false }, }, },

	{key = "XPEV:Darkmoon17", event = "Darkmoon", order = 17, label = "Darkmoon: Jewelcrafting", frameID = "list2", color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "DMF: Jewelcrafting", questID = 29516, profSID = 755, },

	{key = "XPEV:Darkmoon18", event = "Darkmoon", order = 18, faction = "A", label = "Darkmoon: Leatherworking", frameID = "list2", color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "DMF: Leatherworking\n%sl\n - Vendor Outside Portal", questID = 29517, profSID = 165, autoBuyShopping = false, shopping = { { itemID = 6529, required = 10, buy = false }, { itemID = 2320, required = 5, buy = false }, { itemID = 6260, required = 10, buy = false }, }, },

	{key = "XPEV:Darkmoon19", event = "Darkmoon", order = 19, faction = "H", label = "Darkmoon: Leatherworking", frameID = "list2", color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "DMF: Leatherworking\n%sl\n - Vendor Thunder Bluff", questID = 29517, profSID = 165, autoBuyShopping = false, shopping = { { itemID = 6529, required = 10, buy = false }, { itemID = 2320, required = 5, buy = false }, { itemID = 6260, required = 10, buy = false }, }, },

	{key = "XPEV:Darkmoon20", event = "Darkmoon", order = 20, label = "Darkmoon: Mining", frameID = "list2", color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "DMF: Mining", questID = 29518, profSID = 186, },

	{key = "XPEV:Darkmoon21", event = "Darkmoon", order = 21, label = "Darkmoon: Skinning", frameID = "list2", color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "DMF: Skinning", questID = 29519, profSID = 393, },

	{key = "XPEV:Darkmoon22", event = "Darkmoon", order = 22, faction = "A", label = "Darkmoon: Tailoring", frameID = "list2", color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "DMF: Tailoring\n%sl\n - Vendor Outside Portal", questID = 29520, profSID = 197, autoBuyShopping = false, shopping = { { itemID = 2320, required = 6, buy = false }, { itemID = 2604, required = 6, buy = false }, { itemID = 6260, required = 6, buy = false }, }, },

	{key = "XPEV:Darkmoon23", event = "Darkmoon", order = 23, faction = "H", label = "Darkmoon: Tailoring", frameID = "list2", color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "DMF: Tailoring\n%sl\n - Vendor Thunder Bluff", questID = 29520, profSID = 197, autoBuyShopping = false, shopping = { { itemID = 2320, required = 6, buy = false }, { itemID = 2604, required = 6, buy = false }, { itemID = 6260, required = 6, buy = false }, }, },

	{key = "XPEV:Darkmoon24", event = "Darkmoon", order = 24, label = "Test Your Strength", frameID = "list2", playerLevel = { ">=", 20 }, color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "Test Your Strength", questID = 29433, hideDone = true, },

-- Darkmoon Faire Item Quests
	{key = "XPEV:Darkmoon25", event = "Darkmoon", order = 25, label = "A Treatise on Strategy", frameID = "list2", color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "A Treatise on Strategy", questID = 29451, hideDone = true, showIf = { itemID = 71715, includeBank = true }, },

	{key = "XPEV:Darkmoon26", event = "Darkmoon", order = 26, label = "Imbued Crystal", frameID = "list2", color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "Imbued Crystal", questID = 29443, hideDone = true, showIf = { itemID = 71635, includeBank = true }, },

	{key = "XPEV:Darkmoon27", event = "Darkmoon", order = 27, label = "Monstrous Egg", frameID = "list2", color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "Monstrous Egg", questID = 29444, hideDone = true, showIf = { itemID = 71636, includeBank = true }, },

	{key = "XPEV:Darkmoon28", event = "Darkmoon", order = 28, label = "Mysterious Grimoire", frameID = "list2", color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "Mysterious Grimoire", questID = 29445, hideDone = true, showIf = { itemID = 71637, includeBank = true }, },

	{key = "XPEV:Darkmoon29", event = "Darkmoon", order = 29, label = "Ornate Weapon", frameID = "list2", color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "Ornate Weapon", questID = 29446, hideDone = true, showIf = { itemID = 71638, includeBank = true }, },

	{key = "XPEV:Darkmoon30", event = "Darkmoon", order = 30, label = "Banner of the Fallen", frameID = "list2", color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "Banner of the Fallen", questID = 29456, hideDone = true, showIf = { itemID = 71951, includeBank = true }, },

	{key = "XPEV:Darkmoon31", event = "Darkmoon", order = 31, label = "Captured Insignia", frameID = "list2", color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "Captured Insignia", questID = 29457, hideDone = true, showIf = { itemID = 71952, includeBank = true }, },

	{key = "XPEV:Darkmoon32", event = "Darkmoon", order = 32, label = "Fallen Adventurer's Journal", frameID = "list2", color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "Fallen Adventurer's Journal", questID = 29458, hideDone = true, showIf = { itemID = 71953, includeBank = true }, },

	{key = "XPEV:Darkmoon33", event = "Darkmoon", order = 33, label = "Soothsayer's Runes", frameID = "list2", color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "Soothsayer's Runes", questID = 29464, hideDone = true, showIf = { itemID = 71716, includeBank = true }, },

	{key = "XPEV:Darkmoon34", event = "Darkmoon", order = 34, label = "Moonfang's Pelt", frameID = "list2", color = "b88fe6",
	aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "Moonfang's Pelt", questID = 33354, hideDone = true, showIf = { itemID = 105891, includeBank = true }, },

  -- Valentines

	{key = "XPEV:Valentines", event = "Valentines", order = 00, label = "Love is in the Air", frameID = "list2",
	aura = { eventKind = "calendar", keywords = { "Love is in the Air" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "Love is in the Air", font = "lsm:Bazooka", size = 22, color = "6b21a8", align = "center", hideDone = false, },

--	Midsummer Fire Festival

	{key = "XPEV:Midsummer00", event = "Midsummer", order = 00, label = "Midsummer Festival", frameID = "list2", resting = true,
	aura = { eventKind = "calendar", keywords = { "Midsummer Fire Festival" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
	questInfo = "M I D S U M M E R", font = "lsm:Bazooka", size = 24, color = "6b21a8", align = "center", hideDone = false, },

	{key = "XPEV:Midsummer01", group = "Midsummer", order = 00, label = "Midsummer Festival Token", frameID = "list2", resting = true,
	aura = { eventKind = "calendar", keywords = { "Midsummer Fire Festival" }, mustHave = true, rememberDaily = true },
	itemInfo = "Token", item = {itemID = 23247, required = {N,M,N,0}, indp = 1, }, font = "lsm:Bazooka", size = 16, color = "ffe633", align = "center", },

--	Children's Week
	{key = "XPEV:Child00",	event = "Children",	order = 00,																			label = "Children's Week", 					frameID = "list2",								font = "lsm:Bazooka", size = 18, color = "6b21a8", align = "center", questInfo = "Children's Week",		aura = { eventKind = "calendar", keywords = { "Children's Week" }, mustHave = true, rememberDaily = true }, },
--	Brewfest					-- use icon 7128724 for Brewfest popout above level 80 or until questID XX is completed
	{key = "XPEV:Brew00",	event = "Brewfest", order = 00, 																		label = "Brewfest",							frameID = "list2", resting = true, 				font = "lsm:Bazooka", size = 24, color = "6b21a8", align = "center", questInfo = "B R E W F E S T", 	aura = { eventKind = "calendar", keywords = { "Brewfest" }, includeHolidayText = true, mustHave = true, rememberDaily = true }, },
	{key = "XPEV:Brew01",	event = "Brewfest", order = 01,	item = {itemID = 37829, required = {N,M,N,0}, indp = 1,}, 				label = "Brewfest Tokens", 					frameID = "list2", 								font = "lsm:Bazooka", size = 15, color = "b88fe6", align = "center", itemInfo = "WB Tokens", 			aura = { eventKind = "calendar", keywords = { "Brewfest" }, includeHolidayText = true, mustHave = true, rememberDaily = true }, wbc=true, },
--	DireBrew Keg quest is once per event; hide both keg prompts after either faction quest is completed.
	{key = "XPEV:Brew02",	event = "Brewfest", order = 02, hideIfAnyQuestInLog = {12491,12492,}, 	playerLevel = {">=",30},		label = "DireBrew Keg Get",	restomg = true,	frameID = "list2",	hideQID = {12491,12492,},	font = "lsm:Bazooka", size = 15, color = "b88fe6", align = "center", questInfo = "Get Direbrew Keg",	aura = { eventKind = "calendar", keywords = { "Brewfest" }, includeHolidayText = true, mustHave = true, rememberDaily = true }, item = { itemID = {38280,38281,}, includeBank = true, showCount = false, required = { 1, Y, N, 0 }, }, },
	{key = "XPEV:Brew03",	event = "Brewfest", order = 03, hideIfAnyQuestInLog = {12491,12492,}, 	playerLevel = {">=",30},		label = "DireBrew Keg Use",	restomg = true,	frameID = "list2",	hideQID = {12491,12492,},	font = "lsm:Bazooka", size = 15, color = "b88fe6", align = "center", questInfo = "Use Direbrew Keg",	aura = { eventKind = "calendar", keywords = { "Brewfest" }, includeHolidayText = true, mustHave = true, rememberDaily = true }, item = { itemID = {38280,38281,}, mustHave = true, showCount = false, includeBank = true, }, },
	{questGroup = { questIDs = {12491,12492,},	status =
	{key = "XPEV:Brew04",	event = "Brewfest", order = 04, questID = 12491, requireInLog = false,	playerLevel = {">=",30},		label = "DireBrew Quest",					frameID = "list2",	hideDone = false,			font = "lsm:Bazooka", size = 15, color = "b88fe6", align = "center", 									aura = { eventKind = "calendar", keywords = { "Brewfest" }, includeHolidayText = true, mustHave = true, rememberDaily = true }, labelComplete = "DireBrew Done", }, children = {
	{key = "XPEV:Brew05",	event = "Brewfest", order = 05, questID = 12491, requireInLog = true,	playerLevel = {">=",30},		label = "DireBrew Quest A",	faction = "A",	frameID = "list2",	hideDone = true,			font = "lsm:Bazooka", size = 15, color = "b88fe6", align = "center", questInfo = "Deliver DireBrew Keg\nOutside Ironforge", },
	{key = "XPEV:Brew06",	event = "Brewfest", order = 06, questID = 12492, requireInLog = true,	playerLevel = {">=",30},		label = "DireBrew Quest H",	faction = "H",	frameID = "list2",	hideDone = true,			font = "lsm:Bazooka", size = 15, color = "b88fe6", align = "center", questInfo = "Deliver DireBrew Keg\nOutside Orgrimmar", }, }, } },
--	Pirate's Day
	{key = "XPEV:Pirate",	event = "Pirate",	order = 00,																			label = "Pirate's Day", 					frameID = "list2", 								font = "lsm:Bazooka", size = 20, color = "6b21a8", align = "center", questInfo = "Pirate's Day", 		aura = { eventKind = "calendar", keywords = { "Pirate's Day" }, includeHolidayText = true, mustHave = true, rememberDaily = true }, },
--	Harvest Festival
	{key = "XPEV:Harvest",	event = "Harvest",	order = 00,																			label = "Harvest Festival", resting = true, frameID = "list2", 								font = "lsm:Bazooka", size = 16, color = "6b21a8", align = "center", questInfo = "Harvest Festival", 	aura = { eventKind = "calendar", keywords = { "Harvest Festival" }, includeHolidayText = true, mustHave = true, rememberDaily = true }, },
-- Player vs Player Brawls
	{key = "XPEV:PVP-SSvTM", 									noAutoDisplay = true, playerLevel = { ">=", 20 }, 					label = "PvP SS vs TM", 	resting = true,	frameID = "list2", 								font = "lsm:Bazooka", size = 15, color = "E0115F", align = "center", questInfo = "PvP: SS vs TM",		aura = { eventKind = "calendar", keywords = { "PvP Brawl: Southshore vs. Tarren Mill" }, mustHave = true, rememberWeekly = true }, },
	{key = "XPEV:PVP-Ashran", 									noAutoDisplay = true, playerLevel = { ">=", 20 }, 					label = "PvP Ashran", 		resting = true,	frameID = "list2", 								font = "lsm:Bazooka", size = 15, color = "E0115F", align = "center", questInfo = "PvP: Ashran", 		aura = { eventKind = "calendar", keywords = { "PvP Brawl: Classic Ashran" }, mustHave = true, rememberWeekly = true }, },
	{key = "XPEV:PVP-Packed", 									noAutoDisplay = true, playerLevel = { ">=", 20 }, 					label = "PvP Packed House", resting = true,	frameID = "list2", 								font = "lsm:Bazooka", size = 15, color = "E0115F", align = "center", questInfo = "PvP: Packed House",	aura = { eventKind = "calendar", keywords = { "PvP Brawl: Packed House" }, mustHave = true, rememberWeekly = true }, },
	{key = "XPEV:PVP-DeepSix",									noAutoDisplay = true, playerLevel = { ">=", 20 }, 					label = "PvP Deep Six", 	resting = true,	frameID = "list2", 								font = "lsm:Bazooka", size = 15, color = "E0115F", align = "center", questInfo = "PvP: Deep Six",		aura = { eventKind = "calendar", keywords = { "PvP Brawl: Deep Six" }, mustHave = true, rememberWeekly = true },},


 

}
-- mapIDs: fUI_QTUsage.lua

bakedRules = ns.GuideHelpers.ExpandQuestGroups(bakedRules)
for i = 1, #bakedRules do
  local r = bakedRules[i]
	if type(r) == "table" and not r.questGroup then
    ns.GuideHelpers.NormalizeRule(r, EXPANSION_ID, EXPANSION_NAME)
    ns.rules[#ns.rules + 1] = r
  end
end
