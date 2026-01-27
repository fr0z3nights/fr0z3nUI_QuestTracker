local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB04 (Cataclysm)

ns.rules = ns.rules or {}

local EXPANSION_ID = 4
local EXPANSION_NAME = "Cataclysm"

local bakedRules = {

{["label"] = "SU  04  H1  Q-25929  Vashj'ir  Unlock Portal", ["frameID"] = "list1", ["key"] = "custom:q:25929:list1:82",
["questID"] = 25929, ["prereq"] = { 46931, 51341, 61874, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Cataclysm\n+ Vashj'ir (Zygor)\n+ Complete Quest\n      \"Sea Legs\"",
["faction"] = "Horde", },

{["label"] = "SU  04  A1  Q-24432  Vashj'ir  Unlock Portal", ["frameID"] = "list1", ["key"] = "custom:q:24432:list1:83",
["questID"] = 24432, ["prereq"] = { 46931, 51341, 61874, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Cataclysm\n+ Vashj'ir (Zygor)\n+ Complete Quest\n      \"Sea Legs\"",
["faction"] = "Alliance", },

{["frameID"] = "list1", ["key"] = "custom:item:64884:list1:132",
["hideWhenCompleted"] = false,
["faction"] = "Horde",
["locationID"] = "1133",
["item"] = { ["hideWhenAcquired"] = true, ["itemID"] = 64884, ["required"] = 1, },
["restedOnly"] = true, },

{["frameID"] = "list1", ["key"] = "custom:item:64882:list1:136",
["hideWhenCompleted"] = false,
["rep"] = { ["sellWhenExalted"] = true, ["factionID"] = 1134, },
["item"] = { ["hideWhenAcquired"] = true, ["itemID"] = 64882, ["required"] = 1, },
["restedOnly"] = true, },

{["label"] = "Cooking", ["frameID"] = "list1", ["key"] = "custom:spell:list1:87",
["hideWhenCompleted"] = false,
["notSpellKnown"] = 264638,
["notInGroup"] = false, },

{["label"] = "Fishing", ["frameID"] = "list1", ["key"] = "custom:spell:list1:89",
["hideWhenCompleted"] = false,
["notSpellKnown"] = 271660,
["notInGroup"] = false, },

{["label"] = "Alchemy", ["frameID"] = "list1", ["key"] = "custom:spell:list1:88",
["spellInfo"] = "Alchemy", ["missingPrimaryProfessions"] = true,
["hideWhenCompleted"] = false,
["notSpellKnown"] = 264243,
["notInGroup"] = false, },

{["label"] = "Blacksmithing", ["frameID"] = "list1", ["key"] = "custom:spell:list1:88",
["spellInfo"] = "Blacksmithing", ["missingPrimaryProfessions"] = true,
["hideWhenCompleted"] = false,
["notSpellKnown"] = 264641,
["notInGroup"] = false, },

{["label"] = "Encahanting", ["frameID"] = "list1", ["key"] = "custom:spell:list1:88",
["spellInfo"] = "Enchanting", ["missingPrimaryProfessions"] = true,
["hideWhenCompleted"] = false,
["notSpellKnown"] = 264464,
["notInGroup"] = false, },

{["label"] = "Engineering", ["frameID"] = "list1", ["key"] = "custom:spell:list1:88",
["spellInfo"] = "Engineering", ["missingPrimaryProfessions"] = true,
["hideWhenCompleted"] = false,
["notSpellKnown"] = 264483,
["notInGroup"] = false, },

{["label"] = "Herbalism", ["frameID"] = "list1", ["key"] = "custom:spell:list1:90",
["spellInfo"] = "Herbalism", ["missingPrimaryProfessions"] = true,
["hideWhenCompleted"] = false,
["notSpellKnown"] = 265825,
["notInGroup"] = false, },

{["label"] = "Jewelcrafting", ["frameID"] = "list1", ["key"] = "custom:spell:list1:90",
["spellInfo"] = "Jewelcrafting", ["missingPrimaryProfessions"] = true,
["hideWhenCompleted"] = false,
["notSpellKnown"] = 264539,
["notInGroup"] = false, },

{["label"] = "Inscription", ["frameID"] = "list1", ["key"] = "custom:spell:list1:90",
["spellInfo"] = "Inscription", ["missingPrimaryProfessions"] = true,
["hideWhenCompleted"] = false,
["notSpellKnown"] = 246500,
["notInGroup"] = false, },

{["label"] = "Mining", ["frameID"] = "list1", ["key"] = "custom:spell:list1:91:base",
["spellInfo"] = "Mining", ["missingPrimaryProfessions"] = true,
["hideWhenCompleted"] = false,
["notSpellKnown"] = 265843,
["notInGroup"] = false, },

{["label"] = "Skinning", ["frameID"] = "list1", ["key"] = "custom:spell:list1:92",
["spellInfo"] = "Skinning", ["missingPrimaryProfessions"] = true,
["hideWhenCompleted"] = false,
["notSpellKnown"] = 265861,
["notInGroup"] = false, },

{["label"] = "Tailoring", ["frameID"] = "list1", ["key"] = "custom:spell:list1:93",
["spellInfo"] = "Tailoring", ["missingPrimaryProfessions"] = true,
["hideWhenCompleted"] = false,
["notSpellKnown"] = 264622,
["notInGroup"] = false, },

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
