local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB09 (Shadowlands)

ns.rules = ns.rules or {}

local EXPANSION_ID = 9
local EXPANSION_NAME = "Shadowlands"

local Y, N = true, false

local bakedRules = {

{["label"] = "SU  09  Open", ["frameID"] = "list1", ["key"] = "custom:q:60151:list1:11",
["questID"] = 60150, ["hideWhenCompleted"] = true, ["hideIfAnyQuestCompleted"] = { 60151, 61874, 999999 },
["questInfo"] = "Warboard   (Accept if there)\n    - Chromie\n    - Legion\n    - Warlords\n    - Jade Forest\n\nShadowlands\n + Chromie: Shadowlands\n + Enter Shadowlands\n    - Skip Quests at Broker NPC\n    - Learn Professions\nToDo", },

{["itemName"] = "The Brokers Angle'r", ["frameID"] = "list1", ["key"] = "custom:item:180136:list1:145",
["itemInfo"] = "The Brokers Angle'r", ["itemID"] = 180136, ["required"] = 1, 
["locationID"] = "1670", ["restedOnly"] = true, ["item"] = { ["required"] = { 1, true }, }, },

{["label"] = "Shadowlands Cooking", ["frameID"] = "list1", ["key"] = "custom:spell:list1:144",
["spellInfo"] = "Shadowlands Cooking", ["notSpellKnown"] = 309830, ["spellKnown"] = 264638, 
["locationID"] = "1670", ["hideWhenCompleted"] = false, ["notInGroup"] = false, },

{["label"] = "Shadowlands Engineering", ["frameID"] = "list1", ["key"] = "custom:spell:list1:151",
["spellInfo"] = "Shadowlands Engineering", ["notSpellKnown"] = 310542, ["spellKnown"] = 264483,
["locationID"] = "1670", ["notInGroup"] = false, ["hideWhenCompleted"] = false, },

{["label"] = "Shadowlands Fishing", ["frameID"] = "list1", ["key"] = "custom:spell:list1:146",
["spellInfo"] = "Shadowlands Fishing", ["notSpellKnown"] = 310675, ["spellKnown"] = 271660,
["locationID"] = "1670", ["hideWhenCompleted"] = false, ["notInGroup"] = false, },

{["label"] = "Shadowlands Herbalism", ["frameID"] = "list1", ["key"] = "custom:spell:list1:150",
["spellInfo"] = "Shadowlands Herbalism", ["notSpellKnown"] = 309780, ["spellKnown"] = 265825,
["locationID"] = "1670", ["hideWhenCompleted"] = false, ["notInGroup"] = false, },

{["label"] = "Shadowlands Mining", ["frameID"] = "list1", ["key"] = "custom:spell:list1:149",
["spellInfo"] = "Shadowlands Mining", ["notSpellKnown"] = 309835, ["spellKnown"] = 265843,
["locationID"] = "1670", ["hideWhenCompleted"] = false, ["notInGroup"] = false, },

{["label"] = "Shadowlands Skinning", ["frameID"] = "list1", ["key"] = "custom:spell:list1:148",
["spellInfo"] = "Shadowlands Skinning", ["notSpellKnown"] = 308569, ["spellKnown"] = 265861,
["locationID"] = "1670", ["hideWhenCompleted"] = false, ["notInGroup"] = false, },

{["label"] = "Shadowlands Tailoring", ["frameID"] = "list1", ["key"] = "custom:spell:list1:147",
["spellInfo"] = "Shadowlands Tailoring", ["notSpellKnown"] = 310949, ["spellKnown"] = 264622,
["locationID"] = "1670", ["hideWhenCompleted"] = false, ["notInGroup"] = false, },

--{["label"] = "Warboard   (Accept if there)\n    - Chromie\n    - Legion\n    - Warlords\n    - Jade Forest\n\nShadowlands\n + Chromie: Shadowlands\n + Enter Shadowlands\n    - Skip Quests at Broker NPC\n    - Learn Professions", ["frameID"] = "list1", ["key"] = "custom:spell:list1:152",
--["hideWhenCompleted"] = false,
--["notInGroup"] = false,
--["notSpellKnown"] = 310542, },

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
