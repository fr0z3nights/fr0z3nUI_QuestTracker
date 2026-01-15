local addonName, ns = ...

local PREFIX = "|cff00ccff[FQT]|r "
local function Print(msg)
  print(PREFIX .. tostring(msg or ""))
end

local framesEnabled = true
local editMode = false

local function NormalizeSV()
  fr0z3nUI_QuestTracker_Acc = fr0z3nUI_QuestTracker_Acc or {}
  fr0z3nUI_QuestTracker_Char = fr0z3nUI_QuestTracker_Char or {}

  fr0z3nUI_QuestTracker_Acc.settings = fr0z3nUI_QuestTracker_Acc.settings or {}
  fr0z3nUI_QuestTracker_Char.settings = fr0z3nUI_QuestTracker_Char.settings or {}

  fr0z3nUI_QuestTracker_Char.settings.disabledRules = fr0z3nUI_QuestTracker_Char.settings.disabledRules or {}

  fr0z3nUI_QuestTracker_Acc.cache = fr0z3nUI_QuestTracker_Acc.cache or {}
  fr0z3nUI_QuestTracker_Acc.cache.weeklyAuras = fr0z3nUI_QuestTracker_Acc.cache.weeklyAuras or {}
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
    return string.format("%d/%d", fulfilled, required)
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

local function GetPlayerFaction()
  if UnitFactionGroup then
    local f = UnitFactionGroup("player")
    return f
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
  if not spellID then return end
  NormalizeSV()
  local resetAt = GetWeeklyResetAt()
  if resetAt and resetAt > 0 then
    fr0z3nUI_QuestTracker_Acc.cache.weeklyAuras[tostring(spellID)] = resetAt
  end
end

local function HasRememberedWeeklyAura(spellID)
  if not spellID then return false end
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

local function GetIndicatorGlyph(shape)
  shape = tostring(shape or "square"):lower()
  if shape == "circle" then
    return "●"
  end
  return "■"
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
      local done = false
      if type(ind.questIDs) == "table" then
        for _, q in ipairs(ind.questIDs) do
          if IsQuestCompleted(tonumber(q)) then
            done = true
            break
          end
        end
      elseif ind.questID then
        done = IsQuestCompleted(tonumber(ind.questID))
      elseif ind.itemID then
        local need = tonumber(ind.count) or tonumber(ind.required) or 1
        done = GetItemCountSafe(tonumber(ind.itemID)) >= need
      elseif type(ind.aura) == "table" and ind.aura.spellID then
        done = HasAuraSpellID(tonumber(ind.aura.spellID))
      end

      local glyph = GetIndicatorGlyph(ind.shape)
      local color = done and (ind.colorDone or { 0.1, 1.0, 0.1 }) or (ind.colorTodo or { 1.0, 0.2, 0.2 })
      out[#out + 1] = ColorText(color, glyph)
      end
    end
  end

  if out[1] == nil then return nil end
  return table.concat(out, "")
end

local function BuildRuleStatus(rule)
  local questID = tonumber(rule and rule.questID)

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
  if type(rule.aura) == "table" and rule.aura.spellID then
    local spellID = tonumber(rule.aura.spellID)
    local has = HasAuraSpellID(spellID)
    if has and rule.aura.rememberWeekly == true and (rule.aura.mustHave ~= false) then
      RememberWeeklyAura(spellID)
    end
    if (not has) and rule.aura.rememberWeekly == true and (rule.aura.mustHave ~= false) then
      has = HasRememberedWeeklyAura(spellID)
    end
    if rule.aura.mustHave and not has then
      return nil
    end
    if (rule.aura.mustHave == false) and has then
      return nil
    end
  end

  -- Item gate/progress
  local extra = nil
  if type(rule.item) == "table" and rule.item.itemID then
    local itemID = tonumber(rule.item.itemID)
    local count = GetItemCountSafe(itemID)
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
  f:SetSize(def.width or 300, def.height or 20)
  f:SetPoint(def.point or "TOP", UIParent, def.relPoint or def.point or "TOP", def.x or 0, def.y or 0)

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
  f:SetSize(def.width or 300, (def.rowHeight or 16) * ((def.maxItems or 20) + 2))
  f:SetPoint(def.point or "TOPRIGHT", UIParent, def.relPoint or def.point or "TOPRIGHT", def.x or -10, def.y or -120)

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
  local x = 8
  local y = -2

  if frame.title then frame.title:Hide() end

  if frameDef and frameDef.stretchWidth then
    local w = (UIParent and UIParent.GetWidth and UIParent:GetWidth()) or nil
    if w and w > 0 then
      frame:SetWidth(w)
    end
  end

  if frame.prefix then
    frame.prefix:Show()
    ApplyFontStyle(frame.prefix, frameDef and frameDef.font)
    frame.prefix:SetText("|cff00ccff[FQT]|r")
    x = x + (frame.prefix:GetStringWidth() or 0) + 12
  end

  for i = 1, maxItems do
    local e = entries[i]
    local fs = EnsureFontString(frame, i, frameDef and frameDef.font)
    fs:ClearAllPoints()
    fs:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
    if fs.SetWordWrap then fs:SetWordWrap(false) end

    ApplyFontStyle(fs, frameDef and frameDef.font)

    if e then
      local text = e.title
      if e.extra then text = text .. " (" .. e.extra .. ")" end
      if e.indicators then text = text .. " " .. e.indicators end
      fs:SetText(text)
      fs:Show()
      x = x + (fs:GetStringWidth() or 0) + 16
    else
      fs:SetText("")
      fs:Hide()
    end
  end

  if frameDef and frameDef.autoSize then
    frame:SetHeight(tonumber(frameDef.height) or 20)
  end
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
      if e.extra then text = text .. " (" .. e.extra .. ")" end
      if e.indicators then text = text .. " " .. e.indicators end
      fs:SetText(text)
      fs:Show()
      shown = shown + 1
    else
      fs:SetText("")
      fs:Hide()
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

  local rules = ns.rules or {}

  local frames = ns.frames or {}
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

      if type(def) == "table" and def.bgAlpha ~= nil then
        ApplyFAOBackdrop(f, def.bgAlpha)
      elseif editMode then
        ApplyFAOBackdrop(f, 0.25)
      end

      local t = tostring(def.type or "list"):lower()
      local entries = entriesByFrameID[id] or {}
      local hasAny = entries[1] ~= nil

      if not framesEnabled then
        f:Hide()
      elseif editMode then
        f:Show()
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

local function CreateAllFrames()
  for _, def in ipairs(ns.frames or {}) do
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

-- Events
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("QUEST_LOG_UPDATE")
frame:RegisterEvent("QUEST_ACCEPTED")
frame:RegisterEvent("QUEST_TURNED_IN")
frame:RegisterEvent("BAG_UPDATE_DELAYED")
frame:RegisterEvent("UNIT_AURA")

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
SlashCmdList["FQT"] = function(msg)
  msg = tostring(msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
  if msg == "" then
    framesEnabled = not framesEnabled
    RefreshAll()
    Print(framesEnabled and "Enabled." or "Disabled.")
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

  Print("Commands: /fqt  (toggle), /fqt on, /fqt off, /fqt edit")
end
