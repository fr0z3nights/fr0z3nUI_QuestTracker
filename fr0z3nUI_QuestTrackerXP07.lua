local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB07 (Legion)

ns.rules = ns.rules or {}

local bakedRules = {

{["label"] = "SU  07  Karazhan 01", ["frameID"] = "list1", ["key"] = "custom:q:45727:list1:1",
["questID"] = 45727, ["prereq"] = {46931, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Legion\n + Unlock Legion World Quests\n   - Khadgar \"Uniting the Isles\"", },

{["label"] = "SU  07  Karazhan 02", ["frameID"] = "list1", ["key"] = "custom:q:44733:list1:2",
["questID"] = 44733, ["prereq"] = { 45727, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Legion\n + Karazhan Attunement (Zygor)\n      Skip to 12\n + Pickup !Waterlogged Journal\nNotes:\n    - Turn off Instance Reset", },

{["label"] = "SU  07  Karazhan 03", ["frameID"] = "list1", ["key"] = "custom:q:44735:list1:3",
["questID"] = 44735, ["prereq"] = { 44733, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Legion\n + Karazhan Attunement (Zygor)\n + Quests: Fragments & Eye\n + Enter HEROIC Dungeon\n    - Turn off Instance Reset\n + Crystals & Full Clear", },

{["label"] = "SU  07  Karazhan 04", ["frameID"] = "list1", ["key"] = "custom:q:45291:list1:4",
["questID"] = 45291, ["prereq"] = { 44735, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Legion\n + %n\nNotes:\n    - Current Opera: Wikket\n    - Turn off Instance Reset\n    - Front of Karazhan Quest\n       (Centre Legion Dalaran)\nReturn to Karazhan\\n + Quest: Book Wyrms\\n + Re-Enter HEROIC\\n + Clear Library\\n + Create/Leave Group", },

{["label"] = "SU  07  Karazhan 05", ["frameID"] = "list1", ["key"] = "custom:q:45292:list1:5",
["questID"] = 45292, ["prereq"] = { 45291, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Legion\n + %n\nNotes:\n    - Current Opera: Wikket\n    - Turn off Instance Reset\n    - Front of Karazhan Quest\n       (Centre Legion Dalaran)\nReturn to Karazhan\\n + Quest: Rebooting Curator\\n + Reset & Enter HEROIC\\n + Kill Opera, Moroes, Curator\\n + Pickup Item Curator Room\\n + Create/Leave Group", },

{["label"] = "SU  07  Karazhan 06", ["frameID"] = "list1", ["key"] = "custom:q:45293:list1:6",
["questID"] = 45293, ["prereq"] = { 45292, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Legion\n + %n\nNotes:\n    - Current Opera: Wikket\n    - Turn off Instance Reset\n    - Front of Karazhan Quest\n       (Centre Legion Dalaran)\nReturn to Karazhan\\n + Quest: New Shoes\\n +", },

{["label"] = "SU  07  Karazhan 07", ["frameID"] = "list1", ["key"] = "custom:q:45294:list1:7",
["questID"] = 45294, ["prereq"] = { 45293, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Legion\n + %n\nNotes:\n    - Current Opera: Wikket\n    - Turn off Instance Reset\n    - Front of Karazhan Quest\n       (Centre Legion Dalaran)\nReturn to Karazhan\\n + Quest: High Stress Hiatus\\n + Re-Enter HEROIC\\n + Kill Shade/Mana Devourer\\n + Cape Left Wall Chess Room\\n + Create/Leave Group\\n + Reset & Re-Enter\\n + Opera Trash Drops Review\\n + Opera Boss Drops Roses\\n + Kill Moros\\n + Create/Leave Group", },

{["label"] = "SU  07  Karazhan 08", ["frameID"] = "list1", ["key"] = "custom:q:45295:list1:8",
["questID"] = 45295, ["prereq"] = { 45294, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Legion\n + %n\nNotes:\n    - Current Opera: Wikket\n    - Turn off Instance Reset\n    - Front of Karazhan Quest\n       (Centre Legion Dalaran)\nReturn to Karazhan\\n + Quest: Clearing Cobwebs\\n + Re-Enter HEROIC\\n + Kill Opera,", },

{["label"] = "SU  07  Karazhan 09", ["frameID"] = "list1", ["key"] = "custom:q:45296:list1:9",
["questID"] = 45296, ["prereq"] = { 45295, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Legion\n + %n\nNotes:\n    - Current Opera: Wikket\n    - Turn off Instance Reset\n    - Front of Karazhan Quest\n       (Centre Legion Dalaran)\nReturn to Karazhan\\n + Change to MYTHIC & Enter\\n + Get 5 CRYSTALS\\n    Opera, Maiden, Moroes (keys)\\n    Attuman (kill), Spiders, Curator\\n + Back Down Kill Nightbane", },

{["label"] = "SU  07  Hearthstone Unlock", ["frameID"] = "list1", ["key"] = "custom:q:44184:list1:11",
["questID"] = 44184, ["prereq"] = { 60151, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Legion\n + Chromie: Off\n + Warboard: Broken Shore\n + Set Hearth\n + Talk to Quest Guy\n     Orgirmmar - Out Front Gate\n     Stormwind - In the Harbor\n + Skip Scenario if you can\n       Quest Until Getting\n         %2.i %2.n\n07N", },

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
