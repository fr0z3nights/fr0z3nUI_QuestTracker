local addonName, ns = ...

-- Expansion DB02 (The Burning Crusade)

ns.rules = ns.rules or {}

local EXPANSION_ID = 2
local EXPANSION_NAME = "The Burning Crusade"

local bakedRules = {
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
