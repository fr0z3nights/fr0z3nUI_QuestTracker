local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB04 (Cataclysm)

ns.rules = ns.rules or {}

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

{["label"] = "Cataclysm  Cooking", ["frameID"] = "list1", ["key"] = "custom:spell:list1:87",
["hideWhenCompleted"] = false,
["notSpellKnown"] = 264638,
["notInGroup"] = false, },

{["label"] = "Cataclysm  Engineering", ["frameID"] = "list1", ["key"] = "custom:spell:list1:88",
["hideWhenCompleted"] = false,
["notSpellKnown"] = 264483,
["notInGroup"] = false, },

{["label"] = "Cataclysm  Fishing", ["frameID"] = "list1", ["key"] = "custom:spell:list1:89",
["hideWhenCompleted"] = false,
["notSpellKnown"] = 271660,
["notInGroup"] = false, },

{["label"] = "Cataclysm  Herbalism", ["frameID"] = "list1", ["key"] = "custom:spell:list1:90",
["hideWhenCompleted"] = false,
["notSpellKnown"] = 265825,
["notInGroup"] = false, },

{["label"] = "Cataclysm  Mining", ["frameID"] = "list1", ["key"] = "custom:spell:list1:91",
["hideWhenCompleted"] = false,
["notSpellKnown"] = 265843,
["notInGroup"] = false, },

{["label"] = "Cataclysm  Skinning", ["frameID"] = "list1", ["key"] = "custom:spell:list1:92",
["hideWhenCompleted"] = false,
["notSpellKnown"] = 265861,
["notInGroup"] = false, },

{["label"] = "Cataclysm  Tailoring", ["frameID"] = "list1", ["key"] = "custom:spell:list1:93",
["hideWhenCompleted"] = false,
["notSpellKnown"] = 264622,
["notInGroup"] = false, },

}

for i = 1, #bakedRules do
  local r = bakedRules[i]
  if type(r) == "table" then
    if type(r.key) == "string" then
      r.key = r.key:gsub("^custom:", "db:")
    end
    ns.rules[#ns.rules + 1] = r
  end
end
