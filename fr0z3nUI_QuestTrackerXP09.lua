local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB09 (Shadowlands)

ns.rules = ns.rules or {}

local EXPANSION_ID = 9
local EXPANSION_NAME = "Shadowlands"

local bakedRules = {

{["label"] = "SU  09  Open", ["frameID"] = "list1", ["key"] = "custom:q:60151:list1:11",
["questID"] = 60151, ["hideWhenCompleted"] = true,
["questInfo"] = "Warboard   (Accept if there)\n    - Chromie\n    - Legion\n    - Warlords\n    - Jade Forest\n\nShadowlands\n + Chromie: Shadowlands\n + Enter Shadowlands\n    - Skip Quests at Broker NPC\n    - Learn Professions\nToDo", },

{["frameID"] = "list1", ["key"] = "custom:item:180136:list1:145",
["hideWhenCompleted"] = false,
["locationID"] = "10565,13863",
["item"] = { ["hideWhenAcquired"] = true, ["itemID"] = 180136, ["required"] = 1, },
["restedOnly"] = true, },

{["label"] = "Shadowlands Cooking", ["frameID"] = "list1", ["key"] = "custom:spell:list1:144",
["hideWhenCompleted"] = false,
["notInGroup"] = false,
["locationID"] = "696969",
["notSpellKnown"] = 309830,
["spellKnown"] = 264638, },

{["label"] = "Shadowlands Fishing", ["frameID"] = "list1", ["key"] = "custom:spell:list1:146",
["hideWhenCompleted"] = false,
["notInGroup"] = false,
["locationID"] = "696969",
["notSpellKnown"] = 310675,
["spellKnown"] = 271660, },

{["label"] = "Shadowlands Tailoring", ["frameID"] = "list1", ["key"] = "custom:spell:list1:147",
["hideWhenCompleted"] = false,
["notInGroup"] = false,
["locationID"] = "696969",
["notSpellKnown"] = 310949,
["spellKnown"] = 264622, },

{["label"] = "Shadowlands Skinning", ["frameID"] = "list1", ["key"] = "custom:spell:list1:148",
["hideWhenCompleted"] = false,
["notInGroup"] = false,
["locationID"] = "696969",
["notSpellKnown"] = 308569,
["spellKnown"] = 265861, },

{["label"] = "Shadowlands Mining", ["frameID"] = "list1", ["key"] = "custom:spell:list1:149",
["hideWhenCompleted"] = false,
["notInGroup"] = false,
["locationID"] = "696969",
["notSpellKnown"] = 309835,
["spellKnown"] = 265843, },

{["label"] = "Shadowlands Herbalism", ["frameID"] = "list1", ["key"] = "custom:spell:list1:150",
["hideWhenCompleted"] = false,
["notInGroup"] = false,
["locationID"] = "696969",
["notSpellKnown"] = 309780,
["spellKnown"] = 265825, },

{["label"] = "Shadowlands Engineering", ["frameID"] = "list1", ["key"] = "custom:spell:list1:151",
["hideWhenCompleted"] = false,
["notInGroup"] = false,
["locationID"] = "696969",
["notSpellKnown"] = 310542,
["spellKnown"] = 264483, },

{["label"] = "Warboard   (Accept if there)\n    - Chromie\n    - Legion\n    - Warlords\n    - Jade Forest\n\nShadowlands\n + Chromie: Shadowlands\n + Enter Shadowlands\n    - Skip Quests at Broker NPC\n    - Learn Professions", ["frameID"] = "list1", ["key"] = "custom:spell:list1:152",
["hideWhenCompleted"] = false,
["notInGroup"] = false,
["notSpellKnown"] = 310542, },

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
