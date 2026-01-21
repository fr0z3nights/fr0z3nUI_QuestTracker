local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB10 (Dragonflight)

ns.rules = ns.rules or {}

local bakedRules = {

{["label"] = "SU  10  Dragon Isles  34 Slot Bag", ["frameID"] = "list1", ["key"] = "custom:q:65646:list1:84",
["questID"] = 65646, ["prereq"] = { 67700, }, ["hideWhenCompleted"] = true,
["questInfo"] = "+ 34 Bag in Dragon Isles\n   WS 58,53 %c\n07N", },

{["label"] = "SU  10  Dragon Isles  Q-67700  65445  Horde", ["frameID"] = "list1", ["key"] = "custom:q:67700:list1:85",
["questID"] = 67700, ["prereq"] = { 30515, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Dragon Isles  (H)\n + Use Dragon Scale\n    or Cata Portal Area\n + Do Initial Quests\n + Take Portal\nWiggling Egg",
["faction"] = "Horde", },

{["label"] = "SU  10  Dragon Isles  Q-67700  65444  Alliance", ["frameID"] = "list1", ["key"] = "custom:q:67700:list1:86",
["questID"] = 67700, ["prereq"] = { 30515, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Dragon Isles\n + Use Dragon Scale\n    or Castle Balcony\n + Do Initial Quests\n + Take Portal\nWiggling Egg",
["faction"] = "Alliance", },

{["label"] = "Dragon Isles  Cooking", ["frameID"] = "list1", ["key"] = "custom:spell:list1:153",
["hideWhenCompleted"] = false,
["notInGroup"] = false,
["spellKnown"] = 264638,
["notSpellKnown"] = 366256, },

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
