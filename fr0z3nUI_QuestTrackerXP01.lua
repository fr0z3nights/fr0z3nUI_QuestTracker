local addonName, ns = ...

-- Expansion DB01 (Classic)

ns.rules = ns.rules or {}

local EXPANSION_ID = 1
local EXPANSION_NAME = "Classic"

local Y, N = true, false

local bakedRules = {

-- ALLIANCE TABARDS
{["label"] = "Stormwind Tabard", ["faction"] = "Alliance", ["frameID"] = "list1", ["key"] = "custom:item:45574:list1:139",
["itemInfo"] = "Stormwind Tabard", ["rep"] = { ["sellWhenExalted"] = Y, ["factionID"] = 72, }, 
["item"] = { ["itemID"] = 45574, ["required"] = { 1, Y }, }, ["locationID"] = "84, 85, ", ["restedOnly"] = Y,},

{["label"] = "Tushui Tabard", ["faction"] = "Alliance", ["frameID"] = "list1", ["key"] = "custom:item:83079:list1:138",
["itemInfo"] = "Tushui Tabard", ["rep"] = { ["sellWhenExalted"] = true, ["factionID"] = 1353, }, 
["item"] = { ["itemID"] = 83079, ["required"] = { 1, true }, }, ["locationID"] = "84, 85,", ["restedOnly"] = true, },

{["label"] = "Darnassus Tabard", ["faction"] = "Alliance", ["frameID"] = "list1", ["key"] = "custom:item:45579:list1:137",
["itemInfo"] = "Darnassus Tabard", ["rep"] = { ["sellWhenExalted"] = Y, ["factionID"] = 69, }, 
["item"] = { ["itemID"] = 45579, ["required"] = { 1, Y }, }, ["locationID"] = "999999", ["restedOnly"] = Y,},

{["label"] = "Exodar Tabard", ["faction"] = "Alliance", ["frameID"] = "list1", ["key"] = "custom:item:45580:list1:135",
["itemInfo"] = "Take Portal to Exodar\n Buy Exodar Tabard", ["rep"] = { ["sellWhenExalted"] = Y, ["factionID"] = 930, }, 
["item"] = { ["itemID"] = 45580, ["required"] = { 1, Y }, }, ["locationID"] = "999999", ["restedOnly"] = Y,},

{["label"] = "Gnomeregan Tabard", ["faction"] = "Alliance", ["frameID"] = "list1", ["key"] = "custom:item:45578:list1:142",
["itemInfo"] = "Gnomeregan Tabard", ["rep"] = { ["sellWhenExalted"] = Y, ["factionID"] = 54, },
["item"] = { ["itemID"] = 45578, ["required"] = { 1, Y }, }, ["locationID"] = "999999", ["restedOnly"] = Y,},

{["label"] = "Ironforge Tabard", ["faction"] = "Alliance", ["frameID"] = "list1", ["key"] = "custom:item:45577:list1:143",
["itemInfo"] = "Ironforge Tabard", ["rep"] = { ["sellWhenExalted"] = Y, ["factionID"] = 47, },
["item"] = { ["itemID"] = 45577, ["required"] = { 1, Y }, }, ["locationID"] = "999999", ["restedOnly"] = Y, },

{["label"] = "Gilneas Tabard", ["faction"] = "Alliance", ["frameID"] = "list1", ["key"] = "custom:item:64882:list1:136",
["itemInfo"] = "Gilneas Tabard", ["rep"] = { ["sellWhenExalted"] = true, ["factionID"] = 1134, },
["item"] = { ["itemID"] = 64882, ["required"] = { 1, Y }, }, ["locationID"] = "1133", ["restedOnly"] = true, },


-- HORDE TABARDS
{["label"] = "Orgrimmar Tabard", ["faction"] = "Horde", ["frameID"] = "list1", ["key"] = "custom:item:45581:list1:134",
["itemInfo"] = "Orgrimmar Tabard", ["rep"] = { ["sellWhenExalted"] = Y, ["factionID"] = 76, },
["item"] = { ["itemID"] = 45581, ["required"] = { 1, Y }, }, ["locationID"] = "84, 85", ["restedOnly"] = Y, },

{["label"] = "Darkspear Tabard", ["faction"] = "Horde", ["frameID"] = "list1", ["key"] = "custom:item:45582:list1:133",
["itemInfo"] = "Darkspear Tabard", ["rep"] = { ["sellWhenExalted"] = Y, ["factionID"] = 530, },
["item"] = { ["itemID"] = 45582, ["required"] = { 1, Y }, }, ["locationID"] = "84, 85", ["restedOnly"] = Y, },

{["label"] = "Bilgewater Tabard", ["faction"] = "Horde", ["frameID"] = "list1", ["key"] = "custom:item:64884:list1:132",
["itemInfo"] = "Bilgewater Tabard", ["rep"] = { ["sellWhenExalted"] = Y, ["factionID"] = 1133, },
["item"] = { ["itemID"] = 64884, ["required"] = { 1, Y }, }, ["locationID"] = "84, 85, ", ["restedOnly"] = true, },

{["label"] = "Undercity Tabard", ["faction"] = "Horde", ["frameID"] = "list1", ["key"] = "custom:item:45583:list1:130",
["itemInfo"] = "Undercity Tabard", ["rep"] = { ["sellWhenExalted"] = Y, ["factionID"] = 68, },
["item"] = { ["itemID"] = 45583, ["required"] = { 1, Y }, }, ["locationID"] = "84, 85", ["restedOnly"] = Y, },

{["label"] = "Huojin Tabard", ["faction"] = "Horde", ["frameID"] = "list1", ["key"] = "custom:item:83080:list1:131",
["itemInfo"] = "Huojin Tabard", ["rep"] = { ["sellWhenExalted"] = Y, ["factionID"] = 1352, },
["item"] = { ["itemID"] = 83080, ["required"] = { 1, true }, }, ["locationID"] = "84, 85,", ["restedOnly"] = true, },

{["label"] = "Silvermoon Tabard", ["faction"] = "Horde", ["frameID"] = "list1", ["key"] = "custom:item:45585:list1:140",
["itemInfo"] = "Silvermoon Tabard", ["rep"] = { ["sellWhenExalted"] = Y, ["factionID"] = 911, },
["item"] = { ["itemID"] = 45585, ["required"] = { 1, Y }, }, ["locationID"] = "999999", ["restedOnly"] = Y, },

{["label"] = "Thunder Bluff Tabard", ["faction"] = "Horde", ["frameID"] = "list1", ["key"] = "custom:item:45584:list1:141",
["itemInfo"] = "Thunder Bluff Tabard", ["rep"] = { ["sellWhenExalted"] = Y, ["factionID"] = 81, },
["item"] = { ["itemID"] = 45584, ["required"] = { 1, Y }, }, ["locationID"] = "999999", ["restedOnly"] = Y, },


-- NEUTRAL ITEMS
{["label"]   = "Red Rider Air RIfle", ["frameID"] = "list1", ["key"] = "custom:item:46725:list1:127",
["itemInfo"] = "Red Rider Air RIfle", ["locationID"] = "84, 85", ["restedOnly"] = Y,
["item"] = { ["itemID"] = 46725, ["required"] = { 1, Y }, }, },

{["label"]   = "Red Rider Air Ammo", ["frameID"] = "list1", ["key"] = "custom:item:48601:list1:126",
["itemInfo"] = "Red Rider Air Ammo", ["locationID"] = "84, 85", ["restedOnly"] = Y,
["item"] = { ["itemID"] = 48601, ["required"] = { 1, Y }, }, },

{["label"]   = "Goblin Gliders", ["frameID"] = "list1", ["key"] = "custom:item:109076:list1:125",
["itemInfo"] = "Goblin Gliders", ["hideWhenCompleted"] = N, ["restedOnly"] = Y,
["item"] = { ["itemID"] = 109076, ["required"] = { 5, Y }, }, },

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
