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

{label = "SU  05  Jade Forest  A", frameID = "list1", key = "custom:q:29562:list1:XP05013",
questID = 29562, prereq = { 34775, }, hideWhenCompleted = true, faction = "Alliance",
questInfo = "Mists of Pandaria\n + Warboard: Jade Forest\n + Jade Forest (Zygor)\n      Until 'Jail Break'\n ",},

{label = "SU  05  Jade Forest  H", frameID = "list1", key = "custom:q:29822:list1:XP05014",
questID = 29822, prereq = { 34960, }, hideWhenCompleted = true, faction = "Horde",
questInfo = "Mists of Pandaria\n + Warboard: Jade Forest\n + Jade Forest (Zygor)\n       Until \"Lay of the Land\"\n ",},

{label = "SU  05  Kun-Lai  A", frameID = "list1", key = "custom:q:30515:list1:XP05015",
questID = 30515, prereq = { 29562, }, hideWhenCompleted = true, faction = "Alliance",
questInfo = "Mists of Pandaria  Level 20\n + Kun-Lai Summit (Zygor)\n      9  Do Village Quests\n    47  Complete\n      \"Challenge Accepted\"\n ",},

{label = "SU  05  Kun-Lai  H", frameID = "list1", key = "custom:q:30515:list1:XP05016",
questID = 30515, prereq = { 29822, }, hideWhenCompleted = true, faction = "Horde",
questInfo = "Mists of Pandaria  Level 20\n + Kun-Lai Summit (Zygor)\n      Until \"Challenge Accepted\" \n ",},

{label = "SU  05  Kun-Lai  Sprite's Cloth Chest", frameID = "list1", key = "custom:q:31412:list1:XP05017",
questID = 31412, prereq = { 29562, }, hideWhenCompleted = true,
questInfo = "+ Sprites Cloth Chest\n  - Need Steadfast\n  - Tried:\n       DK BL/UH - Strong\n ", },

  -- Shows During MoP Timewalking or on Timeless Isle
{label = "Timeless Isle Celestial", frameID = "list2", key = "event:timewalking:pandaria:celestial",
questID = 33117, aura = { spellID = 335151, eventActive = true, mustHave = true, rememberWeekly = true }, locationOverrideID = 554,
questInfo = "Timeless Celestials", hideWhenCompleted = true, },

{label = "Timeless Isle Chest Low", frameID = "list2", key = "event:timewalking:pandaria:chestlow",
questID = 33209, aura = { spellID = 335151, eventActive = true, mustHave = true, rememberWeekly = true }, locationOverrideID = 554,
questInfo = "Timeless Chest Low", hideWhenCompleted = true, },

{label = "Timeless Isle Chest Mid", frameID = "list2", key = "event:timewalking:pandaria:chestmid",
questID = 33208, aura = { spellID = 335151, eventActive = true, mustHave = true, rememberWeekly = true }, locationOverrideID = 554,
questInfo = "Timeless Chest Mid", hideWhenCompleted = true, },

{label = "Timeless Chest Top", frameID = "list2", key = "event:timewalking:pandaria:chesttop",
questID = 33210, aura = { spellID = 335151, eventActive = true, mustHave = true, rememberWeekly = true }, locationOverrideID = 554,
questInfo = "Timeless Chest Top", hideWhenCompleted = true, },

{label = "Timeless Isle Ordos", frameID = "list2", key = "event:timewalking:pandaria:ordos",
questID = 33118, aura = { spellID = 335151, eventActive = true, mustHave = true, rememberWeekly = true }, locationOverrideID = 554,
questInfo = "Timeless Ordos", hideWhenCompleted = true, },

{label = "Time-Lost Artifact", frameID = "list2", key = "event:timewalking:pandaria:time-lost-artifact",
aura = { spellID = 335151, eventActive = true, mustHave = true, rememberWeekly = true }, locationOverrideID = 554,
textInfo = "Time-Lost Artifact\n - Timeless Coins: $hv / $rq\n - Emperor Shaohao: {rep:have}", currencyID = { 777, 7500, Y }, repDisplay = { factionID = 1492, minStanding = 6 },
complete = { any = { { itemIDs = { 103678, 219222 }, includeBank = true }, }, }, },




}


for i = 1, #bakedRules do
  local r = bakedRules[i]
  if type(r) == "table" then
    if r._expansionID == nil then r._expansionID = EXPANSION_ID end
    if r._expansionName == nil then r._expansionName = EXPANSION_NAME end
    if r.questXY == nil and tonumber(r.questID) and r.qXept == nil then r.qXept = "N" end
    if type(r.key) == "string" then
      r.key = r.key:gsub("^custom:", "db:")
    end
    ns.rules[#ns.rules + 1] = r
  end
end
