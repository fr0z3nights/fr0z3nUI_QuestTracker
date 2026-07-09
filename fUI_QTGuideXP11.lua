local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB11 (The War Within)

ns.rules = ns.rules or {}

local EXPANSION_ID = 11
local EXPANSION_NAME = "The War Within"

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

{label = "TD 3.01  11  Q-82520  Pet - Mind Slurp", frameID = "list1", key = "custom:q:82520:list1:XP11068",
questID = 82520, prereq = { 46957, 51341, 61874, }, hideWhenCompleted = true,
questInfo = "+ Mind Slurp in Azj-Kahet\n    Memory Cache  30.23, 38.75", },

{label = "TD 3.01  11  Q-84260  Crafting Orders Starter", frameID = "list1", key = "custom:q:84260:list1:XP11069",
questID = 84260, prereq = { 46957, 51341, 61874, }, hideWhenCompleted = true,
questInfo = "+ Dornogal Crafting Order Reward", },

{label = "SU  11  N  01  Q-81972  AQ-82819  34 Slot Bag", frameID = "list1", key = "custom:q:81972:list1:XP11070",
questID = 81972, prereq = { 82819, }, hideWhenCompleted = true,
questInfo = "The War Within\n + 34 Bag @ Priory, Hallowfall\n                        30.23, 38.75", },

{label = "SU  11  N  01  Q-82819  AQ-  34 Slot Bag", frameID = "list1", key = "custom:q:82819:list1:XP11071",
questID = 82819, prereq = { 46957, 51341, 61874, }, hideWhenCompleted = true,
questInfo = "The War Within\n + 34 Slot Bag @ Camp Murroch, \n      3-4-1-2           Ringing Deeps", },

{label = "TD 3.01  11  Q-82375  Coffer Key  Foundation Hall", frameID = "list1", key = "custom:q:82375:list1:XP11073",
questID = 82375, prereq = { 46931, 51341, 61874, }, hideWhenCompleted = true,
questInfo = "+ Key - Dornogal Hall\nNo", },

{label = "TD 3.01  11  Q-82356  Coffer Key  Foundation Hall 2", frameID = "list1", key = "custom:q:82356:list1:XP11074",
questID = 82356, prereq = { 46931, 51341, 61874, }, hideWhenCompleted = true,
questInfo = "+ Key - Dornogal Hall\nNo", },

{label = "TD 3.01  11  Q-82375  Coffer Key  Spiders", frameID = "list1", key = "custom:q:82434:list1:XP11075",
questID = 82434, prereq = { 46931, 51341, 61874, }, hideWhenCompleted = true,
questInfo = "+ Key - Spiders (Portal)\nNo", },

{label = "TD 3.01  11  Q-82398  Coffer Key  Undermine", frameID = "list1", key = "custom:q:90557:list1:XP11076",
questID = 90557, prereq = { 46931, 51341, 61874, }, hideWhenCompleted = true,
questInfo = "+ Key - Undermine\nNo", },

{label = "TD 3.01  11  Q-82398  Coffer Key  Mereldar Hallowfall", frameID = "list1", key = "custom:q:82398:list1:XP11077",
questID = 82398, prereq = { 46931, 51341, 61874, }, hideWhenCompleted = true,
questInfo = "+ Key - Mereldar Hallowfall\nNo", },

{label = "SU  11  N  01  Intro & Isle of Dorn 01", frameID = "list1", key = "custom:q:78713:list1:XP11078",
questID = 78713, prereq = { 67700, }, hideWhenCompleted = true,
questInfo = "The War Within\nUse Teleportation Scroll", },

{label = "SU  11  N  01  Intro & Isle of Dorn 02", frameID = "list1", key = "custom:q:81966:list1:XP11079",
questID = 81966, prereq = { 78713, }, hideWhenCompleted = true,
questInfo = "The War Within\nFollow Guide or Skip", },

{label = "SU  11  N  01  Intro & Isle of Dorn 03", frameID = "list1", key = "custom:q:85573:list1:XP11080",
questID = 85573, prereq = { 45727, }, hideWhenCompleted = true,
questInfo = "The War Within\n + Siren Isle (Zygor)\n  - Follow Guide", },

{frameID = "list1", key = "custom:item:230728:list1:129",
hideWhenCompleted = false,
locationID = "2369",
item = { itemID = 230728, required = { 1, true, N, 0 }, },
restedOnly = false, },


{label = "Lucky Tortollan Charm\n      Near Azj-Kahet Portal", frameID = "list1", key = "custom:item:202046:list1:72",
hideWhenCompleted = false, playerLevel = { ">", 70 }, faction = "Horde", restedOnly = true, item = { itemID = 202046, required = { 1, true, N, 0 }, }, },

{label = "Delvez11", frameID = "bar1", key = "wk:delves:bran", progress = { objectiveIndex = 1 },
questID = 82706, requireInLog = false, hideWhenCompleted = true, showXWhenComplete = true, playerLevel = { "=", 80, },},

{label = "Archives: First Disc", frameID = "bar1", key = "11wk:archives:disc1",
questID = 82678, hideWhenCompleted = true, playerLevel = { "=", 80, }, questInfo = "First Disc", },

{label = "Archives", frameID = "bar1", key = "11wk:archives:disc2",
questID = 82679, prereq = { 82678, }, requireInLog = false, hideWhenCompleted = true, showXWhenComplete = true,
questInfo = "Archive", playerLevel = { "=", 80, }, ["progress"] = { ["objectiveIndex"] = 1 },},

{label = "Belt1", frameID = "bar1", key = "custom:q:91009:list1:XP11Disc1", ["color"] = { 0.2, 0.6, 1, },
questID = 91009, hideWhenCompleted = true,playerLevel = { "=", 80, }, questInfo = "Belt1", },

{label = "Belt2", frameID = "bar1", key = "custom:q:91026:list1:XP11Disc2", ["color"] = { 0.2, 0.6, 1, },
questID = 91026, prereq = { 91009, }, hideWhenCompleted = true, playerLevel = { "=", 80, }, questInfo = "Belt2", },

{label = "Belt3", frameID = "bar1", key = "custom:q:91030:list1:XP11Disc3", ["color"] = { 0.2, 0.6, 1, },
questID = 91030, prereq = { 91026, }, hideWhenCompleted = true, playerLevel = { "=", 80, }, questInfo = "Belt3", },

{label = "Belt4", frameID = "bar1", key = "custom:q:91031:list1:XP11Disc4", ["color"] = { 0.2, 0.6, 1, },
questID = 91031, prereq = { 91030, }, hideWhenCompleted = true, playerLevel = { "=", 80, }, questInfo = "Belt4", },

{label = "Reshii Wraps", frameID = "bar1", key = "custom:q:90938:bar1:XP11001", playerLevel = { ">=", 80, }, ["color"] = { 0.2, 0.6, 1, },
questID = 90938, requireInLog = false, questInfo = "Reshii", showXWhenComplete = true, hideIfAnyQuestCompleted = { 90938, 84856, 84910 },},



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
