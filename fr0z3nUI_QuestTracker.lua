local addonName, ns = ...

local PREFIX = "|cff00ccff[FQT]|r "
local function Print(msg)
  print(PREFIX .. tostring(msg or ""))
end

local framesEnabled = true
local editMode = false

local GetUISetting, SetUISetting
local GetPlayerClass, GetPrimaryProfessionNames, HasTradeSkillLine, CanQueryTradeSkillLines

local function NormalizeSV()
  fr0z3nUI_QuestTracker_Acc = fr0z3nUI_QuestTracker_Acc or {}
  fr0z3nUI_QuestTracker_Char = fr0z3nUI_QuestTracker_Char or {}

  fr0z3nUI_QuestTracker_Acc.settings = fr0z3nUI_QuestTracker_Acc.settings or {}
  fr0z3nUI_QuestTracker_Acc.settings.ui = fr0z3nUI_QuestTracker_Acc.settings.ui or {}
  fr0z3nUI_QuestTracker_Acc.settings.customRules = fr0z3nUI_QuestTracker_Acc.settings.customRules or {}
  fr0z3nUI_QuestTracker_Acc.settings.customFrames = fr0z3nUI_QuestTracker_Acc.settings.customFrames or {}
  fr0z3nUI_QuestTracker_Char.settings = fr0z3nUI_QuestTracker_Char.settings or {}

  fr0z3nUI_QuestTracker_Char.settings.disabledRules = fr0z3nUI_QuestTracker_Char.settings.disabledRules or {}
  fr0z3nUI_QuestTracker_Char.settings.framePos = fr0z3nUI_QuestTracker_Char.settings.framePos or {}

  fr0z3nUI_QuestTracker_Acc.cache = fr0z3nUI_QuestTracker_Acc.cache or {}
  fr0z3nUI_QuestTracker_Acc.cache.weeklyAuras = fr0z3nUI_QuestTracker_Acc.cache.weeklyAuras or {}
end

local function GetCustomRules()
  NormalizeSV()
  local t = fr0z3nUI_QuestTracker_Acc.settings.customRules
  if type(t) ~= "table" then
    t = {}
    fr0z3nUI_QuestTracker_Acc.settings.customRules = t
  end
  return t
end

local function GetCustomFrames()
  NormalizeSV()
  local t = fr0z3nUI_QuestTracker_Acc.settings.customFrames
  if type(t) ~= "table" then
    t = {}
    fr0z3nUI_QuestTracker_Acc.settings.customFrames = t
  end
  return t
end

local function ShallowCopyTable(src)
  if type(src) ~= "table" then return nil end
  local out = {}
  for k, v in pairs(src) do
    out[k] = v
  end
  return out
end

local function GetEffectiveRules()
  local out = {}
  for _, r in ipairs(ns.rules or {}) do out[#out + 1] = r end
  for _, r in ipairs(GetCustomRules()) do out[#out + 1] = r end

  local function AddAuto(rule)
    out[#out + 1] = rule
  end

  -- Auto profession reminders
  local autoProf = GetUISetting("autoProfessionTasks", true)
  local targetFrame = tostring(GetUISetting("autoProfessionFrame", "list1"))
  if targetFrame == "" then targetFrame = "list1" end

  if autoProf then
    local class = GetPlayerClass()
    local suggest
    if class == "HUNTER" then
      suggest = "Mining + Herbalism"
    end

    AddAuto({
      key = "auto:prof:primary1",
      label = "Profession 1",
      frameID = targetFrame,
      showIf = { missingPrimarySlot = 1 },
      extra = suggest and ("Suggested: " .. suggest) or nil,
      hideWhenCompleted = false,
    })

    AddAuto({
      key = "auto:prof:primary2",
      label = "Profession 2",
      frameID = targetFrame,
      showIf = { missingPrimarySlot = 2 },
      extra = suggest and ("Suggested: " .. suggest) or nil,
      hideWhenCompleted = false,
    })

    AddAuto({
      key = "auto:prof:cooking",
      label = "Cooking Missing",
      frameID = targetFrame,
      showIf = { missingSecondary = "cooking" },
      hideWhenCompleted = false,
    })

    AddAuto({
      key = "auto:prof:fishing",
      label = "Fishing Missing",
      frameID = targetFrame,
      showIf = { missingSecondary = "fishing" },
      hideWhenCompleted = false,
    })
  end

  -- Auto expansion-specific profession variants (Shadowlands)
  local autoExp = GetUISetting("autoExpansionProfessionTasks", false)
  if autoExp and CanQueryTradeSkillLines() then
    local shadowlandsNames = {
      ["Alchemy"] = "Shadowlands Alchemy",
      ["Blacksmithing"] = "Shadowlands Blacksmithing",
      ["Enchanting"] = "Shadowlands Enchanting",
      ["Engineering"] = "Shadowlands Engineering",
      ["Herbalism"] = "Shadowlands Herbalism",
      ["Inscription"] = "Shadowlands Inscription",
      ["Jewelcrafting"] = "Shadowlands Jewelcrafting",
      ["Leatherworking"] = "Shadowlands Leatherworking",
      ["Mining"] = "Shadowlands Mining",
      ["Skinning"] = "Shadowlands Skinning",
      ["Tailoring"] = "Shadowlands Tailoring",
    }

    local primaries = GetPrimaryProfessionNames() or {}
    for _, baseName in ipairs(primaries) do
      local variant = shadowlandsNames[baseName]
      if variant and not HasTradeSkillLine(variant) then
        AddAuto({
          key = "auto:prof:sl:" .. tostring(baseName),
          label = variant .. " Missing",
          frameID = targetFrame,
          showIf = { missingTradeSkillLine = variant },
          hideWhenCompleted = false,
        })
      end
    end
  end

  return out
end

local function GetEffectiveFrames()
  -- Merge defaults + custom frames (custom overrides defaults if id matches).
  local base = ns.frames or {}
  local custom = GetCustomFrames()

  local byID = {}
  local ordered = {}

  for _, def in ipairs(base) do
    if type(def) == "table" then
      local id = tostring(def.id or "")
      if id ~= "" and not byID[id] then
        byID[id] = ShallowCopyTable(def)
        ordered[#ordered + 1] = id
      end
    end
  end

  for _, def in ipairs(custom) do
    if type(def) == "table" then
      local id = tostring(def.id or "")
      if id ~= "" then
        if not byID[id] then
          ordered[#ordered + 1] = id
        end
        byID[id] = ShallowCopyTable(def)
      end
    end
  end

  local out = {}
  for _, id in ipairs(ordered) do
    local def = byID[id]
    if def then out[#out + 1] = def end
  end
  return out
end

GetUISetting = function(key, default)
  NormalizeSV()
  local ui = fr0z3nUI_QuestTracker_Acc.settings.ui
  if type(ui) == "table" and ui[key] ~= nil then
    return ui[key]
  end
  return default
end

SetUISetting = function(key, value)
  NormalizeSV()
  fr0z3nUI_QuestTracker_Acc.settings.ui[key] = value
end

local function RuleKey(rule)
  if type(rule) ~= "table" then return nil end
  if rule.key ~= nil then return tostring(rule.key) end
  if rule.questID then return "q:" .. tostring(rule.questID) end
  if rule.label then return "label:" .. tostring(rule.label) end
  if rule.group then return "group:" .. tostring(rule.group) .. ":" .. tostring(rule.order or 0) end
  return nil
end

local function IsRuleDisabled(rule)
  NormalizeSV()
  local key = RuleKey(rule)
  if not key then return false end
  return fr0z3nUI_QuestTracker_Char.settings.disabledRules[key] and true or false
end

local function ToggleRuleDisabled(rule)
  NormalizeSV()
  local key = RuleKey(rule)
  if not key then return end
  local t = fr0z3nUI_QuestTracker_Char.settings.disabledRules
  t[key] = not t[key]
end

local function IsQuestCompleted(questID)
  if not questID then return false end
  if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
    return C_QuestLog.IsQuestFlaggedCompleted(questID) and true or false
  end
  return false
end

local function IsQuestInLog(questID)
  if not questID then return false end
  if C_QuestLog and C_QuestLog.GetLogIndexForQuestID then
    local idx = C_QuestLog.GetLogIndexForQuestID(questID)
    return (type(idx) == "number" and idx > 0) and true or false
  end
  return false
end

local function GetQuestObjectiveProgressText(questID, objectiveIndex)
  if not (C_QuestLog and C_QuestLog.GetQuestObjectives) then return nil end
  if not (questID and IsQuestInLog(questID)) then return nil end

  local idx = tonumber(objectiveIndex) or 1
  local objectives = C_QuestLog.GetQuestObjectives(questID)
  local obj = objectives and objectives[idx]
  local fulfilled = obj and tonumber(obj.numFulfilled)
  local required = obj and tonumber(obj.numRequired)
  if fulfilled and required then
    return string.format("%d / %d", fulfilled, required)
  end
  return nil
end

local function HasProfession(prof)
  if not prof then return false end
  if not (GetProfessions and GetProfessionInfo) then return false end

  local wantID = tonumber(prof)
  local wantName = wantID and nil or tostring(prof):lower()

  local p1, p2, _, _, _ = GetProfessions()
  local function Check(p)
    if not p then return false end
    local name, _, _, _, _, _, skillLineID = GetProfessionInfo(p)
    if wantID then
      return skillLineID == wantID
    end
    return name and tostring(name):lower() == wantName
  end

  return Check(p1) or Check(p2)
end

GetPlayerClass = function()
  if UnitClass then
    local _, class = UnitClass("player")
    return class
  end
  return nil
end

local function GetProfessionIndices()
  if not GetProfessions then return nil end
  local p1, p2, arch, fish, cook = GetProfessions()
  return p1, p2, arch, fish, cook
end

local function IsPrimaryProfessionSlotMissing(slot)
  local p1, p2 = GetProfessionIndices()
  slot = tonumber(slot) or 1
  if slot == 2 then
    return p2 == nil
  end
  return p1 == nil
end

local function IsSecondaryProfessionMissing(which)
  local _, _, _, fish, cook = GetProfessionIndices()
  which = tostring(which or ""):lower()
  if which == "fishing" then
    return fish == nil
  end
  if which == "cooking" then
    return cook == nil
  end
  return false
end

GetPrimaryProfessionNames = function()
  if not (GetProfessions and GetProfessionInfo) then return nil end
  local p1, p2 = GetProfessionIndices()
  local out = {}
  local function Add(p)
    if not p then return end
    local name = GetProfessionInfo(p)
    if name then out[#out + 1] = tostring(name) end
  end
  Add(p1)
  Add(p2)
  return out
end

CanQueryTradeSkillLines = function()
  return C_TradeSkillUI and C_TradeSkillUI.GetAllProfessionTradeSkillLines and true or false
end

local function GetTradeSkillLineNameByID(skillLineID)
  if not (C_TradeSkillUI and skillLineID) then return nil end
  if C_TradeSkillUI.GetTradeSkillLineInfoByID then
    local ok, info = pcall(C_TradeSkillUI.GetTradeSkillLineInfoByID, skillLineID)
    if ok and type(info) == "table" then
      local n = info["name"]
      if n then return tostring(n) end
    end
  end
  if C_TradeSkillUI.GetProfessionInfoBySkillLineID then
    local ok, info = pcall(C_TradeSkillUI.GetProfessionInfoBySkillLineID, skillLineID)
    if ok and type(info) == "table" then
      local pn = info["professionName"]
      if pn then return tostring(pn) end
      local n = info["name"]
      if n then return tostring(n) end
    end
  end
  return nil
end

HasTradeSkillLine = function(nameOrID)
  if not CanQueryTradeSkillLines() then return false end
  local wantID = tonumber(nameOrID)
  local wantName = wantID and nil or tostring(nameOrID or ""):lower()
  if wantName == "" and not wantID then return false end

  local ok, lines = pcall(C_TradeSkillUI.GetAllProfessionTradeSkillLines)
  if not ok or type(lines) ~= "table" then return false end

  for _, id in ipairs(lines) do
    if wantID and tonumber(id) == wantID then
      return true
    end
    if wantName then
      local n = GetTradeSkillLineNameByID(id)
      if n and tostring(n):lower() == wantName then
        return true
      end
    end
  end

  return false
end

local function GetPlayerFaction()
  if UnitFactionGroup then
    local f = UnitFactionGroup("player")
    return f
  end
  return nil
end

local function IsInGroupSafe()
  local IsInGroupFn = _G and rawget(_G, "IsInGroup")
  local IsInRaidFn = _G and rawget(_G, "IsInRaid")
  local inGroup = (IsInGroupFn and IsInGroupFn()) and true or false
  local inRaid = (IsInRaidFn and IsInRaidFn()) and true or false
  return inGroup or inRaid
end

local function GetBestMapIDSafe()
  if C_Map and C_Map.GetBestMapForUnit then
    local ok, id = pcall(C_Map.GetBestMapForUnit, "player")
    if ok then return tonumber(id) end
  end
  return nil
end

local function IsSpellKnownSafe(spellID)
  spellID = tonumber(spellID)
  if not spellID then return false end

  local IsSpellKnownFn = _G and rawget(_G, "IsSpellKnown")
  if IsSpellKnownFn then
    local ok, known = pcall(IsSpellKnownFn, spellID)
    if ok and known ~= nil then
      return known and true or false
    end
  end

  local IsPlayerSpellFn = _G and rawget(_G, "IsPlayerSpell")
  if IsPlayerSpellFn then
    local ok, known = pcall(IsPlayerSpellFn, spellID)
    if ok and known ~= nil then
      return known and true or false
    end
  end

  return false
end

local function IsRestingSafe()
  if IsResting then
    return IsResting() and true or false
  end
  return false
end

local function GetStandingIDByFactionID(factionID)
  factionID = tonumber(factionID)
  if not factionID then return nil end

  if C_Reputation and C_Reputation.GetFactionDataByID then
    local ok, data = pcall(C_Reputation.GetFactionDataByID, factionID)
    if ok and type(data) == "table" then
      local sid = tonumber(rawget(data, "standingID") or rawget(data, "reaction") or data.reaction)
      if sid then return sid end
    end
  end

  local GetFactionInfoByIDFn = _G and rawget(_G, "GetFactionInfoByID")
  if GetFactionInfoByIDFn then
    local name, _, standingID = GetFactionInfoByIDFn(factionID)
    if name ~= nil then
      standingID = tonumber(standingID)
      if standingID then return standingID end
    end
  end

  return nil
end

local function GetMaxPlayerLevelSafe()
  if GetMaxPlayerLevel then
    return tonumber(GetMaxPlayerLevel())
  end
  local v = _G and _G["MAX_PLAYER_LEVEL"]
  if v then return tonumber(v) end
  return nil
end

local function IsAtMaxLevel()
  if not UnitLevel then return false end
  local maxLevel = GetMaxPlayerLevelSafe()
  if not maxLevel then return false end
  return (tonumber(UnitLevel("player")) or 0) >= maxLevel
end

local function ArePrereqsMet(prereq)
  if type(prereq) ~= "table" then return true end
  for _, q in ipairs(prereq) do
    if not IsQuestCompleted(tonumber(q)) then
      return false
    end
  end
  return true
end

local function GetQuestTitle(questID)
  if C_QuestLog and C_QuestLog.GetTitleForQuestID then
    return C_QuestLog.GetTitleForQuestID(questID)
  end
  return nil
end

local function GetItemCountSafe(itemID)
  if C_Item and C_Item.GetItemCount then
    return C_Item.GetItemCount(itemID, false, false, false) or 0
  end
  return 0
end

local function GetItemNameSafe(itemID)
  itemID = tonumber(itemID)
  if not itemID then return nil end

  if C_Item and C_Item.GetItemNameByID then
    local ok, name = pcall(C_Item.GetItemNameByID, itemID)
    if ok and name then return tostring(name) end
  end

  local GetItemInfoFn = _G and rawget(_G, "GetItemInfo")
  if GetItemInfoFn then
    local ok, name = pcall(GetItemInfoFn, itemID)
    if ok and name then return tostring(name) end
  end

  return nil
end

local function HasAuraSpellID(spellID)
  if not spellID then return false end

  if AuraUtil and AuraUtil.FindAuraBySpellId then
    local name = AuraUtil.FindAuraBySpellId(spellID, "player", "HELPFUL")
    if name then return true end
    name = AuraUtil.FindAuraBySpellId(spellID, "player", "HARMFUL")
    return name and true or false
  end

  return false
end

local timewalkingSpellToKeywords = {
  [452307] = { "Classic" },
  [335148] = { "Outland", "Burning Crusade" },
  [335149] = { "Wrath", "Northrend", "Lich King" },
  [335150] = { "Cataclysm", "Cata" },
  [335151] = { "Pandaria", "Mists" },
  [335152] = { "Draenor", "Warlords" },
  [359082] = { "Legion" },
  [1223878] = { "Azeroth", "BFA", "Battle for Azeroth" },
  [1256081] = { "Shadowlands" },
}

local _calendarOpened = false
local _twEventCache = { at = 0, active = {} }

local function EnsureCalendarOpened()
  if _calendarOpened then return end
  if C_Calendar and C_Calendar.OpenCalendar then
    pcall(C_Calendar.OpenCalendar)
    _calendarOpened = true
  end
end

local function GetCurrentCalendarDay()
  if C_DateAndTime and C_DateAndTime.GetCurrentCalendarTime then
    local ok, t = pcall(C_DateAndTime.GetCurrentCalendarTime)
    if ok and type(t) == "table" and tonumber(t.monthDay) then
      return tonumber(t.monthDay)
    end
  end
  if C_Calendar and C_Calendar.GetDate then
    local ok, t = pcall(C_Calendar.GetDate)
    if ok and type(t) == "table" and tonumber(t.monthDay) then
      return tonumber(t.monthDay)
    end
  end
  return nil
end

local function GetCurrentMonthNumDays()
  if C_Calendar and C_Calendar.GetMonthInfo then
    local ok, info = pcall(C_Calendar.GetMonthInfo, 0)
    if ok and type(info) == "table" and tonumber(info.numDays) then
      local n = tonumber(info.numDays)
      if n and n > 0 then return n end
    end
  end
  return 31
end

local function GetCalendarEventText(monthOffset, day, index)
  if not (C_Calendar and C_Calendar.GetDayEvent) then return nil end
  local ok, ev = pcall(C_Calendar.GetDayEvent, monthOffset, day, index)
  if not ok or type(ev) ~= "table" then return nil end
  local title = rawget(ev, "title")
  if title then return tostring(title) end
  return nil
end

local function GetCalendarHolidayText(monthOffset, day, index)
  if not (C_Calendar and C_Calendar.GetHolidayInfo) then return nil end
  local ok, info = pcall(C_Calendar.GetHolidayInfo, monthOffset, day, index)
  if not ok or type(info) ~= "table" then return nil end
  local name = rawget(info, "name")
  local desc = rawget(info, "description")
  local out = ""
  if name then out = out .. tostring(name) end
  if desc then out = out .. "\n" .. tostring(desc) end
  if out == "" then return nil end
  return out
end

local _anyTWCache = { at = 0, active = false }
local function IsAnyTimewalkingEventActive()
  local now = 0
  if GetServerTime then now = tonumber(GetServerTime()) or 0 end
  if _anyTWCache.at and (now - (_anyTWCache.at or 0)) < 60 then
    return _anyTWCache.active and true or false
  end

  EnsureCalendarOpened()
  if not (C_Calendar and C_Calendar.GetNumDayEvents and C_Calendar.GetDayEvent) then
    _anyTWCache.at = now
    _anyTWCache.active = false
    return false
  end

  local today = GetCurrentCalendarDay()
  if not today then
    _anyTWCache.at = now
    _anyTWCache.active = false
    return false
  end

  local numDays = GetCurrentMonthNumDays()
  local startDay = today - 1
  local endDay = today + 7
  if startDay < 1 then startDay = 1 end
  if endDay > numDays then endDay = numDays end

  local found = false
  for day = startDay, endDay do
    local okNum, n = pcall(C_Calendar.GetNumDayEvents, 0, day)
    n = okNum and tonumber(n) or 0
    for i = 1, n do
      local title = GetCalendarEventText(0, day, i) or ""
      local holidayText = GetCalendarHolidayText(0, day, i) or ""
      local hay = (title .. "\n" .. holidayText):lower()
      if hay:find("timewalking", 1, true) or hay:find("turbulent timeways", 1, true) then
        found = true
        break
      end
    end
    if found then break end
  end

  _anyTWCache.at = now
  _anyTWCache.active = found and true or false
  return found and true or false
end

local function IsTimewalkingBonusEventActive(spellID)
  spellID = tonumber(spellID)
  if not spellID then return false end

  local keywords = timewalkingSpellToKeywords[spellID]
  if type(keywords) ~= "table" then
    return false
  end

  local now = 0
  if GetServerTime then now = tonumber(GetServerTime()) or 0 end
  local cacheKey = tostring(spellID)
  if _twEventCache.at and (now - (_twEventCache.at or 0)) < 60 and _twEventCache.active[cacheKey] ~= nil then
    return _twEventCache.active[cacheKey] and true or false
  end

  -- Best case: some clients actually have a buff for the active TW week.
  -- This also helps when holiday/calendar strings are generic.
  if HasAuraSpellID(spellID) then
    _twEventCache.at = now
    _twEventCache.active[cacheKey] = true
    return true
  end

  local found = false

  -- Calendar scan (holiday info can include the expansion even when the visible title is generic).
  EnsureCalendarOpened()
  if C_Calendar and C_Calendar.GetNumDayEvents and C_Calendar.GetDayEvent then
    local today = GetCurrentCalendarDay()
    if today then
      local numDays = GetCurrentMonthNumDays()
      local startDay = today - 1
      local endDay = today + 7
      if startDay < 1 then startDay = 1 end
      if endDay > numDays then endDay = numDays end

      for day = startDay, endDay do
        local okNum, n = pcall(C_Calendar.GetNumDayEvents, 0, day)
        n = okNum and tonumber(n) or 0
        for i = 1, n do
          local title = GetCalendarEventText(0, day, i) or ""
          local holidayText = GetCalendarHolidayText(0, day, i) or ""
          local hay = (title .. "\n" .. holidayText):lower()

          if hay:find("timewalking", 1, true) then
            for _, kw in ipairs(keywords) do
              local k = tostring(kw):lower()
              if k ~= "" and hay:find(k, 1, true) then
                found = true
                break
              end
            end
          end

          if found then break end
        end
        if found then break end
      end
    end
  end

  _twEventCache.at = now
  _twEventCache.active[cacheKey] = found and true or false
  return found and true or false
end

local function GetServerTimeSafe()
  if GetServerTime then
    return tonumber(GetServerTime()) or 0
  end
  return 0
end

local function GetWeeklyResetAt()
  local now = GetServerTimeSafe()
  if C_DateAndTime and C_DateAndTime.GetSecondsUntilWeeklyReset then
    local s = tonumber(C_DateAndTime.GetSecondsUntilWeeklyReset())
    if s and s > 0 then
      return now + s
    end
  end
  return 0
end

local function RememberWeeklyAura(spellID)
  if spellID == nil then return end
  NormalizeSV()
  local resetAt = GetWeeklyResetAt()
  if resetAt and resetAt > 0 then
    fr0z3nUI_QuestTracker_Acc.cache.weeklyAuras[tostring(spellID)] = resetAt
  end
end

local function HasRememberedWeeklyAura(spellID)
  if spellID == nil then return false end
  NormalizeSV()
  local now = GetServerTimeSafe()
  local exp = fr0z3nUI_QuestTracker_Acc.cache.weeklyAuras[tostring(spellID)]
  exp = tonumber(exp) or 0
  if exp > now then
    return true
  end
  if exp ~= 0 then
    fr0z3nUI_QuestTracker_Acc.cache.weeklyAuras[tostring(spellID)] = nil
  end
  return false
end

local function ColorHex(r, g, b)
  r = math.floor((tonumber(r) or 1) * 255 + 0.5)
  g = math.floor((tonumber(g) or 1) * 255 + 0.5)
  b = math.floor((tonumber(b) or 1) * 255 + 0.5)
  if r < 0 then r = 0 elseif r > 255 then r = 255 end
  if g < 0 then g = 0 elseif g > 255 then g = 255 end
  if b < 0 then b = 0 elseif b > 255 then b = 255 end
  return string.format("%02x%02x%02x", r, g, b)
end

local function ColorText(rgb, text)
  if not text then return "" end
  if type(rgb) == "string" then
    return "|cff" .. rgb .. text .. "|r"
  end
  if type(rgb) == "table" then
    local hex = ColorHex(rgb[1] or rgb.r, rgb[2] or rgb.g, rgb[3] or rgb.b)
    return "|cff" .. hex .. text .. "|r"
  end
  return text
end

local function ResolveFontPath(fontNameOrPath)
  if not fontNameOrPath then return nil end
  local s = tostring(fontNameOrPath)
  if s:find("\\") or s:find("/") then
    return s
  end
  local ok, lib = pcall(function()
    return LibStub and LibStub("LibSharedMedia-3.0", true)
  end)
  if ok and lib and lib.Fetch then
    local p = lib:Fetch("font", s, true)
    if p then return p end
  end
  return nil
end

local function ApplyFontStyle(fs, fontDef)
  if not (fs and fs.SetFont) then return end
  if type(fontDef) ~= "table" then return end

  local fontPath = ResolveFontPath(fontDef.name or fontDef.font or fontDef.path)
  local size = tonumber(fontDef.size)
  local flags = fontDef.flags
  if flags ~= nil then flags = tostring(flags) end

  if fontPath or size or flags then
    local currentFont, currentSize, currentFlags = fs:GetFont()
    fs:SetFont(fontPath or currentFont, size or currentSize or 12, flags or currentFlags)
  end

  if fontDef.color then
    local hex = tostring(fontDef.color):gsub("^#", "")
    if hex:len() == 6 then
      local r = tonumber(hex:sub(1, 2), 16) / 255
      local g = tonumber(hex:sub(3, 4), 16) / 255
      local b = tonumber(hex:sub(5, 6), 16) / 255
      if fs.SetTextColor then fs:SetTextColor(r, g, b, 1) end
    end
  end

  if fs.SetShadowColor and fs.SetShadowOffset then
    local shadow = fontDef.shadow
    if type(shadow) == "table" then
      local sh = shadow.color or shadow[3]
      local x = tonumber(shadow.x or shadow[1] or 1) or 1
      local y = tonumber(shadow.y or shadow[2] or -1) or -1
      if sh then
        local hex = tostring(sh):gsub("^#", "")
        if hex:len() == 6 then
          local r = tonumber(hex:sub(1, 2), 16) / 255
          local g = tonumber(hex:sub(3, 4), 16) / 255
          local b = tonumber(hex:sub(5, 6), 16) / 255
          fs:SetShadowColor(r, g, b, 1)
        end
      else
        fs:SetShadowColor(0, 0, 0, 1)
      end
      fs:SetShadowOffset(x, y)
    end
  end
end

local function EvaluateIndicatorCondition(ind)
  if type(ind) ~= "table" then return false end

  if type(ind.questIDs) == "table" then
    for _, q in ipairs(ind.questIDs) do
      if IsQuestCompleted(tonumber(q)) then
        return true
      end
    end
    return false
  end

  if ind.questID then
    return IsQuestCompleted(tonumber(ind.questID))
  end

  if type(ind.itemIDs) == "table" then
    local need = tonumber(ind.count) or tonumber(ind.required) or 1
    for _, itemID in ipairs(ind.itemIDs) do
      if GetItemCountSafe(tonumber(itemID)) >= need then
        return true
      end
    end
    return false
  end

  if ind.itemID then
    local need = tonumber(ind.count) or tonumber(ind.required) or 1
    return GetItemCountSafe(tonumber(ind.itemID)) >= need
  end

  if type(ind.aura) == "table" and ind.aura.spellID then
    return HasAuraSpellID(tonumber(ind.aura.spellID))
  end

  return false
end

local function BuildIndicators(rule)
  if type(rule) ~= "table" or type(rule.indicators) ~= "table" then return nil end

  local out = {}
  for _, ind in ipairs(rule.indicators) do
    if type(ind) == "table" then
      local faction = ind.faction
      if faction ~= nil then
        local pf = GetPlayerFaction()
        if pf and tostring(pf):lower() ~= tostring(faction):lower() then
          -- skip indicator not meant for this faction
        else
          faction = nil
        end
      end

      if faction == nil then
        local done = EvaluateIndicatorCondition(ind)
        local onlyWhenDone = (ind.onlyWhenDone == true) or (tostring(ind.showWhen or ""):lower() == "done")
        if (not onlyWhenDone) or done then
          local color = ind.color
          if type(color) ~= "table" then
            color = done and (ind.colorDone or { 0.1, 1.0, 0.1 }) or (ind.colorTodo or { 0.75, 0.1, 0.1 })
          end

          local overlay
          if type(ind.overlay) == "table" then
            local show = EvaluateIndicatorCondition(ind.overlay)
            if show then
              overlay = {
                text = tostring(ind.overlay.text or ""),
                color = type(ind.overlay.color) == "table" and ind.overlay.color or { 1.0, 1.0, 1.0 },
              }
            end
          end

          out[#out + 1] = {
            shape = tostring(ind.shape or "square"):lower(),
            done = done and true or false,
            color = color,
            overlay = overlay,
          }
        end
      end
    end
  end

  if out[1] == nil then return nil end
  return out
end

local function EnsureIndicatorRow(frame, rowIndex)
  if not frame then return nil end
  frame._indicatorRows = frame._indicatorRows or {}
  local row = frame._indicatorRows[rowIndex]
  if row then return row end

  local c = CreateFrame("Frame", nil, frame)
  c:Hide()
  row = { container = c, icons = {}, labels = {} }
  frame._indicatorRows[rowIndex] = row
  return row
end

local function EnsureIndicatorIcon(row, i)
  if not row or not i then return nil end
  local tex = row.icons[i]
  if not tex then
    tex = row.container:CreateTexture(nil, "OVERLAY")
    row.icons[i] = tex
  end
  local lbl = row.labels[i]
  if not lbl then
    lbl = row.container:CreateFontString(nil, "OVERLAY")
    if lbl.SetJustifyH then lbl:SetJustifyH("CENTER") end
    if lbl.SetJustifyV then lbl:SetJustifyV("MIDDLE") end
    row.labels[i] = lbl
  end
  return tex, lbl
end

local function ApplyOverlayFont(label, baseFS)
  if not (label and baseFS and baseFS.GetFont and label.SetFont) then return end
  local font, size, flags = baseFS:GetFont()
  size = tonumber(size) or 12
  local overlaySize = math.max(10, math.floor(size * 1.0 + 0.5))
  label:SetFont(font, overlaySize, flags)
end

local function GetIndicatorMetrics(baseFS)
  local size = 12
  if baseFS and baseFS.GetFont then
    local _, s = baseFS:GetFont()
    size = tonumber(s) or size
  end

  -- Aim: square roughly matches text height.
  local icon = math.floor(size * 1.0 + 0.5)
  if icon < 10 then icon = 10 end
  if icon > 22 then icon = 22 end

  local gap = 2
  local pad = 4
  return icon, gap, pad
end

local function RenderIndicators(frame, rowIndex, baseFS, indicators)
  local row = EnsureIndicatorRow(frame, rowIndex)
  if not row then return end

  if type(indicators) ~= "table" or indicators[1] == nil or not baseFS then
    row.container:Hide()
    return
  end

  local ICON, GAP, PAD = GetIndicatorMetrics(baseFS)

  local count = #indicators
  local width = PAD + (count * ICON) + ((count - 1) * GAP)

  row.container:ClearAllPoints()
  row.container:SetPoint("TOPLEFT", baseFS, "TOPLEFT", (baseFS:GetStringWidth() or 0) + PAD, 0)
  row.container:SetSize(width, ICON)
  row.container:Show()

  for i = 1, count do
    local spec = indicators[i]
    local tex, lbl = EnsureIndicatorIcon(row, i)
    if tex and lbl then
      tex:ClearAllPoints()
      tex:SetPoint("TOPLEFT", row.container, "TOPLEFT", PAD + (i - 1) * (ICON + GAP), 0)
      tex:SetSize(ICON, ICON)
      if tex.SetColorTexture then
        local c = spec.color or { 1, 0, 0 }
        tex:SetColorTexture(c[1] or 1, c[2] or 0, c[3] or 0, c[4] or 1)
      else
        tex:SetTexture("Interface\\Buttons\\WHITE8X8")
        local c = spec.color or { 1, 0, 0 }
        if tex.SetVertexColor then tex:SetVertexColor(c[1] or 1, c[2] or 0, c[3] or 0, c[4] or 1) end
      end
      tex:Show()

      lbl:ClearAllPoints()
      lbl:SetPoint("CENTER", tex, "CENTER", 0, 0)
      if spec.overlay and spec.overlay.text and spec.overlay.text ~= "" then
        ApplyOverlayFont(lbl, baseFS)
        lbl:SetText(spec.overlay.text)
        if lbl.SetTextColor and type(spec.overlay.color) == "table" then
          lbl:SetTextColor(spec.overlay.color[1] or 1, spec.overlay.color[2] or 1, spec.overlay.color[3] or 1, spec.overlay.color[4] or 1)
        end
        lbl:Show()
      else
        lbl:SetText("")
        lbl:Hide()
      end
    end
  end

  -- hide extras
  for i = count + 1, #row.icons do
    if row.icons[i] then row.icons[i]:Hide() end
    if row.labels[i] then row.labels[i]:Hide() end
  end
end

local function GetIndicatorsWidth(baseFS, indicators)
  if type(indicators) ~= "table" or indicators[1] == nil then return 0 end
  local ICON, GAP, PAD = GetIndicatorMetrics(baseFS)
  local count = #indicators
  return PAD + (count * ICON) + ((count - 1) * GAP)
end

local function BuildRuleStatus(rule)
  local questID = tonumber(rule and rule.questID)

  -- Generic conditional rules (used for profession/flow helpers)
  if type(rule) == "table" and type(rule.showIf) == "table" then
    local s = rule.showIf

    if s.class ~= nil then
      local want = s.class
      local have = GetPlayerClass()
      if type(want) == "table" then
        local ok = false
        for _, c in ipairs(want) do
          if tostring(c):upper() == tostring(have or ""):upper() then
            ok = true
            break
          end
        end
        if not ok then return nil end
      else
        if tostring(want):upper() ~= tostring(have or ""):upper() then
          return nil
        end
      end
    end

    if s.missingPrimarySlot ~= nil then
      if not IsPrimaryProfessionSlotMissing(s.missingPrimarySlot) then
        return nil
      end
    end

    if s.missingSecondary ~= nil then
      if not IsSecondaryProfessionMissing(s.missingSecondary) then
        return nil
      end
    end

    if s.missingTradeSkillLine ~= nil then
      -- If we cannot query trade skill lines, don't show the reminder.
      if not CanQueryTradeSkillLines() then
        return nil
      end
      if HasTradeSkillLine(s.missingTradeSkillLine) then
        return nil
      end
    end
  end

  local hideWhenCompleted
  if type(rule) == "table" and rule.hideWhenCompleted ~= nil then
    hideWhenCompleted = rule.hideWhenCompleted and true or false
  else
    -- default: hide completed quests / completed tasks
    hideWhenCompleted = true
  end

  local completed = false
  if questID and IsQuestCompleted(questID) then
    completed = true
    if hideWhenCompleted then
      return nil
    end
  end

  -- Optional additional completion criteria (for non-quest tasks or stricter completion).
  local complete = (type(rule) == "table" and type(rule.complete) == "table") and rule.complete or nil
  if complete then
    local ok = true
    if complete.questID then
      ok = ok and IsQuestCompleted(tonumber(complete.questID))
    end
    if type(complete.item) == "table" and complete.item.itemID then
      local itemID = tonumber(complete.item.itemID)
      local need = tonumber(complete.item.count) or tonumber(complete.item.required) or 1
      local have = GetItemCountSafe(itemID)
      ok = ok and (have >= need)
    end
    if complete.profession ~= nil then
      ok = ok and HasProfession(complete.profession)
    end
    if type(complete.aura) == "table" and complete.aura.spellID then
      local has = HasAuraSpellID(tonumber(complete.aura.spellID))
      local must = (complete.aura.mustHave ~= false)
      ok = ok and (must and has or (not must and not has))
    end
    if ok then
      completed = true
      if hideWhenCompleted then
        return nil
      end
    end
  end

  local disabled = IsRuleDisabled(rule)
  if disabled and not editMode then
    return nil
  end

  -- Prereqs gate
  if not ArePrereqsMet(rule.prereq) then
    return nil
  end

  -- Hide if any quest is currently in log (useful to avoid duplicate reminder rows)
  if not editMode and type(rule) == "table" and type(rule.hideIfAnyQuestInLog) == "table" then
    for _, q in ipairs(rule.hideIfAnyQuestInLog) do
      local qid = tonumber(q)
      if qid and qid > 0 and IsQuestInLog(qid) then
        return nil
      end
    end
  end

  -- Class gate (optional)
  if type(rule) == "table" and rule.class ~= nil then
    local want = tostring(rule.class):upper()
    if want ~= "" and want ~= "NONE" then
      local have = tostring(GetPlayerClass() or ""):upper()
      if have == "" or have ~= want then
        return nil
      end
    end
  end

  -- Not-in-group gate (optional)
  if type(rule) == "table" and rule.notInGroup == true then
    if IsInGroupSafe() then
      return nil
    end
  end

  -- Location gate (optional; uiMapID)
  if type(rule) == "table" and rule.locationID ~= nil then
    local want = tonumber(tostring(rule.locationID):gsub("[^0-9]", ""))
    if want and want > 0 then
      local have = GetBestMapIDSafe()
      if have and have ~= want then
        return nil
      end
    end
  end

  -- Spell gates (optional)
  if type(rule) == "table" then
    local function CheckList(field, shouldKnow)
      local v = rule[field]
      if v == nil then return true end
      local list = {}
      if type(v) == "table" then
        list = v
      else
        list = { v }
      end
      for _, id in ipairs(list) do
        local known = IsSpellKnownSafe(id)
        if shouldKnow and not known then return false end
        if (not shouldKnow) and known then return false end
      end
      return true
    end

    if not CheckList("spellKnown", true) then return nil end
    if not CheckList("notSpellKnown", false) then return nil end
  end

  -- Rested-area gate (optional)
  if type(rule) == "table" and rule.restedOnly == true then
    if not IsRestingSafe() then
      return nil
    end
  end

  -- Reputation gate (optional)
  if type(rule) == "table" and type(rule.rep) == "table" and rule.rep.factionID then
    local standingID = GetStandingIDByFactionID(rule.rep.factionID)
    if standingID then
      local minStanding = tonumber(rule.rep.minStanding)
      if minStanding and standingID < minStanding then
        return nil
      end
      if rule.rep.hideWhenExalted == true and standingID >= 8 then
        return nil
      end
    end
  end

  -- Faction gate (optional)
  if type(rule) == "table" and rule.faction ~= nil then
    local want = tostring(rule.faction)
    if want == "Alliance" or want == "Horde" then
      local have = GetPlayerFaction()
      if have and tostring(have) ~= want then
        return nil
      end
    end
  end

  -- Level gate (useful for Timewalking "max" vs "leveling" variants)
  if type(rule) == "table" and rule.levelGate ~= nil then
    local g = tostring(rule.levelGate):lower()
    if g == "max" and not IsAtMaxLevel() then
      return nil
    end
    if (g == "level" or g == "leveling") and IsAtMaxLevel() then
      return nil
    end
  end

  -- Only show while quest is active/in log (useful for weekly/time-limited quests)
  if questID and rule.requireInLog == true and not IsQuestInLog(questID) then
    return nil
  end

  -- Aura gate
  if type(rule.aura) == "table" then
    local has = nil
    local rememberedKey = nil

    if rule.aura.eventKind == "timewalking" then
      has = IsAnyTimewalkingEventActive()
      rememberedKey = "event:timewalking"
    elseif rule.aura.spellID then
      local spellID = tonumber(rule.aura.spellID)
      rememberedKey = spellID
      if rule.aura.eventActive == true then
        has = IsTimewalkingBonusEventActive(spellID)
      else
        has = HasAuraSpellID(spellID)
      end
    end

    if has ~= nil then
      if has and rule.aura.rememberWeekly == true and (rule.aura.mustHave ~= false) then
        RememberWeeklyAura(rememberedKey)
      end
      if (not has) and rule.aura.rememberWeekly == true and (rule.aura.mustHave ~= false) then
        has = HasRememberedWeeklyAura(rememberedKey)
      end
      if rule.aura.mustHave and not has then
        return nil
      end
      if (rule.aura.mustHave == false) and has then
        return nil
      end
    end
  end

  -- Item gate/progress
  local extra = nil

  -- Explicit extra override (used for helper tasks)
  if type(rule) == "table" and rule.extra ~= nil then
    extra = tostring(rule.extra)
  end

  if type(rule.item) == "table" and rule.item.itemID then
    local itemID = tonumber(rule.item.itemID)
    local count = GetItemCountSafe(itemID)
    if rule.item.hideWhenAcquired == true and count > 0 then
      return nil
    end
    if rule.item.mustHave and count <= 0 then
      return nil
    end
    if rule.item.required and tonumber(rule.item.required) then
      extra = string.format("%d/%d", count, tonumber(rule.item.required))
    else
      extra = tostring(count)
    end
  end

  -- Quest objective progress (for weekly/delve/timewalking style quests)
  if type(rule.progress) == "table" and rule.progress.objectiveIndex then
    local txt = GetQuestObjectiveProgressText(questID, rule.progress.objectiveIndex)
    if txt then extra = txt end
  end

  if completed then
    if type(rule) == "table" and rule.extraComplete ~= nil then
      extra = tostring(rule.extraComplete)
    elseif type(rule) == "table" and rule.showXWhenComplete == true then
      extra = "X"
    end
  end

  local title
  if rule and rule.label then
    title = rule.label
  elseif questID then
    title = GetQuestTitle(questID) or ("Quest " .. questID)
  elseif type(rule) == "table" and type(rule.item) == "table" and rule.item.itemID then
    title = GetItemNameSafe(rule.item.itemID) or ("Item " .. tostring(rule.item.itemID))
  else
    title = "Task"
  end

  if completed and type(rule) == "table" and rule.labelComplete then
    title = tostring(rule.labelComplete)
  end

  local indicators = BuildIndicators(rule)

  if disabled then
    title = ColorText({ 0.6, 0.6, 0.6 }, "[OFF] " .. title)
  end

  if (not disabled) and type(rule) == "table" and rule.color ~= nil then
    title = ColorText(rule.color, title)
  end

  return {
    questID = questID,
    title = title,
    extra = extra,
    completed = completed,
    indicators = indicators,
    rule = rule,
    disabled = disabled,
  }
end

-- UI
local framesByID = {}
local RefreshAll
local CreateAllFrames
local DestroyFrameByID

local function GetFramePosStore()
  NormalizeSV()
  fr0z3nUI_QuestTracker_Char.settings.framePos = fr0z3nUI_QuestTracker_Char.settings.framePos or {}
  return fr0z3nUI_QuestTracker_Char.settings.framePos
end

local function SaveFramePosition(f)
  if not (f and f._id and f.GetPoint) then return end
  local point, _, relPoint, x, y = f:GetPoint(1)
  if not point then return end
  local store = GetFramePosStore()
  store[tostring(f._id)] = {
    point = tostring(point),
    relPoint = tostring(relPoint or point),
    x = tonumber(x) or 0,
    y = tonumber(y) or 0,
  }
end

local function ApplySavedFramePosition(f, def)
  if not (f and f._id and f.SetPoint and f.ClearAllPoints) then return false end
  local store = GetFramePosStore()
  local pos = store[tostring(f._id)]
  if type(pos) ~= "table" then return false end

  local point = pos.point or (def and def.point)
  local relPoint = pos.relPoint or (def and def.relPoint) or point
  if not point then return false end

  f:ClearAllPoints()
  f:SetPoint(point, UIParent, relPoint, tonumber(pos.x) or 0, tonumber(pos.y) or 0)
  return true
end

local function ApplyFAOBackdrop(f, bgAlpha)
  f:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    tile = true,
    tileSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  f:SetBackdropColor(0, 0, 0, tonumber(bgAlpha) or 0.7)
end

local function CreateContainerFrame(def)
  local parent = UIParent
  if type(def) == "table" and def.parentFrame then
    local p = _G and _G[tostring(def.parentFrame)]
    if p then parent = p end
  end

  local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  f:SetClampedToScreen(true)
  f:SetFrameStrata("MEDIUM")
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", function(self)
    if self.StopMovingOrSizing then self:StopMovingOrSizing() end
    SaveFramePosition(self)
  end)
  local bgAlpha = (type(def) == "table") and def.bgAlpha or nil
  ApplyFAOBackdrop(f, bgAlpha)

  f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f.title:SetPoint("TOPLEFT", 8, -6)
  f.title:SetJustifyH("LEFT")
  f.title:SetText("|cff00ccff[FQT]|r")

  return f
end

local function CreateBarFrame(def)
  local f = CreateContainerFrame(def)
  f._id = def and def.id or nil
  f:SetSize(def.width or 300, def.height or 20)
  f:SetPoint(def.point or "TOP", UIParent, def.relPoint or def.point or "TOP", def.x or 0, def.y or 0)
  ApplySavedFramePosition(f, def)

  f._itemFont = "GameFontHighlightSmall"
  f.items = {}

  f.prefix = f:CreateFontString(nil, "OVERLAY", f._itemFont)
  f.prefix:SetJustifyH("LEFT")
  f.prefix:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -2)
  f.prefix:SetText("|cff00ccff[FQT]|r")

  return f
end

local function CreateListFrame(def)
  local f = CreateContainerFrame(def)
  f._id = def and def.id or nil
  f:SetSize(def.width or 300, (def.rowHeight or 16) * ((def.maxItems or 20) + 2))
  f:SetPoint(def.point or "TOPRIGHT", UIParent, def.relPoint or def.point or "TOPRIGHT", def.x or -10, def.y or -120)
  ApplySavedFramePosition(f, def)

  f._itemFont = "GameFontHighlight"
  f.items = {}
  f.buttons = {}
  return f
end

local function EnsureFontString(parent, idx, fontDef)
  if parent.items[idx] then return parent.items[idx] end
  local fs = parent:CreateFontString(nil, "OVERLAY", parent._itemFont or "GameFontHighlight")
  fs:SetJustifyH("LEFT")
  ApplyFontStyle(fs, fontDef)
  parent.items[idx] = fs
  return fs
end

local function EnsureRowButton(frame, idx)
  if frame.buttons and frame.buttons[idx] then return frame.buttons[idx] end
  frame.buttons = frame.buttons or {}
  local b = CreateFrame("Button", nil, frame)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b:SetScript("OnClick", function(self, button)
    if not editMode then return end
    local e = self._entry
    if not (e and e.rule) then return end
    if button == "RightButton" then
      local r = e.rule
      local key = RuleKey(r) or "(no key)"
      Print(string.format("Rule: %s  questID=%s", key, tostring(r.questID)))
      return
    end
    ToggleRuleDisabled(e.rule)
    RefreshAll()
  end)
  frame.buttons[idx] = b
  return b
end

local function RenderBar(frameDef, frame, entries)
  local maxItems = tonumber(frameDef.maxItems) or 6
  local pad = 8
  local y = -2

  if frame.title then frame.title:Hide() end

  local function DetermineGrow()
    local g = GetUISetting("barGrow", nil)
    if g == nil then g = (frameDef and frameDef.grow) end
    g = tostring(g or "auto"):lower()
    if g ~= "auto" and g ~= "left" and g ~= "right" and g ~= "center" then
      g = "auto"
    end
    if g ~= "auto" then return g end

    local point = nil
    if frame and frame.GetPoint then
      point = select(1, frame:GetPoint(1))
    end
    point = tostring(point or (frameDef and frameDef.point) or ""):upper()
    if point:find("RIGHT", 1, true) then return "left" end
    if point:find("LEFT", 1, true) then return "right" end
    return "center"
  end

  local grow = DetermineGrow()

  if frame.prefix then
    frame.prefix:Show()
    ApplyFontStyle(frame.prefix, frameDef and frameDef.font)
    frame.prefix:SetText("|cff00ccff[FQT]|r")
  end

  -- Pre-fill texts so GetStringWidth() is accurate.
  local tempTextByIndex = {}
  local tempIndicatorsByIndex = {}
  local tempIndicatorsWByIndex = {}
  for i = 1, maxItems do
    local e = entries[i]
    if e then
      local text = e.title
      if e.extra then text = text .. "  " .. e.extra .. " " end
      tempTextByIndex[i] = " " .. text .. " "
      tempIndicatorsByIndex[i] = e.indicators
      tempIndicatorsWByIndex[i] = 0
    end
  end

  -- Compute total width if centered.
  local spacingPrefix = 12
  local spacingItem = 16
  local total = 0
  local prefixW = (frame.prefix and frame.prefix:GetStringWidth()) or 0
  if prefixW > 0 then
    total = total + prefixW
  end
  for i = 1, maxItems do
    local txt = tempTextByIndex[i]
    if txt then
      local fs = EnsureFontString(frame, i, frameDef and frameDef.font)
      ApplyFontStyle(fs, frameDef and frameDef.font)
      fs:SetText(txt)
      fs:Show()
      local indW = GetIndicatorsWidth(fs, tempIndicatorsByIndex[i])
      tempIndicatorsWByIndex[i] = indW
      total = total + (fs:GetStringWidth() or 0) + indW
    end
  end

  -- Add spacing between visible segments.
  local visibleCount = 0
  if prefixW > 0 then visibleCount = visibleCount + 1 end
  for i = 1, maxItems do
    if tempTextByIndex[i] then visibleCount = visibleCount + 1 end
  end
  if visibleCount > 1 then
    -- prefix->first uses spacingPrefix, others use spacingItem
    if prefixW > 0 then
      total = total + spacingPrefix
      if visibleCount > 2 then
        total = total + (visibleCount - 2) * spacingItem
      end
    else
      total = total + (visibleCount - 1) * spacingItem
    end
  end

  local frameW = (frame and frame.GetWidth and frame:GetWidth()) or 0
  local start = pad
  if grow == "center" and frameW and frameW > 0 then
    start = math.max(pad, (frameW - total) / 2)
  end

  local cursor = start
  local cursorR = start

  if grow == "left" then
    cursorR = pad
    if frame.prefix and prefixW > 0 then
      frame.prefix:ClearAllPoints()
      frame.prefix:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -cursorR, y)
      cursorR = cursorR + prefixW + spacingPrefix
    end

    for i = 1, maxItems do
      local txt = tempTextByIndex[i]
      local fs = EnsureFontString(frame, i, frameDef and frameDef.font)
      fs:ClearAllPoints()
      if fs.SetWordWrap then fs:SetWordWrap(false) end
      ApplyFontStyle(fs, frameDef and frameDef.font)
      if txt then
        fs:SetText(txt)
        fs:Show()
        fs:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -cursorR, y)
        local indW = tempIndicatorsWByIndex[i] or 0
        RenderIndicators(frame, i, fs, tempIndicatorsByIndex[i])
        cursorR = cursorR + (fs:GetStringWidth() or 0) + indW + spacingItem
      else
        fs:SetText("")
        fs:Hide()
        RenderIndicators(frame, i, fs, nil)
      end
    end
    return
  end

  -- grow == "right" or "center": left-to-right placement
  if frame.prefix and prefixW > 0 then
    frame.prefix:ClearAllPoints()
    frame.prefix:SetPoint("TOPLEFT", frame, "TOPLEFT", cursor, y)
    cursor = cursor + prefixW + spacingPrefix
  end

  for i = 1, maxItems do
    local e = entries[i]
    local fs = EnsureFontString(frame, i, frameDef and frameDef.font)
    fs:ClearAllPoints()
    fs:SetPoint("TOPLEFT", frame, "TOPLEFT", cursor, y)
    if fs.SetWordWrap then fs:SetWordWrap(false) end

    ApplyFontStyle(fs, frameDef and frameDef.font)

    local txt = tempTextByIndex[i]
    if txt then
      fs:SetText(txt)
      fs:Show()
      local indW = tempIndicatorsWByIndex[i] or 0
      RenderIndicators(frame, i, fs, tempIndicatorsByIndex[i])
      cursor = cursor + (fs:GetStringWidth() or 0) + indW + spacingItem
    else
      fs:SetText("")
      fs:Hide()
      RenderIndicators(frame, i, fs, nil)
    end
  end

  if frameDef and frameDef.autoSize then
    frame:SetHeight(tonumber(frameDef.height) or 20)
  end
end

-- Simple config GUI
local optionsFrame
local function RefreshRulesList() end
local function RefreshFramesList() end
local function RefreshActiveTab() end

local function ResetFramePositionsToDefaults()
  local store = GetFramePosStore()
  if wipe then
    wipe(store)
  else
    for k in pairs(store) do store[k] = nil end
  end

  for _, def in ipairs(GetEffectiveFrames()) do
    local id = tostring(def.id or "")
    local f = framesByID[id]
    if f and f.ClearAllPoints and f.SetPoint then
      f:ClearAllPoints()
      f:SetPoint(def.point or "TOP", UIParent, def.relPoint or def.point or "TOP", def.x or 0, def.y or 0)
    end
  end
end

local function EnsureOptionsFrame()
  if optionsFrame then return optionsFrame end

  local f = CreateFrame("Frame", "FR0Z3NUIFQTOptions", UIParent, "BackdropTemplate")
  f:SetSize(560, 420)
  f:SetPoint("CENTER")
  f:SetFrameStrata("DIALOG")
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", function(self)
    if self.StopMovingOrSizing then self:StopMovingOrSizing() end
  end)
  ApplyFAOBackdrop(f, 0.85)

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", 12, -10)
  title:SetText("|cff00ccff[FQT]|r QuestTracker")

  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", f, "TOPRIGHT", 2, 2)

  -- Tabs
  local function MakePanel()
    local p = CreateFrame("Frame", nil, f)
    p:SetAllPoints(f)
    return p
  end

  local panels = {
    general = MakePanel(),
    quest = MakePanel(),
    items = MakePanel(),
    text = MakePanel(),
    spells = MakePanel(),
    rules = MakePanel(),
    frames = MakePanel(),
  }

  local function SetPanelShown(name)
    for k, p in pairs(panels) do
      p:SetShown(k == name)
    end
    if optionsFrame then
      optionsFrame._activeTab = name
      SetUISetting("optionsTab", name)
    end
    if name == "rules" then
      RefreshRulesList()
    elseif name == "frames" then
      RefreshFramesList()
    end
  end

  local tabOrder = { "general", "quest", "items", "text", "spells", "rules", "frames" }
  local tabText = {
    general = "General",
    quest = "Quest",
    items = "Items",
    text = "Text",
    spells = "Spells",
    rules = "Rules",
    frames = "Frames",
  }
  local tabs = {}

  local function SelectTab(name)
    SetPanelShown(name)
    for _, btn in ipairs(tabs) do
      btn:SetEnabled(btn._tabName ~= name)
    end
  end

  for i, name in ipairs(tabOrder) do
    local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btn:SetSize(70, 18)
    btn:SetText(tabText[name] or name)
    btn._tabName = name
    if i == 1 then
      btn:SetPoint("TOPLEFT", title, "TOPRIGHT", 10, 2)
    else
      btn:SetPoint("LEFT", tabs[i - 1], "RIGHT", 4, 0)
    end
    btn:SetScript("OnClick", function() SelectTab(name) end)
    tabs[i] = btn
  end

  f._tabs = tabs
  f._panels = panels

  local function MakeCheck(parent, label, x, y, get, set)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    cb.text:SetText(label)
    cb:SetScript("OnShow", function(self) self:SetChecked(get() and true or false) end)
    cb:SetScript("OnClick", function(self)
      set(self:GetChecked() and true or false)
      RefreshAll()
    end)
    return cb
  end

  -- GENERAL tab
  MakeCheck(panels.general, "Enabled", 12, -40, function() return framesEnabled end, function(v) framesEnabled = v end)
  MakeCheck(panels.general, "Edit mode", 12, -70, function() return editMode end, function(v) editMode = v end)

  MakeCheck(panels.general, "Auto profession reminders", 12, -100,
    function() return GetUISetting("autoProfessionTasks", true) end,
    function(v) SetUISetting("autoProfessionTasks", v) end
  )

  MakeCheck(panels.general, "Auto Shadowlands profession reminders", 220, -100,
    function() return GetUISetting("autoExpansionProfessionTasks", false) end,
    function(v) SetUISetting("autoExpansionProfessionTasks", v) end
  )

  local autoHint = panels.general:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  autoHint:SetPoint("TOPLEFT", 12, -122)
  autoHint:SetText("Shows auto reminders when professions are missing (primary/cooking/fishing).")

  local autoFrameLabel = panels.general:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  autoFrameLabel:SetPoint("TOPLEFT", 12, -146)
  autoFrameLabel:SetText("Auto reminders frameID:")

  local autoFrameBox = CreateFrame("EditBox", nil, panels.general, "InputBoxTemplate")
  autoFrameBox:SetSize(70, 20)
  autoFrameBox:SetPoint("TOPLEFT", 140, -150)
  autoFrameBox:SetAutoFocus(false)
  autoFrameBox:SetText(tostring(GetUISetting("autoProfessionFrame", "list1")))
  autoFrameBox:SetScript("OnEnterPressed", function(self)
    local v = tostring(self:GetText() or ""):gsub("%s+", "")
    if v == "" then v = "list1" end
    SetUISetting("autoProfessionFrame", v)
    self:SetText(v)
    self:ClearFocus()
    CreateAllFrames()
    RefreshAll()
  end)

  -- QUEST tab
  local questTitle = panels.quest:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  questTitle:SetPoint("TOPLEFT", 12, -40)
  questTitle:SetText("Quest")

  local function AddPlaceholder(editBox, text)
    if not (editBox and editBox.CreateFontString) then return end
    local ph = editBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ph:SetPoint("TOPLEFT", 6, -6)
    ph:SetJustifyH("LEFT")
    ph:SetText(text)
    local function Update()
      local hasText = tostring(editBox:GetText() or "") ~= ""
      local focused = editBox.HasFocus and editBox:HasFocus() and true or false
      ph:SetShown((not hasText) and (not focused))
    end
    editBox:HookScript("OnEditFocusGained", Update)
    editBox:HookScript("OnEditFocusLost", Update)
    editBox:HookScript("OnTextChanged", Update)
    editBox:HookScript("OnShow", Update)
    Update()
    editBox._placeholder = ph
  end

  local qiLabel = panels.quest:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  qiLabel:SetPoint("TOPLEFT", 12, -70)
  qiLabel:SetText("Quest Info")

  local qiScroll = CreateFrame("ScrollFrame", nil, panels.quest, "UIPanelScrollFrameTemplate")
  qiScroll:SetPoint("TOPLEFT", 12, -90)
  qiScroll:SetSize(530, 90)

  local qiBox = CreateFrame("EditBox", nil, qiScroll)
  qiBox:SetMultiLine(true)
  qiBox:SetAutoFocus(false)
  qiBox:SetFontObject("ChatFontNormal")
  qiBox:SetWidth(500)
  qiBox:SetTextInsets(6, 6, 6, 6)
  qiBox:SetText("")
  qiBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  qiBox:SetScript("OnCursorChanged", function(self, x, y, w, h)
    if not qiScroll then return end
    qiScroll:UpdateScrollChildRect()
    local offset = qiScroll:GetVerticalScroll() or 0
    local height = qiScroll:GetHeight() or 0
    local top = -y
    if top < offset then
      qiScroll:SetVerticalScroll(top)
    elseif top > offset + height - 20 then
      qiScroll:SetVerticalScroll(top - height + 20)
    end
  end)

  qiScroll:SetScrollChild(qiBox)
  AddPlaceholder(qiBox, "Quest Info (what to display)")

  local qidLabel = panels.quest:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  qidLabel:SetPoint("TOPLEFT", 12, -190)
  qidLabel:SetText("QuestID")

  local questIDBox = CreateFrame("EditBox", nil, panels.quest, "InputBoxTemplate")
  questIDBox:SetSize(90, 20)
  questIDBox:SetPoint("TOPLEFT", 12, -206)
  questIDBox:SetAutoFocus(false)
  questIDBox:SetNumeric(true)
  questIDBox:SetText("0")

  local afterLabel = panels.quest:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  afterLabel:SetPoint("TOPLEFT", 110, -190)
  afterLabel:SetText("After Quest (optional)")

  local afterBox = CreateFrame("EditBox", nil, panels.quest, "InputBoxTemplate")
  afterBox:SetSize(120, 20)
  afterBox:SetPoint("TOPLEFT", 110, -206)
  afterBox:SetAutoFocus(false)
  afterBox:SetNumeric(true)
  afterBox:SetText("0")

  local barLabel = panels.quest:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  barLabel:SetPoint("TOPLEFT", 245, -190)
  barLabel:SetText("Bar / List")

  local factionLabel = panels.quest:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  factionLabel:SetPoint("TOPLEFT", 410, -190)
  factionLabel:SetText("Faction")

  local colorLabel = panels.quest:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  colorLabel:SetPoint("TOPLEFT", 12, -230)
  colorLabel:SetText("Color")

  local questFrameDrop = CreateFrame("Frame", nil, panels.quest, "UIDropDownMenuTemplate")
  questFrameDrop:SetPoint("TOPLEFT", 230, -218)
  local UDDM_SetWidth = _G and rawget(_G, "UIDropDownMenu_SetWidth")
  local UDDM_SetText = _G and rawget(_G, "UIDropDownMenu_SetText")
  local UDDM_Initialize = _G and rawget(_G, "UIDropDownMenu_Initialize")
  local UDDM_CreateInfo = _G and rawget(_G, "UIDropDownMenu_CreateInfo")
  local UDDM_AddButton = _G and rawget(_G, "UIDropDownMenu_AddButton")

  if UDDM_SetWidth then UDDM_SetWidth(questFrameDrop, 160) end
  if UDDM_SetText then UDDM_SetText(questFrameDrop, "list1") end
  panels.quest._questTargetFrameID = "list1"

  local questFactionDrop = CreateFrame("Frame", nil, panels.quest, "UIDropDownMenuTemplate")
  questFactionDrop:SetPoint("TOPLEFT", 395, -218)
  if UDDM_SetWidth then UDDM_SetWidth(questFactionDrop, 140) end
  if UDDM_SetText then UDDM_SetText(questFactionDrop, "Both (Off)") end
  panels.quest._questFaction = nil

  local questColorDrop = CreateFrame("Frame", nil, panels.quest, "UIDropDownMenuTemplate")
  questColorDrop:SetPoint("TOPLEFT", -8, -258)
  if UDDM_SetWidth then UDDM_SetWidth(questColorDrop, 160) end
  if UDDM_SetText then UDDM_SetText(questColorDrop, "None") end
  panels.quest._questColor = nil
  panels.quest._questColorName = "None"

  local function ColorLabel(v)
    if v == nil then return "None" end
    if type(v) == "string" then return v end
    return "Custom"
  end

  local function SetQuestColor(name)
    if name == "None" then
      panels.quest._questColor = nil
    elseif name == "Green" then
      panels.quest._questColor = { 0.1, 1.0, 0.1 }
    elseif name == "Blue" then
      panels.quest._questColor = { 0.2, 0.6, 1.0 }
    elseif name == "Yellow" then
      panels.quest._questColor = { 1.0, 0.9, 0.2 }
    elseif name == "Red" then
      panels.quest._questColor = { 1.0, 0.2, 0.2 }
    elseif name == "Cyan" then
      panels.quest._questColor = { 0.2, 1.0, 1.0 }
    else
      panels.quest._questColor = nil
      name = "None"
    end
    panels.quest._questColorName = name
    if UDDM_SetText then UDDM_SetText(questColorDrop, ColorLabel(name)) end
  end

  local function FactionLabel(v)
    v = tostring(v or "")
    if v == "Alliance" then return "Alliance" end
    if v == "Horde" then return "Horde" end
    return "Both (Off)"
  end

  if UDDM_Initialize and UDDM_CreateInfo and UDDM_AddButton then
    UDDM_Initialize(questFrameDrop, function(self, level)
      local info = UDDM_CreateInfo()
      for _, def in ipairs(GetEffectiveFrames()) do
        if type(def) == "table" and def.id then
          local id = tostring(def.id)
          info.text = id .. " (" .. tostring(def.type or "list") .. ")"
          info.checked = (panels.quest._questTargetFrameID == id) and true or false
          info.func = function()
            panels.quest._questTargetFrameID = id
            if UDDM_SetText then UDDM_SetText(questFrameDrop, id) end
          end
          UDDM_AddButton(info)
        end
      end
    end)

    UDDM_Initialize(questFactionDrop, function(self, level)
      do
        local info = UDDM_CreateInfo()
        info.text = "Both (Off)"
        info.checked = (panels.quest._questFaction == nil) and true or false
        info.func = function()
          panels.quest._questFaction = nil
          if UDDM_SetText then UDDM_SetText(questFactionDrop, FactionLabel(nil)) end
        end
        UDDM_AddButton(info)
      end

      do
        local info = UDDM_CreateInfo()
        info.text = "Alliance"
        info.checked = (panels.quest._questFaction == "Alliance") and true or false
        info.func = function()
          panels.quest._questFaction = "Alliance"
          if UDDM_SetText then UDDM_SetText(questFactionDrop, FactionLabel("Alliance")) end
        end
        UDDM_AddButton(info)
      end

      do
        local info = UDDM_CreateInfo()
        info.text = "Horde"
        info.checked = (panels.quest._questFaction == "Horde") and true or false
        info.func = function()
          panels.quest._questFaction = "Horde"
          if UDDM_SetText then UDDM_SetText(questFactionDrop, FactionLabel("Horde")) end
        end
        UDDM_AddButton(info)
      end
    end)

    UDDM_Initialize(questColorDrop, function(self, level)
      for _, name in ipairs({ "None", "Green", "Blue", "Yellow", "Red", "Cyan" }) do
        local info = UDDM_CreateInfo()
        info.text = name
        info.checked = (panels.quest._questColorName == name) and true or false
        info.func = function() SetQuestColor(name) end
        UDDM_AddButton(info)
      end
    end)
  else
    -- fallback: simple editbox if dropdown template is unavailable
    local fb = CreateFrame("EditBox", nil, panels.quest, "InputBoxTemplate")
    fb:SetSize(80, 20)
    fb:SetPoint("TOPLEFT", 245, -206)
    fb:SetAutoFocus(false)
    fb:SetText("list1")
    fb:SetScript("OnEnterPressed", function(self)
      local v = tostring(self:GetText() or ""):gsub("%s+", "")
      if v == "" then v = "list1" end
      panels.quest._questTargetFrameID = v
      self:SetText(v)
      self:ClearFocus()
    end)
    questFrameDrop:Hide()

    local fbf = CreateFrame("EditBox", nil, panels.quest, "InputBoxTemplate")
    fbf:SetSize(80, 20)
    fbf:SetPoint("TOPLEFT", 410, -206)
    fbf:SetAutoFocus(false)
    fbf:SetText("both")
    fbf:SetScript("OnEnterPressed", function(self)
      local v = tostring(self:GetText() or ""):lower():gsub("%s+", "")
      if v == "a" or v == "alliance" then
        panels.quest._questFaction = "Alliance"
        self:SetText("Alliance")
      elseif v == "h" or v == "horde" then
        panels.quest._questFaction = "Horde"
        self:SetText("Horde")
      else
        panels.quest._questFaction = nil
        self:SetText("both")
      end
      self:ClearFocus()
    end)
    questFactionDrop:Hide()

    local cfb = CreateFrame("EditBox", nil, panels.quest, "InputBoxTemplate")
    cfb:SetSize(80, 20)
    cfb:SetPoint("TOPLEFT", 12, -252)
    cfb:SetAutoFocus(false)
    cfb:SetText("none")
    cfb:SetScript("OnEnterPressed", function(self)
      local v = tostring(self:GetText() or ""):lower():gsub("%s+", "")
      if v == "green" then
        panels.quest._questColor = { 0.1, 1.0, 0.1 }
      elseif v == "blue" then
        panels.quest._questColor = { 0.2, 0.6, 1.0 }
      elseif v == "yellow" then
        panels.quest._questColor = { 1.0, 0.9, 0.2 }
      elseif v == "red" then
        panels.quest._questColor = { 1.0, 0.2, 0.2 }
      elseif v == "cyan" then
        panels.quest._questColor = { 0.2, 1.0, 1.0 }
      else
        panels.quest._questColor = nil
        v = "none"
      end
      self:SetText(v)
      self:ClearFocus()
    end)
    questColorDrop:Hide()
  end

  local addQuestBtn = CreateFrame("Button", nil, panels.quest, "UIPanelButtonTemplate")
  addQuestBtn:SetSize(140, 22)
  addQuestBtn:SetPoint("TOPLEFT", 12, -242)
  addQuestBtn:SetText("Add Quest Rule")
  addQuestBtn:SetScript("OnClick", function()
    local questID = tonumber(questIDBox:GetText() or "")
    if not questID or questID <= 0 then
      Print("Enter a questID > 0.")
      return
    end

    local targetFrame = tostring(panels.quest._questTargetFrameID or ""):gsub("%s+", "")
    if targetFrame == "" then targetFrame = "list1" end

    local infoText = tostring(qiBox:GetText() or "")
    infoText = infoText:gsub("^%s+", ""):gsub("%s+$", "")
    local label = (infoText ~= "") and infoText or nil

    local afterID = tonumber(afterBox:GetText() or "")
    local prereq = nil
    if afterID and afterID > 0 then
      prereq = { afterID }
    end

    local rules = GetCustomRules()
    local key = string.format("custom:q:%d:%s:%d", tostring(questID), tostring(targetFrame), (#rules + 1))

    rules[#rules + 1] = {
      key = key,
      questID = questID,
      frameID = targetFrame,
      label = label,
      prereq = prereq,
      faction = panels.quest._questFaction,
      color = panels.quest._questColor,
      hideWhenCompleted = true,
    }

    CreateAllFrames()
    RefreshAll()
    RefreshRulesList()
    Print("Added quest rule for quest " .. questID .. " -> " .. targetFrame)
  end)

  -- ITEMS tab
  local itemsTitle = panels.items:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  itemsTitle:SetPoint("TOPLEFT", 12, -40)
  itemsTitle:SetText("Items")

  local itemIDLabel = panels.items:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  itemIDLabel:SetPoint("TOPLEFT", 12, -70)
  itemIDLabel:SetText("ItemID")

  local itemIDBox = CreateFrame("EditBox", nil, panels.items, "InputBoxTemplate")
  itemIDBox:SetSize(90, 20)
  itemIDBox:SetPoint("TOPLEFT", 12, -86)
  itemIDBox:SetAutoFocus(false)
  itemIDBox:SetNumeric(true)
  itemIDBox:SetText("0")

  local itemNameLabel = panels.items:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  itemNameLabel:SetPoint("TOPLEFT", 110, -70)
  itemNameLabel:SetText("Label (optional)")

  local itemLabelBox = CreateFrame("EditBox", nil, panels.items, "InputBoxTemplate")
  itemLabelBox:SetSize(220, 20)
  itemLabelBox:SetPoint("TOPLEFT", 110, -86)
  itemLabelBox:SetAutoFocus(false)
  itemLabelBox:SetText("")

  local useNameCheck = CreateFrame("CheckButton", nil, panels.items, "UICheckButtonTemplate")
  useNameCheck:SetPoint("TOPLEFT", 340, -88)
  useNameCheck.text:SetText("Use name from ID")
  useNameCheck:SetChecked(true)

  local itemsFrameLabel = panels.items:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  itemsFrameLabel:SetPoint("TOPLEFT", 12, -116)
  itemsFrameLabel:SetText("Bar / List")

  local itemsFrameDrop = CreateFrame("Frame", nil, panels.items, "UIDropDownMenuTemplate")
  itemsFrameDrop:SetPoint("TOPLEFT", -8, -144)
  if UDDM_SetWidth then UDDM_SetWidth(itemsFrameDrop, 160) end
  if UDDM_SetText then UDDM_SetText(itemsFrameDrop, "list1") end
  panels.items._targetFrameID = "list1"

  local itemsFactionLabel = panels.items:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  itemsFactionLabel:SetPoint("TOPLEFT", 180, -116)
  itemsFactionLabel:SetText("Faction")

  local itemsFactionDrop = CreateFrame("Frame", nil, panels.items, "UIDropDownMenuTemplate")
  itemsFactionDrop:SetPoint("TOPLEFT", 165, -144)
  if UDDM_SetWidth then UDDM_SetWidth(itemsFactionDrop, 140) end
  if UDDM_SetText then UDDM_SetText(itemsFactionDrop, "Both (Off)") end
  panels.items._faction = nil

  local itemsColorLabel = panels.items:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  itemsColorLabel:SetPoint("TOPLEFT", 340, -116)
  itemsColorLabel:SetText("Color")

  local itemsColorDrop = CreateFrame("Frame", nil, panels.items, "UIDropDownMenuTemplate")
  itemsColorDrop:SetPoint("TOPLEFT", 325, -144)
  if UDDM_SetWidth then UDDM_SetWidth(itemsColorDrop, 140) end
  if UDDM_SetText then UDDM_SetText(itemsColorDrop, "None") end
  panels.items._color = nil

  local repFactionLabel = panels.items:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  repFactionLabel:SetPoint("TOPLEFT", 12, -180)
  repFactionLabel:SetText("Rep FactionID")

  local repFactionBox = CreateFrame("EditBox", nil, panels.items, "InputBoxTemplate")
  repFactionBox:SetSize(90, 20)
  repFactionBox:SetPoint("TOPLEFT", 12, -196)
  repFactionBox:SetAutoFocus(false)
  repFactionBox:SetNumeric(true)
  repFactionBox:SetText("0")

  local repMinLabel = panels.items:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  repMinLabel:SetPoint("TOPLEFT", 110, -180)
  repMinLabel:SetText("Min Rep")

  local repMinDrop = CreateFrame("Frame", nil, panels.items, "UIDropDownMenuTemplate")
  repMinDrop:SetPoint("TOPLEFT", 95, -208)
  if UDDM_SetWidth then UDDM_SetWidth(repMinDrop, 140) end
  if UDDM_SetText then UDDM_SetText(repMinDrop, "Off") end
  panels.items._repMinStanding = nil

  local hideAcquired = CreateFrame("CheckButton", nil, panels.items, "UICheckButtonTemplate")
  hideAcquired:SetPoint("TOPLEFT", 250, -198)
  hideAcquired.text:SetText("Hide when acquired")
  hideAcquired:SetChecked(false)

  local hideExalted = CreateFrame("CheckButton", nil, panels.items, "UICheckButtonTemplate")
  hideExalted:SetPoint("TOPLEFT", 400, -198)
  hideExalted.text:SetText("Hide when exalted")
  hideExalted:SetChecked(false)

  local restedOnly = CreateFrame("CheckButton", nil, panels.items, "UICheckButtonTemplate")
  restedOnly:SetPoint("TOPLEFT", 12, -222)
  restedOnly.text:SetText("Rested areas only")
  restedOnly:SetChecked(false)

  if UDDM_Initialize and UDDM_CreateInfo and UDDM_AddButton then
    UDDM_Initialize(itemsFrameDrop, function(self, level)
      for _, def in ipairs(GetEffectiveFrames()) do
        if type(def) == "table" and def.id then
          local id = tostring(def.id)
          local info = UDDM_CreateInfo()
          info.text = id .. " (" .. tostring(def.type or "list") .. ")"
          info.checked = (panels.items._targetFrameID == id) and true or false
          info.func = function()
            panels.items._targetFrameID = id
            if UDDM_SetText then UDDM_SetText(itemsFrameDrop, id) end
          end
          UDDM_AddButton(info)
        end
      end
    end)

    UDDM_Initialize(itemsFactionDrop, function(self, level)
      do
        local info = UDDM_CreateInfo()
        info.text = "Both (Off)"
        info.checked = (panels.items._faction == nil) and true or false
        info.func = function()
          panels.items._faction = nil
          if UDDM_SetText then UDDM_SetText(itemsFactionDrop, "Both (Off)") end
        end
        UDDM_AddButton(info)
      end
      do
        local info = UDDM_CreateInfo()
        info.text = "Alliance"
        info.checked = (panels.items._faction == "Alliance") and true or false
        info.func = function()
          panels.items._faction = "Alliance"
          if UDDM_SetText then UDDM_SetText(itemsFactionDrop, "Alliance") end
        end
        UDDM_AddButton(info)
      end
      do
        local info = UDDM_CreateInfo()
        info.text = "Horde"
        info.checked = (panels.items._faction == "Horde") and true or false
        info.func = function()
          panels.items._faction = "Horde"
          if UDDM_SetText then UDDM_SetText(itemsFactionDrop, "Horde") end
        end
        UDDM_AddButton(info)
      end
    end)

    local function SetItemsColor(name)
      if name == "None" then
        panels.items._color = nil
      elseif name == "Green" then
        panels.items._color = { 0.1, 1.0, 0.1 }
      elseif name == "Blue" then
        panels.items._color = { 0.2, 0.6, 1.0 }
      elseif name == "Yellow" then
        panels.items._color = { 1.0, 0.9, 0.2 }
      elseif name == "Red" then
        panels.items._color = { 1.0, 0.2, 0.2 }
      elseif name == "Cyan" then
        panels.items._color = { 0.2, 1.0, 1.0 }
      else
        panels.items._color = nil
        name = "None"
      end
      if UDDM_SetText then UDDM_SetText(itemsColorDrop, name) end
    end

    UDDM_Initialize(itemsColorDrop, function(self, level)
      for _, name in ipairs({ "None", "Green", "Blue", "Yellow", "Red", "Cyan" }) do
        local info = UDDM_CreateInfo()
        info.text = name
        info.func = function() SetItemsColor(name) end
        UDDM_AddButton(info)
      end
    end)

    UDDM_Initialize(repMinDrop, function(self, level)
      local function Add(name, standing)
        local info = UDDM_CreateInfo()
        info.text = name
        info.checked = (panels.items._repMinStanding == standing) and true or false
        info.func = function()
          panels.items._repMinStanding = standing
          if UDDM_SetText then UDDM_SetText(repMinDrop, name) end
        end
        UDDM_AddButton(info)
      end
      Add("Off", nil)
      Add("Friendly", 5)
      Add("Honored", 6)
      Add("Revered", 7)
      Add("Exalted", 8)
    end)
  end

  local addItemBtn = CreateFrame("Button", nil, panels.items, "UIPanelButtonTemplate")
  addItemBtn:SetSize(140, 22)
  addItemBtn:SetPoint("TOPLEFT", 12, -252)
  addItemBtn:SetText("Add Item Entry")
  addItemBtn:SetScript("OnClick", function()
    local itemID = tonumber(itemIDBox:GetText() or "")
    if not itemID or itemID <= 0 then
      Print("Enter an itemID > 0.")
      return
    end

    local targetFrame = tostring(panels.items._targetFrameID or ""):gsub("%s+", "")
    if targetFrame == "" then targetFrame = "list1" end

    local repFactionID = tonumber(repFactionBox:GetText() or "")
    if repFactionID and repFactionID <= 0 then repFactionID = nil end

    local labelText = tostring(itemLabelBox:GetText() or "")
    labelText = labelText:gsub("^%s+", ""):gsub("%s+$", "")
    local label = (useNameCheck:GetChecked() and true or false) and nil or ((labelText ~= "") and labelText or nil)

    local rep = nil
    if repFactionID and panels.items._repMinStanding then
      rep = { factionID = repFactionID, minStanding = panels.items._repMinStanding, hideWhenExalted = hideExalted:GetChecked() and true or false }
    elseif repFactionID and hideExalted:GetChecked() then
      rep = { factionID = repFactionID, hideWhenExalted = true }
    end

    local rules = GetCustomRules()
    local key = string.format("custom:item:%d:%s:%d", tostring(itemID), tostring(targetFrame), (#rules + 1))
    rules[#rules + 1] = {
      key = key,
      frameID = targetFrame,
      faction = panels.items._faction,
      color = panels.items._color,
      restedOnly = restedOnly:GetChecked() and true or false,
      label = label,
      rep = rep,
      item = {
        itemID = itemID,
        required = 1,
        hideWhenAcquired = hideAcquired:GetChecked() and true or false,
      },
      hideWhenCompleted = false,
    }

    CreateAllFrames()
    RefreshAll()
    RefreshRulesList()
    Print("Added item entry for item " .. itemID .. " -> " .. targetFrame)
  end)

  -- TEXT tab
  local textTitle = panels.text:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  textTitle:SetPoint("TOPLEFT", 12, -40)
  textTitle:SetText("Text")

  local textBox = CreateFrame("EditBox", nil, panels.text, "InputBoxTemplate")
  textBox:SetSize(400, 20)
  textBox:SetPoint("TOPLEFT", 12, -70)
  textBox:SetAutoFocus(false)
  textBox:SetText("")

  local textFrameDrop = CreateFrame("Frame", nil, panels.text, "UIDropDownMenuTemplate")
  textFrameDrop:SetPoint("TOPLEFT", -8, -114)
  if UDDM_SetWidth then UDDM_SetWidth(textFrameDrop, 160) end
  if UDDM_SetText then UDDM_SetText(textFrameDrop, "list1") end
  panels.text._targetFrameID = "list1"

  local textFactionDrop = CreateFrame("Frame", nil, panels.text, "UIDropDownMenuTemplate")
  textFactionDrop:SetPoint("TOPLEFT", 165, -114)
  if UDDM_SetWidth then UDDM_SetWidth(textFactionDrop, 140) end
  if UDDM_SetText then UDDM_SetText(textFactionDrop, "Both (Off)") end
  panels.text._faction = nil

  local textColorDrop = CreateFrame("Frame", nil, panels.text, "UIDropDownMenuTemplate")
  textColorDrop:SetPoint("TOPLEFT", 325, -114)
  if UDDM_SetWidth then UDDM_SetWidth(textColorDrop, 140) end
  if UDDM_SetText then UDDM_SetText(textColorDrop, "None") end
  panels.text._color = nil

  local textRepFactionBox = CreateFrame("EditBox", nil, panels.text, "InputBoxTemplate")
  textRepFactionBox:SetSize(90, 20)
  textRepFactionBox:SetPoint("TOPLEFT", 12, -170)
  textRepFactionBox:SetAutoFocus(false)
  textRepFactionBox:SetNumeric(true)
  textRepFactionBox:SetText("0")

  local textRepMinDrop = CreateFrame("Frame", nil, panels.text, "UIDropDownMenuTemplate")
  textRepMinDrop:SetPoint("TOPLEFT", 95, -182)
  if UDDM_SetWidth then UDDM_SetWidth(textRepMinDrop, 140) end
  if UDDM_SetText then UDDM_SetText(textRepMinDrop, "Off") end
  panels.text._repMinStanding = nil

  local textRestedOnly = CreateFrame("CheckButton", nil, panels.text, "UICheckButtonTemplate")
  textRestedOnly:SetPoint("TOPLEFT", 250, -174)
  textRestedOnly.text:SetText("Rested areas only")
  textRestedOnly:SetChecked(false)

  if UDDM_Initialize and UDDM_CreateInfo and UDDM_AddButton then
    UDDM_Initialize(textFrameDrop, function(self, level)
      for _, def in ipairs(GetEffectiveFrames()) do
        if type(def) == "table" and def.id then
          local id = tostring(def.id)
          local info = UDDM_CreateInfo()
          info.text = id .. " (" .. tostring(def.type or "list") .. ")"
          info.checked = (panels.text._targetFrameID == id) and true or false
          info.func = function()
            panels.text._targetFrameID = id
            if UDDM_SetText then UDDM_SetText(textFrameDrop, id) end
          end
          UDDM_AddButton(info)
        end
      end
    end)

    UDDM_Initialize(textFactionDrop, function(self, level)
      do
        local info = UDDM_CreateInfo()
        info.text = "Both (Off)"
        info.checked = (panels.text._faction == nil) and true or false
        info.func = function()
          panels.text._faction = nil
          if UDDM_SetText then UDDM_SetText(textFactionDrop, "Both (Off)") end
        end
        UDDM_AddButton(info)
      end
      do
        local info = UDDM_CreateInfo()
        info.text = "Alliance"
        info.checked = (panels.text._faction == "Alliance") and true or false
        info.func = function()
          panels.text._faction = "Alliance"
          if UDDM_SetText then UDDM_SetText(textFactionDrop, "Alliance") end
        end
        UDDM_AddButton(info)
      end
      do
        local info = UDDM_CreateInfo()
        info.text = "Horde"
        info.checked = (panels.text._faction == "Horde") and true or false
        info.func = function()
          panels.text._faction = "Horde"
          if UDDM_SetText then UDDM_SetText(textFactionDrop, "Horde") end
        end
        UDDM_AddButton(info)
      end
    end)

    local function SetTextColor(name)
      if name == "None" then
        panels.text._color = nil
      elseif name == "Green" then
        panels.text._color = { 0.1, 1.0, 0.1 }
      elseif name == "Blue" then
        panels.text._color = { 0.2, 0.6, 1.0 }
      elseif name == "Yellow" then
        panels.text._color = { 1.0, 0.9, 0.2 }
      elseif name == "Red" then
        panels.text._color = { 1.0, 0.2, 0.2 }
      elseif name == "Cyan" then
        panels.text._color = { 0.2, 1.0, 1.0 }
      else
        panels.text._color = nil
        name = "None"
      end
      if UDDM_SetText then UDDM_SetText(textColorDrop, name) end
    end

    UDDM_Initialize(textColorDrop, function(self, level)
      for _, name in ipairs({ "None", "Green", "Blue", "Yellow", "Red", "Cyan" }) do
        local info = UDDM_CreateInfo()
        info.text = name
        info.func = function() SetTextColor(name) end
        UDDM_AddButton(info)
      end
    end)

    UDDM_Initialize(textRepMinDrop, function(self, level)
      local function Add(name, standing)
        local info = UDDM_CreateInfo()
        info.text = name
        info.checked = (panels.text._repMinStanding == standing) and true or false
        info.func = function()
          panels.text._repMinStanding = standing
          if UDDM_SetText then UDDM_SetText(textRepMinDrop, name) end
        end
        UDDM_AddButton(info)
      end
      Add("Off", nil)
      Add("Friendly", 5)
      Add("Honored", 6)
      Add("Revered", 7)
      Add("Exalted", 8)
    end)
  end

  local addTextBtn = CreateFrame("Button", nil, panels.text, "UIPanelButtonTemplate")
  addTextBtn:SetSize(140, 22)
  addTextBtn:SetPoint("TOPLEFT", 12, -210)
  addTextBtn:SetText("Add Text Entry")
  addTextBtn:SetScript("OnClick", function()
    local t = tostring(textBox:GetText() or "")
    t = t:gsub("^%s+", ""):gsub("%s+$", "")
    if t == "" then
      Print("Enter some text.")
      return
    end

    local targetFrame = tostring(panels.text._targetFrameID or ""):gsub("%s+", "")
    if targetFrame == "" then targetFrame = "list1" end

    local repFactionID = tonumber(textRepFactionBox:GetText() or "")
    if repFactionID and repFactionID <= 0 then repFactionID = nil end
    local rep = nil
    if repFactionID and panels.text._repMinStanding then
      rep = { factionID = repFactionID, minStanding = panels.text._repMinStanding }
    end

    local rules = GetCustomRules()
    local key = string.format("custom:text:%s:%s:%d", tostring(targetFrame), tostring(t), (#rules + 1))
    rules[#rules + 1] = {
      key = key,
      frameID = targetFrame,
      label = t,
      faction = panels.text._faction,
      color = panels.text._color,
      rep = rep,
      restedOnly = textRestedOnly:GetChecked() and true or false,
      hideWhenCompleted = false,
    }

    CreateAllFrames()
    RefreshAll()
    RefreshRulesList()
    Print("Added text entry -> " .. targetFrame)
  end)

  -- SPELLS tab
  local spellsTitle = panels.spells:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  spellsTitle:SetPoint("TOPLEFT", 12, -40)
  spellsTitle:SetText("Spells")

  local spellsDetailsScroll = CreateFrame("ScrollFrame", nil, panels.spells, "UIPanelScrollFrameTemplate")
  spellsDetailsScroll:SetPoint("TOPLEFT", 12, -70)
  spellsDetailsScroll:SetSize(530, 70)

  local spellsDetailsBox = CreateFrame("EditBox", nil, spellsDetailsScroll)
  spellsDetailsBox:SetMultiLine(true)
  spellsDetailsBox:SetAutoFocus(false)
  spellsDetailsBox:SetFontObject("ChatFontNormal")
  spellsDetailsBox:SetWidth(500)
  spellsDetailsBox:SetTextInsets(6, 6, 6, 6)
  spellsDetailsBox:SetText("")
  spellsDetailsBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  spellsDetailsScroll:SetScrollChild(spellsDetailsBox)
  AddPlaceholder(spellsDetailsBox, "Details")

  local classLabel = panels.spells:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  classLabel:SetPoint("TOPLEFT", 12, -146)
  classLabel:SetText("Class")

  local classDrop = CreateFrame("Frame", nil, panels.spells, "UIDropDownMenuTemplate")
  classDrop:SetPoint("TOPLEFT", -8, -174)
  if UDDM_SetWidth then UDDM_SetWidth(classDrop, 160) end
  if UDDM_SetText then UDDM_SetText(classDrop, "None") end
  panels.spells._class = nil

  local knownLabel = panels.spells:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  knownLabel:SetPoint("TOPLEFT", 180, -146)
  knownLabel:SetText("Spell Known")

  local knownBox = CreateFrame("EditBox", nil, panels.spells, "InputBoxTemplate")
  knownBox:SetSize(90, 20)
  knownBox:SetPoint("TOPLEFT", 180, -162)
  knownBox:SetAutoFocus(false)
  knownBox:SetNumeric(true)
  knownBox:SetText("0")

  local notKnownLabel = panels.spells:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  notKnownLabel:SetPoint("TOPLEFT", 280, -146)
  notKnownLabel:SetText("Not Spell Known")

  local notKnownBox = CreateFrame("EditBox", nil, panels.spells, "InputBoxTemplate")
  notKnownBox:SetSize(90, 20)
  notKnownBox:SetPoint("TOPLEFT", 280, -162)
  notKnownBox:SetAutoFocus(false)
  notKnownBox:SetNumeric(true)
  notKnownBox:SetText("0")

  local locLabel = panels.spells:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  locLabel:SetPoint("TOPLEFT", 380, -146)
  locLabel:SetText("LocationID (uiMapID)")

  local locBox = CreateFrame("EditBox", nil, panels.spells, "InputBoxTemplate")
  locBox:SetSize(90, 20)
  locBox:SetPoint("TOPLEFT", 380, -162)
  locBox:SetAutoFocus(false)
  locBox:SetText("0")

  local notInGroupCheck = CreateFrame("CheckButton", nil, panels.spells, "UICheckButtonTemplate")
  notInGroupCheck:SetPoint("TOPLEFT", 12, -198)
  notInGroupCheck.text:SetText("Not in group")
  notInGroupCheck:SetChecked(false)

  local spellsFrameDrop = CreateFrame("Frame", nil, panels.spells, "UIDropDownMenuTemplate")
  spellsFrameDrop:SetPoint("TOPLEFT", -8, -238)
  if UDDM_SetWidth then UDDM_SetWidth(spellsFrameDrop, 160) end
  if UDDM_SetText then UDDM_SetText(spellsFrameDrop, "list1") end
  panels.spells._targetFrameID = "list1"

  local spellsFactionDrop = CreateFrame("Frame", nil, panels.spells, "UIDropDownMenuTemplate")
  spellsFactionDrop:SetPoint("TOPLEFT", 165, -238)
  if UDDM_SetWidth then UDDM_SetWidth(spellsFactionDrop, 140) end
  if UDDM_SetText then UDDM_SetText(spellsFactionDrop, "Both (Off)") end
  panels.spells._faction = nil

  local spellsColorDrop = CreateFrame("Frame", nil, panels.spells, "UIDropDownMenuTemplate")
  spellsColorDrop:SetPoint("TOPLEFT", 325, -238)
  if UDDM_SetWidth then UDDM_SetWidth(spellsColorDrop, 140) end
  if UDDM_SetText then UDDM_SetText(spellsColorDrop, "None") end
  panels.spells._color = nil

  if UDDM_Initialize and UDDM_CreateInfo and UDDM_AddButton then
    UDDM_Initialize(classDrop, function(self, level)
      do
        local info = UDDM_CreateInfo()
        info.text = "None"
        info.checked = (panels.spells._class == nil) and true or false
        info.func = function()
          panels.spells._class = nil
          if UDDM_SetText then UDDM_SetText(classDrop, "None") end
        end
        UDDM_AddButton(info)
      end

      for _, tok in ipairs({
        "DEATHKNIGHT","DEMONHUNTER","DRUID","EVOKER","HUNTER","MAGE","MONK","PALADIN","PRIEST","ROGUE","SHAMAN","WARLOCK","WARRIOR",
      }) do
        local info = UDDM_CreateInfo()
        info.text = tok
        info.checked = (panels.spells._class == tok) and true or false
        info.func = function()
          panels.spells._class = tok
          if UDDM_SetText then UDDM_SetText(classDrop, tok) end
        end
        UDDM_AddButton(info)
      end
    end)

    UDDM_Initialize(spellsFrameDrop, function(self, level)
      for _, def in ipairs(GetEffectiveFrames()) do
        if type(def) == "table" and def.id then
          local id = tostring(def.id)
          local info = UDDM_CreateInfo()
          info.text = id .. " (" .. tostring(def.type or "list") .. ")"
          info.checked = (panels.spells._targetFrameID == id) and true or false
          info.func = function()
            panels.spells._targetFrameID = id
            if UDDM_SetText then UDDM_SetText(spellsFrameDrop, id) end
          end
          UDDM_AddButton(info)
        end
      end
    end)

    UDDM_Initialize(spellsFactionDrop, function(self, level)
      do
        local info = UDDM_CreateInfo()
        info.text = "Both (Off)"
        info.checked = (panels.spells._faction == nil) and true or false
        info.func = function()
          panels.spells._faction = nil
          if UDDM_SetText then UDDM_SetText(spellsFactionDrop, "Both (Off)") end
        end
        UDDM_AddButton(info)
      end
      do
        local info = UDDM_CreateInfo()
        info.text = "Alliance"
        info.checked = (panels.spells._faction == "Alliance") and true or false
        info.func = function()
          panels.spells._faction = "Alliance"
          if UDDM_SetText then UDDM_SetText(spellsFactionDrop, "Alliance") end
        end
        UDDM_AddButton(info)
      end
      do
        local info = UDDM_CreateInfo()
        info.text = "Horde"
        info.checked = (panels.spells._faction == "Horde") and true or false
        info.func = function()
          panels.spells._faction = "Horde"
          if UDDM_SetText then UDDM_SetText(spellsFactionDrop, "Horde") end
        end
        UDDM_AddButton(info)
      end
    end)

    local function SetSpellsColor(name)
      if name == "None" then
        panels.spells._color = nil
      elseif name == "Green" then
        panels.spells._color = { 0.1, 1.0, 0.1 }
      elseif name == "Blue" then
        panels.spells._color = { 0.2, 0.6, 1.0 }
      elseif name == "Yellow" then
        panels.spells._color = { 1.0, 0.9, 0.2 }
      elseif name == "Red" then
        panels.spells._color = { 1.0, 0.2, 0.2 }
      elseif name == "Cyan" then
        panels.spells._color = { 0.2, 1.0, 1.0 }
      else
        panels.spells._color = nil
        name = "None"
      end
      if UDDM_SetText then UDDM_SetText(spellsColorDrop, name) end
    end

    UDDM_Initialize(spellsColorDrop, function(self, level)
      for _, name in ipairs({ "None", "Green", "Blue", "Yellow", "Red", "Cyan" }) do
        local info = UDDM_CreateInfo()
        info.text = name
        info.func = function() SetSpellsColor(name) end
        UDDM_AddButton(info)
      end
    end)
  end

  local addSpellBtn = CreateFrame("Button", nil, panels.spells, "UIPanelButtonTemplate")
  addSpellBtn:SetSize(140, 22)
  addSpellBtn:SetPoint("TOPLEFT", 12, -280)
  addSpellBtn:SetText("Add Spell Rule")
  addSpellBtn:SetScript("OnClick", function()
    local targetFrame = tostring(panels.spells._targetFrameID or ""):gsub("%s+", "")
    if targetFrame == "" then targetFrame = "list1" end

    local known = tonumber(knownBox:GetText() or "")
    if known and known <= 0 then known = nil end
    local notKnown = tonumber(notKnownBox:GetText() or "")
    if notKnown and notKnown <= 0 then notKnown = nil end
    if not known and not notKnown then
      Print("Enter Spell Known and/or Not Spell Known.")
      return
    end

    local locText = tostring(locBox:GetText() or ""):gsub("%s+", "")
    local locationID = (locText ~= "" and locText ~= "0") and locText or nil

    local details = tostring(spellsDetailsBox:GetText() or "")
    details = details:gsub("^%s+", ""):gsub("%s+$", "")
    local label = (details ~= "") and details or nil

    local rules = GetCustomRules()
    local key = string.format("custom:spell:%s:%d", tostring(targetFrame), (#rules + 1))

    local r = {
      key = key,
      frameID = targetFrame,
      label = label,
      class = panels.spells._class,
      faction = panels.spells._faction,
      color = panels.spells._color,
      notInGroup = notInGroupCheck:GetChecked() and true or false,
      locationID = locationID,
      hideWhenCompleted = false,
    }
    if known then r.spellKnown = known end
    if notKnown then r.notSpellKnown = notKnown end

    rules[#rules + 1] = r
    CreateAllFrames()
    RefreshAll()
    RefreshRulesList()
    Print("Added spell rule -> " .. targetFrame)
  end)

  -- RULES tab (existing custom rules UI)
  local rulesTitle = panels.rules:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  rulesTitle:SetPoint("TOPLEFT", 12, -40)
  rulesTitle:SetText("Custom Rules")
  f._rulesTitle = rulesTitle

  local qBox = CreateFrame("EditBox", nil, panels.rules, "InputBoxTemplate")
  qBox:SetSize(70, 20)
  qBox:SetPoint("TOPLEFT", 12, -65)
  qBox:SetAutoFocus(false)
  qBox:SetNumeric(true)
  qBox:SetText("0")

  local labelBox = CreateFrame("EditBox", nil, panels.rules, "InputBoxTemplate")
  labelBox:SetSize(210, 20)
  labelBox:SetPoint("TOPLEFT", 90, -65)
  labelBox:SetAutoFocus(false)
  labelBox:SetText("")

  local frameBox = CreateFrame("EditBox", nil, panels.rules, "InputBoxTemplate")
  frameBox:SetSize(70, 20)
  frameBox:SetPoint("TOPLEFT", 310, -65)
  frameBox:SetAutoFocus(false)
  frameBox:SetText("bar1")

  local reqInLog = CreateFrame("CheckButton", nil, panels.rules, "UICheckButtonTemplate")
  reqInLog:SetPoint("TOPLEFT", 390, -69)
  reqInLog.text:SetText("In log")

  local hideComp = CreateFrame("CheckButton", nil, panels.rules, "UICheckButtonTemplate")
  hideComp:SetPoint("TOPLEFT", 460, -69)
  hideComp.text:SetText("Hide done")
  hideComp:SetChecked(true)

  local prereqLabel = panels.rules:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  prereqLabel:SetPoint("TOPLEFT", 12, -90)
  prereqLabel:SetText("Prereq questIDs (comma-separated):")

  local prereqBox = CreateFrame("EditBox", nil, panels.rules, "InputBoxTemplate")
  prereqBox:SetSize(210, 20)
  prereqBox:SetPoint("TOPLEFT", 200, -96)
  prereqBox:SetAutoFocus(false)
  prereqBox:SetText("")

  local groupLabel = panels.rules:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  groupLabel:SetPoint("TOPLEFT", 420, -90)
  groupLabel:SetText("Group")

  local groupBox = CreateFrame("EditBox", nil, panels.rules, "InputBoxTemplate")
  groupBox:SetSize(70, 20)
  groupBox:SetPoint("TOPLEFT", 420, -96)
  groupBox:SetAutoFocus(false)
  groupBox:SetText("")

  local orderLabel = panels.rules:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  orderLabel:SetPoint("TOPLEFT", 498, -90)
  orderLabel:SetText("Order")

  local orderBox = CreateFrame("EditBox", nil, panels.rules, "InputBoxTemplate")
  orderBox:SetSize(40, 20)
  orderBox:SetPoint("TOPLEFT", 498, -96)
  orderBox:SetAutoFocus(false)
  orderBox:SetNumeric(true)
  orderBox:SetText("0")

  local addRuleBtn = CreateFrame("Button", nil, panels.rules, "UIPanelButtonTemplate")
  addRuleBtn:SetSize(90, 22)
  addRuleBtn:SetPoint("TOPLEFT", 12, -122)
  addRuleBtn:SetText("Add Rule")
  addRuleBtn:SetScript("OnClick", function()
    local questID = tonumber(qBox:GetText() or "")
    if not questID or questID <= 0 then
      Print("Enter a questID > 0.")
      return
    end

    local targetFrame = tostring(frameBox:GetText() or ""):gsub("%s+", "")
    if targetFrame == "" then targetFrame = "list1" end

    local rules = GetCustomRules()
    local key = string.format("custom:%s:%s:%d", tostring(questID), targetFrame, (#rules + 1))

    local prereq = nil
    local prereqText = tostring(prereqBox:GetText() or "")
    prereqText = prereqText:gsub(";", ",")
    for token in prereqText:gmatch("[^,%s]+") do
      local n = tonumber(token)
      if n and n > 0 then
        prereq = prereq or {}
        prereq[#prereq + 1] = n
      end
    end

    local group = tostring(groupBox:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local order = tonumber(orderBox:GetText() or "")

    local r = {
      key = key,
      questID = questID,
      frameID = targetFrame,
      label = (labelBox:GetText() ~= "") and labelBox:GetText() or nil,
      requireInLog = reqInLog:GetChecked() and true or false,
      hideWhenCompleted = hideComp:GetChecked() and true or false,
      prereq = prereq,
      order = order,
    }
    if group ~= "" then r.group = group end
    rules[#rules + 1] = r
    CreateAllFrames()
    RefreshAll()
    RefreshRulesList()
    Print("Added rule for quest " .. questID .. " -> " .. targetFrame)
  end)

  local rulesScroll = CreateFrame("ScrollFrame", nil, panels.rules, "UIPanelScrollFrameTemplate")
  rulesScroll:SetPoint("TOPLEFT", 12, -152)
  rulesScroll:SetPoint("BOTTOMLEFT", 12, 44)
  rulesScroll:SetWidth(530)
  f._rulesScroll = rulesScroll

  local rulesContent = CreateFrame("Frame", nil, rulesScroll)
  rulesContent:SetSize(1, 1)
  rulesScroll:SetScrollChild(rulesContent)
  f._rulesContent = rulesContent
  f._ruleRows = {}

  -- FRAMES tab
  local framesTitle = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  framesTitle:SetPoint("TOPLEFT", 12, -40)
  framesTitle:SetText("Custom Frames")

  -- Global Bar Grow control (moved from General)
  local barGrowAuto = CreateFrame("CheckButton", nil, panels.frames, "UICheckButtonTemplate")
  barGrowAuto:SetPoint("TOPLEFT", 12, -156)
  barGrowAuto.text:SetText("Bar grow auto (based on anchor)")

  local barGrowDrop = CreateFrame("Frame", nil, panels.frames, "UIDropDownMenuTemplate")
  barGrowDrop:SetPoint("TOPLEFT", 230, -170)
  if UDDM_SetWidth then UDDM_SetWidth(barGrowDrop, 120) end
  if UDDM_SetText then UDDM_SetText(barGrowDrop, "center") end

  local function SetBarGrow(v)
    v = tostring(v or "auto"):lower()
    if v ~= "auto" and v ~= "left" and v ~= "right" and v ~= "center" then v = "auto" end
    SetUISetting("barGrow", v)
    if barGrowAuto then barGrowAuto:SetChecked(v == "auto") end
    if UDDM_SetText then UDDM_SetText(barGrowDrop, (v == "auto") and "center" or v) end
    if barGrowDrop then barGrowDrop:SetEnabled(v ~= "auto") end
    RefreshAll()
  end

  barGrowAuto:SetScript("OnShow", function(self)
    local v = tostring(GetUISetting("barGrow", "auto") or "auto"):lower()
    if v ~= "auto" and v ~= "left" and v ~= "right" and v ~= "center" then v = "auto" end
    self:SetChecked(v == "auto")
    if UDDM_SetText then UDDM_SetText(barGrowDrop, (v == "auto") and "center" or v) end
    if barGrowDrop then barGrowDrop:SetEnabled(v ~= "auto") end
  end)

  barGrowAuto:SetScript("OnClick", function(self)
    if self:GetChecked() then
      SetBarGrow("auto")
    else
      local prev = tostring(GetUISetting("barGrow", "auto") or "auto"):lower()
      if prev == "auto" then prev = tostring(GetUISetting("barGrowManual", "center") or "center"):lower() end
      if prev ~= "left" and prev ~= "right" and prev ~= "center" then prev = "center" end
      SetUISetting("barGrowManual", prev)
      SetBarGrow(prev)
    end
  end)

  if UDDM_Initialize and UDDM_CreateInfo and UDDM_AddButton then
    UDDM_Initialize(barGrowDrop, function(self, level)
      for _, v in ipairs({ "left", "center", "right" }) do
        local info = UDDM_CreateInfo()
        info.text = v
        info.func = function()
          SetUISetting("barGrowManual", v)
          SetBarGrow(v)
        end
        UDDM_AddButton(info)
      end
    end)
  end

  local function NextFrameID(prefix)
    local used = {}
    for _, def in ipairs(GetEffectiveFrames()) do
      if type(def) == "table" and def.id then
        used[tostring(def.id)] = true
      end
    end
    local i = 1
    while true do
      local id = prefix .. tostring(i)
      if not used[id] then return id end
      i = i + 1
    end
  end

  local addBarBtn = CreateFrame("Button", nil, panels.frames, "UIPanelButtonTemplate")
  addBarBtn:SetSize(90, 22)
  addBarBtn:SetPoint("TOPRIGHT", -110, -152)
  addBarBtn:SetText("Add Bar")
  addBarBtn:SetScript("OnClick", function()
    local frames = GetCustomFrames()
    local id = NextFrameID("bar")
    frames[#frames + 1] = {
      id = id,
      type = "bar",
      point = "TOP",
      relPoint = "TOP",
      x = 0,
      y = -40,
      width = 600,
      height = 20,
      maxItems = 6,
      bgAlpha = 0,
      hideWhenEmpty = false,
      stretchWidth = false,
    }
    CreateAllFrames()
    RefreshAll()
    RefreshFramesList()
    Print("Added frame " .. id)
  end)

  local addListBtn = CreateFrame("Button", nil, panels.frames, "UIPanelButtonTemplate")
  addListBtn:SetSize(90, 22)
  addListBtn:SetPoint("TOPRIGHT", -12, -152)
  addListBtn:SetText("Add List")
  f._addBarBtn = addBarBtn
  f._addListBtn = addListBtn
  addListBtn:SetScript("OnClick", function()
    local frames = GetCustomFrames()
    local id = NextFrameID("list")
    frames[#frames + 1] = {
      id = id,
      type = "list",
      point = "TOPRIGHT",
      relPoint = "TOPRIGHT",
      x = -10,
      y = -160,
      width = 300,
      rowHeight = 16,
      maxItems = 20,
      autoSize = true,
      hideWhenEmpty = false,
    }
    CreateAllFrames()
    RefreshAll()
    RefreshFramesList()
    Print("Added frame " .. id)
  end)

  local framesScroll = CreateFrame("ScrollFrame", nil, panels.frames, "UIPanelScrollFrameTemplate")
  framesScroll:SetPoint("TOPLEFT", 12, -182)
  framesScroll:SetPoint("BOTTOMLEFT", 12, 44)
  framesScroll:SetWidth(530)

  local framesContent = CreateFrame("Frame", nil, framesScroll)
  framesContent:SetSize(1, 1)
  framesScroll:SetScrollChild(framesContent)
  f._framesContent = framesContent
  f._frameRows = {}
  f._framesScroll = framesScroll
  f._framesTitle = framesTitle

  -- Frame editor (shown only when Show frame list is enabled)
  local frameEditTitle = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frameEditTitle:SetPoint("TOPLEFT", 12, -70)
  frameEditTitle:SetText("Frame settings")
  f._frameEditTitle = frameEditTitle

  local frameEditLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  frameEditLabel:SetPoint("TOPLEFT", 12, -88)
  frameEditLabel:SetText("Select frame:")
  f._frameEditLabel = frameEditLabel

  local frameDrop = CreateFrame("Frame", nil, panels.frames, "UIDropDownMenuTemplate")
  frameDrop:SetPoint("TOPLEFT", -8, -98)
  -- reuse dropdown helpers if present (quest tab created its own locals above)

  if UDDM_SetWidth then UDDM_SetWidth(frameDrop, 160) end
  if UDDM_SetText then UDDM_SetText(frameDrop, "(pick)") end
  f._frameDrop = frameDrop
  f._selectedFrameID = nil

  local frameAuto = CreateFrame("CheckButton", nil, panels.frames, "UICheckButtonTemplate")
  frameAuto:SetPoint("TOPLEFT", 200, -102)
  frameAuto.text:SetText("Auto")
  f._frameAuto = frameAuto

  local frameHideCombat = CreateFrame("CheckButton", nil, panels.frames, "UICheckButtonTemplate")
  frameHideCombat:SetPoint("TOPLEFT", 260, -102)
  frameHideCombat.text:SetText("Hide in combat")
  frameHideCombat:Hide()
  f._frameHideCombat = frameHideCombat

  local widthLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  widthLabel:SetPoint("TOPLEFT", 12, -130)
  widthLabel:SetText("Width")
  f._frameWidthLabel = widthLabel

  local widthBox = CreateFrame("EditBox", nil, panels.frames, "InputBoxTemplate")
  widthBox:SetSize(60, 20)
  widthBox:SetPoint("TOPLEFT", 55, -136)
  widthBox:SetAutoFocus(false)
  widthBox:SetNumeric(true)
  widthBox:SetText("0")
  f._frameWidthBox = widthBox

  local heightLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  heightLabel:SetPoint("TOPLEFT", 125, -130)
  heightLabel:SetText("Height")
  f._frameHeightLabel = heightLabel

  local heightBox = CreateFrame("EditBox", nil, panels.frames, "InputBoxTemplate")
  heightBox:SetSize(60, 20)
  heightBox:SetPoint("TOPLEFT", 175, -136)
  heightBox:SetAutoFocus(false)
  heightBox:SetNumeric(true)
  heightBox:SetText("0")
  f._frameHeightBox = heightBox

  local lengthLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  lengthLabel:SetPoint("TOPLEFT", 245, -130)
  lengthLabel:SetText("Length")
  f._frameLengthLabel = lengthLabel

  local lengthBox = CreateFrame("EditBox", nil, panels.frames, "InputBoxTemplate")
  lengthBox:SetSize(60, 20)
  lengthBox:SetPoint("TOPLEFT", 292, -136)
  lengthBox:SetAutoFocus(false)
  lengthBox:SetNumeric(true)
  lengthBox:SetText("0")
  f._frameLengthBox = lengthBox

  local function FindEffectiveFrameDef(id)
    id = tostring(id or "")
    if id == "" then return nil end
    for _, def in ipairs(GetEffectiveFrames()) do
      if type(def) == "table" and tostring(def.id or "") == id then
        return def
      end
    end
    return nil
  end

  local function FindOrCreateCustomFrameDef(id)
    id = tostring(id or "")
    if id == "" then return nil end
    local frames = GetCustomFrames()
    for _, def in ipairs(frames) do
      if type(def) == "table" and tostring(def.id or "") == id then
        return def
      end
    end
    local base = FindEffectiveFrameDef(id)
    if not base then return nil end
    local copy = ShallowCopyTable(base) or { id = id }
    copy.id = id
    frames[#frames + 1] = copy
    return copy
  end

  local function UpdateFrameEditor()
    if not optionsFrame then return end
    local id = tostring(optionsFrame._selectedFrameID or "")
    local def = FindEffectiveFrameDef(id)
    if not def then
      if UDDM_SetText then UDDM_SetText(optionsFrame._frameDrop, "(pick)") end
      optionsFrame._frameAuto:SetChecked(false)
      if optionsFrame._frameHideCombat then
        optionsFrame._frameHideCombat:SetChecked(false)
        optionsFrame._frameHideCombat:Hide()
      end
      optionsFrame._frameWidthBox:SetText("0")
      optionsFrame._frameHeightBox:SetText("0")
      optionsFrame._frameLengthBox:SetText("0")
      return
    end

    if UDDM_SetText then UDDM_SetText(optionsFrame._frameDrop, tostring(def.id)) end

    local t = tostring(def.type or "list")
    if t == "list" then
      optionsFrame._frameHeightLabel:SetText("Row")
      optionsFrame._frameLengthLabel:SetText("Rows")
      optionsFrame._frameHeightBox:SetText(tostring(tonumber(def.rowHeight) or 16))
    else
      optionsFrame._frameHeightLabel:SetText("Height")
      optionsFrame._frameLengthLabel:SetText("Segments")
      optionsFrame._frameHeightBox:SetText(tostring(tonumber(def.height) or 20))
    end

    if optionsFrame._frameHideCombat then
      if t == "list" then
        optionsFrame._frameHideCombat:SetChecked(def.hideInCombat == true)
        optionsFrame._frameHideCombat:Show()
      else
        optionsFrame._frameHideCombat:SetChecked(false)
        optionsFrame._frameHideCombat:Hide()
      end
    end

    optionsFrame._frameWidthBox:SetText(tostring(tonumber(def.width) or 300))
    optionsFrame._frameLengthBox:SetText(tostring(tonumber(def.maxItems) or (t == "list" and 20 or 6)))

    -- Auto means: use defaults/fallback sizing (clear overrides)
    local isAuto = false
    local custom = nil
    for _, c in ipairs(GetCustomFrames()) do
      if type(c) == "table" and tostring(c.id or "") == tostring(def.id or "") then
        custom = c
        break
      end
    end
    if custom then
      local hasSize = (custom.width ~= nil) or (custom.height ~= nil) or (custom.rowHeight ~= nil) or (custom.maxItems ~= nil)
      isAuto = not hasSize
    else
      isAuto = true
    end
    optionsFrame._frameAuto:SetChecked(isAuto)

    local enableInputs = not isAuto
    optionsFrame._frameWidthBox:SetEnabled(enableInputs)
    optionsFrame._frameHeightBox:SetEnabled(enableInputs)
    optionsFrame._frameLengthBox:SetEnabled(enableInputs)
  end

  frameHideCombat:SetScript("OnClick", function(self)
    if not optionsFrame then return end
    local id = tostring(optionsFrame._selectedFrameID or "")
    if id == "" then return end
    local eff = FindEffectiveFrameDef(id)
    if not eff then return end
    if tostring(eff.type or "list") ~= "list" then
      self:SetChecked(false)
      self:Hide()
      return
    end

    local def = FindOrCreateCustomFrameDef(id)
    if not def then return end
    def.hideInCombat = self:GetChecked() and true or nil
    RefreshAll()
    RefreshFramesList()
  end)

  if UDDM_Initialize and UDDM_CreateInfo and UDDM_AddButton then
    UDDM_Initialize(frameDrop, function(self, level)
      local info = UDDM_CreateInfo()
      for _, def in ipairs(GetEffectiveFrames()) do
        if type(def) == "table" and def.id then
          local id = tostring(def.id)
          info.text = id .. " (" .. tostring(def.type or "list") .. ")"
          info.checked = (optionsFrame and optionsFrame._selectedFrameID == id) and true or false
          info.func = function()
            optionsFrame._selectedFrameID = id
            UpdateFrameEditor()
          end
          UDDM_AddButton(info)
        end
      end
    end)
  else
    frameEditLabel:SetText("Select frame: (dropdown unavailable)")
  end

  frameAuto:SetScript("OnClick", function(self)
    if not optionsFrame then return end
    local id = tostring(optionsFrame._selectedFrameID or "")
    if id == "" then return end
    local def = FindOrCreateCustomFrameDef(id)
    if not def then return end
    if self:GetChecked() then
      def.width = nil
      def.height = nil
      def.rowHeight = nil
      def.maxItems = nil
    end
    CreateAllFrames()
    RefreshAll()
    RefreshFramesList()
  end)

  local function ApplyFrameSizeFromInputs()
    if not optionsFrame then return end
    local id = tostring(optionsFrame._selectedFrameID or "")
    if id == "" then return end
    local eff = FindEffectiveFrameDef(id)
    local def = FindOrCreateCustomFrameDef(id)
    if not (eff and def) then return end

    if optionsFrame._frameAuto:GetChecked() then
      def.width = nil
      def.height = nil
      def.rowHeight = nil
      def.maxItems = nil
    else
      def.width = tonumber(optionsFrame._frameWidthBox:GetText() or "")
      def.maxItems = tonumber(optionsFrame._frameLengthBox:GetText() or "")
      if tostring(eff.type or "list") == "list" then
        def.rowHeight = tonumber(optionsFrame._frameHeightBox:GetText() or "")
      else
        def.height = tonumber(optionsFrame._frameHeightBox:GetText() or "")
      end
    end

    CreateAllFrames()
    RefreshAll()
    RefreshFramesList()
  end

  widthBox:SetScript("OnEnterPressed", function(self) self:ClearFocus(); ApplyFrameSizeFromInputs() end)
  heightBox:SetScript("OnEnterPressed", function(self) self:ClearFocus(); ApplyFrameSizeFromInputs() end)
  lengthBox:SetScript("OnEnterPressed", function(self) self:ClearFocus(); ApplyFrameSizeFromInputs() end)

  RefreshFramesList = function()
    if not optionsFrame then return end
    UpdateFrameEditor()

    local frames = GetCustomFrames()
    local rowH = 18
    local fcontent = optionsFrame._framesContent
    local frows = optionsFrame._frameRows
    fcontent:SetHeight(math.max(1, #frames * rowH))

    for i = 1, #frames do
      local def = frames[i]
      local row = frows[i]
      if not row then
        row = CreateFrame("Frame", nil, fcontent)
        row:SetHeight(rowH)
        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.text:SetPoint("LEFT", 2, 0)
        row.del = CreateFrame("Button", nil, row, "UIPanelCloseButton")
        row.del:SetSize(20, 20)
        row.del:SetPoint("RIGHT", 6, 0)
        frows[i] = row
      end

      row:SetPoint("TOPLEFT", 0, -(i - 1) * rowH)
      row:SetPoint("TOPRIGHT", 0, -(i - 1) * rowH)
      row.text:SetText(string.format("%s  (%s)", tostring(def and def.id or ""), tostring(def and def.type or "list")))

      local idx = i
      row.del:SetScript("OnClick", function()
        local id = tostring(frames[idx] and frames[idx].id or "")
        table.remove(frames, idx)
        if id ~= "" then DestroyFrameByID(id) end
        RefreshAll()
        RefreshFramesList()
        Print("Removed frame " .. (id ~= "" and id or "(unknown)") .. ".")
      end)

      row:Show()
    end
    for i = #frames + 1, #frows do
      if frows[i] then frows[i]:Hide() end
    end
  end

  RefreshRulesList = function()
    if not optionsFrame then return end

    local rules = GetCustomRules()
    local rowH = 18
    local content = optionsFrame._rulesContent
    local rows = optionsFrame._ruleRows
    content:SetHeight(math.max(1, #rules * rowH))

    for i = 1, #rules do
      local r = rules[i]
      local row = rows[i]
      if not row then
        row = CreateFrame("Frame", nil, content)
        row:SetHeight(rowH)
        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.text:SetPoint("LEFT", 2, 0)
        row.del = CreateFrame("Button", nil, row, "UIPanelCloseButton")
        row.del:SetSize(20, 20)
        row.del:SetPoint("RIGHT", 6, 0)
        rows[i] = row
      end

      row:SetPoint("TOPLEFT", 0, -(i - 1) * rowH)
      row:SetPoint("TOPRIGHT", 0, -(i - 1) * rowH)

      local frameID = tostring(r and r.frameID or "")
      local fac = (type(r) == "table" and (r.faction == "Alliance" or r.faction == "Horde")) and (" [" .. tostring(r.faction) .. "]") or ""
      local rested = (type(r) == "table" and r.restedOnly == true) and " [Rested]" or ""

      local rep = ""
      if type(r) == "table" and type(r.rep) == "table" and r.rep.factionID then
        local min = tonumber(r.rep.minStanding)
        rep = string.format(" [Rep:%s%s%s]", tostring(r.rep.factionID), min and (":" .. tostring(min)) or "", r.rep.hideWhenExalted and ",hideEx" or "")
      end

      local label = (r and r.label) and tostring(r.label) or ""
      label = label:gsub("\n", " ")

      if type(r) == "table" and type(r.item) == "table" and r.item.itemID then
        local itemID = tonumber(r.item.itemID) or 0
        local base = (label ~= "") and label or ("Item " .. tostring(itemID))
        local hide = (r.item.hideWhenAcquired == true) and " [HideAcq]" or ""
        row.text:SetText(string.format("Item %d  %s%s%s%s%s  -> %s", itemID, base, fac, rested, rep, hide, frameID))
      elseif tonumber(r and r.questID) and tonumber(r.questID) > 0 then
        local q = tonumber(r.questID) or 0
        local base = (label ~= "") and label or ""
        row.text:SetText(string.format("Quest %d  %s%s%s%s  -> %s", q, base, fac, rested, rep, frameID))
      else
        local base = (label ~= "") and label or "Text"
        row.text:SetText(string.format("Text  %s%s%s%s  -> %s", base, fac, rested, rep, frameID))
      end

      local idx = i
      row.del:SetScript("OnClick", function()
        table.remove(rules, idx)
        RefreshAll()
        RefreshRulesList()
        Print("Removed custom rule.")
      end)

      row:Show()
    end
    for i = #rules + 1, #rows do
      if rows[i] then rows[i]:Hide() end
    end
  end

  RefreshActiveTab = function()
    if not optionsFrame then return end
    local t = optionsFrame._activeTab
    if t == "frames" then
      RefreshFramesList()
    elseif t == "rules" then
      RefreshRulesList()
    end
  end

  local resetBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  resetBtn:SetSize(160, 22)
  resetBtn:SetPoint("BOTTOMLEFT", 12, 12)
  resetBtn:SetText("Reset frame positions")
  resetBtn:SetScript("OnClick", function()
    ResetFramePositionsToDefaults()
    RefreshAll()
    RefreshActiveTab()
    Print("Frame positions reset to defaults.")
  end)

  local reloadBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  reloadBtn:SetSize(160, 22)
  reloadBtn:SetPoint("BOTTOMRIGHT", -12, 12)
  reloadBtn:SetText("/reload")
  reloadBtn:SetScript("OnClick", function()
    local r = _G and _G["ReloadUI"]
    if r then r() end
  end)

  optionsFrame = f
  -- default tab (persisted)
  local initial = tostring(GetUISetting("optionsTab", "quest") or "quest")
  if not panels[initial] then initial = "quest" end
  SelectTab(initial)
  return f
end

local function ShowOptions()
  local f = EnsureOptionsFrame()
  RefreshActiveTab()
  f:Show()
end

local function RenderList(frameDef, frame, entries)
  local maxItems = tonumber(frameDef.maxItems) or 20
  local rowH = tonumber(frameDef.rowHeight) or 16

  if frame.title then
    frame.title:Show()
    frame.title:SetText("|cff00ccff[FQT]|r " .. (frameDef.id or "list"))
  end

  local shown = 0

  for i = 1, maxItems do
    local e = entries[i]
    local fs = EnsureFontString(frame, i, frameDef and frameDef.font)
    fs:ClearAllPoints()
    fs:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -22 - (i - 1) * rowH)

    ApplyFontStyle(fs, frameDef and frameDef.font)

    local btn = EnsureRowButton(frame, i)
    btn:ClearAllPoints()
    btn:SetPoint("TOPLEFT", fs, "TOPLEFT", -2, 2)
    btn:SetPoint("BOTTOMRIGHT", fs, "BOTTOMRIGHT", 2, -2)
    btn._entry = e
    btn:EnableMouse(editMode and true or false)
    if editMode then
      btn:Show()
    else
      btn:Hide()
    end

    if e then
      local text = e.title
      if e.extra then text = text .. "  " .. e.extra .. " " end
      fs:SetText(" " .. text .. " ")
      fs:Show()
      RenderIndicators(frame, i, fs, e.indicators)
      shown = shown + 1
    else
      fs:SetText("")
      fs:Hide()
      RenderIndicators(frame, i, fs, nil)
    end
  end

  if frameDef and frameDef.autoSize then
    local padTop = 22
    local padBottom = 8
    local minRows = tonumber(frameDef.minRows) or 0
    local rows = shown
    if editMode then rows = maxItems end
    if rows < minRows then rows = minRows end
    frame:SetHeight(padTop + padBottom + rows * rowH)
  end
end

RefreshAll = function()
  NormalizeSV()

  local rules = GetEffectiveRules()

  local frames = GetEffectiveFrames()
  local frameDefsByID = {}
  local entriesByFrameID = {}
  local frameIDsByType = { bar = {}, list = {} }

  for _, def in ipairs(frames) do
    local id = tostring(def.id or "")
    if id ~= "" then
      frameDefsByID[id] = def
      entriesByFrameID[id] = entriesByFrameID[id] or {}
      local t = tostring(def.type or "list"):lower()
      if t ~= "bar" then t = "list" end
      frameIDsByType[t][#frameIDsByType[t] + 1] = id
    end
  end

  local function AddToFrame(frameID, status)
    if not (frameID and entriesByFrameID[frameID]) then return end
    entriesByFrameID[frameID][#entriesByFrameID[frameID] + 1] = status
  end

  local staged = {}
  local function Stage(frameID, rule, status)
    staged[#staged + 1] = { frameID = frameID, rule = rule, status = status }
  end

  for _, rule in ipairs(rules) do
    local status = BuildRuleStatus(rule)
    if status then
      if type(rule.targets) == "table" then
        for _, frameID in ipairs(rule.targets) do
          Stage(tostring(frameID), rule, status)
        end
      elseif rule.frameID then
        Stage(tostring(rule.frameID), rule, status)
      else
        local display = tostring(rule.display or "list"):lower()
        if display ~= "bar" then display = "list" end
        for _, frameID in ipairs(frameIDsByType[display]) do
          Stage(frameID, rule, status)
        end
      end
    end
  end

  if editMode then
    -- In edit mode, show everything (no group collapsing) so it's easy to toggle/inspect.
    for _, row in ipairs(staged) do
      AddToFrame(row.frameID, row.status)
    end
  else
    -- Sequential groups: if rule.group is set, only the lowest-order active entry per (frameID, group) is shown.
    local winnersByGroup = {}
    for _, row in ipairs(staged) do
      local frameID = row.frameID
      local rule = row.rule
      local status = row.status
      local group = rule and rule.group
      local order = tonumber(rule and rule.order) or 0

      if group ~= nil then
        local key = frameID .. "|" .. tostring(group)
        local current = winnersByGroup[key]
        if not current or order < current.order then
          winnersByGroup[key] = { order = order, status = status, frameID = frameID }
        end
      else
        AddToFrame(frameID, status)
      end
    end

    for _, win in pairs(winnersByGroup) do
      AddToFrame(win.frameID, win.status)
    end
  end

  for _, def in ipairs(frames) do
    local id = tostring(def.id or "")
    local f = framesByID[id]
    if f then
      -- late parent binding (useful when parent addon loads after us)
      if type(def) == "table" and def.parentFrame then
        local p = _G and _G[tostring(def.parentFrame)]
        if p and f:GetParent() ~= p then
          f:SetParent(p)
        end
      end

      if editMode then
        local a = (type(def) == "table") and tonumber(def.bgAlpha) or nil
        if not a or a < 0.25 then a = 0.25 end
        ApplyFAOBackdrop(f, a)
      elseif type(def) == "table" and def.bgAlpha ~= nil then
        ApplyFAOBackdrop(f, def.bgAlpha)
      end

      local t = tostring(def.type or "list"):lower()
      local entries = entriesByFrameID[id] or {}
      local hasAny = entries[1] ~= nil

      if not framesEnabled then
        f:Hide()
      elseif editMode then
        f:Show()
      elseif type(def) == "table" and def.hideInCombat == true and InCombatLockdown and InCombatLockdown() then
        f:Hide()
      elseif (def.hideWhenEmpty ~= false) and not hasAny then
        f:Hide()
      else
        f:Show()
      end

      if t == "bar" then
        RenderBar(def, f, entries)
      else
        RenderList(def, f, entries)
      end
    end
  end
end

CreateAllFrames = function()
  for _, def in ipairs(GetEffectiveFrames()) do
    local id = tostring(def.id or "")
    if id ~= "" and not framesByID[id] then
      local t = tostring(def.type or "list"):lower()
      if t == "bar" then
        framesByID[id] = CreateBarFrame(def)
      else
        framesByID[id] = CreateListFrame(def)
      end
    end
  end
end

DestroyFrameByID = function(id)
  id = tostring(id or "")
  if id == "" then return end
  local f = framesByID[id]
  if not f then return end
  f:Hide()
  f:SetParent(nil)
  framesByID[id] = nil
end

-- Events
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("QUEST_LOG_UPDATE")
frame:RegisterEvent("QUEST_ACCEPTED")
frame:RegisterEvent("QUEST_TURNED_IN")
frame:RegisterEvent("BAG_UPDATE_DELAYED")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("CALENDAR_UPDATE_EVENT_LIST")
frame:RegisterEvent("CALENDAR_UPDATE_EVENT")

frame:SetScript("OnEvent", function(_, event, ...)
  if event == "UNIT_AURA" then
    local unit = ...
    if unit ~= "player" then return end
  end

  if event == "PLAYER_LOGIN" then
    NormalizeSV()
    CreateAllFrames()
    C_Timer.After(1.0, RefreshAll)
    Print("Loaded. Edit rules in fr0z3nUI_QuestTrackerDB.lua")
    return
  end

  -- debounce rapid spam
  if frame._refreshTimer then
    frame._refreshTimer:Cancel()
  end
  frame._refreshTimer = C_Timer.NewTimer(0.25, RefreshAll)
end)

SLASH_FR0Z3NUIFQT1 = "/fqt"
SlashCmdList["FR0Z3NUIFQT"] = function(msg)
  msg = tostring(msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
  if msg == "" then
    ShowOptions()
    return
  end
  if msg == "on" then
    framesEnabled = true
    RefreshAll()
    Print("Enabled.")
    return
  end
  if msg == "off" then
    framesEnabled = false
    RefreshAll()
    Print("Disabled.")
    return
  end
  if msg == "edit" then
    editMode = not editMode
    RefreshAll()
    Print(editMode and "Edit mode ON (click rows to toggle OFF/ON)." or "Edit mode OFF.")
    return
  end

  if msg == "reset" then
    ResetFramePositionsToDefaults()
    RefreshAll()
    Print("Frame positions reset to defaults.")
    return
  end

  if msg == "twdebug" then
    Print("Timewalking debug:")
    EnsureCalendarOpened()
    if not (C_Calendar and C_Calendar.GetNumDayEvents) then
      Print("Calendar API unavailable.")
      return
    end

    local today = GetCurrentCalendarDay()
    if not today then
      Print("Calendar date unavailable (try opening the Calendar once).")
      return
    end

    local numDays = GetCurrentMonthNumDays()
    local startDay = today - 1
    local endDay = today + 7
    if startDay < 1 then startDay = 1 end
    if endDay > numDays then endDay = numDays end

    local any = false
    for day = startDay, endDay do
      local okNum, n = pcall(C_Calendar.GetNumDayEvents, 0, day)
      n = okNum and tonumber(n) or 0
      for i = 1, n do
        local title = GetCalendarEventText(0, day, i) or ""
        local holidayText = GetCalendarHolidayText(0, day, i) or ""
        local hay = (title .. "\n" .. holidayText):lower()
        if hay:find("timewalking", 1, true) then
          any = true
          local h = holidayText:gsub("\n", " ")
          if #h > 140 then h = h:sub(1, 140) .. "..." end
          Print(string.format("Day %d: %s", day, title ~= "" and title or "(no title)"))
          if h ~= "" then
            Print("  Holiday: " .. h)
          end
        end
      end
    end

    if not any then
      Print("No timewalking found in calendar window.")
    end
    return
  end

  Print("Commands: /fqt (options), /fqt on, /fqt off, /fqt edit, /fqt reset, /fqt twdebug")
end
