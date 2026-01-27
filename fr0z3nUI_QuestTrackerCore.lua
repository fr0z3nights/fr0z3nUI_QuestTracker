local addonName, ns = ...

local PREFIX = "|cff00ccff[FQT]|r "
local function Print(msg)
  print(PREFIX .. tostring(msg or ""))
end

ns.Print = Print

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

local RuleKey

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
  if value == nil then return nil end
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

  if type(rule.itemInfo) == "string" then
    local t = string.gsub(rule.itemInfo, "^%s+", "")
    t = string.gsub(t, "%s+$", "")
    rule.itemInfo = (t ~= "") and t or nil
  end

  if type(rule.spellInfo) == "string" then
    local t = string.gsub(rule.spellInfo, "^%s+", "")
    t = string.gsub(t, "%s+$", "")
    rule.spellInfo = (t ~= "") and t or nil
  end

  if type(rule.textInfo) == "string" then
    local t = string.gsub(rule.textInfo, "^%s+", "")
    t = string.gsub(t, "%s+$", "")
    rule.textInfo = (t ~= "") and t or nil
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

local _defaultRulesMigrated = false
local function EnsureDefaultRulesMigrated()
  if _defaultRulesMigrated then return end
  _defaultRulesMigrated = true

  if type(ns.rules) ~= "table" then return end

  for _, r in ipairs(ns.rules) do
    if type(r) == "table" then
      NormalizeRuleInPlace(r)

      -- Legacy default DB rules used `label` as a multiline info field for items/spells.
      if type(r.item) == "table" and tonumber(r.item.itemID) and tonumber(r.item.itemID) > 0 then
        if r.itemInfo == nil and type(r.label) == "string" and r.label ~= "" then
          r.itemInfo = r.label
          r.label = nil
        end
      elseif (r.spellKnown or r.notSpellKnown or r.locationID or r.class or r.notInGroup) then
        if r.spellInfo == nil and type(r.label) == "string" and r.label ~= "" then
          r.spellInfo = r.label
          r.label = nil
        end
      else
        if r.textInfo == nil and type(r.label) == "string" and r.label ~= "" then
          r.textInfo = r.label
        end
      end
    end
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

  local edits = settings.defaultRuleEdits
  if type(edits) == "table" then
    for _, r in pairs(edits) do
      NormalizeRuleInPlace(r)
    end
  end

  _rulesNormalized = true
end

local function NormalizeSV()
  EnsureDefaultRulesMigrated()
  fr0z3nUI_QuestTracker_Acc = fr0z3nUI_QuestTracker_Acc or {}
  fr0z3nUI_QuestTracker_Char = fr0z3nUI_QuestTracker_Char or {}

  fr0z3nUI_QuestTracker_Acc.settings = fr0z3nUI_QuestTracker_Acc.settings or {}
  fr0z3nUI_QuestTracker_Acc.settings.ui = fr0z3nUI_QuestTracker_Acc.settings.ui or {}
  fr0z3nUI_QuestTracker_Acc.settings.customRules = fr0z3nUI_QuestTracker_Acc.settings.customRules or {}
  fr0z3nUI_QuestTracker_Acc.settings.customRulesTrash = fr0z3nUI_QuestTracker_Acc.settings.customRulesTrash or {}
  fr0z3nUI_QuestTracker_Acc.settings.defaultRuleEdits = fr0z3nUI_QuestTracker_Acc.settings.defaultRuleEdits or {}
  fr0z3nUI_QuestTracker_Acc.settings.customFrames = fr0z3nUI_QuestTracker_Acc.settings.customFrames or {}
  fr0z3nUI_QuestTracker_Char.settings = fr0z3nUI_QuestTracker_Char.settings or {}

  -- Character-specific layout data (mirrors account customFrames when enabled).
  fr0z3nUI_QuestTracker_Char.settings.customFrames = fr0z3nUI_QuestTracker_Char.settings.customFrames or {}

  fr0z3nUI_QuestTracker_Char.settings.disabledRules = fr0z3nUI_QuestTracker_Char.settings.disabledRules or {}
  fr0z3nUI_QuestTracker_Char.settings.framePos = fr0z3nUI_QuestTracker_Char.settings.framePos or {}
  fr0z3nUI_QuestTracker_Char.settings.frameScroll = fr0z3nUI_QuestTracker_Char.settings.frameScroll or {}
  fr0z3nUI_QuestTracker_Char.settings.ui = fr0z3nUI_QuestTracker_Char.settings.ui or {}

  fr0z3nUI_QuestTracker_Acc.cache = fr0z3nUI_QuestTracker_Acc.cache or {}
  fr0z3nUI_QuestTracker_Acc.cache.weeklyAuras = fr0z3nUI_QuestTracker_Acc.cache.weeklyAuras or {}
  fr0z3nUI_QuestTracker_Acc.cache.dailyAuras = fr0z3nUI_QuestTracker_Acc.cache.dailyAuras or {}
  fr0z3nUI_QuestTracker_Acc.cache.twWeekly = fr0z3nUI_QuestTracker_Acc.cache.twWeekly or {}
  if type(fr0z3nUI_QuestTracker_Acc.cache.twWeekly) ~= "table" then
    fr0z3nUI_QuestTracker_Acc.cache.twWeekly = {}
  end

  -- Explicit-only frame anchor/grow settings (no runtime auto-anchoring).
  do
    local function NormalizeAnchorCornerLocal(v)
      v = tostring(v or ""):lower():gsub("%s+", "")
      v = v:gsub("_", ""):gsub("-", "")
      if v == "tl" or v == "topleft" then return "tl" end
      if v == "tr" or v == "topright" then return "tr" end
      if v == "tc" or v == "topcenter" or v == "topcentre" then return "tc" end
      if v == "bl" or v == "bottomleft" then return "bl" end
      if v == "br" or v == "bottomright" then return "br" end
      if v == "bc" or v == "bottomcenter" or v == "bottomcentre" then return "bc" end
      return nil
    end

    local function PointToAnchorCornerLocal(point)
      point = tostring(point or ""):upper()
      if point == "TOP" then return "tc" end
      if point == "BOTTOM" then return "bc" end
      local vert = point:find("BOTTOM", 1, true) and "b" or "t"
      local horiz = point:find("RIGHT", 1, true) and "r" or "l"
      return vert .. horiz
    end

    local function NormalizeGrowDirLocal(v)
      v = tostring(v or ""):lower():gsub("%s+", "")
      v = v:gsub("_", "-")
      if v == "upleft" then v = "up-left" end
      if v == "upright" then v = "up-right" end
      if v == "downleft" then v = "down-left" end
      if v == "downright" then v = "down-right" end
      if v == "up-left" or v == "up-right" or v == "down-left" or v == "down-right" then
        return v
      end
      return nil
    end

    local function DeriveGrowDirFromCornerLocal(corner)
      corner = NormalizeAnchorCornerLocal(corner) or "tl"
      if corner == "tl" then return "down-right" end
      if corner == "tr" then return "down-left" end
      if corner == "tc" then return "down-right" end
      if corner == "bl" then return "up-right" end
      if corner == "br" then return "up-left" end
      if corner == "bc" then return "up-right" end
      return "down-right"
    end

    local function NormalizeFrames(frames)
      if type(frames) ~= "table" then return end
      for _, def in ipairs(frames) do
        if type(def) == "table" then
          if def.anchorCorner == nil then
            def.anchorCorner = PointToAnchorCornerLocal(def.point or def.relPoint or "TOPLEFT")
          else
            def.anchorCorner = NormalizeAnchorCornerLocal(def.anchorCorner) or PointToAnchorCornerLocal(def.point or def.relPoint or "TOPLEFT")
          end

          -- Unified mapping: growDir is implied by anchorCorner.
          def.growDir = DeriveGrowDirFromCornerLocal(def.anchorCorner)
        end
      end
    end

    NormalizeFrames(fr0z3nUI_QuestTracker_Acc.settings.customFrames)
    NormalizeFrames(fr0z3nUI_QuestTracker_Char.settings.customFrames)
  end

  EnsureRulesNormalized()
end

-- Make sure default DB rules are migrated/normalized early (before Options UI renders).
EnsureDefaultRulesMigrated()

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

ns.GetCustomRulesTrash = GetCustomRulesTrash

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

  return out
end

ns.GetEffectiveRules = GetEffectiveRules

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

RuleKey = function(rule)
  if type(rule) ~= "table" then return nil end
  if rule.key ~= nil then return tostring(rule.key) end
  if rule.questID then return "q:" .. tostring(rule.questID) end
  if rule.group then return "group:" .. tostring(rule.group) .. ":" .. tostring(rule.order or 0) end

  -- Additional stable keys for rules that don't have explicit `key`/`questID`/`label`.
  if type(rule.item) == "table" and rule.item.itemID ~= nil then
    local itemID = tonumber(rule.item.itemID)
    if itemID and itemID > 0 then
      local required = tonumber(rule.item.required or rule.item.count or 0) or 0
      local mustHave = (rule.item.mustHave == true) and 1 or 0
      return "item:" .. tostring(itemID) .. ":" .. tostring(required) .. ":" .. tostring(mustHave)
    end
  end

  if rule.locationID ~= nil then
    local loc = tostring(rule.locationID)
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

local function IsRuleDisabled(rule)
  NormalizeSV()
  local key = RuleKey(rule)
  if not key then return false end
  return fr0z3nUI_QuestTracker_Char.settings.disabledRules[key] and true or false
end

ns.IsRuleDisabled = IsRuleDisabled

local function ToggleRuleDisabled(rule)
  NormalizeSV()
  local key = RuleKey(rule)
  if not key then return end
  local t = fr0z3nUI_QuestTracker_Char.settings.disabledRules
  t[key] = not t[key]
end

ns.ToggleRuleDisabled = ToggleRuleDisabled

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

ns.DeepCopyValue = DeepCopyValue

local function MakeUniqueRuleKey(prefix)
  prefix = tostring(prefix or "custom")
  local t = tostring((type(time) == "function") and time() or 0)
  local r = tostring(math.random(100000, 999999))
  return prefix .. ":" .. t .. ":" .. r
end

ns.MakeUniqueRuleKey = MakeUniqueRuleKey

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

ns.EnsureUniqueKeyForCustomRule = EnsureUniqueKeyForCustomRule

local function IsQuestCompleted(questID)
  if not questID then return false end
  if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
    return C_QuestLog.IsQuestFlaggedCompleted(questID) and true or false
  end
  return false
end

local function IsQuestInLog(questID)
  questID = tonumber(questID)
  if not questID or questID <= 0 then return false end

  if C_QuestLog then
    if C_QuestLog.IsOnQuest then
      local ok, onQuest = pcall(C_QuestLog.IsOnQuest, questID)
      if ok and onQuest then return true end
    end
    if C_QuestLog.GetLogIndexForQuestID then
      local idx = C_QuestLog.GetLogIndexForQuestID(questID)
      return (type(idx) == "number" and idx > 0) and true or false
    end
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

local function GetCurrencyQuantitySafe(currencyID)
  currencyID = tonumber(currencyID)
  if not currencyID or currencyID <= 0 then return 0 end

  if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
    local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, currencyID)
    if ok and type(info) == "table" then
      return tonumber(info.quantity) or 0
    end
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

local function IsHolidayDayEvent(monthOffset, day, index)
  if not (C_Calendar and C_Calendar.GetDayEvent) then return false end
  local ok, ev = pcall(C_Calendar.GetDayEvent, monthOffset, day, index)
  if not ok or type(ev) ~= "table" then return false end

  local eventType = rawget(ev, "eventType")
  do
    local et = Enum and Enum.CalendarEventType
    local holidayEnum = et and (rawget(et, "Holiday") or rawget(et, "HOLIDAY"))
    if holidayEnum ~= nil and eventType == holidayEnum then
      return true
    end
  end
  if type(eventType) == "string" and tostring(eventType):lower() == "holiday" then
    return true
  end

  local calendarType = rawget(ev, "calendarType")
  if type(calendarType) == "string" and tostring(calendarType):lower() == "holiday" then
    return true
  end

  return false
end

local function GetCalendarHolidayText(monthOffset, day, index)
  if not (C_Calendar and C_Calendar.GetHolidayInfo) then return nil end
  -- IMPORTANT: holiday indices are not the same as day-event indices.
  -- Only query holiday info for day-events that are actually holiday-type;
  -- otherwise we can accidentally attach unrelated holiday text to normal events
  -- and get false positives (e.g., stale bonus events / wrong Timewalking kind).
  if not IsHolidayDayEvent(monthOffset, day, index) then
    return nil
  end
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
  local startDay = today
  local endDay = today
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

local _calendarKeywordCache = { at = 0, active = {} }

local function NormalizeCalendarKeywords(keywords)
  if keywords == nil then return nil end
  if type(keywords) == "string" then
    keywords = { keywords }
  end
  if type(keywords) ~= "table" then return nil end

  local out = {}
  for _, kw in ipairs(keywords) do
    local s = tostring(kw or "")
    s = s:gsub("%s+", " ")
    s = s:gsub("^%s+", "")
    s = s:gsub("%s+$", "")
    if s ~= "" then
      out[#out + 1] = s
    end
  end
  return out[1] and out or nil
end

local function CalendarKeywordCacheKey(keywords)
  local list = NormalizeCalendarKeywords(keywords)
  if not list then return nil end
  for i = 1, #list do
    list[i] = tostring(list[i] or ""):lower()
  end
  table.sort(list)
  return table.concat(list, "|")
end

local function IsCalendarEventActiveByKeywords(keywords)
  local cacheKey = CalendarKeywordCacheKey(keywords)
  if not cacheKey then return false end

  local now = 0
  if GetServerTime then now = tonumber(GetServerTime()) or 0 end
  if _calendarKeywordCache.at and (now - (_calendarKeywordCache.at or 0)) < 60 and _calendarKeywordCache.active[cacheKey] ~= nil then
    return _calendarKeywordCache.active[cacheKey] and true or false
  end

  EnsureCalendarOpened()
  if not (C_Calendar and C_Calendar.GetNumDayEvents and C_Calendar.GetDayEvent) then
    _calendarKeywordCache.at = now
    _calendarKeywordCache.active[cacheKey] = false
    return false
  end

  local today = GetCurrentCalendarDay()
  if not today then
    _calendarKeywordCache.at = now
    _calendarKeywordCache.active[cacheKey] = false
    return false
  end

  local numDays = GetCurrentMonthNumDays()
  local startDay = today
  local endDay = today
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

      for kw in cacheKey:gmatch("[^|]+") do
        local k = tostring(kw or ""):lower()
        if k ~= "" and hay:find(k, 1, true) then
          found = true
          break
        end
      end

      if found then break end
    end
    if found then break end
  end

  _calendarKeywordCache.at = now
  _calendarKeywordCache.active[cacheKey] = found and true or false
  return found and true or false
end

local function GetCalendarDebugEvents(daysBack, daysForward)
  daysBack = tonumber(daysBack) or 1
  daysForward = tonumber(daysForward) or 7
  if daysBack < 0 then daysBack = 0 end
  if daysForward < 0 then daysForward = 0 end

  EnsureCalendarOpened()
  if not (C_Calendar and C_Calendar.GetNumDayEvents and C_Calendar.GetDayEvent) then
    return {}, { ok = false, reason = "calendar_api_unavailable" }
  end

  local today = GetCurrentCalendarDay()
  if not today then
    return {}, { ok = false, reason = "no_today" }
  end

  local numDays = GetCurrentMonthNumDays()
  local startDay = today - daysBack
  local endDay = today + daysForward
  if startDay < 1 then startDay = 1 end
  if endDay > numDays then endDay = numDays end

  local events = {}
  for day = startDay, endDay do
    local okNum, n = pcall(C_Calendar.GetNumDayEvents, 0, day)
    n = okNum and tonumber(n) or 0
    for i = 1, n do
      local title = GetCalendarEventText(0, day, i)
      local holidayText = GetCalendarHolidayText(0, day, i)
      if (type(title) == "string" and title ~= "") or (type(holidayText) == "string" and holidayText ~= "") then
        events[#events + 1] = {
          monthOffset = 0,
          day = day,
          index = i,
          title = title,
          holidayText = holidayText,
          relDay = day - today,
        }
      end
    end
  end

  return events, {
    ok = true,
    today = today,
    startDay = startDay,
    endDay = endDay,
    numDays = numDays,
  }
end

ns.GetCalendarDebugEvents = GetCalendarDebugEvents

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
    -- Sanity clamp: weekly resets should never be weeks/months away.
    -- If Blizzard returns bogus values, don't persist remembered weekly state.
    if s and s > 0 and s < (60 * 60 * 24 * 10) then
      return now + s
    end
  end
  return 0
end

local function GetDailyResetAt()
  local now = GetServerTimeSafe()
  local s = nil
  if C_DateAndTime and C_DateAndTime.GetSecondsUntilDailyReset then
    s = tonumber(C_DateAndTime.GetSecondsUntilDailyReset())
  elseif GetQuestResetTime then
    s = tonumber(GetQuestResetTime())
  end
  -- Sanity clamp: daily reset should be within ~48 hours.
  if s and s > 0 and s < (60 * 60 * 48) then
    return now + s
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
  -- If expiration is absurdly far in the future, treat as corrupt/stale.
  if exp > (now + (60 * 60 * 24 * 10)) then
    fr0z3nUI_QuestTracker_Acc.cache.weeklyAuras[tostring(spellID)] = nil
    return false
  end
  if exp > now then
    return true
  end
  if exp ~= 0 then
    fr0z3nUI_QuestTracker_Acc.cache.weeklyAuras[tostring(spellID)] = nil
  end
  return false
end

local function RememberDailyAura(spellID)
  if spellID == nil then return end
  NormalizeSV()
  local resetAt = GetDailyResetAt()
  if resetAt and resetAt > 0 then
    fr0z3nUI_QuestTracker_Acc.cache.dailyAuras[tostring(spellID)] = resetAt
  end
end

local function HasRememberedDailyAura(spellID)
  if spellID == nil then return false end
  NormalizeSV()
  local now = GetServerTimeSafe()
  local exp = fr0z3nUI_QuestTracker_Acc.cache.dailyAuras[tostring(spellID)]
  exp = tonumber(exp) or 0
  -- If expiration is absurdly far in the future, treat as corrupt/stale.
  if exp > (now + (60 * 60 * 48)) then
    fr0z3nUI_QuestTracker_Acc.cache.dailyAuras[tostring(spellID)] = nil
    return false
  end
  if exp > now then
    return true
  end
  if exp ~= 0 then
    fr0z3nUI_QuestTracker_Acc.cache.dailyAuras[tostring(spellID)] = nil
  end
  return false
end

local function RememberWeeklyTimewalkingKind(kind)
  kind = tostring(kind or "")
  if kind == "" then return end
  NormalizeSV()
  local resetAt = GetWeeklyResetAt()
  if resetAt and resetAt > 0 then
    fr0z3nUI_QuestTracker_Acc.cache.twWeekly.kind = kind
    fr0z3nUI_QuestTracker_Acc.cache.twWeekly.exp = resetAt
  end
end

local function HasRememberedWeeklyTimewalkingKind(kind)
  NormalizeSV()
  local now = GetServerTimeSafe()
  local cache = fr0z3nUI_QuestTracker_Acc.cache.twWeekly
  if type(cache) ~= "table" then return false end
  local exp = tonumber(cache.exp) or 0
  -- If expiration is absurdly far in the future, treat as corrupt/stale.
  if exp > (now + (60 * 60 * 24 * 10)) then
    cache.kind = nil
    cache.exp = nil
    return false
  end
  if exp <= now then
    if exp ~= 0 then
      cache.kind = nil
      cache.exp = nil
    end
    return false
  end
  if kind == nil then
    return cache.kind ~= nil and tostring(cache.kind) ~= ""
  end
  kind = tostring(kind or "")
  if kind == "" then return false end
  return tostring(cache.kind or "") == kind
end

local function ClearRememberedTimewalkingKind()
  NormalizeSV()
  if fr0z3nUI_QuestTracker_Acc and type(fr0z3nUI_QuestTracker_Acc.cache) == "table" then
    local cache = fr0z3nUI_QuestTracker_Acc.cache.twWeekly
    if type(cache) == "table" then
      cache.kind = nil
      cache.exp = nil
    end
  end
end

local function ClearRememberedEventState()
  NormalizeSV()
  if not (fr0z3nUI_QuestTracker_Acc and type(fr0z3nUI_QuestTracker_Acc.cache) == "table") then return end
  local cache = fr0z3nUI_QuestTracker_Acc.cache

  if type(cache.weeklyAuras) == "table" then
    for k in pairs(cache.weeklyAuras) do
      if type(k) == "string" and k:find("^event:") then
        cache.weeklyAuras[k] = nil
      end
    end
  end

  if type(cache.dailyAuras) == "table" then
    for k in pairs(cache.dailyAuras) do
      if type(k) == "string" and k:find("^event:") then
        cache.dailyAuras[k] = nil
      end
    end
  end

  if type(cache.twWeekly) == "table" then
    cache.twWeekly.kind = nil
    cache.twWeekly.exp = nil
  end
end

ns.ClearRememberedTimewalkingKind = ClearRememberedTimewalkingKind
ns.ClearRememberedEventState = ClearRememberedEventState

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

  -- Only add spacing between text and icons when there is real text.
  -- For icon-only rows, avoid reserving extra space.
  local outerGap = blankText and 0 or PAD
  local leftInset = blankText and 0 or PAD

  local count = #indicators
  local width = leftInset + (count * ICON) + ((count - 1) * GAP)

  row.container:ClearAllPoints()
  row.container:SetPoint("TOPLEFT", baseFS, "TOPLEFT", textWidth + outerGap, 0)
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
    if hideWhenCompleted and applyGates then
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
      if hideWhenCompleted and applyGates then
        return nil
      end
    end
  end

  -- Account-wide Timewalking weekly memory: once ANY character picks up the weekly,
  -- remember which expansion-kind it is until weekly reset.
  if not editMode and questID and type(rule) == "table" and rule.twKind ~= nil then
    if IsQuestInLog(questID) and IsAnyTimewalkingEventActive() then
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
    local eventActive = IsAnyTimewalkingEventActive() and true or false
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
  if applyGates and type(rule) == "table" and type(rule.hideIfAnyQuestCompleted) == "table" then
    for _, q in ipairs(rule.hideIfAnyQuestCompleted) do
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

  -- Primary-professions-missing gate (optional)
  if applyGates and type(rule) == "table" and rule.missingPrimaryProfessions == true then
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
  if applyGates and type(rule) == "table" and rule.locationID ~= nil then
    local wants = ParseLocationIDs(rule.locationID)
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

    -- Support legacy/capitalized DB keys.
    -- IMPORTANT: these are aliases, not fallbacks-on-failure.
    local spellKnownGate = (rule.spellKnown ~= nil) and rule.spellKnown or rule.SpellKnown
    local notSpellKnownGate = (rule.notSpellKnown ~= nil) and rule.notSpellKnown or rule.NotSpellKnown

    if not CheckValue(spellKnownGate, true) then return nil end
    if not CheckValue(notSpellKnownGate, false) then return nil end
  end

  -- Rested-area gate (optional)
  if applyGates and type(rule) == "table" and rule.restedOnly == true then
    if not IsRestingSafe() then
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
      if rule.rep.hideWhenExalted == true and standingID >= 8 and rule.rep.sellWhenExalted ~= true then
        return nil
      end
    end
  end

  -- Faction gate (optional)
  if applyGates and type(rule) == "table" and rule.faction ~= nil then
    local want = tostring(rule.faction)
    if want == "Alliance" or want == "Horde" then
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
    if (g == "level" or g == "leveling") and atMax then
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
    local twKind = (type(rule) == "table") and rule.twKind or nil
    if twKind ~= nil and HasRememberedWeeklyTimewalkingKind(twKind) then
      -- allow: another character already picked up this week's TW quest
    elseif not (completed and hideWhenCompleted == false) then
      return nil
    end
  end

  -- Aura gate
  if applyGates and type(rule.aura) == "table" then
    local has = nil
    local rememberedKey = nil

    if rule.aura.eventKind == "timewalking" then
      has = IsAnyTimewalkingEventActive()
      rememberedKey = "event:timewalking"
    elseif rule.aura.eventKind == "calendar" then
      local kws = rule.aura.keywords or rule.aura.keyword or rule.aura.text
      has = IsCalendarEventActiveByKeywords(kws)
      local ck = CalendarKeywordCacheKey(kws)
      if ck and ck ~= "" then
        rememberedKey = "event:calendar:" .. ck
      end
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
      if has and rule.aura.rememberDaily == true and (rule.aura.mustHave ~= false) and (not editMode) then
        RememberDailyAura(rememberedKey)
      end
      if has and rule.aura.rememberWeekly == true and (rule.aura.mustHave ~= false) and (not editMode) then
        RememberWeeklyAura(rememberedKey)
      end
      if (not has) and rule.aura.rememberDaily == true and (rule.aura.mustHave ~= false) then
        has = HasRememberedDailyAura(rememberedKey) or has
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

    if applyGates then
      local currencyID = tonumber(rule.item.currencyID)
      local currencyRequired = tonumber(rule.item.currencyRequired)
      if currencyID and currencyRequired and currencyID > 0 and currencyRequired > 0 then
        if GetCurrencyQuantitySafe(currencyID) < currencyRequired then
          return nil
        end
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

    local count = GetItemCountSafe(itemID)

    if applyGates then
      local showBelow = tonumber(rule.item.showWhenBelow)
      if showBelow and showBelow > 0 and count >= showBelow then
        return nil
      end
    end

    if applyGates then
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
      local showBelow = tonumber(rule.item.showWhenBelow)
      if showBelow and showBelow > 0 then
        extra = string.format("%d/%d", count, showBelow)
      else
        extra = tostring(count)
      end
    end

    -- Optional vendor reminder: if exalted, show a SELL prompt for remaining items.
    if applyGates and type(rule.rep) == "table" and rule.rep.sellWhenExalted == true and rule.rep.factionID then
      local standingID = GetStandingIDByFactionID(rule.rep.factionID)
      if standingID and standingID >= 8 then
        if count <= 0 then
          return nil
        end
        extra = "SELL " .. tostring(count)
      end
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
    if type(rule) == "table" and rule.preferQuestInfoForTitle == true then
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
    if type(r) == "table" and (r.spellKnown or r.notSpellKnown or r.SpellKnown or r.NotSpellKnown or r.locationID or r.class or r.notInGroup) then
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
    rawTitle = rawTitle,
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
local frame

local UpdateAnchorLabel
local FindCustomRuleIndex
local UnassignRuleFromFrame

ApplyTrackerInteractivity = function()
  if InCombatLockdown and InCombatLockdown() then
    if frame then
      frame._pendingInteractivity = true
    end
    return
  end

  local clickThrough = not editMode
  local wantWheel = (editMode and true) or ((IsShiftKeyDown and IsShiftKeyDown()) and true or false)

  if type(framesByID) ~= "table" then return end
  for _, f in pairs(framesByID) do
    if f then
      -- Keep mouse enabled so wheel can be toggled by Shift.
      if f.EnableMouse then f:EnableMouse(true) end

      if f.SetMouseClickEnabled then
        local clickable = not clickThrough
        local ok = pcall(f.SetMouseClickEnabled, f, clickable)
        if not ok then
          pcall(f.SetMouseClickEnabled, f, "LeftButton", clickable)
          pcall(f.SetMouseClickEnabled, f, "RightButton", clickable)
        end
      elseif f.SetPropagateMouseClicks then
        pcall(f.SetPropagateMouseClicks, f, clickThrough)
      else
        -- Old client fallback: disabling mouse also disables hover (acceptable).
        if f.EnableMouse then f:EnableMouse(not clickThrough) end
      end

      if f.SetPropagateMouseMotion then
        pcall(f.SetPropagateMouseMotion, f, clickThrough)
      end

      if f.EnableMouseWheel then
        if f._wheelEnabled ~= wantWheel then
          f._wheelEnabled = wantWheel
          pcall(f.EnableMouseWheel, f, wantWheel)
        end
      end
    end
  end
end

local function GetFramePosStore()
  NormalizeSV()
  fr0z3nUI_QuestTracker_Acc.settings.framePos = fr0z3nUI_QuestTracker_Acc.settings.framePos or {}
  fr0z3nUI_QuestTracker_Char.settings.framePos = fr0z3nUI_QuestTracker_Char.settings.framePos or {}
  return fr0z3nUI_QuestTracker_Acc.settings.framePos
end

local function ClearSavedFramePosition(frameID)
  frameID = tostring(frameID or "")
  if frameID == "" then return false end
  local store = GetFramePosStore()
  if type(store) ~= "table" then return false end
  store[frameID] = nil
  return true
end

ns.ClearSavedFramePosition = ClearSavedFramePosition

local function NormalizeAnchorCorner(v)
  v = tostring(v or ""):lower():gsub("%s+", "")
  v = v:gsub("_", ""):gsub("-", "")
  if v == "tl" or v == "topleft" then return "tl" end
  if v == "tr" or v == "topright" then return "tr" end
  if v == "tc" or v == "topcenter" or v == "topcentre" then return "tc" end
  if v == "bl" or v == "bottomleft" then return "bl" end
  if v == "br" or v == "bottomright" then return "br" end
  if v == "bc" or v == "bottomcenter" or v == "bottomcentre" then return "bc" end
  return nil
end

local function AnchorCornerToPoint(corner)
  corner = NormalizeAnchorCorner(corner)
  if corner == "tl" then return "TOPLEFT" end
  if corner == "tr" then return "TOPRIGHT" end
  if corner == "tc" then return "TOP" end
  if corner == "bl" then return "BOTTOMLEFT" end
  if corner == "br" then return "BOTTOMRIGHT" end
  if corner == "bc" then return "BOTTOM" end
  return nil
end

local function PointToAnchorCorner(point)
  point = tostring(point or ""):upper()
  if point == "TOP" then return "tc" end
  if point == "BOTTOM" then return "bc" end
  local vert = point:find("BOTTOM", 1, true) and "b" or "t"
  local horiz = point:find("RIGHT", 1, true) and "r" or "l"
  return vert .. horiz
end

local function NormalizeGrowDir(v)
  v = tostring(v or ""):lower():gsub("%s+", "")
  v = v:gsub("_", "-")
  if v == "upleft" then v = "up-left" end
  if v == "upright" then v = "up-right" end
  if v == "downleft" then v = "down-left" end
  if v == "downright" then v = "down-right" end
  if v == "up-left" or v == "up-right" or v == "down-left" or v == "down-right" then
    return v
  end
  return nil
end

local function GrowDirToGrowX(dir)
  dir = NormalizeGrowDir(dir)
  if not dir then return nil end
  return dir:find("left", 1, true) and "left" or "right"
end

local function GrowDirToGrowY(dir)
  dir = NormalizeGrowDir(dir)
  if not dir then return nil end
  return dir:find("up", 1, true) and "up" or "down"
end

local function SaveFramePosition(f)
  if not (f and f._id and f.GetPoint) then return end

  -- Explicit only: keep the current anchor point; do not auto-pick based on screen position.
  local point, _, relPoint, x, y = f:GetPoint(1)
  if not point then return end

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

ns.SaveFramePosition = SaveFramePosition
ns.GetTrackerFrameByID = function(id)
  id = tostring(id or "")
  if id == "" then return nil end
  return framesByID and framesByID[id] or nil
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
  local btn = CreateFrame("Button", nil, frame)
  btn:EnableMouse(true)
  btn:SetSize(92, 16)
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

  if not btn.CreateFontString then return nil end
  local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  if fs.SetJustifyH then fs:SetJustifyH("LEFT") end
  if fs.SetJustifyV then fs:SetJustifyV("MIDDLE") end
  fs:SetPoint("LEFT", 6, 0)
  fs:SetPoint("RIGHT", -6, 0)
  fs:SetText("|cff00ccff[FQT]|r")
  fs:Hide()

  frame._anchorLabel = fs
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

  local def = (type(frameDef) == "table") and frameDef or (frame and frame._lastFrameDef)
  local corner = (type(def) == "table") and NormalizeAnchorCorner(def.anchorCorner) or nil
  if not corner and frame and frame.GetPoint then
    local p = frame:GetPoint(1)
    corner = PointToAnchorCorner(p)
  end
  if corner ~= "tl" and corner ~= "tr" and corner ~= "tc" and corner ~= "bl" and corner ~= "br" and corner ~= "bc" then corner = "tl" end

  fs:ClearAllPoints()
  if corner == "tr" then
    if fs.SetJustifyH then fs:SetJustifyH("RIGHT") end
    if btn then
      btn:ClearAllPoints()
      btn:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 0)
    end
  elseif corner == "tc" then
    if fs.SetJustifyH then fs:SetJustifyH("CENTER") end
    if btn then
      btn:ClearAllPoints()
      btn:SetPoint("BOTTOM", frame, "TOP", 0, 0)
    end
  elseif corner == "bl" then
    if fs.SetJustifyH then fs:SetJustifyH("LEFT") end
    if btn then
      btn:ClearAllPoints()
      btn:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, 0)
    end
  elseif corner == "br" then
    if fs.SetJustifyH then fs:SetJustifyH("RIGHT") end
    if btn then
      btn:ClearAllPoints()
      btn:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    end
  elseif corner == "bc" then
    if fs.SetJustifyH then fs:SetJustifyH("CENTER") end
    if btn then
      btn:ClearAllPoints()
      btn:SetPoint("TOP", frame, "BOTTOM", 0, 0)
    end
  else
    if fs.SetJustifyH then fs:SetJustifyH("LEFT") end
    if btn then
      btn:ClearAllPoints()
      btn:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 0)
    end
  end

  if btn then
    fs:ClearAllPoints()
    fs:SetPoint("LEFT", btn, "LEFT", 6, 0)
    fs:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
    btn:SetFrameLevel((frame.GetFrameLevel and frame:GetFrameLevel() or 1) + 20)
    btn:Show()
  end

  fs:Show()

  -- Keep the bar "List" inspect button attached to the bar's actual anchor corner.
  if frame and frame._barInspectBtn then
    -- Map TL/TR/BL/BR to the button side:
    -- TL + down-right => right, TR + down-left => left, BL + up-right => right, BR + up-left => left.
    local c = tostring(corner or "tl")
    local p
    if c == "tc" then
      p = "TOPRIGHT"
    elseif c == "bc" then
      p = "BOTTOMRIGHT"
    else
      if c ~= "tl" and c ~= "tr" and c ~= "bl" and c ~= "br" then c = "tl" end
      local vert = (c:sub(1, 1) == "t") and "TOP" or "BOTTOM"
      local horiz = (c:sub(2, 2) == "l") and "RIGHT" or "LEFT"
      p = vert .. horiz
    end
    frame._barInspectBtn:ClearAllPoints()
    frame._barInspectBtn:SetPoint(p, frame, p, (p:find("LEFT", 1, true) and 6 or -6), (p:find("TOP", 1, true) and -6 or 6))
  end
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

local function CreateContainerFrame(def)
  local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
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

  return f
end

local function ResolveNamedFrame(name)
  name = tostring(name or "")
  name = name:gsub("^%s+", ""):gsub("%s+$", "")
  if name == "" then return nil end
  return _G and _G[name] or nil
end

local function NormalizeVisLinkMode(def)
  if type(def) ~= "table" then return "off" end
  local mode = tostring(def.visibilityLinkMode or ""):lower():gsub("%s+", "")
  -- Re-parent mode removed; map any legacy values to hook.
  if mode == "parent" or mode == "reparent" then mode = "hook" end
  if mode ~= "hook" then
    -- Back-compat: old configs could have parentFrame set; treat as hook.
    if type(def.parentFrame) == "string" and def.parentFrame ~= "" then
      mode = "hook"
    else
      mode = "off"
    end
  end
  return mode
end

local function GetVisLinkFrameName(def)
  if type(def) ~= "table" then return "" end
  local nm = def.visibilityLinkFrame
  if (nm == nil or nm == "") and type(def.parentFrame) == "string" then
    nm = def.parentFrame
  end
  nm = tostring(nm or "")
  nm = nm:gsub("^%s+", ""):gsub("%s+$", "")
  return nm
end

local function ApplyVisLink(frame, def, baseScale)
  if not frame then return false end
  if editMode then
    -- In edit mode, always show and keep frames under UIParent; apply base scale.
    frame._visLinkForceHide = nil
    if frame.GetParent and frame.SetParent and frame:GetParent() ~= UIParent then
      frame:SetParent(UIParent)
    end
    if frame.SetScale then frame:SetScale(tonumber(baseScale) or 1) end
    return false
  end

  local mode = NormalizeVisLinkMode(def)
  local nm = GetVisLinkFrameName(def)
  local target = (nm ~= "") and ResolveNamedFrame(nm) or nil

  -- Re-parent mode removed: always keep frames under UIParent.
  if frame.SetParent and frame.GetParent and frame:GetParent() ~= UIParent then
    frame:SetParent(UIParent)
  end
  if frame.SetScale then frame:SetScale(tonumber(baseScale) or 1) end

  if mode == "hook" and target and target.HookScript and target.IsShown then
    if frame._visLinkHookTarget ~= target then
      frame._visLinkHookTarget = target
      local function Sync()
        if not frame then return end
        -- Force a re-eval of visibility with the new target state.
        RefreshAll()
      end
      frame._visLinkHookFn = Sync
      target:HookScript("OnShow", Sync)
      target:HookScript("OnHide", Sync)
    end
    frame._visLinkForceHide = (target:IsShown() ~= true) and true or nil
    return frame._visLinkForceHide and true or false
  end

  frame._visLinkForceHide = nil
  return false
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

local function CreateBarFrame(def)
  local f = CreateContainerFrame(def)
  f._id = def and def.id or nil
  f:SetSize(def.width or 300, def.height or 20)
  local ref = (f.GetParent and f:GetParent()) or UIParent
  f:SetPoint(def.point or "TOP", ref or UIParent, def.relPoint or def.point or "TOP", def.x or 0, def.y or 0)
  ApplySavedFramePosition(f, def)

  f._itemFont = "GameFontHighlightSmall"
  f.items = {}

  f._wheelEnabled = (editMode and true) or ((IsShiftKeyDown and IsShiftKeyDown()) and true or false)
  f:EnableMouseWheel(f._wheelEnabled)
  f:SetScript("OnMouseWheel", function(self, delta)
    if not (editMode or (IsShiftKeyDown and IsShiftKeyDown())) then return end
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

  f._wheelEnabled = (editMode and true) or ((IsShiftKeyDown and IsShiftKeyDown()) and true or false)
  f:EnableMouseWheel(f._wheelEnabled)
  f:SetScript("OnMouseWheel", function(self, delta)
    if not (editMode or (IsShiftKeyDown and IsShiftKeyDown())) then return end
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
  parent.items = parent.items or {}
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
  local maxItems = tonumber(frameDef.maxItems) or 6
  local uiPad = ClampPadPx((type(frameDef) == "table") and frameDef.pad or nil)
  if uiPad == nil and type(GetUISetting) == "function" then
    local v = GetUISetting("pad", nil)
    if v == nil then v = GetUISetting("listPadding", 0) end
    uiPad = ClampPadPx(v) or 0
  end
  uiPad = uiPad or 0

  local pad = 8 + uiPad
  local y = -2
  if type(entries) ~= "table" then entries = {} end

  if frame.title then frame.title:Hide() end

  -- Bars: align to the side their anchor is on; reverse order only affects which entries
  -- appear left-to-right (it should not force a different alignment).
  local reverse = GetUISetting("reverseOrder", false) and true or false
  local corner = (type(frameDef) == "table") and NormalizeAnchorCorner(frameDef.anchorCorner) or nil
  if not corner and frame and frame.GetPoint then
    local p = frame:GetPoint(1)
    corner = PointToAnchorCorner(p)
  end
  local align
  if corner == "tc" or corner == "bc" then
    align = "center"
  else
    align = (corner == "tr" or corner == "br") and "right" or "left"
  end

  local offset = GetFrameScrollOffset(frame and frame._id)
  local maxOffset = 0
  if type(entries) == "table" then
    maxOffset = math.max(0, (#entries) - maxItems)
  end
  if offset > maxOffset then
    offset = maxOffset
    SetFrameScrollOffset(frame and frame._id, offset)
  end

  local function EntryForSlot(i)
    i = tonumber(i) or 1
    if i < 1 then return nil end
    local idx
    if reverse then
      idx = offset + (maxItems - i + 1)
    else
      idx = offset + i
    end
    return entries[idx]
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
    local e = EntryForSlot(i)
    if e then
      local text = (editMode and e.title) or e.title
      if e.extra then text = text .. "  " .. e.extra end
      tempTextByIndex[i] = text
      tempIndicatorsByIndex[i] = e.indicators
      tempIndicatorsWByIndex[i] = 0
    end
  end

  -- Compute total width if centered.
  local spacingPrefix = 12 + uiPad
  local spacingItem = 16 + uiPad
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
      local indW = GetIndicatorsWidth(fs, tempIndicatorsByIndex[i], uiPad)
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
  if frameW and frameW > 0 then
    if align == "right" then
      start = math.max(pad, frameW - pad - total)
    elseif align == "center" then
      local desired = math.floor((frameW - total) / 2 + 0.5)
      local minStart = pad
      local maxStart = math.max(pad, frameW - pad - total)
      if desired < minStart then desired = minStart end
      if desired > maxStart then desired = maxStart end
      start = desired
    end
  end

  local cursor = start

  -- Left-to-right placement; start position handles alignment.
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
      RenderIndicators(frame, i, fs, tempIndicatorsByIndex[i], uiPad)

      local btn = EnsureRowButton(frame, i)
      btn:ClearAllPoints()
      btn:SetPoint("TOPLEFT", fs, "TOPLEFT", -2, 2)
      btn:SetPoint("BOTTOMRIGHT", fs, "BOTTOMRIGHT", 2 + indW, -2)
      btn._entry = EntryForSlot(i)
      btn:EnableMouse(editMode and true or false)
      if editMode then btn:Show() else btn:Hide() end

      -- Remove buttons (X) are list-only; hide on bars.
      local rm = EnsureRemoveButton(frame, i)
      rm:Hide()

      cursor = cursor + (fs:GetStringWidth() or 0) + indW + spacingItem
    else
      fs:SetText("")
      fs:Hide()
      RenderIndicators(frame, i, fs, nil, uiPad)

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

ns.ResetFramePositionsToDefaults = ResetFramePositionsToDefaults

-- Options UI was split out to fr0z3nUI_QuestTracker_Options.lua
-- (kept separate to reduce compile-time locals/upvalues in core)

local function RenderList(frameDef, frame, entries)
  local maxItems = tonumber(frameDef.maxItems) or 20
  local rowH = tonumber(frameDef.rowHeight) or 16
  if type(entries) ~= "table" then entries = {} end

  -- Always allow zebra in edit mode so list editing is readable.
  local zebra = (editMode and true) or ((type(frameDef) == "table" and frameDef.zebra == true) and true or false)
  local zebraA = tonumber(GetUISetting("zebraAlpha", 0.05) or 0.05) or 0.05
  if zebraA < 0 then zebraA = 0 elseif zebraA > 0.20 then zebraA = 0.20 end

  local uiPad = ClampPadPx((type(frameDef) == "table") and frameDef.pad or nil)
  if uiPad == nil and type(GetUISetting) == "function" then
    local v = GetUISetting("pad", nil)
    if v == nil then v = GetUISetting("listPadding", 0) end
    uiPad = ClampPadPx(v) or 0
  end
  uiPad = uiPad or 0

  -- Lists: extra vertical gap only outside edit mode.
  local listPad = editMode and 0 or uiPad

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

  -- If prior versions created per-frame scroll buttons, keep them hidden.
  if frame and frame._listScrollUp and frame._listScrollUp.Hide then frame._listScrollUp:Hide() end
  if frame and frame._listScrollDown and frame._listScrollDown.Hide then frame._listScrollDown:Hide() end

  local shown = 0

  local wrapText = not editMode

  -- If zebra striping was enabled in a previous render (e.g. edit mode), ensure it
  -- can't remain visible when zebra is not active in the current render.
  local wantZebra = (zebra and (not wrapText) and zebraA > 0) and true or false
  if frame and type(frame._zebraRows) == "table" and (not wantZebra) then
    for _, t in pairs(frame._zebraRows) do
      if t and t.Hide then t:Hide() end
    end
  end
  -- Lists always render in their natural order, top->bottom.
  local growY = "down"
  local yCursor = 0
  local maxY = nil
  if wrapText and type(frameDef) == "table" and tonumber(frameDef.maxHeight) and tonumber(frameDef.maxHeight) > 0 then
    maxY = (tonumber(frameDef.maxHeight) or 0) - padTop - padBottom
    if maxY < rowH then maxY = rowH end
  end

  local function GetTextWidth()
    local w = (frame and frame.GetWidth and frame:GetWidth()) or (frameDef and frameDef.width) or 300
    -- Edit mode needs room for: [up][down][X] on the right.
    local rightPad = editMode and 62 or 12
    local leftPad = 16
    local tw = w - leftPad - rightPad
    if tw < 50 then tw = 50 end
    return tw
  end

  local textW = GetTextWidth()

  local function EnsureZebraRow(i)
    if not (zebra and frame and frame.CreateTexture) then return nil end
    frame._zebraRows = frame._zebraRows or {}
    local t = frame._zebraRows[i]
    if t then return t end
    t = frame:CreateTexture(nil, "BACKGROUND")
    frame._zebraRows[i] = t
    if t.SetColorTexture then
      t:SetColorTexture(1, 1, 1, zebraA)
    elseif t.SetVertexColor then
      t:SetVertexColor(1, 1, 1, zebraA)
    end
    t:Hide()
    return t
  end

  for i = 1, visibleRows do
    local e = entries[i + offset]
    local yBefore = yCursor
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

    -- Zebra striping (only reliable when not wrapping).
    local zb = EnsureZebraRow(i)
    if zb then
      if (not wrapText) and zebraA > 0 and ((i % 2) == 0) then
        zb:ClearAllPoints()
        zb:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -padTop - yBefore)
        zb:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -4, -padTop - yBefore - rowH)
        zb:Show()
      else
        zb:Hide()
      end
    end

    ApplyFontStyle(fs, frameDef and frameDef.font)

    local btn = EnsureRowButton(frame, i)
    btn:ClearAllPoints()
    btn:SetPoint("TOPLEFT", fs, "TOPLEFT", -2, 2)
    btn:SetPoint("BOTTOMRIGHT", fs, "BOTTOMRIGHT", 2, -2)
    btn._entry = e
    btn._entryAbsIndex = i + offset
    -- Keep the row button for drag-and-drop, but never allow it to toggle disable on click.
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
      if not (IsShiftKeyDown and IsShiftKeyDown()) then
        Print("Hold SHIFT and click X to remove from this frame.")
        return
      end
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

    -- Move up/down buttons sit to the left of X.
    local mvDown = EnsureMoveButton(frame, i, "down")
    local mvUp = EnsureMoveButton(frame, i, "up")
    if mvDown and mvUp then
      mvDown:ClearAllPoints()
      mvUp:ClearAllPoints()
      mvDown:SetPoint("RIGHT", rm, "LEFT", -2, 0)
      mvUp:SetPoint("RIGHT", mvDown, "LEFT", -2, 0)

      local absIdx = i + offset
      local entriesCount = (type(entries) == "table") and #entries or 0

      mvUp._entry = entry
      mvUp._entryAbsIndex = absIdx
      mvDown._entry = entry
      mvDown._entryAbsIndex = absIdx

      mvUp:SetShown(editMode and entry ~= nil)
      mvDown:SetShown(editMode and entry ~= nil)
      if editMode and entry ~= nil then
        mvUp:SetEnabled(absIdx > 1)
        mvDown:SetEnabled(absIdx < entriesCount)
      end

      local function DoMove(selfBtn, delta)
        if not editMode then return end
        local ent = selfBtn and selfBtn._entry
        local r = ent and ent.rule
        if type(r) ~= "table" then return end

        local realFrame = frame
        if frame and frame._targetID and framesByID then
          realFrame = framesByID[tostring(frame._targetID)] or realFrame
        end
        if not (realFrame and realFrame._lastEntries) then return end

        local curAbs = tonumber(selfBtn and selfBtn._entryAbsIndex) or 1
        local destAbs = curAbs + (tonumber(delta) or 0)
        if destAbs < 1 then destAbs = 1 end

        local ok = ReorderCustomRulesInFrame(realFrame, r, destAbs)
        if not ok then return end
        RefreshAll()
        if optionsFrame then RefreshActiveTab() end
      end

      mvUp:SetScript("OnClick", function(selfBtn) DoMove(selfBtn, -1) end)
      mvDown:SetScript("OnClick", function(selfBtn) DoMove(selfBtn, 1) end)
    end

    if e then
      local text
      if editMode then
        if tostring(frame and frame._id or ""):find("^inspect:") then
          local lbl = (e.rule and e.rule.label ~= nil) and tostring(e.rule.label) or ""
          if lbl ~= "" then
            text = lbl
          else
            text = e.rawTitle or e.editText or e.title
          end
        else
          text = e.editText or e.title
        end
      else
        text = e.title
      end
      if (not editMode) and e.extra then text = text .. "  " .. e.extra .. " " end
      fs:SetText(" " .. text .. " ")
      fs:Show()
      RenderIndicators(frame, i, fs, e.indicators, uiPad)
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
          RenderIndicators(frame, j, fs2, nil, uiPad)
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
      RenderIndicators(frame, i, fs, nil, uiPad)

      local zb = frame and frame._zebraRows and frame._zebraRows[i]
      if zb then zb:Hide() end
    end
  end

  for i = visibleRows + 1, maxItems do
    local fs = EnsureFontString(frame, i, frameDef and frameDef.font)
    fs:SetText("")
    fs:Hide()
    RenderIndicators(frame, i, fs, nil, uiPad)
    local btn = EnsureRowButton(frame, i)
    btn._entry = nil
    btn:Hide()

    local rm = EnsureRemoveButton(frame, i)
    rm:Hide()

    local zb = frame and frame._zebraRows and frame._zebraRows[i]
    if zb then zb:Hide() end
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

-- Bar contents inspector (instead of transforming bars into lists in edit mode)
local function GetFrameDisplayNameForInspector(frameID)
  frameID = tostring(frameID or "")
  if frameID == "" then return "" end
  local defs = GetEffectiveFrames and GetEffectiveFrames() or nil
  if type(defs) == "table" then
    for _, def in ipairs(defs) do
      if tostring(def and def.id or "") == frameID then
        local n = tostring(def and def.name or "")
        if n ~= "" then return n end
        break
      end
    end
  end
  return frameID
end

local RefreshBarContentsFrame

local function EnsureBarContentsFrame()
  if barContentsFrame then return barContentsFrame end

  local f = CreateFrame("Frame", "FR0Z3NUIFQTBarContents", UIParent, "BackdropTemplate")
  f:SetSize(420, 520)
  f:SetPoint("CENTER")
  f:SetFrameStrata("DIALOG")
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:EnableMouse(true)
  RestoreWindowPosition("barContents", f, "CENTER", "CENTER", 0, 0)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", function(self)
    if self.StopMovingOrSizing then self:StopMovingOrSizing() end
    SaveWindowPosition("barContents", self)
  end)
  ApplyFAOBackdrop(f, 0.90)

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", 12, -10)
  title:SetText("|cff00ccff[FQT]|r Bar Contents")
  f._title = title

  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", f, "TOPRIGHT", 2, 2)

  local up = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  up:SetSize(16, 16)
  up:SetText("")
  up:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
  up:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Down")
  up:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Highlight")
  up:SetDisabledTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Disabled")
  up:SetPoint("TOPRIGHT", close, "BOTTOMRIGHT", 0, -2)
  up:Hide()

  local down = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  down:SetSize(16, 16)
  down:SetText("")
  down:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
  down:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Down")
  down:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Highlight")
  down:SetDisabledTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Disabled")
  down:SetPoint("TOPRIGHT", up, "BOTTOMRIGHT", 0, -2)
  down:Hide()

  f._scrollUp = up
  f._scrollDown = down

  local host = CreateFrame("Frame", nil, f)
  host:SetPoint("TOPLEFT", 12, -34)
  host:SetPoint("BOTTOMRIGHT", -12, 12)
  host._isTrackerFrame = true
  f._host = host

  host:EnableMouseWheel(true)
  host:SetScript("OnMouseWheel", function(_, delta)
    if not editMode then return end
    local off = GetFrameScrollOffset(host and host._id)
    off = off + ((delta and delta < 0) and 1 or -1)
    if off < 0 then off = 0 end
    SetFrameScrollOffset(host and host._id, off)
    if RefreshBarContentsFrame then RefreshBarContentsFrame() end
  end)

  f:HookScript("OnShow", function(self)
    RestoreWindowPosition("barContents", self, "CENTER", "CENTER", 0, 0)
  end)

  barContentsFrame = f
  return f
end

RefreshBarContentsFrame = function()
  if not (barContentsFrame and barContentsFrame.IsShown and barContentsFrame:IsShown()) then return end
  local targetID = tostring(barContentsFrame._targetFrameID or "")
  if targetID == "" then return end

  local target = framesByID and framesByID[targetID]
  local entries = (target and (target._lastAllEntries or target._lastEntries)) or {}

  local host = barContentsFrame._host
  if not host then return end
  if host.EnableMouseWheel then host:EnableMouseWheel(editMode and true or false) end
  host._targetID = targetID
  host._id = "inspect:" .. targetID

  if barContentsFrame._title and barContentsFrame._title.SetText then
    barContentsFrame._title:SetText("|cff00ccff[FQT]|r Contents: " .. tostring(GetFrameDisplayNameForInspector(targetID)))
  end

  local tmp = {
    id = host._id,
    type = "list",
    rowHeight = 16,
    maxItems = 24,
    zebra = true,
  }

  -- No dedicated scroll buttons; edit-mode uses mousewheel.
  if barContentsFrame._scrollUp and barContentsFrame._scrollDown then
    barContentsFrame._scrollUp:Hide()
    barContentsFrame._scrollDown:Hide()
    barContentsFrame._scrollUp:SetScript("OnClick", nil)
    barContentsFrame._scrollDown:SetScript("OnClick", nil)
  end

  RenderList(tmp, host, entries)
end

local function ShowBarContentsForFrameID(frameID)
  frameID = tostring(frameID or "")
  if frameID == "" then return end
  local f = EnsureBarContentsFrame()
  f._targetFrameID = frameID
  RefreshBarContentsFrame()
  f:Show()
end

local function EnsureBarInspectButton(frame)
  if frame._barInspectBtn then return frame._barInspectBtn end
  local b = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  b:SetSize(44, 16)
  b:SetText("List")
  b:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
  b:SetFrameLevel((frame.GetFrameLevel and frame:GetFrameLevel() or 1) + 40)
  b:SetScript("OnClick", function()
    if not editMode then return end
    local id = tostring(frame and frame._id or "")
    if id == "" then return end
    if barContentsFrame and barContentsFrame.IsShown and barContentsFrame:IsShown() then
      local cur = tostring(barContentsFrame._targetFrameID or "")
      if cur == id then
        barContentsFrame:Hide()
        return
      end
    end
    ShowBarContentsForFrameID(id)
  end)
  frame._barInspectBtn = b
  return b
end

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
      local status = BuildRuleStatus(rule, evalCtx, { forceNormalVisibility = true })
      if status then
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

    -- Apply normal (non-edit) sequential group collapsing for the active view.
    local winnersByGroup = {}
    for _, row in ipairs(stagedActive) do
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
        local btn = EnsureBarInspectButton(f)
        btn:SetShown(editMode and true or false)
      else
        RenderList(def, f, entries)
      end

      UpdateAnchorLabel(f, def)
    end
  end

  RefreshBarContentsFrame()
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

-- Events
frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("QUEST_LOG_UPDATE")
frame:RegisterEvent("QUEST_ACCEPTED")
frame:RegisterEvent("QUEST_TURNED_IN")
frame:RegisterEvent("BAG_UPDATE_DELAYED")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("CALENDAR_UPDATE_EVENT_LIST")
frame:RegisterEvent("CALENDAR_UPDATE_EVENT")
frame:RegisterEvent("MODIFIER_STATE_CHANGED")

frame:SetScript("OnEvent", function(_, event, ...)
  if event == "MODIFIER_STATE_CHANGED" then
    if InCombatLockdown and InCombatLockdown() then
      frame._pendingInteractivity = true
      return
    end
    if ApplyTrackerInteractivity then ApplyTrackerInteractivity() end
    return
  end
  if event == "UNIT_AURA" then
    local unit = ...
    if unit ~= "player" then return end
  end

  if event == "PLAYER_LOGIN" then
    NormalizeSV()
    CreateAllFrames()
    C_Timer.After(1.0, RefreshAll)
    frame._didPostWorldWarm = false
    Print("Loaded. Type /fqt to configure.")
    return
  end

  if event == "PLAYER_ENTERING_WORLD" and not frame._didPostWorldWarm then
    frame._didPostWorldWarm = true
    -- Calendar data can arrive slightly after login; do one delayed refresh.
    C_Timer.After(5.0, RefreshAll)
  end

  if event == "CALENDAR_UPDATE_EVENT_LIST" or event == "CALENDAR_UPDATE_EVENT" then
    -- Calendar can fire a burst of events; avoid constant timer churn.
    if frame._refreshTimer then
      return
    end
    frame._refreshTimer = C_Timer.NewTimer(1.5, RefreshAll)
    return
  end

  if event == "PLAYER_REGEN_ENABLED" then
    if frame._pendingInteractivity then
      frame._pendingInteractivity = nil
      if ApplyTrackerInteractivity then
        C_Timer.After(0, ApplyTrackerInteractivity)
      end
    end
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
    if ns and ns.ShowOptions then
      ns.ShowOptions()
    else
      Print("Options UI module not loaded.")
    end
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
    local startDay = today
    local endDay = today
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

  if cmd == "twclear" then
    if type(ns) == "table" and type(ns.ClearRememberedTimewalkingKind) == "function" then
      ns.ClearRememberedTimewalkingKind()
    end
    RefreshAll()
    Print("Cleared remembered Timewalking weekly kind.")
    return
  end

  if cmd == "evclear" then
    if type(ns) == "table" and type(ns.ClearRememberedEventState) == "function" then
      ns.ClearRememberedEventState()
    end
    RefreshAll()
    Print("Cleared remembered calendar/timewalking event state.")
    return
  end

  Print("Commands: /fqt (options), /fqt on, /fqt off, /fqt reset, /fqt twdebug, /fqt twclear, /fqt evclear")
  end)
end
