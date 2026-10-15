local addonName, ns = ...

ns.GuideHelpers = ns.GuideHelpers or {}

local realmHourOffset

function ns.GuideHelpers.ApplyClockCountdowns(text, owners, owner)
  if type(text) ~= "string" then return text, false end
  if not text:find("%cdhr", 1, true) and not text:find("%cdtp", 1, true) then
    return text, false
  end

  local serverTime = GetServerTime()
  if realmHourOffset == nil then
    local _, minute = GetGameTime()
    -- Time zones use quarter-hour offsets; rounding ignores clock rollover skew.
    realmHourOffset = math.floor((minute * 60 - serverTime % 3600) / 900 + 0.5) * 900
  end
  local secondsIntoHour = (serverTime + realmHourOffset) % 3600
  local replacements = {}
  for token, target in pairs({ cdhr = 0, cdtp = 600 }) do
    if text:find("%" .. token, 1, true) then
      if owners[token] == nil then owners[token] = owner end
      local remaining = (target - secondsIntoHour) % 3600
      if remaining == 0 then remaining = 3600 end
      replacements[token] = owners[token] == owner
        and string.format("%dm %02ds", math.floor(remaining / 60), remaining % 60) or ""
    end
  end

  local lines = {}
  local prefix = ""
  for rawLine in (text .. "\n"):gmatch("(.-)\n") do
    local line = rawLine
    local hadToken = line:find("%cdhr", 1, true) or line:find("%cdtp", 1, true)
    line = line:gsub("%%cdhr", replacements.cdhr or "")
    line = line:gsub("%%cdtp", replacements.cdtp or "")
    local visible = line:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("\194\160", " ")
    if hadToken and not visible:find("%S") then
      local colors = line:gsub("[ \t\194\160]", "")
      if #lines > 0 then
        lines[#lines] = lines[#lines] .. colors
      else
        prefix = prefix .. colors
      end
    else
      lines[#lines + 1] = prefix .. line
      prefix = ""
    end
  end
  return table.concat(lines, "\n") .. prefix, true
end

local Y, N = true, false
local REQ_BUY_ON, REQ_BUY_MAX = 3, 4

-- Inline icon texture helper for questInfo/textInfo/spellInfo strings.
-- Usage: ns.GuideHelpers.Icon("Interface\\MoneyFrame\\UI-GoldIcon") or the GOLD_ICON shorthand below.
function ns.GuideHelpers.Icon(path, size)
  size = tonumber(size) or 0
  return "|T" .. tostring(path) .. ":" .. tostring(size) .. "|t"
end

ns.GuideHelpers.GOLD_ICON = ns.GuideHelpers.Icon("Interface\\MoneyFrame\\UI-GoldIcon")

function ns.GuideHelpers.NormalizeRule(rule, expansionID, expansionName)
  if type(rule) ~= "table" then return false end

  if rule._expansionID == nil then rule._expansionID = expansionID end
  if rule._expansionName == nil then rule._expansionName = expansionName end
  if rule.restedOnly == nil then
    if rule.resting ~= nil then
      rule.restedOnly = rule.resting and true or false
    elseif rule.rested ~= nil then
      rule.restedOnly = rule.rested and true or false
    end
  end
  if rule.questXY == nil and tonumber(rule.questID) and rule.qXept == nil then
    rule.qXept = "N"
  end
  if type(rule.key) == "string" then
    rule.key = rule.key:gsub("^custom:", "db:")
  end

  -- DB shorthand: sortGO = { sortGroup, sortOrder }
  if type(rule.sortGO) == "table" then
    if rule.sortGroup == nil then rule.sortGroup = rule.sortGO[1] end
    if rule.sortOrder == nil then rule.sortOrder = tonumber(rule.sortGO[2]) end
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

function ns.GuideHelpers.ExpandQuestGroups(rules)
  if type(rules) ~= "table" then return rules end

  local expanded = {}
  local groupedQuestIDs = {}
  for _, rule in ipairs(rules) do
    if type(rule) == "table" and type(rule.questGroup) == "table" then
      local group = rule.questGroup
      local questIDs = group.questIDs or {}
      for _, questID in ipairs(questIDs) do
        groupedQuestIDs[tonumber(questID)] = true
      end

      local status = group.status
      status.questIDs = questIDs
      status._fromQuestGroup = true
      local completeAny = {}
      for _, questID in ipairs(questIDs) do
        completeAny[#completeAny + 1] = { questID = questID }
      end
      status.complete = { any = completeAny }
      status.completeMode = "replace"
      status.hideIfAnyQuestInLog = true
      expanded[#expanded + 1] = status

      for _, child in ipairs(group.children or {}) do
        child.questIDs = questIDs
        child.hideIfAnyQuestCompleted = true
        child.XDone = nil
        child._fromQuestGroup = true
        expanded[#expanded + 1] = child
      end
    else
      expanded[#expanded + 1] = rule
    end
  end

  if next(groupedQuestIDs) then
    local filtered = {}
    for _, rule in ipairs(expanded) do
      if not (type(rule) == "table" and groupedQuestIDs[tonumber(rule.questID)] and rule._fromQuestGroup ~= true) then
        filtered[#filtered + 1] = rule
      end
    end
    expanded = filtered
  end

  return expanded
end
