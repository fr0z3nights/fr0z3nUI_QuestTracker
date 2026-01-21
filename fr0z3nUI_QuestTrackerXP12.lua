local addonName, ns = ...

-- Expansion DB12 (Midnight)

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
