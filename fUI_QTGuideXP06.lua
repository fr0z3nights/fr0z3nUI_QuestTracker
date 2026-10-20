local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB06 (Warlords of Draenor)

ns.rules = ns.rules or {}

local EXPANSION_ID = 6
local EXPANSION_NAME = "Warlords of Draenor"

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
--   $wgcs -> {garrisonCache} ("Cache N" estimate; line is dropped until a cache loot is recorded)


-- item.required tuple keys:
--   item.required = { count, hideWhenAcquired, autoBuyEnabled, autoBuyMax }
local REQ_COUNT, REQ_HIDE, REQ_BUY_ON, REQ_BUY_MAX = 1, 2, 3, 4
local bakedRules = {

--	Alliance Garrison																																							zygor = { "Guide\\Title", zygorTT, zygorX, zygorStep }
	{key="XP06:Q-34582A",	questID = 34582, 					label = "06 Garrison A0", frameID = "list2", hideDone = true,	faction = "A",									font = "lsm:Bazooka", size = 14, color = "b88fe6", align = "center",		questInfo = "Garrison Locked", },
	{key="XP06:Q-36941A",	questID = 36941, prereq = {47189,},	label = "06 Garrison A1", frameID = "list1", hideDone = true,	faction = "A",	mapID = {84,17,},				zygor = { "EVENTS\\Warlords of Draenor\\Iron Horde Invasion",1,1,1 }, 		questInfo = "Warlords of Draenor\n + Warboard: Tanaan Jungle\n - Portal Tower Entry NPC\n > Iron Horde Invasion <",},
	{key="XP06:Q-34586A",	questID = 34586, prereq = {36941,},	label = "06 Garrison A2", frameID = "list1", hideDone = true,	faction = "A",	mapID = {84,17,539,540,582,},																				questInfo = "Warlords of Draenor\n + Warboard: Tanaan Jungle\n - Portal Tower Entry NPC\n - Red Portal, Do Quests",},
	{key="XP06:Q-34775A",	questID = 34775, prereq = {34586,},	label = "06 Garrison A3", frameID = "list1", hideDone = true,	faction = "A",	mapID = {84,17,539,540,582,},	zygor = { "LEVELING\\Draenor (10-70)\\Shadowmoon Valley (10-70)",1,1,1 }, 	questInfo = "Warlords of Draenor\n > Shadowmoon Valley <\n - Do 'Delegating on Draenor'",},
	{key="XP06:Q-36567A",	questID = 36592, prereq = {34586,},	label = "06 Garrison A4", frameID = "list2", hideDone = true,	faction = "A",									font = "lsm:Bazooka", size = 14, color = "b88fe6", align = "center",	 	questInfo = "Garrison ^2  $hv\n$wgcs",	currencyID = {824, 200,Y}, },
	{key="XP06:Q-36615A",	questID = 36615, prereq = {36592,},	label = "06 Garrison A5", frameID = "list2", hideDone = true,	faction = "A",									font = "lsm:Bazooka", size = 14, color = "b88fe6", align = "center",	 	questInfo = "Garrison ^3  $hv\n$wgcs",	currencyID = {824,2000,Y}, gold = 10000, },
	{key="XP06:Q-38241A",	questID = 38241, prereq = {36615,},	label = "06 Garrison A6", frameID = "list2", hideDone = true,	faction = "A",									font = "lsm:Bazooka", size = 14, color = "b88fe6", align = "center",		questInfo = "Garrison Pet Stone", },
	{key="XP06:Q-GCACHEA",					 prereq = {36615,},	label = "06 Garrison A7", frameID = "list2", hideDone = false,	faction = "A",	resting = true,					font = "lsm:Bazooka", size = 14, color = "b88fe6", align = "center",		textInfo  = "Garrison $wgcs", },
--	Horde Garrison																															--	mapIDs: fUI_QTUsage.lua						currencyID = { 3310, 1000, Y },							textInfo  = "",
	{key="XP06:Q-33815H",	questID = 33815, 					label = "06 Garrison H0", frameID = "list2", hideDone = true,	faction = "H",									font = "lsm:Bazooka", size = 14, color = "b88fe6", align = "center",		questInfo = "Garrison Locked", },
	{key="XP06:Q-36940H",	questID = 36940, prereq = {47514,},	label = "06 Garrison H1", frameID = "list1", hideDone = true,	faction = "H",	mapID = {85,17,624},			zygor = { "EVENTS\\Warlords of Draenor\\Iron Horde Invasion",1,1,1 }, 		questInfo = "Warlords of Draenor\n - Warboard: Tanaan Jungle\n - Lower Portal Room NPC\n > Iron Horde Invasion <",},
	{key="XP06:Q-34586H",	questID = 34586, prereq = {36940,},	label = "06 Garrison H2", frameID = "list1", hideDone = true,	faction = "H",	mapID = {85,17,624,525,590,},																					questInfo = "Warlords of Draenor\n - Warboard: Tanaan Jungle\n - Lower Portal Room NPC\n - Red Portal, Do Quests",},
	{key="XP06:Q-34960H",	questID = 34960, prereq = {34586,},	label = "06 Garrison H3", frameID = "list1", hideDone = true,	faction = "H",	mapID = {85,17,624,525,590,},	zygor = { "LEVELING\\Draenor (10-70)\\Frostfire Ridge (10-70)",1,1,1 }, 	questInfo = "Warlords of Draenor\n > Frostfire Ridge <\n - Do 'The Land Provides'",},
	{key="XP06:Q-36567H",	questID = 36567, prereq = {34586,},	label = "06 Garrison H4", frameID = "list2", hideDone = true,	faction = "H",									font = "lsm:Bazooka", size = 14, color = "b88fe6", align = "center",		questInfo = "Garrison ^2  $hv\n$wgcs",	currencyID = {824, 200,Y}, },
	{key="XP06:Q-36614H",	questID = 36614, prereq = {36567,},	label = "06 Garrison H5", frameID = "list2", hideDone = true,	faction = "H",									font = "lsm:Bazooka", size = 14, color = "b88fe6", align = "center", 		questInfo = "Garrison ^3  $hv\n$wgcs",	currencyID = {824,2000,Y}, gold = 10000, },
	{key="XP06:Q-38242H",	questID = 38242, prereq = {36614,},	label = "06 Garrison H6", frameID = "list2", hideDone = true,	faction = "H",									font = "lsm:Bazooka", size = 14, color = "b88fe6", align = "center",		questInfo = "Garrison Pet Level", },
	{key="XP06:Q-GCACHEH",					 prereq = {36614,},	label = "06 Garrison H7", frameID = "list2", hideDone = false,	faction = "H",	resting = true,					font = "lsm:Bazooka", size = 14, color = "b88fe6", align = "center",		textInfo  = "Garrison $wgcs", },
--	Other
	{key="XP06:Q-33505",	questID = 33505, prereq = {34586,},	label = "06 Wiggling Egg", frameID = "list1", hideDone = true,					mapID = {525,624},				questInfo = "Frostfire Ridge\n + Wiggling Egg", },



}
bakedRules = ns.GuideHelpers.ExpandQuestGroups(bakedRules)
for i = 1, #bakedRules do
  local r = bakedRules[i]
	if type(r) == "table" and not r.questGroup then
    ns.GuideHelpers.NormalizeRule(r, EXPANSION_ID, EXPANSION_NAME)
    ns.rules[#ns.rules + 1] = r
  end
end
