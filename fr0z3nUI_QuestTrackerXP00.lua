local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB00 (Unknown/Unclassified)

ns.rules = ns.rules or {}

local bakedRules = {
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
