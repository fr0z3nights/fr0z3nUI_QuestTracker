local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB05 (Mists of Pandaria)

ns.rules = ns.rules or {}

local EXPANSION_ID = 5
local EXPANSION_NAME = "Mists of Pandaria"

local Y, N = true, false

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

	{key = "XP05:Q29562",   questID = 29562, prereq = {34775,}, label = "05 Jade Forest A", faction = "A",  mapID = {"MoP","SW","OR",}, frameID = "list1", hideDone = true, questInfo = "Mists of Pandaria\n + Warboard: Jade Forest\n + Jade Forest (Zygor)\n      Until 'Jail Break'\n ",},
	{key = "XP05:Q29822",   questID = 29822, prereq = {34960,}, label = "05 Jade Forest H", faction = "H",  mapID = {"MoP","SW","OR",}, frameID = "list1", hideDone = true, questInfo = "Mists of Pandaria\n + Warboard: Jade Forest\n + Jade Forest (Zygor)\n       Until \"Lay of the Land\"\n ",},
	{key = "XP05:Q30515A",  questID = 30515, prereq = {29562,}, label = "05 Kun-Lai A",     faction = "A",  mapID = {"MoP","SW","OR",}, frameID = "list1", hideDone = true, questInfo = "Mists of Pandaria  Level 20\n + Kun-Lai Summit (Zygor)\n      9  Do Village Quests\n    47  Complete\n      \"Challenge Accepted\"\n ",},
	{key = "XP05:Q30515H",  questID = 30515, prereq = {29822,}, label = "05 Kun-Lai H",     faction = "H",  mapID = {"MoP","SW","OR",}, frameID = "list1", hideDone = true, questInfo = "Mists of Pandaria  Level 20\n + Kun-Lai Summit (Zygor)\n      Until \"Challenge Accepted\" \n ",},
	{key = "XP05:Q31412",   questID = 31412, prereq = {29562,}, label = "05 Kun-Lai Chest",                 mapID = {"MoP",},           frameID = "list1", hideDone = true, questInfo = "+ Sprites Cloth Chest\n  - Need Steadfast\n  - Tried:\n       DK BL/UH - Strong\n ", }, -- Chest Transmog missing, shows only when on Pandaria
--                                                                                                                                       -- mapIDs: fUI_QTUsage.lua

	{key = "XP05:Q33117",   questID = 33117,                    label = "Timeless Isle Celestial",          mapID = {"TI",},            frameID = "list2", hideDone = true, questInfo = "Timeless Celestials",                                                                  aura = { spellID = 335151, eventActive = true, mustHave = true, rememberWeekly = true }, },   -- Shows During MoP Timewalking or on Timeless Isle
	{key = "XP05:Q33209",   questID = 33209,                    label = "Timeless Isle Chest Low",          mapID = {"TI",},            frameID = "list2", hideDone = true, questInfo = "Timeless Chest Low",                                                                   aura = { spellID = 335151, eventActive = true, mustHave = true, rememberWeekly = true }, },
	{key = "XP05:Q33208",   questID = 33208,                    label = "Timeless Isle Chest Mid",          mapID = {"TI",},            frameID = "list2", hideDone = true, questInfo = "Timeless Chest Mid",                                                                   aura = { spellID = 335151, eventActive = true, mustHave = true, rememberWeekly = true }, },
	{key = "XP05:Q33210",   questID = 33210,                    label = "Timeless Isle Chest Top",          mapID = {"TI",},            frameID = "list2", hideDone = true, questInfo = "Timeless Chest Top",                                                                   aura = { spellID = 335151, eventActive = true, mustHave = true, rememberWeekly = true }, },
	{key = "XP05:Q33118",   questID = 33118,                    label = "Timeless Isle Ordos",              mapID = {"TI",},            frameID = "list2", hideDone = true, questInfo = "Timeless Ordos",                                                                       aura = { spellID = 335151, eventActive = true, mustHave = true, rememberWeekly = true }, },
	{key = "XP05:I103678",                                      label = "Time-Lost Artifact",               mapID = {"TI",},            frameID = "list2", hideDone = true, textInfo  = "Time-Lost Artifact\n - Timeless Coins: $hv / $rq\n - Emperor Shaohao: {rep:have}",     aura = { spellID = 335151, eventActive = true, mustHave = true, rememberWeekly = true }, currencyID = { 777, 7500, Y }, repDisplay = { factionID = 1492, minStanding = 6 }, complete = { any = { { itemIDs = { 103678, 219222 }, includeBank = true }, }, }, }, -- Shows when on Timeless Isle, Do during Pandaria Timewalking Week Only


}


for i = 1, #bakedRules do
  local r = bakedRules[i]
  if type(r) == "table" then
    ns.GuideHelpers.NormalizeRule(r, EXPANSION_ID, EXPANSION_NAME)
    ns.rules[#ns.rules + 1] = r
  end
end
