local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB06 (Warlords of Draenor)

ns.rules = ns.rules or {}

local EXPANSION_ID = 6
local EXPANSION_NAME = "Warlords of Draenor"

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

	{key = "XP06:Q36941A",  questID = 36941, prereq = {47189,},	label = "06 A Garrison 1", frameID = "list1", hideDone = true, faction = "A",	mapID = {84,17,},				questInfo = "Warlords of Draenor\n + Iron Horde Invasion (Zygor)\n  - Warboard: Tanaan Jungle\n  - Portal Tower Entrance\n    - Talk to Battlemage\n    - Abandon Quest After Port",},
	{key = "XP06:Q34586A",  questID = 34586, prereq = {36941,},	label = "06 A Garrison 2", frameID = "list1", hideDone = true, faction = "A",	mapID = {84,17,539,540,582,},	questInfo = "Warlords of Draenor\n - Warboard: Tanaan Jungle\n  - Portal Tower Entrance\n    - Talk to Battlemage\n    - Abandon Quest After Port\n  - Take Red Portal (Draenor)\n    - If Green phase @ Sidormi",},
	{key = "XP06:Q34775A",  questID = 34775, prereq = {34586,},	label = "06 A Garrison 3", frameID = "list1", hideDone = true, faction = "A",	mapID = {84,17,539,540,582,},	questInfo = "Warlords of Draenor\n + Zygor: Shadowmoon Valley\n - Q2: 'Delegating on Draenor'",},
	{key = "XP06:Q36615A",  questID = 36615,					label = "06 A Garrison 4", frameID = "list2", hideDone = true, faction = "A",	gold = 20000,					questInfo = "Level Garrison to 3", restedOnly = true, },
--                                                                                                                                       -- mapIDs: fUI_QTUsage.lua

	{key = "XP06:Q36940H",	questID = 36940, prereq = {47514,},	label = "06 H Garrison 1", frameID = "list1", hideDone = true, faction = "H",	mapID = {85,17,},				questInfo = "Warlords of Draenor\n + Iron Horde Invasion (Zygor)\n  - Warboard: Tanaan Jungle\n  - Lower Portal Room\n    - Talk to Battlemage\n    - After Port Abandon Quest",},
	{key = "XP06:Q34586H",	questID = 34586, prereq = {36940,},	label = "06 H Garrison 2", frameID = "list1", hideDone = true, faction = "H",	mapID = {85,17,525,590,},		questInfo = "Warlords of Draenor\n - Warboard: Tanaan Jungle\n - Lower Portal Room\n - Talk to Battlemage\n - After Port Abandon Quest\n - Take Red Portal (Draenor)",},
	{key = "XP06:Q34960H",	questID = 34960, prereq = {34586,},	label = "06 H Garrison 3", frameID = "list1", hideDone = true, faction = "H",	mapID = {85,17,525,590,},		questInfo = "Warlords of Draenor\n + Frostfire Ridge (Zygor)\n - Q2: 'The Land Provides'",},
	{key = "XP06:Q36567H",	questID = 36567, prereq = {34960,},	label = "06 H Garrison 4", frameID = "list1", hideDone = true, faction = "H",	mapID = {85,17,525,590,},		questInfo = "Warlords of Draenor\n - 200 Garrison Resources\n - Upgrade Garrison to Level 2",},
	{key = "XP06:Q36614H",	questID = 36614, gold = 20000,		label = "06 H Garrison 5", frameID = "list2", hideDone = true, faction = "H",						questInfo = "Level Garrison to 3", restedOnly = true, },
	{key = "XP06:Q33505",	questID = 33505, prereq = {34586,},	label = "06 Wiggling Egg", frameID = "list1", hideDone = true,					mapID = 525,					questInfo = "Frostfire Ridge\n + Wiggling Egg", },



}




for i = 1, #bakedRules do
  local r = bakedRules[i]
  if type(r) == "table" then
    ns.GuideHelpers.NormalizeRule(r, EXPANSION_ID, EXPANSION_NAME)
    ns.rules[#ns.rules + 1] = r
  end
end
