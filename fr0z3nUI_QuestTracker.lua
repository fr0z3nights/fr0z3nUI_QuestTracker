local addonName, ns = ...

local PREFIX = "|cff00ccff[FQT]|r "
local function Print(msg)
  print(PREFIX .. tostring(msg or ""))
end

ns.Print = Print

local function NormalizeSV()
  if type(fr0z3nUI_QuestTracker_Acc) == "table"
    and fr0z3nUI_QuestTracker_Acc._fqtNorm
    and type(fr0z3nUI_QuestTracker_Char) == "table"
    and fr0z3nUI_QuestTracker_Char._fqtNorm
  then
    return fr0z3nUI_QuestTracker_Acc, fr0z3nUI_QuestTracker_Char
  end

  if type(fr0z3nUI_QuestTracker_Acc) ~= "table" then
    fr0z3nUI_QuestTracker_Acc = {}
  end
  if type(fr0z3nUI_QuestTracker_Char) ~= "table" then
    fr0z3nUI_QuestTracker_Char = {}
  end

  local acc = fr0z3nUI_QuestTracker_Acc
  acc.settings = (type(acc.settings) == "table") and acc.settings or {}
  acc.settings.ui = (type(acc.settings.ui) == "table") and acc.settings.ui or {}
  acc.cache = (type(acc.cache) == "table") and acc.cache or {}
  acc.cache.weeklyAuras = (type(acc.cache.weeklyAuras) == "table") and acc.cache.weeklyAuras or {}
  acc.cache.dailyAuras = (type(acc.cache.dailyAuras) == "table") and acc.cache.dailyAuras or {}
  acc.cache.twWeekly = (type(acc.cache.twWeekly) == "table") and acc.cache.twWeekly or {}
  acc.cache.currencyWB = (type(acc.cache.currencyWB) == "table") and acc.cache.currencyWB or {}

  local ch = fr0z3nUI_QuestTracker_Char
  ch.settings = (type(ch.settings) == "table") and ch.settings or {}
  ch.cache = (type(ch.cache) == "table") and ch.cache or {}

  -- Common containers referenced throughout the addon.
  ch.settings.disabledRules = (type(ch.settings.disabledRules) == "table") and ch.settings.disabledRules or {}

  -- Frame positions are stored on both scopes; create tables to prevent nil indexing.
  acc.settings.framePos = (type(acc.settings.framePos) == "table") and acc.settings.framePos or {}
  ch.settings.framePos = (type(ch.settings.framePos) == "table") and ch.settings.framePos or {}

  -- Frame scroll offset store.
  ch.settings.frameScroll = (type(ch.settings.frameScroll) == "table") and ch.settings.frameScroll or {}

  acc._fqtNorm = true
  ch._fqtNorm = true

  return acc, ch
end

ns.NormalizeSV = NormalizeSV
if _G then
  _G.NormalizeSV = NormalizeSV
end

local framesEnabled = true
local editMode = false
local barContentsFrame
local ApplyTrackerInteractivity

-- Exposed for split Options UI module.
ns.GetEditMode = function()
  return editMode and true or false
end

ns.SetEditMode = function(v)
  editMode = v and true or false
  if not editMode and barContentsFrame and barContentsFrame.Hide then
    barContentsFrame:Hide()
  end

  if ApplyTrackerInteractivity then
    ApplyTrackerInteractivity()
  end
end

local GetUISetting, SetUISetting

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
if _G then
  _G.GetUISetting = GetUISetting
  _G.SetUISetting = SetUISetting
end

local function GetWindowPosStore()
  NormalizeSV()

  local function Ensure(t)
    if type(t.windowPos) ~= "table" then
      t.windowPos = {}
    end
    return t.windowPos
  end

  local accUI = fr0z3nUI_QuestTracker_Acc.settings.ui
  return Ensure(accUI)
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
if _G then
  _G.SaveWindowPosition = SaveWindowPosition
  _G.RestoreWindowPosition = RestoreWindowPosition
end

local RuleKey

local GetPlayerClass
local HasProfessionSkillLineID, HasExactProfessionSkillLineID, GetPrimaryProfessionNames, HasTradeSkillLine, CanQueryTradeSkillLines
local GetProfessionIndices, IsPrimaryProfessionSlotMissing, IsSecondaryProfessionMissing, HasProfession

do
  local Profs = (type(ns) == "table") and ns.Profs or nil

  HasProfessionSkillLineID = Profs and (Profs.HasProfessionSkillLineID or Profs.HasSkillLineID) or nil
  HasExactProfessionSkillLineID = Profs and (Profs.HasExactProfessionSkillLineID or Profs.HasExactSkillLineID) or nil
  GetProfessionIndices = Profs and Profs.GetProfessionIndices or nil
  IsPrimaryProfessionSlotMissing = Profs and Profs.IsPrimaryProfessionSlotMissing or nil
  IsSecondaryProfessionMissing = Profs and Profs.IsSecondaryProfessionMissing or nil
  GetPrimaryProfessionNames = Profs and Profs.GetPrimaryProfessionNames or nil
  CanQueryTradeSkillLines = Profs and Profs.CanQueryTradeSkillLines or nil
  HasTradeSkillLine = Profs and Profs.HasTradeSkillLine or nil
  HasProfession = Profs and Profs.HasProfession or nil
end

if type(HasProfessionSkillLineID) ~= "function" then HasProfessionSkillLineID = function(_) return false end end
if type(HasExactProfessionSkillLineID) ~= "function" then HasExactProfessionSkillLineID = HasProfessionSkillLineID end
if type(GetProfessionIndices) ~= "function" then GetProfessionIndices = function() return nil end end
if type(IsPrimaryProfessionSlotMissing) ~= "function" then IsPrimaryProfessionSlotMissing = function(_) return false end end
if type(IsSecondaryProfessionMissing) ~= "function" then IsSecondaryProfessionMissing = function(_) return false end end
if type(GetPrimaryProfessionNames) ~= "function" then GetPrimaryProfessionNames = function() return nil end end
if type(CanQueryTradeSkillLines) ~= "function" then CanQueryTradeSkillLines = function() return false end end
if type(HasTradeSkillLine) ~= "function" then HasTradeSkillLine = function(_) return false end end
if type(HasProfession) ~= "function" then HasProfession = function(_) return false end end

local function CopyArray(src)
  if type(src) ~= "table" then return nil end
  local out = {}
  for i = 1, #src do
    out[i] = src[i]
  end
  return out
end

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

local function GetPlayerLevelGate(rule)
  if type(rule) ~= "table" then return nil, nil end

  local op, lvl
  if type(rule.playerLevel) == "table" then
    op = rule.playerLevel[1]
    lvl = rule.playerLevel[2]
  else
    op = rule.playerLevelOp
    lvl = rule.playerLevel
  end

  op = NormalizePlayerLevelOp(op)
  lvl = tonumber(lvl)
  if not op or not lvl or lvl <= 0 then return nil, nil end
  return op, lvl
end

local function GetItemCurrencyGate(item)
  if type(item) ~= "table" then return nil, nil end

  local currencyID, currencyRequired
  if type(item.currencyID) == "table" then
    currencyID = tonumber(item.currencyID[1])
    currencyRequired = tonumber(item.currencyID[2])
    if not currencyRequired then
      currencyRequired = tonumber(item.currencyRequired)
    end
  else
    currencyID = tonumber(item.currencyID)
    currencyRequired = tonumber(item.currencyRequired)
  end

  if not currencyID or currencyID <= 0 then return nil, nil end
  if not currencyRequired or currencyRequired <= 0 then return nil, nil end
  return currencyID, currencyRequired
end

ns.GetItemCurrencyGate = GetItemCurrencyGate

local function GetItemRequiredGate(item)
  if type(item) ~= "table" then return nil, nil end

  local req = nil
  local hide = nil

  if type(item.required) == "table" then
    req = tonumber(item.required[1])
    hide = (item.required[2] == true)
    if item.required[2] == nil then
      hide = (item.hideWhenAcquired == true)
    end
  else
    req = tonumber(item.required)
    hide = (item.hideWhenAcquired == true)
  end

  if not req then
    req = tonumber(item.count)
  end

  req = tonumber(req)
  if not req or req <= 0 then req = 1 end

  return req, (hide and true or false)
end

ns.GetItemRequiredGate = GetItemRequiredGate

local function NormalizeLocationID(value)
  if value == nil then return nil end
  if type(value) == "table" then
    local out = {}
    local seen = {}
    for i = 1, #value do
      local v = value[i]
      if type(v) == "number" then
        local n = tonumber(v)
        if n and n > 0 and not seen[n] then
          out[#out + 1] = n
          seen[n] = true
        end
      else
        local s = tostring(v or "")
        s = s:gsub("%s+", "")
        for token in s:gmatch("[^,;]+") do
          local digits = token:match("^%a*(%d+)$") or token:match("^(%d+)$")
          local n = digits and tonumber(digits) or nil
          if n and n > 0 and not seen[n] then
            out[#out + 1] = n
            seen[n] = true
          end
        end
      end
    end

    if not out[1] then return nil end
    if #out == 1 then return out[1] end
    local parts = {}
    for i = 1, #out do parts[i] = tostring(out[i]) end
    return table.concat(parts, ",")
  end
  if type(value) == "number" then
    if value > 0 then return value end
    return nil
  end

  local s = tostring(value or "")
  s = s:gsub("%s+", "")
  if s == "" or s == "0" then return nil end

  local out = {}
  local seen = {}
  for token in s:gmatch("[^,;]+") do
    local digits = token:match("^%a*(%d+)$") or token:match("^(%d+)$")
    local n = digits and tonumber(digits) or nil
    if n and n > 0 and not seen[n] then
      out[#out + 1] = n
      seen[n] = true
    end
  end

  if not out[1] then return nil end
  if #out == 1 then return out[1] end
  local parts = {}
  for i = 1, #out do parts[i] = tostring(out[i]) end
  return table.concat(parts, ",")
end

local function ParseLocationIDs(value)
  if value == nil then return nil end
  if type(value) == "table" then
    local out = {}
    local seen = {}
    for i = 1, #value do
      local v = value[i]
      if type(v) == "number" then
        local n = tonumber(v)
        if n and n > 0 and not seen[n] then
          out[#out + 1] = n
          seen[n] = true
        end
      else
        local s = tostring(v or "")
        s = s:gsub("%s+", "")
        for token in s:gmatch("[^,;]+") do
          local digits = token:match("^%a*(%d+)$") or token:match("^(%d+)$")
          local n = digits and tonumber(digits) or nil
          if n and n > 0 and not seen[n] then
            out[#out + 1] = n
            seen[n] = true
          end
        end
      end
    end
    return out[1] and out or nil
  end
  if type(value) == "number" then
    if value > 0 then return { value } end
    return nil
  end

  local s = tostring(value or "")
  s = s:gsub("%s+", "")
  if s == "" or s == "0" then return nil end

  local out = {}
  local seen = {}
  for token in s:gmatch("[^,;]+") do
    local digits = token:match("^%a*(%d+)$") or token:match("^(%d+)$")
    local n = digits and tonumber(digits) or nil
    if n and n > 0 and not seen[n] then
      out[#out + 1] = n
      seen[n] = true
    end
  end
  return out[1] and out or nil
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

if _G then
  _G.GetFrameScrollOffset = GetFrameScrollOffset
  _G.SetFrameScrollOffset = SetFrameScrollOffset
end

RuleKey = function(rule)
  if type(rule) ~= "table" then return nil end
  if rule.key ~= nil then return tostring(rule.key) end
  if rule.questID then
    local qid = tonumber(rule.questID) or rule.questID
    local xy = (rule.questXY ~= nil) and tostring(rule.questXY):upper() or nil
    if xy == "X" or xy == "Y" or xy == "K" then
      return "qxy:" .. xy .. ":" .. tostring(qid)
    end
    return "q:" .. tostring(qid)
  end
  if rule.group then return "group:" .. tostring(rule.group) .. ":" .. tostring(rule.order or 0) end

  -- Additional stable keys for rules that don't have explicit `key`/`questID`/`label`.
  if type(rule.item) == "table" and rule.item.itemID ~= nil then
    local itemID = tonumber(rule.item.itemID)
    if itemID and itemID > 0 then
      local required = tonumber((select(1, GetItemRequiredGate(rule.item)))) or 0
      local mustHave = (rule.item.mustHave == true) and 1 or 0
      return "item:" .. tostring(itemID) .. ":" .. tostring(required) .. ":" .. tostring(mustHave)
    end
  end

  if rule.mapID ~= nil then
    local loc = tostring(rule.mapID)
    if loc ~= "" then
      return "loc:" .. loc
    end
  end

  local spellKnownGate = (rule.spellKnown ~= nil) and rule.spellKnown or rule.SpellKnown
  local notSpellKnownGate = (rule.notSpellKnown ~= nil) and rule.notSpellKnown or rule.NotSpellKnown
  if spellKnownGate ~= nil or notSpellKnownGate ~= nil then
    local a = tonumber(spellKnownGate or 0) or 0
    local b = tonumber(notSpellKnownGate or 0) or 0
    if a > 0 or b > 0 then
      return "spellKnown:" .. tostring(a) .. ":" .. tostring(b)
    end
  end

  if type(rule.aura) == "table" then
    local spellID = tonumber(rule.aura.spellID or 0) or 0
    if spellID > 0 then
      local mustHave = (rule.aura.mustHave == true) and 1 or 0
      return "aura:" .. tostring(spellID) .. ":" .. tostring(mustHave)
    end

    -- Calendar/timewalking kind rules.
    local kind = tostring(rule.aura.eventKind or "")
    if kind ~= "" then
      local kw = ""
      if type(rule.aura.keywords) == "table" then
        local parts = {}
        for i = 1, #rule.aura.keywords do
          local s = tostring(rule.aura.keywords[i] or "")
          if s ~= "" then parts[#parts + 1] = s end
        end
        if parts[1] then kw = table.concat(parts, "|") end
      end
      if kw ~= "" then
        return "event:" .. kind .. ":" .. kw
      end
      return "event:" .. kind
    end
  end

  -- `label` is often not unique; only use it as a last-resort stable key.
  if rule.label then return "label:" .. tostring(rule.label) end

  return nil
end

ns.RuleKey = RuleKey

-- Custom rules/frames stores + effective merged views (defaults + overrides).
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

function ns.GetCharCustomRules()
  NormalizeSV()
  local t = fr0z3nUI_QuestTracker_Char.settings.customRules
  if type(t) ~= "table" then
    t = {}
    fr0z3nUI_QuestTracker_Char.settings.customRules = t
  end
  return t
end

local function GetCustomRulesTrash()
  NormalizeSV()
  local t = fr0z3nUI_QuestTracker_Acc.settings.customRulesTrash
  if type(t) ~= "table" then
    t = {}
    fr0z3nUI_QuestTracker_Acc.settings.customRulesTrash = t
  end
  return t
end

ns.GetCustomRulesTrash = GetCustomRulesTrash

function ns.GetCharCustomRulesTrash()
  NormalizeSV()
  local t = fr0z3nUI_QuestTracker_Char.settings.customRulesTrash
  if type(t) ~= "table" then
    t = {}
    fr0z3nUI_QuestTracker_Char.settings.customRulesTrash = t
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

ns.GetCustomFrames = GetCustomFrames

local function ShallowCopyTable(src)
  if type(src) ~= "table" then return nil end
  local out = {}
  for k, v in pairs(src) do
    out[k] = v
  end
  return out
end

ns.ShallowCopyTable = ShallowCopyTable

local function GetDefaultRuleEdits()
  NormalizeSV()
  local t = fr0z3nUI_QuestTracker_Acc.settings.defaultRuleEdits
  if type(t) ~= "table" then
    t = {}
    fr0z3nUI_QuestTracker_Acc.settings.defaultRuleEdits = t
  end
  return t
end

ns.GetDefaultRuleEdits = GetDefaultRuleEdits

local function GetEffectiveDefaultRules()
  local out = {}
  local edits = GetDefaultRuleEdits()

  for _, base in ipairs(ns.rules or {}) do
    local key = RuleKey and RuleKey(base) or nil
    local edited = key and edits[key] or nil
    if type(edited) ~= "table" and key and type(base) == "table" and base.questID ~= nil then
      edited = edits["q:" .. tostring(tonumber(base.questID) or base.questID)]
    end
    if type(edited) == "table" then
      out[#out + 1] = edited
    else
      out[#out + 1] = base
    end
  end

  return out
end

ns.GetEffectiveDefaultRules = GetEffectiveDefaultRules

local function GetEffectiveRules()
  local out = {}
  for _, r in ipairs(GetEffectiveDefaultRules()) do out[#out + 1] = r end
  for _, r in ipairs(GetCustomRules()) do out[#out + 1] = r end
  for _, r in ipairs(ns.GetCharCustomRules()) do out[#out + 1] = r end

  return out
end

ns.GetEffectiveRules = GetEffectiveRules

-- Tag Blizzard quest tooltips with the matching Keep/Abandon rule (if any).
if TooltipDataProcessor and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Quest then
  local function OnQuestTooltip(tooltip, data)
    local qid = data and tonumber(data.id)
    if not (tooltip and tooltip.AddLine and qid) then return end

    local rules = GetEffectiveRules()
    for _, rule in ipairs(rules) do
      if type(rule) == "table" and tonumber(rule.questID) == qid then
        local xy = tostring(rule.questXY or ""):upper()
        if xy == "K" then
          tooltip:AddLine("|cff00ccff[FQT]|r |cffffd100Keep|r")
          return
        elseif xy == "X" then
          tooltip:AddLine("|cff00ccff[FQT]|r |cffff9900Abandon|r")
          return
        end
      end
    end
  end
  TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Quest, OnQuestTooltip)
end

local function GetEffectiveFrames()
  -- Merge defaults + custom frames (custom overrides defaults if id matches).
  local base = ns.frames or {}
  local custom = GetCustomFrames()

  local function MergeFrameDef(baseDef, overrideDef)
    if type(baseDef) ~= "table" then baseDef = {} end
    if type(overrideDef) ~= "table" then return ShallowCopyTable(baseDef) end

    local out = ShallowCopyTable(baseDef) or {}
    for k, v in pairs(overrideDef) do
      -- Only override fields that are explicitly present in the custom definition.
      -- (Prevents missing point/x/y in custom frames from forcing fallback anchors.)
      if v ~= nil then
        out[k] = v
      end
    end
    return out
  end

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
        byID[id] = MergeFrameDef(byID[id], def)
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

ns.GetEffectiveFrames = GetEffectiveFrames
if _G then
  _G.GetCustomRules = GetCustomRules
  _G.GetCustomRulesTrash = GetCustomRulesTrash
  _G.GetCustomFrames = GetCustomFrames
  _G.GetEffectiveRules = GetEffectiveRules
  _G.GetEffectiveFrames = GetEffectiveFrames
end

function ns.IsRuleDisabledInScope(rule, isAccount)
  NormalizeSV()
  local key = RuleKey(rule)
  if not key then return false end

  local settings = (isAccount and fr0z3nUI_QuestTracker_Acc and fr0z3nUI_QuestTracker_Acc.settings)
    or (fr0z3nUI_QuestTracker_Char and fr0z3nUI_QuestTracker_Char.settings)
    or nil
  local t = (type(settings) == "table") and settings.disabledRules or nil
  if type(t) ~= "table" then
    t = {}
    if type(settings) == "table" then settings.disabledRules = t end
  end

  if t[key] then return true end

  -- Back-compat for Keep List rules that previously keyed as q:<questID>
  if type(rule) == "table" and rule.questID ~= nil and tostring(rule.questXY or ""):upper() == "K" then
    local qid = tonumber(rule.questID) or rule.questID
    local legacy = "q:" .. tostring(qid)
    if t[legacy] then return true end
  end

  return false
end

function ns.ClearRuleDisabledInScope(rule, isAccount)
  NormalizeSV()
  local key = RuleKey(rule)
  if not key then return end

  local settings = (isAccount and fr0z3nUI_QuestTracker_Acc and fr0z3nUI_QuestTracker_Acc.settings)
    or (fr0z3nUI_QuestTracker_Char and fr0z3nUI_QuestTracker_Char.settings)
    or nil
  local t = (type(settings) == "table") and settings.disabledRules or nil
  if type(t) ~= "table" then
    t = {}
    if type(settings) == "table" then settings.disabledRules = t end
  end

  t[key] = nil

  if type(rule) == "table" and rule.questID ~= nil and tostring(rule.questXY or ""):upper() == "K" then
    local qid = tonumber(rule.questID) or rule.questID
    local legacy = "q:" .. tostring(qid)
    t[legacy] = nil
  end
end

function ns.ToggleRuleDisabledInScope(rule, isAccount)
  NormalizeSV()
  local key = RuleKey(rule)
  if not key then return end

  local settings = (isAccount and fr0z3nUI_QuestTracker_Acc and fr0z3nUI_QuestTracker_Acc.settings)
    or (fr0z3nUI_QuestTracker_Char and fr0z3nUI_QuestTracker_Char.settings)
    or nil
  local t = (type(settings) == "table") and settings.disabledRules or nil
  if type(t) ~= "table" then
    t = {}
    if type(settings) == "table" then settings.disabledRules = t end
  end

  t[key] = not t[key]

  -- If toggling a Keep List rule, normalize away the legacy key.
  if type(rule) == "table" and rule.questID ~= nil and tostring(rule.questXY or ""):upper() == "K" then
    local qid = tonumber(rule.questID) or rule.questID
    local legacy = "q:" .. tostring(qid)
    t[legacy] = nil
  end
end

local function IsRuleDisabled(rule)
  -- A rule is disabled if either:
  --  - Account disabledRules contains the key (disables for all characters), OR
  --  - Character disabledRules contains the key (disables for this character only)
  return (ns and ns.IsRuleDisabledInScope and ns.IsRuleDisabledInScope(rule, true))
    or (ns and ns.IsRuleDisabledInScope and ns.IsRuleDisabledInScope(rule, false))
end

ns.IsRuleDisabled = IsRuleDisabled

local function ToggleRuleDisabled(rule)
  -- Preserve existing behavior: toggles CHARACTER disabled state.
  if ns and ns.ToggleRuleDisabledInScope then
    ns.ToggleRuleDisabledInScope(rule, false)
  end
end

ns.ToggleRuleDisabled = ToggleRuleDisabled

if _G then
  _G.IsRuleDisabled = IsRuleDisabled
  _G.ToggleRuleDisabled = ToggleRuleDisabled
end

local function SetCheckButtonLabel(btn, text)
  if not btn then return end
  local label = btn.text or btn.Text
  if not label and btn.GetName and _G then
    local name = btn:GetName()
    if name then
      label = _G[name .. "Text"] or _G[name .. "Label"]
    end
  end

  if label and label.SetText then
    label:SetText(tostring(text or ""))
  end
end

-- Deps shim for split slash-command module (fUI_QTCoreCmd.lua)
ns._FQTSlash = ns._FQTSlash or {}
ns._FQTSlash.deps = {
  Print = Print,
  NormalizeSV = function()
    if type(NormalizeSV) == "function" then
      return NormalizeSV()
    end
  end,
  RefreshAll = function(...)
    if type(ns) == "table" and type(ns.RefreshAll) == "function" then
      return ns.RefreshAll(...)
    end
    local fn = _G and rawget(_G, "RefreshAll")
    if type(fn) == "function" then
      return fn(...)
    end
  end,
  ResetFramePositionsToDefaults = function(...)
    if type(ns) == "table" and type(ns.ResetFramePositionsToDefaults) == "function" then
      return ns.ResetFramePositionsToDefaults()
    end
    local fn = _G and rawget(_G, "ResetFramePositionsToDefaults")
    if type(fn) == "function" then
      return fn()
    end
  end,
  GetFramesEnabled = function() return framesEnabled and true or false end,
  SetFramesEnabled = function(v) framesEnabled = (v == true) end,
  GetEditMode = function() return editMode and true or false end,
  HasProfessionSkillLineID = HasProfessionSkillLineID,
  HasExactProfessionSkillLineID = HasExactProfessionSkillLineID,
}

-- NOTE: deps.DispatchDebugCommand is attached later once the debug handler is defined.

-- Deps shim for split render module (fUI_QTUsageUIR.lua)
ns._FQTRender = ns._FQTRender or {}
ns._FQTRender.deps = ns._FQTRender.deps or {}

-- NOTE: deps render hooks are attached later once UI helpers are defined.


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

ns.GetStandingIDByFactionID = GetStandingIDByFactionID

local function GetMaxPlayerLevelSafe()
  local fn

  fn = _G and rawget(_G, "GetMaxLevelForPlayerExpansion")
  if type(fn) == "function" then
    local ok, v = pcall(fn)
    v = ok and tonumber(v) or nil
    if v and v > 0 then return v end
  end

  local getExp = _G and rawget(_G, "GetExpansionLevel")
  local getMaxForExp = _G and rawget(_G, "GetMaxLevelForExpansionLevel")
  if type(getExp) == "function" and type(getMaxForExp) == "function" then
    local okE, exp = pcall(getExp)
    exp = okE and tonumber(exp) or nil
    if exp and exp >= 0 then
      local ok, v = pcall(getMaxForExp, exp)
      v = ok and tonumber(v) or nil
      if v and v > 0 then return v end
    end
  end

  fn = _G and rawget(_G, "GetMaxLevelForLatestExpansion")
  if type(fn) == "function" then
    local ok, v = pcall(fn)
    v = ok and tonumber(v) or nil
    if v and v > 0 then return v end
  end

  if GetMaxPlayerLevel then
    local ok, v = pcall(GetMaxPlayerLevel)
    v = ok and tonumber(v) or nil
    if v and v > 0 then return v end
  end

  local v = _G and _G["MAX_PLAYER_LEVEL"]
  v = tonumber(v)
  if v and v > 0 then return v end

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
  local op, want = GetPlayerLevelGate(rule)
  if not op or not want then return true end
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

-- Quest API wrappers live in Quest feature module (fUI_QTQuest.lua).
-- Main file uses local aliases for performance and to keep call sites tidy.
local GetQuestTitle = (ns and ns.GetQuestTitle)
local IsQuestCompleted = (ns and ns.IsQuestCompleted)
local IsQuestInLog = (ns and ns.IsQuestInLog)
local GetQuestObjectiveProgressText = (ns and ns.GetQuestObjectiveProgressText)

if type(GetQuestTitle) ~= "function" then GetQuestTitle = function(_) return nil end end
if type(IsQuestCompleted) ~= "function" then IsQuestCompleted = function(_) return false end end
if type(IsQuestInLog) ~= "function" then IsQuestInLog = function(_) return false end end
if type(GetQuestObjectiveProgressText) ~= "function" then GetQuestObjectiveProgressText = function(_, _, _) return nil end end

local function ArePrereqsMet(prereq)
  if type(prereq) ~= "table" then return true end
  for _, q in ipairs(prereq) do
    if not IsQuestCompleted(tonumber(q)) then
      return false
    end
  end
  return true
end

GetPlayerClass = function()
  if UnitClass then
    local _, class = UnitClass("player")
    return class
  end
  return nil
end

if _G then
  _G.GetPlayerClass = GetPlayerClass
end

function ns.GetPurchasedItemsCacheTable()
  local c = fr0z3nUI_QuestTracker_Char
  if type(c) ~= "table" then
    fr0z3nUI_QuestTracker_Char = fr0z3nUI_QuestTracker_Char or {}
    c = fr0z3nUI_QuestTracker_Char
  end
  c.cache = (type(c.cache) == "table") and c.cache or {}
  c.cache.purchasedItems = (type(c.cache.purchasedItems) == "table") and c.cache.purchasedItems or {}
  return c.cache.purchasedItems
end

function ns.IsItemCachedPurchased(itemID)
  itemID = tonumber(itemID)
  if not itemID or itemID <= 0 then return false end
  local t = ns.GetPurchasedItemsCacheTable()
  return (t and t[itemID] ~= nil) and true or false
end

function ns.MarkItemCachedPurchased(itemID)
  itemID = tonumber(itemID)
  if not itemID or itemID <= 0 then return end
  local t = ns.GetPurchasedItemsCacheTable()
  if not t then return end
  if t[itemID] ~= nil then return end
  t[itemID] = true

  -- Ensure the rule UI updates immediately (otherwise this may only show up after /reload).
  if C_Timer and C_Timer.After then
    if ns._cachePurchasedRefreshPending then return end
    ns._cachePurchasedRefreshPending = true
    C_Timer.After(0.05, function()
      ns._cachePurchasedRefreshPending = nil
      if ns and type(ns.RefreshAll) == "function" then
        ns.RefreshAll()
      end
    end)
  elseif ns and type(ns.RefreshAll) == "function" then
    ns.RefreshAll()
  end
end

function ns.IsMerchantFrameOpenSafe()
  if frame and frame._merchantOpen == true then return true end
  local mf = rawget(_G, "MerchantFrame")
  if mf and mf.IsShown and mf:IsShown() then return true end
  return false
end

function ns.MerchantItemIsAlreadyKnown(merchantIndex)
  merchantIndex = tonumber(merchantIndex)
  if not merchantIndex or merchantIndex <= 0 then return false end

  local needles = {}
  local function AddNeedle(v)
    if type(v) == "string" and v ~= "" then
      needles[#needles + 1] = v:lower()
    end
  end
  AddNeedle(rawget(_G, "ITEM_SPELL_KNOWN"))
  AddNeedle(rawget(_G, "ITEM_PET_KNOWN"))
  AddNeedle(rawget(_G, "SPELL_ALREADY_KNOWN"))
  AddNeedle("already known")

  local function LineHasNeedle(s)
    s = tostring(s or "")
    if s == "" then return false end
    local l = s:lower()
    for i = 1, #needles do
      local n = needles[i]
      if n ~= "" and l:find(n, 1, true) then
        return true
      end
    end
    return false
  end

  if _G and rawget(_G, "C_TooltipInfo") and type(_G.C_TooltipInfo.GetMerchantItem) == "function" then
    local ok, tip = pcall(_G.C_TooltipInfo.GetMerchantItem, merchantIndex)
    if ok and type(tip) == "table" and type(tip.lines) == "table" then
      for _, line in ipairs(tip.lines) do
        if type(line) == "table" then
          if LineHasNeedle(line.leftText) or LineHasNeedle(line.rightText) or LineHasNeedle(line.text) then
            return true
          end
        end
      end
    end
  end

  if not (GameTooltip and GameTooltip.SetOwner and GameTooltip.SetMerchantItem and GameTooltip.NumLines) then
    return false
  end

  ns._autoBuyScanTip = ns._autoBuyScanTip or CreateFrame("GameTooltip", "FQT_AutoBuyScanTip", UIParent, "GameTooltipTemplate")
  local tip = ns._autoBuyScanTip
  if not tip then return false end

  tip:SetOwner(UIParent, "ANCHOR_NONE")
  tip:ClearLines()
  pcall(tip.SetMerchantItem, tip, merchantIndex)

  local n = tonumber(tip:NumLines()) or 0
  for i = 1, n do
    local fs = _G["FQT_AutoBuyScanTipTextLeft" .. tostring(i)]
    if fs and fs.GetText and LineHasNeedle(fs:GetText()) then
      tip:Hide()
      return true
    end
    local fs2 = _G["FQT_AutoBuyScanTipTextRight" .. tostring(i)]
    if fs2 and fs2.GetText and LineHasNeedle(fs2:GetText()) then
      tip:Hide()
      return true
    end
  end
  tip:Hide()
  return false
end

local GetItemCountSafe

function ns.SchedulePostBuyCacheCheck(itemID, merchantIndex, spec)
  if not (C_Timer and C_Timer.After) then return end
  if type(spec) ~= "table" or spec.cachePurchased ~= true then return end
  itemID = tonumber(itemID)
  if not itemID or itemID <= 0 then return end

  C_Timer.After(0.65, function()
    if not ns.IsMerchantFrameOpenSafe() then return end
    if type(spec) == "table" and spec.knownTooltip == true and merchantIndex then
      if ns.MerchantItemIsAlreadyKnown(merchantIndex) then
        ns.MarkItemCachedPurchased(itemID)
      end
    end
    if type(GetItemCountSafe) == "function" then
      GetItemCountSafe(itemID, false, { cachePurchased = true, cachePurchasedFromBag = (type(spec) == "table") and spec.cachePurchasedFromBag or nil })
    end
  end)
end

GetItemCountSafe = function(itemID, includeBank, opts)
  itemID = tonumber(itemID)
  if not itemID then return 0 end

  includeBank = (includeBank == true) or (type(opts) == "table" and opts.inBank == true)

  local function ApplyPurchasedCache(raw)
    if type(opts) == "table" and opts.cachePurchased == true then
      if (tonumber(raw) or 0) > 0 and opts.cachePurchasedFromBag ~= false then
        ns.MarkItemCachedPurchased(itemID)
      end
      if ns.IsItemCachedPurchased(itemID) then
        return math.max(tonumber(raw) or 0, 1)
      end
    end
    return tonumber(raw) or 0
  end

  local raw = 0

  -- Prefer the global API when available; it typically counts bags + equipped.
  local GetItemCountFn = _G and rawget(_G, "GetItemCount")
  if type(GetItemCountFn) == "function" then
    local ok, v = pcall(GetItemCountFn, itemID, includeBank, false, false)
    v = ok and tonumber(v) or 0
    if v and v > 0 then raw = v end
  end

  if raw <= 0 and C_Item and C_Item.GetItemCount then
    local ok, v = pcall(C_Item.GetItemCount, itemID, includeBank, false, false)
    v = ok and tonumber(v) or 0
    if v and v > 0 then raw = v end
  end

  -- Last-resort: consider equipped items (not all count APIs include equipment).
  if raw <= 0 and GetInventoryItemID and GetInventoryItemID("player", 19) == itemID then
    raw = 1
  end

  return ApplyPurchasedCache(raw)
end

-- Currency / warband-currency logic was split out to fUI_QTGuideGold.lua.

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

ns.GetItemNameSafe = GetItemNameSafe

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

-- Calendar / Timewalking logic (including remembered event state) lives in fUI_QTGuideEvent.lua.
-- Use ns.Calendar.* and ns.GetCalendarDebugEvents.

local Calendar = (type(ns) == "table" and ns.Calendar) or {}
local RememberWeeklyAura = Calendar.RememberWeeklyAura or function(...) end
local HasRememberedWeeklyAura = Calendar.HasRememberedWeeklyAura or function(...) return false end
local RememberDailyAura = Calendar.RememberDailyAura or function(...) end
local HasRememberedDailyAura = Calendar.HasRememberedDailyAura or function(...) return false end
local RememberWeeklyTimewalkingKind = Calendar.RememberWeeklyTimewalkingKind or function(...) end
local HasRememberedWeeklyTimewalkingKind = Calendar.HasRememberedWeeklyTimewalkingKind or function(...) return false end
local ClearRememberedTimewalkingKind = Calendar.ClearRememberedTimewalkingKind or function(...) end
local ClearRememberedEventState = Calendar.ClearRememberedEventState or function(...) end
local MaybeAutoResetEventsOncePerDay = Calendar.MaybeAutoResetEventsOncePerDay or function(...) end
local MaybeAutoClearTimewalkingKindOncePerWeek = Calendar.MaybeAutoClearTimewalkingKindOncePerWeek or function(...) end

local function ColorHex(r, g, b)
  local function Normalize01(v)
    v = tonumber(v) or 1
    if v > 1 then v = v / 255 end
    if v < 0 then v = 0 elseif v > 1 then v = 1 end
    return v
  end

  r = math.floor(Normalize01(r) * 255 + 0.5)
  g = math.floor(Normalize01(g) * 255 + 0.5)
  b = math.floor(Normalize01(b) * 255 + 0.5)
  if r < 0 then r = 0 elseif r > 255 then r = 255 end
  if g < 0 then g = 0 elseif g > 255 then g = 255 end
  if b < 0 then b = 0 elseif b > 255 then b = 255 end
  return string.format("%02x%02x%02x", r, g, b)
end

local function ColorText(rgb, text)
  if not text then return "" end
  if type(rgb) == "string" then
    local s = tostring(rgb or "")
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    -- Accept: "#rrggbb", "rrggbb", "|cffaarrggbb", "ffaarrggbb"
    s = s:gsub("^#", "")
    s = s:gsub("^0x", "")
    s = s:gsub("^|c", "")
    s = s:gsub("^|C", "")
    s = s:gsub("^ff", "")
    s = s:lower()
    if s:match("^[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]$") then
      return "|cff" .. s .. text .. "|r"
    end
    return text
  end
  if type(rgb) == "table" then
    local hex = ColorHex(rgb[1] or rgb.r, rgb[2] or rgb.g, rgb[3] or rgb.b)
    return "|cff" .. hex .. text .. "|r"
  end
  return text
end

local function NormalizeColorString(color)
  if color == nil then return nil end
  local s = tostring(color)
  s = s:gsub("^%s+", ""):gsub("%s+$", "")
  if s == "" then return nil end
  s = s:gsub("^|[cC]", "")
  s = s:gsub("^#", "")
  s = s:gsub("^0x", "")
  s = s:lower()
  if #s == 8 then
    s = s:sub(3)
  end
  if #s == 6 and s:match("^[0-9a-f]+$") then
    return s
  end
  return nil
end

local function ResolveColorRGB(color)
  if type(color) == "table" then
    local r = tonumber(color[1] or color.r)
    local g = tonumber(color[2] or color.g)
    local b = tonumber(color[3] or color.b)
    if not (r and g and b) then return nil end
    if r > 1 or g > 1 or b > 1 then
      r = r / 255
      g = g / 255
      b = b / 255
    end
    if r < 0 then r = 0 elseif r > 1 then r = 1 end
    if g < 0 then g = 0 elseif g > 1 then g = 1 end
    if b < 0 then b = 0 elseif b > 1 then b = 1 end
    return r, g, b
  end

  local hex = NormalizeColorString(color)
  if not hex then return nil end
  local r = tonumber(hex:sub(1, 2), 16) / 255
  local g = tonumber(hex:sub(3, 4), 16) / 255
  local b = tonumber(hex:sub(5, 6), 16) / 255
  return r, g, b
end

local function ResolveFontPath(fontNameOrPath)
  if not fontNameOrPath then return nil end
  local s = tostring(fontNameOrPath)
  local forceLSM = false
  do
    local lsmName = s:match("^lsm:(.+)$")
    if lsmName and lsmName ~= "" then
      s = lsmName
      forceLSM = true
    end
  end
  if s:find("\\") or s:find("/") then
    return s
  end

  -- Allow WoW font objects by global name (e.g. "GameFontHighlight").
  if not forceLSM then
    local obj = _G and rawget(_G, s)
    if obj and obj.GetFont then
      local ok, path = pcall(function()
        -- GetFont() may return (path, size, flags)
        return (select(1, obj:GetFont()))
      end)
      if ok and type(path) == "string" and path ~= "" then
        return path
      end
    end
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

local function GetRuleFontDef(rule)
  if type(rule) ~= "table" then return nil end

  local name = rule.font or rule.textFont or rule.fontName
  if name ~= nil and tostring(name):lower() == "inherit" then name = nil end

  local size = rule.size or rule.Size or rule.fontSize or rule.FontSize
  size = tonumber(size)
  if size ~= nil and size <= 0 then size = nil end

  local flags = rule.fontFlags or rule.flags
  if flags ~= nil and tostring(flags):lower() == "inherit" then flags = nil end

  local color = rule.color or rule.Color or rule.fontColor or rule.FontColor
  if color ~= nil and tostring(color):lower() == "inherit" then color = nil end

  if name == nil and size == nil and flags == nil and color == nil then
    return nil
  end

  return { name = name, size = size, flags = flags, color = color }
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
    local r, g, b = ResolveColorRGB(fontDef.color)
    if r and fs.SetTextColor then fs:SetTextColor(r, g, b, 1) end
  end

  if fs.SetShadowColor and fs.SetShadowOffset then
    local shadow = fontDef.shadow
    if type(shadow) == "table" then
      local sh = shadow.color or shadow[3]
      local x = tonumber(shadow.x or shadow[1] or 1) or 1
      local y = tonumber(shadow.y or shadow[2] or -1) or -1
      if sh ~= nil then
        local hex2 = tostring(sh):gsub("^#", "")
        if hex2:len() == 6 then
          local r = tonumber(hex2:sub(1, 2), 16) / 255
          local g = tonumber(hex2:sub(3, 4), 16) / 255
          local b = tonumber(hex2:sub(5, 6), 16) / 255
          fs:SetShadowColor(r, g, b, 1)
        else
          fs:SetShadowColor(0, 0, 0, 1)
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

  -- Composite conditions
  if type(ind.any) == "table" then
    for _, child in ipairs(ind.any) do
      if EvaluateIndicatorCondition(child) then
        return true
      end
    end
    return false
  end

  if type(ind.all) == "table" then
    for _, child in ipairs(ind.all) do
      if not EvaluateIndicatorCondition(child) then
        return false
      end
    end
    return true
  end

  -- Reputation condition (standingID)
  do
    local rep = (type(ind.rep) == "table") and ind.rep or nil
    local factionID = tonumber((rep and rep.factionID) or ind.factionID)
    if factionID then
      local standingID = GetStandingIDByFactionID(factionID)
      if not standingID then
        return false
      end

      local minStanding = tonumber((rep and rep.minStanding) or ind.minStanding)
      if minStanding and standingID < minStanding then
        return false
      end

      local maxStanding = tonumber((rep and rep.maxStanding) or ind.maxStanding)
      if maxStanding and standingID > maxStanding then
        return false
      end

      return true
    end
  end

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

local function PlayerHasFindFishUnlocked()
  if not (C_Minimap and type(C_Minimap.GetNumTrackingTypes) == "function" and type(C_Minimap.GetTrackingInfo) == "function") then
    return false
  end

  local n = tonumber(C_Minimap.GetNumTrackingTypes()) or 0
  for i = 1, n do
    local ok, a, b, c, d, e, f = pcall(C_Minimap.GetTrackingInfo, i)
    if ok then
      local name, trackingType

      if type(a) == "table" then
        -- Newer API shape: returns a table.
        name = a.name
        trackingType = a.type or a.trackingType or a.category
      else
        -- Legacy API shape: returns tuple values.
        name = a
        trackingType = d
      end

      if type(name) == "string" then
        if name == "Find Fish" then
          return true
        end

        local trackingTypeNum = tonumber(trackingType)
        if trackingTypeNum == 7 or trackingTypeNum == 8 then
          if name:lower():find("fish", 1, true) then
            return true
          end
        end
      end
    end
  end

  return false
end

local function EvaluateRuleCondition(node)
  if type(node) ~= "table" then return false end

  local includeBank = (node.includeBank == true) or (node.inBank == true)

  local function EvalChild(child)
    if includeBank and type(child) == "table" and child.includeBank == nil and child.inBank == nil then
      local t = {}
      for k, v in pairs(child) do t[k] = v end
      t.inBank = true
      return EvaluateRuleCondition(t)
    end
    return EvaluateRuleCondition(child)
  end

  if type(node.any) == "table" then
    for _, child in ipairs(node.any) do
      if EvalChild(child) then
        return true
      end
    end
    return false
  end

  if type(node.all) == "table" then
    for _, child in ipairs(node.all) do
      if not EvalChild(child) then
        return false
      end
    end
    return true
  end

  local hadCondition = false

  if node.class ~= nil then
    hadCondition = true
    local want = node.class
    local have = GetPlayerClass()
    if type(want) == "table" then
      local ok = false
      for _, c in ipairs(want) do
        if tostring(c):upper() == tostring(have or ""):upper() then
          ok = true
          break
        end
      end
      if not ok then return false end
    else
      if tostring(want):upper() ~= tostring(have or ""):upper() then
        return false
      end
    end
  end

  if node.missingPrimarySlot ~= nil then
    hadCondition = true
    if not IsPrimaryProfessionSlotMissing(node.missingPrimarySlot) then
      return false
    end
  end

  if node.missingSecondary ~= nil then
    hadCondition = true
    if not IsSecondaryProfessionMissing(node.missingSecondary) then
      return false
    end
  end

  if node.missingTradeSkillLine ~= nil then
    hadCondition = true
    if not CanQueryTradeSkillLines() then
      return false
    end
    if HasTradeSkillLine(node.missingTradeSkillLine) then
      return false
    end
  end

  if node.findFish ~= nil or node.hasFindFish ~= nil then
    hadCondition = true
    local want = (node.findFish ~= nil) and (node.findFish == true) or (node.hasFindFish == true)
    if PlayerHasFindFishUnlocked() ~= want then
      return false
    end
  end

  if node.missingFindFish ~= nil then
    hadCondition = true
    local missing = (node.missingFindFish == true)
    local wantUnlocked = (not missing)
    if PlayerHasFindFishUnlocked() ~= wantUnlocked then
      return false
    end
  end

  if type(node.questIDs) == "table" then
    hadCondition = true
    local any = false
    for _, q in ipairs(node.questIDs) do
      if IsQuestCompleted(tonumber(q)) then
        any = true
        break
      end
    end
    if not any then
      return false
    end
  end

  -- Quest-in-log gate (active quest): useful for reminders that should appear while a quest
  -- is currently picked up.
  if type(node.questInLogIDs) == "table" then
    hadCondition = true
    local any = false
    for _, q in ipairs(node.questInLogIDs) do
      local qid = tonumber(q)
      if qid and qid > 0 and IsQuestInLog(qid) then
        any = true
        break
      end
    end
    if not any then
      return false
    end
  end

  if node.questInLog then
    hadCondition = true
    local qid = tonumber(node.questInLog)
    if not (qid and qid > 0 and IsQuestInLog(qid)) then
      return false
    end
  end

  if node.questID then
    hadCondition = true
    if not IsQuestCompleted(tonumber(node.questID)) then
      return false
    end
  end

  if type(node.itemIDs) == "table" then
    hadCondition = true
    local need = tonumber(node.count) or tonumber(node.required) or 1
    local any = false
    for _, itemID in ipairs(node.itemIDs) do
      if GetItemCountSafe(tonumber(itemID), includeBank, node) >= need then
        any = true
        break
      end
    end
    if not any then
      return false
    end
  end

  if node.itemID then
    hadCondition = true
    local need = tonumber(node.count) or tonumber(node.required) or 1
    if GetItemCountSafe(tonumber(node.itemID), includeBank, node) < need then
      return false
    end
  end

  if type(node.item) == "table" and node.item.itemID then
    hadCondition = true
    local itemID = tonumber(node.item.itemID)
    local need = tonumber(node.item.count) or tonumber(node.item.required) or 1
    local inc = (node.item.includeBank == true) or (node.item.inBank == true) or includeBank
    if GetItemCountSafe(itemID, inc, node.item) < need then
      return false
    end
  end

  do
    -- Currency gate support (used by showIf and other helper rules).
    local currencyID = nil
    local currencyRequired = nil

    if node.currencyID ~= nil then
      if type(node.currencyID) == "table" then
        currencyID = tonumber(node.currencyID[1])
        currencyRequired = tonumber(node.currencyID[2])
      else
        currencyID = tonumber(node.currencyID)
        currencyRequired = tonumber(node.currencyRequired) or tonumber(node.required) or tonumber(node.count)
      end
    elseif type(node.currency) == "table" then
      currencyID = tonumber(node.currency.currencyID or node.currency.id or node.currency[1])
      currencyRequired = tonumber(node.currency.required or node.currency[2] or node.required or node.count)
    elseif type(node.item) == "table" and node.item.currencyID ~= nil and node.item.itemID == nil then
      if type(node.item.currencyID) == "table" then
        currencyID = tonumber(node.item.currencyID[1])
        currencyRequired = tonumber(node.item.currencyID[2])
      else
        currencyID = tonumber(node.item.currencyID)
        currencyRequired = tonumber(node.item.currencyRequired) or tonumber(node.item.required) or tonumber(node.item.count)
      end
    end

    if currencyID and currencyID > 0 then
      hadCondition = true
      local req = tonumber(currencyRequired) or 1
      local charQty = (ns and ns.GetCurrencyQuantitySafe and ns.GetCurrencyQuantitySafe(currencyID)) or 0
      local gateQty = charQty
      if ns and ns.IsCurrencyWarbandTransferableSafe and ns.IsCurrencyWarbandTransferableSafe(currencyID) then
        local wbTotal = (ns.GetWarbandCurrencyTotalSafe and select(1, ns.GetWarbandCurrencyTotalSafe(currencyID, true)))
        if wbTotal ~= nil then gateQty = wbTotal end
      end
      if gateQty < req then
        return false
      end
    end
  end

  do
    local rep = (type(node.rep) == "table") and node.rep or nil
    local factionID = tonumber((rep and rep.factionID) or node.factionID)
    if factionID then
      hadCondition = true
      local standingID = GetStandingIDByFactionID(factionID)
      if not standingID then
        return false
      end

      local minStanding = tonumber((rep and rep.minStanding) or node.minStanding)
      if minStanding and standingID < minStanding then
        return false
      end

      local maxStanding = tonumber((rep and rep.maxStanding) or node.maxStanding)
      if maxStanding and standingID > maxStanding then
        return false
      end
    end
  end

  if type(node.aura) == "table" and node.aura.spellID then
    hadCondition = true
    local has = HasAuraSpellID(tonumber(node.aura.spellID))
    local must = (node.aura.mustHave ~= false)
    if must and not has then return false end
    if (not must) and has then return false end
  end

  if node.profession ~= nil then
    hadCondition = true
    if not HasProfession(node.profession) then
      return false
    end
  end

  return hadCondition and true or false
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
            local hasCondition = false
            if ind.overlay.questID or ind.overlay.itemID then
              hasCondition = true
            elseif type(ind.overlay.questIDs) == "table" or type(ind.overlay.itemIDs) == "table" then
              hasCondition = true
            elseif type(ind.overlay.aura) == "table" and ind.overlay.aura.spellID then
              hasCondition = true
            elseif type(ind.overlay.any) == "table" or type(ind.overlay.all) == "table" then
              hasCondition = true
            elseif type(ind.overlay.rep) == "table" or ind.overlay.factionID or ind.overlay.minStanding or ind.overlay.maxStanding then
              hasCondition = true
            end

            local show = (not hasCondition) or EvaluateIndicatorCondition(ind.overlay)
            if show then
              overlay = {
                text = ind.overlay.text,
                color = ind.overlay.color,
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

local function ClampPadPx(v)
  v = tonumber(v)
  if v == nil then return nil end
  if v < -10 then v = -10 end
  if v > 50 then v = 50 end
  return v
end

local function GetIndicatorMetrics(baseFS, padPx)
  local size = 12
  if baseFS and baseFS.GetFont then
    local _, s = baseFS:GetFont()
    size = tonumber(s) or size
  end

  -- Aim: square roughly matches text height.
  local icon = math.floor(size * 1.0 + 0.5)
  if icon < 10 then icon = 10 end
  if icon > 22 then icon = 22 end

  local uiPad = ClampPadPx(padPx)
  if uiPad == nil and type(GetUISetting) == "function" then
    local v = GetUISetting("pad", nil)
    if v == nil then v = GetUISetting("listPadding", 0) end
    uiPad = ClampPadPx(v) or 0
  end
  uiPad = uiPad or 0

  local gap = 2
  local pad = 4 + uiPad
  if pad < 0 then pad = 0 end
  return icon, gap, pad
end

local function RenderIndicators(frame, rowIndex, baseFS, indicators, padPx)
  local row = EnsureIndicatorRow(frame, rowIndex)
  if not row then return end

  if type(indicators) ~= "table" or indicators[1] == nil or not baseFS then
    row.container:Hide()
    return
  end

  local ICON, GAP, PAD = GetIndicatorMetrics(baseFS, padPx)

  local function IsEffectivelyBlankText(fs)
    if not fs or not fs.GetText then return true end
    local t = fs:GetText()
    if t == nil or t == "" then return true end
    -- Treat NBSP as whitespace too.
    t = tostring(t):gsub("\194\160", " ")
    t = t:gsub("%s+", "")
    return t == ""
  end

  local blankText = IsEffectivelyBlankText(baseFS)
  local textWidth = blankText and 0 or (baseFS:GetStringWidth() or 0)

  -- Icon-only rows (blank text) sit a bit low if top-aligned.
  -- Nudge them up slightly (Timewalking token indicators use this path).
  local yAdjust = blankText and 2 or 0

  -- Only add spacing between text and icons when there is real text.
  -- For icon-only rows, avoid reserving extra space.
  local outerGap = blankText and 0 or PAD
  local leftInset = blankText and 0 or PAD

  local count = #indicators
  local width = leftInset + (count * ICON) + ((count - 1) * GAP)

  row.container:ClearAllPoints()
  row.container:SetPoint("TOPLEFT", baseFS, "TOPLEFT", textWidth + outerGap, yAdjust)
  row.container:SetSize(width, ICON)
  row.container:Show()

  for i = 1, count do
    local spec = indicators[i]
    local tex, lbl = EnsureIndicatorIcon(row, i)
    if tex and lbl then
      tex:ClearAllPoints()
      tex:SetPoint("TOPLEFT", row.container, "TOPLEFT", leftInset + (i - 1) * (ICON + GAP), 0)
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

local function GetIndicatorsWidth(baseFS, indicators, padPx)
  if type(indicators) ~= "table" or indicators[1] == nil then return 0 end
  local ICON, GAP, PAD = GetIndicatorMetrics(baseFS, padPx)

  local blankText = true
  if baseFS and baseFS.GetText then
    local t = baseFS:GetText()
    if t ~= nil and t ~= "" then
      t = tostring(t):gsub("\194\160", " ")
      t = t:gsub("%s+", "")
      blankText = (t == "")
    end
  end
  local leftInset = blankText and 0 or PAD

  local count = #indicators
  return leftInset + (count * ICON) + ((count - 1) * GAP)
end

local function BuildRuleStatus(rule, ctx, opts)
  local questID = tonumber(rule and rule.questID)

  if type(opts) ~= "table" then opts = nil end
  -- In edit mode we typically bypass visibility gates so you can inspect/toggle everything.
  -- Some callers (bars) want the normal "only active" filtering even while editing.
  local applyGates = (not editMode) or (opts and opts.forceNormalVisibility == true) or false

  if type(ctx) ~= "table" then ctx = nil end

  -- Generic conditional rules (used for profession/flow helpers)
  if applyGates and type(rule) == "table" and type(rule.showIf) == "table" then
    if not EvaluateRuleCondition(rule.showIf) then
      return nil
    end
  end

  local hideDone
  if type(rule) == "table" and rule.hideDone ~= nil then
    hideDone = rule.hideDone and true or false
  else
    -- default: hide completed quests / completed tasks
    hideDone = true
  end



  local completed = false
  if questID and IsQuestCompleted(questID) then
    completed = true
  end

  local forceShowWhileQuestInLog = applyGates and type(rule) == "table"
    and rule.qilID ~= nil and IsQuestInLog(rule.qilID) or false
  if forceShowWhileQuestInLog then
    hideDone = false
  end

  -- Optional additional completion criteria (for non-quest tasks or stricter completion).
  local complete = (type(rule) == "table" and type(rule.complete) == "table") and rule.complete or nil
  if complete then
    local ok
    local tested = false
    if type(complete.any) == "table" or type(complete.all) == "table" then
      ok = EvaluateRuleCondition(complete)
      tested = true
    else
      ok = true
      if complete.questID then
        tested = true
        ok = ok and IsQuestCompleted(tonumber(complete.questID))
      end
      if type(complete.item) == "table" and complete.item.itemID then
        tested = true
        local itemID = tonumber(complete.item.itemID)
        local need = tonumber(complete.item.count) or tonumber(complete.item.required) or 1
        local have = GetItemCountSafe(itemID, (complete.item.includeBank == true) or (complete.item.inBank == true), complete.item)
        ok = ok and (have >= need)
      end
      if complete.rep ~= nil or complete.factionID ~= nil or complete.minStanding ~= nil or complete.maxStanding ~= nil then
        tested = true
        ok = ok and EvaluateRuleCondition({ rep = complete.rep, factionID = complete.factionID, minStanding = complete.minStanding, maxStanding = complete.maxStanding })
      end
      if complete.profession ~= nil then
        tested = true
        ok = ok and HasProfession(complete.profession)
      end
      if complete.skillLineID ~= nil then
        tested = true
        ok = ok and HasProfessionSkillLineID(complete.skillLineID)
      end
      if type(complete.skillLineIDs) == "table" then
        tested = true
        local anySkill = false
        for _, sid in ipairs(complete.skillLineIDs) do
          if HasProfessionSkillLineID(sid) then
            anySkill = true
            break
          end
        end
        ok = ok and anySkill
      end
      if type(complete.aura) == "table" and complete.aura.spellID then
        tested = true
        local has = HasAuraSpellID(tonumber(complete.aura.spellID))
        local must = (complete.aura.mustHave ~= false)
        ok = ok and (must and has or (not must and not has))
      end
      if complete.findFish ~= nil or complete.hasFindFish ~= nil then
        tested = true
        local want = (complete.findFish ~= nil) and (complete.findFish == true) or (complete.hasFindFish == true)
        ok = ok and (PlayerHasFindFishUnlocked() == want)
      end
      if complete.missingFindFish ~= nil then
        tested = true
        local missing = (complete.missingFindFish == true)
        local wantUnlocked = (not missing)
        ok = ok and (PlayerHasFindFishUnlocked() == wantUnlocked)
      end

      if not tested then
        ok = false
      end
    end

    local mode = (type(rule) == "table" and rule.completeMode ~= nil) and tostring(rule.completeMode):lower() or ""
    if mode == "replace" then
      completed = ok and true or false
    elseif ok then
      completed = true
    end
  end

  -- Account-wide Timewalking weekly memory: once ANY character picks up the weekly,
  -- remember which expansion-kind it is until weekly reset.
  if not editMode and questID and type(rule) == "table" and rule.twKind ~= nil then
    local anyTW = (ns and ns.Calendar and ns.Calendar.IsAnyTimewalkingEventActive) or nil
    if IsQuestInLog(questID) and type(anyTW) == "function" and anyTW() then
      RememberWeeklyTimewalkingKind(rule.twKind)
    end
  end

  -- Require a remembered TW kind (used by token indicator rows that should appear
  -- on alts once any character picked up the weekly quest).
  if applyGates and type(rule) == "table" and rule.requireRememberedTimewalkingKind == true then
    local twKind = rule.twKind
    if twKind == nil then
      return nil
    end
    local anyTW = (ns and ns.Calendar and ns.Calendar.IsAnyTimewalkingEventActive) or nil
    local eventActive = (type(anyTW) == "function" and anyTW()) and true or false
    local remembered = HasRememberedWeeklyTimewalkingKind(twKind) and true or false

    if remembered and eventActive then
      -- ok
    else
      local ok = false
      if type(rule.fallbackQuestInLog) == "table" then
        for _, q in ipairs(rule.fallbackQuestInLog) do
          local qid = tonumber(q)
          if qid and qid > 0 and IsQuestInLog(qid) then
            ok = true
            break
          end
        end
      end

      if not ok and type(rule.fallbackItemInBags) == "table" then
        for _, it in ipairs(rule.fallbackItemInBags) do
          local itemID = tonumber(it)
          if itemID and itemID > 0 then
            local have = GetItemCountSafe(itemID)
            if (tonumber(have) or 0) > 0 then
              ok = true
              break
            end
          end
        end
      end
      if not ok then
        return nil
      end
    end
  end

  local disabled = IsRuleDisabled(rule)
  if disabled then
    return nil
  end

  -- Prereqs gate
  if applyGates and not ArePrereqsMet(rule.prereq) then
    return nil
  end

  -- Hide if any quest is currently in log (useful to avoid duplicate reminder rows)
  if applyGates and type(rule) == "table" and type(rule.hideIfAnyQuestInLog) == "table" then
    for _, q in ipairs(rule.hideIfAnyQuestInLog) do
      local qid = tonumber(q)
      if qid and qid > 0 and IsQuestInLog(qid) then
        return nil
      end
    end
  end

  -- Hide if any quest is completed (useful when quests drop from log on completion)
  if applyGates and not forceShowWhileQuestInLog and type(rule) == "table" and type(rule.hideQID) == "table" then
    for _, q in ipairs(rule.hideQID) do
      local qid = tonumber(q)
      if qid and qid > 0 and IsQuestCompleted(qid) then
        return nil
      end
    end
  end

  -- Hide a generic reminder if we've already learned which TW weekly is active this reset.
  if applyGates and type(rule) == "table" and rule.hideIfRememberedTimewalkingKind == true then
    if HasRememberedWeeklyTimewalkingKind() then
      return nil
    end
  end

  -- Class gate (optional)
  if applyGates and type(rule) == "table" and rule.class ~= nil then
    local have = tostring((ctx and ctx.class) or GetPlayerClass() or ""):upper()
    local want = rule.class

    if type(want) == "table" then
      local ok = false
      for _, c in ipairs(want) do
        if tostring(c):upper() == have then
          ok = true
          break
        end
      end
      if not ok then
        return nil
      end
    else
      local w = tostring(want):upper()
      if w ~= "" and w ~= "NONE" then
        if have == "" or have ~= w then
          return nil
        end
      end
    end
  end

  -- Profession gate (optional): skillLineID or profession name.
  -- Uses trade-skill-line querying when available (supports secondary/archaeology/etc).
  if applyGates and type(rule) == "table" and rule.profession ~= nil then
    local ok = false
    if CanQueryTradeSkillLines and CanQueryTradeSkillLines() and HasTradeSkillLine then
      ok = HasTradeSkillLine(rule.profession) and true or false
    elseif HasProfession then
      ok = HasProfession(rule.profession) and true or false
    end
    if not ok then
      return nil
    end
  end

  -- Profession skillLine gate (optional): checks any profession returned by GetProfessions().
  -- Useful for cases where spellKnown is unreliable (e.g. Mining across expansion variants).
  if applyGates and type(rule) == "table" and rule.profSID ~= nil then
    if not HasProfessionSkillLineID(rule.profSID) then
      return nil
    end
  end

  -- Missing profession skillLine gate (optional): show only if the player does NOT have this skillLineID.
  -- Intended for "you are missing this profession" reminders where spell-based gates are unreliable.
  if applyGates and type(rule) == "table" and rule.xprofSID ~= nil then
    if HasExactProfessionSkillLineID(rule.xprofSID) then
      return nil
    end
  end

  -- Find Fish unlock gate (optional): derived from minimap tracking entries.
  if applyGates and type(rule) == "table" and (rule.findFish ~= nil or rule.hasFindFish ~= nil) then
    local want = (rule.findFish ~= nil) and (rule.findFish == true) or (rule.hasFindFish == true)
    if PlayerHasFindFishUnlocked() ~= want then
      return nil
    end
  end

  if applyGates and type(rule) == "table" and rule.missingFindFish ~= nil then
    local missing = (rule.missingFindFish == true)
    local wantUnlocked = (not missing)
    if PlayerHasFindFishUnlocked() ~= wantUnlocked then
      return nil
    end
  end

  -- Primary-professions-missing gate (optional)
  if applyGates and type(rule) == "table" and rule.xprofPRI == true then
    if not (IsPrimaryProfessionSlotMissing(1) or IsPrimaryProfessionSlotMissing(2)) then
      return nil
    end
  end

  -- Not-in-group gate (optional)
  if applyGates and type(rule) == "table" and rule.notInGroup == true then
    if (ctx and ctx.isInGroup) or IsInGroupSafe() then
      return nil
    end
  end

  -- Location gate (optional; uiMapID)
  if applyGates and type(rule) == "table" and rule.mapID ~= nil then
    local wants = ParseLocationIDs(rule.mapID)
    if wants and wants[1] then
      local have = (ctx and ctx.mapID) or GetBestMapIDSafe()
      if have then
        local ok = false
        for i = 1, #wants do
          if have == wants[i] then ok = true break end
        end
        if not ok then return nil end
      end
    end
  end

  -- Spell gates (optional)
  if applyGates and type(rule) == "table" then
    local function CheckValue(v, shouldKnow)
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

    -- Any-of variant: at least one spell must match.
    local function CheckAnyValue(v)
      if v == nil then return true end
      local list = {}
      if type(v) == "table" then
        list = v
      else
        list = { v }
      end
      for _, id in ipairs(list) do
        if IsSpellKnownSafe(id) then
          return true
        end
      end
      return false
    end

    -- Support legacy/capitalized DB keys.
    -- IMPORTANT: these are aliases, not fallbacks-on-failure.
    -- NOTE: spellKnown with a table means ALL listed spells must be known.
    -- Use spellKnownAny for OR semantics.
    local spellKnownGate = (rule.spellKnown ~= nil) and rule.spellKnown or rule.SpellKnown
    local notSpellKnownGate = (rule.notSpellKnown ~= nil) and rule.notSpellKnown or rule.NotSpellKnown
    local spellKnownAnyGate = (rule.spellKnownAny ~= nil) and rule.spellKnownAny or rule.SpellKnownAny

    if not CheckValue(spellKnownGate, true) then return nil end
    if not CheckValue(notSpellKnownGate, false) then return nil end
    if not CheckAnyValue(spellKnownAnyGate) then return nil end
  end

  -- Rested-area gate (optional)
  if applyGates and type(rule) == "table" and rule.restedOnly == true then
    if not IsRestingSafe() then
      return nil
    end
  end

  -- Gold gate (optional): rule.gold is entered in gold, compared against GetMoney() (copper).
  if applyGates and type(rule) == "table" and tonumber(rule.gold) then
    local haveCopper = (type(GetMoney) == "function") and (tonumber(GetMoney()) or 0) or 0
    if haveCopper < (tonumber(rule.gold) * 10000) then
      return nil
    end
  end

  -- Reputation gate (optional)
  if applyGates and type(rule) == "table" and type(rule.rep) == "table" and rule.rep.factionID then
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
  if applyGates and type(rule) == "table" and rule.faction ~= nil then
    local wantRaw = tostring(rule.faction)
    local wantLower = wantRaw:lower()
    local want = (wantLower == "alliance" or wantLower == "a") and "Alliance"
      or (wantLower == "horde" or wantLower == "h") and "Horde" or nil
    if want then
      local have = (ctx and ctx.faction) or GetPlayerFaction()
      if have and tostring(have) ~= want then
        return nil
      end
    end
  end

  -- Level gate (useful for Timewalking "max" vs "leveling" variants)
  if applyGates and type(rule) == "table" and rule.levelGate ~= nil then
    local g = tostring(rule.levelGate):lower()
    local atMax = (ctx and ctx.isAtMaxLevel ~= nil) and (ctx.isAtMaxLevel and true or false) or IsAtMaxLevel()
    if g == "max" and not atMax then
      return nil
    end
    if (g == "level" or g == "leveling" or g == "lvl") and atMax then
      return nil
    end
  end

  -- Player level gate (optional; applies to any rule type)
  if applyGates and not IsPlayerLevelGateMet(rule, ctx) then
    return nil
  end

  -- Only show while quest is active/in log (useful for weekly/time-limited quests)
  -- Exception: if the quest is already completed and the rule is configured to
  -- keep showing when completed, allow it to remain visible even if it drops
  -- out of the quest log (Timewalking weeklies commonly do this).
  if applyGates and questID and rule.requireInLog == true and not IsQuestInLog(questID) then
    if not (completed and hideDone == false) then
      -- Special-case for Timewalking: token rows and other indicators intentionally
      -- appear on alts once the weekly kind is known. Allow specific TW quest rows
      -- to bypass requireInLog when the current TW kind has been remembered.
      if type(rule) == "table" and rule.showIfRememberedTimewalkingKind == true and rule.twKind ~= nil then
        local anyTW = (ns and ns.Calendar and ns.Calendar.IsAnyTimewalkingEventActive) or nil
        if type(anyTW) == "function" and anyTW() and HasRememberedWeeklyTimewalkingKind(rule.twKind) then
          -- ok
        else
          return nil
        end
      else
      return nil
      end
    end
  end

  -- Aura gate
  if applyGates and type(rule.aura) == "table" then
    local has = nil
    local rememberedKey = nil
    local calendarUnknown = false

    if rule.aura.eventKind == "timewalking" then
      local anyTW = (ns and ns.Calendar and ns.Calendar.IsAnyTimewalkingEventActive) or nil
      if type(anyTW) == "function" then
        has = anyTW() and true or false
        calendarUnknown = false
      else
        has = false
        calendarUnknown = true
      end
      rememberedKey = "event:timewalking"
    elseif rule.aura.eventKind == "calendar" then
      local kws = rule.aura.keywords or rule.aura.keyword or rule.aura.text
      local calFn = (ns and ns.Calendar and ns.Calendar.IsCalendarEventActiveByKeywords) or nil
      if type(calFn) == "function" then
        has, calendarUnknown = calFn(kws, rule.aura.includeHolidayText == true)
      else
        has, calendarUnknown = false, true
      end

      local ckFn = (ns and ns.Calendar and ns.Calendar.CalendarKeywordCacheKey) or nil
      local ck = (type(ckFn) == "function") and ckFn(kws) or nil
      if ck and ck ~= "" then
        rememberedKey = "event:calendar:" .. ck
      end
    elseif rule.aura.spellID then
      local spellID = tonumber(rule.aura.spellID)
      rememberedKey = spellID
      if rule.aura.eventActive == true then
        local twFn = (ns and ns.Calendar and ns.Calendar.IsTimewalkingBonusEventActive) or nil
        has = (type(twFn) == "function") and (twFn(spellID) and true or false) or false
      else
        has = HasAuraSpellID(spellID)
      end
    end

    if has ~= nil then
      if has and rule.aura.rememberDaily == true and (rule.aura.mustHave ~= false) and (not editMode) then
        RememberDailyAura(rememberedKey)
      end
      if has and rule.aura.rememberWeekly == true and (rule.aura.mustHave ~= false) and (not editMode) then
        RememberWeeklyAura(rememberedKey)
      end
      if (not has) and rule.aura.rememberDaily == true and (rule.aura.mustHave ~= false) then
        if calendarUnknown == true then
          has = HasRememberedDailyAura(rememberedKey) or has
        end
      end
      if (not has) and rule.aura.rememberWeekly == true and (rule.aura.mustHave ~= false) then
        if calendarUnknown == true then
          has = HasRememberedWeeklyAura(rememberedKey) or has
        end
      end
      if rule.aura.mustHave and not has then
        local overrideMapID = tonumber(rule.mapIO or rule.locationOverrideMapID)
        if overrideMapID and overrideMapID > 0 then
          local haveMapID = (ctx and ctx.mapID) or (GetBestMapIDSafe and GetBestMapIDSafe()) or nil
          if haveMapID and haveMapID == overrideMapID then
            has = true
          else
            return nil
          end
        else
          return nil
        end
      end
      if (rule.aura.mustHave == false) and has then
        return nil
      end
    end
  end

  -- Item gate/progress
  local extra = nil
  local shoppingListText = nil
  local currencyGate = nil
  local repDisplayGate = nil

  -- Explicit extra override (used for helper tasks)
  if type(rule) == "table" and rule.extra ~= nil then
    extra = tostring(rule.extra)
  end

  -- Currency progress placeholders for questInfo/spellInfo/textInfo.
  -- For quest rules, currency gates commonly live under showIf (e.g. Archaeology fragments).
  -- We extract the first currency gate we can find so $hv/$rq/{currency} placeholders render.
  if type(rule) == "table" and currencyGate == nil then
    local function ExtractCurrencyGate(node)
      if type(node) ~= "table" then return nil, nil, nil end

      if type(node.any) == "table" then
        for _, child in ipairs(node.any) do
          local cid, req, clamp = ExtractCurrencyGate(child)
          if cid and cid > 0 then return cid, req, clamp end
        end
      end

      if type(node.all) == "table" then
        for _, child in ipairs(node.all) do
          local cid, req, clamp = ExtractCurrencyGate(child)
          if cid and cid > 0 then return cid, req, clamp end
        end
      end

      if node.currencyID ~= nil then
        if type(node.currencyID) == "table" then
          return tonumber(node.currencyID[1]), tonumber(node.currencyID[2]), node.currencyID[3]
        end
        return tonumber(node.currencyID), tonumber(node.currencyRequired) or tonumber(node.required) or tonumber(node.count), nil
      end
      if type(node.currency) == "table" then
        local cid = tonumber(node.currency.currencyID or node.currency.id or node.currency[1])
        local req = tonumber(node.currency.required or node.currency[2] or node.required or node.count)
        return cid, req, node.currency.clampToRequired or node.currency.clamp
      end
      return nil, nil, nil
    end

    local cid, req, clamp = ExtractCurrencyGate(rule)
    if not (cid and cid > 0) and type(rule.showIf) == "table" then
      cid, req, clamp = ExtractCurrencyGate(rule.showIf)
    end

    if cid and cid > 0 then
      local charQty = (ns and ns.GetCurrencyQuantitySafe and ns.GetCurrencyQuantitySafe(cid)) or 0
      local isWB = (ns and ns.IsCurrencyWarbandTransferableSafe and ns.IsCurrencyWarbandTransferableSafe(cid)) or false
      local wbTotal = nil
      local gateQty = charQty
      if isWB then
        wbTotal = (ns and ns.GetWarbandCurrencyTotalSafe) and select(1, ns.GetWarbandCurrencyTotalSafe(cid, true)) or nil
        if wbTotal ~= nil then
          gateQty = wbTotal
        end
      end
      currencyGate = {
        id = cid,
        required = tonumber(req) or 0,
        charQty = charQty,
        wbTotal = wbTotal,
        gateQty = gateQty,
        isWarbandTransferable = isWB,
      }

      local clampFlag = clamp
      if clampFlag == nil and type(rule) == "table" then
        clampFlag = rule.currencyClampToRequired
        if clampFlag == nil then clampFlag = rule.currencyClamp end
      end
      currencyGate.clampToRequired = (clampFlag == true or clampFlag == "Y")
    end
  end

  -- Reputation display placeholders for questInfo/spellInfo/textInfo.
  -- Unlike rule.rep / showIf.rep, this is *display-only* and does not gate visibility.
  if type(rule) == "table" and repDisplayGate == nil then
    local rd = rule.repDisplay
    if type(rd) == "table" then
      local fid = tonumber(rd.factionID or rd.factionId or rd.id or rd[1])
      local min = tonumber(rd.minStanding or rd.min or rd.required or rd.req or rd[2])
      if fid and fid > 0 and min and min > 0 then
        repDisplayGate = { factionID = fid, minStanding = min }
      end
    end
  end

  if type(rule.item) == "table" and rule.item.itemID then
    local itemID = tonumber(rule.item.itemID)

    if applyGates then
      local currencyID, currencyRequired = GetItemCurrencyGate(rule.item)
      if currencyID and currencyRequired then
        local charQty = (ns and ns.GetCurrencyQuantitySafe and ns.GetCurrencyQuantitySafe(currencyID)) or 0
        local isWB = (ns and ns.IsCurrencyWarbandTransferableSafe and ns.IsCurrencyWarbandTransferableSafe(currencyID)) or false
        local wbTotal = nil
        local gateQty = charQty
        if isWB then
          wbTotal = (ns and ns.GetWarbandCurrencyTotalSafe) and select(1, ns.GetWarbandCurrencyTotalSafe(currencyID, true)) or nil
          if wbTotal ~= nil then
            gateQty = wbTotal
          end
        end

        if gateQty < currencyRequired then
          return nil
        end

        currencyGate = {
          id = currencyID,
          required = currencyRequired,
          charQty = charQty,
          wbTotal = wbTotal,
          gateQty = gateQty,
          isWarbandTransferable = isWB,
        }
      end
    end

    -- Optional quest-gating for quest-collection items.
    if applyGates then
      local qid = tonumber(rule.item.questID)
      if qid and qid > 0 and IsQuestCompleted(qid) then
        return nil
      end
      local after = tonumber(rule.item.afterQuestID)
      if after and after > 0 and not IsQuestCompleted(after) then
        return nil
      end
    end

    local count = GetItemCountSafe(itemID, (rule.item.includeBank == true) or (rule.item.inBank == true), rule.item)

    if applyGates then
      local showBelow = tonumber(rule.item.showWhenBelow)
      if showBelow and showBelow > 0 and count >= showBelow then
        return nil
      end
    end

    if applyGates then
      local req, hideWhenAcquired = GetItemRequiredGate(rule.item)
      if hideWhenAcquired == true and count > 0 then
        return nil
      end
      if rule.item.mustHave and count <= 0 then
        return nil
      end
    end

    do
      local req = tonumber((select(1, GetItemRequiredGate(rule.item))))
      if req and req > 0 then
        extra = string.format("%d/%d", count, req)
      else
        local showBelow = tonumber(rule.item.showWhenBelow)
        if showBelow and showBelow > 0 then
          extra = string.format("%d/%d", count, showBelow)
        else
          extra = tostring(count)
        end
      end
    end

  end

  -- Quest objective progress (for weekly/delve/timewalking style quests)
  if type(rule.progress) == "table" then
    if rule.progress.objectiveIndex then
      local txt = GetQuestObjectiveProgressText(questID, rule.progress.objectiveIndex)
      if txt then extra = txt end
    elseif type(rule.progress.merge) == "table" and rule.progress.merge[1] ~= nil then
      local sep = (rule.progress.sep ~= nil) and tostring(rule.progress.sep) or " | "
      local requireAll = (rule.progress.requireAll ~= false)

      local parts = {}
      local allOk = true

      for _, spec in ipairs(rule.progress.merge) do
        local qid, oidx
        if type(spec) == "table" then
          qid = tonumber(spec.questID or spec.questId or spec.qid or spec[1])
          oidx = tonumber(spec.objectiveIndex or spec.objIndex or spec.objective or spec[2])
        else
          qid = tonumber(spec)
        end
        if not (qid and qid > 0) then
          qid = questID
        end
        if not (oidx and oidx > 0) then
          oidx = 1
        end

        local txt = (qid and oidx) and GetQuestObjectiveProgressText(qid, oidx, { allowCompletedFallback = true }) or nil
        if not txt then
          allOk = false
          if requireAll then
            break
          end
        end
        parts[#parts + 1] = txt or ""
      end

      if (not requireAll) then
        local nonEmpty = {}
        for i = 1, #parts do
          if parts[i] ~= "" then
            nonEmpty[#nonEmpty + 1] = parts[i]
          end
        end
        if nonEmpty[1] ~= nil then
          extra = table.concat(nonEmpty, sep)
        end
      elseif allOk and parts[1] ~= nil then
        extra = table.concat(parts, sep)
      end
    end
  end

  -- Optional quest shopping list (typically vendor mats).
  -- Embed using %sl / {shoppingList} in questInfo.
  if not completed and type(rule) == "table" and type(rule.shopping) == "table" and rule.shopping[1] ~= nil then
    local qi = (type(rule.questInfo) == "string") and rule.questInfo or nil
    local wantsShoppingList = qi and (
      qi:find("%sl", 1, true)
      or qi:find("{shoppingList}", 1, true)
    )
    local shouldBuildList = wantsShoppingList

    if shouldBuildList then
      local lines = {}
      for _, it in ipairs(rule.shopping) do
        if type(it) == "table" then
          local itemID = tonumber(it.itemID or it.id)
          local need = tonumber(it.required or it.count or it.need)
          if itemID and itemID > 0 and need and need > 0 then
            local have = GetItemCountSafe(itemID, (it.includeBank == true) or (it.inBank == true), it)
            if have < 0 then have = 0 end
            local name = GetItemNameSafe(itemID)
            if not name or name == "" then
              name = "Loading..."
            end
            lines[#lines + 1] = string.format("  - %s %d/%d", tostring(name), tonumber(have) or 0, tonumber(need) or 0)
          end
        end
      end

      if lines[1] ~= nil then
        shoppingListText = table.concat(lines, "\n")
      end
    end
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
      ---@diagnostic disable-next-line: param-type-mismatch
      s = s:gsub("^([ \t]+)", Conv)
      ---@diagnostic disable-next-line: param-type-mismatch
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
  elseif type(rule) == "table" and type(rule.item) == "table" and rule.item.itemID then
    local itemName = (rule.label ~= nil and tostring(rule.label) ~= "") and tostring(rule.label) or (GetItemNameSafe(rule.item.itemID) or ("Item " .. tostring(rule.item.itemID)))
    rawTitle = itemName
    if rule.itemInfo ~= nil and tostring(rule.itemInfo) ~= "" then
      title = tostring(rule.itemInfo)
    else
      title = itemName
    end
  elseif type(rule) == "table" and (rule.spellKnown or rule.notSpellKnown or rule.SpellKnown or rule.NotSpellKnown) then
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

    local spellID = PickSpellID(rule.spellKnown) or PickSpellID(rule.SpellKnown) or PickSpellID(rule.notSpellKnown) or PickSpellID(rule.NotSpellKnown)
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
    local spellName = (rule.label ~= nil and tostring(rule.label) ~= "") and tostring(rule.label) or (name or (spellID and ("Spell " .. tostring(spellID)) or "Spell"))
    rawTitle = spellName
    if rule.spellInfo ~= nil and tostring(rule.spellInfo) ~= "" then
      title = tostring(rule.spellInfo)
    else
      title = spellName
    end
  else
    local textName = (type(rule) == "table" and rule.label ~= nil and tostring(rule.label) ~= "") and tostring(rule.label) or "Task"
    rawTitle = textName
    if type(rule) == "table" and (rule.preferQuestInfoForTitle == true or (type(rule.aura) == "table" and rule.aura.eventKind == "calendar")) then
      local qiLine = FirstNonEmptyLine(rule.questInfo)
      if qiLine then
        -- Intentionally allow NBSP/blank-like questInfo to suppress label text (used by TW token rows).
        title = tostring(qiLine)
      end
    end

    if title == nil and type(rule) == "table" and rule.textInfo ~= nil and tostring(rule.textInfo) ~= "" then
      title = tostring(rule.textInfo)
    else
      title = title or textName
    end
  end

  if completed and type(rule) == "table" and rule.labelComplete then
    title = tostring(rule.labelComplete)
    rawTitle = title
  end

  local function ApplyShorthandPlaceholders(s)
    if type(s) ~= "string" then return s, false end
    local before = s

    -- Progress shorthand
    s = s:gsub("%%p", "{progress}")

    -- Shopping-list shorthand (vendor mats)
    s = s:gsub("%%sl", "{shoppingList}")

    -- Currency shorthands
    s = s:gsub("%$rq", "{currency:req}")
    s = s:gsub("%$nm", "{currency:name}")
    -- Amount used for gating (warband total when transferable; otherwise character amount)
    s = s:gsub("%$hv", "{currency}")
    s = s:gsub("%$ga", "{currency}")
    -- Character-only amount
    s = s:gsub("%$cc", "{currency:char}")
    s = s:gsub("%$wb", "{currency:wb}")

    return s, s ~= before
  end

  do
    local newTitle = title
    newTitle = (select(1, ApplyShorthandPlaceholders(newTitle)))
    title = newTitle
  end

  local function ApplyCurrencyPlaceholders(s, g)
    if type(s) ~= "string" then return s, false end
    if type(g) ~= "table" or not g.id then return s, false end
    if not s:find("{currency", 1, true) then
      return s, false
    end

    local GREEN = (_G and rawget(_G, "GREEN_FONT_COLOR_CODE")) or "|cff00ff00"
    local CLOSE = (_G and rawget(_G, "FONT_COLOR_CODE_CLOSE")) or "|r"
    local gateOk = (tonumber(g.required) or 0) > 0 and (tonumber(g.gateQty) or 0) >= (tonumber(g.required) or 0)

    local info = (ns and ns.GetCurrencyInfoSafe and ns.GetCurrencyInfoSafe(g.id))
    local name = (type(info) == "table" and info.name) or ""
    local haveNum = tonumber(g.gateQty) or 0
    local reqNum = tonumber(g.required) or 0
    if g.clampToRequired == true and reqNum > 0 and haveNum > reqNum then
      haveNum = reqNum
    end

    local repHave = tostring(haveNum)
    local repChar = tostring(tonumber(g.charQty) or 0)
    local repWB = (g.wbTotal ~= nil) and tostring(tonumber(g.wbTotal) or 0) or ""
    local repReq = tostring(tonumber(g.required) or 0)
    local repName = tostring(name or "")

    local before = s
    s = s:gsub("\r", "\n")

    local lines = {}
    local start = 1
    while true do
      local pos = s:find("\n", start, true)
      if not pos then
        lines[#lines + 1] = s:sub(start)
        break
      end
      lines[#lines + 1] = s:sub(start, pos - 1)
      start = pos + 1
    end

    for i = 1, #lines do
      local line = lines[i]
      local wantsColor = gateOk and line:find("{currency", 1, true)
      line = line:gsub("{currency}", repHave)
      line = line:gsub("{currency:have}", repHave)
      line = line:gsub("{currency:char}", repChar)
      line = line:gsub("{currency:wb}", repWB)
      line = line:gsub("{currency:req}", repReq)
      line = line:gsub("{currency:name}", repName)
      line = line:gsub("%s+$", "")
      if wantsColor then
        line = GREEN .. line .. CLOSE
      end
      lines[i] = line
    end

    local out = table.concat(lines, "\n")
    return out, out ~= before
  end

  do
    local newTitle = title
    local replaced = false
    newTitle, replaced = ApplyCurrencyPlaceholders(newTitle, currencyGate)
    if replaced then
      title = newTitle
    end
  end

  local function RepStandingLabelLite(standing)
    standing = tonumber(standing)
    if not standing then return "Unknown" end
    if standing == 1 then return "Hated" end
    if standing == 2 then return "Hostile" end
    if standing == 3 then return "Unfriendly" end
    if standing == 4 then return "Neutral" end
    if standing == 5 then return "Friendly" end
    if standing == 6 then return "Honored" end
    if standing == 7 then return "Revered" end
    if standing == 8 then return "Exalted" end
    return "Unknown"
  end

  local function ApplyRepPlaceholders(s, g)
    if type(s) ~= "string" then return s, false end
    if type(g) ~= "table" or not g.factionID then return s, false end
    if not s:find("{rep", 1, true) then
      return s, false
    end

    local GREEN = (_G and rawget(_G, "GREEN_FONT_COLOR_CODE")) or "|cff00ff00"
    local CLOSE = (_G and rawget(_G, "FONT_COLOR_CODE_CLOSE")) or "|r"

    local factionID = tonumber(g.factionID)
    local reqStanding = tonumber(g.minStanding)
    if not (factionID and factionID > 0) then return s, false end

    local haveStanding = (ns and ns.GetStandingIDByFactionID and ns.GetStandingIDByFactionID(factionID)) or nil
    local haveLabel = RepStandingLabelLite(haveStanding)
    local reqLabel = RepStandingLabelLite(reqStanding)
    local repOk = (tonumber(reqStanding) or 0) > 0 and (tonumber(haveStanding) or 0) >= (tonumber(reqStanding) or 0)

    local fname = ""
    local GFI = _G and rawget(_G, "GetFactionInfoByID")
    if type(GFI) == "function" then
      local ok, n = pcall(GFI, factionID)
      if ok and type(n) == "string" and n ~= "" then fname = n end
    end

    local before = s
    s = s:gsub("\r", "\n")

    local lines = {}
    local start = 1
    while true do
      local pos = s:find("\n", start, true)
      if not pos then
        lines[#lines + 1] = s:sub(start)
        break
      end
      lines[#lines + 1] = s:sub(start, pos - 1)
      start = pos + 1
    end

    for i = 1, #lines do
      local line = lines[i]
      local wantsColor = repOk and line:find("{rep", 1, true)
      line = line:gsub("{rep}", haveLabel)
      line = line:gsub("{rep:have}", haveLabel)
      line = line:gsub("{rep:req}", reqLabel)
      line = line:gsub("{rep:name}", tostring(fname or ""))
      line = line:gsub("%s+$", "")
      if wantsColor then
        line = GREEN .. line .. CLOSE
      end
      lines[i] = line
    end

    local out = table.concat(lines, "\n")
    return out, out ~= before
  end

  do
    local newTitle = title
    local replaced = false
    newTitle, replaced = ApplyRepPlaceholders(newTitle, repDisplayGate)
    if replaced then
      title = newTitle
    end
  end

  do
    -- If both the currency and rep targets are met, color the primary title line green.
    -- This is display-only (does not affect gating).
    local function IsCurrencyTargetMet(g)
      if type(g) ~= "table" then return false end
      local req = tonumber(g.required) or 0
      local have = tonumber(g.gateQty) or 0
      return req > 0 and have >= req
    end

    local function IsRepTargetMet(g)
      if type(g) ~= "table" then return false end
      local fid = tonumber(g.factionID)
      local req = tonumber(g.minStanding) or 0
      if not (fid and fid > 0 and req > 0) then return false end
      local have = (ns and ns.GetStandingIDByFactionID and ns.GetStandingIDByFactionID(fid)) or nil
      have = tonumber(have) or 0
      return have >= req
    end

    if IsCurrencyTargetMet(currencyGate) and IsRepTargetMet(repDisplayGate) and type(title) == "string" then
      local GREEN = (_G and rawget(_G, "GREEN_FONT_COLOR_CODE")) or "|cff00ff00"
      local CLOSE = (_G and rawget(_G, "FONT_COLOR_CODE_CLOSE")) or "|r"

      local s = title:gsub("\r", "\n")
      local firstLine, rest = s:match("^([^\n]*)(.*)$")
      if firstLine and firstLine ~= "" then
        title = GREEN .. firstLine .. CLOSE .. (rest or "")
      end
    end
  end

  local function ApplyExtraPlaceholder(s, extraText)
    if type(s) ~= "string" then return s, false end
    if not (s:find("{progress}", 1, true) or s:find("{extra}", 1, true)) then
      return s, false
    end
    local rep = extraText or ""
    local before = s
    s = s:gsub("{progress}", rep)
    s = s:gsub("{extra}", rep)
    if rep == "" then
      s = s:gsub("%s+$", "")
    end
    return s, s ~= before
  end

  do
    local newTitle, replaced = ApplyExtraPlaceholder(title, extra)
    if replaced then
      title = newTitle
      extra = nil
    end
  end

  local function ApplyShoppingListPlaceholder(s, slText)
    if type(s) ~= "string" then return s, false end
    if not s:find("{shoppingList}", 1, true) then
      return s, false
    end
    local rep = slText or ""
    local before = s
    s = s:gsub("{shoppingList}", rep)
    if rep == "" then
      s = s:gsub("%s+$", "")
    end
    return s, s ~= before
  end

  do
    local newTitle, replaced = ApplyShoppingListPlaceholder(title, shoppingListText)
    if replaced then
      title = newTitle
    end
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
    if type(r) == "table" and (r.spellKnown or r.notSpellKnown or r.SpellKnown or r.NotSpellKnown or r.mapID or r.class or r.notInGroup) then
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

    do
      local op, lvl = GetPlayerLevelGate(rule)
      if op and lvl then
        editText = editText .. string.format(" [Lvl %s %d]", op, lvl)
      end
    end
  end

  local indicators = BuildIndicators(rule)

  if type(rule) == "table" and (rule.color ~= nil or rule.Color ~= nil or rule.fontColor ~= nil or rule.FontColor ~= nil) then
    local c = rule.color or rule.Color or rule.fontColor or rule.FontColor
    if c ~= false and tostring(c):lower() ~= "inherit" then
      title = ColorText(c, title)
    end
  end

  return {
    questID = questID,
    title = title,
    rawTitle = rawTitle,
    editText = editText,
    extra = extra,
    completed = completed,
    hideDone = hideDone,
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
local frame

local UpdateAnchorLabel
local FindCustomRuleIndex
local UnassignRuleFromFrame

-- Tracker frame system was split to fUI_QTUsageUX.lua (loaded before this file)
local function _fqtNoop(...) end
local function _fqtFalse(...) return false end
local function _fqtNil(...) return nil end

local TF = (type(ns) == "table") and ns.TrackerFrames or nil
local NormalizeAnchorCorner = (TF and TF.NormalizeAnchorCorner) or _fqtNil
local PointToAnchorCorner = (TF and TF.PointToAnchorCorner) or _fqtNil
local ApplyFAOBackdrop = (TF and TF.ApplyFAOBackdrop) or _fqtNoop
local ApplyVisLink = (TF and TF.ApplyVisLink) or _fqtFalse
local ApplyFramePositionFromDef = (TF and TF.ApplyFramePositionFromDef) or _fqtFalse
local NudgeFrameOnScreen = (TF and TF.NudgeFrameOnScreen) or _fqtFalse
local CreateBarFrame = (TF and TF.CreateBarFrame) or _fqtNil
local CreateListFrame = (TF and TF.CreateListFrame) or _fqtNil

ApplyTrackerInteractivity = function()
  if TF and TF.ApplyTrackerInteractivity then
    return TF.ApplyTrackerInteractivity(framesByID, frame)
  end
end

local function OnModifierStateChanged()
  if TF and TF.OnModifierStateChanged then
    return TF.OnModifierStateChanged(frame, ApplyTrackerInteractivity)
  end
end

local function OnPlayerRegenEnabled_Interactivity()
  if TF and TF.OnPlayerRegenEnabled_Interactivity then
    return TF.OnPlayerRegenEnabled_Interactivity(frame, ApplyTrackerInteractivity)
  end
end

ns.GetTrackerFrameByID = function(id)
  id = tostring(id or "")
  if id == "" then return nil end
  return framesByID and framesByID[id] or nil
end

UpdateAnchorLabel = (TF and TF.UpdateAnchorLabel) or _fqtNoop

local function AssignRuleToFrame(rule, frameID)
  if type(rule) ~= "table" then return false end
  frameID = tostring(frameID or "")
  if frameID == "" then return false end

  -- QuestX/QuestY entries are not assignable to bars (list-only).
  do
    local xy = rule.questXY
    if xy ~= nil then
      xy = tostring(xy):upper()
      if xy == "X" or xy == "Y" then
        for _, def in ipairs(GetEffectiveFrames()) do
          if type(def) == "table" and tostring(def.id or "") == frameID then
            local t = tostring(def.type or "list"):lower()
            if t == "bar" then
              return false
            end
            break
          end
        end
      end
    end
  end

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

ns.AssignRuleToFrame = AssignRuleToFrame

local function ReorderCustomRulesInFrame(frame, movedRule, destAbsIndex)
  if type(movedRule) ~= "table" then return false end
  if not frame then return false end

  local function GetEntriesForOrdering(f)
    if type(f._lastAllEntries) == "table" then return f._lastAllEntries end
    if type(f._lastEntries) == "table" then return f._lastEntries end
    return nil
  end

  local entries = GetEntriesForOrdering(frame)
  if type(entries) ~= "table" then return false end

  local visibleRules = {}
  for i = 1, #entries do
    local r = entries[i] and entries[i].rule
    if type(r) == "table" then
      visibleRules[#visibleRules + 1] = r
    end
  end

  return (type(ns.ReorderRulesInFrameByID) == "function")
    and ns.ReorderRulesInFrameByID(frame._id, movedRule, destAbsIndex, visibleRules)
    or false
end

-- Reorder rules within a specific frame id.
--
-- This is used by both:
--   1) Edit-mode move buttons in actual frames (bar/list contents)
--   2) Options UI (Rules tab) where we don't have a rendered frame object
--
-- Parameters:
--   frameID (string)
--   movedRule (table)
--   destIndex (number)              -- index into `visibleRules`
--   visibleRules (table[] of rule)  -- the rules currently considered "visible" for ordering
local function ReorderRulesInFrameByID(frameID, movedRule, destIndex, visibleRules)
  frameID = tostring(frameID or "")
  if frameID == "" then return false end
  if type(movedRule) ~= "table" then return false end
  if type(visibleRules) ~= "table" then return false end

  local movedKey = RuleKey and RuleKey(movedRule) or nil
  if not movedKey then
    Print("That rule can't be reordered.")
    return false
  end

  destIndex = tonumber(destIndex) or 1
  if destIndex < 1 then destIndex = 1 end
  if destIndex > #visibleRules then destIndex = #visibleRules end
  if destIndex < 1 then return false end

  local destRule = visibleRules[destIndex]
  local destKey = (type(destRule) == "table") and (RuleKey and RuleKey(destRule) or nil) or nil
  if not destKey then return false end

  -- Per-frame ordering is stored on the custom frame def as `ruleOrder`.
  local function FindOrCreateCustomFrameDefLocal(id)
    id = tostring(id or "")
    if id == "" then return nil end
    local list = GetCustomFrames()
    for _, d in ipairs(list) do
      if type(d) == "table" and tostring(d.id or "") == id then
        return d
      end
    end
    local d = { id = id }
    list[#list + 1] = d
    return d
  end

  local def = FindOrCreateCustomFrameDefLocal(frameID)
  if type(def) ~= "table" then return false end

  -- Build the visible key sequence.
  local keys = {}
  for i = 1, #visibleRules do
    local r = visibleRules[i]
    local k = (type(r) == "table") and (RuleKey and RuleKey(r) or nil) or nil
    if k then keys[#keys + 1] = tostring(k) end
  end
  if #keys == 0 then return false end

  -- Ensure the stored order list contains all currently visible keys (keep existing order, append new).
  if type(def.ruleOrder) ~= "table" then def.ruleOrder = {} end
  local seen = {}
  for _, k in ipairs(def.ruleOrder) do
    seen[tostring(k)] = true
  end
  for _, k in ipairs(keys) do
    local kk = tostring(k)
    if not seen[kk] then
      def.ruleOrder[#def.ruleOrder + 1] = kk
      seen[kk] = true
    end
  end

  -- Create a current-order slice of ruleOrder for this frame's visible keys.
  local current = {}
  local currentIndex = {}
  for _, k in ipairs(def.ruleOrder) do
    local kk = tostring(k)
    if seen[kk] and not currentIndex[kk] then
      current[#current + 1] = kk
      currentIndex[kk] = #current
    end
  end

  local fromPos = currentIndex[tostring(movedKey)]
  local destPos = currentIndex[tostring(destKey)]
  if not fromPos or not destPos then return false end
  if fromPos == destPos then return true end

  table.remove(current, fromPos)
  table.insert(current, destPos, tostring(movedKey))

  -- Rewrite the stored order list so it matches the new current order for visible keys,
  -- while preserving any keys not currently visible (kept at the end).
  do
    local keep = {}
    local vis = {}
    for _, k in ipairs(current) do vis[k] = true end
    for _, k in ipairs(def.ruleOrder) do
      local kk = tostring(k)
      if not vis[kk] then
        keep[#keep + 1] = kk
      end
    end
    def.ruleOrder = {}
    for _, k in ipairs(current) do def.ruleOrder[#def.ruleOrder + 1] = k end
    for _, k in ipairs(keep) do def.ruleOrder[#def.ruleOrder + 1] = k end
  end

  return true
end

ns.ReorderRulesInFrameByID = ReorderRulesInFrameByID

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

  if type(frame._moveButtons) == "table" then
    local up = frame._moveButtons.up
    local down = frame._moveButtons.down
    if type(up) == "table" then
      for i = fromIndex, #up do
        local b = up[i]
        if b and b.Hide then b:Hide() end
      end
    end
    if type(down) == "table" then
      for i = fromIndex, #down do
        local b = down[i]
        if b and b.Hide then b:Hide() end
      end
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

local function EnsureFontString(parent, idx, fontDef)
  parent.items = parent.items or {}
  if parent.items[idx] then return parent.items[idx] end
  local fs = parent:CreateFontString(nil, "OVERLAY", parent._itemFont or "GameFontHighlight")
  fs:SetJustifyH("LEFT")
  ApplyFontStyle(fs, fontDef)
  do
    if fs.GetFont then
      local p, s, f = fs:GetFont()
      fs._defaultFont = { p, s, f }
    end
    if fs.GetTextColor then
      local r, g, b, a = fs:GetTextColor()
      fs._defaultTextColor = { r, g, b, a }
    end
  end
  parent.items[idx] = fs
  return fs
end

local function EnsureRowButton(frame, idx)
  if frame.buttons and frame.buttons[idx] then return frame.buttons[idx] end
  frame.buttons = frame.buttons or {}
  local b = CreateFrame("Button", nil, frame)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  -- Drag/drop reordering is intentionally disabled (it was unreliable).
  -- Use the per-row up/down buttons next to X instead.
  b:SetScript("OnEnter", function(self)
    if not editMode then return end
    local e = self and self._entry
    local r = e and e.rule
    if not r then return end

    local lbl = (r.label ~= nil) and tostring(r.label) or ""
    if lbl == "" then
      lbl = tostring(e.rawTitle or e.title or "")
    end
    if lbl == "" then return end

    if GameTooltip and GameTooltip.SetOwner and GameTooltip.SetText then
      GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
      GameTooltip:SetText(lbl, 1, 1, 1)
      if GameTooltip.AddLine then
        local key = RuleKey(r)
        local qid = tonumber(r.questID)
        if key or qid then
          GameTooltip:AddLine(string.format("%s  questID=%s", tostring(key or "(no key)"), tostring(qid or "")), 0.7, 0.7, 0.7)
        end
      end
      if GameTooltip.Show then GameTooltip:Show() end
    end
  end)
  b:SetScript("OnLeave", function()
    if GameTooltip and GameTooltip.Hide then GameTooltip:Hide() end
  end)
  b:SetScript("OnClick", function(self, button)
    if not editMode then return end
    local e = self._entry
    if not (e and e.rule) then return end

    -- Bar contents inspector: never toggle rule disable on simple click.
    -- (Clicking a row would otherwise effectively "remove" it from the bar.)
    if frame and frame._targetID then
      if button == "RightButton" then
        local r = e.rule
        local key = RuleKey(r) or "(no key)"
        Print(string.format("Rule: %s  questID=%s", key, tostring(r.questID)))
      end
      return
    end

    if button == "RightButton" then
      local r = e.rule
      local key = RuleKey(r) or "(no key)"
      Print(string.format("Rule: %s  questID=%s", key, tostring(r.questID)))
      return
    end
    -- Left-click in edit mode should NOT disable items; that's what the X is for.
    return
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

local function EnsureMoveButton(frame, idx, dir)
  if not frame then return nil end
  frame._moveButtons = frame._moveButtons or { up = {}, down = {} }
  dir = (dir == "down") and "down" or "up"
  if frame._moveButtons[dir] and frame._moveButtons[dir][idx] then
    return frame._moveButtons[dir][idx]
  end

  local b = CreateFrame("Button", nil, frame)
  b:SetSize(16, 16)
  b:SetFrameLevel((frame.GetFrameLevel and frame:GetFrameLevel() or 1) + 30)
  if dir == "up" then
    b:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
    b:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Down")
    b:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Highlight")
    b:SetDisabledTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Disabled")
  else
    b:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
    b:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Down")
    b:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Highlight")
    b:SetDisabledTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Disabled")
  end
  b:Hide()

  if not frame._moveButtons[dir] then frame._moveButtons[dir] = {} end
  frame._moveButtons[dir][idx] = b
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

ns.FindCustomRuleIndex = FindCustomRuleIndex

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

ns.UnassignRuleFromFrame = UnassignRuleFromFrame

local function RenderBar(frameDef, frame, entries)
  if type(ns) == "table" and type(ns.Render) == "table" and type(ns.Render.RenderBar) == "function" then
    return ns.Render.RenderBar(frameDef, frame, entries)
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
  local store = (TF and TF.GetFramePosStore and TF.GetFramePosStore()) or {}
  if wipe then
    wipe(store)
  else
    for k in pairs(store) do store[k] = nil end
  end

  -- Also clear any custom frame position overrides so effective defs fall back to layout defaults.
  -- (Positions can be stored either in the framePos store OR in customFrames itself.)
  local custom = GetCustomFrames and GetCustomFrames() or nil
  if type(custom) == "table" then
    for _, d in ipairs(custom) do
      if type(d) == "table" then
        d.point = nil
        d.relPoint = nil
        d.x = nil
        d.y = nil
        d.anchorCorner = nil
      end
    end
  end

  local baseByID = {}
  if type(ns) == "table" and type(ns.frames) == "table" then
    for _, d in ipairs(ns.frames) do
      if type(d) == "table" and tostring(d.id or "") ~= "" then
        baseByID[tostring(d.id)] = d
      end
    end
  end

  for _, def in ipairs(GetEffectiveFrames()) do
    local id = tostring(def.id or "")
    local f = framesByID[id]
    if f and f.ClearAllPoints and f.SetPoint then
      local baseDef = baseByID[id]
      local useDef = baseDef or def
      f:ClearAllPoints()
      local point = (type(useDef) == "table") and useDef.point or nil
      local relPoint = (type(useDef) == "table") and (useDef.relPoint or useDef.point) or nil
      local x = (type(useDef) == "table") and useDef.x or nil
      local y = (type(useDef) == "table") and useDef.y or nil
      if not point then
        point = "CENTER"
        relPoint = "CENTER"
        x = 0
        y = 0
      end
      f:SetPoint(point, UIParent, relPoint or point, tonumber(x) or 0, tonumber(y) or 0)
    end
  end
end

ns.ResetFramePositionsToDefaults = ResetFramePositionsToDefaults

-- Options UI was split out to fr0z3nUI_QuestTracker_Options.lua
-- (kept separate to reduce compile-time locals/upvalues in core)

local function RenderList(frameDef, frame, entries)
  if type(ns) == "table" and type(ns.Render) == "table" and type(ns.Render.RenderList) == "function" then
    return ns.Render.RenderList(frameDef, frame, entries)
  end
end

-- NOTE: bar inspector and heavy rendering moved to fUI_QTUsageUIR.lua

RefreshAll = function()
  NormalizeSV()

  local evalCtx = BuildEvalContext()

  local rules = GetEffectiveRules()

  local frames = GetEffectiveFrames()
  local frameDefsByID = {}
  local entriesByFrameID = {}
  local entriesByFrameIDActive = nil
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

  local function AddToFrameActive(frameID, status)
    if not (entriesByFrameIDActive and frameID and entriesByFrameIDActive[frameID]) then return end
    entriesByFrameIDActive[frameID][#entriesByFrameIDActive[frameID] + 1] = status
  end

  local staged = {}
  local function Stage(frameID, rule, status)
    staged[#staged + 1] = { frameID = frameID, rule = rule, status = status }
  end

  local function IsHiddenByCompletion(status)
    if not status then return false end
    if status.completed ~= true then return false end
    return status.hideDone == true
  end

  for _, rule in ipairs(rules) do
    -- QuestX/QuestY/KeepList rules are automation-only and should not be staged into any list/bar frames.
    if type(rule) == "table" and (rule.questXY == "X" or rule.questXY == "Y" or rule.questXY == "K") then
      -- skip
    else
      local status = BuildRuleStatus(rule, evalCtx)
      if status and (editMode or (not IsHiddenByCompletion(status))) then
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
  end

  -- In edit mode, bars should render only what's actually active (same as normal mode),
  -- but the bar "List" inspector should still show everything assigned to the bar.
  if editMode then
    entriesByFrameIDActive = {}
    for _, def in ipairs(frames) do
      local id = tostring(def.id or "")
      if id ~= "" then
        entriesByFrameIDActive[id] = entriesByFrameIDActive[id] or {}
      end
    end

    local stagedActive = {}
    local function StageActive(frameID, rule, status)
      stagedActive[#stagedActive + 1] = { frameID = frameID, rule = rule, status = status }
    end

    for _, rule in ipairs(rules) do
      if type(rule) == "table" and (rule.questXY == "X" or rule.questXY == "Y" or rule.questXY == "K") then
        -- skip
      else
        local status = BuildRuleStatus(rule, evalCtx, { forceNormalVisibility = true })
        if status and (not IsHiddenByCompletion(status)) then
          if type(rule.targets) == "table" then
            for _, frameID in ipairs(rule.targets) do
              StageActive(tostring(frameID), rule, status)
            end
          elseif rule.frameID then
            StageActive(tostring(rule.frameID), rule, status)
          else
            local display = tostring(rule.display or "list"):lower()
            if display ~= "bar" then display = "list" end
            for _, frameID in ipairs(frameIDsByType[display]) do
              StageActive(frameID, rule, status)
            end
          end
        end
      end
    end

    -- Apply normal (non-edit) sequential group collapsing for the active view.
    local winnersByGroup = {}
    for _, row in ipairs(stagedActive) do
      local frameID = row.frameID
      local rule = row.rule
      local status = row.status
      local group = rule and rule.group
      local order = tonumber(rule and rule.order) or 0

      local groupStr = (group ~= nil) and tostring(group) or ""
      local isDMF = (groupStr ~= "") and (groupStr:find("event:darkmoon-faire", 1, true) ~= nil)

      if group ~= nil and (not isDMF) then
        local key = frameID .. "|" .. tostring(group)
        local current = winnersByGroup[key]
        if not current or order < current.order then
          winnersByGroup[key] = { order = order, status = status, frameID = frameID }
        end
      else
        AddToFrameActive(frameID, status)
      end
    end

    for _, win in pairs(winnersByGroup) do
      AddToFrameActive(win.frameID, win.status)
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

      local groupStr = (group ~= nil) and tostring(group) or ""
      local isDMF = (groupStr ~= "") and (groupStr:find("event:darkmoon-faire", 1, true) ~= nil)

      if group ~= nil and (not isDMF) then
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

  -- Apply per-frame rule ordering overrides (after entries are built).
  do
    -- `ruleOrder` is stored on the custom frame def (SavedVariables), even when the
    -- frame being ordered is one of the built-in/default frames. Build a quick lookup
    -- so ordering works everywhere.
    local customOrderByID = {}
    do
      local custom = GetCustomFrames()
      if type(custom) == "table" then
        for _, cd in ipairs(custom) do
          local id = (type(cd) == "table") and tostring(cd.id or "") or ""
          if id ~= "" and type(cd.ruleOrder) == "table" then
            customOrderByID[id] = cd.ruleOrder
          end
        end
      end
    end

    for _, def in ipairs(frames) do
      local id = tostring(def and def.id or "")
      local ruleOrder = (type(def) == "table" and type(def.ruleOrder) == "table") and def.ruleOrder or customOrderByID[id]
      if id ~= "" and type(ruleOrder) == "table" then
        local orderIndex = {}
        for i, k in ipairs(ruleOrder) do
          orderIndex[tostring(k)] = i
        end
        local function SortFrameEntries(list)
          if type(list) ~= "table" or not list[1] then return end
          local orig = {}
          for i = 1, #list do orig[list[i]] = i end
          table.sort(list, function(a, b)
            local ra = a and a.rule
            local rb = b and b.rule
            local ka = ra and (RuleKey and RuleKey(ra) or nil)
            local kb = rb and (RuleKey and RuleKey(rb) or nil)
            local pa = ka and orderIndex[tostring(ka)] or nil
            local pb = kb and orderIndex[tostring(kb)] or nil
            if pa and pb and pa ~= pb then return pa < pb end
            if pa and not pb then return true end
            if pb and not pa then return false end
            return (orig[a] or 0) < (orig[b] or 0)
          end)
        end

        SortFrameEntries(entriesByFrameID[id])
        if entriesByFrameIDActive then
          SortFrameEntries(entriesByFrameIDActive[id])
        end
      end
    end
  end

  for _, def in ipairs(frames) do
    local id = tostring(def.id or "")
    local f = framesByID[id]
    if f then
      -- Apply size updates for existing frames.
      -- Note: CreateAllFrames() only creates missing frames; it does not re-apply sizing
      -- to already-created frames, so size edits (like list width) must be reflected here.
      do
        local t0 = tostring(def.type or "list"):lower()
        local w = tonumber(def.width) or 300
        if w < 1 then w = 1 end
        if t0 == "bar" then
          local h = tonumber(def.height) or 20
          if h < 1 then h = 1 end
          if f.SetSize then
            f:SetSize(w, h)
          elseif f.SetWidth then
            f:SetWidth(w)
          end
        else
          local rh = tonumber(def.rowHeight) or 16
          local mi = tonumber(def.maxItems) or 20
          local h = (rh or 16) * ((mi or 20) + 2)
          if type(def) == "table" and tonumber(def.maxHeight) and tonumber(def.maxHeight) > 0 then
            h = math.min(h, tonumber(def.maxHeight))
          end
          if f.SetSize then
            f:SetSize(w, h)
          elseif f.SetWidth then
            f:SetWidth(w)
          end
        end
      end

      -- `parentFrame` is legacy; re-parenting was removed.
      -- Keeping frames under UIParent avoids coordinate-space drift between edit mode and normal mode.

      if editMode then
        local a = (type(def) == "table") and tonumber(def.bgAlpha) or nil
        if not a or a < 0.25 then a = 0.25 end
        local c = (type(def) == "table") and def.bgColor or nil
        ApplyFAOBackdrop(f, a, c)
      elseif type(def) == "table" and (def.bgAlpha ~= nil or def.bgColor ~= nil) then
        ApplyFAOBackdrop(f, def.bgAlpha, def.bgColor)
      end

      local t = tostring(def.type or "list"):lower()
      local allEntries = entriesByFrameID[id] or {}
      local entries = allEntries
      if editMode and t == "bar" and entriesByFrameIDActive then
        entries = entriesByFrameIDActive[id] or {}
      end
      local hasAny = entries[1] ~= nil

      -- Used by edit-mode drag/drop.
      f._lastFrameDef = def
      f._lastEntries = entries
      f._lastAllEntries = (editMode and allEntries) or nil

      local baseScale = (type(def) == "table") and tonumber(def.scale) or nil
      if baseScale == nil then baseScale = 1 end
      if baseScale < 0.50 then baseScale = 0.50 end
      if baseScale > 2.00 then baseScale = 2.00 end
      if f.SetScale then f:SetScale(baseScale) end

      local forceHide = ApplyVisLink(f, def, baseScale)

      -- Re-apply anchor/position after ApplyVisLink so parent/scale are stable.
      -- This keeps edit-mode and normal-mode positioning consistent.
      ApplyFramePositionFromDef(f, def)

      if forceHide then
        f:Hide()
      elseif type(def) == "table" and def.hideFrame == true then
        -- Explicitly hidden frames stay hidden even in edit mode.
        f:Hide()
      elseif editMode then
        -- Edit mode should always show frames, even if the addon is toggled off.
        f:Show()
      elseif not framesEnabled then
        f:Hide()
      elseif type(def) == "table" and def.hideInCombat == true and InCombatLockdown and InCombatLockdown() then
        f:Hide()
      elseif (def.hideWhenEmpty ~= false) and not hasAny then
        f:Hide()
      else
        f:Show()
      end

      if t == "bar" then
        RenderBar(def, f, entries)
        if type(ns) == "table" and type(ns.Render) == "table" and type(ns.Render.EnsureBarInspectButton) == "function" then
          local btn = ns.Render.EnsureBarInspectButton(f)
          if btn and btn.SetShown then
            btn:SetShown(editMode and true or false)
          elseif btn and btn.Show and btn.Hide then
            if editMode then btn:Show() else btn:Hide() end
          end
        end
      else
        RenderList(def, f, entries)
      end

      UpdateAnchorLabel(f, def)

      -- Auto-size (lists) and resolution/UI scale changes can leave frames off-screen.
      -- Nudge them back on-screen without altering their anchor corner.
      NudgeFrameOnScreen(f, 8)
    end
  end

  if type(ns) == "table" and type(ns.Render) == "table" and type(ns.Render.RefreshBarContentsFrame) == "function" then
    ns.Render.RefreshBarContentsFrame()
  end
end

-- Attach render deps for fUI_QTUsageUIR.lua (loaded after this file)
if type(ns) == "table" and type(ns._FQTRender) == "table" and type(ns._FQTRender.deps) == "table" then
  local deps = ns._FQTRender.deps
  deps.Print = Print
  deps.IsEditMode = function() return editMode and true or false end
  deps.IsOptionsOpen = function() return optionsFrame ~= nil end
  deps.RefreshAll = function(...) return ns.RefreshAll(...) end
  deps.RefreshActiveTab = function(...)
    if type(RefreshActiveTab) == "function" then return RefreshActiveTab(...) end
  end

  deps.ClampPadPx = ClampPadPx
  deps.NormalizeAnchorCorner = NormalizeAnchorCorner
  deps.PointToAnchorCorner = PointToAnchorCorner

  deps.EnsureFontString = EnsureFontString
  deps.ApplyFontStyle = ApplyFontStyle
  deps.GetRuleFontDef = GetRuleFontDef
  deps.GetIndicatorsWidth = GetIndicatorsWidth
  deps.RenderIndicators = RenderIndicators
  deps.EnsureRowButton = EnsureRowButton
  deps.EnsureRemoveButton = EnsureRemoveButton
  deps.EnsureMoveButton = EnsureMoveButton
  deps.HideExtraFrameRows = HideExtraFrameRows

  deps.GetFrameScrollOffset = GetFrameScrollOffset
  deps.SetFrameScrollOffset = SetFrameScrollOffset

  deps.RuleKey = RuleKey
  deps.GetEffectiveFrames = GetEffectiveFrames
  deps.GetFrameByID = function(frameID)
    frameID = tostring(frameID or "")
    return (type(framesByID) == "table") and framesByID[frameID] or nil
  end
  deps.GetFramesEnabled = function() return framesEnabled and true or false end
  deps.UnassignRuleFromFrame = UnassignRuleFromFrame
  deps.ReorderCustomRulesInFrame = ReorderCustomRulesInFrame

  deps.ApplyFAOBackdrop = ApplyFAOBackdrop
  deps.RestoreWindowPosition = RestoreWindowPosition
  deps.SaveWindowPosition = SaveWindowPosition
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

  if ApplyTrackerInteractivity then
    ApplyTrackerInteractivity()
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

ns.DestroyFrameByID = DestroyFrameByID

-- QuestX/QuestY integration (QuestXY rules)
local function GetActiveQuestOfferIDSafe()
  local fn = _G and rawget(_G, "GetQuestID")
  if type(fn) ~= "function" then return nil end
  local ok, id = pcall(fn)
  id = ok and tonumber(id) or nil
  if id and id > 0 then
    return id
  end
  return nil
end

local function TryAutoAcceptQuestYFromRules()
  local qid = GetActiveQuestOfferIDSafe()
  if not qid then return end

  local acceptFunc = _G and rawget(_G, "AcceptQuest")
  if type(acceptFunc) ~= "function" then return end

  local rules = (type(GetEffectiveRules) == "function" and GetEffectiveRules()) or nil
  if type(rules) ~= "table" then return end

  local evalCtx = (type(BuildEvalContext) == "function") and BuildEvalContext() or nil

  for _, rule in ipairs(rules) do
    local isQuestY = (type(rule) == "table" and rule.questXY == "Y" and tonumber(rule.questID) == qid)
    local isQuestAccept = (type(rule) == "table" and rule.questXY == nil and tostring(rule.qXept or "N"):upper():gsub("%s+", "") == "Y" and tonumber(rule.questID) == qid)

    if isQuestY or isQuestAccept then
      local status = BuildRuleStatus(rule, evalCtx, { forceNormalVisibility = true })
      if status ~= nil then
        local ok = pcall(acceptFunc)
        if ok then
          local title = (type(GetQuestTitle) == "function" and GetQuestTitle(qid)) or tostring(qid)
          Print("Auto-accepted: " .. tostring(title))
        end
        return
      end
    end
  end
end

-- Expose for split quest event handler module.
ns.TryAutoAcceptQuestYFromRules = TryAutoAcceptQuestYFromRules

local function AbandonQuestByLogIndex(i, qid)
  if not qid then return false end
  if C_QuestLog.CanAbandonQuest and not C_QuestLog.CanAbandonQuest(qid) then
    return false
  end

  local info = C_QuestLog.GetInfo and C_QuestLog.GetInfo(i) or nil
  local qTitle = (info and info.title) or ((type(GetQuestTitle) == "function" and GetQuestTitle(qid)) or tostring(qid))

  if C_QuestLog.SetSelectedQuest and C_QuestLog.SetAbandonQuest and C_QuestLog.AbandonQuest then
    local ok = pcall(C_QuestLog.SetSelectedQuest, qid)
    if not ok then
      -- Compatibility fallback: some environments may still accept log index.
      ok = pcall(C_QuestLog.SetSelectedQuest, i)
    end
    if not ok then return false end

    C_QuestLog.SetAbandonQuest()
    C_QuestLog.AbandonQuest()

    if StaticPopup1 and StaticPopup1.which == "ABANDON_QUEST" and type(StaticPopup_OnClick) == "function" then
      StaticPopup_OnClick(StaticPopup1, 1)
    end

    Print(tostring(qTitle) .. " Abandoned")
    return true
  end

  return false
end

local function TryAbandonQuestXFromRules()
  if InCombatLockdown and InCombatLockdown() then return end

  local rules = (type(GetEffectiveRules) == "function" and GetEffectiveRules()) or nil
  if type(rules) ~= "table" then return end

  if not (C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetQuestIDForLogIndex) then return end

  local targets = {}
  local evalCtx = (type(BuildEvalContext) == "function") and BuildEvalContext() or nil

  for _, rule in ipairs(rules) do
    if type(rule) == "table" and rule.questXY == "X" then
      local qid = tonumber(rule.questID)
      if qid and qid > 0 then
        local status = BuildRuleStatus(rule, evalCtx, { forceNormalVisibility = true })
        if status ~= nil then
          targets[qid] = true
        end
      end
    end
  end

  if not next(targets) then return end

  for i = 1, (C_QuestLog.GetNumQuestLogEntries() or 0) do
    local qid = C_QuestLog.GetQuestIDForLogIndex(i)
    if qid and targets[qid] then
      AbandonQuestByLogIndex(i, qid)
    end
  end
end

local function RunQuestXKeepListAbandonFromRules(forceBypassConfirm)
  if InCombatLockdown and InCombatLockdown() then return end

  local skipCompleted = (type(GetUISetting) == "function") and (GetUISetting("keepAbandonSkipCompleted", true) == true) or false

  local rules = (type(GetEffectiveRules) == "function" and GetEffectiveRules()) or nil
  if type(rules) ~= "table" then return end

  if not (C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetQuestIDForLogIndex) then return end

  local keep = {}
  local IsRuleDisabled = (type(ns) == "table") and ns.IsRuleDisabled or nil
  for _, rule in ipairs(rules) do
    if type(rule) == "table" then
      local xy = tostring(rule.questXY or ""):upper():gsub("%s+", "")
      if xy == "K" then
        local disabled = (type(IsRuleDisabled) == "function") and (IsRuleDisabled(rule) == true) or false
        if not disabled then
          local qid = tonumber(rule.questID)
          if qid and qid > 0 then
            keep[qid] = true
          end
        end
      end
    end
  end

  local keepEmpty = (next(keep) == nil)

  local toAbandon = {}
  for i = 1, (C_QuestLog.GetNumQuestLogEntries() or 0) do
    local info = (C_QuestLog.GetInfo and C_QuestLog.GetInfo(i)) or nil
    local qid = (info and info.questID) or C_QuestLog.GetQuestIDForLogIndex(i)
    qid = tonumber(qid)
    if qid and qid > 0 and not keep[qid] then
      local isHeader = info and info.isHeader
      local isHidden = info and info.isHidden
      if not isHeader and not isHidden then
        if (not C_QuestLog.CanAbandonQuest) or C_QuestLog.CanAbandonQuest(qid) == true then
          local isComplete = false
          if info and info.isComplete ~= nil then
            isComplete = (info.isComplete == true) or ((tonumber(info.isComplete) or 0) == 1)
          end

          -- "Completed" should also treat ready-to-turn-in quests as complete.
          if (not isComplete) and C_QuestLog.ReadyForTurnIn then
            local ok, v = pcall(C_QuestLog.ReadyForTurnIn, qid)
            if ok then
              isComplete = (v == true) or (v == 1) or ((tonumber(v) or 0) == 1)
            end
          end

          if (not isComplete) and C_QuestLog.IsComplete then
            local ok, v = pcall(C_QuestLog.IsComplete, qid)
            if ok then
              isComplete = (v == true) or (v == 1) or ((tonumber(v) or 0) == 1)
            end
          end

          if (not skipCompleted) or (not isComplete) then
            toAbandon[#toAbandon + 1] = qid
          end
        end
      end
    end
  end

  if #toAbandon == 0 then
    Print("Nothing to abandon (everything is kept/protected/unabandonable).")
    return
  end

  local function FindLogIndexByQuestID(qid)
    qid = tonumber(qid)
    if not qid or qid <= 0 then return nil end
    if C_QuestLog.GetLogIndexForQuestID then
      local ok, idx = pcall(C_QuestLog.GetLogIndexForQuestID, qid)
      idx = ok and tonumber(idx) or nil
      if idx and idx > 0 then return idx end
    end
    for i = 1, (C_QuestLog.GetNumQuestLogEntries() or 0) do
      local info = (C_QuestLog.GetInfo and C_QuestLog.GetInfo(i)) or nil
      local id = tonumber((info and info.questID) or C_QuestLog.GetQuestIDForLogIndex(i))
      if id and id == qid then
        return i
      end
    end
    return nil
  end

  local function RunAbandonBatch()
    local stepDelay = 0.20
    local idx = 1

    if frame and frame._questXKeepAbandonTimer then
      frame._questXKeepAbandonTimer:Cancel()
      frame._questXKeepAbandonTimer = nil
    end

    local function Step()
      local qid = toAbandon[idx]
      idx = idx + 1
      if not qid then
        if frame then frame._questXKeepAbandonTimer = nil end
        return
      end

      local logIndex = FindLogIndexByQuestID(qid)
      if logIndex then
        AbandonQuestByLogIndex(logIndex, qid)
      end

      if C_Timer and C_Timer.NewTimer then
        if frame then
          frame._questXKeepAbandonTimer = C_Timer.NewTimer(stepDelay, Step)
        else
          C_Timer.NewTimer(stepDelay, Step)
        end
      else
        Step()
      end
    end

    Step()
  end

  local function ShouldBypassConfirm()
    if forceBypassConfirm == true then
      return true
    end
    if IsShiftKeyDown then return IsShiftKeyDown() == true end
    return false
  end

  if ShouldBypassConfirm() or #toAbandon < 2 then
    RunAbandonBatch()
    return
  end

  if StaticPopupDialogs and StaticPopup_Show then
    StaticPopupDialogs["FQT_KEEP_ABANDON_CONFIRM"] = StaticPopupDialogs["FQT_KEEP_ABANDON_CONFIRM"] or {
      text = "",
      button1 = YES,
      button2 = NO,
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
      preferredIndex = 3,
    }
    if keepEmpty then
      StaticPopupDialogs["FQT_KEEP_ABANDON_CONFIRM"].text = string.format("Keep List is empty. Abandon %d quest(s)?", #toAbandon)
    else
      StaticPopupDialogs["FQT_KEEP_ABANDON_CONFIRM"].text = string.format("Abandon %d quest(s) (Keep List)?", #toAbandon)
    end
    StaticPopupDialogs["FQT_KEEP_ABANDON_CONFIRM"].OnAccept = RunAbandonBatch
    StaticPopup_Show("FQT_KEEP_ABANDON_CONFIRM")
    return
  end

  -- Fallback: no popup available; run immediately.
  RunAbandonBatch()
end

ns.RunQuestXKeepListAbandon = function()
  RunQuestXKeepListAbandonFromRules(false)
end

-- Slash-only helper: Abandon All Quests (Keep List) without confirmation.
ns.RunQuestXKeepListAbandonNoConfirm = function()
  RunQuestXKeepListAbandonFromRules(true)
end

_G.FQT_RunQuestXKeepListAbandonNoConfirm = function()
  if type(ns) == "table" and type(ns.RunQuestXKeepListAbandonNoConfirm) == "function" then
    ns.RunQuestXKeepListAbandonNoConfirm()
    return true
  end
  return false
end

local function QueueTryAbandonQuestX()
  if not (C_Timer and C_Timer.NewTimer) then
    TryAbandonQuestXFromRules()
    return
  end
  if frame and frame._questXAbandonTimer then
    frame._questXAbandonTimer:Cancel()
    frame._questXAbandonTimer = nil
  end
  if frame then
    frame._questXAbandonTimer = C_Timer.NewTimer(0.5, function()
      if frame then frame._questXAbandonTimer = nil end
      TryAbandonQuestXFromRules()
    end)
  else
    C_Timer.NewTimer(0.5, TryAbandonQuestXFromRules)
  end
end

-- Expose for split quest event handler module.
ns.QueueTryAbandonQuestX = QueueTryAbandonQuestX

-- Events
frame = CreateFrame("Frame")

local function SafeRegisterEvent(f, event)
  if not f or not event then return end
  pcall(f.RegisterEvent, f, event)
end

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("QUEST_LOG_UPDATE")
frame:RegisterEvent("QUEST_ACCEPTED")
frame:RegisterEvent("QUEST_DETAIL")
frame:RegisterEvent("QUEST_TURNED_IN")
frame:RegisterEvent("BAG_UPDATE_DELAYED")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")

-- Refresh quickly when spells/professions update (e.g. learning a new profession skill line).
frame:RegisterEvent("SPELLS_CHANGED")
frame:RegisterEvent("SKILL_LINES_CHANGED")
SafeRegisterEvent(frame, "LEARNED_SPELL_IN_TAB")
SafeRegisterEvent(frame, "NEW_RECIPE_LEARNED")
SafeRegisterEvent(frame, "TRADE_SKILL_LIST_UPDATE")

frame:RegisterEvent("MERCHANT_SHOW")
SafeRegisterEvent(frame, "MERCHANT_UPDATE")
SafeRegisterEvent(frame, "MERCHANT_CLOSED")

frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")

frame:RegisterEvent("CALENDAR_UPDATE_EVENT_LIST")
frame:RegisterEvent("CALENDAR_UPDATE_EVENT")

frame:RegisterEvent("MODIFIER_STATE_CHANGED")

local function OnQuestDetail()
  if not (C_Timer and C_Timer.After) then
    if type(TryAutoAcceptQuestYFromRules) == "function" then
      TryAutoAcceptQuestYFromRules()
    end
    return
  end

  C_Timer.After(0, function()
    if type(TryAutoAcceptQuestYFromRules) == "function" then
      TryAutoAcceptQuestYFromRules()
    end
  end)
end

local function OnQuestEventGroup()
  if type(QueueTryAbandonQuestX) == "function" then
    QueueTryAbandonQuestX()
  end
end

local function FQT_OnEvent(_, event, ...)
  if event == "MERCHANT_SHOW" then
    if ns and ns.Merchant and ns.Merchant.OnMerchantShow then
      ns.Merchant.OnMerchantShow(frame)
    end
    return
  end
  if event == "MERCHANT_CLOSED" then
    if ns and ns.Merchant and ns.Merchant.OnMerchantClosed then
      ns.Merchant.OnMerchantClosed(frame)
    end
    return
  end
  if event == "MERCHANT_UPDATE" then
    if ns and ns.Merchant and ns.Merchant.OnMerchantUpdate then
      ns.Merchant.OnMerchantUpdate(frame)
    end
    return
  end
  if event == "MODIFIER_STATE_CHANGED" then
    OnModifierStateChanged()
    return
  end
  if event == "UNIT_AURA" then
    local unit = ...
    if unit ~= "player" then return end
  end

  if event == "PLAYER_LOGIN" then
    NormalizeSV()
    MaybeAutoClearTimewalkingKindOncePerWeek()
    MaybeAutoResetEventsOncePerDay()
    if ns and ns.RequestWarbandCurrencyData then
      ns.RequestWarbandCurrencyData()
    end
    if C_Timer and C_Timer.After and ns and ns.RefreshWarbandCurrencyCacheForAllKnownCurrencies then
      C_Timer.After(2.0, ns.RefreshWarbandCurrencyCacheForAllKnownCurrencies)
    end
    CreateAllFrames()
    C_Timer.After(1.0, RefreshAll)
    frame._didPostWorldWarm = false
    Print("Loaded. Type /fqt to configure.")
    return
  end

  if event == "CURRENCY_DISPLAY_UPDATE" then
    local currencyID = tonumber((...))
    if ns and ns.Currency and ns.Currency.OnCurrencyDisplayUpdate then
      ns.Currency.OnCurrencyDisplayUpdate(frame, currencyID)
    end
  end

  if event == "PLAYER_ENTERING_WORLD" and not frame._didPostWorldWarm then
    frame._didPostWorldWarm = true
    -- Calendar data can arrive slightly after login; do one delayed refresh.
    C_Timer.After(5.0, RefreshAll)
  end

  if event == "QUEST_DETAIL" then
    OnQuestDetail()
  end

  if event == "QUEST_ACCEPTED" or event == "QUEST_LOG_UPDATE" or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_REGEN_ENABLED" or event == "ZONE_CHANGED_NEW_AREA" then
    OnQuestEventGroup()
  end

  if event == "CALENDAR_UPDATE_EVENT_LIST" or event == "CALENDAR_UPDATE_EVENT" then
    if ns and ns.Calendar and ns.Calendar.OnCalendarUpdate then
      ns.Calendar.OnCalendarUpdate(frame)
    end
    return
  end

  if event == "PLAYER_REGEN_ENABLED" then
    OnPlayerRegenEnabled_Interactivity()
  end

  -- debounce rapid spam
  if frame._refreshTimer then
    frame._refreshTimer:Cancel()
  end
  frame._refreshTimer = C_Timer.NewTimer(0.25, RefreshAll)
end

frame:SetScript("OnEvent", FQT_OnEvent)

-- Extra deps for debug commands (implemented in fUI_QTCoreCmd.lua)
if type(ns) == "table" and type(ns._FQTSlash) == "table" and type(ns._FQTSlash.deps) == "table" then
  local deps = ns._FQTSlash.deps
  deps.GetEffectiveFrames = GetEffectiveFrames
  deps.GetEffectiveRules = GetEffectiveRules
  deps.RuleKey = RuleKey
  deps.BuildRuleStatus = BuildRuleStatus
  deps.BuildEvalContext = BuildEvalContext
  deps.GetFrameByID = function(frameID)
    frameID = tostring(frameID or "")
    return (type(framesByID) == "table") and framesByID[frameID] or nil
  end
  deps.CreateAllFrames = function()
    if type(CreateAllFrames) == "function" then
      return CreateAllFrames()
    end
  end
  deps.GetFrameScrollOffset = function(frameID)
    if type(GetFrameScrollOffset) == "function" then
      return GetFrameScrollOffset(frameID)
    end
    return 0
  end
  deps.HasRememberedDailyAura = HasRememberedDailyAura
  deps.GetUISetting = GetUISetting
  deps.SetUISetting = SetUISetting
end
