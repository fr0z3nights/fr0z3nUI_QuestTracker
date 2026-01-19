local addonName, ns = ...

local PREFIX = "|cff00ccff[FQT]|r "
local function Print(msg)
  print(PREFIX .. tostring(msg or ""))
end

ns.Print = Print

local framesEnabled = true
local editMode = false

local GetUISetting, SetUISetting

local GetPlayerClass, GetPrimaryProfessionNames, HasTradeSkillLine, CanQueryTradeSkillLines

local function CopyArray(src)
  if type(src) ~= "table" then return nil end
  local out = {}
  for i = 1, #src do
    out[i] = src[i]
  end
  return out
end

local function SetCheckButtonLabel(btn, text)
  if not btn then return end
  local label = btn.text or btn.Text
  if not label and btn.GetName and _G then
    local name = btn:GetName()
    if name then
      label = _G[name .. "Text"]
    end
  end
  if label and label.SetText then
    label:SetText(tostring(text or ""))
  end
  if btn.Text and not btn.text then
    btn.text = btn.Text
  end
end

ns.CopyArray = CopyArray

local function PrereqListKey(prereq)
  if type(prereq) ~= "table" then return "" end
  local out = {}
  for _, n in ipairs(prereq) do
    local v = tonumber(n)
    if v and v > 0 then out[#out + 1] = tostring(v) end
  end
  return table.concat(out, ",")
end

ns.PrereqListKey = PrereqListKey

local function GetWAExportDB()
  local db = _G and _G["fr0z3nUI_QuestTracker_WAExportDB"]
  if type(db) ~= "table" then
    db = { version = 1, exports = {} }
    if _G then _G["fr0z3nUI_QuestTracker_WAExportDB"] = db end
  end
  if type(db.exports) ~= "table" then db.exports = {} end
  if type(db.version) ~= "number" then db.version = 1 end
  return db
end

ns.GetWAExportDB = GetWAExportDB

local function SaveWAExportSnapshot(snapshot)
  if type(snapshot) ~= "table" then return false end
  local db = GetWAExportDB()
  db.exports[#db.exports + 1] = snapshot
  return true
end

ns.SaveWAExportSnapshot = SaveWAExportSnapshot

local _rulesNormalized = false

local function NormalizePlayerLevelOp(op)
  op = tostring(op or ""):gsub("%s+", "")
  if op == "" then return nil end
  if op == "==" then op = "=" end
  if op == "~=" then op = "!=" end
  if op == "<" or op == "<=" or op == "=" or op == ">=" or op == ">" or op == "!=" then
    return op
  end
  return nil
end

local function NormalizeLocationID(value)
  local n = tonumber((tostring(value or ""):gsub("[^0-9]", "")))
  if n and n > 0 then return n end
  return nil
end

local function NormalizeRuleInPlace(rule)
  if type(rule) ~= "table" then return end

  if rule.locationID ~= nil then
    rule.locationID = NormalizeLocationID(rule.locationID)
  end

  if rule.playerLevelOp ~= nil then
    rule.playerLevelOp = NormalizePlayerLevelOp(rule.playerLevelOp)
    if rule.playerLevelOp == nil then
      rule.playerLevel = nil
    end
  end

  if rule.playerLevel ~= nil then
    local n = tonumber(rule.playerLevel)
    if n and n > 0 then
      rule.playerLevel = n
    else
      rule.playerLevel = nil
      rule.playerLevelOp = nil
    end
  end

  if type(rule.label) == "string" then
    local t = string.gsub(rule.label, "^%s+", "")
    t = string.gsub(t, "%s+$", "")
    rule.label = (t ~= "") and t or nil
  end

  if type(rule.prereq) == "table" then
    local out = {}
    for _, q in ipairs(rule.prereq) do
      local id = tonumber(q)
      if id and id > 0 then out[#out + 1] = id end
    end
    rule.prereq = out[1] and out or nil
  end
end

local function EnsureRulesNormalized()
  if _rulesNormalized then return end

  local acc = fr0z3nUI_QuestTracker_Acc
  local settings = (type(acc) == "table") and acc.settings or nil
  if type(settings) ~= "table" then return end

  local custom = settings.customRules
  if type(custom) == "table" then
    for _, r in ipairs(custom) do
      NormalizeRuleInPlace(r)
    end
  end

  local trash = settings.customRulesTrash
  if type(trash) == "table" then
    for _, r in ipairs(trash) do
      NormalizeRuleInPlace(r)
    end
  end

  _rulesNormalized = true
end

local function NormalizeSV()
  fr0z3nUI_QuestTracker_Acc = fr0z3nUI_QuestTracker_Acc or {}
  fr0z3nUI_QuestTracker_Char = fr0z3nUI_QuestTracker_Char or {}

  fr0z3nUI_QuestTracker_Acc.settings = fr0z3nUI_QuestTracker_Acc.settings or {}
  fr0z3nUI_QuestTracker_Acc.settings.ui = fr0z3nUI_QuestTracker_Acc.settings.ui or {}
  fr0z3nUI_QuestTracker_Acc.settings.customRules = fr0z3nUI_QuestTracker_Acc.settings.customRules or {}
  fr0z3nUI_QuestTracker_Acc.settings.customRulesTrash = fr0z3nUI_QuestTracker_Acc.settings.customRulesTrash or {}
  fr0z3nUI_QuestTracker_Acc.settings.customFrames = fr0z3nUI_QuestTracker_Acc.settings.customFrames or {}
  fr0z3nUI_QuestTracker_Char.settings = fr0z3nUI_QuestTracker_Char.settings or {}

  fr0z3nUI_QuestTracker_Char.settings.disabledRules = fr0z3nUI_QuestTracker_Char.settings.disabledRules or {}
  fr0z3nUI_QuestTracker_Char.settings.framePos = fr0z3nUI_QuestTracker_Char.settings.framePos or {}
  fr0z3nUI_QuestTracker_Char.settings.frameScroll = fr0z3nUI_QuestTracker_Char.settings.frameScroll or {}

  fr0z3nUI_QuestTracker_Acc.cache = fr0z3nUI_QuestTracker_Acc.cache or {}
  fr0z3nUI_QuestTracker_Acc.cache.weeklyAuras = fr0z3nUI_QuestTracker_Acc.cache.weeklyAuras or {}

  EnsureRulesNormalized()
end

local function GetFrameScrollStore()
  NormalizeSV()
  fr0z3nUI_QuestTracker_Char.settings.frameScroll = fr0z3nUI_QuestTracker_Char.settings.frameScroll or {}
  return fr0z3nUI_QuestTracker_Char.settings.frameScroll
end

local function GetFrameScrollOffset(frameID)
  frameID = tostring(frameID or "")
  if frameID == "" then return 0 end
  local store = GetFrameScrollStore()
  local v = tonumber(store[frameID]) or 0
  if v < 0 then v = 0 end
  return v
end

local function SetFrameScrollOffset(frameID, offset)
  frameID = tostring(frameID or "")
  if frameID == "" then return end
  local store = GetFrameScrollStore()
  offset = tonumber(offset) or 0
  if offset < 0 then offset = 0 end
  store[frameID] = offset
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

ns.GetCustomRules = GetCustomRules

local function GetCustomRulesTrash()
  NormalizeSV()
  local t = fr0z3nUI_QuestTracker_Acc.settings.customRulesTrash
  if type(t) ~= "table" then
    t = {}
    fr0z3nUI_QuestTracker_Acc.settings.customRulesTrash = t
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

ns.GetUISetting = GetUISetting

SetUISetting = function(key, value)
  NormalizeSV()
  fr0z3nUI_QuestTracker_Acc.settings.ui[key] = value
end

ns.SetUISetting = SetUISetting

local function GetWindowPosStore()
  NormalizeSV()
  local ui = fr0z3nUI_QuestTracker_Acc.settings.ui
  if type(ui.windowPos) ~= "table" then
    ui.windowPos = {}
  end
  return ui.windowPos
end

local function SaveWindowPosition(name, frame)
  if not (frame and frame.GetPoint) then return end
  local point, relTo, relPoint, xOfs, yOfs = frame:GetPoint(1)
  if not point then return end
  local store = GetWindowPosStore()
  store[tostring(name or "")] = {
    point = point,
    relPoint = relPoint or point,
    x = tonumber(xOfs) or 0,
    y = tonumber(yOfs) or 0,
  }
end

ns.SaveWindowPosition = SaveWindowPosition

local function RestoreWindowPosition(name, frame, defPoint, defRelPoint, defX, defY)
  if not (frame and frame.ClearAllPoints and frame.SetPoint) then return false end
  local store = GetWindowPosStore()
  local pos = store[tostring(name or "")]
  local point = (type(pos) == "table") and pos.point or nil
  local relPoint = (type(pos) == "table") and (pos.relPoint or pos.point) or nil
  local x = (type(pos) == "table") and pos.x or nil
  local y = (type(pos) == "table") and pos.y or nil

  local function TrySetUserPlaced()
    if not (frame and frame.SetUserPlaced) then return end
    local movable = (frame.IsMovable and frame:IsMovable()) or false
    local resizable = (frame.IsResizable and frame:IsResizable()) or false
    if not (movable or resizable) then return end
    pcall(frame.SetUserPlaced, frame, true)
  end

  frame:ClearAllPoints()
  if point then
    frame:SetPoint(point, UIParent, relPoint or point, tonumber(x) or 0, tonumber(y) or 0)
    TrySetUserPlaced()
    return true
  end

  if defPoint then
    frame:SetPoint(defPoint, UIParent, defRelPoint or defPoint, tonumber(defX) or 0, tonumber(defY) or 0)
    TrySetUserPlaced()
  end
  return false
end

ns.RestoreWindowPosition = RestoreWindowPosition

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

local function DeepCopyValue(v, seen)
  if type(v) ~= "table" then return v end
  seen = seen or {}
  if seen[v] then return seen[v] end
  local out = {}
  seen[v] = out
  for k2, v2 in pairs(v) do
    out[DeepCopyValue(k2, seen)] = DeepCopyValue(v2, seen)
  end
  return out
end

local function MakeUniqueRuleKey(prefix)
  prefix = tostring(prefix or "custom")
  local t = tostring((type(time) == "function") and time() or 0)
  local r = tostring(math.random(100000, 999999))
  return prefix .. ":" .. t .. ":" .. r
end

local function EnsureUniqueKeyForCustomRule(rule)
  if type(rule) ~= "table" then return end
  local rules = GetCustomRules()
  local used = {}
  for _, r in ipairs(rules) do
    if type(r) == "table" and r.key then
      used[tostring(r.key)] = true
    end
  end
  local key = rule.key and tostring(rule.key) or ""
  if key == "" or used[key] then
    rule.key = MakeUniqueRuleKey("custom")
  end
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

local function GetPlayerLevelSafe()
  if not UnitLevel then return nil end
  local ok, v = pcall(UnitLevel, "player")
  if not ok then return nil end
  v = tonumber(v)
  if not v or v <= 0 then return nil end
  return v
end

local function CompareNumber(op, left, right)
  op = tostring(op or "")
  if op == "==" then op = "=" end
  if op == "~=" then op = "!=" end

  left = tonumber(left)
  right = tonumber(right)
  if left == nil or right == nil then return false end

  if op == "<" then return left < right end
  if op == "<=" then return left <= right end
  if op == "=" then return left == right end
  if op == ">=" then return left >= right end
  if op == ">" then return left > right end
  if op == "!=" then return left ~= right end
  return false
end

local function IsPlayerLevelGateMet(rule, ctx)
  if type(rule) ~= "table" then return true end
  local op = rule.playerLevelOp
  local want = tonumber(rule.playerLevel)
  if not op or not want or want <= 0 then return true end
  local have = (type(ctx) == "table" and tonumber(ctx.playerLevel)) or GetPlayerLevelSafe()
  if not have then return true end
  return CompareNumber(op, have, want)
end

local function IsAtMaxLevel()
  if not UnitLevel then return false end
  local maxLevel = GetMaxPlayerLevelSafe()
  if not maxLevel then return false end
  return (tonumber(UnitLevel("player")) or 0) >= maxLevel
end

local function BuildEvalContext()
  return {
    class = GetPlayerClass and GetPlayerClass() or nil,
    isInGroup = IsInGroupSafe and (IsInGroupSafe() and true or false) or false,
    mapID = GetBestMapIDSafe and GetBestMapIDSafe() or nil,
    faction = GetPlayerFaction and GetPlayerFaction() or nil,
    playerLevel = GetPlayerLevelSafe(),
    isAtMaxLevel = IsAtMaxLevel() and true or false,
  }
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

ns.GetQuestTitle = GetQuestTitle

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
    if lbl.SetFontObject and GameFontHighlightSmall then
      lbl:SetFontObject(GameFontHighlightSmall)
    end
    if lbl.SetJustifyH then lbl:SetJustifyH("CENTER") end
    if lbl.SetJustifyV then lbl:SetJustifyV("MIDDLE") end
    row.labels[i] = lbl
  end
  return tex, lbl
end

local function ApplyOverlayFont(label, baseFS)
  if not label then return end

  -- Ensure *some* font is set even if baseFS isn't ready.
  if label.SetFontObject then
    local obj
    if baseFS and baseFS.GetFontObject then
      obj = baseFS:GetFontObject()
    end
    if obj then
      label:SetFontObject(obj)
    elseif GameFontHighlightSmall then
      label:SetFontObject(GameFontHighlightSmall)
    end
  end

  if not (baseFS and baseFS.GetFont and label.SetFont) then return end
  local font, size, flags = baseFS:GetFont()
  if not font or font == "" then return end

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
      lbl:SetPoint("TOPLEFT", tex, "TOPLEFT", 0, 0)
      lbl:SetPoint("BOTTOMRIGHT", tex, "BOTTOMRIGHT", 0, 0)
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

local function BuildRuleStatus(rule, ctx)
  local questID = tonumber(rule and rule.questID)

  if type(ctx) ~= "table" then ctx = nil end

  -- Generic conditional rules (used for profession/flow helpers)
  if not editMode and type(rule) == "table" and type(rule.showIf) == "table" then
    local s = rule.showIf

    if s.class ~= nil then
      local want = s.class
      local have = (ctx and ctx.class) or GetPlayerClass()
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
    if hideWhenCompleted and not editMode then
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
      if hideWhenCompleted and not editMode then
        return nil
      end
    end
  end

  local disabled = IsRuleDisabled(rule)
  if disabled then
    return nil
  end

  -- Prereqs gate
  if not editMode and not ArePrereqsMet(rule.prereq) then
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

  -- Hide if any quest is completed (useful when quests drop from log on completion)
  if not editMode and type(rule) == "table" and type(rule.hideIfAnyQuestCompleted) == "table" then
    for _, q in ipairs(rule.hideIfAnyQuestCompleted) do
      local qid = tonumber(q)
      if qid and qid > 0 and IsQuestCompleted(qid) then
        return nil
      end
    end
  end

  -- Class gate (optional)
  if not editMode and type(rule) == "table" and rule.class ~= nil then
    local want = tostring(rule.class):upper()
    if want ~= "" and want ~= "NONE" then
      local have = tostring((ctx and ctx.class) or GetPlayerClass() or ""):upper()
      if have == "" or have ~= want then
        return nil
      end
    end
  end

  -- Not-in-group gate (optional)
  if not editMode and type(rule) == "table" and rule.notInGroup == true then
    if (ctx and ctx.isInGroup) or IsInGroupSafe() then
      return nil
    end
  end

  -- Location gate (optional; uiMapID)
  if not editMode and type(rule) == "table" and rule.locationID ~= nil then
    local want = tonumber((tostring(rule.locationID):gsub("[^0-9]", "")))
    if want and want > 0 then
      local have = (ctx and ctx.mapID) or GetBestMapIDSafe()
      if have and have ~= want then
        return nil
      end
    end
  end

  -- Spell gates (optional)
  if not editMode and type(rule) == "table" then
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
  if not editMode and type(rule) == "table" and rule.restedOnly == true then
    if not IsRestingSafe() then
      return nil
    end
  end

  -- Reputation gate (optional)
  if not editMode and type(rule) == "table" and type(rule.rep) == "table" and rule.rep.factionID then
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
  if not editMode and type(rule) == "table" and rule.faction ~= nil then
    local want = tostring(rule.faction)
    if want == "Alliance" or want == "Horde" then
      local have = (ctx and ctx.faction) or GetPlayerFaction()
      if have and tostring(have) ~= want then
        return nil
      end
    end
  end

  -- Level gate (useful for Timewalking "max" vs "leveling" variants)
  if not editMode and type(rule) == "table" and rule.levelGate ~= nil then
    local g = tostring(rule.levelGate):lower()
    local atMax = (ctx and ctx.isAtMaxLevel ~= nil) and (ctx.isAtMaxLevel and true or false) or IsAtMaxLevel()
    if g == "max" and not atMax then
      return nil
    end
    if (g == "level" or g == "leveling") and atMax then
      return nil
    end
  end

  -- Player level gate (optional; applies to any rule type)
  if not editMode and not IsPlayerLevelGateMet(rule, ctx) then
    return nil
  end

  -- Only show while quest is active/in log (useful for weekly/time-limited quests)
  -- Exception: if the quest is already completed and the rule is configured to
  -- keep showing when completed, allow it to remain visible even if it drops
  -- out of the quest log (Timewalking weeklies commonly do this).
  if not editMode and questID and rule.requireInLog == true and not IsQuestInLog(questID) then
    if not (completed and hideWhenCompleted == false) then
      return nil
    end
  end

  -- Aura gate
  if not editMode and type(rule.aura) == "table" then
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
    if not editMode then
      if rule.item.hideWhenAcquired == true and count > 0 then
        return nil
      end
      if rule.item.mustHave and count <= 0 then
        return nil
      end
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

  local function FirstNonEmptyLine(s)
    if s == nil then return nil end
    s = tostring(s or "")
    s = s:gsub("\r", "\n")
    for line in s:gmatch("[^\n]+") do
      line = tostring(line or ""):gsub("^%s+", ""):gsub("%s+$", "")
      if line ~= "" then
        return line
      end
    end
    return nil
  end

  local title
  local rawTitle
  if questID then
    local function NormalizeQuestInfoToMultiline(s)
      if s == nil then return nil end
      s = tostring(s or "")
      s = s:gsub("\r", "\n")
      local parts = {}
      for line in s:gmatch("[^\n]+") do
        line = tostring(line or ""):gsub("%s+$", "")
        if line:gsub("%s+", "") ~= "" then
          parts[#parts + 1] = line
        end
      end
      if parts[1] == nil then return nil end
      return table.concat(parts, "\n")
    end

    local NBSP = "\194\160"
    local function PreserveLeadingWhitespaceForDisplay(s)
      if s == nil then return nil end
      s = tostring(s or "")
      local function Conv(ws)
        ws = tostring(ws or "")
        ws = ws:gsub(" ", NBSP)
        ws = ws:gsub("\t", NBSP .. NBSP .. NBSP .. NBSP)
        return ws
      end
      s = s:gsub("^([ \t]+)", Conv)
      s = s:gsub("\n([ \t]+)", function(ws) return "\n" .. Conv(ws) end)
      return s
    end

    local questTitle = nil
    if type(rule) == "table" and rule.label then
      questTitle = tostring(rule.label)
    end
    if not questTitle or questTitle == "" then
      questTitle = GetQuestTitle(questID) or ("Quest " .. questID)
    end

    rawTitle = questTitle

    local qi = (type(rule) == "table") and (rule.questInfo or nil) or nil
    local fullInfo = NormalizeQuestInfoToMultiline(qi)
    if fullInfo and fullInfo ~= "" then
      title = PreserveLeadingWhitespaceForDisplay(fullInfo)
    else
      title = questTitle
    end
  elseif rule and rule.label then
    title = rule.label
    rawTitle = rule.label
  elseif type(rule) == "table" and type(rule.item) == "table" and rule.item.itemID then
    title = GetItemNameSafe(rule.item.itemID) or ("Item " .. tostring(rule.item.itemID))
    rawTitle = title
  elseif type(rule) == "table" and (rule.spellKnown or rule.notSpellKnown) then
    local function PickSpellID(v)
      if type(v) == "table" then
        for _, x in ipairs(v) do
          local n = tonumber(x)
          if n and n > 0 then return n end
        end
        return nil
      end
      local n = tonumber(v)
      return (n and n > 0) and n or nil
    end

    local spellID = PickSpellID(rule.spellKnown) or PickSpellID(rule.notSpellKnown)
    local name = nil
    if spellID then
      local CS = _G and rawget(_G, "C_Spell")
      if CS and CS.GetSpellName then
        local ok, n = pcall(CS.GetSpellName, spellID)
        if ok and type(n) == "string" and n ~= "" then name = n end
      end
      local GSI = _G and rawget(_G, "GetSpellInfo")
      if not name and GSI then
        local ok, n = pcall(GSI, spellID)
        if ok and type(n) == "string" and n ~= "" then name = n end
      end
    end
    title = name or (spellID and ("Spell " .. tostring(spellID)) or "Spell")
    rawTitle = title
  else
    title = "Task"
    rawTitle = title
  end

  if completed and type(rule) == "table" and rule.labelComplete then
    title = tostring(rule.labelComplete)
    rawTitle = title
  end

  -- Tag Timewalking quests when name is derived from ID.
  if questID and not (type(rule) == "table" and (rule.questInfo ~= nil or rule.label ~= nil)) then
    local hay = tostring(rawTitle or ""):lower()
    local aura = (type(rule) == "table") and rule.aura or nil
    if (type(aura) == "table" and aura.eventKind == "timewalking") or hay:find("timewalking", 1, true) or hay:find("turbulent timeways", 1, true) then
      rawTitle = tostring(rawTitle) .. " [TW]"
    end
  end

  local function RuleTypeLabel(r, qid)
    if type(r) == "table" and type(r.item) == "table" and r.item.itemID then
      return "I"
    end
    if qid and qid > 0 then
      return "Q"
    end
    if type(r) == "table" and (r.spellKnown or r.notSpellKnown or r.locationID or r.class or r.notInGroup) then
      return "S"
    end
    return "T"
  end

  local srcColor = "|cff00ccff"
  if type(rule) == "table" and type(rule.key) == "string" then
    local k = rule.key
    if k:find("^custom:") then
      srcColor = "|cffffffff"
    end
  end

  local editText = string.format("%s: %s%s|r", RuleTypeLabel(rule, questID), srcColor, tostring(rawTitle or title or ""))
  if completed then
    editText = editText .. " (Done)"
  end

  -- Extra context for editors (keeps the on-screen tracker clean).
  if editMode and type(rule) == "table" then
    if rule.faction == "Alliance" then
      editText = editText .. " [A]"
    elseif rule.faction == "Horde" then
      editText = editText .. " [H]"
    end

    if rule.playerLevelOp and rule.playerLevel then
      local op = tostring(rule.playerLevelOp)
      local lvl = tonumber(rule.playerLevel)
      if lvl and lvl > 0 and op ~= "" then
        editText = editText .. string.format(" [Lvl %s %d]", op, lvl)
      end
    end
  end

  local indicators = BuildIndicators(rule)

  if type(rule) == "table" and rule.color ~= nil then
    title = ColorText(rule.color, title)
  end

  return {
    questID = questID,
    title = title,
    editText = editText,
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
local optionsFrame
local RefreshRulesList
local RefreshFramesList
local RefreshActiveTab

local UpdateAnchorLabel
local FindCustomRuleIndex
local UnassignRuleFromFrame

local function GetFramePosStore()
  NormalizeSV()
  fr0z3nUI_QuestTracker_Char.settings.framePos = fr0z3nUI_QuestTracker_Char.settings.framePos or {}
  return fr0z3nUI_QuestTracker_Char.settings.framePos
end

local function SaveFramePosition(f)
  if not (f and f._id and f.GetPoint) then return end

  local function DetermineListGrowSetting(frameDef)
    local g = GetUISetting("listGrow", nil)
    if g == nil and type(frameDef) == "table" then
      g = frameDef.listGrow or frameDef.growY
    end
    g = tostring(g or "auto"):lower()
    if g ~= "auto" and g ~= "up" and g ~= "down" then g = "auto" end
    return g
  end

  local function PickPointAndOffsets(frameDef)
    local ref = (f.GetParent and f:GetParent()) or UIParent
    if not ref then return nil end
    if not (ref.GetLeft and ref.GetRight and ref.GetTop and ref.GetBottom) then
      return nil
    end

    local cx, cy = nil, nil
    if f.GetCenter then
      cx, cy = f:GetCenter()
    end
    local refW = ref.GetWidth and ref:GetWidth() or nil
    local refH = ref.GetHeight and ref:GetHeight() or nil
    if not (cx and cy and refW and refH and refW > 0 and refH > 0) then
      return nil
    end

    local refLeft = ref:GetLeft()
    local refBottom = ref:GetBottom()
    if not (refLeft and refBottom) then
      return nil
    end

    local xFrac = (cx - refLeft) / refW
    local yFrac = (cy - refBottom) / refH

    local horiz = ""
    if xFrac < 0.33 then horiz = "LEFT"
    elseif xFrac > 0.66 then horiz = "RIGHT" end

    local vert = ""
    if yFrac < 0.33 then vert = "BOTTOM"
    elseif yFrac > 0.66 then vert = "TOP" end

    -- Optional grow override for list frames.
    if type(frameDef) == "table" and tostring(frameDef.type or "list"):lower() == "list" then
      local lg = DetermineListGrowSetting(frameDef)
      if lg == "up" then
        vert = "BOTTOM"
      elseif lg == "down" then
        vert = "TOP"
      end
    end

    local point
    if vert == "" and horiz == "" then
      point = "CENTER"
    elseif vert == "" then
      point = horiz
    elseif horiz == "" then
      point = vert
    else
      point = vert .. horiz
    end

    local refLeft = refLeft
    local refRight = ref:GetRight()
    local refTop = ref:GetTop()
    local refBottom = refBottom
    local refCenterX, refCenterY = ref:GetCenter()

    local left = f.GetLeft and f:GetLeft() or nil
    local right = f.GetRight and f:GetRight() or nil
    local top = f.GetTop and f:GetTop() or nil
    local bottom = f.GetBottom and f:GetBottom() or nil

    local x, y
    if point == "TOPLEFT" then
      if not (left and top and refLeft and refTop) then return nil end
      x, y = left - refLeft, top - refTop
    elseif point == "TOP" then
      if not (cx and top and refCenterX and refTop) then return nil end
      x, y = cx - refCenterX, top - refTop
    elseif point == "TOPRIGHT" then
      if not (right and top and refRight and refTop) then return nil end
      x, y = right - refRight, top - refTop
    elseif point == "LEFT" then
      if not (left and cy and refLeft and refCenterY) then return nil end
      x, y = left - refLeft, cy - refCenterY
    elseif point == "CENTER" then
      if not (cx and cy and refCenterX and refCenterY) then return nil end
      x, y = cx - refCenterX, cy - refCenterY
    elseif point == "RIGHT" then
      if not (right and cy and refRight and refCenterY) then return nil end
      x, y = right - refRight, cy - refCenterY
    elseif point == "BOTTOMLEFT" then
      if not (left and bottom and refLeft and refBottom) then return nil end
      x, y = left - refLeft, bottom - refBottom
    elseif point == "BOTTOM" then
      if not (cx and bottom and refCenterX and refBottom) then return nil end
      x, y = cx - refCenterX, bottom - refBottom
    elseif point == "BOTTOMRIGHT" then
      if not (right and bottom and refRight and refBottom) then return nil end
      x, y = right - refRight, bottom - refBottom
    else
      return nil
    end

    return point, point, x, y
  end

  local def = f._lastFrameDef
  local point, relPoint, x, y = PickPointAndOffsets(def)
  if not point then
    point, _, relPoint, x, y = f:GetPoint(1)
    if not point then return end
  end

  local store = GetFramePosStore()
  local ref = (f.GetParent and f:GetParent()) or UIParent
  local refName = (ref == UIParent) and "UIParent" or ((ref and ref.GetName and ref:GetName()) or "UIParent")
  store[tostring(f._id)] = {
    point = tostring(point),
    relPoint = tostring(relPoint or point),
    x = tonumber(x) or 0,
    y = tonumber(y) or 0,
    parent = tostring(refName),
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

  local ref = UIParent
  if type(pos.parent) == "string" and pos.parent ~= "" then
    if pos.parent ~= "UIParent" then
      local p = _G and _G[pos.parent]
      if p then ref = p end
    end
  else
    ref = (f.GetParent and f:GetParent()) or UIParent
  end

  f:ClearAllPoints()
  f:SetPoint(point, ref or UIParent, relPoint, tonumber(pos.x) or 0, tonumber(pos.y) or 0)
  return true
end

local function ApplyFAOBackdrop(f, bgAlpha, bgColor)
  f:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    tile = true,
    tileSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })

  local a = tonumber(bgAlpha)
  if a == nil then a = 0 end
  if a < 0 then a = 0 end
  if a > 1 then a = 1 end

  local r, g, b = 0, 0, 0
  if type(bgColor) == "table" then
    r = tonumber(bgColor[1]) or r
    g = tonumber(bgColor[2]) or g
    b = tonumber(bgColor[3]) or b
  end
  if r < 0 then r = 0 end
  if r > 1 then r = 1 end
  if g < 0 then g = 0 end
  if g > 1 then g = 1 end
  if b < 0 then b = 0 end
  if b > 1 then b = 1 end

  f:SetBackdropColor(r, g, b, a)
end

ns.ApplyFAOBackdrop = ApplyFAOBackdrop

local function EnsureAnchorLabel(frame)
  if not frame then return nil end
  if frame._anchorLabel then return frame._anchorLabel end
  if not frame.CreateFontString then return nil end

  local fs = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  if fs.SetJustifyH then fs:SetJustifyH("LEFT") end
  if fs.SetJustifyV then fs:SetJustifyV("MIDDLE") end
  fs:SetText("|cff00ccff[FQT]|r")
  fs:Hide()

  frame._anchorLabel = fs

  local btn = CreateFrame("Button", nil, frame)
  btn:EnableMouse(true)
  btn:SetSize(80, 14)
  btn:RegisterForDrag("LeftButton")
  btn:SetScript("OnDragStart", function(self)
    if not editMode then return end
    local p = self:GetParent()
    if p and p.StartMoving then p:StartMoving() end
  end)
  btn:SetScript("OnDragStop", function(self)
    local p = self:GetParent()
    if p and p.StopMovingOrSizing then p:StopMovingOrSizing() end
    if p then
      SaveFramePosition(p)
      UpdateAnchorLabel(p)
    end
  end)
  btn:Hide()
  frame._anchorBtn = btn

  return fs
end

UpdateAnchorLabel = function(frame, frameDef)
  local fs = EnsureAnchorLabel(frame)
  if not fs then return end

  local btn = frame and frame._anchorBtn

  if not editMode then
    fs:Hide()
    if btn then btn:Hide() end
    return
  end

  local id = (type(frameDef) == "table" and frameDef.id) or frame._id
  local text = "|cff00ccff[FQT]|r"
  if id ~= nil and tostring(id) ~= "" then
    text = text .. " " .. tostring(id)
  end
  fs:SetText(text)

  fs:ClearAllPoints()
  -- Static anchor label position (doesn't depend on screen location).
  fs:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -6)

  fs:Show()

  if btn then
    btn:ClearAllPoints()
    btn:SetAllPoints(fs)
    btn:SetFrameLevel((frame.GetFrameLevel and frame:GetFrameLevel() or 1) + 20)
    btn:Show()
  end
end

local _dragState = nil

local function FindOwningTrackerFrame(widget)
  local w = widget
  while w do
    local id = w._id
    if id ~= nil and framesByID and framesByID[tostring(id)] == w then
      return w
    end
    if w.GetParent then
      w = w:GetParent()
    else
      w = nil
    end
  end
  return nil
end

local function AssignRuleToFrame(rule, frameID)
  if type(rule) ~= "table" then return false end
  frameID = tostring(frameID or "")
  if frameID == "" then return false end

  if type(rule.targets) == "table" then
    for _, v in ipairs(rule.targets) do
      if tostring(v or "") == frameID then
        return true
      end
    end
    rule.targets[#rule.targets + 1] = frameID
    return true
  end

  rule.frameID = frameID
  return true
end

local function ReorderCustomRulesInFrame(frame, movedRule, destAbsIndex)
  if type(movedRule) ~= "table" then return false end
  if not frame or type(frame._lastEntries) ~= "table" then return false end

  if not FindCustomRuleIndex(movedRule) then
    Print("That rule isn't custom; can't reorder it.")
    return false
  end

  local entries = frame._lastEntries

  local function IsCustomRule(r)
    return FindCustomRuleIndex(r) ~= nil
  end

  local customRules = {}
  for _, st in ipairs(entries) do
    local r = st and st.rule
    if IsCustomRule(r) then
      customRules[#customRules + 1] = r
    end
  end

  local fromPos = nil
  for i = 1, #customRules do
    if customRules[i] == movedRule then
      fromPos = i
      break
    end
  end
  if not fromPos then return false end

  destAbsIndex = tonumber(destAbsIndex) or 1
  if destAbsIndex < 1 then destAbsIndex = 1 end
  if destAbsIndex > #entries then destAbsIndex = #entries end

  local seen = 0
  local destPos = 1
  for i = 1, destAbsIndex do
    local r = entries[i] and entries[i].rule
    if IsCustomRule(r) then
      seen = seen + 1
      destPos = seen
    end
  end
  if seen == 0 then
    destPos = 1
  elseif destAbsIndex >= #entries then
    destPos = #customRules
  end
  if destPos < 1 then destPos = 1 end
  if destPos > #customRules then destPos = #customRules end

  if fromPos == destPos then return true end

  table.remove(customRules, fromPos)
  table.insert(customRules, destPos, movedRule)

  for i = 1, #customRules do
    customRules[i].order = i
  end

  return true
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
  -- Frame moving is handled via the anchor label button in edit mode.
  local bgAlpha = (type(def) == "table") and def.bgAlpha or nil
  local bgColor = (type(def) == "table") and def.bgColor or nil
  ApplyFAOBackdrop(f, bgAlpha, bgColor)

  f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f.title:SetPoint("TOPLEFT", 8, -6)
  f.title:SetJustifyH("LEFT")
  f.title:SetText("")
  f.title:Hide()

  -- Per-frame scroll controls (edit-mode only). Shift+MouseWheel already works; these are explicit buttons.
  f._scrollUp = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  f._scrollUp:SetSize(20, 18)
  f._scrollUp:SetText("Up")
  f._scrollUp:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
  f._scrollUp:Hide()
  f._scrollUp:SetScript("OnClick", function()
    if not editMode then return end
    local id = tostring(f._id or "")
    if id == "" then return end
    local offset = GetFrameScrollOffset(id)
    offset = offset - 1
    if offset < 0 then offset = 0 end
    SetFrameScrollOffset(id, offset)
    RefreshAll()
  end)

  f._scrollDown = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  f._scrollDown:SetSize(20, 18)
  f._scrollDown:SetText("Dn")
  f._scrollDown:SetPoint("TOPRIGHT", f._scrollUp, "BOTTOMRIGHT", 0, -2)
  f._scrollDown:Hide()
  f._scrollDown:SetScript("OnClick", function()
    if not editMode then return end
    local id = tostring(f._id or "")
    if id == "" then return end
    local offset = GetFrameScrollOffset(id)
    offset = offset + 1
    if offset < 0 then offset = 0 end
    SetFrameScrollOffset(id, offset)
    RefreshAll()
  end)

  return f
end

local function HideExtraFrameRows(frame, fromIndex)
  if not frame then return end
  fromIndex = tonumber(fromIndex) or 1
  if fromIndex < 1 then fromIndex = 1 end

  if type(frame.items) == "table" then
    for i = fromIndex, #frame.items do
      local fs = frame.items[i]
      if fs then
        if fs.SetText then fs:SetText("") end
        if fs.Hide then fs:Hide() end
      end
    end
  end

  if type(frame.buttons) == "table" then
    for i = fromIndex, #frame.buttons do
      local b = frame.buttons[i]
      if b then
        b._entry = nil
        b._entryAbsIndex = nil
        if b.Hide then b:Hide() end
      end
    end
  end

  if type(frame._removeButtons) == "table" then
    for i = fromIndex, #frame._removeButtons do
      local b = frame._removeButtons[i]
      if b and b.Hide then b:Hide() end
    end
  end

  if type(frame._indicatorRows) == "table" then
    for i = fromIndex, #frame._indicatorRows do
      local row = frame._indicatorRows[i]
      if row and row.container and row.container.Hide then
        row.container:Hide()
      end
    end
  end
end

local function CreateBarFrame(def)
  local f = CreateContainerFrame(def)
  f._id = def and def.id or nil
  f:SetSize(def.width or 300, def.height or 20)
  local ref = (f.GetParent and f:GetParent()) or UIParent
  f:SetPoint(def.point or "TOP", ref or UIParent, def.relPoint or def.point or "TOP", def.x or 0, def.y or 0)
  ApplySavedFramePosition(f, def)

  f._itemFont = "GameFontHighlightSmall"
  f.items = {}

  f:EnableMouseWheel(true)
  f:SetScript("OnMouseWheel", function(self, delta)
    if not (IsShiftKeyDown and IsShiftKeyDown()) then return end
    local id = tostring(self._id or "")
    if id == "" then return end
    local offset = GetFrameScrollOffset(id)
    offset = offset + ((delta and delta < 0) and 1 or -1)
    if offset < 0 then offset = 0 end
    SetFrameScrollOffset(id, offset)
    RefreshAll()
  end)

  f.prefix = f:CreateFontString(nil, "OVERLAY", f._itemFont)
  f.prefix:SetJustifyH("LEFT")
  f.prefix:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -2)
  f.prefix:SetText("")
  f.prefix:Hide()

  return f
end

local function CreateListFrame(def)
  local f = CreateContainerFrame(def)
  f._id = def and def.id or nil
  local rh = (def and def.rowHeight) or 16
  local mi = (def and def.maxItems) or 20
  local h = (rh or 16) * ((mi or 20) + 2)
  if type(def) == "table" and tonumber(def.maxHeight) and tonumber(def.maxHeight) > 0 then
    h = math.min(h, tonumber(def.maxHeight))
  end
  f:SetSize(def.width or 300, h)
  local ref = (f.GetParent and f:GetParent()) or UIParent
  f:SetPoint(def.point or "TOPRIGHT", ref or UIParent, def.relPoint or def.point or "TOPRIGHT", def.x or -10, def.y or -120)
  ApplySavedFramePosition(f, def)

  f._itemFont = "GameFontHighlight"
  f.items = {}
  f.buttons = {}

  f:EnableMouseWheel(true)
  f:SetScript("OnMouseWheel", function(self, delta)
    if not (IsShiftKeyDown and IsShiftKeyDown()) then return end
    local id = tostring(self._id or "")
    if id == "" then return end
    local offset = GetFrameScrollOffset(id)
    offset = offset + ((delta and delta < 0) and 1 or -1)
    if offset < 0 then offset = 0 end
    SetFrameScrollOffset(id, offset)
    RefreshAll()
  end)

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
  b:RegisterForDrag("LeftButton")
  b:SetScript("OnDragStart", function(self)
    if not editMode then return end
    local e = self._entry
    if not (e and e.rule) then return end
    _dragState = {
      srcFrame = frame,
      srcFrameID = frame and frame._id,
      rule = e.rule,
      srcAbsIndex = tonumber(self._entryAbsIndex) or nil,
    }
    if self.SetAlpha then self:SetAlpha(0.6) end
  end)
  b:SetScript("OnDragStop", function(self)
    if self.SetAlpha then self:SetAlpha(1) end
    if not (editMode and _dragState and _dragState.rule) then
      _dragState = nil
      return
    end

    local movedRule = _dragState.rule
    local srcFrame = _dragState.srcFrame

    _dragState = nil

    local GMF = _G and rawget(_G, "GetMouseFocus")
    local focus = (type(GMF) == "function") and GMF() or nil
    local targetFrame = FindOwningTrackerFrame(focus)
    if not (srcFrame and targetFrame and srcFrame._id and targetFrame._id) then return end

    local srcID = tostring(srcFrame._id)
    local targetID = tostring(targetFrame._id)

    -- Destination index in target frame, based on cursor position.
    local def = targetFrame._lastFrameDef or {}
    local rowH = tonumber(def.rowHeight) or 16
    local padTop = 8
    local offset = GetFrameScrollOffset(targetFrame._id)

    local destAbsIndex = 1
    if GetCursorPosition and targetFrame.GetScale and targetFrame.GetTop then
      local _, y = GetCursorPosition()
      local s = targetFrame:GetScale() or 1
      if s == 0 then s = 1 end
      local cursorY = y / s
      local top = targetFrame:GetTop()
      if top then
        local rel = (top - cursorY) - padTop
        local row = math.floor(rel / rowH) + 1
        if row < 1 then row = 1 end
        destAbsIndex = offset + row
      end
    end

    if targetFrame ~= srcFrame then
      if not FindCustomRuleIndex(movedRule) then
        Print("That rule isn't custom; can't move it.")
        return
      end
      UnassignRuleFromFrame(movedRule, srcID)
      AssignRuleToFrame(movedRule, targetID)
    end

    ReorderCustomRulesInFrame(targetFrame, movedRule, destAbsIndex)
    RefreshAll()
    if optionsFrame then RefreshActiveTab() end
  end)
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

local function EnsureRemoveButton(frame, idx)
  frame._removeButtons = frame._removeButtons or {}
  if frame._removeButtons[idx] then return frame._removeButtons[idx] end
  local b = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  b:SetSize(18, 18)
  b:SetFrameLevel((frame.GetFrameLevel and frame:GetFrameLevel() or 1) + 30)
  b:Hide()
  frame._removeButtons[idx] = b
  return b
end

FindCustomRuleIndex = function(rule)
  if type(rule) ~= "table" then return nil end
  local custom = GetCustomRules()
  for i = 1, #custom do
    if custom[i] == rule then return i end
  end
  return nil
end

-- WeakAuras tooling moved to fr0z3nUI_QuestTracker_WeakAuras.lua
UnassignRuleFromFrame = function(rule, frameID)
  if type(rule) ~= "table" then return false end
  local idx = FindCustomRuleIndex(rule)
  if not idx then return false end
  frameID = tostring(frameID or "")
  if frameID == "" then return false end

  if type(rule.targets) == "table" then
    for i = #rule.targets, 1, -1 do
      if tostring(rule.targets[i] or "") == frameID then
        table.remove(rule.targets, i)
      end
    end
    if #rule.targets == 0 then rule.targets = nil end
  end

  if tostring(rule.frameID or "") == frameID then
    rule.frameID = nil
  end

  return true
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

  local offset = GetFrameScrollOffset(frame and frame._id)
  local maxOffset = 0
  if type(entries) == "table" then
    maxOffset = math.max(0, (#entries) - maxItems)
  end
  if offset > maxOffset then
    offset = maxOffset
    SetFrameScrollOffset(frame and frame._id, offset)
  end

  -- Edit-mode scroll buttons live on the frame (requested).
  if frame and frame._scrollUp and frame._scrollDown then
    local show = editMode and maxOffset > 0
    frame._scrollUp:SetShown(show)
    frame._scrollDown:SetShown(show)
    if show then
      frame._scrollUp:SetEnabled(offset > 0)
      frame._scrollDown:SetEnabled(offset < maxOffset)
    end
  end

  if frame.prefix then
    frame.prefix:SetText("")
    frame.prefix:Hide()
  end

  -- Pre-fill texts so GetStringWidth() is accurate.
  local tempTextByIndex = {}
  local tempIndicatorsByIndex = {}
  local tempIndicatorsWByIndex = {}
  for i = 1, maxItems do
    local e = entries[i + offset]
    if e then
      local text = (editMode and e.editText) or e.title
      if (not editMode) and e.extra then text = text .. "  " .. e.extra .. " " end
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

        local btn = EnsureRowButton(frame, i)
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", fs, "TOPLEFT", -2 - indW, 2)
        btn:SetPoint("BOTTOMRIGHT", fs, "BOTTOMRIGHT", 2, -2)
        btn._entry = entries[i + offset]
        btn:EnableMouse(editMode and true or false)
        if editMode then btn:Show() else btn:Hide() end

        local rm = EnsureRemoveButton(frame, i)
        rm:ClearAllPoints()
        rm:SetPoint("TOPRIGHT", fs, "TOPRIGHT", 2, 2)
        rm:SetScript("OnClick", function()
          local e = entries[i + offset]
          if not (e and e.rule) then return end
          local ok = UnassignRuleFromFrame(e.rule, frame and frame._id)
          if not ok then
            Print("That rule isn't custom; use disable toggle instead.")
            ToggleRuleDisabled(e.rule)
          end
          RefreshAll()
          if optionsFrame then RefreshActiveTab() end
        end)
        rm:SetShown(editMode and true or false)

        cursorR = cursorR + (fs:GetStringWidth() or 0) + indW + spacingItem
      else
        fs:SetText("")
        fs:Hide()
        RenderIndicators(frame, i, fs, nil)

        local btn = EnsureRowButton(frame, i)
        btn._entry = nil
        btn:Hide()

        local rm = EnsureRemoveButton(frame, i)
        rm:Hide()
      end
    end

    -- If this bar was previously rendered as a list, hide leftover rows.
    HideExtraFrameRows(frame, maxItems + 1)
    return
  end

  -- grow == "right" or "center": left-to-right placement
  if frame.prefix and prefixW > 0 then
    frame.prefix:ClearAllPoints()
    frame.prefix:SetPoint("TOPLEFT", frame, "TOPLEFT", cursor, y)
    cursor = cursor + prefixW + spacingPrefix
  end

  for i = 1, maxItems do
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

      local btn = EnsureRowButton(frame, i)
      btn:ClearAllPoints()
      btn:SetPoint("TOPLEFT", fs, "TOPLEFT", -2, 2)
      btn:SetPoint("BOTTOMRIGHT", fs, "BOTTOMRIGHT", 2 + indW, -2)
      btn._entry = entries[i + offset]
      btn:EnableMouse(editMode and true or false)
      if editMode then btn:Show() else btn:Hide() end

      local rm = EnsureRemoveButton(frame, i)
      rm:ClearAllPoints()
      rm:SetPoint("TOPRIGHT", fs, "TOPRIGHT", 2, 2)
      rm:SetScript("OnClick", function()
        local e = entries[i + offset]
        if not (e and e.rule) then return end
        local ok = UnassignRuleFromFrame(e.rule, frame and frame._id)
        if not ok then
          Print("That rule isn't custom; use disable toggle instead.")
          ToggleRuleDisabled(e.rule)
        end
        RefreshAll()
        if optionsFrame then RefreshActiveTab() end
      end)
      rm:SetShown(editMode and true or false)

      cursor = cursor + (fs:GetStringWidth() or 0) + indW + spacingItem
    else
      fs:SetText("")
      fs:Hide()
      RenderIndicators(frame, i, fs, nil)

      local btn = EnsureRowButton(frame, i)
      btn._entry = nil
      btn:Hide()

      local rm = EnsureRemoveButton(frame, i)
      rm:Hide()
    end
  end

  -- If this bar was previously rendered as a list, hide leftover rows.
  HideExtraFrameRows(frame, maxItems + 1)

  if frameDef and frameDef.autoSize then
    frame:SetHeight(tonumber(frameDef.height) or 20)
  end
end

-- Simple config GUI
RefreshRulesList = function(...) end
RefreshFramesList = function(...) end
RefreshActiveTab = function(...) end

-- Stable wrappers for split modules (these globals are assigned later)
ns.RefreshRulesList = function(...)
  return RefreshRulesList()
end
ns.RefreshAll = function(...)
  return RefreshAll()
end
ns.CreateAllFrames = function(...)
  return CreateAllFrames()
end

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

  -- Allow closing with Escape.
  do
    local special = _G and _G["UISpecialFrames"]
    if type(special) == "table" then
      local name = "FR0Z3NUIFQTOptions"
      local exists = false
      for i = 1, #special do
        if special[i] == name then exists = true break end
      end
      if not exists and table and table.insert then table.insert(special, name) end
    end
  end

  f:SetSize(560, 420)
  f:SetPoint("CENTER")
  f:SetFrameStrata("DIALOG")
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:EnableMouse(true)
  RestoreWindowPosition("options", f, "CENTER", "CENTER", 0, 0)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", function(self)
    if self.StopMovingOrSizing then self:StopMovingOrSizing() end
    SaveWindowPosition("options", self)
  end)
  ApplyFAOBackdrop(f, 0.85)

  f:HookScript("OnShow", function(self)
    RestoreWindowPosition("options", self, "CENTER", "CENTER", 0, 0)
  end)

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

  local tabOrder = { "frames", "rules", "items", "quest", "spells", "text" }
  local tabText = {
    frames = "Frames",
    rules = "Rules",
    items = "Items",
    quest = "Quest",
    spells = "Spell",
    text = "Text",
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

  -- Shared quick color palette (used for both backgrounds and text colors)
  local QUICK_COLOR_PALETTE = {
    { 0.00, 0.00, 0.00 }, -- black
    { 0.20, 0.20, 0.20 }, -- dark gray
    { 0.75, 0.75, 0.75 }, -- light gray
    { 1.00, 1.00, 1.00 }, -- white
    { 1.00, 0.25, 0.25 }, -- red
    { 1.00, 0.55, 0.10 }, -- orange
    { 1.00, 0.90, 0.20 }, -- yellow
    { 0.20, 1.00, 0.20 }, -- green
    { 0.20, 0.60, 1.00 }, -- blue
  }

  local function Clamp01(v)
    v = tonumber(v)
    if not v then return 0 end
    if v < 0 then return 0 end
    if v > 1 then return 1 end
    return v
  end

  local function NormalizeRGB(r, g, b)
    return Clamp01(r), Clamp01(g), Clamp01(b)
  end

  local function ShowTextColorPicker(initialR, initialG, initialB, onChanged)
    local CPF = _G and rawget(_G, "ColorPickerFrame")
    if not CPF then
      local CAO = _G and rawget(_G, "C_AddOns")
      if CAO and CAO.LoadAddOn then pcall(CAO.LoadAddOn, "Blizzard_ColorPicker") end
      local LoadAddOn = _G and rawget(_G, "LoadAddOn")
      if LoadAddOn then pcall(LoadAddOn, "Blizzard_ColorPicker") end
      CPF = _G and rawget(_G, "ColorPickerFrame")
    end
    if not (CPF and (CPF.SetupColorPickerAndShow or (CPF.Show and CPF.SetColorRGB and CPF.GetColorRGB))) then
      Print("Color picker unavailable.")
      return
    end

    -- Make it feel like a "pop-out" attached to our options window.
    if CPF.ClearAllPoints and CPF.SetPoint and f and f.IsShown and f:IsShown() then
      CPF:ClearAllPoints()
      CPF:SetPoint("TOPRIGHT", f, "TOPLEFT", -8, -40)
      if CPF.SetFrameStrata then CPF:SetFrameStrata("DIALOG") end
      if CPF.SetClampedToScreen then CPF:SetClampedToScreen(true) end
    end

    local r0, g0, b0 = NormalizeRGB(initialR, initialG, initialB)
    local prev = { r0, g0, b0 }
    if CPF.SetupColorPickerAndShow then
      local info = {
        r = r0,
        g = g0,
        b = b0,
        hasOpacity = false,
        swatchFunc = function()
          local r, g, b = CPF:GetColorRGB()
          r, g, b = NormalizeRGB(r, g, b)
          if onChanged then onChanged(r, g, b) end
        end,
        cancelFunc = function(restored)
          local rv = restored or prev
          local r, g, b = NormalizeRGB(rv.r or rv[1], rv.g or rv[2], rv.b or rv[3])
          if onChanged then onChanged(r, g, b) end
        end,
        previousValues = prev,
      }
      CPF:SetupColorPickerAndShow(info)
    else
      CPF.hasOpacity = false
      CPF.opacityFunc = nil
      CPF.previousValues = prev

      CPF.func = function()
        local r, g, b = CPF:GetColorRGB()
        r, g, b = NormalizeRGB(r, g, b)
        if onChanged then onChanged(r, g, b) end
      end

      CPF.cancelFunc = function(restored)
        local rv = restored or prev
        local r, g, b = NormalizeRGB(rv[1], rv[2], rv[3])
        if onChanged then onChanged(r, g, b) end
      end

      CPF:SetColorRGB(r0, g0, b0)
      CPF:Show()
    end
  end

  local function CreateQuickColorPalette(parent, anchor, point, relPoint, xOff, yOff, opts)
    if not (parent and anchor) then return nil end
    opts = opts or {}

    local btnSize = tonumber(opts.buttonSize) or 12
    local gap = tonumber(opts.gap) or 3
    local cols = tonumber(opts.cols) or #QUICK_COLOR_PALETTE
    if cols < 1 then cols = 1 end

    local onPick = opts.onPick
    local getColor = opts.getColor

    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(1, 1)
    container:SetPoint(point or "TOPLEFT", anchor, relPoint or "BOTTOMLEFT", xOff or 0, yOff or 0)

    local buttons = {}
    for i = 1, #QUICK_COLOR_PALETTE do
      local row = math.floor((i - 1) / cols)
      local col = (i - 1) % cols

      local btn = CreateFrame("Button", nil, container)
      btn:SetSize(btnSize, btnSize)
      btn:SetPoint("TOPLEFT", container, "TOPLEFT", col * (btnSize + gap), -row * (btnSize + gap))
      btn:EnableMouse(true)

      local t = btn:CreateTexture(nil, "ARTWORK")
      t:SetAllPoints()
      if t.SetColorTexture then
        t:SetColorTexture(QUICK_COLOR_PALETTE[i][1], QUICK_COLOR_PALETTE[i][2], QUICK_COLOR_PALETTE[i][3], 1)
      end
      btn._tex = t

      btn:SetScript("OnClick", function()
        if not onPick then return end
        local r, g, b = NormalizeRGB(QUICK_COLOR_PALETTE[i][1], QUICK_COLOR_PALETTE[i][2], QUICK_COLOR_PALETTE[i][3])
        onPick(r, g, b)
      end)

      buttons[i] = btn
    end

    local lastBtn = buttons[#buttons]
    local moreBtn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    moreBtn:SetSize(56, 18)
    if lastBtn then
      moreBtn:SetPoint("LEFT", lastBtn, "RIGHT", 6, 0)
    else
      moreBtn:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    end
    moreBtn:SetText("More...")

    moreBtn:SetScript("OnClick", function()
      local r, g, b = 1, 1, 1
      if getColor then
        local cr, cg, cb = getColor()
        if cr ~= nil and cg ~= nil and cb ~= nil then
          r, g, b = NormalizeRGB(cr, cg, cb)
        end
      end
      ShowTextColorPicker(r, g, b, function(nr, ng, nb)
        if onPick then onPick(nr, ng, nb) end
      end)
    end)

    container._buttons = buttons
    container._moreBtn = moreBtn
    return container
  end

  f:HookScript("OnHide", function(self)
    SaveWindowPosition("options", self)
    if editMode then
      editMode = false
      RefreshAll()
    end
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

  local qTitleLabel = panels.quest:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  qTitleLabel:SetPoint("TOPLEFT", 12, -230)
  qTitleLabel:SetText("Title (optional)")

  local qTitleBox = CreateFrame("EditBox", nil, panels.quest, "InputBoxTemplate")
  qTitleBox:SetSize(220, 20)
  qTitleBox:SetPoint("TOPLEFT", 12, -246)
  qTitleBox:SetAutoFocus(false)
  qTitleBox:SetText("")
  AddPlaceholder(qTitleBox, "Custom title (leave blank for quest name)")

  local colorLabel = panels.quest:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  colorLabel:SetPoint("TOPLEFT", 12, -270)
  colorLabel:SetText("Color")

  local qLevelLabel = panels.quest:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  qLevelLabel:SetPoint("TOPLEFT", 180, -270)
  qLevelLabel:SetText("Player level")

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
  questColorDrop:SetPoint("TOPLEFT", -8, -298)
  if UDDM_SetWidth then UDDM_SetWidth(questColorDrop, 160) end
  if UDDM_SetText then UDDM_SetText(questColorDrop, "None") end
  panels.quest._questColor = nil
  panels.quest._questColorName = "None"

  local qLevelOpDrop = CreateFrame("Frame", nil, panels.quest, "UIDropDownMenuTemplate")
  qLevelOpDrop:SetPoint("TOPLEFT", 165, -298)
  if UDDM_SetWidth then UDDM_SetWidth(qLevelOpDrop, 70) end
  if UDDM_SetText then UDDM_SetText(qLevelOpDrop, "Off") end
  panels.quest._playerLevelOp = nil

  local qLevelBox = CreateFrame("EditBox", nil, panels.quest, "InputBoxTemplate")
  qLevelBox:SetSize(50, 20)
  qLevelBox:SetPoint("TOPLEFT", 270, -294)
  qLevelBox:SetAutoFocus(false)
  qLevelBox:SetNumeric(true)
  qLevelBox:SetText("0")

  local qLocLabel = panels.quest:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  qLocLabel:SetPoint("TOPLEFT", 330, -270)
  qLocLabel:SetText("LocationID (uiMapID)")

  local qLocBox = CreateFrame("EditBox", nil, panels.quest, "InputBoxTemplate")
  qLocBox:SetSize(90, 20)
  qLocBox:SetPoint("TOPLEFT", 330, -294)
  qLocBox:SetAutoFocus(false)
  qLocBox:SetText("0")

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

    UDDM_Initialize(qLevelOpDrop, function(self, level)
      local function Add(name, op)
        local info = UDDM_CreateInfo()
        info.text = name
        info.checked = (panels.quest._playerLevelOp == op) and true or false
        info.func = function()
          panels.quest._playerLevelOp = op
          if UDDM_SetText then UDDM_SetText(qLevelOpDrop, name) end
        end
        UDDM_AddButton(info)
      end
      Add("Off", nil)
      Add("<", "<")
      Add("<=", "<=")
      Add("=", "=")
      Add(">=", ">=")
      Add(">", ">")
      Add("!=", "!=")
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
    cfb:SetPoint("TOPLEFT", 12, -292)
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

    qLevelOpDrop:Hide()
    qLevelLabel:Hide()
    qLevelBox:Hide()
  end

  local addQuestBtn = CreateFrame("Button", nil, panels.quest, "UIPanelButtonTemplate")
  addQuestBtn:SetSize(140, 22)
  addQuestBtn:SetPoint("TOPLEFT", 12, -340)
  addQuestBtn:SetText("Add Quest Rule")

  panels.quest._questIDBox = questIDBox
  panels.quest._questInfoBox = qiBox
  panels.quest._questAfterBox = afterBox
  panels.quest._titleBox = qTitleBox
  panels.quest._locBox = qLocBox
  panels.quest._questFrameDrop = questFrameDrop
  panels.quest._questFactionDrop = questFactionDrop
  panels.quest._questColorDrop = questColorDrop
  panels.quest._addQuestBtn = addQuestBtn

  local cancelQuestEditBtn = CreateFrame("Button", nil, panels.quest, "UIPanelButtonTemplate")
  cancelQuestEditBtn:SetSize(120, 22)
  cancelQuestEditBtn:SetPoint("LEFT", addQuestBtn, "RIGHT", 8, 0)
  cancelQuestEditBtn:SetText("Cancel Edit")
  cancelQuestEditBtn:Hide()
  panels.quest._cancelEditBtn = cancelQuestEditBtn

  -- Quick color palette for quest text color
  CreateQuickColorPalette(panels.quest, addQuestBtn, "TOPLEFT", "TOPLEFT", 0, 33, {
    cols = 5,
    getColor = function()
      if type(panels.quest._questColor) == "table" then
        return panels.quest._questColor[1], panels.quest._questColor[2], panels.quest._questColor[3]
      end
      return nil
    end,
    onPick = function(r, g, b)
      panels.quest._questColor = { r, g, b }
      panels.quest._questColorName = "Custom"
      if UDDM_SetText then UDDM_SetText(questColorDrop, ColorLabel("Custom")) end
    end,
  })

  addQuestBtn:SetScript("OnClick", function()
    local wasEditing = (panels.quest._editingCustomIndex ~= nil) and true or false
    local questID = tonumber(questIDBox:GetText() or "")
    if not questID or questID <= 0 then
      Print("Enter a questID > 0.")
      return
    end

    local targetFrame = tostring(panels.quest._questTargetFrameID or ""):gsub("%s+", "")
    if targetFrame == "" then targetFrame = "list1" end

    local infoText = tostring(qiBox:GetText() or "")
    infoText = infoText:gsub("\r\n?", "\n")
    -- Preserve leading spaces/tabs for indentation; only strip trailing whitespace and blank-line padding.
    infoText = infoText:gsub("^\n+", ""):gsub("\n+$", "")
    infoText = infoText:gsub("%s+$", "")
    local questInfo = (infoText ~= "") and infoText or nil

    local titleText = tostring(qTitleBox:GetText() or "")
    titleText = titleText:gsub("^%s+", ""):gsub("%s+$", "")
    local title = (titleText ~= "") and titleText or nil

    local afterID = tonumber(afterBox:GetText() or "")
    local prereq = nil
    if afterID and afterID > 0 then
      prereq = { afterID }
    end

    local locText = tostring(qLocBox:GetText() or ""):gsub("%s+", "")
    local locationID = (locText ~= "" and locText ~= "0") and locText or nil

    local rules = GetCustomRules()
    if panels.quest._editingCustomIndex and type(rules[panels.quest._editingCustomIndex]) == "table" then
      local rule = rules[panels.quest._editingCustomIndex]
      rule.questID = questID
      rule.frameID = targetFrame
      rule.questInfo = questInfo
      rule.label = title
      rule.prereq = prereq
      rule.faction = panels.quest._questFaction
      rule.color = panels.quest._questColor
      rule.locationID = locationID

      local op = panels.quest._playerLevelOp
      local lvl = qLevelBox and tonumber(qLevelBox:GetText() or "") or nil
      if lvl and lvl <= 0 then lvl = nil end
      if op and lvl then
        rule.playerLevelOp = op
        rule.playerLevel = lvl
      else
        rule.playerLevelOp = nil
        rule.playerLevel = nil
      end
      if rule.hideWhenCompleted == nil then rule.hideWhenCompleted = true end

      panels.quest._editingCustomIndex = nil
      addQuestBtn:SetText("Add Quest Rule")
      cancelQuestEditBtn:Hide()
      Print("Saved quest rule.")
    else
      local key = string.format("custom:q:%d:%s:%d", tostring(questID), tostring(targetFrame), (#rules + 1))

      local op = panels.quest._playerLevelOp
      local lvl = qLevelBox and tonumber(qLevelBox:GetText() or "") or nil
      if lvl and lvl <= 0 then lvl = nil end
      if not (op and lvl) then op = nil; lvl = nil end

      rules[#rules + 1] = {
        key = key,
        questID = questID,
        frameID = targetFrame,
        questInfo = questInfo,
        label = title,
        prereq = prereq,
        faction = panels.quest._questFaction,
        color = panels.quest._questColor,
        locationID = locationID,
        playerLevelOp = op,
        playerLevel = lvl,
        hideWhenCompleted = true,
      }

      Print("Added quest rule for quest " .. questID .. " -> " .. targetFrame)
    end

    CreateAllFrames()
    RefreshAll()
    RefreshRulesList()
    if wasEditing then
      SelectTab("rules")
    end
  end)

  cancelQuestEditBtn:SetScript("OnClick", function()
    panels.quest._editingCustomIndex = nil
    addQuestBtn:SetText("Add Quest Rule")
    cancelQuestEditBtn:Hide()
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
  SetCheckButtonLabel(useNameCheck, "Use name from ID")
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

  -- Quick color palette for item text color
  CreateQuickColorPalette(panels.items, itemsColorDrop, "TOPLEFT", "BOTTOMLEFT", 26, 12, {
    cols = 5,
    getColor = function()
      if type(panels.items._color) == "table" then
        return panels.items._color[1], panels.items._color[2], panels.items._color[3]
      end
      return nil
    end,
    onPick = function(r, g, b)
      panels.items._color = { r, g, b }
      if UDDM_SetText then UDDM_SetText(itemsColorDrop, "Custom") end
    end,
  })

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
  SetCheckButtonLabel(hideAcquired, "Hide when acquired")
  hideAcquired:SetChecked(false)

  local hideExalted = CreateFrame("CheckButton", nil, panels.items, "UICheckButtonTemplate")
  hideExalted:SetPoint("TOPLEFT", 400, -198)
  SetCheckButtonLabel(hideExalted, "Hide when exalted")
  hideExalted:SetChecked(false)

  local restedOnly = CreateFrame("CheckButton", nil, panels.items, "UICheckButtonTemplate")
  restedOnly:SetPoint("TOPLEFT", 12, -222)
  SetCheckButtonLabel(restedOnly, "Rested areas only")
  restedOnly:SetChecked(false)

  local itemsLevelLabel = panels.items:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  itemsLevelLabel:SetPoint("TOPLEFT", 250, -228)
  itemsLevelLabel:SetText("Player level")

  local itemsLevelOpDrop = CreateFrame("Frame", nil, panels.items, "UIDropDownMenuTemplate")
  itemsLevelOpDrop:SetPoint("TOPLEFT", 235, -248)
  if UDDM_SetWidth then UDDM_SetWidth(itemsLevelOpDrop, 70) end
  if UDDM_SetText then UDDM_SetText(itemsLevelOpDrop, "Off") end
  panels.items._playerLevelOp = nil

  local itemsLevelBox = CreateFrame("EditBox", nil, panels.items, "InputBoxTemplate")
  itemsLevelBox:SetSize(50, 20)
  itemsLevelBox:SetPoint("TOPLEFT", 340, -244)
  itemsLevelBox:SetAutoFocus(false)
  itemsLevelBox:SetNumeric(true)
  itemsLevelBox:SetText("0")

  local itemsLocLabel = panels.items:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  itemsLocLabel:SetPoint("TOPLEFT", 12, -252)
  itemsLocLabel:SetText("LocationID (uiMapID)")

  local itemsLocBox = CreateFrame("EditBox", nil, panels.items, "InputBoxTemplate")
  itemsLocBox:SetSize(90, 20)
  itemsLocBox:SetPoint("TOPLEFT", 12, -268)
  itemsLocBox:SetAutoFocus(false)
  itemsLocBox:SetText("0")

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

    UDDM_Initialize(itemsLevelOpDrop, function(self, level)
      local function Add(name, op)
        local info = UDDM_CreateInfo()
        info.text = name
        info.checked = (panels.items._playerLevelOp == op) and true or false
        info.func = function()
          panels.items._playerLevelOp = op
          if UDDM_SetText then UDDM_SetText(itemsLevelOpDrop, name) end
        end
        UDDM_AddButton(info)
      end
      Add("Off", nil)
      Add("<", "<")
      Add("<=", "<=")
      Add("=", "=")
      Add(">=", ">=")
      Add(">", ">")
      Add("!=", "!=")
    end)
  end

  local addItemBtn = CreateFrame("Button", nil, panels.items, "UIPanelButtonTemplate")
  addItemBtn:SetSize(140, 22)
  addItemBtn:SetPoint("TOPLEFT", 12, -312)
  addItemBtn:SetText("Add Item Entry")

  panels.items._itemIDBox = itemIDBox
  panels.items._itemLabelBox = itemLabelBox
  panels.items._useNameCheck = useNameCheck
  panels.items._repFactionBox = repFactionBox
  panels.items._repMinDrop = repMinDrop
  panels.items._hideAcquired = hideAcquired
  panels.items._hideExalted = hideExalted
  panels.items._restedOnly = restedOnly
  panels.items._locBox = itemsLocBox
  panels.items._itemsFrameDrop = itemsFrameDrop
  panels.items._itemsFactionDrop = itemsFactionDrop
  panels.items._itemsColorDrop = itemsColorDrop
  panels.items._addItemBtn = addItemBtn

  local cancelItemEditBtn = CreateFrame("Button", nil, panels.items, "UIPanelButtonTemplate")
  cancelItemEditBtn:SetSize(120, 22)
  cancelItemEditBtn:SetPoint("LEFT", addItemBtn, "RIGHT", 8, 0)
  cancelItemEditBtn:SetText("Cancel Edit")
  cancelItemEditBtn:Hide()
  panels.items._cancelEditBtn = cancelItemEditBtn

  addItemBtn:SetScript("OnClick", function()
    local wasEditing = (panels.items._editingCustomIndex ~= nil) and true or false
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

    local locText = tostring(itemsLocBox:GetText() or ""):gsub("%s+", "")
    local locationID = (locText ~= "" and locText ~= "0") and locText or nil

    local rules = GetCustomRules()
    if panels.items._editingCustomIndex and type(rules[panels.items._editingCustomIndex]) == "table" then
      local rule = rules[panels.items._editingCustomIndex]
      rule.frameID = targetFrame
      rule.faction = panels.items._faction
      rule.color = panels.items._color
      rule.restedOnly = restedOnly:GetChecked() and true or false
      rule.label = label
      rule.rep = rep
      rule.locationID = locationID

      local op = panels.items._playerLevelOp
      local lvl = itemsLevelBox and tonumber(itemsLevelBox:GetText() or "") or nil
      if lvl and lvl <= 0 then lvl = nil end
      if op and lvl then
        rule.playerLevelOp = op
        rule.playerLevel = lvl
      else
        rule.playerLevelOp = nil
        rule.playerLevel = nil
      end

      rule.item = rule.item or {}
      rule.item.itemID = itemID
      rule.item.required = tonumber(rule.item.required) or 1
      rule.item.hideWhenAcquired = hideAcquired:GetChecked() and true or false
      if rule.hideWhenCompleted == nil then rule.hideWhenCompleted = false end

      panels.items._editingCustomIndex = nil
      addItemBtn:SetText("Add Item Entry")
      cancelItemEditBtn:Hide()
      Print("Saved item entry.")
    else
      local key = string.format("custom:item:%d:%s:%d", tostring(itemID), tostring(targetFrame), (#rules + 1))
      local op = panels.items._playerLevelOp
      local lvl = itemsLevelBox and tonumber(itemsLevelBox:GetText() or "") or nil
      if lvl and lvl <= 0 then lvl = nil end
      if not (op and lvl) then op = nil; lvl = nil end
      rules[#rules + 1] = {
        key = key,
        frameID = targetFrame,
        faction = panels.items._faction,
        color = panels.items._color,
        restedOnly = restedOnly:GetChecked() and true or false,
        label = label,
        rep = rep,
        locationID = locationID,
        playerLevelOp = op,
        playerLevel = lvl,
        item = {
          itemID = itemID,
          required = 1,
          hideWhenAcquired = hideAcquired:GetChecked() and true or false,
        },
        hideWhenCompleted = false,
      }

      Print("Added item entry for item " .. itemID .. " -> " .. targetFrame)
    end

    CreateAllFrames()
    RefreshAll()
    RefreshRulesList()
    if wasEditing then
      SelectTab("rules")
    end
  end)

  cancelItemEditBtn:SetScript("OnClick", function()
    panels.items._editingCustomIndex = nil
    addItemBtn:SetText("Add Item Entry")
    cancelItemEditBtn:Hide()
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

  -- Quick color palette for text entry color
  CreateQuickColorPalette(panels.text, textColorDrop, "TOPLEFT", "BOTTOMLEFT", 26, 12, {
    cols = 5,
    getColor = function()
      if type(panels.text._color) == "table" then
        return panels.text._color[1], panels.text._color[2], panels.text._color[3]
      end
      return nil
    end,
    onPick = function(r, g, b)
      panels.text._color = { r, g, b }
      if UDDM_SetText then UDDM_SetText(textColorDrop, "Custom") end
    end,
  })

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
  textRestedOnly:SetPoint("TOPLEFT", 250, -196)
  SetCheckButtonLabel(textRestedOnly, "Rested areas only")
  textRestedOnly:SetChecked(false)

  local textLocLabel = panels.text:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  textLocLabel:SetPoint("TOPLEFT", 250, -156)
  textLocLabel:SetText("LocationID (uiMapID)")

  local textLocBox = CreateFrame("EditBox", nil, panels.text, "InputBoxTemplate")
  textLocBox:SetSize(90, 20)
  textLocBox:SetPoint("TOPLEFT", 250, -172)
  textLocBox:SetAutoFocus(false)
  textLocBox:SetText("0")

  local textLevelLabel = panels.text:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  textLevelLabel:SetPoint("TOPLEFT", 400, -156)
  textLevelLabel:SetText("Player level")

  local textLevelOpDrop = CreateFrame("Frame", nil, panels.text, "UIDropDownMenuTemplate")
  textLevelOpDrop:SetPoint("TOPLEFT", 385, -176)
  if UDDM_SetWidth then UDDM_SetWidth(textLevelOpDrop, 70) end
  if UDDM_SetText then UDDM_SetText(textLevelOpDrop, "Off") end
  panels.text._playerLevelOp = nil

  local textLevelBox = CreateFrame("EditBox", nil, panels.text, "InputBoxTemplate")
  textLevelBox:SetSize(50, 20)
  textLevelBox:SetPoint("TOPLEFT", 490, -172)
  textLevelBox:SetAutoFocus(false)
  textLevelBox:SetNumeric(true)
  textLevelBox:SetText("0")

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

    UDDM_Initialize(textLevelOpDrop, function(self, level)
      local function Add(name, op)
        local info = UDDM_CreateInfo()
        info.text = name
        info.checked = (panels.text._playerLevelOp == op) and true or false
        info.func = function()
          panels.text._playerLevelOp = op
          if UDDM_SetText then UDDM_SetText(textLevelOpDrop, name) end
        end
        UDDM_AddButton(info)
      end
      Add("Off", nil)
      Add("<", "<")
      Add("<=", "<=")
      Add("=", "=")
      Add(">=", ">=")
      Add(">", ">")
      Add("!=", "!=")
    end)
  end

  local addTextBtn = CreateFrame("Button", nil, panels.text, "UIPanelButtonTemplate")
  addTextBtn:SetSize(140, 22)
  addTextBtn:SetPoint("TOPLEFT", 12, -236)
  addTextBtn:SetText("Add Text Entry")

  panels.text._textBox = textBox
  panels.text._textFrameDrop = textFrameDrop
  panels.text._textFactionDrop = textFactionDrop
  panels.text._textColorDrop = textColorDrop
  panels.text._repFactionBox = textRepFactionBox
  panels.text._repMinDrop = textRepMinDrop
  panels.text._restedOnly = textRestedOnly
  panels.text._locBox = textLocBox
  panels.text._addTextBtn = addTextBtn

  local cancelTextEditBtn = CreateFrame("Button", nil, panels.text, "UIPanelButtonTemplate")
  cancelTextEditBtn:SetSize(120, 22)
  cancelTextEditBtn:SetPoint("LEFT", addTextBtn, "RIGHT", 8, 0)
  cancelTextEditBtn:SetText("Cancel Edit")
  cancelTextEditBtn:Hide()
  panels.text._cancelEditBtn = cancelTextEditBtn

  addTextBtn:SetScript("OnClick", function()
    local wasEditing = (panels.text._editingCustomIndex ~= nil) and true or false
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

    local locText = tostring(textLocBox:GetText() or ""):gsub("%s+", "")
    local locationID = (locText ~= "" and locText ~= "0") and locText or nil

    local rules = GetCustomRules()
    if panels.text._editingCustomIndex and type(rules[panels.text._editingCustomIndex]) == "table" then
      local rule = rules[panels.text._editingCustomIndex]
      rule.frameID = targetFrame
      rule.label = t
      rule.faction = panels.text._faction
      rule.color = panels.text._color
      rule.rep = rep
      rule.restedOnly = textRestedOnly:GetChecked() and true or false
      rule.locationID = locationID

      local op = panels.text._playerLevelOp
      local lvl = textLevelBox and tonumber(textLevelBox:GetText() or "") or nil
      if lvl and lvl <= 0 then lvl = nil end
      if op and lvl then
        rule.playerLevelOp = op
        rule.playerLevel = lvl
      else
        rule.playerLevelOp = nil
        rule.playerLevel = nil
      end

      if rule.hideWhenCompleted == nil then rule.hideWhenCompleted = false end

      panels.text._editingCustomIndex = nil
      addTextBtn:SetText("Add Text Entry")
      cancelTextEditBtn:Hide()
      Print("Saved text entry.")
    else
      local key = string.format("custom:text:%s:%s:%d", tostring(targetFrame), tostring(t), (#rules + 1))
      local op = panels.text._playerLevelOp
      local lvl = textLevelBox and tonumber(textLevelBox:GetText() or "") or nil
      if lvl and lvl <= 0 then lvl = nil end
      if not (op and lvl) then op = nil; lvl = nil end
      rules[#rules + 1] = {
        key = key,
        frameID = targetFrame,
        label = t,
        faction = panels.text._faction,
        color = panels.text._color,
        rep = rep,
        restedOnly = textRestedOnly:GetChecked() and true or false,
        locationID = locationID,
        playerLevelOp = op,
        playerLevel = lvl,
        hideWhenCompleted = false,
      }

      Print("Added text entry -> " .. targetFrame)
    end

    CreateAllFrames()
    RefreshAll()
    RefreshRulesList()
    if wasEditing then
      SelectTab("rules")
    end
  end)

  cancelTextEditBtn:SetScript("OnClick", function()
    panels.text._editingCustomIndex = nil
    addTextBtn:SetText("Add Text Entry")
    cancelTextEditBtn:Hide()
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
  SetCheckButtonLabel(notInGroupCheck, "Not in group")
  notInGroupCheck:SetChecked(false)

  local spellsLevelLabel = panels.spells:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  spellsLevelLabel:SetPoint("TOPLEFT", 180, -202)
  spellsLevelLabel:SetText("Player level")

  local spellsLevelOpDrop = CreateFrame("Frame", nil, panels.spells, "UIDropDownMenuTemplate")
  spellsLevelOpDrop:SetPoint("TOPLEFT", 165, -222)
  if UDDM_SetWidth then UDDM_SetWidth(spellsLevelOpDrop, 70) end
  if UDDM_SetText then UDDM_SetText(spellsLevelOpDrop, "Off") end
  panels.spells._playerLevelOp = nil

  local spellsLevelBox = CreateFrame("EditBox", nil, panels.spells, "InputBoxTemplate")
  spellsLevelBox:SetSize(50, 20)
  spellsLevelBox:SetPoint("TOPLEFT", 270, -218)
  spellsLevelBox:SetAutoFocus(false)
  spellsLevelBox:SetNumeric(true)
  spellsLevelBox:SetText("0")

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

  -- Quick color palette for spell text color
  CreateQuickColorPalette(panels.spells, spellsColorDrop, "TOPLEFT", "BOTTOMLEFT", 26, 20, {
    cols = 5,
    getColor = function()
      if type(panels.spells._color) == "table" then
        return panels.spells._color[1], panels.spells._color[2], panels.spells._color[3]
      end
      return nil
    end,
    onPick = function(r, g, b)
      panels.spells._color = { r, g, b }
      if UDDM_SetText then UDDM_SetText(spellsColorDrop, "Custom") end
    end,
  })

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

    UDDM_Initialize(spellsLevelOpDrop, function(self, level)
      local function Add(name, op)
        local info = UDDM_CreateInfo()
        info.text = name
        info.checked = (panels.spells._playerLevelOp == op) and true or false
        info.func = function()
          panels.spells._playerLevelOp = op
          if UDDM_SetText then UDDM_SetText(spellsLevelOpDrop, name) end
        end
        UDDM_AddButton(info)
      end
      Add("Off", nil)
      Add("<", "<")
      Add("<=", "<=")
      Add("=", "=")
      Add(">=", ">=")
      Add(">", ">")
      Add("!=", "!=")
    end)
  end

  local addSpellBtn = CreateFrame("Button", nil, panels.spells, "UIPanelButtonTemplate")
  addSpellBtn:SetSize(140, 22)
  addSpellBtn:SetPoint("TOPLEFT", 12, -280)
  addSpellBtn:SetText("Add Spell Rule")

  panels.spells._detailsBox = spellsDetailsBox
  panels.spells._classDrop = classDrop
  panels.spells._knownBox = knownBox
  panels.spells._notKnownBox = notKnownBox
  panels.spells._locBox = locBox
  panels.spells._notInGroup = notInGroupCheck
  panels.spells._spellsFrameDrop = spellsFrameDrop
  panels.spells._spellsFactionDrop = spellsFactionDrop
  panels.spells._spellsColorDrop = spellsColorDrop
  panels.spells._addSpellBtn = addSpellBtn

  local cancelSpellEditBtn = CreateFrame("Button", nil, panels.spells, "UIPanelButtonTemplate")
  cancelSpellEditBtn:SetSize(120, 22)
  cancelSpellEditBtn:SetPoint("LEFT", addSpellBtn, "RIGHT", 8, 0)
  cancelSpellEditBtn:SetText("Cancel Edit")
  cancelSpellEditBtn:Hide()
  panels.spells._cancelEditBtn = cancelSpellEditBtn

  addSpellBtn:SetScript("OnClick", function()
    local wasEditing = (panels.spells._editingCustomIndex ~= nil) and true or false
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
    if panels.spells._editingCustomIndex and type(rules[panels.spells._editingCustomIndex]) == "table" then
      local rule = rules[panels.spells._editingCustomIndex]
      rule.frameID = targetFrame
      rule.label = label
      rule.class = panels.spells._class
      rule.faction = panels.spells._faction
      rule.color = panels.spells._color
      rule.notInGroup = notInGroupCheck:GetChecked() and true or false
      rule.locationID = locationID
      rule.spellKnown = known
      rule.notSpellKnown = notKnown

      local op = panels.spells._playerLevelOp
      local lvl = spellsLevelBox and tonumber(spellsLevelBox:GetText() or "") or nil
      if lvl and lvl <= 0 then lvl = nil end
      if op and lvl then
        rule.playerLevelOp = op
        rule.playerLevel = lvl
      else
        rule.playerLevelOp = nil
        rule.playerLevel = nil
      end

      if rule.hideWhenCompleted == nil then rule.hideWhenCompleted = false end

      panels.spells._editingCustomIndex = nil
      addSpellBtn:SetText("Add Spell Rule")
      cancelSpellEditBtn:Hide()
      Print("Saved spell rule.")
    else
      local key = string.format("custom:spell:%s:%d", tostring(targetFrame), (#rules + 1))

      local op = panels.spells._playerLevelOp
      local lvl = spellsLevelBox and tonumber(spellsLevelBox:GetText() or "") or nil
      if lvl and lvl <= 0 then lvl = nil end
      if not (op and lvl) then op = nil; lvl = nil end

      local r = {
        key = key,
        frameID = targetFrame,
        label = label,
        class = panels.spells._class,
        faction = panels.spells._faction,
        color = panels.spells._color,
        notInGroup = notInGroupCheck:GetChecked() and true or false,
        locationID = locationID,
        playerLevelOp = op,
        playerLevel = lvl,
        hideWhenCompleted = false,
      }
      if known then r.spellKnown = known end
      if notKnown then r.notSpellKnown = notKnown end

      rules[#rules + 1] = r
      Print("Added spell rule -> " .. targetFrame)
    end
    CreateAllFrames()
    RefreshAll()
    RefreshRulesList()
    if wasEditing then
      SelectTab("rules")
    end
  end)

  cancelSpellEditBtn:SetScript("OnClick", function()
    panels.spells._editingCustomIndex = nil
    addSpellBtn:SetText("Add Spell Rule")
    cancelSpellEditBtn:Hide()
  end)

  local function ClearTabEdits()
    if panels.quest then
      panels.quest._editingCustomIndex = nil
      if panels.quest._addQuestBtn then panels.quest._addQuestBtn:SetText("Add Quest Rule") end
      if panels.quest._cancelEditBtn then panels.quest._cancelEditBtn:Hide() end
    end
    if panels.items then
      panels.items._editingCustomIndex = nil
      if panels.items._addItemBtn then panels.items._addItemBtn:SetText("Add Item Entry") end
      if panels.items._cancelEditBtn then panels.items._cancelEditBtn:Hide() end
    end
    if panels.text then
      panels.text._editingCustomIndex = nil
      if panels.text._addTextBtn then panels.text._addTextBtn:SetText("Add Text Entry") end
      if panels.text._cancelEditBtn then panels.text._cancelEditBtn:Hide() end
    end
    if panels.spells then
      panels.spells._editingCustomIndex = nil
      if panels.spells._addSpellBtn then panels.spells._addSpellBtn:SetText("Add Spell Rule") end
      if panels.spells._cancelEditBtn then panels.spells._cancelEditBtn:Hide() end
    end
  end

  local function ColorToNameLite(color)
    if type(color) ~= "table" then return "None" end
    local r, g, b = tonumber(color[1]), tonumber(color[2]), tonumber(color[3])
    if r == 0.1 and g == 1.0 and b == 0.1 then return "Green" end
    if r == 0.2 and g == 0.6 and b == 1.0 then return "Blue" end
    if r == 1.0 and g == 0.9 and b == 0.2 then return "Yellow" end
    if r == 1.0 and g == 0.2 and b == 0.2 then return "Red" end
    if r == 0.2 and g == 1.0 and b == 1.0 then return "Cyan" end
    return "Custom"
  end

  local function RepStandingLabelLite(standing)
    standing = tonumber(standing)
    if not standing then return "Off" end
    if standing == 5 then return "Friendly" end
    if standing == 6 then return "Honored" end
    if standing == 7 then return "Revered" end
    if standing == 8 then return "Exalted" end
    return tostring(standing)
  end

  local function DetectRuleTypeLite(r)
    if type(r) ~= "table" then return "text" end
    if tonumber(r.questID) and tonumber(r.questID) > 0 then return "quest" end
    if type(r.item) == "table" and tonumber(r.item.itemID) and tonumber(r.item.itemID) > 0 then return "item" end
    if r.spellKnown or r.notSpellKnown or r.locationID or r.class or r.notInGroup then return "spell" end
    return "text"
  end

  local function OpenCustomRuleInTab(customIndex)
    if not optionsFrame then return end
    local rules = GetCustomRules()
    local rule = rules[customIndex]
    if type(rule) ~= "table" then return end

    if optionsFrame._ruleEditorFrame then
      optionsFrame._ruleEditorFrame._skipRestore = true
      optionsFrame._ruleEditorFrame:Hide()
    end
    ClearTabEdits()

    local t = DetectRuleTypeLite(rule)
    if t == "quest" then
      SelectTab("quest")
      panels.quest._editingCustomIndex = customIndex
      if panels.quest._addQuestBtn then panels.quest._addQuestBtn:SetText("Save Quest Rule") end
      if panels.quest._cancelEditBtn then panels.quest._cancelEditBtn:Show() end

      if panels.quest._questIDBox then panels.quest._questIDBox:SetText(tostring(tonumber(rule.questID) or 0)) end
      if panels.quest._questInfoBox then panels.quest._questInfoBox:SetText(tostring(rule.questInfo or rule.label or "")) end
      if panels.quest._titleBox then panels.quest._titleBox:SetText(tostring(rule.label or "")) end
      local after = 0
      if type(rule.prereq) == "table" then
        local n = tonumber(rule.prereq[1])
        if n and n > 0 then after = n end
      end
      if panels.quest._questAfterBox then panels.quest._questAfterBox:SetText(tostring(after)) end
      if panels.quest._locBox then panels.quest._locBox:SetText(tostring(rule.locationID or "0")) end

      local frameID = tostring(rule.frameID or "list1")
      panels.quest._questTargetFrameID = frameID
      if UDDM_SetText and panels.quest._questFrameDrop then UDDM_SetText(panels.quest._questFrameDrop, frameID) end

      panels.quest._questFaction = (rule.faction == "Alliance" or rule.faction == "Horde") and rule.faction or nil
      if UDDM_SetText and panels.quest._questFactionDrop and FactionLabel then
        UDDM_SetText(panels.quest._questFactionDrop, FactionLabel(panels.quest._questFaction))
      end

      panels.quest._questColor = rule.color
      if UDDM_SetText and panels.quest._questColorDrop and ColorLabel then
        local name = ColorToNameLite(rule.color)
        if name == "Custom" then name = ColorLabel("Custom") end
        UDDM_SetText(panels.quest._questColorDrop, ColorLabel(name == "Custom" and "Custom" or name))
      end

      panels.quest._playerLevelOp = (rule.playerLevelOp == "<" or rule.playerLevelOp == "<=" or rule.playerLevelOp == "=" or rule.playerLevelOp == ">=" or rule.playerLevelOp == ">" or rule.playerLevelOp == "!=") and rule.playerLevelOp or nil
      if UDDM_SetText and qLevelOpDrop then UDDM_SetText(qLevelOpDrop, panels.quest._playerLevelOp or "Off") end
      if qLevelBox then qLevelBox:SetText(tostring(tonumber(rule.playerLevel) or 0)) end
      return
    end

    if t == "item" then
      SelectTab("items")
      panels.items._editingCustomIndex = customIndex
      if panels.items._addItemBtn then panels.items._addItemBtn:SetText("Save Item Entry") end
      if panels.items._cancelEditBtn then panels.items._cancelEditBtn:Show() end

      local itemID = (type(rule.item) == "table") and tonumber(rule.item.itemID) or 0
      if panels.items._itemIDBox then panels.items._itemIDBox:SetText(tostring(itemID or 0)) end

      local useName = (rule.label == nil)
      if panels.items._useNameCheck then panels.items._useNameCheck:SetChecked(useName and true or false) end
      if panels.items._itemLabelBox then panels.items._itemLabelBox:SetText(useName and "" or tostring(rule.label or "")) end

      local frameID = tostring(rule.frameID or "list1")
      panels.items._targetFrameID = frameID
      if UDDM_SetText and panels.items._itemsFrameDrop then UDDM_SetText(panels.items._itemsFrameDrop, frameID) end

      panels.items._faction = (rule.faction == "Alliance" or rule.faction == "Horde") and rule.faction or nil
      if UDDM_SetText and panels.items._itemsFactionDrop then
        UDDM_SetText(panels.items._itemsFactionDrop, panels.items._faction and tostring(panels.items._faction) or "Both (Off)")
      end

      panels.items._color = rule.color
      if UDDM_SetText and panels.items._itemsColorDrop then
        UDDM_SetText(panels.items._itemsColorDrop, ColorToNameLite(rule.color))
      end

      if panels.items._restedOnly then panels.items._restedOnly:SetChecked(rule.restedOnly and true or false) end
      if panels.items._locBox then panels.items._locBox:SetText(tostring(rule.locationID or "0")) end
      if panels.items._hideAcquired and type(rule.item) == "table" then
        panels.items._hideAcquired:SetChecked(rule.item.hideWhenAcquired and true or false)
      end

      local repFactionID = 0
      local repMin = nil
      local repHideEx = false
      if type(rule.rep) == "table" and rule.rep.factionID then
        repFactionID = tonumber(rule.rep.factionID) or 0
        repMin = tonumber(rule.rep.minStanding)
        repHideEx = (rule.rep.hideWhenExalted == true)
      end
      if panels.items._repFactionBox then panels.items._repFactionBox:SetText(tostring(repFactionID or 0)) end
      panels.items._repMinStanding = repMin
      if UDDM_SetText and panels.items._repMinDrop then UDDM_SetText(panels.items._repMinDrop, RepStandingLabelLite(repMin)) end
      if panels.items._hideExalted then panels.items._hideExalted:SetChecked(repHideEx and true or false) end

      panels.items._playerLevelOp = (rule.playerLevelOp == "<" or rule.playerLevelOp == "<=" or rule.playerLevelOp == "=" or rule.playerLevelOp == ">=" or rule.playerLevelOp == ">" or rule.playerLevelOp == "!=") and rule.playerLevelOp or nil
      if UDDM_SetText and itemsLevelOpDrop then UDDM_SetText(itemsLevelOpDrop, panels.items._playerLevelOp or "Off") end
      if itemsLevelBox then itemsLevelBox:SetText(tostring(tonumber(rule.playerLevel) or 0)) end
      return
    end

    if t == "spell" then
      SelectTab("spells")
      panels.spells._editingCustomIndex = customIndex
      if panels.spells._addSpellBtn then panels.spells._addSpellBtn:SetText("Save Spell Rule") end
      if panels.spells._cancelEditBtn then panels.spells._cancelEditBtn:Show() end

      if panels.spells._detailsBox then panels.spells._detailsBox:SetText(tostring(rule.label or "")) end
      if panels.spells._knownBox then panels.spells._knownBox:SetText(tostring(tonumber(rule.spellKnown) or 0)) end
      if panels.spells._notKnownBox then panels.spells._notKnownBox:SetText(tostring(tonumber(rule.notSpellKnown) or 0)) end
      if panels.spells._locBox then panels.spells._locBox:SetText(tostring(rule.locationID or "0")) end
      if panels.spells._notInGroup then panels.spells._notInGroup:SetChecked(rule.notInGroup and true or false) end

      panels.spells._class = rule.class
      if UDDM_SetText and panels.spells._classDrop then UDDM_SetText(panels.spells._classDrop, panels.spells._class or "None") end

      local frameID = tostring(rule.frameID or "list1")
      panels.spells._targetFrameID = frameID
      if UDDM_SetText and panels.spells._spellsFrameDrop then UDDM_SetText(panels.spells._spellsFrameDrop, frameID) end

      panels.spells._faction = (rule.faction == "Alliance" or rule.faction == "Horde") and rule.faction or nil
      if UDDM_SetText and panels.spells._spellsFactionDrop then
        UDDM_SetText(panels.spells._spellsFactionDrop, panels.spells._faction and tostring(panels.spells._faction) or "Both (Off)")
      end

      panels.spells._color = rule.color
      if UDDM_SetText and panels.spells._spellsColorDrop then
        UDDM_SetText(panels.spells._spellsColorDrop, ColorToNameLite(rule.color))
      end

      panels.spells._playerLevelOp = (rule.playerLevelOp == "<" or rule.playerLevelOp == "<=" or rule.playerLevelOp == "=" or rule.playerLevelOp == ">=" or rule.playerLevelOp == ">" or rule.playerLevelOp == "!=") and rule.playerLevelOp or nil
      if UDDM_SetText and spellsLevelOpDrop then UDDM_SetText(spellsLevelOpDrop, panels.spells._playerLevelOp or "Off") end
      if spellsLevelBox then spellsLevelBox:SetText(tostring(tonumber(rule.playerLevel) or 0)) end
      return
    end

    -- text
    SelectTab("text")
    panels.text._editingCustomIndex = customIndex
    if panels.text._addTextBtn then panels.text._addTextBtn:SetText("Save Text Entry") end
    if panels.text._cancelEditBtn then panels.text._cancelEditBtn:Show() end

    if panels.text._textBox then panels.text._textBox:SetText(tostring(rule.label or "")) end

    local frameID = tostring(rule.frameID or "list1")
    panels.text._targetFrameID = frameID
    if UDDM_SetText and panels.text._textFrameDrop then UDDM_SetText(panels.text._textFrameDrop, frameID) end

    panels.text._faction = (rule.faction == "Alliance" or rule.faction == "Horde") and rule.faction or nil
    if UDDM_SetText and panels.text._textFactionDrop then
      UDDM_SetText(panels.text._textFactionDrop, panels.text._faction and tostring(panels.text._faction) or "Both (Off)")
    end

    panels.text._color = rule.color
    if UDDM_SetText and panels.text._textColorDrop then
      UDDM_SetText(panels.text._textColorDrop, ColorToNameLite(rule.color))
    end

    local repFactionID = 0
    local repMin = nil
    if type(rule.rep) == "table" and rule.rep.factionID then
      repFactionID = tonumber(rule.rep.factionID) or 0
      repMin = tonumber(rule.rep.minStanding)
    end
    if panels.text._repFactionBox then panels.text._repFactionBox:SetText(tostring(repFactionID or 0)) end
    panels.text._repMinStanding = repMin
    if UDDM_SetText and panels.text._repMinDrop then UDDM_SetText(panels.text._repMinDrop, RepStandingLabelLite(repMin)) end
    if panels.text._restedOnly then panels.text._restedOnly:SetChecked(rule.restedOnly and true or false) end
    if panels.text._locBox then panels.text._locBox:SetText(tostring(rule.locationID or "0")) end

    panels.text._playerLevelOp = (rule.playerLevelOp == "<" or rule.playerLevelOp == "<=" or rule.playerLevelOp == "=" or rule.playerLevelOp == ">=" or rule.playerLevelOp == ">" or rule.playerLevelOp == "!=") and rule.playerLevelOp or nil
    if UDDM_SetText and textLevelOpDrop then UDDM_SetText(textLevelOpDrop, panels.text._playerLevelOp or "Off") end
    if textLevelBox then textLevelBox:SetText(tostring(tonumber(rule.playerLevel) or 0)) end
  end

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
  SetCheckButtonLabel(reqInLog, "In log")

  local hideComp = CreateFrame("CheckButton", nil, panels.rules, "UICheckButtonTemplate")
  hideComp:SetPoint("TOPLEFT", 460, -69)
  SetCheckButtonLabel(hideComp, "Hide done")
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

  local viewLabel = panels.rules:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  viewLabel:SetPoint("TOPLEFT", 410, -46)
  viewLabel:SetText("View")

  local rulesViewDrop = CreateFrame("Frame", nil, panels.rules, "UIDropDownMenuTemplate")
  rulesViewDrop:SetPoint("TOPLEFT", 440, -60)
  if UDDM_SetWidth then UDDM_SetWidth(rulesViewDrop, 120) end
  if UDDM_SetText then UDDM_SetText(rulesViewDrop, "All") end
  f._rulesViewDrop = rulesViewDrop

  local function GetRulesView()
    if not optionsFrame then return "all" end
    local v = tostring(optionsFrame._rulesView or GetUISetting("rulesView", "all") or "all")
    if v ~= "all" and v ~= "custom" and v ~= "defaults" and v ~= "trash" then v = "all" end
    return v
  end

  local function SetRulesView(v)
    if not optionsFrame then return end
    v = tostring(v or "all")
    if v ~= "all" and v ~= "custom" and v ~= "defaults" and v ~= "trash" then v = "all" end
    optionsFrame._rulesView = v
    SetUISetting("rulesView", v)
    if UDDM_SetText then
      UDDM_SetText(rulesViewDrop, (v == "all") and "All" or (v == "defaults") and "Defaults" or (v == "trash") and "Trash" or "Custom")
    end
    RefreshRulesList()
  end

  f._rulesView = tostring(GetUISetting("rulesView", "all") or "all")

  local addRuleBtn = CreateFrame("Button", nil, panels.rules, "UIPanelButtonTemplate")
  addRuleBtn:SetSize(90, 22)
  addRuleBtn:SetPoint("TOPLEFT", 12, -122)
  addRuleBtn:SetText("New Rule")
  addRuleBtn:Hide()

  -- Legacy inline editor controls are hidden; create/edit happens in the type-specific tabs.
  qBox:Hide(); labelBox:Hide(); frameBox:Hide(); reqInLog:Hide(); hideComp:Hide(); prereqLabel:Hide(); prereqBox:Hide(); groupLabel:Hide(); groupBox:Hide(); orderLabel:Hide(); orderBox:Hide()

  local hint = panels.rules:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  hint:SetPoint("TOPLEFT", 110, -127)
  hint:SetText("Create rules using the Quest / Items / Spell / Text tabs. Use this list to enable/disable and edit.")

  local function RepStandingLabel(standing)
    standing = tonumber(standing)
    if not standing then return "Off" end
    if standing == 5 then return "Friendly" end
    if standing == 6 then return "Honored" end
    if standing == 7 then return "Revered" end
    if standing == 8 then return "Exalted" end
    return tostring(standing)
  end

  local function ColorToName(color)
    if type(color) ~= "table" then return "None" end
    local r, g, b = tonumber(color[1]), tonumber(color[2]), tonumber(color[3])
    if r == 0.1 and g == 1.0 and b == 0.1 then return "Green" end
    if r == 0.2 and g == 0.6 and b == 1.0 then return "Blue" end
    if r == 1.0 and g == 0.9 and b == 0.2 then return "Yellow" end
    if r == 1.0 and g == 0.2 and b == 0.2 then return "Red" end
    if r == 0.2 and g == 1.0 and b == 1.0 then return "Cyan" end
    return "None"
  end

  local function NameToColor(name)
    name = tostring(name or "None")
    if name == "Green" then return { 0.1, 1.0, 0.1 } end
    if name == "Blue" then return { 0.2, 0.6, 1.0 } end
    if name == "Yellow" then return { 1.0, 0.9, 0.2 } end
    if name == "Red" then return { 1.0, 0.2, 0.2 } end
    if name == "Cyan" then return { 0.2, 1.0, 1.0 } end
    return nil
  end

  local function ParsePrereqList(text)
    local prereq = nil
    local t = tostring(text or "")
    t = t:gsub(";", ",")
    for token in t:gmatch("[^,%s]+") do
      local n = tonumber(token)
      if n and n > 0 then
        prereq = prereq or {}
        prereq[#prereq + 1] = n
      end
    end
    return prereq
  end

  local function PrereqListToText(prereq)
    if type(prereq) ~= "table" then return "" end
    local out = {}
    for _, n in ipairs(prereq) do
      local v = tonumber(n)
      if v and v > 0 then out[#out + 1] = tostring(v) end
    end
    return table.concat(out, ",")
  end

  local function DetectRuleType(r)
    if type(r) ~= "table" then return "text" end
    if tonumber(r.questID) and tonumber(r.questID) > 0 then return "quest" end
    if type(r.item) == "table" and r.item.itemID then return "item" end
    if r.spellKnown or r.notSpellKnown or r.locationID or r.class or r.notInGroup then return "spell" end
    return "text"
  end

  local ENABLE_RULE_EDITOR_OVERLAY = false

  local function EnsureRuleEditor()
    if not ENABLE_RULE_EDITOR_OVERLAY then return nil end
    if optionsFrame and optionsFrame._ruleEditorFrame then return optionsFrame._ruleEditorFrame end
    if not optionsFrame then return nil end

    local ed = CreateFrame("Frame", nil, optionsFrame, "BackdropTemplate")
    ed:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 12, -40)
    ed:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOMRIGHT", -12, 44)
    ed:SetFrameStrata("DIALOG")
    ed:SetClampedToScreen(true)
    ApplyFAOBackdrop(ed, 0.9)
    ed:Hide()
    ed._skipRestore = false

    ed:HookScript("OnShow", function(self)
      if not optionsFrame then return end
      optionsFrame._tabBeforeRuleEditor = optionsFrame._tabBeforeRuleEditor or optionsFrame._activeTab or "rules"
      for _, p in pairs(panels) do
        if p and p.Hide then p:Hide() end
      end
      for _, btn in ipairs(tabs) do
        if btn and btn.SetEnabled then btn:SetEnabled(false) end
      end
    end)

    ed:HookScript("OnHide", function(self)
      if self._skipRestore then
        self._skipRestore = false
        return
      end
      if not optionsFrame or not optionsFrame.IsShown or not optionsFrame:IsShown() then return end

      for _, btn in ipairs(tabs) do
        if btn and btn.SetEnabled then btn:SetEnabled(true) end
      end

      local prev = tostring(optionsFrame._tabBeforeRuleEditor or "rules")
      optionsFrame._tabBeforeRuleEditor = nil
      if not panels[prev] then prev = "rules" end
      SelectTab(prev)
    end)

    local title = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 12, -10)
    title:SetText("Rule Editor")
    ed._title = title

    local close = CreateFrame("Button", nil, ed, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", ed, "TOPRIGHT", 2, 2)

    local typeLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    typeLabel:SetPoint("TOPLEFT", 12, -36)
    typeLabel:SetText("Type")

    local typeDrop = CreateFrame("Frame", nil, ed, "UIDropDownMenuTemplate")
    typeDrop:SetPoint("TOPLEFT", -8, -56)
    if UDDM_SetWidth then UDDM_SetWidth(typeDrop, 150) end
    if UDDM_SetText then UDDM_SetText(typeDrop, "Text") end
    ed._typeDrop = typeDrop
    ed._type = "text"

    local frameLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frameLabel:SetPoint("TOPLEFT", 180, -36)
    frameLabel:SetText("FrameID")

    local frameIDBox = CreateFrame("EditBox", nil, ed, "InputBoxTemplate")
    frameIDBox:SetSize(90, 20)
    frameIDBox:SetPoint("TOPLEFT", 180, -52)
    frameIDBox:SetAutoFocus(false)
    frameIDBox:SetText("list1")
    ed._frameIDBox = frameIDBox

    local labelLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    labelLabel:SetPoint("TOPLEFT", 280, -36)
    labelLabel:SetText("Custom name")

    local labelEdit = CreateFrame("EditBox", nil, ed, "InputBoxTemplate")
    labelEdit:SetSize(220, 20)
    labelEdit:SetPoint("TOPLEFT", 280, -52)
    labelEdit:SetAutoFocus(false)
    labelEdit:SetText("")
    ed._labelEdit = labelEdit

    local factionLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    factionLabel:SetPoint("TOPLEFT", 12, -84)
    factionLabel:SetText("Faction")

    local factionDrop = CreateFrame("Frame", nil, ed, "UIDropDownMenuTemplate")
    factionDrop:SetPoint("TOPLEFT", -8, -104)
    if UDDM_SetWidth then UDDM_SetWidth(factionDrop, 150) end
    if UDDM_SetText then UDDM_SetText(factionDrop, "Both (Off)") end
    ed._factionDrop = factionDrop
    ed._faction = nil

    local colorLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    colorLabel:SetPoint("TOPLEFT", 180, -84)
    colorLabel:SetText("Color")

    local colorDrop = CreateFrame("Frame", nil, ed, "UIDropDownMenuTemplate")
    colorDrop:SetPoint("TOPLEFT", 165, -104)
    if UDDM_SetWidth then UDDM_SetWidth(colorDrop, 150) end
    if UDDM_SetText then UDDM_SetText(colorDrop, "None") end
    ed._colorDrop = colorDrop
    ed._colorName = "None"

    local restedOnly = CreateFrame("CheckButton", nil, ed, "UICheckButtonTemplate")
    restedOnly:SetPoint("TOPLEFT", 330, -104)
    SetCheckButtonLabel(restedOnly, "Rested only")
    restedOnly:SetChecked(false)
    ed._restedOnly = restedOnly

    local hideDone = CreateFrame("CheckButton", nil, ed, "UICheckButtonTemplate")
    hideDone:SetPoint("TOPLEFT", 430, -104)
    SetCheckButtonLabel(hideDone, "Hide done")
    hideDone:SetChecked(false)
    ed._hideDone = hideDone

    local levelLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    levelLabel:SetPoint("TOPLEFT", 330, -84)
    levelLabel:SetText("Player level")

    local levelOpDrop = CreateFrame("Frame", nil, ed, "UIDropDownMenuTemplate")
    levelOpDrop:SetPoint("TOPLEFT", 315, -104)
    if UDDM_SetWidth then UDDM_SetWidth(levelOpDrop, 70) end
    if UDDM_SetText then UDDM_SetText(levelOpDrop, "Off") end
    ed._playerLevelOpDrop = levelOpDrop
    ed._playerLevelOp = nil

    local levelBox = CreateFrame("EditBox", nil, ed, "InputBoxTemplate")
    levelBox:SetSize(50, 20)
    levelBox:SetPoint("TOPLEFT", 420, -100)
    levelBox:SetAutoFocus(false)
    levelBox:SetNumeric(true)
    levelBox:SetText("0")
    ed._playerLevelBox = levelBox

    local repFactionLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    repFactionLabel:SetPoint("TOPLEFT", 12, -132)
    repFactionLabel:SetText("Rep FactionID")

    local repFactionBox = CreateFrame("EditBox", nil, ed, "InputBoxTemplate")
    repFactionBox:SetSize(90, 20)
    repFactionBox:SetPoint("TOPLEFT", 12, -148)
    repFactionBox:SetAutoFocus(false)
    repFactionBox:SetNumeric(true)
    repFactionBox:SetText("0")
    ed._repFactionBox = repFactionBox

    local repMinLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    repMinLabel:SetPoint("TOPLEFT", 110, -132)
    repMinLabel:SetText("Min Rep")

    local repMinDrop = CreateFrame("Frame", nil, ed, "UIDropDownMenuTemplate")
    repMinDrop:SetPoint("TOPLEFT", 95, -160)
    if UDDM_SetWidth then UDDM_SetWidth(repMinDrop, 150) end
    if UDDM_SetText then UDDM_SetText(repMinDrop, "Off") end
    ed._repMinDrop = repMinDrop
    ed._repMinStanding = nil

    local hideExalted = CreateFrame("CheckButton", nil, ed, "UICheckButtonTemplate")
    hideExalted:SetPoint("TOPLEFT", 250, -152)
    SetCheckButtonLabel(hideExalted, "Hide when exalted")
    hideExalted:SetChecked(false)
    ed._hideExalted = hideExalted

    local questGroup = CreateFrame("Frame", nil, ed)
    questGroup:SetPoint("TOPLEFT", 12, -190)
    questGroup:SetPoint("TOPRIGHT", -12, -190)
    questGroup:SetHeight(90)
    ed._questGroup = questGroup

    local questIDLabel = questGroup:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    questIDLabel:SetPoint("TOPLEFT", 0, 0)
    questIDLabel:SetText("QuestID")

    local questIDBox = CreateFrame("EditBox", nil, questGroup, "InputBoxTemplate")
    questIDBox:SetSize(90, 20)
    questIDBox:SetPoint("TOPLEFT", 0, -16)
    questIDBox:SetAutoFocus(false)
    questIDBox:SetNumeric(true)
    questIDBox:SetText("0")
    ed._questIDBox = questIDBox

    local reqInLog2 = CreateFrame("CheckButton", nil, questGroup, "UICheckButtonTemplate")
    reqInLog2:SetPoint("TOPLEFT", 100, -16)
    SetCheckButtonLabel(reqInLog2, "In log")
    reqInLog2:SetChecked(false)
    ed._reqInLog = reqInLog2

    local prereq2Label = questGroup:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    prereq2Label:SetPoint("TOPLEFT", 0, -44)
    prereq2Label:SetText("Prereq questIDs")

    local prereq2Box = CreateFrame("EditBox", nil, questGroup, "InputBoxTemplate")
    prereq2Box:SetSize(200, 20)
    prereq2Box:SetPoint("TOPLEFT", 0, -60)
    prereq2Box:SetAutoFocus(false)
    prereq2Box:SetText("")
    ed._prereqBox = prereq2Box

    local group2Label = questGroup:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    group2Label:SetPoint("TOPLEFT", 210, -44)
    group2Label:SetText("Group")

    local group2Box = CreateFrame("EditBox", nil, questGroup, "InputBoxTemplate")
    group2Box:SetSize(120, 20)
    group2Box:SetPoint("TOPLEFT", 210, -60)
    group2Box:SetAutoFocus(false)
    group2Box:SetText("")
    ed._groupBox = group2Box

    local order2Label = questGroup:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    order2Label:SetPoint("TOPLEFT", 340, -44)
    order2Label:SetText("Order")

    local order2Box = CreateFrame("EditBox", nil, questGroup, "InputBoxTemplate")
    order2Box:SetSize(60, 20)
    order2Box:SetPoint("TOPLEFT", 340, -60)
    order2Box:SetAutoFocus(false)
    order2Box:SetNumeric(true)
    order2Box:SetText("0")
    ed._orderBox = order2Box

    local itemGroup = CreateFrame("Frame", nil, ed)
    itemGroup:SetPoint("TOPLEFT", 12, -190)
    itemGroup:SetPoint("TOPRIGHT", -12, -190)
    itemGroup:SetHeight(60)
    ed._itemGroup = itemGroup

    local itemIDLabel = itemGroup:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    itemIDLabel:SetPoint("TOPLEFT", 0, 0)
    itemIDLabel:SetText("ItemID")

    local itemIDBox = CreateFrame("EditBox", nil, itemGroup, "InputBoxTemplate")
    itemIDBox:SetSize(90, 20)
    itemIDBox:SetPoint("TOPLEFT", 0, -16)
    itemIDBox:SetAutoFocus(false)
    itemIDBox:SetNumeric(true)
    itemIDBox:SetText("0")
    ed._itemIDBox = itemIDBox

    local hideAcq = CreateFrame("CheckButton", nil, itemGroup, "UICheckButtonTemplate")
    hideAcq:SetPoint("TOPLEFT", 100, -18)
    SetCheckButtonLabel(hideAcq, "Hide when acquired")
    hideAcq:SetChecked(false)
    ed._hideAcquired = hideAcq

    local spellGroup = CreateFrame("Frame", nil, ed)
    spellGroup:SetPoint("TOPLEFT", 12, -190)
    spellGroup:SetPoint("TOPRIGHT", -12, -190)
    spellGroup:SetHeight(90)
    ed._spellGroup = spellGroup

    local class2Label = spellGroup:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    class2Label:SetPoint("TOPLEFT", 0, 0)
    class2Label:SetText("Class")

    local classDrop2 = CreateFrame("Frame", nil, spellGroup, "UIDropDownMenuTemplate")
    classDrop2:SetPoint("TOPLEFT", -8, -20)
    if UDDM_SetWidth then UDDM_SetWidth(classDrop2, 150) end
    if UDDM_SetText then UDDM_SetText(classDrop2, "None") end
    ed._classDrop = classDrop2
    ed._class = nil

    local known2Label = spellGroup:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    known2Label:SetPoint("TOPLEFT", 160, 0)
    known2Label:SetText("Spell Known")

    local known2Box = CreateFrame("EditBox", nil, spellGroup, "InputBoxTemplate")
    known2Box:SetSize(90, 20)
    known2Box:SetPoint("TOPLEFT", 160, -16)
    known2Box:SetAutoFocus(false)
    known2Box:SetNumeric(true)
    known2Box:SetText("0")
    ed._spellKnownBox = known2Box

    local notKnown2Label = spellGroup:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    notKnown2Label:SetPoint("TOPLEFT", 260, 0)
    notKnown2Label:SetText("Not Known")

    local notKnown2Box = CreateFrame("EditBox", nil, spellGroup, "InputBoxTemplate")
    notKnown2Box:SetSize(90, 20)
    notKnown2Box:SetPoint("TOPLEFT", 260, -16)
    notKnown2Box:SetAutoFocus(false)
    notKnown2Box:SetNumeric(true)
    notKnown2Box:SetText("0")
    ed._notSpellKnownBox = notKnown2Box

    local loc2Label = spellGroup:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    loc2Label:SetPoint("TOPLEFT", 360, 0)
    loc2Label:SetText("LocationID")

    local loc2Box = CreateFrame("EditBox", nil, spellGroup, "InputBoxTemplate")
    loc2Box:SetSize(90, 20)
    loc2Box:SetPoint("TOPLEFT", 360, -16)
    loc2Box:SetAutoFocus(false)
    loc2Box:SetText("0")
    ed._locationIDBox = loc2Box

    local notInGroup2 = CreateFrame("CheckButton", nil, spellGroup, "UICheckButtonTemplate")
    notInGroup2:SetPoint("TOPLEFT", 0, -44)
    SetCheckButtonLabel(notInGroup2, "Not in group")
    notInGroup2:SetChecked(false)
    ed._notInGroup = notInGroup2

    local function ShowType(t)
      ed._type = t
      if ed._questGroup then ed._questGroup:SetShown(t == "quest") end
      if ed._itemGroup then ed._itemGroup:SetShown(t == "item") end
      if ed._spellGroup then ed._spellGroup:SetShown(t == "spell") end
    end
    ed._showType = ShowType

    if UDDM_Initialize and UDDM_CreateInfo and UDDM_AddButton then
      UDDM_Initialize(typeDrop, function(self, level)
        local function Add(name, t)
          local info = UDDM_CreateInfo()
          info.text = name
          info.checked = (ed._type == t) and true or false
          info.func = function()
            if UDDM_SetText then UDDM_SetText(typeDrop, name) end
            ShowType(t)
          end
          UDDM_AddButton(info)
        end
        Add("Quest", "quest")
        Add("Item", "item")
        Add("Text", "text")
        Add("Spell", "spell")
      end)

      UDDM_Initialize(factionDrop, function(self, level)
        local function Add(name, v)
          local info = UDDM_CreateInfo()
          info.text = name
          info.checked = (ed._faction == v) and true or false
          info.func = function()
            ed._faction = v
            if UDDM_SetText then UDDM_SetText(factionDrop, name) end
          end
          UDDM_AddButton(info)
        end
        Add("Both (Off)", nil)
        Add("Alliance", "Alliance")
        Add("Horde", "Horde")
      end)

      UDDM_Initialize(colorDrop, function(self, level)
        for _, name in ipairs({ "None", "Green", "Blue", "Yellow", "Red", "Cyan" }) do
          local info = UDDM_CreateInfo()
          info.text = name
          info.checked = (ed._colorName == name) and true or false
          info.func = function()
            ed._colorName = name
            if UDDM_SetText then UDDM_SetText(colorDrop, name) end
          end
          UDDM_AddButton(info)
        end
      end)

      UDDM_Initialize(repMinDrop, function(self, level)
        local function Add(name, standing)
          local info = UDDM_CreateInfo()
          info.text = name
          info.checked = (ed._repMinStanding == standing) and true or false
          info.func = function()
            ed._repMinStanding = standing
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

      UDDM_Initialize(levelOpDrop, function(self, level)
        local function Add(name, op)
          local info = UDDM_CreateInfo()
          info.text = name
          info.checked = (ed._playerLevelOp == op) and true or false
          info.func = function()
            ed._playerLevelOp = op
            if UDDM_SetText then UDDM_SetText(levelOpDrop, name) end
          end
          UDDM_AddButton(info)
        end
        Add("Off", nil)
        Add("<", "<")
        Add("<=", "<=")
        Add("=", "=")
        Add(">=", ">=")
        Add(">", ">")
        Add("!=", "!=")
      end)

      UDDM_Initialize(classDrop2, function(self, level)
        do
          local info = UDDM_CreateInfo()
          info.text = "None"
          info.checked = (ed._class == nil) and true or false
          info.func = function()
            ed._class = nil
            if UDDM_SetText then UDDM_SetText(classDrop2, "None") end
          end
          UDDM_AddButton(info)
        end

        for _, tok in ipairs({
          "DEATHKNIGHT","DEMONHUNTER","DRUID","EVOKER","HUNTER","MAGE","MONK","PALADIN","PRIEST","ROGUE","SHAMAN","WARLOCK","WARRIOR",
        }) do
          local info = UDDM_CreateInfo()
          info.text = tok
          info.checked = (ed._class == tok) and true or false
          info.func = function()
            ed._class = tok
            if UDDM_SetText then UDDM_SetText(classDrop2, tok) end
          end
          UDDM_AddButton(info)
        end
      end)
    end

    local saveBtn = CreateFrame("Button", nil, ed, "UIPanelButtonTemplate")
    saveBtn:SetSize(120, 22)
    saveBtn:SetPoint("BOTTOMRIGHT", -12, 12)
    saveBtn:SetText("Save")
    ed._saveBtn = saveBtn

    local cancelBtn = CreateFrame("Button", nil, ed, "UIPanelButtonTemplate")
    cancelBtn:SetSize(120, 22)
    cancelBtn:SetPoint("RIGHT", saveBtn, "LEFT", -8, 0)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", function() ed:Hide() end)

    ShowType("text")

    optionsFrame._ruleEditorFrame = ed
    return ed
  end

  local function OpenRuleEditor(mode, customIndex)
    if not ENABLE_RULE_EDITOR_OVERLAY then
      -- Overlay editor is disabled; always edit using the main tabs.
      if mode == "edit" and customIndex then
        OpenCustomRuleInTab(customIndex)
      else
        SelectTab("quest")
      end
      return
    end
    if not optionsFrame then return end
    local ed = EnsureRuleEditor()
    if not ed then return end

    local rules = GetCustomRules()
    local src = (mode == "edit") and rules[customIndex] or nil
    if mode == "edit" and type(src) ~= "table" then return end
    local r = src or {}

    ed._mode = mode
    ed._customIndex = (mode == "edit") and customIndex or nil
    ed._existingKey = (mode == "edit" and r.key ~= nil) and tostring(r.key) or nil

    local t = (mode == "edit") and DetectRuleType(r) or "text"
    ed._showType(t)

    local typeName = (t == "quest") and "Quest" or (t == "item") and "Item" or (t == "spell") and "Spell" or "Text"
    if UDDM_SetText and ed._typeDrop then UDDM_SetText(ed._typeDrop, typeName) end

    ed._frameIDBox:SetText(tostring((mode == "edit" and r.frameID) or "list1"))
    ed._labelEdit:SetText(tostring((mode == "edit" and r.label) or ""))

    ed._faction = (mode == "edit") and ((r.faction == "Alliance" or r.faction == "Horde") and r.faction or nil) or nil
    if UDDM_SetText and ed._factionDrop then
      UDDM_SetText(ed._factionDrop, ed._faction and tostring(ed._faction) or "Both (Off)")
    end

    ed._colorName = (mode == "edit") and ColorToName(r.color) or "None"
    if UDDM_SetText and ed._colorDrop then UDDM_SetText(ed._colorDrop, ed._colorName) end

    ed._restedOnly:SetChecked((mode == "edit" and r.restedOnly == true) and true or false)
    ed._hideDone:SetChecked((mode == "edit" and r.hideWhenCompleted == true) and true or false)

    ed._playerLevelOp = (mode == "edit") and r.playerLevelOp or nil
    if UDDM_SetText and ed._playerLevelOpDrop then
      UDDM_SetText(ed._playerLevelOpDrop, ed._playerLevelOp and tostring(ed._playerLevelOp) or "Off")
    end
    if ed._playerLevelBox then
      ed._playerLevelBox:SetText(tostring((mode == "edit" and tonumber(r.playerLevel)) or 0))
    end

    local repFactionID = 0
    local repMin = nil
    local repHideEx = false
    if mode == "edit" and type(r.rep) == "table" and r.rep.factionID then
      local rep = r.rep
      repFactionID = tonumber(rep.factionID) or 0
      repMin = tonumber(rep.minStanding)
      repHideEx = (rep.hideWhenExalted == true)
    end
    ed._repFactionBox:SetText(tostring(repFactionID or 0))
    ed._repMinStanding = repMin
    if UDDM_SetText and ed._repMinDrop then UDDM_SetText(ed._repMinDrop, RepStandingLabel(repMin)) end
    ed._hideExalted:SetChecked(repHideEx and true or false)

    if t == "quest" then
      ed._questIDBox:SetText(tostring((mode == "edit" and tonumber(r.questID)) or 0))
      ed._reqInLog:SetChecked((mode == "edit" and r.requireInLog == true) and true or false)
      ed._prereqBox:SetText((mode == "edit") and PrereqListToText(r.prereq) or "")
      ed._groupBox:SetText((mode == "edit") and tostring(r.group or "") or "")
      ed._orderBox:SetText(tostring((mode == "edit" and tonumber(r.order)) or 0))
      if mode ~= "edit" then
        ed._hideDone:SetChecked(true)
      end
    elseif t == "item" then
      local itemID = (mode == "edit" and type(r.item) == "table" and tonumber(r.item.itemID)) or 0
      ed._itemIDBox:SetText(tostring(itemID or 0))
      ed._hideAcquired:SetChecked((mode == "edit" and type(r.item) == "table" and r.item.hideWhenAcquired == true) and true or false)
      if mode ~= "edit" then
        ed._hideDone:SetChecked(false)
      end
    elseif t == "spell" then
      ed._class = (mode == "edit") and r.class or nil
      if UDDM_SetText and ed._classDrop then UDDM_SetText(ed._classDrop, ed._class or "None") end
      ed._spellKnownBox:SetText(tostring((mode == "edit" and tonumber(r.spellKnown)) or 0))
      ed._notSpellKnownBox:SetText(tostring((mode == "edit" and tonumber(r.notSpellKnown)) or 0))
      ed._locationIDBox:SetText(tostring((mode == "edit" and r.locationID) or "0"))
      ed._notInGroup:SetChecked((mode == "edit" and r.notInGroup == true) and true or false)
      if mode ~= "edit" then
        ed._hideDone:SetChecked(false)
      end
    else
      if mode ~= "edit" then
        ed._hideDone:SetChecked(false)
      end
    end

    ed._title:SetText((mode == "edit") and "Edit Rule" or "New Rule")
    ed:Show()
  end

  addRuleBtn:SetScript("OnClick", nil)

  local function ParsePrereqList(text)
    local prereq = nil
    local t = tostring(text or "")
    t = t:gsub(";", ",")
    for token in t:gmatch("[^,%s]+") do
      local n = tonumber(token)
      if n and n > 0 then
        prereq = prereq or {}
        prereq[#prereq + 1] = n
      end
    end
    return prereq
  end

  local function PrereqListToText(prereq)
    if type(prereq) ~= "table" then return "" end
    local out = {}
    for _, n in ipairs(prereq) do
      local v = tonumber(n)
      if v and v > 0 then out[#out + 1] = tostring(v) end
    end
    return table.concat(out, ",")
  end

  do
    local ed = EnsureRuleEditor()
    if ed and ed._saveBtn then
      ed._saveBtn:SetScript("OnClick", function()
        local rules = GetCustomRules()

        local t = tostring(ed._type or "text")
        if t ~= "quest" and t ~= "item" and t ~= "spell" and t ~= "text" then t = "text" end

        local frameID = tostring(ed._frameIDBox:GetText() or "")
        frameID = frameID:gsub("%s+", "")
        if frameID == "" then frameID = "list1" end

        local labelText = tostring(ed._labelEdit:GetText() or "")
        labelText = labelText:gsub("^%s+", ""):gsub("%s+$", "")
        local label = (labelText ~= "") and labelText or nil

        local repFactionID = tonumber(ed._repFactionBox:GetText() or "")
        if repFactionID and repFactionID <= 0 then repFactionID = nil end
        local rep = nil
        if repFactionID and ed._repMinStanding then
          rep = { factionID = repFactionID, minStanding = ed._repMinStanding, hideWhenExalted = ed._hideExalted:GetChecked() and true or false }
        elseif repFactionID and ed._hideExalted:GetChecked() then
          rep = { factionID = repFactionID, hideWhenExalted = true }
        end

        local function ApplyCommon(rule)
          rule.frameID = frameID
          rule.faction = (ed._faction == "Alliance" or ed._faction == "Horde") and ed._faction or nil
          rule.color = NameToColor(ed._colorName)
          rule.restedOnly = ed._restedOnly:GetChecked() and true or false
          rule.hideWhenCompleted = ed._hideDone:GetChecked() and true or false
          rule.rep = rep
          rule.label = label

          local op = ed._playerLevelOp
          local lvl = ed._playerLevelBox and tonumber(ed._playerLevelBox:GetText() or "") or nil
          if lvl and lvl <= 0 then lvl = nil end
          if op and lvl then
            rule.playerLevelOp = op
            rule.playerLevel = lvl
          else
            rule.playerLevelOp = nil
            rule.playerLevel = nil
          end
        end

        local rule
        if ed._mode == "edit" and ed._customIndex and type(rules[ed._customIndex]) == "table" then
          rule = rules[ed._customIndex]
        else
          rule = {}
          rules[#rules + 1] = rule
        end

        ApplyCommon(rule)

        -- Clear type-specific fields first.
        rule.questID = nil
        rule.requireInLog = nil
        rule.prereq = nil
        rule.group = nil
        rule.order = nil
        rule.item = nil
        rule.spellKnown = nil
        rule.notSpellKnown = nil
        rule.locationID = nil
        rule.notInGroup = nil
        rule.class = nil

        if t == "quest" then
          local questID = tonumber(ed._questIDBox:GetText() or "")
          if not questID or questID <= 0 then
            Print("Enter a questID > 0.")
            return
          end
          rule.questID = questID
          rule.requireInLog = ed._reqInLog:GetChecked() and true or false
          rule.prereq = ParsePrereqList(ed._prereqBox:GetText())

          local g = tostring(ed._groupBox:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", "")
          if g ~= "" then rule.group = g end
          rule.order = tonumber(ed._orderBox:GetText() or "")
        elseif t == "item" then
          local itemID = tonumber(ed._itemIDBox:GetText() or "")
          if not itemID or itemID <= 0 then
            Print("Enter an itemID > 0.")
            return
          end
          rule.item = {
            itemID = itemID,
            required = 1,
            hideWhenAcquired = ed._hideAcquired:GetChecked() and true or false,
          }
        elseif t == "spell" then
          local known = tonumber(ed._spellKnownBox:GetText() or "")
          if known and known <= 0 then known = nil end
          local notKnown = tonumber(ed._notSpellKnownBox:GetText() or "")
          if notKnown and notKnown <= 0 then notKnown = nil end
          if not known and not notKnown then
            Print("Enter Spell Known and/or Not Known.")
            return
          end
          if known then rule.spellKnown = known end
          if notKnown then rule.notSpellKnown = notKnown end
          rule.class = ed._class
          rule.notInGroup = ed._notInGroup:GetChecked() and true or false

          local locText = tostring(ed._locationIDBox:GetText() or ""):gsub("%s+", "")
          rule.locationID = (locText ~= "" and locText ~= "0") and locText or nil
        else
          if not label then
            Print("Enter some text in Label.")
            return
          end
        end

        local key = (ed._existingKey and tostring(ed._existingKey)) or nil
        if not key or key == "" then
          rule.key = MakeUniqueRuleKey("custom:" .. t)
        else
          rule.key = key
        end
        EnsureUniqueKeyForCustomRule(rule)

        CreateAllFrames()
        RefreshAll()
        RefreshRulesList()
        ed:Hide()
        Print("Saved rule.")
      end)
    end
  end

  if UDDM_Initialize and UDDM_CreateInfo and UDDM_AddButton then
    UDDM_Initialize(rulesViewDrop, function(self, level)
      for _, v in ipairs({ "all", "custom", "defaults", "trash" }) do
        local info = UDDM_CreateInfo()
        info.text = (v == "all") and "All" or (v == "defaults") and "Defaults" or (v == "trash") and "Trash" or "Custom"
        info.checked = (GetRulesView() == v) and true or false
        info.func = function() SetRulesView(v) end
        UDDM_AddButton(info)
      end
    end)
  else
    viewLabel:SetText("View (dropdown unavailable)")
  end

  local rulesScroll = CreateFrame("ScrollFrame", nil, panels.rules, "UIPanelScrollFrameTemplate")
  rulesScroll:SetPoint("TOPLEFT", 12, -152)
  rulesScroll:SetPoint("BOTTOMLEFT", 12, 44)
  rulesScroll:SetWidth(530)
  f._rulesScroll = rulesScroll

  local rulesContent = CreateFrame("Frame", nil, rulesScroll)
  rulesContent:SetSize(1, 1)
  rulesScroll:SetScrollChild(rulesContent)
  rulesScroll:SetScript("OnSizeChanged", function(self)
    if not optionsFrame or not optionsFrame._rulesContent then return end
    local w = tonumber(self:GetWidth() or 0) or 0
    optionsFrame._rulesContent:SetWidth(math.max(1, w - 28))
  end)
  f._rulesContent = rulesContent
  f._ruleRows = {}

  -- FRAMES tab
  local framesTitle = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  framesTitle:SetPoint("TOPLEFT", 12, -40)
  framesTitle:SetText("Custom Frames")

  local UDDM_SetWidth = _G and rawget(_G, "UIDropDownMenu_SetWidth")
  local UDDM_SetText = _G and rawget(_G, "UIDropDownMenu_SetText")
  local UDDM_Initialize = _G and rawget(_G, "UIDropDownMenu_Initialize")
  local UDDM_CreateInfo = _G and rawget(_G, "UIDropDownMenu_CreateInfo")
  local UDDM_AddButton = _G and rawget(_G, "UIDropDownMenu_AddButton")
  local UDDM_Enable = _G and rawget(_G, "UIDropDownMenu_EnableDropDown")
  local UDDM_Disable = _G and rawget(_G, "UIDropDownMenu_DisableDropDown")

  local function SetDropDownEnabled(dropdown, enabled)
    if not dropdown then return end
    enabled = enabled and true or false

    if UDDM_Enable and UDDM_Disable then
      if enabled then
        UDDM_Enable(dropdown)
      else
        UDDM_Disable(dropdown)
      end
      return
    end

    if dropdown.EnableMouse then dropdown:EnableMouse(enabled) end
    if dropdown.SetAlpha then dropdown:SetAlpha(enabled and 1 or 0.5) end
  end

  -- Global List Grow control
  local listGrowAuto = CreateFrame("CheckButton", nil, panels.frames, "UICheckButtonTemplate")
  listGrowAuto:SetPoint("TOPLEFT", 365, -70)
  SetCheckButtonLabel(listGrowAuto, "List grow from anchor")

  local listGrowDrop = CreateFrame("Frame", nil, panels.frames, "UIDropDownMenuTemplate")
  listGrowDrop:SetPoint("TOPLEFT", 350, -86)
  if UDDM_SetWidth then UDDM_SetWidth(listGrowDrop, 120) end
  if UDDM_SetText then UDDM_SetText(listGrowDrop, "anchor") end

  local function SetListGrow(v)
    v = tostring(v or "auto"):lower()
    if v ~= "auto" and v ~= "up" and v ~= "down" then v = "auto" end
    SetUISetting("listGrow", v)
    if listGrowAuto then listGrowAuto:SetChecked(v == "auto") end
    if UDDM_SetText then UDDM_SetText(listGrowDrop, (v == "auto") and "anchor" or v) end
    SetDropDownEnabled(listGrowDrop, v ~= "auto")
    RefreshAll()
  end

  listGrowAuto:SetScript("OnShow", function(self)
    local v = tostring(GetUISetting("listGrow", "auto") or "auto"):lower()
    if v ~= "auto" and v ~= "up" and v ~= "down" then v = "auto" end
    self:SetChecked(v == "auto")
    if UDDM_SetText then UDDM_SetText(listGrowDrop, (v == "auto") and "anchor" or v) end
    SetDropDownEnabled(listGrowDrop, v ~= "auto")
  end)

  listGrowAuto:SetScript("OnClick", function(self)
    if self:GetChecked() then
      SetListGrow("auto")
    else
      local prev = tostring(GetUISetting("listGrow", "auto") or "auto"):lower()
      if prev == "auto" then prev = tostring(GetUISetting("listGrowManual", "down") or "down"):lower() end
      if prev ~= "up" and prev ~= "down" then prev = "down" end
      SetUISetting("listGrowManual", prev)
      SetListGrow(prev)
    end
  end)

  if UDDM_Initialize and UDDM_CreateInfo and UDDM_AddButton then
    UDDM_Initialize(listGrowDrop, function(self, level)
      for _, v in ipairs({ "down", "up" }) do
        local info = UDDM_CreateInfo()
        info.text = v
        info.func = function()
          SetUISetting("listGrowManual", v)
          SetListGrow(v)
        end
        UDDM_AddButton(info)
      end
    end)
  end

  -- Global Bar Grow control (moved from General)
  local barGrowAuto = CreateFrame("CheckButton", nil, panels.frames, "UICheckButtonTemplate")
  barGrowAuto:SetPoint("TOPLEFT", 365, -96)
  SetCheckButtonLabel(barGrowAuto, "Bar grow from anchor")

  local barGrowDrop = CreateFrame("Frame", nil, panels.frames, "UIDropDownMenuTemplate")
  barGrowDrop:SetPoint("TOPLEFT", 350, -112)
  if UDDM_SetWidth then UDDM_SetWidth(barGrowDrop, 120) end
  if UDDM_SetText then UDDM_SetText(barGrowDrop, "anchor") end

  local function SetBarGrow(v)
    v = tostring(v or "auto"):lower()
    if v ~= "auto" and v ~= "left" and v ~= "right" and v ~= "center" then v = "auto" end
    SetUISetting("barGrow", v)
    if barGrowAuto then barGrowAuto:SetChecked(v == "auto") end
    if UDDM_SetText then UDDM_SetText(barGrowDrop, (v == "auto") and "anchor" or v) end
    SetDropDownEnabled(barGrowDrop, v ~= "auto")
    RefreshAll()
  end

  barGrowAuto:SetScript("OnShow", function(self)
    local v = tostring(GetUISetting("barGrow", "auto") or "auto"):lower()
    if v ~= "auto" and v ~= "left" and v ~= "right" and v ~= "center" then v = "auto" end
    self:SetChecked(v == "auto")
    if UDDM_SetText then UDDM_SetText(barGrowDrop, (v == "auto") and "anchor" or v) end
    SetDropDownEnabled(barGrowDrop, v ~= "auto")
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

  -- Global List Padding control
  local listPadLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  listPadLabel:SetPoint("TOPLEFT", 365, -132)
  listPadLabel:SetText("List padding (px)")

  local listPadBox = CreateFrame("EditBox", nil, panels.frames, "InputBoxTemplate")
  listPadBox:SetSize(40, 20)
  listPadBox:SetPoint("TOPLEFT", 365, -148)
  listPadBox:SetAutoFocus(false)
  listPadBox:SetNumeric(true)

  local function RefreshListPadBox(self)
    local v = tonumber(GetUISetting("listPadding", 0) or 0) or 0
    if v < 0 then v = 0 end
    if v > 50 then v = 50 end
    self:SetText(tostring(v))
  end

  listPadBox:SetScript("OnShow", function(self)
    RefreshListPadBox(self)
  end)
  listPadBox:SetScript("OnEnterPressed", function(self)
    local v = tonumber(self:GetText() or "") or 0
    if v < 0 then v = 0 end
    if v > 50 then v = 50 end
    SetUISetting("listPadding", v)
    RefreshListPadBox(self)
    if self.ClearFocus then self:ClearFocus() end
    RefreshAll()
  end)
  listPadBox:SetScript("OnEscapePressed", function(self)
    RefreshListPadBox(self)
    if self.ClearFocus then self:ClearFocus() end
  end)

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
      bgAlpha = 0,
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
  framesScroll:SetScript("OnSizeChanged", function(self)
    if not optionsFrame or not optionsFrame._framesContent then return end
    local w = tonumber(self:GetWidth() or 0) or 0
    optionsFrame._framesContent:SetWidth(math.max(1, w - 28))
  end)
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
  SetCheckButtonLabel(frameAuto, "Auto")
  f._frameAuto = frameAuto

  local nameLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  nameLabel:SetPoint("TOPLEFT", 12, -112)
  nameLabel:SetText("Name")
  f._frameNameLabel = nameLabel

  local nameBox = CreateFrame("EditBox", nil, panels.frames, "InputBoxTemplate")
  nameBox:SetSize(180, 20)
  nameBox:SetPoint("TOPLEFT", 55, -118)
  nameBox:SetAutoFocus(false)
  nameBox:SetText("")
  f._frameNameBox = nameBox

  local frameHideCombat = CreateFrame("CheckButton", nil, panels.frames, "UICheckButtonTemplate")
  frameHideCombat:SetPoint("TOPLEFT", 260, -102)
  SetCheckButtonLabel(frameHideCombat, "Hide in combat")
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

  local maxHLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  maxHLabel:SetPoint("TOPLEFT", 365, -130)
  maxHLabel:SetText("Max H")
  f._frameMaxHLabel = maxHLabel

  local maxHBox = CreateFrame("EditBox", nil, panels.frames, "InputBoxTemplate")
  maxHBox:SetSize(60, 20)
  maxHBox:SetPoint("TOPLEFT", 410, -136)
  maxHBox:SetAutoFocus(false)
  maxHBox:SetNumeric(true)
  maxHBox:SetText("0")
  f._frameMaxHBox = maxHBox

  -- Background (per-frame)
  local bgLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  bgLabel:SetPoint("TOPLEFT", 12, -160)
  bgLabel:SetText("Background")
  f._frameBgLabel = bgLabel

  local bgSwatch = CreateFrame("Button", nil, panels.frames)
  bgSwatch:SetSize(18, 18)
  bgSwatch:SetPoint("TOPLEFT", 85, -164)
  bgSwatch:EnableMouse(true)
  local swTex = bgSwatch:CreateTexture(nil, "ARTWORK")
  swTex:SetAllPoints()
  if swTex.SetColorTexture then
    swTex:SetColorTexture(0, 0, 0, 1)
  end
  bgSwatch._tex = swTex
  f._frameBgSwatch = bgSwatch

  local bgAlphaSlider = CreateFrame("Slider", "FR0Z3NUIFQT_BGAlphaSlider", panels.frames, "OptionsSliderTemplate")
  bgAlphaSlider:SetPoint("TOPLEFT", 115, -168)
  bgAlphaSlider:SetWidth(140)
  bgAlphaSlider:SetMinMaxValues(0, 1)
  bgAlphaSlider:SetValueStep(0.05)
  bgAlphaSlider:SetObeyStepOnDrag(true)
  bgAlphaSlider:SetValue(0)
  if _G["FR0Z3NUIFQT_BGAlphaSliderText"] then _G["FR0Z3NUIFQT_BGAlphaSliderText"]:SetText("Alpha") end
  if _G["FR0Z3NUIFQT_BGAlphaSliderLow"] then _G["FR0Z3NUIFQT_BGAlphaSliderLow"]:SetText("0") end
  if _G["FR0Z3NUIFQT_BGAlphaSliderHigh"] then _G["FR0Z3NUIFQT_BGAlphaSliderHigh"]:SetText("1") end
  f._frameBgAlphaSlider = bgAlphaSlider

  -- Quick palette + full picker launcher
  local palette = {
    { 0.00, 0.00, 0.00 }, -- black
    { 0.20, 0.20, 0.20 }, -- dark gray
    { 0.75, 0.75, 0.75 }, -- light gray
    { 1.00, 1.00, 1.00 }, -- white
    { 1.00, 0.25, 0.25 }, -- red
    { 1.00, 0.55, 0.10 }, -- orange
    { 1.00, 0.90, 0.20 }, -- yellow
    { 0.20, 1.00, 0.20 }, -- green
    { 0.20, 0.60, 1.00 }, -- blue
  }

  local paletteButtons = {}
  local paletteStartX = 10
  for i = 1, #palette do
    local btn = CreateFrame("Button", nil, panels.frames)
    btn:SetSize(12, 12)
    if i == 1 then
      btn:SetPoint("TOPLEFT", bgAlphaSlider, "TOPRIGHT", paletteStartX, -2)
    else
      btn:SetPoint("LEFT", paletteButtons[i - 1], "RIGHT", 3, 0)
    end
    btn:EnableMouse(true)
    local t = btn:CreateTexture(nil, "ARTWORK")
    t:SetAllPoints()
    if t.SetColorTexture then
      t:SetColorTexture(palette[i][1], palette[i][2], palette[i][3], 1)
    end
    btn._tex = t
    paletteButtons[i] = btn
  end
  f._frameBgPaletteButtons = paletteButtons

  local bgMoreBtn = CreateFrame("Button", nil, panels.frames, "UIPanelButtonTemplate")
  bgMoreBtn:SetSize(56, 18)
  bgMoreBtn:SetPoint("LEFT", paletteButtons[#paletteButtons], "RIGHT", 6, 0)
  bgMoreBtn:SetText("More...")
  f._frameBgMoreBtn = bgMoreBtn

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
      if optionsFrame._frameNameBox then
        optionsFrame._frameNameBox:SetText("")
        optionsFrame._frameNameBox:SetEnabled(false)
      end
      if optionsFrame._frameMaxHBox then
        optionsFrame._frameMaxHBox:SetText("0")
        optionsFrame._frameMaxHBox:SetEnabled(false)
      end

      if optionsFrame._frameBgSwatch and optionsFrame._frameBgSwatch._tex and optionsFrame._frameBgSwatch._tex.SetColorTexture then
        optionsFrame._frameBgSwatch._tex:SetColorTexture(0, 0, 0, 1)
      end
      if optionsFrame._frameBgSwatch and optionsFrame._frameBgSwatch.Disable then
        optionsFrame._frameBgSwatch:Disable()
      end
      if optionsFrame._frameBgAlphaSlider then
        optionsFrame._skipBgAlphaChange = true
        optionsFrame._frameBgAlphaSlider:SetValue(0)
        optionsFrame._skipBgAlphaChange = false
        optionsFrame._frameBgAlphaSlider:Disable()
      end
      if optionsFrame._frameBgMoreBtn and optionsFrame._frameBgMoreBtn.Disable then
        optionsFrame._frameBgMoreBtn:Disable()
      end
      if type(optionsFrame._frameBgPaletteButtons) == "table" then
        for _, b in ipairs(optionsFrame._frameBgPaletteButtons) do
          if b and b.Disable then b:Disable() end
        end
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
      if optionsFrame._frameMaxHBox then
        optionsFrame._frameMaxHBox:SetText(tostring(tonumber(def.maxHeight) or 0))
        optionsFrame._frameMaxHBox:SetEnabled(true)
      end
    else
      optionsFrame._frameHeightLabel:SetText("Height")
      optionsFrame._frameLengthLabel:SetText("Segments")
      optionsFrame._frameHeightBox:SetText(tostring(tonumber(def.height) or 20))
      if optionsFrame._frameMaxHBox then
        optionsFrame._frameMaxHBox:SetText("0")
        optionsFrame._frameMaxHBox:SetEnabled(false)
      end
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

    if optionsFrame._frameNameBox then
      local nm = (type(def) == "table" and def.name ~= nil) and tostring(def.name) or ""
      optionsFrame._frameNameBox:SetText(nm)
      optionsFrame._frameNameBox:SetEnabled(true)
    end

    optionsFrame._frameWidthBox:SetText(tostring(tonumber(def.width) or 300))
    optionsFrame._frameLengthBox:SetText(tostring(tonumber(def.maxItems) or (t == "list" and 20 or 6)))

    -- Background controls
    do
      local c = (type(def) == "table") and def.bgColor or nil
      local r, g, b = 0, 0, 0
      if type(c) == "table" then
        r = tonumber(c[1]) or 0
        g = tonumber(c[2]) or 0
        b = tonumber(c[3]) or 0
      end
      if optionsFrame._frameBgSwatch and optionsFrame._frameBgSwatch._tex and optionsFrame._frameBgSwatch._tex.SetColorTexture then
        optionsFrame._frameBgSwatch._tex:SetColorTexture(r, g, b, 1)
      end
      if optionsFrame._frameBgSwatch and optionsFrame._frameBgSwatch.Enable then
        optionsFrame._frameBgSwatch:Enable()
      end

      local a = (type(def) == "table") and tonumber(def.bgAlpha)
      if a == nil then a = 0 end
      if a < 0 then a = 0 end
      if a > 1 then a = 1 end
      if optionsFrame._frameBgAlphaSlider then
        optionsFrame._skipBgAlphaChange = true
        optionsFrame._frameBgAlphaSlider:SetValue(a)
        optionsFrame._skipBgAlphaChange = false
        optionsFrame._frameBgAlphaSlider:Enable()
      end
      if optionsFrame._frameBgMoreBtn and optionsFrame._frameBgMoreBtn.Enable then
        optionsFrame._frameBgMoreBtn:Enable()
      end
      if type(optionsFrame._frameBgPaletteButtons) == "table" then
        for _, b in ipairs(optionsFrame._frameBgPaletteButtons) do
          if b and b.Enable then b:Enable() end
        end
      end
    end

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
    if optionsFrame._frameMaxHBox then
      optionsFrame._frameMaxHBox:SetEnabled(enableInputs and (t == "list"))
    end
  end

  local function ShowFrameBGColorPicker(initialR, initialG, initialB, initialA, onChanged)
    local CPF = _G and rawget(_G, "ColorPickerFrame")
    if not CPF then
      local CAO = _G and rawget(_G, "C_AddOns")
      if CAO and CAO.LoadAddOn then pcall(CAO.LoadAddOn, "Blizzard_ColorPicker") end
      local LoadAddOn = _G and rawget(_G, "LoadAddOn")
      if LoadAddOn then pcall(LoadAddOn, "Blizzard_ColorPicker") end
      CPF = _G and rawget(_G, "ColorPickerFrame")
    end
    if not (CPF and (CPF.SetupColorPickerAndShow or (CPF.Show and CPF.SetColorRGB and CPF.GetColorRGB))) then
      Print("Color picker unavailable.")
      return
    end

    local function Clamp01Local(v)
      v = tonumber(v)
      if not v then return 0 end
      if v < 0 then return 0 end
      if v > 1 then return 1 end
      return v
    end

    -- Make it feel like a "pop-out" attached to our options window.
    if CPF.ClearAllPoints and CPF.SetPoint and optionsFrame and optionsFrame.IsShown and optionsFrame:IsShown() then
      CPF:ClearAllPoints()
      -- Prefer opening to the left of the options frame; clamp will keep it on-screen.
      CPF:SetPoint("TOPRIGHT", optionsFrame, "TOPLEFT", -8, -40)
      if CPF.SetFrameStrata then CPF:SetFrameStrata("DIALOG") end
      if CPF.SetClampedToScreen then CPF:SetClampedToScreen(true) end
    end

    local r0 = Clamp01Local(initialR)
    local g0 = Clamp01Local(initialG)
    local b0 = Clamp01Local(initialB)
    local a0 = Clamp01Local(initialA)
    local prev = { r0, g0, b0, a0 }

    local function CurrentOpacity()
      if OpacitySliderFrame and OpacitySliderFrame.GetValue then
        return 1 - (tonumber(OpacitySliderFrame:GetValue()) or 0)
      end
      if CPF.opacity ~= nil then
        return 1 - (tonumber(CPF.opacity) or 0)
      end
      return a0
    end

    if CPF.SetupColorPickerAndShow then
      local info = {
        r = r0,
        g = g0,
        b = b0,
        opacity = 1 - a0,
        hasOpacity = true,
        swatchFunc = function()
          local r, g, b = CPF:GetColorRGB()
          local a = Clamp01Local(CurrentOpacity())
          if onChanged then onChanged(r, g, b, a) end
        end,
        opacityFunc = function()
          local r, g, b = CPF:GetColorRGB()
          local a = Clamp01Local(CurrentOpacity())
          if onChanged then onChanged(r, g, b, a) end
        end,
        cancelFunc = function(restored)
          local rv = restored or prev
          local r = rv.r or rv[1]
          local g = rv.g or rv[2]
          local b = rv.b or rv[3]
          local a = rv.a or rv[4]
          if rv.opacity ~= nil and a == nil then a = 1 - (tonumber(rv.opacity) or 0) end
          if onChanged then onChanged(r, g, b, a) end
        end,
        previousValues = prev,
      }
      CPF:SetupColorPickerAndShow(info)
    else
      CPF.hasOpacity = true
      CPF.opacity = 1 - a0
      CPF.previousValues = prev

      CPF.func = function()
        local r, g, b = CPF:GetColorRGB()
        local a = Clamp01Local(CurrentOpacity())
        if onChanged then onChanged(r, g, b, a) end
      end

      CPF.opacityFunc = function()
        local r, g, b = CPF:GetColorRGB()
        local a = Clamp01Local(CurrentOpacity())
        if onChanged then onChanged(r, g, b, a) end
      end

      CPF.cancelFunc = function(restored)
        local rv = restored or prev
        if onChanged then onChanged(rv[1], rv[2], rv[3], rv[4]) end
      end

      CPF:SetColorRGB(r0, g0, b0)
      CPF:Show()
    end
  end

  local function ApplyBGToSelectedFrame(r, g, b, a)
    if not optionsFrame then return end
    local id = tostring(optionsFrame._selectedFrameID or "")
    if id == "" then return end
    local eff = FindEffectiveFrameDef(id)
    if not eff then return end
    local def = FindOrCreateCustomFrameDef(id)
    if not def then return end

    def.bgColor = { tonumber(r) or 0, tonumber(g) or 0, tonumber(b) or 0 }
    if a ~= nil then
      def.bgAlpha = tonumber(a) or 0
    end
    UpdateFrameEditor()
    RefreshAll()
    RefreshFramesList()
  end

  bgSwatch:SetScript("OnClick", function()
    if not optionsFrame then return end
    local id = tostring(optionsFrame._selectedFrameID or "")
    if id == "" then return end
    local eff = FindEffectiveFrameDef(id)
    if not eff then return end
    local def = FindOrCreateCustomFrameDef(id)
    if not def then return end

    local c = (type(eff) == "table") and eff.bgColor or nil
    local r, g, b = 0, 0, 0
    if type(c) == "table" then
      r = tonumber(c[1]) or 0
      g = tonumber(c[2]) or 0
      b = tonumber(c[3]) or 0
    end
    local a = (type(eff) == "table") and tonumber(eff.bgAlpha)
    if a == nil then a = 0 end
    if a < 0 then a = 0 end
    if a > 1 then a = 1 end

    ShowFrameBGColorPicker(r, g, b, a, function(nr, ng, nb, na)
      ApplyBGToSelectedFrame(nr, ng, nb, na)
    end)
  end)

  for i, btn in ipairs(paletteButtons) do
    btn:SetScript("OnClick", function()
      local c = palette[i]
      if not c then return end
      local a = nil
      if optionsFrame and optionsFrame._frameBgAlphaSlider and optionsFrame._frameBgAlphaSlider.GetValue then
        a = tonumber(optionsFrame._frameBgAlphaSlider:GetValue())
      end
      if a == nil then a = 0 end
      -- If the background is currently hidden, picking a color should make it visible.
      if a <= 0 then
        a = 0.25
        if optionsFrame and optionsFrame._frameBgAlphaSlider and optionsFrame._frameBgAlphaSlider.SetValue then
          optionsFrame._skipBgAlphaChange = true
          optionsFrame._frameBgAlphaSlider:SetValue(a)
          optionsFrame._skipBgAlphaChange = false
        end
      end
      ApplyBGToSelectedFrame(c[1], c[2], c[3], a)
    end)
  end

  bgMoreBtn:SetScript("OnClick", function()
    if not optionsFrame then return end
    local id = tostring(optionsFrame._selectedFrameID or "")
    if id == "" then return end
    local eff = FindEffectiveFrameDef(id)
    if not eff then return end

    local c = (type(eff) == "table") and eff.bgColor or nil
    local r, g, b = 0, 0, 0
    if type(c) == "table" then
      r = tonumber(c[1]) or 0
      g = tonumber(c[2]) or 0
      b = tonumber(c[3]) or 0
    end
    local a = (type(eff) == "table") and tonumber(eff.bgAlpha)
    if a == nil then a = 0 end
    if a < 0 then a = 0 end
    if a > 1 then a = 1 end

    ShowFrameBGColorPicker(r, g, b, a, function(nr, ng, nb, na)
      ApplyBGToSelectedFrame(nr, ng, nb, na)
    end)
  end)

  bgAlphaSlider:SetScript("OnValueChanged", function(self, value)
    if not optionsFrame or optionsFrame._skipBgAlphaChange then return end
    local id = tostring(optionsFrame._selectedFrameID or "")
    if id == "" then return end
    local eff = FindEffectiveFrameDef(id)
    if not eff then return end
    local def = FindOrCreateCustomFrameDef(id)
    if not def then return end
    def.bgAlpha = tonumber(value) or 0
    RefreshAll()
    RefreshFramesList()
  end)

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
      def.maxHeight = nil
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
      def.maxHeight = nil
    else
      def.width = tonumber(optionsFrame._frameWidthBox:GetText() or "")
      def.maxItems = tonumber(optionsFrame._frameLengthBox:GetText() or "")
      if tostring(eff.type or "list") == "list" then
        def.rowHeight = tonumber(optionsFrame._frameHeightBox:GetText() or "")
        if optionsFrame._frameMaxHBox then
          local mh = tonumber(optionsFrame._frameMaxHBox:GetText() or "")
          def.maxHeight = (mh and mh > 0) and mh or nil
        end
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
  maxHBox:SetScript("OnEnterPressed", function(self) self:ClearFocus(); ApplyFrameSizeFromInputs() end)

  nameBox:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
    if not optionsFrame then return end
    local id = tostring(optionsFrame._selectedFrameID or "")
    if id == "" then return end
    local def = FindOrCreateCustomFrameDef(id)
    if not def then return end

    local nm = tostring(self:GetText() or "")
    nm = nm:gsub("^%s+", ""):gsub("%s+$", "")
    def.name = (nm ~= "") and nm or nil
    RefreshFramesList()
    RefreshAll()
  end)

  RefreshFramesList = function()
    if not optionsFrame then return end
    UpdateFrameEditor()

    local frames = GetCustomFrames()
    local rowH = 18
    local fcontent = optionsFrame._framesContent
    local frows = optionsFrame._frameRows
    if optionsFrame._framesScroll and fcontent then
      local w = tonumber(optionsFrame._framesScroll:GetWidth() or 0) or 0
      fcontent:SetWidth(math.max(1, w - 28))
    end
    fcontent:SetHeight(math.max(1, #frames * rowH))

    for i = 1, #frames do
      local def = frames[i]
      local row = frows[i]
      if not row then
        row = CreateFrame("Frame", nil, fcontent)
        row:SetHeight(rowH)
        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.text:SetPoint("LEFT", 2, 0)

        row.up = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.up:SetSize(18, 18)
        row.up:SetText("^")
        row.up:SetScript("OnEnter", function(self)
          if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Move up")
            GameTooltip:Show()
          end
        end)
        row.up:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

        row.down = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.down:SetSize(18, 18)
        row.down:SetText("v")
        row.down:SetScript("OnEnter", function(self)
          if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Move down")
            GameTooltip:Show()
          end
        end)
        row.down:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

        row.del = CreateFrame("Button", nil, row, "UIPanelCloseButton")
        row.del:SetSize(20, 20)
        row.del:SetPoint("RIGHT", 6, 0)

        row.down:SetPoint("RIGHT", row.del, "LEFT", -2, 0)
        row.up:SetPoint("RIGHT", row.down, "LEFT", -2, 0)
        row.text:SetPoint("RIGHT", row.up, "LEFT", -4, 0)
        frows[i] = row
      end

      row:SetPoint("TOPLEFT", 0, -(i - 1) * rowH)
      row:SetPoint("TOPRIGHT", 0, -(i - 1) * rowH)
      local nm = (type(def) == "table" and def.name ~= nil) and tostring(def.name) or ""
      if nm ~= "" then
        row.text:SetText(string.format("%s  (%s)  %s", tostring(def and def.id or ""), tostring(def and def.type or "list"), nm))
      else
        row.text:SetText(string.format("%s  (%s)", tostring(def and def.id or ""), tostring(def and def.type or "list")))
      end

      local idx = i
      row.up:SetEnabled(idx > 1)
      row.down:SetEnabled(idx < #frames)
      row.up:SetScript("OnClick", function()
        if idx <= 1 then return end
        frames[idx], frames[idx - 1] = frames[idx - 1], frames[idx]
        RefreshAll()
        RefreshFramesList()
      end)

      row.down:SetScript("OnClick", function()
        if idx >= #frames then return end
        frames[idx], frames[idx + 1] = frames[idx + 1], frames[idx]
        RefreshAll()
        RefreshFramesList()
      end)

      row.del:SetScript("OnClick", function()
        if not (IsShiftKeyDown and IsShiftKeyDown()) then
          Print("Hold SHIFT and click X to delete a frame.")
          return
        end
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

    local function GetRulesView()
      local v = tostring(optionsFrame._rulesView or GetUISetting("rulesView", "all") or "all")
      if v ~= "all" and v ~= "custom" and v ~= "defaults" and v ~= "trash" then v = "all" end
      optionsFrame._rulesView = v
      return v
    end

    local view = GetRulesView()

    local list
    local sourceOf = nil
    if view == "defaults" then
      list = ns.rules or {}
      if optionsFrame._rulesTitle then optionsFrame._rulesTitle:SetText("Default Rules") end
    elseif view == "trash" then
      list = GetCustomRulesTrash()
      if optionsFrame._rulesTitle then optionsFrame._rulesTitle:SetText("Trash (Custom Rules)") end
    elseif view == "custom" then
      list = GetCustomRules()
      if optionsFrame._rulesTitle then optionsFrame._rulesTitle:SetText("Custom Rules") end
    else
      -- all: defaults + custom + auto
      list = {}
      sourceOf = {}
      for _, r in ipairs(ns.rules or {}) do
        list[#list + 1] = r
        sourceOf[r] = "default"
      end
      for _, r in ipairs(GetCustomRules()) do
        list[#list + 1] = r
        sourceOf[r] = "custom"
      end
      for _, r in ipairs(GetEffectiveRules()) do
        -- GetEffectiveRules already includes defaults+custom, but also adds auto rules.
        -- We only need the autos here.
        if sourceOf[r] == nil then
          list[#list + 1] = r
          sourceOf[r] = "auto"
        end
      end
      if optionsFrame._rulesTitle then optionsFrame._rulesTitle:SetText("All Rules") end
    end

    local rowH = 18
    local content = optionsFrame._rulesContent
    local rows = optionsFrame._ruleRows
    if optionsFrame._rulesScroll and content then
      local w = tonumber(optionsFrame._rulesScroll:GetWidth() or 0) or 0
      content:SetWidth(math.max(1, w - 28))
    end
    content:SetHeight(math.max(1, #list * rowH))

    local function FormatRuleText(r)
      local label = (type(r) == "table" and r.label ~= nil) and tostring(r.label) or ""
      label = label:gsub("\n", " "):gsub("^%s+", ""):gsub("%s+$", "")

      local function LevelSuffix(rr)
        if type(rr) ~= "table" then return "" end
        local op = rr.playerLevelOp
        local lvl = tonumber(rr.playerLevel)
        if op and lvl and lvl > 0 then
          return string.format(" [Lvl %s %d]", tostring(op), lvl)
        end
        return ""
      end

      if type(r) == "table" and type(r.item) == "table" and r.item.itemID then
        local itemID = tonumber(r.item.itemID) or 0
        local base = (label ~= "") and label or (GetItemNameSafe(itemID) or ("Item " .. tostring(itemID)))
        return string.format("I: %s%s", base, LevelSuffix(r))
      elseif tonumber(r and r.questID) and tonumber(r.questID) > 0 then
        local q = tonumber(r.questID) or 0
        local base = (label ~= "") and label or (GetQuestTitle(q) or ("Quest " .. tostring(q)))
        if label == "" then
          local hay = tostring(base or ""):lower()
          local aura = (type(r) == "table") and r.aura or nil
          if (type(aura) == "table" and aura.eventKind == "timewalking") or hay:find("timewalking", 1, true) or hay:find("turbulent timeways", 1, true) then
            base = tostring(base) .. " [TW]"
          end
        end
        return string.format("Q: %s%s", tostring(base), LevelSuffix(r))
      elseif type(r) == "table" and (r.spellKnown or r.notSpellKnown or r.locationID or r.class or r.notInGroup) then
        local function PickSpellID(v)
          if type(v) == "table" then
            for _, x in ipairs(v) do
              local n = tonumber(x)
              if n and n > 0 then return n end
            end
            return nil
          end
          local n = tonumber(v)
          return (n and n > 0) and n or nil
        end

        local spellID = PickSpellID(r.spellKnown) or PickSpellID(r.notSpellKnown)
        local name = nil
        if label == "" and spellID then
          local CS = _G and rawget(_G, "C_Spell")
          if CS and CS.GetSpellName then
            local ok, n = pcall(CS.GetSpellName, spellID)
            if ok and type(n) == "string" and n ~= "" then name = n end
          end
          local GSI = _G and rawget(_G, "GetSpellInfo")
          if not name and GSI then
            local ok, n = pcall(GSI, spellID)
            if ok and type(n) == "string" and n ~= "" then name = n end
          end
        end

        local base = (label ~= "") and label or (name or (spellID and ("Spell " .. tostring(spellID)) or "Spell"))
        return string.format("S: %s%s", base, LevelSuffix(r))
      else
        local base = (label ~= "") and label or "Text"
        return string.format("T: %s%s", base, LevelSuffix(r))
      end
    end

    for i = 1, #list do
      local r = list[i]
      local row = rows[i]
      if not row then
        row = CreateFrame("Frame", nil, content)
        row:SetHeight(rowH)
        row:EnableMouse(true)

        row.toggle = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        row.toggle:SetSize(18, 18)
        row.toggle:SetPoint("LEFT", 0, 0)

        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.text:SetPoint("LEFT", row.toggle, "RIGHT", 4, 0)

        row.action = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.action:SetSize(70, 18)

        row.up = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.up:SetSize(18, 18)
        row.up:SetText("^")
        row.up:SetScript("OnEnter", function(self)
          if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Move up")
            GameTooltip:Show()
          end
        end)
        row.up:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

        row.down = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.down:SetSize(18, 18)
        row.down:SetText("v")
        row.down:SetScript("OnEnter", function(self)
          if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Move down")
            GameTooltip:Show()
          end
        end)
        row.down:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

        row.action:SetPoint("RIGHT", -62, 0)

        row.del = CreateFrame("Button", nil, row, "UIPanelCloseButton")
        row.del:SetSize(20, 20)
        row.del:SetPoint("RIGHT", 6, 0)

        row.down:SetPoint("RIGHT", row.del, "LEFT", -2, 0)
        row.up:SetPoint("RIGHT", row.down, "LEFT", -2, 0)
        row.text:SetPoint("RIGHT", row.action, "LEFT", -6, 0)

        rows[i] = row
      end

      row:SetPoint("TOPLEFT", 0, -(i - 1) * rowH)
      row:SetPoint("TOPRIGHT", 0, -(i - 1) * rowH)

      local disabled = IsRuleDisabled(r)
      row.toggle:SetChecked(not disabled)
      if disabled then
        row.text:SetFontObject("GameFontDisableSmall")
      else
        row.text:SetFontObject("GameFontHighlightSmall")
      end

      local src = (view == "defaults") and "default" or (view == "trash") and "trash" or (view == "custom") and "custom" or (sourceOf and sourceOf[r])
      local c = (src == "default" or src == "auto") and "|cff00ccff" or (src == "trash") and "|cffff8800" or "|cffffffff"
      row.text:SetText(c .. FormatRuleText(r) .. "|r")

      local idx = i
      if view == "trash" then
        row.toggle:Hide()
      else
        row.toggle:Show()
        row.toggle:SetScript("OnClick", function()
          ToggleRuleDisabled(r)
          RefreshAll()
          RefreshRulesList()
        end)
      end

      local function FindCustomIndex(rule)
        local custom = GetCustomRules()
        for ci, cr in ipairs(custom) do
          if cr == rule then return ci end
        end
        return nil
      end

      local function MoveCustomByIndex(ci, delta)
        local custom = GetCustomRules()
        if type(ci) ~= "number" then return end
        local ni = ci + delta
        if ni < 1 or ni > #custom then return end
        custom[ci], custom[ni] = custom[ni], custom[ci]

        if optionsFrame and optionsFrame._editingCustomRuleIndex then
          if optionsFrame._editingCustomRuleIndex == ci then
            optionsFrame._editingCustomRuleIndex = ni
          elseif optionsFrame._editingCustomRuleIndex == ni then
            optionsFrame._editingCustomRuleIndex = ci
          end
        end

        RefreshAll()
        RefreshRulesList()
      end

      local function SetMoveButtonsVisible(isVisible)
        if isVisible then
          row.up:Show()
          row.down:Show()
        else
          row.up:Hide()
          row.down:Hide()
        end
      end

      if view == "custom" then
        SetMoveButtonsVisible(true)
        row.action:SetText("Edit")
        row.action:Show()
        row.action:SetScript("OnClick", function()
          local ci = FindCustomIndex(list[idx])
          if not ci then return end
          OpenCustomRuleInTab(ci)
        end)

        do
          local ci = FindCustomIndex(list[idx])
          local n = #(GetCustomRules() or {})
          row.up:SetEnabled(ci ~= nil and ci > 1)
          row.down:SetEnabled(ci ~= nil and ci < n)
        end

        row.up:SetScript("OnClick", function()
          local ci = FindCustomIndex(list[idx])
          if not ci then return end
          MoveCustomByIndex(ci, -1)
        end)
        row.down:SetScript("OnClick", function()
          local ci = FindCustomIndex(list[idx])
          if not ci then return end
          MoveCustomByIndex(ci, 1)
        end)

        row:SetScript("OnMouseUp", nil)

        row.del:Show()
        row.del:SetScript("OnClick", function()
          if not (IsShiftKeyDown and IsShiftKeyDown()) then
            Print("Hold SHIFT and click X to move a rule to Trash.")
            return
          end
          local trash = GetCustomRulesTrash()
          trash[#trash + 1] = list[idx]
          table.remove(list, idx)
          if optionsFrame then optionsFrame._editingCustomRuleIndex = nil end
          RefreshAll()
          RefreshRulesList()
          Print("Moved custom rule to Trash.")
        end)
      elseif view == "defaults" then
        SetMoveButtonsVisible(false)
        row:SetScript("OnMouseUp", nil)
        row.action:SetText("Override")
        row.action:Show()
        row.action:SetScript("OnClick", function()
          local base = list[idx]
          if type(base) ~= "table" then return end

          local copy = DeepCopyValue(base)
          copy.key = MakeUniqueRuleKey("custom:override")
          EnsureUniqueKeyForCustomRule(copy)

          local custom = GetCustomRules()
          custom[#custom + 1] = copy
          ToggleRuleDisabled(base)

          CreateAllFrames()
          RefreshAll()
          RefreshRulesList()
          Print("Created custom override and disabled the default rule.")
        end)

        row.del:Hide()
      elseif view == "trash" then
        SetMoveButtonsVisible(false)
        row:SetScript("OnMouseUp", nil)
        row.action:SetText("Restore")
        row.action:Show()
        row.action:SetScript("OnClick", function()
          local trash = GetCustomRulesTrash()
          local r2 = trash[idx]
          if type(r2) ~= "table" then return end
          local restored = DeepCopyValue(r2)
          EnsureUniqueKeyForCustomRule(restored)
          local custom = GetCustomRules()
          custom[#custom + 1] = restored
          table.remove(trash, idx)
          RefreshAll()
          RefreshRulesList()
          Print("Restored custom rule.")
        end)

        row.del:Show()
        row.del:SetScript("OnClick", function()
          if not (IsShiftKeyDown and IsShiftKeyDown()) then
            Print("Hold SHIFT and click X to delete permanently.")
            return
          end
          table.remove(list, idx)
          RefreshRulesList()
          Print("Deleted trashed rule permanently.")
        end)
      else
        -- all: choose actions per-row
        row:SetScript("OnMouseUp", nil)

        local src2 = (sourceOf and sourceOf[r]) or "custom"
        if src2 == "default" then
          SetMoveButtonsVisible(false)
          row.action:SetText("Override")
          row.action:Show()
          row.action:SetScript("OnClick", function()
            local base = r
            if type(base) ~= "table" then return end

            local copy = DeepCopyValue(base)
            copy.key = MakeUniqueRuleKey("custom:override")
            EnsureUniqueKeyForCustomRule(copy)

            local custom = GetCustomRules()
            custom[#custom + 1] = copy
            ToggleRuleDisabled(base)

            CreateAllFrames()
            RefreshAll()
            RefreshRulesList()
            Print("Created custom override and disabled the default rule.")
          end)
          row.del:Hide()
        elseif src2 == "custom" then
          SetMoveButtonsVisible(true)
          row.action:SetText("Edit")
          row.action:Show()
          row.action:SetScript("OnClick", function()
            local ci = FindCustomIndex(r)
            if not ci then return end
            OpenCustomRuleInTab(ci)
          end)

          do
            local ci = FindCustomIndex(r)
            local n = #(GetCustomRules() or {})
            row.up:SetEnabled(ci ~= nil and ci > 1)
            row.down:SetEnabled(ci ~= nil and ci < n)
          end

          row.up:SetScript("OnClick", function()
            local ci = FindCustomIndex(r)
            if not ci then return end
            MoveCustomByIndex(ci, -1)
          end)
          row.down:SetScript("OnClick", function()
            local ci = FindCustomIndex(r)
            if not ci then return end
            MoveCustomByIndex(ci, 1)
          end)

          row.del:Show()
          row.del:SetScript("OnClick", function()
            if not (IsShiftKeyDown and IsShiftKeyDown()) then
              Print("Hold SHIFT and click X to move a rule to Trash.")
              return
            end
            local ci = FindCustomIndex(r)
            if not ci then return end
            local custom = GetCustomRules()
            local trash = GetCustomRulesTrash()
            trash[#trash + 1] = custom[ci]
            table.remove(custom, ci)
            if optionsFrame then optionsFrame._editingCustomRuleIndex = nil end
            RefreshAll()
            RefreshRulesList()
            Print("Moved custom rule to Trash.")
          end)
        else
          -- auto: no edit/delete
          SetMoveButtonsVisible(false)
          row.action:Hide()
          row.del:Hide()
        end
      end

      row:Show()
    end
    for i = #list + 1, #rows do
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
  local initial = tostring(GetUISetting("optionsTab", "frames") or "frames")
  if not panels[initial] then initial = "frames" end
  SelectTab(initial)
  return f
end

local function ShowOptions()
  editMode = true
  RefreshAll()
  local f = EnsureOptionsFrame()
  RefreshActiveTab()
  f:Show()
end

-- WeakAuras tooling is implemented in fr0z3nUI_QuestTracker_WeakAuras.lua.
-- Keep a small shim here so the slash command can still open the importer if the module loaded.
local function EnsureWeakAuraImportFrame()
  local ensure = _G and rawget(_G, "EnsureWeakAuraImportFrame")
  if type(ensure) == "function" then
    return ensure()
  end
  Print("WeakAuras import module not loaded.")
  return nil
end

local function RenderList(frameDef, frame, entries)
  local maxItems = tonumber(frameDef.maxItems) or 20
  local rowH = tonumber(frameDef.rowHeight) or 16

  local listPad = 0
  if not editMode then
    listPad = tonumber(GetUISetting("listPadding", 0) or 0) or 0
    if listPad < 0 then listPad = 0 end
    if listPad > 50 then listPad = 50 end
  end

  local function DetermineListGrow()
    local g = GetUISetting("listGrow", nil)
    if g == nil and type(frameDef) == "table" then
      g = frameDef.listGrow or frameDef.growY
    end
    g = tostring(g or "auto"):lower()
    if g ~= "auto" and g ~= "up" and g ~= "down" then g = "auto" end
    if g ~= "auto" then return g end

    local point = nil
    if frame and frame.GetPoint then
      point = select(1, frame:GetPoint(1))
    end
    point = tostring(point or (frameDef and frameDef.point) or ""):upper()
    if point:find("BOTTOM", 1, true) then return "up" end
    if point:find("TOP", 1, true) then return "down" end

    -- For CENTER/LEFT/RIGHT anchors, pick a stable default.
    return "down"
  end

  if frame.title then
    frame.title:Hide()
  end

  local padTop = 8
  local padBottom = 8

  local visibleRows = maxItems
  if type(frameDef) == "table" and tonumber(frameDef.maxHeight) and tonumber(frameDef.maxHeight) > 0 then
    local mh = tonumber(frameDef.maxHeight) or 0
    local can = math.floor((mh - padTop - padBottom) / rowH)
    if can < 1 then can = 1 end
    if can < visibleRows then visibleRows = can end
    if frame and frame.SetHeight then
      frame:SetHeight(mh)
    end
  end

  local offset = GetFrameScrollOffset(frame and frame._id)
  local maxOffset = 0
  if type(entries) == "table" then
    if not editMode then
      -- With multi-line wrapping, "rows per page" varies. Allow scrolling to any starting index.
      maxOffset = math.max(0, (#entries) - 1)
    else
      maxOffset = math.max(0, (#entries) - visibleRows)
    end
  end
  if offset > maxOffset then
    offset = maxOffset
    SetFrameScrollOffset(frame and frame._id, offset)
  end

  -- Edit-mode scroll buttons live on the frame (requested).
  if frame and frame._scrollUp and frame._scrollDown then
    local show = editMode and maxOffset > 0
    frame._scrollUp:SetShown(show)
    frame._scrollDown:SetShown(show)
    if show then
      frame._scrollUp:SetEnabled(offset > 0)
      frame._scrollDown:SetEnabled(offset < maxOffset)
    end
  end

  local shown = 0

  local wrapText = not editMode
  local growY = (editMode and "down") or DetermineListGrow()
  local yCursor = 0
  local maxY = nil
  if wrapText and type(frameDef) == "table" and tonumber(frameDef.maxHeight) and tonumber(frameDef.maxHeight) > 0 then
    maxY = (tonumber(frameDef.maxHeight) or 0) - padTop - padBottom
    if maxY < rowH then maxY = rowH end
  end

  local function GetTextWidth()
    local w = (frame and frame.GetWidth and frame:GetWidth()) or (frameDef and frameDef.width) or 300
    local rightPad = editMode and 28 or 12
    local leftPad = 16
    local tw = w - leftPad - rightPad
    if tw < 50 then tw = 50 end
    return tw
  end

  local textW = GetTextWidth()

  for i = 1, visibleRows do
    local e = entries[i + offset]
    local fs = EnsureFontString(frame, i, frameDef and frameDef.font)
    fs:ClearAllPoints()
    if wrapText then
      if fs.SetJustifyV then fs:SetJustifyV((growY == "up") and "BOTTOM" or "TOP") end
      if fs.SetWordWrap then fs:SetWordWrap(true) end
      if fs.SetNonSpaceWrap then fs:SetNonSpaceWrap(true) end
      if fs.SetWidth then fs:SetWidth(textW) end
    else
      if fs.SetJustifyV then fs:SetJustifyV("MIDDLE") end
      if fs.SetWordWrap then fs:SetWordWrap(false) end
      if fs.SetNonSpaceWrap then fs:SetNonSpaceWrap(false) end
      -- In edit mode, avoid SetWidth() so the row button doesn't cover the remove (X) button.
      if fs.SetWidth then fs:SetWidth(0) end
    end
    if growY == "up" and not editMode then
      fs:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, padBottom + yCursor)
    else
      fs:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -padTop - yCursor)
    end

    ApplyFontStyle(fs, frameDef and frameDef.font)

    local btn = EnsureRowButton(frame, i)
    btn:ClearAllPoints()
    btn:SetPoint("TOPLEFT", fs, "TOPLEFT", -2, 2)
    btn:SetPoint("BOTTOMRIGHT", fs, "BOTTOMRIGHT", 2, -2)
    btn._entry = e
    btn._entryAbsIndex = i + offset
    btn:EnableMouse(editMode and true or false)
    if editMode then
      btn:Show()
    else
      btn:Hide()
    end

    local entry = e
    local rm = EnsureRemoveButton(frame, i)
    rm:ClearAllPoints()
    rm:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -padTop - (i - 1) * rowH + 2)
    rm._entry = entry
    rm:SetScript("OnClick", function(self)
      local ent = self and self._entry
      if not (ent and ent.rule) then return end
      local ok = UnassignRuleFromFrame(ent.rule, frame and frame._id)
      if not ok then
        Print("That rule isn't custom; use disable toggle instead.")
        ToggleRuleDisabled(ent.rule)
      end
      RefreshAll()
      if optionsFrame then RefreshActiveTab() end
    end)
    rm:SetShown(editMode and e ~= nil)

    if e then
      local text = (editMode and e.editText) or e.title
      if (not editMode) and e.extra then text = text .. "  " .. e.extra .. " " end
      fs:SetText(" " .. text .. " ")
      fs:Show()
      RenderIndicators(frame, i, fs, e.indicators)
      shown = shown + 1

      local h = rowH
      if wrapText then
        local sh = (fs.GetStringHeight and fs:GetStringHeight()) or (fs.GetHeight and fs:GetHeight()) or nil
        if sh and sh > h then h = sh end
      end
      yCursor = yCursor + h
      if wrapText then yCursor = yCursor + 2 end

      -- Optional extra gap between quest entries.
      if wrapText and listPad > 0 and entries[i + offset + 1] ~= nil then
        yCursor = yCursor + listPad
      end

      if maxY and yCursor > maxY and shown > 0 then
        -- Stop early; remaining rows are hidden below.
        for j = i + 1, visibleRows do
          local fs2 = EnsureFontString(frame, j, frameDef and frameDef.font)
          fs2:SetText("")
          fs2:Hide()
          RenderIndicators(frame, j, fs2, nil)
          local btn2 = EnsureRowButton(frame, j)
          btn2._entry = nil
          btn2:Hide()
          local rm2 = EnsureRemoveButton(frame, j)
          rm2:Hide()
        end
        break
      end
    else
      fs:SetText("")
      fs:Hide()
      RenderIndicators(frame, i, fs, nil)
    end
  end

  for i = visibleRows + 1, maxItems do
    local fs = EnsureFontString(frame, i, frameDef and frameDef.font)
    fs:SetText("")
    fs:Hide()
    RenderIndicators(frame, i, fs, nil)
    local btn = EnsureRowButton(frame, i)
    btn._entry = nil
    btn:Hide()

    local rm = EnsureRemoveButton(frame, i)
    rm:Hide()
  end

  if frameDef and frameDef.autoSize then
    local minRows = tonumber(frameDef.minRows) or 0
    local want
    if wrapText then
      local minH = (minRows > 0) and (minRows * rowH) or 0
      want = padTop + padBottom + math.max(minH, yCursor)
    else
      local rows = shown
      if editMode then rows = visibleRows end
      if rows < minRows then rows = minRows end
      want = padTop + padBottom + rows * rowH
    end
    if type(frameDef) == "table" and tonumber(frameDef.maxHeight) and tonumber(frameDef.maxHeight) > 0 then
      want = math.min(want, tonumber(frameDef.maxHeight))
    end
    frame:SetHeight(want)
  end
end

RefreshAll = function()
  NormalizeSV()

  local evalCtx = BuildEvalContext()

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
    local status = BuildRuleStatus(rule, evalCtx)
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
        local c = (type(def) == "table") and def.bgColor or nil
        ApplyFAOBackdrop(f, a, c)
      elseif type(def) == "table" and (def.bgAlpha ~= nil or def.bgColor ~= nil) then
        ApplyFAOBackdrop(f, def.bgAlpha, def.bgColor)
      end

      local t = tostring(def.type or "list"):lower()
      local entries = entriesByFrameID[id] or {}
      local hasAny = entries[1] ~= nil

      -- Used by edit-mode drag/drop.
      f._lastFrameDef = def
      f._lastEntries = entries

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
        if editMode then
          local tmp = ShallowCopyTable(def) or {}
          tmp.type = "list"
          tmp.rowHeight = tonumber(tmp.rowHeight) or 16
          tmp.maxItems = tonumber(tmp.maxItems) or 20
          tmp.maxHeight = tonumber(tmp.maxHeight) or tmp.height or nil
          RenderList(tmp, f, entries)
        else
          RenderBar(def, f, entries)
        end
      else
        RenderList(def, f, entries)
      end

      UpdateAnchorLabel(f, def)
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
    Print("Loaded. Type /fqt to configure.")
    return
  end

  -- debounce rapid spam
  if frame._refreshTimer then
    frame._refreshTimer:Cancel()
  end
  frame._refreshTimer = C_Timer.NewTimer(0.25, RefreshAll)
end)

SLASH_FR0Z3NUIFQT1 = "/fqt"
if not SlashCmdList["FR0Z3NUIFQT"] then
  rawset(SlashCmdList, "FR0Z3NUIFQT", function(msg)
  local raw = tostring(msg or "")
  local trimmed = raw:gsub("^%s+", ""):gsub("%s+$", "")
  local cmd, rest = trimmed:match("^(%S+)%s*(.-)$")
  cmd = tostring(cmd or ""):lower()
  rest = tostring(rest or "")
  if cmd == "" then
    ShowOptions()
    return
  end
  if cmd == "weakaura" then
    local arg = rest ~= "" and rest or nil
    local ensure = _G and rawget(_G, "EnsureWeakAuraImportFrame")
    local f
    if type(ensure) == "function" then
      f = ensure()
    else
      f = EnsureWeakAuraImportFrame()
    end
    if not f then return end
    if arg and f and f._auraBox then
      f._auraBox:SetText(tostring(arg))
    end
    f:Show()
    return
  end
  if cmd == "on" then
    framesEnabled = true
    RefreshAll()
    Print("Enabled.")
    return
  end
  if cmd == "off" then
    framesEnabled = false
    RefreshAll()
    Print("Disabled.")
    return
  end

  if cmd == "reset" then
    ResetFramePositionsToDefaults()
    RefreshAll()
    Print("Frame positions reset to defaults.")
    return
  end

  if cmd == "twdebug" then
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

  Print("Commands: /fqt (options), /fqt on, /fqt off, /fqt reset, /fqt weakaura, /fqt twdebug")
  end)
end
