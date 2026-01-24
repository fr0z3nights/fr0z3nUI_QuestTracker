local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB03 (Wrath of the Lich King)

ns.rules = ns.rules or {}

local EXPANSION_ID = 3
local EXPANSION_NAME = "Wrath of the Lich King"

local bakedRules = {

{["label"] = "Kirin Tor Ring\n + Filter 'All\", Ring 1", ["frameID"] = "list1", ["key"] = "custom:item:40586:list1:81",
["hideWhenCompleted"] = false,
["playerLevel"] = 70,
["playerLevelOp"] = ">",
["faction"] = "Horde",
["restedOnly"] = true,
["item"] = { ["hideWhenAcquired"] = true, ["itemID"] = 40586, ["required"] = 1, }, },

{["label"] = "+ Red Rider Air RIfle Ammo", ["frameID"] = "list1", ["key"] = "custom:item:48601:list1:126",
["hideWhenCompleted"] = false,
["restedOnly"] = true,
["item"] = { ["hideWhenAcquired"] = true, ["itemID"] = 48601, ["required"] = 1, }, },

{["label"] = "Red Rider Air RIfle", ["frameID"] = "list1", ["key"] = "custom:item:46725:list1:127",
["hideWhenCompleted"] = false,
["restedOnly"] = true,
["item"] = { ["hideWhenAcquired"] = true, ["itemID"] = 46725, ["required"] = 1, }, },

{["label"] = "Argent Crusader's Tabard\n+ 50 Champion Seals", ["frameID"] = "list1", ["key"] = "custom:item:46874:list1:128",
["hideWhenCompleted"] = false,
["restedOnly"] = true,
["item"] = { ["hideWhenAcquired"] = true, ["itemID"] = 46874, ["required"] = 1, ["currencyRequired"] = 50, ["currencyID"] = 241, }, },

{["frameID"] = "list1", ["key"] = "custom:item:45583:list1:130",
["hideWhenCompleted"] = false,
["rep"] = { ["sellWhenExalted"] = true, ["factionID"] = 68, },
["faction"] = "Horde",
["item"] = { ["hideWhenAcquired"] = true, ["itemID"] = 45583, ["required"] = 1, },
["restedOnly"] = true, },

{["frameID"] = "list1", ["key"] = "custom:item:45582:list1:133",
["hideWhenCompleted"] = false,
["rep"] = { ["sellWhenExalted"] = true, ["factionID"] = 530, },
["faction"] = "Horde",
["item"] = { ["hideWhenAcquired"] = true, ["itemID"] = 45582, ["required"] = 1, },
["restedOnly"] = true, },

{["frameID"] = "list1", ["key"] = "custom:item:45581:list1:134",
["hideWhenCompleted"] = false,
["rep"] = { ["sellWhenExalted"] = true, ["factionID"] = 76, },
["faction"] = "Horde",
["item"] = { ["hideWhenAcquired"] = true, ["itemID"] = 45581, ["required"] = 1, },
["restedOnly"] = true, },

{["frameID"] = "list1", ["key"] = "custom:item:45580:list1:135",
["hideWhenCompleted"] = false,
["rep"] = { ["sellWhenExalted"] = true, ["factionID"] = 930, },
["faction"] = "Alliance",
["item"] = { ["hideWhenAcquired"] = true, ["itemID"] = 45580, ["required"] = 1, },
["restedOnly"] = true, },

{["frameID"] = "list1", ["key"] = "custom:item:45579:list1:137",
["hideWhenCompleted"] = false,
["rep"] = { ["sellWhenExalted"] = true, ["factionID"] = 69, },
["faction"] = "Alliance",
["item"] = { ["hideWhenAcquired"] = true, ["itemID"] = 45579, ["required"] = 1, },
["restedOnly"] = true, },

{["frameID"] = "list1", ["key"] = "custom:item:45574:list1:139",
["hideWhenCompleted"] = false,
["rep"] = { ["sellWhenExalted"] = true, ["factionID"] = 72, },
["faction"] = "Alliance",
["item"] = { ["hideWhenAcquired"] = true, ["itemID"] = 45574, ["required"] = 1, },
["restedOnly"] = true, },

{["frameID"] = "list1", ["key"] = "custom:item:45585:list1:140",
["hideWhenCompleted"] = false,
["rep"] = { ["sellWhenExalted"] = true, ["factionID"] = 911, },
["faction"] = "Horde",
["item"] = { ["hideWhenAcquired"] = true, ["itemID"] = 45585, ["required"] = 1, },
["restedOnly"] = true, },

{["frameID"] = "list1", ["key"] = "custom:item:45584:list1:141",
["hideWhenCompleted"] = false,
["rep"] = { ["sellWhenExalted"] = true, ["factionID"] = 81, },
["faction"] = "Horde",
["item"] = { ["hideWhenAcquired"] = true, ["itemID"] = 45584, ["required"] = 1, },
["restedOnly"] = true, },

{["frameID"] = "list1", ["key"] = "custom:item:45578:list1:142",
["hideWhenCompleted"] = false,
["rep"] = { ["sellWhenExalted"] = true, ["factionID"] = 54, },
["faction"] = "Alliance",
["item"] = { ["hideWhenAcquired"] = true, ["itemID"] = 45578, ["required"] = 1, },
["restedOnly"] = true, },

{["frameID"] = "list1", ["key"] = "custom:item:45577:list1:143",
["hideWhenCompleted"] = false,
["rep"] = { ["sellWhenExalted"] = true, ["factionID"] = 47, },
["faction"] = "Alliance",
["item"] = { ["hideWhenAcquired"] = true, ["itemID"] = 45577, ["required"] = 1, },
["restedOnly"] = true, },

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
