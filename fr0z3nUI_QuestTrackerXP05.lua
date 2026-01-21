local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB05 (Mists of Pandaria)

ns.rules = ns.rules or {}

local bakedRules = {

{["label"] = "SU  05  Jade Forest  A", ["frameID"] = "list1", ["key"] = "custom:q:29562:list1:13",
["questID"] = 29562, ["prereq"] = { 34775, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Mists of Pandaria\n + Warboard: Jade Forest\n + Jade Forest (Zygor)\n      Until 'Jail Break'\n07N",
["faction"] = "Alliance", },

{["label"] = "SU  05  Jade Forest  H", ["frameID"] = "list1", ["key"] = "custom:q:29822:list1:14",
["questID"] = 29822, ["prereq"] = { 34960, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Mists of Pandaria\n + Warboard: Jade Forest\n + Jade Forest (Zygor)\n       Until \"Lay of the Land\"\n07N",
["faction"] = "Horde", },

{["label"] = "SU  05  Kun-Lai  A", ["frameID"] = "list1", ["key"] = "custom:q:30515:list1:14",
["questID"] = 30515, ["prereq"] = { 29562, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Mists of Pandaria  Level 20\n + Kun-Lai Summit (Zygor)\n      9  Do Village Quests\n    47  Complete\n      \"Challenge Accepted\"\n05A",
["faction"] = "Alliance", },

{["label"] = "SU  05  Kun-Lai  H", ["frameID"] = "list1", ["key"] = "custom:q:30515:list1:15",
["questID"] = 30515, ["prereq"] = { 29822, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Mists of Pandaria  Level 20\n + Kun-Lai Summit (Zygor)\n      Until \"Challenge Accepted\" \n07N",
["faction"] = "Horde", },

{["label"] = "SU  05  Kun-Lai  Sprite's Cloth Chest", ["frameID"] = "list1", ["key"] = "custom:q:31412:list1:16",
["questID"] = 31412, ["prereq"] = { 29562, }, ["hideWhenCompleted"] = true,
["questInfo"] = "+ Sprites Cloth Chest\n  - Need Steadfast\n  - Tried:\n       DK BL/UH - Strong\n07N", },

{["frameID"] = "list1", ["key"] = "custom:item:83080:list1:131",
["hideWhenCompleted"] = false,
["rep"] = { ["sellWhenExalted"] = true, ["factionID"] = 1352, },
["faction"] = "Horde",
["item"] = { ["hideWhenAcquired"] = true, ["itemID"] = 83080, ["required"] = 1, },
["restedOnly"] = true, },

{["frameID"] = "list1", ["key"] = "custom:item:83079:list1:138",
["hideWhenCompleted"] = false,
["rep"] = { ["sellWhenExalted"] = true, ["factionID"] = 1353, },
["faction"] = "Alliance",
["item"] = { ["hideWhenAcquired"] = true, ["itemID"] = 83079, ["required"] = 1, },
["restedOnly"] = true, },

{["label"] = "Pandaria Herbalism", ["frameID"] = "list1", ["key"] = "custom:spell:list1:94",
["hideWhenCompleted"] = false,
["spellKnown"] = 265825,
["notSpellKnown"] = 265827,
["locationID"] = 6666666,
["notInGroup"] = false, },

{["label"] = "Pandaria Mining", ["frameID"] = "list1", ["key"] = "custom:spell:list1:95",
["hideWhenCompleted"] = false,
["spellKnown"] = 265843,
["notSpellKnown"] = 265845,
["locationID"] = 6666666,
["notInGroup"] = false, },

{["label"] = "Pandaria Skinning", ["frameID"] = "list1", ["key"] = "custom:spell:list1:96",
["hideWhenCompleted"] = false,
["spellKnown"] = 265861,
["notSpellKnown"] = 265863,
["locationID"] = 6666666,
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
