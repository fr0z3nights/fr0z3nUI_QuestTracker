local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB06 (Warlords of Draenor)

ns.rules = ns.rules or {}

local bakedRules = {

{["label"] = "SU  06  Garrison 01 A", ["frameID"] = "list1", ["key"] = "custom:q:36941:list1:17",
["questID"] = 36941, ["prereq"] = { 47189, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Warlords of Draenor\n%c\n+ Warboard: The Dark Portal\\n + Talk to Battlemage\\n   - Portal Tower Entrance\\n   - After Port Abandom Quest\\n + Iron Horde Invasion (Zygor)",
["faction"] = "Alliance", },

{["label"] = "SU  06  Garrison 02 A", ["frameID"] = "list1", ["key"] = "custom:q:34586:list1:18",
["questID"] = 34586, ["prereq"] = { 36941, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Warlords of Draenor\n%c\n+ Warboard: The Dark Portal\\n + Talk to Battlemage\\n   - In Portal Tower Entrance\\n   - After Port Abandom Quest\\n   - Take Red Portal (Draenor)\\n   - Do Initial Quests",
["faction"] = "Alliance", },

{["label"] = "SU  06  Garrison 03 A", ["frameID"] = "list1", ["key"] = "custom:q:34775:list1:19",
["questID"] = 34775, ["prereq"] = { 34586, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Warlords of Draenor\n + Zygor: Shadowmoon Valley\n    01-31 \"Delegating on Draenor\"",
["faction"] = "Alliance", },

{["label"] = "SU  06  Garrison 01 H", ["frameID"] = "list1", ["key"] = "custom:q:36940:list1:20",
["questID"] = 36940, ["prereq"] = { 47514, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Warlords of Draenor\n%c\n+ Warboard: The Dark Portal\\n + Talk to Battlemage\\n   - Lower Portal Room\\n   - After Port Abandom Quest\\n + Iron Horde Invasion (Zygor)",
["faction"] = "Horde", },

{["label"] = "SU  06  Garrison 02 H", ["frameID"] = "list1", ["key"] = "custom:q:34586:list1:21",
["questID"] = 34586, ["prereq"] = { 36940, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Warlords of Draenor\n%c\n+ Warboard: The Dark Portal\\n + Talk to Battlemage\\n   - Lower Portal Room\\n   - After Port Abandom Quest\\n   - Take Red Portal (Draenor)\\n   - Do Initial Quests",
["faction"] = "Horde", },

{["label"] = "SU  06  Garrison 03 H", ["frameID"] = "list1", ["key"] = "custom:q:34960:list1:22",
["questID"] = 34960, ["prereq"] = { 34586, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Warlords of Draenor\n + Frostfire Ridge (Zygor)\n + Quest Until Step 26\n     ' The Land Provides'\n",
["faction"] = "Horde", },

{["label"] = "SU  06  Garrison 04 H", ["frameID"] = "list1", ["key"] = "custom:q:36567:list1:23",
["questID"] = 36567, ["prereq"] = { 34960, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Warlords of Draenor\n + Collect 200 Garrison Resources\n + Upgrade Garrison to Level 2\n              (Turn in Quest)",
["faction"] = "Horde", },

{["label"] = "SU  06  Wiggling Egg (Pet)", ["frameID"] = "list1", ["key"] = "custom:q:33505:list1:24",
["questID"] = 33505, ["prereq"] = { 34586, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Frostfire Ridge\n + Wiggling Egg",
["locationID"] = 525, },

{["label"] = "+ Goblin Gliders  %s", ["frameID"] = "list1", ["key"] = "custom:item:109076:list1:125",
["hideWhenCompleted"] = false,
["restedOnly"] = true,
["item"] = { ["hideWhenAcquired"] = true, ["itemID"] = 109076, ["required"] = 1, }, },

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
