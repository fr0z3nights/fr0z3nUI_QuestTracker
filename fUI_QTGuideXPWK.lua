local addonName, ns = ...

ns.rules = ns.rules or {}

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
--   %icd -> {itemCD} (remaining cooldown on rule.itemCD's item; line is dropped when ready)
--   $rq -> {currency:req}
--   $nm -> {currency:name}
--   $hv -> {currency} (gate/have amount)
--   $ga -> {currency} (gate/have amount)
--   $cc -> {currency:char}
--   $wb -> {currency:wb}


-- item.required tuple keys:
--   item.required = { count, hideWhenAcquired, autoBuyEnabled, autoBuyMax }
local REQ_COUNT, REQ_HIDE, REQ_BUY_ON, REQ_BUY_MAX = 1, 2, 3, 4
-- Rules define WHAT you want tracked.
-- Each rule can appear in a "bar" or a "list" frame (or both by duplicating the rule).
--
-- Fields:
--   questID (number?)          - quest to track; if set, hides when quest completes
--   display ("bar"|"list")     - default routing (used if no explicit frame target)
--   frameID (string?)          - route ONLY to this frame id (e.g. "bar1" or "list1")
--   targets (string[]?)        - route to multiple frame ids
--   hideMapID (number/table?)  - hide while on any listed map
--   label (string?)            - override label (otherwise uses quest title)
--   hideDone (boolean?) - default true; set false to keep showing when completed
--   labelComplete (string?)    - optional label override when completed
--   extraComplete (string?)    - optional extra override when completed (e.g. "X")
--   XDone (boolean?) - convenience; if true, shows "X" when completed (unless extraComplete is set)
--   prereq (number[]?)         - only show once these quests are completed
--   requireInLog (boolean?)    - if true, only show while the quest is in your quest log
--   group (string?)            - sequential group; only lowest-order active rule shows per frame
--   order (number?)            - used within group; lower shows first
--   sortGO (table?)            - Rules-tab display order shorthand: { sortGroup, sortOrder }
--   pad (number?)              - extra pixels of space after this row in list frames (-10..50)
--   itemCD (number?)           - itemID whose remaining cooldown fills %icd / {itemCD};
--                                shared itemIDs only print the timer on the first matching rule
--   levelGate ("max"|"leveling"?) - optionally show only at max level or only while leveling
--   indicators (table[]?)      - append small red/green glyphs after the row (for "done" markers)
--       questID (number?)      - completion source: quest completed
--       questIDs (number[]?)   - completion source: any quest completed in list
--       itemID (number?)       - completion source: have item count
--       itemIDs (number[]?)    - completion source: have ANY item in list
--       count (number?)        - required count for itemID (default 1)
--       aura (table?)          - completion source: aura present
--           spellID (number)
--       shape ("square"|"circle"?) - default "square"
--       overlay (table?)       - optional overlay drawn on top of the indicator (e.g. a "1")
--           text (string)      - overlay text
--           color (table?)     - overlay text color {r,g,b[,a]}
--           questID/questIDs/itemID/itemIDs/aura/count/required - condition for overlay visibility
--       onlyWhenDone (boolean?) - if true, indicator only renders when condition is met
--       faction ("Alliance"|"Horde"?) - optional faction gate for that indicator
--   item (table?)              - item-based tracking gate/progress
--       itemID (number)
--       required (number?)     - display count/required if provided
--       mustHave (boolean?)    - if true, only show when count > 0
--   progress (table?)          - progress display helpers
--       objectiveIndex (number?) - show quest objective progress like "1/5"
--   aura (table?)              - aura gate (Timewalking etc)
--       spellID (number)
--       mustHave (boolean?)    - if true, only show when aura is present
--       rememberWeekly (boolean?) - if true, remembers the aura "active" until weekly reset once seen
--       rememberDaily (boolean?) - if true, remembers the aura "active" until daily reset once seen
--   complete (table?)          - extra completion logic; when satisfied, the rule hides
--       questID (number?)
--       item (table?)
--           itemID (number)
--           count (number?)
--       profession (number|string?) - skillLineID or profession name
--       aura (table?)
--           spellID (number)
--           mustHave (boolean?)
--
-- Examples below are placeholders; replace with your real questIDs/items/auras.

local EXPANSION_ID = -1
local EXPANSION_NAME = "Weekly"

local bakedRules = {





	{key = "XPEV:Q-PetBtl",						requireInLog = false,	playerLevel = {">=",20},	label = "Event: Pet Battle",		frameID = "bar1",	hideDone = false,										XDone = true,		questInfo = "Pet XP",																									 pad = 3,	aura = { eventKind = "calendar", keywords = { "Pet Battle Bonus Event" }, mustHave = true, rememberWeekly = true }, },
	{key = "XPEV:Q-93595",	questID = 93595,	requireInLog = false,	playerLevel = {">=",80},	label = "Event: Delves",			frameID = "list2",	hideDone = true,	progress = { objectiveIndex = 1 },	XDone = true,		questInfo = "Delves",				font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top",	pad = 3,	aura = { eventKind = "calendar", keywords = { "Delves Bonus Event" }, mustHave = true, rememberWeekly = true }, },
	{key = "XPEV:Q-93606",	questID = 93593,	requireInLog = false,	playerLevel = {">=",80},	label = "Event: Battleground",		frameID = "bar1",	hideDone = true,	progress = { objectiveIndex = 1 },  XDone = true,		questInfo = "PVP BG",																												aura = { eventKind = "calendar", keywords = { "Battleground Bonus Event" }, mustHave = true, rememberWeekly = true }, },
	{key = "XPEV:Q-93605",	questID = 93605,	requireInLog = false,	playerLevel = { "=",90},	label = "Event: World Quest",		frameID = "list2",	hideDone = true,	progress = { objectiveIndex = 1 },	XDone = true,		questInfo = "World Quest %p\n$icd",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top",	pad = 3, aura = { eventKind = "calendar", keywords = { "World Quest Bonus Event" }, mustHave = true, rememberWeekly = true }, itemCD = 230850, },

--	Timewalking weekly bar entries. -- Goal: calendar strings can be generic ("Timewalking Dungeon Event"), so we: --   1) show a single generic reminder when any Timewalking/Turbulent Timeways event is up   --   2) show the specific weekly quest row only once you've actually picked it up (requireInLog)   -- Keep showing after completion, and show "X" when complete.   -- Append a red/green marker for the token quest completion.
	{key = "tw:reminder",																			label = "TW Reminder", 				frameID = "bar1",	hideDone = false,	preferQuestInfoForTitle = true,							questInfo = "Timewalking",			hideIfRememberedTimewalkingKind = true, aura = { eventKind = "timewalking", mustHave = true, rememberWeekly = true }, 
	hideIfAnyQuestInLog =     {85947, 93607,   85948, 93608,   85949, 93610,   86556, 93611,   86560, 93612,   86563, 93613,   86564, 93614,   88808, 93627,   92647, 93628,   93495, 93497},
	hideQID =                 {85947, 93607,   85948, 93608,   85949, 93610,   86556, 93611,   86560, 93612,   86563, 93613,   86564, 93614,   88808, 93627,   92647, 93628,   93495, 93497}, },
--	                              CLASSIC        OUTLAND          WRATH         CATACLYSM        PANDARIA        DRAENOR          LEGION          BATTLE       SHADOWLANDS     DRGONFLIGHT
--  	                       LVL  01  MAX    LVL  02  MAX    LVL  03  MAX    LVL  04  MAX    LVL  05  MAX    LVL  06  MAX    LVL  07  MAX    LVL  08  MAX    LVL  09  MAX    LVL  10  MAX
--																UPDATE REMINDER ABOVE & XRULESDB & GOTALKEV & IN GAME WoW2 FQT ORDER WHEN UPDATING QUESTID
--	01  Classic
	{key = "XPTW:01-LVL",	questID = 85947,	requireInLog = true,	sortGO = {"XP01:TW",1},		label = "TW Classic LVL",			frameID = "bar1",	hideDone = false,	progress = { objectiveIndex = 1 },	XDone = true,		questInfo = "Classic",				list = "last", levelGate = "LVL",	twKind = "classic", showIfRememberedTimewalkingKind = true, },
	{key = "XPTW:01-MAX",	questID = 93607,	requireInLog = true,	sortGO = {"XP01:TW",2},		label = "TW Classic MAX", 			frameID = "bar1",	hideDone = false,	progress = { objectiveIndex = 1 },	XDone = true,		questInfo = "Classic",				list = "last", levelGate = "MAX",	twKind = "classic", showIfRememberedTimewalkingKind = true, },
	{key = "XPTW:01-TKN",	fallbackQuestInLog = { 83285 }, 			sortGO = {"XP01:TW",3},		label = "TW Classic TKN",			frameID = "bar1",	hideDone = false, 	preferQuestInfoForTitle = true, 						questInfo = "\194\160",				list = "last",						twKind = "classic", requireRememberedTimewalkingKind = true,	indicators = { { questID = 83285, shape = "square", overlay = { itemIDs = { 225348 }, text = "1", color = { 1.0, 1.0, 0.1 } }, }, }, },
--	02  Outland
	{key = "XPTW:02-LVL",	questID = 85948,	requireInLog = true,	sortGO = {"XP02:TW",1},		label = "TW Outland LVL", 			frameID = "bar1",	hideDone = false,	progress = { objectiveIndex = 1 },	XDone = true,		questInfo = "Outland",				list = "last", levelGate = "LVL",	twKind = "outland", showIfRememberedTimewalkingKind = true, },
	{key = "XPTW:02-MAX",	questID = 93608,	requireInLog = true,	sortGO = {"XP02:TW",2},		label = "TW Outland MAX",			frameID = "bar1",	hideDone = false,	progress = { objectiveIndex = 1 },	XDone = true,		questInfo = "Outland",				list = "last", levelGate = "MAX",	twKind = "outland", showIfRememberedTimewalkingKind = true, },
	{key = "XPTW:02-TKN",	fallbackQuestInLog = { 40168 },				sortGO = {"XP02:TW",3},		label = "TW Outland TKN",			frameID = "bar1",	hideDone = false,	preferQuestInfoForTitle = true,							questInfo = "\194\160",				list = "last", 						twKind = "outland", requireRememberedTimewalkingKind = true,	indicators = { { questID = 40168, shape = "square", overlay = { itemIDs = { 129747 }, text = "1", color = { 1.0, 1.0, 0.1 } }, }, }, },
--	03  Wrath
	{key = "XPTW:03-LVL",	questID = 85949,	requireInLog = true,	sortGO = {"XP03:TW",1},		label = "TW Wrath LVL",				frameID = "bar1",	hideDone = false,	progress = { objectiveIndex = 1 },	XDone = true,		questInfo = "Wrath",				list = "last", levelGate = "LVL",	twKind = "wrath", showIfRememberedTimewalkingKind = true, },
	{key = "XPTW:03-MAX",	questID = 93610,	requireInLog = true,	sortGO = {"XP03:TW",2},		label = "TW Wrath MAX",				frameID = "bar1",	hideDone = false,	progress = { objectiveIndex = 1 },	XDone = true,		questInfo = "Wrath",				list = "last", levelGate = "MAX",	twKind = "wrath", showIfRememberedTimewalkingKind = true, },
	{key = "XPTW:03-TKN",	fallbackQuestInLog = { 40173 },				sortGO = {"XP03:TW",3},		label = "TW Wrath TKN",				frameID = "bar1",	hideDone = false,	preferQuestInfoForTitle = true,							questInfo = "\194\160",				list = "last",						twKind = "wrath", requireRememberedTimewalkingKind = true,	indicators = { { questID = 40173, shape = "square", overlay = { itemIDs = { 129928 }, text = "1", color = { 1.0, 1.0, 0.1 } }, }, }, },
--	04  Cataclysm
	{key = "XPTW:04-LVL",	questID = 86556,	requireInLog = true,	sortGO = {"XP04:TW",1},		label = "TW Cataclysm LVL",			frameID = "bar1",	hideDone = false,	progress = { objectiveIndex = 1 },	XDone = true,		questInfo = "Cataclysm",			list = "last", levelGate = "LVL",	twKind = "cata", showIfRememberedTimewalkingKind = true, },
	{key = "XPTW:04-MAX",	questID = 93611,	requireInLog = true,	sortGO = {"XP04:TW",2},		label = "TW Cataclysm MAX",			frameID = "bar1",	hideDone = false,	progress = { objectiveIndex = 1 },	XDone = true,		questInfo = "Cataclysm",			list = "last", levelGate = "MAX",	twKind = "cata", showIfRememberedTimewalkingKind = true, },
	{key = "XPTW:04-TKN",	fallbackQuestInLog = { 40787, 40786 },		sortGO = {"XP04:TW",3},		label = "TW Cataclysm TKN",			frameID = "bar1",	hideDone = false,	preferQuestInfoForTitle = true,							questInfo = "\194\160",				list = "last",						twKind = "cata", requireRememberedTimewalkingKind = true,	indicators = { { questIDs = { 40787, 40786 }, shape = "square", overlay = { itemIDs = { 133377,133378 }, text = "1", color = { 1.0, 1.0, 0.1 } }, }, }, },
--  05  Pandaria
	{key = "XPTW:05-LVL",	questID = 86560,	requireInLog = true,	sortGO = {"XP05:TW",1},		label = "TW Pandaria LVL",			frameID = "bar1",	hideDone = false,	progress = { objectiveIndex = 1 },	XDone = true,		questInfo = "Pandaria",				list = "last", levelGate = "LVL",	twKind = "pandaria", showIfRememberedTimewalkingKind = true, },
	{key = "XPTW:05-MAX",	questID = 93612,	requireInLog = true,	sortGO = {"XP05:TW",2},		label = "TW Pandaria MAX",			frameID = "bar1",	hideDone = false,	progress = { objectiveIndex = 1 },	XDone = true,		questInfo = "Pandaria",				list = "last", levelGate = "MAX",	twKind = "pandaria", showIfRememberedTimewalkingKind = true, },
	{key = "XPTW:05-TKN",	fallbackQuestInLog = { 45563 },				sortGO = {"XP05:TW",3},		label = "TW Pandaria TKN",			frameID = "bar1",	hideDone = false,	preferQuestInfoForTitle = true,							questInfo = "\194\160",				list = "last",						twKind = "pandaria", requireRememberedTimewalkingKind = true, indicators = { { questID = 45563, shape = "square", overlay = { itemIDs = { 143776 }, text = "1", color = { 1.0, 1.0, 0.1 } }, }, }, },
	{key = "XPTW:05-JMP",	questID = 33231,														label = "TW Pandaria JMP",			frameID = "list1",	hideDone = true,	questInfo = "Jump to Timeless Isle\n + Click to Load Zygor\n - Go To Eternal Blozzoms\n - Chromie on Balcony\n - Quest Abandon Enabled",	list = "top",	twKind = "pandaria", requireRememberedTimewalkingKind = true, showIf = { questInLogIDs = {86560,45563} }, hideMapID = {554}, zygor = { "DAILIES\\Mists of Pandaria Dailies\\Timeless Isle Dailies", 0, 0, 3 }, complete = { any = { { itemIDs = { 103678, 219222 }, includeBank = false }, }, },},
--	06  Draenor
	{key = "XPTW:06-LVL",	questID = 86563,	requireInLog = true,	sortGO = {"XP06:TW",1},		label = "TW Draenor LVL",			frameID = "bar1",	hideDone = false,	progress = { objectiveIndex = 1 },	XDone = true,		questInfo = "Draenor",				list = "last", levelGate = "LVL",	twKind = "draenor", showIfRememberedTimewalkingKind = true, },
	{key = "XPTW:06-MAX",	questID = 93613,	requireInLog = true,	sortGO = {"XP06:TW",2},		label = "TW Draenor MAX",			frameID = "bar1",	hideDone = false,	progress = { objectiveIndex = 1 },	XDone = true,		questInfo = "Draenor",				list = "last", levelGate = "MAX",	twKind = "draenor", showIfRememberedTimewalkingKind = true, },
	{key = "XPTW:06-TKN",	fallbackQuestInLog = { 55498, 55499 },		sortGO = {"XP06:TW",3},		label = "TW Draenor TKN",			frameID = "bar1",	hideDone = false,	preferQuestInfoForTitle = true,							questInfo = "\194\160",				list = "last",						twKind = "draenor", requireRememberedTimewalkingKind = true,	indicators = { { questIDs = { 55498, 55499 }, shape = "square", overlay = { itemIDs = { 167921, 167922 }, text = "1", color = { 1.0, 1.0, 0.1 } }, }, }, },
--	07  Legion
	{key = "XPTW:07-LVL",	questID = 86564,	requireInLog = true,	sortGO = {"XP07:TW",1},		label = "TW Legion LVL",			frameID = "bar1",	hideDone = false,	progress = { objectiveIndex = 1 },	XDone = true,		questInfo = "Legion",				list = "last", levelGate = "LVL",	twKind = "legion", showIfRememberedTimewalkingKind = true, },
	{key = "XPTW:07-MAX",	questID = 93614,	requireInLog = true,	sortGO = {"XP07:TW",2},		label = "TW Legion MAX",			frameID = "bar1",	hideDone = false,	progress = { objectiveIndex = 1 },	XDone = true,		questInfo = "Legion",				list = "last", levelGate = "MAX",	twKind = "legion", showIfRememberedTimewalkingKind = true, },
	{key = "XPTW:07-TKN",	fallbackQuestInLog = { 64710 },				sortGO = {"XP07:TW",3},		label = "TW Legion TKN",			frameID = "bar1",	hideDone = false,	preferQuestInfoForTitle = true,							questInfo = "\194\160",				list = "last",						twKind = "legion", requireRememberedTimewalkingKind = true,	indicators = { { questID = 64710, shape = "square", overlay = { itemIDs = { 187611 }, text = "1", color = { 1.0, 1.0, 0.1 } }, }, }, },
--	08  Battle
	{key = "XPTW:08-LVL",	questID = 88808,	requireInLog = true,	sortGO = {"XP08:TW",1},		label = "TW Battle LVL",			frameID = "bar1",	hideDone = false,	progress = { objectiveIndex = 1 },	XDone = true,		questInfo = "Battle",				list = "last", levelGate = "LVL",	twKind = "bfa", showIfRememberedTimewalkingKind = true, },
	{key = "XPTW:08-MAX",	questID = 93627,	requireInLog = true,	sortGO = {"XP08:TW",2},		label = "TW Battle MAX",			frameID = "bar1",	hideDone = false,	progress = { objectiveIndex = 1 },	XDone = true,		questInfo = "Battle",				list = "last", levelGate = "MAX",	twKind = "bfa", showIfRememberedTimewalkingKind = true, },
	{key = "XPTW:08-TKN",	fallbackQuestInLog = { 89222, 89223 },		sortGO = {"XP08:TW",3},		label = "TW Battle TKN",			frameID = "bar1",	hideDone = false,	preferQuestInfoForTitle = true,							questInfo = "\194\160",				list = "last",						twKind = "bfa", requireRememberedTimewalkingKind = true,	indicators = { { questIDs = { 89222, 89223 }, shape = "square", overlay = { itemIDs = { 238790, 238791 }, text = "1", color = { 1.0, 1.0, 0.1 } }, }, }, },
--	09  Shadowlands
	{key = "XPTW:09-LVL",	questID = 92647,	requireInLog = true,	sortGO = {"XP09:TW",1},		label = "TW Shadowlands LVL",		frameID = "bar1",	hideDone = false,	progress = { objectiveIndex = 1 },	XDone = true,		questInfo = "Shadowlands",			list = "last", levelGate = "LVL",	twKind = "shadowlands", showIfRememberedTimewalkingKind = true, },
	{key = "XPTW:09-MAX",	questID = 93628,	requireInLog = true,	sortGO = {"XP09:TW",2},		label = "TW Shadowlands MAX",		frameID = "bar1",	hideDone = false,	progress = { objectiveIndex = 1 },	XDone = true,		questInfo = "Shadowlands",			list = "last", levelGate = "MAX",	twKind = "shadowlands", showIfRememberedTimewalkingKind = true, },
	{key = "XPTW:09-TKN",	fallbackQuestInLog = { 92650 },				sortGO = {"XP09:TW",3},		label = "TW Shadowlands TKN",		frameID = "bar1",	hideDone = false,	preferQuestInfoForTitle = true,							questInfo = "\194\160",				list = "last",						twKind = "shadowlands", requireRememberedTimewalkingKind = true,	indicators = { { questID = 92650, shape = "square", overlay = { itemIDs = { 253517 }, text = "1", color = { 1.0, 1.0, 0.1 } }, }, }, },
--	10  Dragonflight
	{key = "XPTW:10-LVL",	questID = 93495,	requireInLog = true,	sortGO = {"XP10:TW",1},		label = "TW Dragonflight LVL",		frameID = "bar1",	hideDone = false,	progress = { objectiveIndex = 1 },	XDone = true,		questInfo = "Dragonflight",			list = "last", levelGate = "LVL",	twKind = "dragonflight", showIfRememberedTimewalkingKind = true, },
	{key = "XPTW:10-MAX",	questID = 93497,	requireInLog = true,	sortGO = {"XP10:TW",2},		label = "TW Dragonflight MAX",		frameID = "bar1",	hideDone = false,	progress = { objectiveIndex = 1 },	XDone = true,		questInfo = "Dragonflight",			list = "last", levelGate = "MAX",	twKind = "dragonflight", showIfRememberedTimewalkingKind = true, },
	{key = "XPTW:10-TKN",	fallbackQuestInLog = { 93852 },				sortGO = {"XP10:TW",3},		label = "TW Dragonflight TKN",		frameID = "bar1",	hideDone = false,	preferQuestInfoForTitle = true,							questInfo = "\194\160",				list = "last",						twKind = "dragonflight", requireRememberedTimewalkingKind = true,	indicators = { { questID = 93852, shape = "square", overlay = { itemIDs = { 262918 }, text = "1", color = { 1.0, 1.0, 0.1 } }, }, }, },


--	USERS NOTES ONLY
	--	Update when Khaz Algar Timewalking comes out
	--	- Update Timewalking in QuestTracker for War Within Timewalking
	--	- Update Timewalking in DateTime for War Within Timewalking events
	--	- Aura:       
	--	- Calendar:   War Within Timewalking
	--	- LFD ID:     3305
	--	- Not sure what else is needed?


--	Kalimdor Pet Battles						Horde Only								w/ Zygor Guide Click																														zygor = { "Guide\\Title", zygorTT, zygorX, zygorStep }
	{key = "XPPB:Q-31818",	questID = 31818,	charLI = "Bullseyeshot-Caelestrasz",	label = "PB H Zunta",					frameID = "list2",	hideDone = true,	questInfo = "Zunta\nDurotar",								zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,  97 }, faction = "H",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31819",	questID = 31819,	charLI = "Shadowswings-Barthilas",		label = "PB H Dagra the Fierce",		frameID = "list2",	hideDone = true,	questInfo = "Dagra the Fierce\nNorthern Barrens",			zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1, 100 }, faction = "H",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31905",	questID = 31905,	charLI = "Shadowizards-Caelestrasz",	label = "PB H Grazzle the Great",		frameID = "list2",	hideDone = true,	questInfo = "Grazzle the Great\nDustwallow",				zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1, 130 }, faction = "H",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31906",	questID = 31906,	charLI = "Shadowzdeath-Barthilas",		label = "PB H Kela Grimtotem",			frameID = "list2",	hideDone = true,	questInfo = "Kela Grimtotem\nThousand Needles",				zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1, 124 }, faction = "H",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31904",	questID = 31904,	charLI = "Frozenflamed-Caelestrasz",	label = "PB H Cassy Kaboom",			frameID = "list2",	hideDone = true,	questInfo = "Cassy Kaboom\nSouthern Barrens",				zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1, 127 }, faction = "H",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31871",	questID = 31871,	charLI = "Shadowsmashr-Barthilas",		label = "PB H Traitor Gluk",			frameID = "list2",	hideDone = true,	questInfo = "Traitor Gluk\nFeralas",						zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1, 121 }, faction = "H",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31872",	questID = 31872,	charLI = "Frozenlegion-Barthilas",		label = "PB H Merda Stronghoof",		frameID = "list2",	hideDone = true,	questInfo = "Merda Stronghoof\nDesolace",					zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1, 118 }, faction = "H",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31862",	questID = 31862,	charLI = "Shadowardenz-Caelestrasz",	label = "PB H Zonya the Patient",		frameID = "list2",	hideDone = true,	questInfo = "Zonya the Patient\nStonetalon Mtn",			zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1, 115 }, faction = "H",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31854",	questID = 31854,	charLI = "Shadowarlord-Barthilas",		label = "PB H Analynn",					frameID = "list2",	hideDone = true,	questInfo = "Analynn\nAshenvale",							zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1, 112 }, faction = "H",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31907",	questID = 31907,	charLI = "Frozenfrosti-Caelestrasz",	label = "PB H Zoltan",					frameID = "list2",	hideDone = true,	questInfo = "Zoltan\nFelwood",								zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1, 109 }, faction = "H",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31908",	questID = 31908,	charLI = "Shadowyclawz-Barthilas",		label = "PB H Elena Flutterfly",		frameID = "list2",	hideDone = true,	questInfo = "Elena Flutterfly\nMoonglade",					zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1, 106 }, faction = "H",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31909",	questID = 31909,	charLI = "Bullseyekick-Caelestrasz",	label = "PB H Stone Cold Trixxy",		frameID = "list2",	hideDone = true,	questInfo = "Stone Cold Trixxy\nWinterspring",				zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1, 103 }, faction = "H",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
--	Eastern Kingdoms Pet Battles		 		Alliance Only							w/ Zygor Guide Click																														zygor = { "Guide\\Title", zygorTT, zygorX, zygorStep }
	{key = "XPPB:Q-31693",	questID = 31693,	charLI = "Shadowardenz-Frostmourne",	label = "PB A Julia Stevens",			frameID = "list2",	hideDone = true,	questInfo = "Julia Stevens\nElwynn Forest",					zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,   3 }, faction = "A",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31780",	questID = 31780,	charLI = "Frozenlegion-Dath'Remar",		label = "PB A Old MacDonald",			frameID = "list2",	hideDone = true,	questInfo = "Old MacDonald\nWestfall",						zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,   6 }, faction = "A",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31850",	questID = 31850,	charLI = "Shadowarlord-Dath'Remar",		label = "PB A Duskwood",				frameID = "list2",	hideDone = true,	questInfo = "Eric Davidson\nDuskwood",						zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,   9 }, faction = "A",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31852",	questID = 31852,	charLI = "Frozenfrosti-Frostmourne",	label = "PB A Steven Lisbane",			frameID = "list2",	hideDone = true,	questInfo = "Steven Lisbane\nNorth Stranglethorn",			zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,  12 }, faction = "A",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31851",	questID = 31851,	charLI = "Shadowyclawz-Dath'Remar",		label = "PB A Bill Buckler",			frameID = "list2",	hideDone = true,	questInfo = "Bill Buckler\nCape Stranglethorn",				zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,  15 }, faction = "A",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31916",	questID = 31916,	charLI = "Bullseyekick-Frostmourne",	label = "PB A Lydia Accoste",			frameID = "list2",	hideDone = true,	questInfo = "Lydia Accoste\nDeadwind Pass",					zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,  18 }, faction = "A",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31913",	questID = 31913,	charLI = "Bullseyeshot-Dath'Remar",		label = "PB A Everessa",				frameID = "list2",	hideDone = true,	questInfo = "Everessa\nSwamp of Sorrows",					zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,  21 }, faction = "A",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31781",	questID = 31781,	charLI = "Shadowswings-Frostmourne",	label = "PB A Lindsay",					frameID = "list2",	hideDone = true,	questInfo = "Lindsay\nRedridge Mountains",					zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,  24 }, faction = "A",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31914",	questID = 31914,	charLI = "Shadowizards-Dath'Remar",		label = "PB A Durin Darkhammer",		frameID = "list2",	hideDone = true,	questInfo = "Durin Darkhammer\nBurning Steppes",			zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,  27 }, faction = "A",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31912",	questID = 31912,	charLI = "Shadowzdeath-Frostmourne",	label = "PB A Kortas Darkhammer",		frameID = "list2",	hideDone = true,	questInfo = "Kortas Darkhammer\nSearing Gorge",				zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,  30 }, faction = "A",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31910",	questID = 31910,	charLI = "Frozenflamed-Dath'Remar",		label = "PB A David Kosse",				frameID = "list2",	hideDone = true,	questInfo = "David Kosse\nHinterlands",						zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,  33 }, faction = "A",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31911",	questID = 31911,	charLI = "Shadowsmashr-Frostmourne",	label = "PB A Deiza Plaguehorn",		frameID = "list2",	hideDone = true,	questInfo = "Deiza Plaguehorn\nEast Plaguelands",			zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,  36 }, faction = "A",	font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
--	Outland Pet Battles							Alliance / Horde						w/ Zygor Guide Click																														zygor = { "Guide\\Title", zygorTT, zygorX, zygorStep }
	{key = "XPPB:Q-31922",	questID = 31922,	charLI = "Bullseyeshot-Barthilas",		label = "PB N Nicki Tinytech",			frameID = "list2",	hideDone = true,	questInfo = "Nicki Tinytech\nHellfire, Outland",			zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,{ 42,136} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31923",	questID = 31923,	charLI = "Shadowizards-Barthilas",		label = "PB N Ras'an",					frameID = "list2",	hideDone = true,	questInfo = "Ras'an\nZangarmarsh, Outland",					zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,{ 45,145} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31924",	questID = 31924,	charLI = "Frozenlegion-Frostmourne",	label = "PB N Narrok",					frameID = "list2",	hideDone = true,	questInfo = "Narrok\nNagrand, Outland",						zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,{ 48,142} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31925",	questID = 31925,	charLI = "Shadowardenz-Dath'Remar",		label = "PB N Morulu The Elder",		frameID = "list2",	hideDone = true,	questInfo = "Morulu The Elder\nShattrath, Outland",			zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,{ 51,139} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31926",	questID = 31926,	charLI = "Shadowswings-Caelestrasz",	label = "PB N Bloodknight Antari",		frameID = "list2",	hideDone = true,	questInfo = "Bloodknight Antari\nShadowmoon, Outland",		zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,{ 54,148} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
--	Northrend Pet Battles						Alliance / Horde						w/ Zygor Guide Click																														zygor = { "Guide\\Title", zygorTT, zygorX, zygorStep }
	{key = "XPPB:Q-31934",	questID = 31934,	charLI = "Shadowyclawz-Frostmourne",	label = "PB N Gutretch",				frameID = "list2",	hideDone = true,	questInfo = "Gutretch\nZul'Drak",							zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,{ 69,160} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31932",	questID = 31932,	charLI = "Shadowsmashr-Caelestrasz",	label = "PB N Nearly Headless Jacob",	frameID = "list2",	hideDone = true,	questInfo = "Nearly Headless Jacob\nCrystalsong Forest",	zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,{ 63,157} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31935",	questID = 31935,	charLI = "Bullseyekick-Dath'Remar",		label = "PB N Major Payne",				frameID = "list2",	hideDone = true,	questInfo = "Major Payne\nIcecrown",						zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,{ 66,163} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31933",	questID = 31933,	charLI = "Bullseyeshot-Frostmourne",	label = "PB N Okrut Dragonwaste",		frameID = "list2",	hideDone = true,	questInfo = "Okrut Dragonwaste\nDragonblight",				zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,{ 60,154} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31931",	questID = 31931,	charLI = "Frozenlegion-Caelestrasz",	label = "PB N Beegle Blastfuse",		frameID = "list2",	hideDone = true,	questInfo = "Beegle Blastfuse\nHowling Fjord",				zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,{ 57,151} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
--	Cataclysm Pet Battles						Alliance / Horde						W/ Zygor Guide Click																														zygor = { "Guide\\Title", zygorTT, zygorX, zygorStep }
	{key = "XPPB:Q-31972",	questID = 31972,	charLI = "Shadowarlord-Frostmourne",	label = "PB N Brok",					frameID = "list2",	hideDone = true,	questInfo = "Brok\nMount Hyjal",							zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,{ 72,166} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31973",	questID = 31973,	charLI = "Shadowzdeath-Caelestrasz",	label = "PB N Bordin Steadyfist",		frameID = "list2",	hideDone = true,	questInfo = "Bordin Steadyfist\nDeepholm",					zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,{ 75,169} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31974",	questID = 31974,	charLI = "Frozenfrosti-Dath'Remar",		label = "PB N Goz Banefury",			frameID = "list2",	hideDone = true,	questInfo = "Goz Banefury\nTwilight Highlands",				zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,{ 78,172} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31971",	questID = 31971,	charLI = "Frozenflamed-Barthilas",		label = "PB N Obalis",					frameID = "list2",	hideDone = true,	questInfo = "Obalis\nUldum",								zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,{ 81,175} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
--	Pandaria Pet Battle							sAlliance / Horde						W/ Zygor Guide Click																														zygor = { "Guide\\Title", zygorTT, zygorX, zygorStep }
	{key = "XPPB:Q-31953",	questID = 31953,	charLI = "Shadowildlif-Dath'Remar",		label = "PB N Hyuna of the Shrines",	frameID = "list2",	hideDone = true,	questInfo = "Hyuna of the Shrines\nJade Forest, Pandaria",	zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,{ 84,178} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31958",	questID = 31958,	charLI = "Shadowarrant-Barthilas",		label = "PB N Aki the Chosen",			frameID = "list2",	hideDone = true,	questInfo = "Aki the Chosen\nEternal Vale, Pandaria",		zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,{ 87,196} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31956",	questID = 31956,	charLI = "Shadowspiner-Frostmourne",	label = "PB N Courageous Yon",			frameID = "list2",	hideDone = true,	questInfo = "Courageous Yon\nKun-Lai, Pandaria",			zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,{ 90,187} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31991",	questID = 31991,	charLI = "Shadowildlif-Caelestrasz",	label = "PB N Zusshi",					frameID = "list2",	hideDone = true,	questInfo = "Seeker Zusshi\nTownlong, Pandaria",			zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,{ 93,190} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31957",	questID = 31957,	charLI = "Shadowarrant-Dath'Remar",		label = "PB N Wastewalker Shu",			frameID = "list2",	hideDone = true,	questInfo = "Wastewalker Shu\nDreadwaste, Pandaria",		zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,{ 96,193} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31954",	questID = 31954,	charLI = "Shadowarrant-Frostmourne",	label = "PB N Mo'ruk",					frameID = "list2",	hideDone = true,	questInfo = "Mo'ruk\nKrasarang, Pandaria",					zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,{ 99,184} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-31955",	questID = 31955,	charLI = "Shadowildlif-Barthilas",		label = "PB N Farmer Nishi",			frameID = "list2",	hideDone = true,	questInfo = "Farmer Nishi\nFour Winds, Pandaria",			zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Battle Pet Dailies",     0,1,{102,181} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-32439",	questID = 32439,	charLI = "Shadowwaning-Barthilas",		label = "PB N Flowing Spirit",			frameID = "list2",	hideDone = true,	questInfo = "Flowing Spirit\nDreadwaste, Pandaria",			zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Beasts of Fable Dailies",0,1,{  7,  7} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-32434",	questID = 32434,	charLI = "Shadowreckge-Caelestrasz",	label = "PB N Burning Spirit",			frameID = "list2",	hideDone = true,	questInfo = "Burning Spirit\nTownlong, Pandaria",			zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Beasts of Fable Dailies",0,1,{ 13, 13} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-32441",	questID = 32441,	charLI = "Shadowreckge-Barthilas",		label = "PB N Thundering Spirit",		frameID = "list2",	hideDone = true,	questInfo = "Thundering Spirit\nEternal Vale, Pandaria",	zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Beasts of Fable Dailies",0,1,{ 18, 18} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-32440",	questID = 32440,	charLI = "Shadowwaning-Dath'Remar",		label = "PB N Whispering Spirit",		frameID = "list2",	hideDone = true,	questInfo = "Whispering Spirit\nJade Forest, Pandaria",		zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Beasts of Fable Dailies",0,1,{ 23, 23} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-32604T",						charLI = "NOONEYETNAMED-Frostmourne",	label = "PB N Beasts of Fable",			frameID = "list2",	hideDone = true,	questInfo = "Fable Beast, Pandaria",						zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Beasts of Fable Dailies",0,1,{  1,  1} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", hideQID = {{32604},{32868},{32869}}, },
	{key = "XPPB:Q-32604",	questID = 32604,	charLI = "NOONEYETNAMED-Frostmourne",	label = "PB N Beasts of Fable I",		frameID = "list2",	hideDone = true,	questInfo = "  - Book I",									zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Beasts of Fable Dailies",0,1,{  1,  1} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-32868",	questID = 32868,	charLI = "NOONEYETNAMED-Frostmourne",	label = "PB N Beasts of Fable II",		frameID = "list2",	hideDone = true,	questInfo = "  - Book II",									zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Beasts of Fable Dailies",0,1,{  1,  1} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-32869",	questID = 32869,	charLI = "NOONEYETNAMED-Frostmourne",	label = "PB N Beasts of Fable III",		frameID = "list2",	hideDone = true,	questInfo = "  - Book III",									zygor = { "Pets & Mounts Guides\\Battle Pet Quests\\Beasts of Fable Dailies",0,1,{  1,  1} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
--	Draenor Pet Battles							Alliance / Horde						W/ Zygor Guide Click																														zygor = { "Guide\\Title", zygorTT, zygorX, zygorStep }
	{key = "XPPB:Q-37208",	questID = 37208,	charLI = "Shadowreckge-Frostmourne",	label = "PB N Taralune",				frameID = "list2",	hideDone = true,	questInfo = "Taralune\nTalador, Draenor",					zygor = { "Daily Guides\\Warlords of Draenor Dailies\\Battle Pets Dailies",  0,1,{ 14, 14} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-37201",	questID = 37201,	charLI = "Shadowarrant-Caelestrasz",	label = "PB N Cymre Brightblade",		frameID = "list2",	hideDone = true,	questInfo = "Cymre Brightblade\nGorgrond, Draenor",			zygor = { "Daily Guides\\Warlords of Draenor Dailies\\Battle Pets Dailies",  0,1,{  2,  2} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-37205",	questID = 37205,	charLI = "Shadowwaning-Caelestrasz",	label = "PB N Gargra",					frameID = "list2",	hideDone = true,	questInfo = "Gargra\nFrostfire, Draenor",					zygor = { "Daily Guides\\Warlords of Draenor Dailies\\Battle Pets Dailies",  0,1,{ 11, 11} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-37207",	questID = 37207,	charLI = "Shadowildlif-Frostmourne",	label = "PB N Vesharr",					frameID = "list2",	hideDone = true,	questInfo = "Vesharr\nSpires, Draenor",						zygor = { "Daily Guides\\Warlords of Draenor Dailies\\Battle Pets Dailies",  0,1,{  8,  8} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-37203",	questID = 37203,	charLI = "Shadowwaning-Frostmourne",	label = "PB N Ashlei",					frameID = "list2",	hideDone = true,	questInfo = "Ashlei\nShadowmoon, Draenor",					zygor = { "Daily Guides\\Warlords of Draenor Dailies\\Battle Pets Dailies",  0,1,{  5,  5} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-37206",	questID = 37206,	charLI = "Shadowspiner-Barthilas",		label = "PB N Tarr the Terrible",		frameID = "list2",	hideDone = true,	questInfo = "Tarr the Terrible\nNagrand, Draenor",			zygor = { "Daily Guides\\Warlords of Draenor Dailies\\Battle Pets Dailies",  0,1,{  5, 17} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
--	Other Pet Battles							Alliance / Horde						W/ Zygor Guide Click																														zygor = { "Guide\\Title", zygorTT, zygorX, zygorStep }
	{key = "XPPB:Q-45083",	questID = 45083,	charLI = "Shadowspiner-Caelestrasz",	label = "PB N Crysa",					frameID = "list2",	hideDone = true,	questInfo = "Crysa\nNorthern Barrens",						zygor = { "PETSMOUNTS\\Battle Pets\\Flying Pets\\Albino Buzzard",			 0,1,{  2,  2} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-47895",	questID = 47895,	charLI = "Shadowspiner-Dath'Remar",		label = "PB N Environeer Bert",			frameID = "list2",	hideDone = true,	questInfo = "Environeer Bert\nLegion Dalaran",				zygor = { "PETSMOUNTS\\Battle Pets\\Battle Pet Dungeons\\Gnomeregan",		 0,1,{  3,  3} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },
	{key = "XPPB:Q-63435",	questID = 63435,	charLI = "Shadowreckge-Dath'Remar",		label = "PB N Anthea",					frameID = "list2",	hideDone = true,	questInfo = "Anthea\nKun-Lai, Pandaria",					zygor = { "Pets & Mounts Guides\\Battle Pets\\Mechanical Pets\\Squibbles",   0,1,{  1,  1} },			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "btm", },






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
