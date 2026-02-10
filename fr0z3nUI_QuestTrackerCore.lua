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

local function HasProfessionSkillLineID(skillLineID)
  skillLineID = tonumber(skillLineID)
  if not skillLineID or skillLineID <= 0 then return false end

  local GP = _G and rawget(_G, "GetProfessions")
  local GPI = _G and rawget(_G, "GetProfessionInfo")
  if type(GP) ~= "function" or type(GPI) ~= "function" then
    return false
  end

  local ok, prof1, prof2, archaeology, fishing, cooking = pcall(GP)
  if not ok then return false end

  local indices = { prof1, prof2, archaeology, fishing, cooking }
  for i = 1, #indices do
    local idx = indices[i]
    if idx then
      local ok2, _, _, _, _, _, line = pcall(GPI, idx)
      line = ok2 and tonumber(line) or nil
      if line and line == skillLineID then
        return true
      end
    end
  end

  return false
end

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

  do
    local op, lvl = GetPlayerLevelGate(rule)
    if op and lvl then
      rule.playerLevel = { op, lvl }
    else
      rule.playerLevel = nil
    end
    rule.playerLevelOp = nil
  end

  if type(rule.item) == "table" then
    local cid, creq = GetItemCurrencyGate(rule.item)
    if cid and creq then
      rule.item.currencyID = { cid, creq }
      rule.item.currencyRequired = nil
    end

    local req, hide = GetItemRequiredGate(rule.item)
    if req then
      if hide then
        rule.item.required = { req, true }
      else
        rule.item.required = req
      end
      rule.item.hideWhenAcquired = nil
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

  -- Item auto-buy config (default off).
  -- Visible schema:
  --   item.required = { count, hideWhenAcquired, autoBuyEnabled, autoBuyMax }
  -- Also mirrored to:
  --   item.buy = { enabled = bool, max = number }
  if type(rule.item) == "table" and tonumber(rule.item.itemID) and tonumber(rule.item.itemID) > 0 then
    local item = rule.item

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
    if not req then req = tonumber(item.count) end
    req = tonumber(req)
    if not req or req <= 0 then req = 1 end
    hide = (hide and true or false)

    local buyEnabled = false
    local buyMax = 0

    -- Prefer tuple fields if present (so baked DB edits can be done in one place).
    if type(item.required) == "table" and (item.required[3] ~= nil or item.required[4] ~= nil) then
      buyEnabled = (item.required[3] == true)
      buyMax = tonumber(item.required[4]) or 0
    elseif type(item.buy) == "table" then
      buyEnabled = (item.buy.enabled == true)
      buyMax = tonumber(item.buy.max) or 0
    end
    if buyMax < 0 then buyMax = 0 end
    if buyMax <= 0 then buyEnabled = false end

    item.buy = item.buy or {}
    item.buy.enabled = buyEnabled and true or false
    item.buy.max = buyMax

    -- Make it visible directly on the rule.
    item.required = { req, hide, item.buy.enabled, item.buy.max }
    item.hideWhenAcquired = nil
  end

  -- Per-rule text styling ("inherit"/0 means no override).
  -- These are explicit so the DB + custom rules are consistent for manual edits.
  if rule.font == nil then rule.font = "inherit" end
  if rule.size == nil then rule.size = 0 end
  if rule.color == nil then rule.color = "inherit" end
end

local _defaultRulesMigrated = false
local function EnsureDefaultRulesMigrated()
  if _defaultRulesMigrated then return end
  _defaultRulesMigrated = true

  if type(ns.rules) ~= "table" then return end

  for _, r in ipairs(ns.rules) do
    if type(r) == "table" then
      NormalizeRuleInPlace(r)

      local isQuest = (r.questID ~= nil)

      -- Legacy default DB rules used `label` as a multiline info field for items/spells.
      -- Do not migrate quest labels: quest rules commonly use `label` as their display name.
      if (not isQuest) and type(r.item) == "table" and tonumber(r.item.itemID) and tonumber(r.item.itemID) > 0 then
        if r.itemInfo == nil and type(r.label) == "string" and r.label ~= "" then
          r.itemInfo = r.label
          r.label = nil
        end
      elseif (not isQuest) and (r.spellKnown or r.notSpellKnown or r.locationID or r.class or r.notInGroup) then
        if r.spellInfo == nil and type(r.label) == "string" and r.label ~= "" then
          r.spellInfo = r.label
          r.label = nil
        end
      elseif not isQuest then
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
  if fr0z3nUI_QuestTracker_Acc.settings.debugAutoBuy == nil then
    fr0z3nUI_QuestTracker_Acc.settings.debugAutoBuy = false
  else
    fr0z3nUI_QuestTracker_Acc.settings.debugAutoBuy = (fr0z3nUI_QuestTracker_Acc.settings.debugAutoBuy == true)
  end
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
  fr0z3nUI_QuestTracker_Acc.cache.currencyWB = fr0z3nUI_QuestTracker_Acc.cache.currencyWB or {}
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
      local required = tonumber((select(1, GetItemRequiredGate(rule.item)))) or 0
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

local function GetItemCountSafe(itemID, includeBank)
  itemID = tonumber(itemID)
  if not itemID then return 0 end

  includeBank = (includeBank == true)

  -- Prefer the global API when available; it typically counts bags + equipped.
  local GetItemCountFn = _G and rawget(_G, "GetItemCount")
  if type(GetItemCountFn) == "function" then
    local ok, v = pcall(GetItemCountFn, itemID, includeBank, false, false)
    v = ok and tonumber(v) or 0
    if v and v > 0 then return v end
  end

  if C_Item and C_Item.GetItemCount then
    local ok, v = pcall(C_Item.GetItemCount, itemID, includeBank, false, false)
    v = ok and tonumber(v) or 0
    if v and v > 0 then return v end
  end

  -- Last-resort: consider equipped items (not all count APIs include equipment).
  if GetInventoryItemID and GetInventoryItemID("player", 19) == itemID then
    return 1
  end

  return 0
end

local function GetCurrencyInfoSafe(currencyID)
  currencyID = tonumber(currencyID)
  if not currencyID or currencyID <= 0 then return nil end

  if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
    local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, currencyID)
    if ok and type(info) == "table" then
      return info
    end
  end

  return nil
end

local function GetCurrencyQuantitySafe(currencyID)
  currencyID = tonumber(currencyID)
  if not currencyID or currencyID <= 0 then return 0 end

  local info = GetCurrencyInfoSafe(currencyID)
  if type(info) == "table" then
    return tonumber(info.quantity) or 0
  end

  return 0
end

local _warbandCurrencyTotals = {}
local _warbandCurrencyRequestAt = 0
local _warbandCurrencyFullRefreshAt = 0

local function RequestWarbandCurrencyData()
  if not (C_CurrencyInfo and C_CurrencyInfo.RequestCurrencyDataForAccountCharacters) then
    return false
  end

  local now = (GetTime and GetTime()) or 0
  if now > 0 and _warbandCurrencyRequestAt > 0 and (now - _warbandCurrencyRequestAt) < 30 then
    return false
  end
  _warbandCurrencyRequestAt = now
  pcall(C_CurrencyInfo.RequestCurrencyDataForAccountCharacters)
  return true
end

local function GetCachedWarbandCurrencyTotal(currencyID)
  local acc = fr0z3nUI_QuestTracker_Acc
  local t = (type(acc) == "table" and type(acc.cache) == "table") and acc.cache.currencyWB or nil
  if type(t) ~= "table" then return nil end

  local e = t[currencyID]
  if type(e) == "table" then
    local total = tonumber(e.total)
    if total ~= nil then return total end
  end
  return nil
end

local function SaveCachedWarbandCurrencyTotal(currencyID, total)
  local acc = fr0z3nUI_QuestTracker_Acc
  if type(acc) ~= "table" then return end
  acc.cache = acc.cache or {}
  acc.cache.currencyWB = acc.cache.currencyWB or {}
  acc.cache.currencyWB[currencyID] = {
    total = tonumber(total) or 0,
    at = (time and time()) or 0,
  }
end

local function ComputeWarbandCurrencyTotalFromAccountData(currencyID)
  if not (C_CurrencyInfo and C_CurrencyInfo.GetAccountCharacterCurrencyData) then
    return nil
  end

  local ok, data = pcall(C_CurrencyInfo.GetAccountCharacterCurrencyData, currencyID)
  if not ok or type(data) ~= "table" then
    return nil
  end

  local total = 0
  local found = false
  for _, row in ipairs(data) do
    if type(row) == "table" then
      local q = row.quantity
      if q == nil then q = row.amount end
      if q == nil then q = row.count end
      if q == nil then q = row.totalQuantity end
      q = tonumber(q)
      if q ~= nil then
        total = total + q
        found = true
      end
    end
  end

  if not found then return nil end
  return total
end

local function GetWarbandCurrencyTotalSafe(currencyID, allowCache)
  currencyID = tonumber(currencyID)
  if not currencyID or currencyID <= 0 then return nil, false end

  if _warbandCurrencyTotals[currencyID] ~= nil then
    return _warbandCurrencyTotals[currencyID], false
  end

  RequestWarbandCurrencyData()

  local total = ComputeWarbandCurrencyTotalFromAccountData(currencyID)
  if total ~= nil then
    _warbandCurrencyTotals[currencyID] = total
    SaveCachedWarbandCurrencyTotal(currencyID, total)
    return total, false
  end

  if allowCache then
    local cached = GetCachedWarbandCurrencyTotal(currencyID)
    if cached ~= nil then
      return cached, true
    end
  end

  return nil, false
end

local IsCurrencyWarbandTransferableSafe

local function CollectCurrencyGateIDsFromRules()
  local out = {}

  local function AddFromRule(r)
    if type(r) ~= "table" then return end
    if type(r.item) == "table" then
      local cid = tonumber((type(r.item.currencyID) == "table") and r.item.currencyID[1] or r.item.currencyID)
      if cid and cid > 0 then
        out[cid] = true
      end
    end
  end

  if type(ns.rules) == "table" then
    for _, r in ipairs(ns.rules) do
      AddFromRule(r)
    end
  end

  local acc = fr0z3nUI_QuestTracker_Acc
  local settings = (type(acc) == "table") and acc.settings or nil
  local custom = (type(settings) == "table") and settings.customRules or nil
  if type(custom) == "table" then
    for _, r in ipairs(custom) do
      AddFromRule(r)
    end
  end

  local edits = (type(settings) == "table") and settings.defaultRuleEdits or nil
  if type(edits) == "table" then
    for _, r in pairs(edits) do
      AddFromRule(r)
    end
  end

  return out
end

local function RefreshWarbandCurrencyCacheForAllKnownCurrencies()
  local now = (GetTime and GetTime()) or 0
  if now > 0 and _warbandCurrencyFullRefreshAt > 0 and (now - _warbandCurrencyFullRefreshAt) < 30 then
    return
  end
  _warbandCurrencyFullRefreshAt = now

  RequestWarbandCurrencyData()

  local ids = CollectCurrencyGateIDsFromRules()
  for cid in pairs(ids) do
    if IsCurrencyWarbandTransferableSafe(cid) then
      _warbandCurrencyTotals[cid] = nil
      local total = ComputeWarbandCurrencyTotalFromAccountData(cid)
      if total ~= nil then
        _warbandCurrencyTotals[cid] = total
        SaveCachedWarbandCurrencyTotal(cid, total)
      end
    end
  end
end

IsCurrencyWarbandTransferableSafe = function(currencyID)
  local info = GetCurrencyInfoSafe(currencyID)
  return (type(info) == "table" and info.isAccountTransferable == true) and true or false
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

local _calendarKeywordCache = { at = 0, active = {}, unknown = {} }

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

local function IsCalendarEventActiveByKeywords(keywords, includeHolidayText)
  local kwList = NormalizeCalendarKeywords(keywords)
  if not kwList then return false, false end

  local cacheKeyBase = CalendarKeywordCacheKey(kwList)
  if not cacheKeyBase then return false, false end
  local cacheKey = (includeHolidayText == true and "h:" or "t:") .. cacheKeyBase

  local needles = {}
  for i = 1, #kwList do
    needles[i] = tostring(kwList[i] or ""):lower()
  end

  local now = 0
  if GetServerTime then now = tonumber(GetServerTime()) or 0 end
  if _calendarKeywordCache.at and (now - (_calendarKeywordCache.at or 0)) < 60 and _calendarKeywordCache.active[cacheKey] ~= nil then
    local unk = (_calendarKeywordCache.unknown and _calendarKeywordCache.unknown[cacheKey]) and true or false
    return _calendarKeywordCache.active[cacheKey] and true or false, unk
  end

  EnsureCalendarOpened()
  if not (C_Calendar and C_Calendar.GetNumDayEvents and C_Calendar.GetDayEvent) then
    _calendarKeywordCache.at = now
    _calendarKeywordCache.active[cacheKey] = false
    if _calendarKeywordCache.unknown then _calendarKeywordCache.unknown[cacheKey] = true end
    return false, true
  end

  local today = GetCurrentCalendarDay()
  if not today then
    _calendarKeywordCache.at = now
    _calendarKeywordCache.active[cacheKey] = false
    if _calendarKeywordCache.unknown then _calendarKeywordCache.unknown[cacheKey] = true end
    return false, true
  end

  -- Daily check only: only treat an event as active if it appears on *today*.
  -- This avoids false positives from upcoming/previous calendar entries.
  local startDay = today
  local endDay = today

  local found = false
  for day = startDay, endDay do
    local okNum, n = pcall(C_Calendar.GetNumDayEvents, 0, day)
    n = okNum and tonumber(n) or 0
    for i = 1, n do
      local title = GetCalendarEventText(0, day, i) or ""
      local holidayText = ""
      if includeHolidayText == true then
        holidayText = GetCalendarHolidayText(0, day, i) or ""
      end
      local hay = title:lower()
      if holidayText ~= "" then
        hay = (hay .. "\n" .. holidayText:lower())
      end

      for j = 1, #needles do
        local k = needles[j]
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
  if _calendarKeywordCache.unknown then _calendarKeywordCache.unknown[cacheKey] = false end
  return found and true or false, false
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
    if s and s > 0 and s < (60 * 60 * 24 * 8) then
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
  if exp > (now + (60 * 60 * 24 * 8)) then
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
  -- Timewalking kind memory is intentionally short-lived.
  -- Store it only until the next DAILY reset to avoid stale/incorrect kinds persisting.
  local resetAt = GetDailyResetAt()
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
  -- Daily reset should be within ~48 hours.
  if exp > (now + (60 * 60 * 48)) then
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

-- First character per account to log in after daily reset: clear remembered event state.
-- We store the *next daily reset timestamp* (GetDailyResetAt) as a stable per-day stamp.
local function MaybeAutoResetEventsOncePerDay()
  NormalizeSV()
  local acc = fr0z3nUI_QuestTracker_Acc
  if not (type(acc) == "table" and type(acc.cache) == "table") then
    return
  end

  local dailyResetAt = tonumber(GetDailyResetAt()) or 0
  if dailyResetAt <= 0 then
    return
  end

  local cache = acc.cache
  local lastStamp = tonumber(cache.eventAutoResetDailyStamp) or 0
  if lastStamp == dailyResetAt then
    return
  end

  ClearRememberedEventState()
  cache.eventAutoResetDailyStamp = dailyResetAt
end

ns.ClearRememberedTimewalkingKind = ClearRememberedTimewalkingKind
ns.ClearRememberedEventState = ClearRememberedEventState

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

  local size = rule.size or rule.fontSize
  size = tonumber(size)
  if size ~= nil and size <= 0 then size = nil end

  local flags = rule.fontFlags or rule.flags
  if flags ~= nil and tostring(flags):lower() == "inherit" then flags = nil end

  local color = rule.fontColor
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

local function EvaluateRuleCondition(node)
  if type(node) ~= "table" then return false end

  local includeBank = (node.includeBank == true)

  local function EvalChild(child)
    if includeBank and type(child) == "table" and child.includeBank == nil then
      local t = {}
      for k, v in pairs(child) do t[k] = v end
      t.includeBank = true
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
      if GetItemCountSafe(tonumber(itemID), includeBank) >= need then
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
    if GetItemCountSafe(tonumber(node.itemID), includeBank) < need then
      return false
    end
  end

  if type(node.item) == "table" and node.item.itemID then
    hadCondition = true
    local itemID = tonumber(node.item.itemID)
    local need = tonumber(node.item.count) or tonumber(node.item.required) or 1
    local inc = (node.item.includeBank == true) or includeBank
    if GetItemCountSafe(itemID, inc) < need then
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
      local charQty = GetCurrencyQuantitySafe(currencyID)
      local gateQty = charQty
      if IsCurrencyWarbandTransferableSafe(currencyID) then
        local wbTotal = select(1, GetWarbandCurrencyTotalSafe(currencyID, true))
        if wbTotal ~= nil then
          gateQty = wbTotal
        end
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

  local hideWhenCompleted
  if type(rule) == "table" and rule.hideWhenCompleted ~= nil then
    hideWhenCompleted = rule.hideWhenCompleted and true or false
  else
    -- default: hide completed quests / completed tasks
    hideWhenCompleted = true
  end

  -- Events: Darkmoon Faire behaves like a checklist; keep entries visible even when completed.
  if type(rule) == "table" and tostring(rule.group or "") == "event:darkmoon-faire" then
    hideWhenCompleted = false
  end

  local completed = false
  if questID and IsQuestCompleted(questID) then
    completed = true
  end

  -- Optional additional completion criteria (for non-quest tasks or stricter completion).
  local complete = (type(rule) == "table" and type(rule.complete) == "table") and rule.complete or nil
  if complete then
    local ok
    if type(complete.any) == "table" or type(complete.all) == "table" then
      ok = EvaluateRuleCondition(complete)
    else
      ok = true
      if complete.questID then
        ok = ok and IsQuestCompleted(tonumber(complete.questID))
      end
      if type(complete.item) == "table" and complete.item.itemID then
        local itemID = tonumber(complete.item.itemID)
        local need = tonumber(complete.item.count) or tonumber(complete.item.required) or 1
        local have = GetItemCountSafe(itemID)
        ok = ok and (have >= need)
      end
      if complete.rep ~= nil or complete.factionID ~= nil or complete.minStanding ~= nil or complete.maxStanding ~= nil then
        ok = ok and EvaluateRuleCondition({ rep = complete.rep, factionID = complete.factionID, minStanding = complete.minStanding, maxStanding = complete.maxStanding })
      end
      if complete.profession ~= nil then
        ok = ok and HasProfession(complete.profession)
      end
      if type(complete.aura) == "table" and complete.aura.spellID then
        local has = HasAuraSpellID(tonumber(complete.aura.spellID))
        local must = (complete.aura.mustHave ~= false)
        ok = ok and (must and has or (not must and not has))
      end
    end

    if ok then
      completed = true
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
  if applyGates and type(rule) == "table" and rule.professionSkillLineID ~= nil then
    if not HasProfessionSkillLineID(rule.professionSkillLineID) then
      return nil
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
    if not (completed and hideWhenCompleted == false) then
      return nil
    end
  end

  -- Aura gate
  if applyGates and type(rule.aura) == "table" then
    local has = nil
    local rememberedKey = nil
    local calendarUnknown = false

    if rule.aura.eventKind == "timewalking" then
      has = IsAnyTimewalkingEventActive()
      rememberedKey = "event:timewalking"
    elseif rule.aura.eventKind == "calendar" then
      local kws = rule.aura.keywords or rule.aura.keyword or rule.aura.text
      has, calendarUnknown = IsCalendarEventActiveByKeywords(kws, rule.aura.includeHolidayText == true)
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
        if calendarUnknown == true then
          has = HasRememberedDailyAura(rememberedKey) or has
        end
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
  local shoppingListText = nil
  local currencyGate = nil

  -- Explicit extra override (used for helper tasks)
  if type(rule) == "table" and rule.extra ~= nil then
    extra = tostring(rule.extra)
  end

  -- Currency progress placeholders for questInfo/spellInfo/textInfo.
  -- For quest rules, currency gates commonly live under showIf (e.g. Archaeology fragments).
  -- We extract the first currency gate we can find so $hv/$rq/{currency} placeholders render.
  if type(rule) == "table" and currencyGate == nil then
    local function ExtractCurrencyGate(node)
      if type(node) ~= "table" then return nil, nil end

      if type(node.any) == "table" then
        for _, child in ipairs(node.any) do
          local cid, req = ExtractCurrencyGate(child)
          if cid and cid > 0 then return cid, req end
        end
      end

      if type(node.all) == "table" then
        for _, child in ipairs(node.all) do
          local cid, req = ExtractCurrencyGate(child)
          if cid and cid > 0 then return cid, req end
        end
      end

      if node.currencyID ~= nil then
        if type(node.currencyID) == "table" then
          return tonumber(node.currencyID[1]), tonumber(node.currencyID[2])
        end
        return tonumber(node.currencyID), tonumber(node.currencyRequired) or tonumber(node.required) or tonumber(node.count)
      end
      if type(node.currency) == "table" then
        local cid = tonumber(node.currency.currencyID or node.currency.id or node.currency[1])
        local req = tonumber(node.currency.required or node.currency[2] or node.required or node.count)
        return cid, req
      end
      return nil, nil
    end

    local cid, req = ExtractCurrencyGate(rule)
    if not (cid and cid > 0) and type(rule.showIf) == "table" then
      cid, req = ExtractCurrencyGate(rule.showIf)
    end

    if cid and cid > 0 then
      local charQty = GetCurrencyQuantitySafe(cid)
      local isWB = IsCurrencyWarbandTransferableSafe(cid)
      local wbTotal = nil
      local gateQty = charQty
      if isWB then
        wbTotal = select(1, GetWarbandCurrencyTotalSafe(cid, true))
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
    end
  end

  if type(rule.item) == "table" and rule.item.itemID then
    local itemID = tonumber(rule.item.itemID)

    if applyGates then
      local currencyID, currencyRequired = GetItemCurrencyGate(rule.item)
      if currencyID and currencyRequired then
        local charQty = GetCurrencyQuantitySafe(currencyID)
        local isWB = IsCurrencyWarbandTransferableSafe(currencyID)
        local wbTotal = nil
        local gateQty = charQty
        if isWB then
          wbTotal = select(1, GetWarbandCurrencyTotalSafe(currencyID, true))
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

    local count = GetItemCountSafe(itemID, (rule.item.includeBank == true))

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
  if type(rule.progress) == "table" and rule.progress.objectiveIndex then
    local txt = GetQuestObjectiveProgressText(questID, rule.progress.objectiveIndex)
    if txt then extra = txt end
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
            local have = GetItemCountSafe(itemID, (it.includeBank == true))
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

    local info = GetCurrencyInfoSafe(g.id)
    local name = (type(info) == "table" and info.name) or ""
    local repHave = tostring(tonumber(g.gateQty) or 0)
    local repChar = tostring(tonumber(g.charQty) or 0)
    local repWB = (g.wbTotal ~= nil) and tostring(tonumber(g.wbTotal) or 0) or ""
    local repReq = tostring(tonumber(g.required) or 0)
    local repName = tostring(name or "")

    local before = s
    s = s:gsub("{currency}", repHave)
    s = s:gsub("{currency:have}", repHave)
    s = s:gsub("{currency:char}", repChar)
    s = s:gsub("{currency:wb}", repWB)
    s = s:gsub("{currency:req}", repReq)
    s = s:gsub("{currency:name}", repName)
    s = s:gsub("%s+$", "")
    return s, s ~= before
  end

  do
    local newTitle = title
    local replaced = false
    newTitle, replaced = ApplyCurrencyPlaceholders(newTitle, currencyGate)
    if replaced then
      title = newTitle
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

    do
      local op, lvl = GetPlayerLevelGate(rule)
      if op and lvl then
        editText = editText .. string.format(" [Lvl %s %d]", op, lvl)
      end
    end
  end

  local indicators = BuildIndicators(rule)

  if type(rule) == "table" and rule.color ~= nil then
    local c = rule.color
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
    hideWhenCompleted = hideWhenCompleted,
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
  store[tostring(f._id)] = {
    point = tostring(point),
    relPoint = tostring(relPoint or point),
    x = tonumber(x) or 0,
    y = tonumber(y) or 0,
    -- Always store relative to UIParent for consistent behavior across all frames.
    parent = "UIParent",
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

  f:ClearAllPoints()
  f:SetPoint(point, ref or UIParent, relPoint, tonumber(pos.x) or 0, tonumber(pos.y) or 0)
  return true
end

local function ResolveFrameAnchor(def, defaultPoint)
  if type(def) ~= "table" then
    local p = tostring(defaultPoint or "CENTER")
    return p, p, 0, 0
  end

  local point = def.point
  local relPoint = def.relPoint or def.point
  local x = def.x
  local y = def.y

  if not point then
    local ap = AnchorCornerToPoint and AnchorCornerToPoint(def.anchorCorner)
    if ap then
      point = ap
      relPoint = ap
    end
  end

  if not point then
    point = tostring(defaultPoint or "CENTER")
    relPoint = point
    x = x or 0
    y = y or 0
  end

  return tostring(point), tostring(relPoint or point), tonumber(x) or 0, tonumber(y) or 0
end

local function ApplyFramePositionFromDef(f, def)
  if not (f and f.ClearAllPoints and f.SetPoint) then return false end
  -- Avoid fighting the user while actively dragging in edit mode.
  if f.IsMoving and f:IsMoving() then return false end
  if f._fqtIsMoving then return false end

  -- Prefer saved offsets (dragged positions) but allow anchorCorner/point changes to take effect.
  local store = GetFramePosStore()
  local pos = store and f._id and store[tostring(f._id)]
  if type(pos) == "table" then
    local point, relPoint = pos.point, pos.relPoint
    if type(def) == "table" and def.anchorCorner then
      local ap = AnchorCornerToPoint and AnchorCornerToPoint(def.anchorCorner)
      if ap then
        -- If the user changes anchorCorner, keep the frame in the same on-screen spot
        -- by converting the saved offsets from the old point to the new point.
        if pos.point and tostring(pos.point) ~= tostring(ap) and f.GetLeft then
          local left, right, top, bottom = f:GetLeft(), f:GetRight(), f:GetTop(), f:GetBottom()
          local pl, pr, pt, pb = UIParent:GetLeft(), UIParent:GetRight(), UIParent:GetTop(), UIParent:GetBottom()
          if left and right and top and bottom and pl and pr and pt and pb then
            local cx, cy = (left + right) / 2, (bottom + top) / 2
            local pcx, pcy = (pl + pr) / 2, (pb + pt) / 2

            local function AnchorXYFromRect(pointStr, l, r, t, b, cX, cY)
              pointStr = tostring(pointStr or "CENTER"):upper()
              local x
              if pointStr:find("LEFT", 1, true) then x = l
              elseif pointStr:find("RIGHT", 1, true) then x = r
              else x = cX end

              local y
              if pointStr:find("TOP", 1, true) then y = t
              elseif pointStr:find("BOTTOM", 1, true) then y = b
              else y = cY end

              return x, y
            end

            local ax, ay = AnchorXYFromRect(ap, left, right, top, bottom, cx, cy)
            local px, py = AnchorXYFromRect(ap, pl, pr, pt, pb, pcx, pcy)
            if ax and ay and px and py then
              pos.x = math.floor(((ax - px) or 0) + 0.5)
              pos.y = math.floor(((ay - py) or 0) + 0.5)
              pos.point = ap
              pos.relPoint = ap
              point = ap
              relPoint = ap
            end
          end
        end
        point = ap
        relPoint = ap
      end
    end
    if not point and type(def) == "table" then point = def.point end
    if not relPoint and type(def) == "table" then relPoint = def.relPoint or def.point end
    if point then
      local ref = UIParent
      f:ClearAllPoints()
      f:SetPoint(tostring(point), ref or UIParent, tostring(relPoint or point), tonumber(pos.x) or 0, tonumber(pos.y) or 0)
      return true
    end
  end

  -- No saved framePos entry: if an anchorCorner is set, keep the frame visually stationary by
  -- computing the offsets for that anchor from the current on-screen rect.
  if type(def) == "table" and def.anchorCorner and f.GetLeft and UIParent and UIParent.GetLeft then
    local ap = AnchorCornerToPoint and AnchorCornerToPoint(def.anchorCorner)
    if ap then
      local left, right, top, bottom = f:GetLeft(), f:GetRight(), f:GetTop(), f:GetBottom()
      local pl, pr, pt, pb = UIParent:GetLeft(), UIParent:GetRight(), UIParent:GetTop(), UIParent:GetBottom()
      if left and right and top and bottom and pl and pr and pt and pb then
        local cx, cy = (left + right) / 2, (bottom + top) / 2
        local pcx, pcy = (pl + pr) / 2, (pb + pt) / 2

        local function AnchorXYFromRect(pointStr, l, r, t, b, cX, cY)
          pointStr = tostring(pointStr or "CENTER"):upper()
          local x
          if pointStr:find("LEFT", 1, true) then x = l
          elseif pointStr:find("RIGHT", 1, true) then x = r
          else x = cX end

          local y
          if pointStr:find("TOP", 1, true) then y = t
          elseif pointStr:find("BOTTOM", 1, true) then y = b
          else y = cY end

          return x, y
        end

        local ax, ay = AnchorXYFromRect(ap, left, right, top, bottom, cx, cy)
        local px, py = AnchorXYFromRect(ap, pl, pr, pt, pb, pcx, pcy)
        if ax and ay and px and py then
          local x = math.floor(((ax - px) or 0) + 0.5)
          local y = math.floor(((ay - py) or 0) + 0.5)
          -- Persist the converted offsets into the def so subsequent refreshes stay consistent.
          def.point = ap
          def.relPoint = ap
          def.x = x
          def.y = y
        end
      end
    end
  end

  local point, relPoint, x, y = ResolveFrameAnchor(def, "CENTER")
  local ref = (f.GetParent and f:GetParent()) or UIParent
  f:ClearAllPoints()
  f:SetPoint(point, ref or UIParent, relPoint, x, y)
  return true
end

local function NudgeFrameOnScreen(f, pad)
  if not (f and f.GetLeft and f.GetRight and f.GetTop and f.GetBottom and f.GetPoint and f.SetPoint and f.ClearAllPoints) then return false end
  pad = tonumber(pad)
  if not pad or pad < 0 then pad = 8 end

  local scale = (f.GetEffectiveScale and f:GetEffectiveScale()) or 1
  if not scale or scale <= 0 then scale = 1 end

  local left, right, top, bottom = f:GetLeft(), f:GetRight(), f:GetTop(), f:GetBottom()
  if not (left and right and top and bottom) then return false end

  local sw = (GetScreenWidth and GetScreenWidth()) or (UIParent and UIParent.GetWidth and UIParent:GetWidth()) or 0
  local sh = (GetScreenHeight and GetScreenHeight()) or (UIParent and UIParent.GetHeight and UIParent:GetHeight()) or 0
  if not (sw and sh) or sw <= 0 or sh <= 0 then return false end

  -- Convert into scaled screen space so comparisons stay correct under per-frame scaling.
  left, right, top, bottom = left * scale, right * scale, top * scale, bottom * scale
  local padS = pad * scale

  local frameW = right - left
  local frameH = top - bottom

  local dxS, dyS = 0, 0

  if frameW > (sw - 2 * padS) then
    dxS = (padS - left)
  else
    if left < padS then dxS = (padS - left)
    elseif right > (sw - padS) then dxS = ((sw - padS) - right) end
  end

  if frameH > (sh - 2 * padS) then
    dyS = ((sh - padS) - top)
  else
    if bottom < padS then dyS = (padS - bottom)
    elseif top > (sh - padS) then dyS = ((sh - padS) - top) end
  end

  if dxS == 0 and dyS == 0 then return false end

  -- Convert correction back into unscaled anchor offsets.
  local dx = dxS / scale
  local dy = dyS / scale

  local point, rel, relPoint, x, y = f:GetPoint(1)
  if not point then return false end
  f:ClearAllPoints()
  f:SetPoint(point, rel or UIParent, relPoint or point, (tonumber(x) or 0) + dx, (tonumber(y) or 0) + dy)
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
    if p then p._fqtIsMoving = true end
  end)
  btn:SetScript("OnDragStop", function(self)
    local p = self:GetParent()
    if p and p.StopMovingOrSizing then p:StopMovingOrSizing() end
    if p then p._fqtIsMoving = nil end
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
  do
    local p, rp, x, y = ResolveFrameAnchor(def, "TOP")
    f:SetPoint(p, ref or UIParent, rp, x, y)
  end
  ApplyFramePositionFromDef(f, def)
  NudgeFrameOnScreen(f, 8)

  f._itemFont = "GameFontHighlightSmall"
  f.items = {}

  f._wheelEnabled = (editMode and true) or ((IsShiftKeyDown and IsShiftKeyDown()) and true or false)
  f:EnableMouseWheel(f._wheelEnabled)
  f:SetScript("OnMouseWheel", function(self, delta)
    if not (editMode or (IsShiftKeyDown and IsShiftKeyDown())) then return end
    -- Only allow scrolling when the content actually overflows.
    if self._canScroll ~= true then return end
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
  do
    local p, rp, x, y = ResolveFrameAnchor(def, "TOPRIGHT")
    f:SetPoint(p, ref or UIParent, rp, x, y)
  end
  ApplyFramePositionFromDef(f, def)
  NudgeFrameOnScreen(f, 8)

  f._itemFont = "GameFontHighlight"
  f.items = {}
  f.buttons = {}

  f._wheelEnabled = (editMode and true) or ((IsShiftKeyDown and IsShiftKeyDown()) and true or false)
  f:EnableMouseWheel(f._wheelEnabled)
  f:SetScript("OnMouseWheel", function(self, delta)
    if not (editMode or (IsShiftKeyDown and IsShiftKeyDown())) then return end
    -- Only allow scrolling when the content actually overflows.
    if self._canScroll ~= true then return end
    local id = tostring(self._id or "")
    if id == "" then return end
    local offset = GetFrameScrollOffset(id)
    offset = offset + ((delta and delta < 0) and 1 or -1)
    if offset < 0 then offset = 0 end
    local maxOffset = tonumber(self._maxScrollOffset)
    if maxOffset and maxOffset >= 0 and offset > maxOffset then
      offset = maxOffset
    end
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
      local e = EntryForSlot(i)
      if e and e.rule then
        ApplyFontStyle(fs, GetRuleFontDef(e.rule))
      end
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
    local e = EntryForSlot(i)
    if e and e.rule then
      ApplyFontStyle(fs, GetRuleFontDef(e.rule))
    end

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
  local maxItems = tonumber(frameDef.maxItems) or 20
  local rowH = tonumber(frameDef.rowHeight) or 16
  if type(entries) ~= "table" then entries = {} end

  local debugHitboxes = (editMode and (type(GetUISetting) == "function") and (GetUISetting("debugHitboxes", false) == true)) and true or false

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
    local count = #entries

    local wrapText0 = not editMode
    local maxY0 = nil
    if wrapText0 then
      local limit = nil
      if type(frameDef) == "table" and tonumber(frameDef.maxHeight) and tonumber(frameDef.maxHeight) > 0 then
        limit = tonumber(frameDef.maxHeight) or nil
      elseif frame and frame.GetHeight then
        limit = frame:GetHeight()
      end
      if limit and limit > 0 then
        maxY0 = limit - padTop - padBottom
        if maxY0 < rowH then maxY0 = rowH end
      end
    end

    local textW0
    do
      local w = (frame and frame.GetWidth and frame:GetWidth()) or (frameDef and frameDef.width) or 300
      local rightPad = editMode and 62 or 12
      local leftPad = 16
      local tw = w - leftPad - rightPad
      if tw < 50 then tw = 50 end
      textW0 = tw
    end

    -- Default: only allow scrolling when there are more entries than visible rows.
    maxOffset = math.max(0, count - visibleRows)

    -- Wrapped text can overflow even when count <= visibleRows. Also, the prior approach
    -- allowed maxOffset=count-1 which can leave the list mostly empty at the bottom.
    -- Instead, compute maxOffset based on how many entries can fit on the *last page*.
    if (not editMode) and wrapText0 and maxY0 and count > 0 and frame and frame.CreateFontString then
      local function GetEntryText(e)
        if not e then return nil end
        local text = e.title
        if text == nil then return nil end
        text = tostring(text)
        if e.extra then text = text .. "  " .. tostring(e.extra) .. " " end
        return " " .. text .. " "
      end

      local measure = frame._measureFS
      if not (measure and measure.SetText and measure.GetStringHeight) then
        measure = frame:CreateFontString(nil, "OVERLAY", frame._itemFont or "GameFontHighlight")
        frame._measureFS = measure
        if measure.SetJustifyH then measure:SetJustifyH("LEFT") end
        if measure.SetJustifyV then measure:SetJustifyV("TOP") end
      end
      ApplyFontStyle(measure, frameDef and frameDef.font)
      if measure.SetWordWrap then measure:SetWordWrap(true) end
      if measure.SetNonSpaceWrap then measure:SetNonSpaceWrap(true) end
      if measure.SetWidth then measure:SetWidth(textW0) end

      local gapWrap = 2
      local total = 0
      local fitCount = 0
      for i = count, 1, -1 do
        local e = entries[i]
        if e and e.rule then
          ApplyFontStyle(measure, GetRuleFontDef(e.rule))
        else
          ApplyFontStyle(measure, frameDef and frameDef.font)
        end
        local t = GetEntryText(e)
        measure:SetText(t or "")
        local h = (measure:GetStringHeight() or 0)
        if h < rowH then h = rowH end

        local add = h + gapWrap
        if fitCount > 0 and listPad > 0 then
          add = add + listPad
        end

        -- Always allow at least one entry, even if it exceeds the frame.
        if fitCount > 0 and (total + add) > maxY0 then
          break
        end

        total = total + add
        fitCount = fitCount + 1
        if fitCount >= visibleRows then
          break
        end
      end
      if fitCount < 1 then fitCount = 1 end

      local wrapMaxOffset = math.max(0, count - fitCount)
      maxOffset = wrapMaxOffset
    end
  end

  -- Store whether scrolling is meaningful for this frame right now.
  if frame then
    frame._canScroll = (maxOffset > 0) and true or false
    frame._maxScrollOffset = maxOffset
  end

  -- If the frame doesn't need scrolling, force-reset any stale stored scroll offset.
  if maxOffset <= 0 and offset ~= 0 then
    offset = 0
    if frame and frame._id and SetFrameScrollOffset then
      SetFrameScrollOffset(frame._id, 0)
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
  -- Lists render in natural order, top->bottom (content ordering is independent of frame anchoring).
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

  local function HideDebugRects()
    if not frame then return end
    if type(frame._debugHitRects) ~= "table" then return end
    for _, byIdx in pairs(frame._debugHitRects) do
      if type(byIdx) == "table" then
        for _, t in pairs(byIdx) do
          if t and t.Hide then t:Hide() end
        end
      end
    end
  end

  local function EnsureDebugRect(kind, i, r, g, b, a)
    if not (frame and frame.CreateTexture) then return nil end
    frame._debugHitRects = frame._debugHitRects or {}
    frame._debugHitRects[kind] = frame._debugHitRects[kind] or {}
    local t = frame._debugHitRects[kind][i]
    if t then return t end
    t = frame:CreateTexture(nil, "OVERLAY")
    frame._debugHitRects[kind][i] = t
    if t.SetColorTexture then
      t:SetColorTexture(r or 1, g or 1, b or 1, a or 0.15)
    elseif t.SetVertexColor then
      t:SetVertexColor(r or 1, g or 1, b or 1, a or 0.15)
    end
    t:Hide()
    return t
  end

  if not debugHitboxes then
    HideDebugRects()
  end

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

    -- Reset any prior per-row styling (FontStrings are reused across rows).
    if fs then
      if fs._defaultFont and fs.SetFont then
        local d = fs._defaultFont
        if d[1] or d[2] or d[3] then
          local curP, curS, curF = fs:GetFont()
          fs:SetFont(d[1] or curP, d[2] or curS or 12, d[3] or curF)
        end
      end
      if fs._defaultTextColor and fs.SetTextColor then
        local c = fs._defaultTextColor
        fs:SetTextColor(c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1)
      end
      if fs.SetJustifyH then fs:SetJustifyH("LEFT") end
    end

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
      -- In edit mode, keep a stable hitbox width while leaving room for [up][down][X].
      if fs.SetWidth then fs:SetWidth(textW) end
    end
    fs:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -padTop - yCursor)

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

    if debugHitboxes then
      local tRow = EnsureDebugRect("row", i, 1, 0, 0, 0.12)
      if tRow and tRow.SetAllPoints then
        tRow:ClearAllPoints()
        tRow:SetAllPoints(btn)
        tRow:SetShown(editMode and e ~= nil)
      end

      local tX = EnsureDebugRect("x", i, 0, 1, 0, 0.18)
      if tX and tX.SetAllPoints then
        tX:ClearAllPoints()
        tX:SetAllPoints(rm)
        tX:SetShown(editMode and e ~= nil)
      end

      local tUp = EnsureDebugRect("up", i, 0, 0.65, 1, 0.18)
      if tUp and tUp.SetAllPoints and mvUp then
        tUp:ClearAllPoints()
        tUp:SetAllPoints(mvUp)
        tUp:SetShown(editMode and e ~= nil)
      end

      local tDown = EnsureDebugRect("down", i, 0, 0.65, 1, 0.18)
      if tDown and tDown.SetAllPoints and mvDown then
        tDown:ClearAllPoints()
        tDown:SetAllPoints(mvDown)
        tDown:SetShown(editMode and e ~= nil)
      end
    end

    if e then
      -- Darkmoon Faire styling (header + child entries)
      local isDMFHeader = false
      do
        local r = e.rule
        local grp = (type(r) == "table") and (r.group or r["group"]) or nil
        if grp == "event:darkmoon-faire" then
          local k = (type(r) == "table") and tostring(r.key or "") or ""
          if k == "event:darkmoon-faire" then
            isDMFHeader = true
            ApplyFontStyle(fs, { name = "lsm:Bazooka", size = 20, color = "6b21a8" })
            if fs.SetJustifyH then fs:SetJustifyH("CENTER") end
          else
            if fs.SetTextColor then fs:SetTextColor(0.72, 0.56, 0.90, 1) end
          end
        end
      end

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
      if isDMFHeader then
        fs:SetText(tostring(text or ""))
      else
        fs:SetText(" " .. text .. " ")
      end
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

  local function IsHiddenByCompletion(status)
    if not status then return false end
    if status.completed ~= true then return false end
    return status.hideWhenCompleted == true
  end

  for _, rule in ipairs(rules) do
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
        local btn = EnsureBarInspectButton(f)
        btn:SetShown(editMode and true or false)
      else
        RenderList(def, f, entries)
      end

      UpdateAnchorLabel(f, def)

      -- Auto-size (lists) and resolution/UI scale changes can leave frames off-screen.
      -- Nudge them back on-screen without altering their anchor corner.
      NudgeFrameOnScreen(f, 8)
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

local function AutoSellItemsAtMerchant()
  if InCombatLockdown and InCombatLockdown() then return end

  if not (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemID and C_Container.UseContainerItem) then
    return
  end

  local rules = GetEffectiveRules()
  if type(rules) ~= "table" or not rules[1] then return end

  local shouldSellByItemID = {}
  for _, rule in ipairs(rules) do
    if type(rule) == "table" and type(rule.rep) == "table" and rule.rep.sellWhenExalted == true and rule.rep.factionID then
      if not IsRuleDisabled(rule) then
        local sid = GetStandingIDByFactionID(rule.rep.factionID)
        if sid and sid >= 8 then
          local itemID
          if type(rule.item) == "table" and rule.item.itemID then
            itemID = tonumber(rule.item.itemID)
          elseif rule.itemID then
            itemID = tonumber(rule.itemID)
          end
          if itemID and itemID > 0 then
            shouldSellByItemID[itemID] = true
          end
        end
      end
    end
  end

  if not next(shouldSellByItemID) then return end

  local soldCountsByItemID = {}
  for bag = 0, 4 do
    local n = C_Container.GetContainerNumSlots(bag) or 0
    for slot = 1, n do
      local itemID = C_Container.GetContainerItemID(bag, slot)
      if itemID and shouldSellByItemID[itemID] then
        local info = C_Container.GetContainerItemInfo and C_Container.GetContainerItemInfo(bag, slot) or nil
        local locked = (type(info) == "table" and info.isLocked == true)
        local noValue = (type(info) == "table" and info.hasNoValue == true)
        if not locked and not noValue then
          C_Container.UseContainerItem(bag, slot)
          soldCountsByItemID[itemID] = (soldCountsByItemID[itemID] or 0) + 1
        end
      end
    end
  end

  if not next(soldCountsByItemID) then return end

  local parts = {}
  for itemID, count in pairs(soldCountsByItemID) do
    local name
    if C_Item and C_Item.GetItemNameByID then
      local ok, n = pcall(C_Item.GetItemNameByID, itemID)
      if ok and n and n ~= "" then
        name = n
      end
    end
    parts[#parts + 1] = tostring(count) .. "x " .. tostring(name or ("itemID:" .. tostring(itemID)))
  end
  table.sort(parts)
  Print("Sold (Exalted): " .. table.concat(parts, ", "))
end

local function AutoBuyItemsAtMerchant()
  if InCombatLockdown and InCombatLockdown() then return end

  NormalizeSV()
  local debugSetting = fr0z3nUI_QuestTracker_Acc
    and fr0z3nUI_QuestTracker_Acc.settings
    and fr0z3nUI_QuestTracker_Acc.settings.debugAutoBuy == true
  local debugShift = (type(IsShiftKeyDown) == "function") and (IsShiftKeyDown() == true) or false
  local debug = (debugSetting or debugShift) and true or false
  local function Debug(msg)
    if not debug then return end
    Print("AutoBuy: " .. tostring(msg))
  end

  -- Session-local tracking to prevent duplicate buys when merchant/bag data updates lag behind.
  frame._autoBuyBaselineHave = (type(frame._autoBuyBaselineHave) == "table") and frame._autoBuyBaselineHave or {}
  frame._autoBuySessionBought = (type(frame._autoBuySessionBought) == "table") and frame._autoBuySessionBought or {}

  local function IsMerchantSessionOpen()
    if frame and frame._merchantOpen == true then return true end
    local mf = rawget(_G, "MerchantFrame")
    if mf and mf.IsShown and mf:IsShown() then return true end
    return false
  end

  local function CanRetry()
    if not IsMerchantSessionOpen() then return false end
    local attempts = tonumber(frame and frame._autoBuyAttempts) or 0
    return attempts < 12
  end

  local function ScheduleRetry(delay, reason)
    if not (C_Timer and C_Timer.After) then return end
    if not CanRetry() then
      Debug("retry blocked (merchant closed or attempts exceeded)")
      return
    end
    if frame and frame._autoBuyRetryPending then
      return
    end
    if frame then
      frame._autoBuyRetryPending = true
      frame._autoBuyAttempts = (tonumber(frame._autoBuyAttempts) or 0) + 1
    end
    Debug("scheduled retry in " .. tostring(delay) .. "s" .. (reason and (" (" .. tostring(reason) .. ")") or ""))
    C_Timer.After(tonumber(delay) or 0.2, function()
      if frame then frame._autoBuyRetryPending = nil end
      if IsMerchantSessionOpen() then
        AutoBuyItemsAtMerchant()
      end
    end)
  end

  local function ResolveMerchantAPI()
    -- 1) Prefer C_MerchantFrame when present.
    local cmf = rawget(_G, "C_MerchantFrame")
    if type(cmf) == "table" and type(cmf.GetItemInfo) == "function" then
      local getNum = cmf.GetNumItems or cmf.GetNumMerchantItems
      if type(getNum) == "function" then
        return {
          kind = "C_MerchantFrame",
          getNum = function() return getNum() end,
          getInfo = function(index) return cmf.GetItemInfo(index) end,
        }
      end

      -- Some builds expose GetItemInfo but not a public GetNum*; probe until nil.
      return {
        kind = "C_MerchantFrame(probe)",
        getNum = function()
          local maxProbe = 200
          local count = 0
          local sawAny = false
          for i = 1, maxProbe do
            local ok, info = pcall(cmf.GetItemInfo, i)
            if ok and type(info) == "table" then
              sawAny = true
              count = i
            else
              if sawAny then
                break
              end
            end
          end
          return count
        end,
        getInfo = function(index) return cmf.GetItemInfo(index) end,
      }
    end

    -- 2) Legacy global functions (names vary across builds; try a small set).
    local getNumFn = rawget(_G, "GetMerchantNumItems") or rawget(_G, "GetNumMerchantItems")
    local getInfoFn = rawget(_G, "GetMerchantItemInfo")
    local getLinkFn = rawget(_G, "GetMerchantItemLink")
    if type(getNumFn) == "function" and type(getInfoFn) == "function" then
      return {
        kind = "legacy",
        getNum = function() return getNumFn() end,
        getInfo = function(index)
          local name, texture, price, quantity, numAvailable, isPurchasable, isUsable, extendedCost = getInfoFn(index)
          local link = (type(getLinkFn) == "function") and getLinkFn(index) or nil
          return {
            name = name,
            texture = texture,
            price = price,
            quantity = quantity,
            stackCount = quantity,
            numAvailable = numAvailable,
            isPurchasable = isPurchasable,
            isUsable = isUsable,
            extendedCost = extendedCost,
            hasExtendedCost = extendedCost,
            itemLink = link,
          }
        end,
      }
    end

    -- 3) Heuristic: scan globals for a Merchant* namespace with the right shape.
    -- This avoids hard-coding API names when Blizzard renames namespaces.
    local candidates
    for k, v in pairs(_G) do
      if type(k) == "string" and k:find("Merchant") and type(v) == "table" then
        local getInfo = v.GetItemInfo or v.GetMerchantItemInfo
        local getNum = v.GetNumItems or v.GetNumMerchantItems
        if type(getInfo) == "function" and type(getNum) == "function" then
          return {
            kind = k,
            getNum = function() return getNum() end,
            getInfo = function(index) return getInfo(index) end,
          }
        end
        if debug then
          candidates = candidates or {}
          if (v.GetItemInfo or v.GetMerchantItemInfo or v.GetNumItems or v.GetNumMerchantItems) then
            candidates[#candidates + 1] = k
          end
        end
      end
    end

    if debug and candidates and candidates[1] then
      table.sort(candidates)
      if #candidates > 25 then
        local trimmed = {}
        for i = 1, 25 do trimmed[i] = candidates[i] end
        candidates = trimmed
      end
      Debug("merchant namespace candidates: " .. table.concat(candidates, ", "))
    end

    return nil
  end

  local api = ResolveMerchantAPI()
  if not api then
    Debug("Merchant API missing (no supported namespace/functions found)")
    return
  end
  Debug("merchant api=" .. tostring(api.kind))

  local GetNumMerchantItems = api.getNum
  local GetMerchantItemInfoSafe = api.getInfo

  if not (C_Item and C_Item.GetItemCount) then
    Debug("C_Item.GetItemCount missing")
    return
  end

  -- Ensure default/custom rules have been migrated/normalized so `item.buy` is populated.
  if EnsureDefaultRulesMigrated then EnsureDefaultRulesMigrated() end
  if EnsureRulesNormalized then EnsureRulesNormalized() end

  local rules = GetEffectiveRules()
  if type(rules) ~= "table" or not rules[1] then
    Debug("no rules")
    return
  end

  Debug("rules=" .. tostring(#rules))

  -- Collapse enabled auto-buy rules.
  -- Supports:
  --   item.buy = { enabled=true, max=N } (legacy)
  --   item.buy = { enabled=true, min=A, target=B, max=C } (restock behavior)
  --   item.buy = { enabled=true, cheapestOf={...}, ... } (buy cheapest merchant variant)
  local wantByItemID = {}
  local wantCheapestGroups = {}

  local function MergeBuySpec(dst, src)
    if type(dst) ~= "table" then dst = {} end
    if type(src) ~= "table" then return dst end

    local function pickMax(a, b)
      a = tonumber(a) or 0
      b = tonumber(b) or 0
      return (b > a) and b or a
    end

    dst.max = pickMax(dst.max, src.max)
    dst.min = pickMax(dst.min, src.min)
    dst.target = pickMax(dst.target, src.target)

    -- Optional "bundle yield" semantics:
    -- When set, min/target/max are interpreted in terms of yieldItemID count, and
    -- each purchased item contributes yieldCount toward that total.
    local yieldItemID = tonumber(src.yieldItemID)
    local yieldCount = tonumber(src.yieldCount)
    if yieldItemID and yieldItemID > 0 then
      dst.yieldItemID = yieldItemID
      dst.yieldCount = (yieldCount and yieldCount > 0) and yieldCount or (tonumber(dst.yieldCount) or 1)
      if dst.yieldCount <= 0 then dst.yieldCount = 1 end
    end
    return dst
  end

  local function NormalizeIDList(t)
    local tmp = {}
    if type(t) == "table" then
      for _, v in pairs(t) do
        local id = tonumber(v)
        if id and id > 0 then
          tmp[#tmp + 1] = id
        end
      end
    end
    if not tmp[1] then return nil end
    table.sort(tmp)
    local out = {}
    local last
    for i = 1, #tmp do
      local id = tmp[i]
      if id ~= last then
        out[#out + 1] = id
        last = id
      end
    end
    return out
  end

  for _, rule in ipairs(rules) do
    if type(rule) == "table" and not IsRuleDisabled(rule) then
      -- Standard item auto-buy rules.
      if type(rule.item) == "table" then
        local buy = rule.item.buy
        if type(buy) == "table" and buy.enabled == true then
          local itemID = tonumber(rule.item.itemID)
          local maxQty = tonumber(buy.max) or 0
          local minQty = tonumber(buy.min) or 0
          local targetQty = tonumber(buy.target) or 0

          local yieldItemID = tonumber(buy.yieldItemID)
          local yieldCount = tonumber(buy.yieldCount)

          if itemID and itemID > 0 and maxQty and maxQty > 0 then
            local spec = { max = maxQty, min = minQty, target = targetQty, yieldItemID = yieldItemID, yieldCount = yieldCount }

            local cheapestIDs = NormalizeIDList(buy.cheapestOf)
            if cheapestIDs and cheapestIDs[1] then
              -- Ensure the primary itemID is included.
              cheapestIDs[#cheapestIDs + 1] = itemID
              cheapestIDs = NormalizeIDList(cheapestIDs)
              local key = table.concat(cheapestIDs, ",")
              wantCheapestGroups[key] = wantCheapestGroups[key] or { ids = cheapestIDs, max = 0, min = 0, target = 0 }
              MergeBuySpec(wantCheapestGroups[key], spec)
            else
              wantByItemID[itemID] = MergeBuySpec(wantByItemID[itemID], spec)
            end
          end
        end
      end

      -- Quest shopping-list auto-buy (vendor mats), only while quest is incomplete and gates pass.
      if rule.autoBuyShopping == true and type(rule.shopping) == "table" and rule.shopping[1] ~= nil and rule.questID ~= nil then
        local status = BuildRuleStatus(rule, nil, { forceNormalVisibility = true })
        if status and status.completed ~= true then
          for _, it in ipairs(rule.shopping) do
            if type(it) == "table" and it.buy == true then
              local itemID = tonumber(it.itemID or it.id)
              local req = tonumber(it.required or it.count or it.need)
              if itemID and itemID > 0 and req and req > 0 then
                wantByItemID[itemID] = MergeBuySpec(wantByItemID[itemID], { max = req, target = req, min = 0 })
              end
            end
          end
        end
      end
    end
  end

  if not (next(wantByItemID) or next(wantCheapestGroups)) then return end

  do
    local sample = {}
    for id, spec in pairs(wantByItemID) do
      sample[#sample + 1] = tostring(id) .. "->" .. tostring(spec and spec.max or 0)
      if #sample >= 8 then break end
    end
    table.sort(sample)
    Debug("wantByItemID sample=" .. table.concat(sample, ", "))
    if next(wantCheapestGroups) then
      local gSample = {}
      for k, g in pairs(wantCheapestGroups) do
        gSample[#gSample + 1] = string.format("[%s] max=%s", tostring(k), tostring(g and g.max or 0))
        if #gSample >= 2 then break end
      end
      table.sort(gSample)
      Debug("wantCheapestGroups=" .. tostring(#gSample) .. " sample=" .. table.concat(gSample, " | "))
    end
  end

  local function GetItemIDFromMerchantInfo(info, merchantIndex)
    if type(info) ~= "table" then return nil end

    local function ItemIDFromLink(link)
      if type(link) ~= "string" or link == "" then return nil end
      if C_Item and C_Item.GetItemInfoInstant then
        local ok, iid = pcall(function()
          return select(1, C_Item.GetItemInfoInstant(link))
        end)
        iid = ok and tonumber(iid) or nil
        if iid and iid > 0 then return iid end
      end
      local iid = tonumber((tostring(link):match("item:(%d+)") or ""))
      if iid and iid > 0 then return iid end
      return nil
    end

    local itemID = tonumber(info["itemID"] or info["itemId"] or info["itemid"]) 
    if itemID and itemID > 0 then return itemID end

    local link = info["itemLink"] or info["link"] or info["hyperlink"]
    if type(link) == "string" and link ~= "" then
      local iid = ItemIDFromLink(link)
      if iid and iid > 0 then return iid end
      if C_Item and C_Item.GetItemIDForItemInfo then
        local ok, iid = pcall(C_Item.GetItemIDForItemInfo, link)
        iid = ok and tonumber(iid) or nil
        if iid and iid > 0 then return iid end
      end
    end

    if type(GetMerchantItemLink) == "function" and merchantIndex then
      local ok, l2 = pcall(GetMerchantItemLink, merchantIndex)
      local iid = ok and ItemIDFromLink(l2) or nil
      if iid and iid > 0 then return iid end
    end

    return nil
  end

  -- Build merchant lookup by itemID once.
  local okN, n = pcall(GetNumMerchantItems)
  n = (okN and tonumber(n)) or 0
  if n <= 0 then
    Debug("merchant has 0 items")
    return
  end

  Debug("merchant items=" .. tostring(n))

  local merchantIndexByItemID = {}
  local merchantInfoByIndex = {}
  local missingItemID = 0
  for i = 1, n do
    local okInfo, info = pcall(GetMerchantItemInfoSafe, i)
    if okInfo and type(info) == "table" then
      if debug and i == 1 and not frame._didDumpMerchantInfoKeys then
        frame._didDumpMerchantInfoKeys = true
        local keys = {}
        for k in pairs(info) do
          keys[#keys + 1] = tostring(k)
        end
        table.sort(keys)
        if #keys > 40 then
          local trimmed = {}
          for j = 1, 40 do trimmed[j] = keys[j] end
          keys = trimmed
        end
        Debug("merchantInfo keys (index=1): " .. table.concat(keys, ", "))
      end

      local itemID = GetItemIDFromMerchantInfo(info, i)
      if itemID and itemID > 0 then
        do
          local prev = merchantIndexByItemID[itemID]
          if not prev then
            merchantIndexByItemID[itemID] = i
          else
            local prevInfo = merchantInfoByIndex[prev]
            local prevPrice = (type(prevInfo) == "table") and (tonumber(prevInfo["price"]) or 0) or 0
            local newPrice = tonumber(info["price"]) or 0
            if newPrice < prevPrice then
              merchantIndexByItemID[itemID] = i
            end
          end
        end
        merchantInfoByIndex[i] = info
      else
        missingItemID = missingItemID + 1
      end
    end
  end

  if not next(merchantIndexByItemID) then
    Debug("merchant itemID map empty; missingItemID=" .. tostring(missingItemID))
    -- Some clients populate merchant item links/IDs a tick after MERCHANT_SHOW.
    ScheduleRetry(0.25, "itemID map empty")
    return
  end

  -- If we have wants but the merchant map is missing some of them, retry shortly.
  do
    local missingWants = 0
    for itemID in pairs(wantByItemID) do
      if not merchantIndexByItemID[itemID] then
        missingWants = missingWants + 1
        if missingWants >= 3 then break end
      end
    end
    if missingWants > 0 then
      Debug("merchant missing " .. tostring(missingWants) .. " wanted itemIDs; will retry")
      ScheduleRetry(0.25, "wanted itemID not mapped")
    end
  end

  do
    local wantDarnassus = wantByItemID[45579]
    if wantDarnassus then
      Debug("want itemID 45579 max=" .. tostring(wantDarnassus.max) .. "; merchantIndex=" .. tostring(merchantIndexByItemID[45579]))
    end
  end

  local boughtCountsByItemID = {}

  local function CanBuyFromMerchantInfo(info)
    if type(info) ~= "table" then return false end
    local isPurchasable = (info["isPurchasable"] ~= false)
    local extendedCost = (info["extendedCost"] == true) or (info["hasExtendedCost"] == true)
    return (isPurchasable and not extendedCost) and true or false
  end

  local function GetRawHaveCount(itemID)
    local have = 0
    local okCount, c = pcall(C_Item.GetItemCount, itemID, false, false, false)
    have = (okCount and tonumber(c)) or 0
    if have < 0 then have = 0 end
    return have
  end

  local function GetHaveCount(itemID)
    itemID = tonumber(itemID)
    if not itemID or itemID <= 0 then return 0 end

    local raw = GetRawHaveCount(itemID)

    local base = frame._autoBuyBaselineHave[itemID]
    if base == nil then
      base = raw
      frame._autoBuyBaselineHave[itemID] = base
    end

    local bought = tonumber(frame._autoBuySessionBought[itemID]) or 0
    local expected = (tonumber(base) or 0) + bought

    local have = raw
    if expected > have then
      have = expected
    end
    return have
  end

  local function GetEffectiveHaveForSpec(spec, itemIDs)
    if type(spec) ~= "table" then return 0 end
    if type(itemIDs) ~= "table" or not itemIDs[1] then
      local itemID = tonumber(spec.itemID)
      return (itemID and itemID > 0) and GetHaveCount(itemID) or 0
    end

    local yieldItemID = tonumber(spec.yieldItemID)
    local yieldCount = tonumber(spec.yieldCount) or 1
    if yieldCount <= 0 then yieldCount = 1 end

    if yieldItemID and yieldItemID > 0 then
      local haveYield = GetHaveCount(yieldItemID)
      local haveContainers = 0
      for i = 1, #itemIDs do
        local id = tonumber(itemIDs[i])
        if id and id > 0 and id ~= yieldItemID then
          haveContainers = haveContainers + GetHaveCount(id)
        end
      end
      return haveYield + (haveContainers * yieldCount)
    end

    local haveTotal = 0
    for i = 1, #itemIDs do
      haveTotal = haveTotal + GetHaveCount(itemIDs[i])
    end
    return haveTotal
  end

  local function ComputeNeed(spec, have)
    if type(spec) ~= "table" then return 0 end
    local maxQty = tonumber(spec.max) or 0
    local minQty = tonumber(spec.min) or 0
    local targetQty = tonumber(spec.target) or 0
    if maxQty <= 0 then return 0 end
    if have < 0 then have = 0 end

    -- Restock semantics:
    -- - max is always a hard cap
    -- - if target is set, restock up to target whenever below target
    -- - else if min is set, restock up to min whenever below min
    local desired = (targetQty > 0) and targetQty or ((minQty > 0) and minQty or maxQty)
    if desired > maxQty then desired = maxQty end
    local need = desired - have
    if need < 0 then need = 0 end
    return need
  end

  local function BuyFromMerchant(merchantIndex, info, itemID, need)
    itemID = tonumber(itemID)
    if not itemID or itemID <= 0 then return end
    if need <= 0 then return end
    if not (merchantIndex and info) then return end

    local bundleQty = tonumber(info["stackCount"] or info["quantity"]) or 1
    if bundleQty <= 0 then bundleQty = 1 end

    local purchases = math.floor((need + bundleQty - 1) / bundleQty)
    local numAvailable = tonumber(info["numAvailable"])
    if numAvailable and numAvailable >= 0 then
      purchases = math.min(purchases, numAvailable)
    end

    local price = tonumber(info["price"]) or 0
    if price > 0 and type(GetMoney) == "function" then
      local money = tonumber(GetMoney()) or 0
      purchases = math.min(purchases, math.floor(money / price))
    end

    if purchases and purchases > 0 then
      local remaining = purchases
      while remaining > 0 do
        local chunk = math.min(remaining, 100)
        BuyMerchantItem(merchantIndex, chunk)
        remaining = remaining - chunk
      end
      local got = (purchases * bundleQty)
      boughtCountsByItemID[itemID] = (boughtCountsByItemID[itemID] or 0) + got
      frame._autoBuySessionBought[itemID] = (tonumber(frame._autoBuySessionBought[itemID]) or 0) + got
    end
  end

  -- 1) Cheapest-variant groups
  for _, g in pairs(wantCheapestGroups) do
    if type(g) == "table" and type(g.ids) == "table" and g.ids[1] then
      local chosenItemID
      local chosenIndex
      local chosenInfo
      local chosenPrice

      for i = 1, #g.ids do
        local id = g.ids[i]
        local idx = merchantIndexByItemID[id]
        if idx then
          local info = merchantInfoByIndex[idx]
          if CanBuyFromMerchantInfo(info) then
            local price = tonumber(info["price"]) or 0
            if (chosenItemID == nil) or (price < (chosenPrice or 0)) or (price == (chosenPrice or 0) and id < chosenItemID) then
              chosenItemID = id
              chosenIndex = idx
              chosenInfo = info
              chosenPrice = price
            end
          end
        end
      end

      if chosenItemID and chosenIndex and chosenInfo then
        local haveTotal = GetEffectiveHaveForSpec(g, g.ids)
        local need = ComputeNeed(g, haveTotal)
        if need > 0 then
          local yieldItemID = tonumber(g.yieldItemID)
          local yieldCount = tonumber(g.yieldCount) or 1
          if yieldCount <= 0 then yieldCount = 1 end

          if yieldItemID and yieldItemID > 0 then
            local maxQty = tonumber(g.max) or 0
            local capacity = maxQty - haveTotal
            if capacity < yieldCount then
              need = 0
            else
              local purchasesNeeded = math.floor((need + yieldCount - 1) / yieldCount)
              local maxPurchases = math.floor(capacity / yieldCount)
              need = math.min(purchasesNeeded, maxPurchases)
            end
          end

          if need > 0 then
            Debug(string.format("cheapestOf: chose itemID=%d price=%s need=%d", chosenItemID, tostring(chosenPrice), need))
            BuyFromMerchant(chosenIndex, chosenInfo, chosenItemID, need)
          end
        end
      end
    end
  end

  -- 2) Direct itemIDs
  for itemID, spec in pairs(wantByItemID) do
    local merchantIndex = merchantIndexByItemID[itemID]
    if merchantIndex then
      local info = merchantInfoByIndex[merchantIndex]
      if CanBuyFromMerchantInfo(info) then
        local have = GetHaveCount(itemID)
        local need = ComputeNeed(spec, have)

        local yieldItemID = tonumber(spec.yieldItemID)
        local yieldCount = tonumber(spec.yieldCount) or 1
        if yieldCount <= 0 then yieldCount = 1 end
        if yieldItemID and yieldItemID > 0 then
          local maxQty = tonumber(spec.max) or 0
          local capacity = maxQty - have
          if capacity < yieldCount then
            need = 0
          else
            local purchasesNeeded = math.floor((need + yieldCount - 1) / yieldCount)
            local maxPurchases = math.floor(capacity / yieldCount)
            need = math.min(purchasesNeeded, maxPurchases)
          end
        end

        if need > 0 then
          BuyFromMerchant(merchantIndex, info, itemID, need)
        end
      end
    end
  end

  if not next(boughtCountsByItemID) then return end

  -- Merchant data / bag counts can update after purchases; rerun once more shortly
  -- to catch delayed itemIDs or additional wants (prevents needing to reopen vendor).
  ScheduleRetry(0.25, "post-purchase refresh")

  local parts = {}
  for itemID, count in pairs(boughtCountsByItemID) do
    local name
    if C_Item and C_Item.GetItemNameByID then
      local ok, n2 = pcall(C_Item.GetItemNameByID, itemID)
      if ok and n2 and n2 ~= "" then
        name = n2
      end
    end
    parts[#parts + 1] = tostring(count) .. "x " .. tostring(name or ("itemID:" .. tostring(itemID)))
  end
  table.sort(parts)
  Print("Bought (Auto): " .. table.concat(parts, ", "))
end

-- Events
frame = CreateFrame("Frame")

local function SafeRegisterEvent(f, event)
  if not f or not event then return end
  pcall(f.RegisterEvent, f, event)
end

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("QUEST_LOG_UPDATE")
frame:RegisterEvent("QUEST_ACCEPTED")
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

frame:SetScript("OnEvent", function(_, event, ...)
  if event == "MERCHANT_SHOW" then
    frame._didDumpMerchantInfoKeys = nil
    frame._merchantOpen = true
    frame._autoBuyRetryPending = nil
    frame._autoBuyAttempts = 0
    frame._autoBuyBaselineHave = {}
    frame._autoBuySessionBought = {}
    -- Sell items flagged with rep.sellWhenExalted once the merchant opens.
    AutoSellItemsAtMerchant()
    AutoBuyItemsAtMerchant()
    return
  end
  if event == "MERCHANT_CLOSED" then
    frame._merchantOpen = nil
    frame._autoBuyRetryPending = nil
    frame._autoBuyAttempts = nil
    frame._autoBuyBaselineHave = nil
    frame._autoBuySessionBought = nil
    if frame._autoBuyUpdateTimer then
      frame._autoBuyUpdateTimer:Cancel()
      frame._autoBuyUpdateTimer = nil
    end
    return
  end
  if event == "MERCHANT_UPDATE" then
    if InCombatLockdown and InCombatLockdown() then return end
    if frame._autoBuyUpdateTimer then return end
    if not (C_Timer and C_Timer.NewTimer) then return end
    frame._autoBuyUpdateTimer = C_Timer.NewTimer(0.15, function()
      frame._autoBuyUpdateTimer = nil
      if frame._merchantOpen == true then
        AutoBuyItemsAtMerchant()
      end
    end)
    return
  end
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
    MaybeAutoResetEventsOncePerDay()
    RequestWarbandCurrencyData()
    C_Timer.After(2.0, RefreshWarbandCurrencyCacheForAllKnownCurrencies)
    CreateAllFrames()
    C_Timer.After(1.0, RefreshAll)
    frame._didPostWorldWarm = false
    Print("Loaded. Type /fqt to configure.")
    return
  end

  if event == "CURRENCY_DISPLAY_UPDATE" then
    local currencyID = tonumber((...))
    if currencyID and currencyID > 0 then
      _warbandCurrencyTotals[currencyID] = nil
    end
    RequestWarbandCurrencyData()
    if frame._wbCurrencyRefreshTimer then
      frame._wbCurrencyRefreshTimer:Cancel()
    end
    frame._wbCurrencyRefreshTimer = C_Timer.NewTimer(1.0, RefreshWarbandCurrencyCacheForAllKnownCurrencies)
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

-- /fqt rgb helper (standalone window to generate copyable colors)
local rgbPickerFrame

local function Clamp01(v)
  v = tonumber(v)
  if v == nil then return 0 end
  if v < 0 then return 0 end
  if v > 1 then return 1 end
  return v
end

local function FormatLuaRGB(r, g, b)
  return string.format("{ %.3f, %.3f, %.3f }", Clamp01(r), Clamp01(g), Clamp01(b))
end

local function OpenColorPicker(r, g, b, onChanged)
  r, g, b = Clamp01(r), Clamp01(g), Clamp01(b)
  if not ColorPickerFrame then
    if type(onChanged) == "function" then onChanged(r, g, b) end
    return
  end

  -- Dragonflight+ API
  if ColorPickerFrame.SetupColorPickerAndShow then
    local info = {
      swatchFunc = function()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        if type(onChanged) == "function" then onChanged(nr, ng, nb) end
      end,
      cancelFunc = function(prev)
        if type(prev) == "table" and prev.r and prev.g and prev.b then
          if type(onChanged) == "function" then onChanged(prev.r, prev.g, prev.b) end
        end
      end,
      r = r,
      g = g,
      b = b,
      hasOpacity = false,
    }
    ColorPickerFrame:SetupColorPickerAndShow(info)
    return
  end

  -- Legacy API
  ColorPickerFrame.func = function()
    local nr, ng, nb = ColorPickerFrame:GetColorRGB()
    if type(onChanged) == "function" then onChanged(nr, ng, nb) end
  end
  ColorPickerFrame.cancelFunc = function(prev)
    if type(prev) == "table" and prev.r and prev.g and prev.b then
      if type(onChanged) == "function" then onChanged(prev.r, prev.g, prev.b) end
    end
  end
  ColorPickerFrame.hasOpacity = false
  ColorPickerFrame.previousValues = { r = r, g = g, b = b }
  ColorPickerFrame:SetColorRGB(r, g, b)
  ColorPickerFrame:Show()
end

local function EnsureRGBPickerFrame()
  if rgbPickerFrame then return rgbPickerFrame end

  local f = CreateFrame("Frame", "FR0Z3NUIFQTRGBPicker", UIParent, "BackdropTemplate")
  f:SetSize(420, 170)
  f:SetPoint("CENTER")
  f:SetFrameStrata("DIALOG")
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:EnableMouse(true)
  RestoreWindowPosition("rgbPicker", f, "CENTER", "CENTER", 0, 0)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", function(self)
    if self.StopMovingOrSizing then self:StopMovingOrSizing() end
    SaveWindowPosition("rgbPicker", self)
  end)
  ApplyFAOBackdrop(f, 0.90)

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", 12, -10)
  title:SetText("|cff00ccff[FQT]|r RGB Picker")

  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", f, "TOPRIGHT", 2, 2)

  local swatch = CreateFrame("Button", nil, f, "BackdropTemplate")
  swatch:SetSize(28, 28)
  swatch:SetPoint("TOPLEFT", 14, -36)
  swatch:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
  })
  swatch:SetBackdropColor(1, 1, 1, 1)

  local function CreateSmallBox(parent, labelText)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetText(labelText)
    local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    eb:SetSize(52, 18)
    eb:SetAutoFocus(false)
    eb:SetJustifyH("CENTER")
    return lbl, eb
  end

  local lr, er = CreateSmallBox(f, "R (0-255)")
  local lg, eg = CreateSmallBox(f, "G")
  local lb, eb = CreateSmallBox(f, "B")

  lr:SetPoint("TOPLEFT", swatch, "TOPRIGHT", 14, 6)
  er:SetPoint("TOPLEFT", lr, "BOTTOMLEFT", -6, -2)

  lg:SetPoint("LEFT", lr, "RIGHT", 70, 0)
  eg:SetPoint("TOPLEFT", lg, "BOTTOMLEFT", -6, -2)

  lb:SetPoint("LEFT", lg, "RIGHT", 70, 0)
  eb:SetPoint("TOPLEFT", lb, "BOTTOMLEFT", -6, -2)

  local outLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  outLbl:SetPoint("TOPLEFT", swatch, "BOTTOMLEFT", 0, -16)
  outLbl:SetText("Output (copy into rule):")

  local out = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
  out:SetSize(390, 20)
  out:SetPoint("TOPLEFT", outLbl, "BOTTOMLEFT", -6, -2)
  out:SetAutoFocus(false)
  out:SetJustifyH("LEFT")

  local out2 = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
  out2:SetSize(390, 20)
  out2:SetPoint("TOPLEFT", out, "BOTTOMLEFT", 0, -6)
  out2:SetAutoFocus(false)
  out2:SetJustifyH("LEFT")

  local help = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  help:SetPoint("TOPLEFT", out2, "BOTTOMLEFT", 6, -8)
  help:SetText("Use as: color = { r, g, b }   (or paste hex)")

  local function GetRGB255()
    local r = tonumber(er:GetText() or "") or 255
    local g = tonumber(eg:GetText() or "") or 255
    local b = tonumber(eb:GetText() or "") or 255
    if r < 0 then r = 0 elseif r > 255 then r = 255 end
    if g < 0 then g = 0 elseif g > 255 then g = 255 end
    if b < 0 then b = 0 elseif b > 255 then b = 255 end
    return r, g, b
  end

  local function SetRGB255(r, g, b)
    r = tonumber(r) or 255
    g = tonumber(g) or 255
    b = tonumber(b) or 255
    if r < 0 then r = 0 elseif r > 255 then r = 255 end
    if g < 0 then g = 0 elseif g > 255 then g = 255 end
    if b < 0 then b = 0 elseif b > 255 then b = 255 end
    er:SetText(tostring(math.floor(r + 0.5)))
    eg:SetText(tostring(math.floor(g + 0.5)))
    eb:SetText(tostring(math.floor(b + 0.5)))
  end

  local function RefreshOutput()
    local r, g, b = GetRGB255()
    swatch:SetBackdropColor(r / 255, g / 255, b / 255, 1)
    local rr, gg, bb = r / 255, g / 255, b / 255
    local hex = ColorHex(rr, gg, bb)
    out:SetText("color = " .. FormatLuaRGB(rr, gg, bb))
    out2:SetText("color = \"#" .. hex .. "\"")
  end

  local function OnAnyChanged()
    RefreshOutput()
  end

  er:SetScript("OnTextChanged", OnAnyChanged)
  eg:SetScript("OnTextChanged", OnAnyChanged)
  eb:SetScript("OnTextChanged", OnAnyChanged)

  swatch:SetScript("OnClick", function()
    local r, g, b = GetRGB255()
    OpenColorPicker(r / 255, g / 255, b / 255, function(nr, ng, nb)
      SetRGB255(nr * 255, ng * 255, nb * 255)
      RefreshOutput()
    end)
  end)

  SetRGB255(255, 255, 255)
  RefreshOutput()

  rgbPickerFrame = f
  return f
end

local function ShowRGBPicker()
  local f = EnsureRGBPickerFrame()
  f:Show()
  if f.Raise then f:Raise() end
end

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

  if cmd == "rgb" then
    ShowRGBPicker()
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

  if cmd == "evdebug" then
    Print("Event debug:")
    EnsureCalendarOpened()

    local events, meta = GetCalendarDebugEvents(0, 0)
    if type(meta) == "table" and meta.ok == false then
      Print("Calendar debug unavailable: " .. tostring(meta.reason or "unknown"))
    else
      if type(events) ~= "table" or events[1] == nil then
        Print("Today: no calendar day-events returned.")
      else
        for _, ev in ipairs(events) do
          local title = tostring(ev.title or "")
          local ht = tostring(ev.holidayText or "")
          if ht ~= "" then
            ht = ht:gsub("\n", " ")
            if #ht > 140 then ht = ht:sub(1, 140) .. "..." end
          end
          Print(string.format("Day %s: %s", tostring(ev.day or "?"), title ~= "" and title or "(no title)"))
          if ht ~= "" then
            Print("  Holiday: " .. ht)
          end
        end
      end
    end

    do
      local found, unknown = IsCalendarEventActiveByKeywords({ "Darkmoon Faire" }, true)
      Print("DMF keyword match today: " .. tostring(found and true or false) .. "; calendarUnknown=" .. tostring(unknown and true or false))

      NormalizeSV()
      local disabled = fr0z3nUI_QuestTracker_Char
        and fr0z3nUI_QuestTracker_Char.settings
        and fr0z3nUI_QuestTracker_Char.settings.disabledRules
        and fr0z3nUI_QuestTracker_Char.settings.disabledRules["event:darkmoon-faire"]
      Print("DMF title rule disabledRules['event:darkmoon-faire']=" .. tostring(disabled and true or false))

      local ck = CalendarKeywordCacheKey({ "Darkmoon Faire" })
      if ck and ck ~= "" then
        local rememberedKey = "event:calendar:" .. ck
        Print("DMF remembered daily aura state: " .. tostring(HasRememberedDailyAura(rememberedKey) and true or false))
      end
    end

    return
  end

  if cmd == "framedebug" then
    NormalizeSV()
    local frameID = tostring(rest or "")
    frameID = frameID:gsub("^%s+", ""):gsub("%s+$", "")
    if frameID == "" then frameID = "list2" end

    Print("Frame debug: " .. frameID)
    Print("framesEnabled=" .. tostring(framesEnabled and true or false) .. "; editMode=" .. tostring(editMode and true or false))

    local def
    local defs = GetEffectiveFrames and GetEffectiveFrames() or nil
    if type(defs) == "table" then
      for _, d in ipairs(defs) do
        if tostring(d and d.id or "") == frameID then
          def = d
          break
        end
      end
    end

    if not def then
      Print("No effective frame def for id='" .. frameID .. "'.")
    else
      Print(string.format(
        "type=%s hideFrame=%s hideWhenEmpty=%s parentFrame=%s visLink=%s",
        tostring(def.type or "list"),
        tostring(def.hideFrame == true),
        tostring(def.hideWhenEmpty ~= false),
        tostring(def.parentFrame or ""),
        tostring(def.visLink or "")
      ))
    end

    local f = framesByID and framesByID[frameID] or nil
    if not f then
      Print("Frame object not created (framesByID['" .. frameID .. "']=nil).")
      if CreateAllFrames then
        CreateAllFrames()
        f = framesByID and framesByID[frameID] or nil
        Print("CreateAllFrames() attempted; frame now " .. (f and "exists" or "missing") .. ".")
      end
    end

    if f then
      local shown = (f.IsShown and f:IsShown()) and true or false
      Print("IsShown=" .. tostring(shown))

      local scrollOffset = (GetFrameScrollOffset and GetFrameScrollOffset(frameID)) or 0
      Print("scrollOffset=" .. tostring(scrollOffset))

      local entries = f._lastEntries or {}
      local allEntries = f._lastAllEntries or nil
      Print("entries=" .. tostring(type(entries) == "table" and #entries or 0) .. "; allEntries=" .. tostring(type(allEntries) == "table" and #allEntries or "(nil)"))

      local maxDump = 12
      for i = 1, math.min(maxDump, (type(entries) == "table" and #entries or 0)) do
        local e = entries[i]
        local r = e and e.rule
        local k = (RuleKey and r) and RuleKey(r) or (type(r) == "table" and r.key) or nil
        local title = (e and (e.rawTitle or e.title or e.editText)) or ""
        if type(title) == "string" then
          title = title:gsub("\n", " ")
          if #title > 120 then title = title:sub(1, 120) .. "..." end
        end
        Print(string.format("%d) %s  key=%s", i, tostring(title), tostring(k or "")))
      end

      -- Dump actual rendered row texts (what the user should be seeing on screen).
      if type(f.items) == "table" then
        local maxRows = 12
        for i = 1, maxRows do
          local fs = f.items[i]
          if fs and fs.GetText then
            local t = fs:GetText() or ""
            if type(t) == "string" then
              t = t:gsub("\n", " ")
              if #t > 120 then t = t:sub(1, 120) .. "..." end
            end
            local fsShown = (fs.IsShown and fs:IsShown()) and true or false
            Print(string.format("rowFS %d shown=%s text=%s", i, tostring(fsShown), tostring(t)))
          end
        end
      end
    end

    return
  end

  if cmd == "ruledebug" then
    NormalizeSV()
    local key = tostring(rest or "")
    key = key:gsub("^%s+", ""):gsub("%s+$", "")
    if key == "" then
      Print("Usage: /fqt ruledebug <ruleKey>")
      return
    end

    local rules = GetEffectiveRules and GetEffectiveRules() or nil
    local found
    if type(rules) == "table" then
      for _, r in ipairs(rules) do
        if type(r) == "table" then
          local rk = RuleKey and RuleKey(r) or r.key
          if tostring(rk or "") == key then
            found = r
            break
          end
        end
      end
    end

    if not found then
      Print("Rule not found for key='" .. key .. "'.")
      return
    end

    local status = BuildRuleStatus(found, BuildEvalContext(), { forceNormalVisibility = true })
    if not status then
      Print("BuildRuleStatus: nil (gated/disabled/prereq/etc)")
      if found.professionSkillLineID ~= nil then
        Print("  professionSkillLineID=" .. tostring(found.professionSkillLineID) .. "; has=" .. tostring(HasProfessionSkillLineID(found.professionSkillLineID)))
      end
      return
    end

    Print("Rule debug key='" .. key .. "':")
    Print("  completed=" .. tostring(status.completed and true or false) .. "; hideWhenCompleted=" .. tostring(status.hideWhenCompleted and true or false))
    Print("  title=" .. tostring((status.rawTitle or status.title) or ""))
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

  if cmd == "debug" then
    NormalizeSV()
    local sub, rest2 = rest:match("^(%S+)%s*(.-)$")
    sub = tostring(sub or ""):lower()
    rest2 = tostring(rest2 or ""):lower()
    if sub == "autobuy" or sub == "buy" then
      local v
      if rest2 == "on" or rest2 == "1" or rest2 == "true" then
        v = true
      elseif rest2 == "off" or rest2 == "0" or rest2 == "false" then
        v = false
      else
        v = not (fr0z3nUI_QuestTracker_Acc.settings.debugAutoBuy == true)
      end
      fr0z3nUI_QuestTracker_Acc.settings.debugAutoBuy = (v == true)
      Print("AutoBuy debug: " .. (fr0z3nUI_QuestTracker_Acc.settings.debugAutoBuy and "ON" or "OFF"))
      return
    end

    if sub == "hitboxes" or sub == "hitbox" or sub == "hb" then
      local v
      if rest2 == "on" or rest2 == "1" or rest2 == "true" then
        v = true
      elseif rest2 == "off" or rest2 == "0" or rest2 == "false" then
        v = false
      else
        v = not ((type(GetUISetting) == "function") and (GetUISetting("debugHitboxes", false) == true))
      end
      if type(SetUISetting) == "function" then
        SetUISetting("debugHitboxes", v == true)
      end
      RefreshAll()
      Print("Hitbox debug: " .. (((type(GetUISetting) == "function") and (GetUISetting("debugHitboxes", false) == true)) and "ON" or "OFF"))
      return
    end

    Print("Usage: /fqt debug autobuy [on|off] | hitboxes [on|off]")
    return
  end

  Print("Commands: /fqt (options), /fqt on, /fqt off, /fqt reset, /fqt rgb, /fqt debug autobuy [on|off], /fqt debug hitboxes [on|off], /fqt twdebug, /fqt twclear, /fqt evdebug, /fqt framedebug [frameID], /fqt ruledebug <ruleKey>, /fqt evclear")
  end)
end
