local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB11 (The War Within)

ns.rules = ns.rules or {}

local EXPANSION_ID = 11
local EXPANSION_NAME = "The War Within"

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

{["label"] = "TD 3.01  11  Q-82520  Pet - Mind Slurp", ["frameID"] = "list1", ["key"] = "custom:q:82520:list1:68",
["questID"] = 82520, ["prereq"] = { 46957, 51341, 61874, }, ["hideWhenCompleted"] = true,
["questInfo"] = "+ Mind Slurp in Azj-Kahet\n    Memory Cache  30.23, 38.75", },

{["label"] = "TD 3.01  11  Q-84260  Crafting Orders Starter", ["frameID"] = "list1", ["key"] = "custom:q:84260:list1:69",
["questID"] = 84260, ["prereq"] = { 46957, 51341, 61874, }, ["hideWhenCompleted"] = true,
["questInfo"] = "+ Dornogal Crafting Order Reward", },

{["label"] = "SU  11  N  01  Q-81972  AQ-82819  34 Slot Bag", ["frameID"] = "list1", ["key"] = "custom:q:81972:list1:70",
["questID"] = 81972, ["prereq"] = { 82819, }, ["hideWhenCompleted"] = true,
["questInfo"] = "The War Within\n + 34 Bag @ Priory, Hallowfall\n                        30.23, 38.75", },

{["label"] = "SU  11  N  01  Q-82819  AQ-  34 Slot Bag", ["frameID"] = "list1", ["key"] = "custom:q:82819:list1:71",
["questID"] = 82819, ["prereq"] = { 46957, 51341, 61874, }, ["hideWhenCompleted"] = true,
["questInfo"] = "The War Within\n + 34 Slot Bag @ Camp Murroch, \n      3-4-1-2           Ringing Deeps", },

{["label"] = "TD 3.01  11  Q-82375  Coffer Key  Foundation Hall", ["frameID"] = "list1", ["key"] = "custom:q:82375:list1:73",
["questID"] = 82375, ["prereq"] = { 46931, 51341, 61874, }, ["hideWhenCompleted"] = true,
["questInfo"] = "+ Key - Dornogal Hall\nNo", },

{["label"] = "TD 3.01  11  Q-82356  Coffer Key  Foundation Hall 2", ["frameID"] = "list1", ["key"] = "custom:q:82356:list1:74",
["questID"] = 82356, ["prereq"] = { 46931, 51341, 61874, }, ["hideWhenCompleted"] = true,
["questInfo"] = "+ Key - Dornogal Hall\nNo", },

{["label"] = "TD 3.01  11  Q-82375  Coffer Key  Spiders", ["frameID"] = "list1", ["key"] = "custom:q:82434:list1:75",
["questID"] = 82434, ["prereq"] = { 46931, 51341, 61874, }, ["hideWhenCompleted"] = true,
["questInfo"] = "+ Key - Spiders (Portal)\nNo", },

{["label"] = "TD 3.01  11  Q-82398  Coffer Key  Undermine", ["frameID"] = "list1", ["key"] = "custom:q:90557:list1:76",
["questID"] = 90557, ["prereq"] = { 46931, 51341, 61874, }, ["hideWhenCompleted"] = true,
["questInfo"] = "+ Key - Undermine\nNo", },

{["label"] = "TD 3.01  11  Q-82398  Coffer Key  Mereldar Hallowfall", ["frameID"] = "list1", ["key"] = "custom:q:82398:list1:77",
["questID"] = 82398, ["prereq"] = { 46931, 51341, 61874, }, ["hideWhenCompleted"] = true,
["questInfo"] = "+ Key - Mereldar Hallowfall\nNo", },

{["label"] = "SU  11  N  01  Intro & Isle of Dorn 01", ["frameID"] = "list1", ["key"] = "custom:q:78713:list1:78",
["questID"] = 78713, ["prereq"] = { 67700, }, ["hideWhenCompleted"] = true,
["questInfo"] = "The War Within\nUse Teleportation Scroll", },

{["label"] = "SU  11  N  01  Intro & Isle of Dorn 02", ["frameID"] = "list1", ["key"] = "custom:q:81966:list1:79",
["questID"] = 81966, ["prereq"] = { 78713, }, ["hideWhenCompleted"] = true,
["questInfo"] = "The War Within\nFollow Guide or Skip", },

{["label"] = "SU  11  N  01  Intro & Isle of Dorn 03", ["frameID"] = "list1", ["key"] = "custom:q:85573:list1:80",
["questID"] = 85573, ["prereq"] = { 45727, }, ["hideWhenCompleted"] = true,
["questInfo"] = "The War Within\nSiren Isle (Zygor)\\n + Follow Guide", },

{["frameID"] = "list1", ["key"] = "custom:item:230728:list1:129",
["hideWhenCompleted"] = false,
["locationID"] = "2369",
["item"] = { ["itemID"] = 230728, ["required"] = { 1, true, N, 0 }, },
["restedOnly"] = false, },

{["label"] = "Khaz Algar Cooking", ["frameID"] = "list1", ["key"] = "custom:spell:list1:118",
["hideWhenCompleted"] = false,
["spellKnown"] = 264638,
["notSpellKnown"] = 423333,
["locationID"] = 6666666,
["notInGroup"] = false, },

{["label"] = "Khaz Algar Fishing", ["frameID"] = "list1", ["key"] = "custom:spell:list1:119",
["hideWhenCompleted"] = false,
["spellKnown"] = 271660,
["notSpellKnown"] = 423336,
["locationID"] = 6666666,
["notInGroup"] = false, },

{["label"] = "Khaz Algar Herbalism", ["frameID"] = "list1", ["key"] = "custom:spell:list1:120",
["hideWhenCompleted"] = false,
["spellKnown"] = 265825,
["notSpellKnown"] = 441327,
["locationID"] = 6666666,
["notInGroup"] = false, },

{["label"] = "Khaz Algar Leatherworking", ["frameID"] = "list1", ["key"] = "custom:spell:list1:121",
["hideWhenCompleted"] = false,
["spellKnown"] = 264583,
["notSpellKnown"] = 423340,
["locationID"] = 6666666,
["notInGroup"] = false, },

{["label"] = "Khaz Algar Mining", ["frameID"] = "list1", ["key"] = "custom:spell:list1:122",
["hideWhenCompleted"] = false,
["spellKnown"] = 265843,
["notSpellKnown"] = 423341,
["locationID"] = 6666666,
["notInGroup"] = false, },

{["label"] = "Khaz Algar Skinning", ["frameID"] = "list1", ["key"] = "custom:spell:list1:123",
["hideWhenCompleted"] = false,
["spellKnown"] = 265861,
["notSpellKnown"] = 423342,
["locationID"] = 6666666,
["notInGroup"] = false, },

{["label"] = "Lucky Tortollan Charm\n      Near Azj-Kahet Portal", ["frameID"] = "list1", ["key"] = "custom:item:202046:list1:72",
["hideWhenCompleted"] = false,
["playerLevel"] = { ">", 70 },
["faction"] = "Horde",
["restedOnly"] = true,
["item"] = { ["itemID"] = 202046, ["required"] = { 1, true, N, 0 }, }, },

{["label"] = "Khaz Algar Tailoring", ["frameID"] = "list1", ["key"] = "custom:spell:list1:124",
["hideWhenCompleted"] = false,
["spellKnown"] = 264622,
["notSpellKnown"] = 423343,
["locationID"] = 6666666,
["notInGroup"] = false, },

{["label"] = "Delvez", ["frameID"] = "bar1", ["key"] = "wk:delves:bran",
["questID"] = 82706, ["requireInLog"] = false, ["hideWhenCompleted"] = true, ["showXWhenComplete"] = true,
["playerLevel"] = { ">=", 70, },
["progress"] = { ["objectiveIndex"] = 1 },},


{["label"] = "Belt1", ["frameID"] = "bar1", ["key"] = "custom:q:91009:list1:Disc1", ["color"] = { 0.2, 0.6, 1, },
["questID"] = 91009, ["hideWhenCompleted"] = true,["playerLevel"] = { ">=", 80, },
["questInfo"] = "Belt1", },

{["label"] = "Belt2", ["frameID"] = "bar1", ["key"] = "custom:q:91026:list1:Disc2", ["color"] = { 0.2, 0.6, 1, },
["questID"] = 91026, ["prereq"] = { 91009, }, ["hideWhenCompleted"] = true, ["playerLevel"] = { ">=", 80, },
["questInfo"] = "Belt2", },

{["label"] = "Belt3", ["frameID"] = "bar1", ["key"] = "custom:q:91030:list1:Disc3", ["color"] = { 0.2, 0.6, 1, },
["questID"] = 91030, ["prereq"] = { 91026, }, ["hideWhenCompleted"] = true, ["playerLevel"] = { ">=", 80, },
["questInfo"] = "Belt3", },

{["label"] = "Belt4", ["frameID"] = "bar1", ["key"] = "custom:q:91031:list1:Disc4", ["color"] = { 0.2, 0.6, 1, },
["questID"] = 91031, ["prereq"] = { 91030, }, ["hideWhenCompleted"] = true, ["playerLevel"] = { ">=", 80, },
["questInfo"] = "Belt4", },






{["label"] = "Reshii Wraps", ["frameID"] = "bar1", ["key"] = "custom:q:90938:bar1:1",
["questID"] = 90938, ["requireInLog"] = false, ["hideWhenCompleted"] = true, ["showXWhenComplete"] = true,
["hideIfAnyQuestCompleted"] = { 90938, 84856, 84910 },
["playerLevel"] = { ">=", 80, }, ["color"] = { 0.2, 0.6, 1, },
["questInfo"] = "Reshii",},



}

for i = 1, #bakedRules do
  local r = bakedRules[i]
  if type(r) == "table" then
    if r._expansionID == nil then r._expansionID = EXPANSION_ID end
    if r._expansionName == nil then r._expansionName = EXPANSION_NAME end
    if type(r.key) == "string" then
      r.key = r.key:gsub("^custom:", "db:")
    end
    ns.rules[#ns.rules + 1] = r
  end
end
