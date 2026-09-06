local addonName, ns = ...

ns.GuideHelpers = ns.GuideHelpers or {}

local Y, N = true, false
local REQ_BUY_ON, REQ_BUY_MAX = 3, 4

function ns.GuideHelpers.NormalizeRule(rule, expansionID, expansionName)
  if type(rule) ~= "table" then return false end

  if rule._expansionID == nil then rule._expansionID = expansionID end
  if rule._expansionName == nil then rule._expansionName = expansionName end
  if rule.questXY == nil and tonumber(rule.questID) and rule.qXept == nil then
    rule.qXept = "N"
  end
  if type(rule.key) == "string" then
    rule.key = rule.key:gsub("^custom:", "db:")
  end

  if type(rule.item) == "table" and rule.item.itemID then
    local required = rule.item.required
    local buyOn, buyMax
    if type(required) == "table" then
      buyOn = (required[REQ_BUY_ON] == Y) and Y or N
      buyMax = tonumber(required[REQ_BUY_MAX]) or 0
      if buyMax < 0 then buyMax = 0 end
    end

    if type(rule.item.buy) ~= "table" then
      rule.item.buy = { enabled = N, max = 0 }
    end
    if buyOn ~= nil then
      rule.item.buy.enabled = buyOn
      rule.item.buy.max = buyMax or 0
    else
      if rule.item.buy.enabled ~= Y then rule.item.buy.enabled = N end
      local maxQty = tonumber(rule.item.buy.max) or 0
      if maxQty < 0 then maxQty = 0 end
      rule.item.buy.max = maxQty
    end
  end

  if type(rule.mapID) == "table" and type(ns.ExpandMapIDs) == "function" then
    rule.mapID = ns.ExpandMapIDs(rule.mapID)
  end

  return true
end

function ns.GuideHelpers.NormalizeRules(rules, expansionID, expansionName)
  if type(rules) ~= "table" then return rules end
  for i = 1, #rules do
    ns.GuideHelpers.NormalizeRule(rules[i], expansionID, expansionName)
  end
  return rules
end
