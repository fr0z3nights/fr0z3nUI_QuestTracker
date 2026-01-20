local addonName, ns = ...

-- Import recovered rules into the addon database (ns.rules).
-- This makes the recovered WA/QuestTracker rules part of the addon DB instead of account SavedVariables.

local function DeepCopy(v, seen)
  if type(v) ~= "table" then return v end
  seen = seen or {}
  if seen[v] then return seen[v] end
  local out = {}
  seen[v] = out
  for k2, v2 in pairs(v) do
    out[DeepCopy(k2, seen)] = DeepCopy(v2, seen)
  end
  return out
end

local function AppendRecoveredRulesToDB()
  if type(ns) ~= "table" then return 0 end
  if type(ns.rules) ~= "table" then ns.rules = {} end

  local seed = ns._seedAcc
  local rules = seed and seed.settings and seed.settings.customRules
  if type(rules) ~= "table" then return 0 end

  local existing = {}
  for _, r in ipairs(ns.rules) do
    if type(r) == "table" and r.key ~= nil then
      existing[tostring(r.key)] = true
    end
  end

  local added = 0
  for _, r in ipairs(rules) do
    if type(r) == "table" then
      local origKey = (r.key ~= nil) and tostring(r.key) or nil
      local bakedKey = origKey and ("baked:" .. origKey) or nil

      if bakedKey and existing[bakedKey] then
        -- already imported
      else
        local rr = DeepCopy(r)
        rr.key = bakedKey or rr.key
        ns.rules[#ns.rules + 1] = rr
        if bakedKey then existing[bakedKey] = true end
        added = added + 1
      end
    end
  end

  ns._importedDBRulesCount = added
  return added
end

AppendRecoveredRulesToDB()
