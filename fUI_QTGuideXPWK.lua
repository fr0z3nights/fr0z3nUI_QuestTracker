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





	{key = "XPEV:Q-PetBtl",						requireInLog = false,	playerLevel = {">=",20},	label = "Event: Pet Battle",		frameID = "bar1",	hideDone = false,										XDone = true,		questInfo = "Pet XP",																									pad = 3, aura = { eventKind = "calendar", keywords = { "Pet Battle Bonus Event" }, mustHave = true, rememberWeekly = true }, },
	{key = "XPEV:Q-93595",	questID = 93595,	requireInLog = false,	playerLevel = {">=",80},	label = "Event: Delves",			frameID = "list2",	hideDone = true,	progress = { objectiveIndex = 1 },	XDone = true,		questInfo = "Delves",				font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top",	pad = 3, aura = { eventKind = "calendar", keywords = { "Delves Bonus Event" }, mustHave = true, rememberWeekly = true }, },
	{key = "XPEV:Q-93606",	questID = 93605,	requireInLog = false,	playerLevel = {">=",80},	label = "Event: Battleground",		frameID = "list2",	hideDone = true,	progress = { objectiveIndex = 1 },  XDone = true,		questInfo = "Battleground",			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top",	pad = 3, aura = { eventKind = "calendar", keywords = { "Battleground Bonus Event" }, mustHave = true, rememberWeekly = true }, },
	{key = "XPEV:Q-93605",	questID = 93605,	requireInLog = false,	playerLevel = { "=",90},	label = "Event: World Quest",		frameID = "list2",	hideDone = true,	progress = { objectiveIndex = 1 },	XDone = true,		questInfo = "World Quest",			font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "top",	pad = 3, aura = { eventKind = "calendar", keywords = { "World Quest Bonus Event" }, mustHave = true, rememberWeekly = true }, },

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
	{key = "XPTW:05-TKN",	fallbackQuestInLog = { 45563 },				sortGO = {"XP05:TW",3},		label = "TW Pandaria TKN",			frameID = "bar1",	hideDone = false,	preferQuestInfoForTitle = true,							questInfo = "\194\160",				list = "last",						twKind = "pandaria", requireRememberedTimewalkingKind = true,	indicators = { { questID = 45563, shape = "square", overlay = { itemIDs = { 143776 }, text = "1", color = { 1.0, 1.0, 0.1 } }, }, }, },
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
