local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB03 (Wrath of the Lich King)

ns.rules = ns.rules or {}

local EXPANSION_ID = 3
local EXPANSION_NAME = "Wrath of the Lich King"

local Y, N = true, false

local bakedRules = {

{["label"] = "Kirin Tor Ring",
["itemInfo"] = "Kirin Tor Ring\n + Filter 'All'\", Ring 1 (40586)", ["frameID"] = "list1", ["key"] = "custom:item:40586:list1:81",
["playerLevel"] = { ">", 70, }, ["locationID"] = "85, 86, ", ["restedOnly"] = true, 
["item"] = { ["itemID"] = 40586, ["required"] = { 1, true }, }, },

{["label"] = "Argent Crusader's Tabard",
["itemInfo"] = "Argent Crusader's Tabard\n+ 50 Champion Seals (WB)", ["frameID"] = "list1", ["key"] = "custom:item:46874:list1:128",
["playerLevel"] = { ">", 70, }, ["locationID"] = "999999", ["restedOnly"] = true,
 ["item"] = { ["itemID"] = 46874, ["required"] = { 1, true }, ["currencyID"] = { 241, 50 }, }, },



-- ["itemInfo"] = "Orgrimmar Tabard", 
-- ["locationID"] = "999999", 













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
