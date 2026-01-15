local addonName, ns = ...

local PREFIX = "|cff00ccff[FQT]|r "
local function Print(msg)
  print(PREFIX .. tostring(msg or ""))
end

local framesEnabled = true

local function NormalizeSV()
  fr0z3nUI_QuestTracker_Acc = fr0z3nUI_QuestTracker_Acc or {}
  fr0z3nUI_QuestTracker_Char = fr0z3nUI_QuestTracker_Char or {}

  fr0z3nUI_QuestTracker_Acc.settings = fr0z3nUI_QuestTracker_Acc.settings or {}
  fr0z3nUI_QuestTracker_Char.settings = fr0z3nUI_QuestTracker_Char.settings or {}
end

local function IsQuestCompleted(questID)
  if not questID then return false end
  if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
    return C_QuestLog.IsQuestFlaggedCompleted(questID) and true or false
  end
  return false
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

local function BuildRuleStatus(rule)
  local questID = tonumber(rule and rule.questID)
  if not questID then return nil end

  -- Hide when complete
  if IsQuestCompleted(questID) then
    return nil
  end

  -- Prereqs gate
  if not ArePrereqsMet(rule.prereq) then
    return nil
  end

  -- Aura gate
  if type(rule.aura) == "table" and rule.aura.spellID then
    local has = HasAuraSpellID(tonumber(rule.aura.spellID))
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

  local title = rule.label or GetQuestTitle(questID) or ("Quest " .. questID)
  return {
    questID = questID,
    title = title,
    extra = extra,
  }
end

-- UI
local framesByID = {}

local function ApplyFAOBackdrop(f)
  f:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    tile = true,
    tileSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  f:SetBackdropColor(0, 0, 0, 0.7)
end

local function CreateContainerFrame(def)
  local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
  f:SetClampedToScreen(true)
  f:SetFrameStrata("MEDIUM")
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", function(self)
    if self.StopMovingOrSizing then self:StopMovingOrSizing() end
  end)
  ApplyFAOBackdrop(f)

  f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f.title:SetPoint("TOPLEFT", 8, -6)
  f.title:SetJustifyH("LEFT")
  f.title:SetText("|cff00ccff[FQT]|r")

  return f
end

local function CreateBarFrame(def)
  local f = CreateContainerFrame(def)
  f:SetSize(def.width or 300, def.height or 20)
  f:SetPoint(def.point or "TOPRIGHT", UIParent, def.relPoint or def.point or "TOPRIGHT", def.x or -10, def.y or -10)

  f._itemFont = "GameFontHighlightSmall"
  f.items = {}
  return f
end

local function CreateListFrame(def)
  local f = CreateContainerFrame(def)
  f:SetSize(def.width or 300, (def.rowHeight or 16) * ((def.maxItems or 20) + 2))
  f:SetPoint(def.point or "TOPRIGHT", UIParent, def.relPoint or def.point or "TOPRIGHT", def.x or -10, def.y or -120)

  f._itemFont = "GameFontHighlight"
  f.items = {}
  return f
end

local function EnsureFontString(parent, idx)
  if parent.items[idx] then return parent.items[idx] end
  local fs = parent:CreateFontString(nil, "OVERLAY", parent._itemFont or "GameFontHighlight")
  fs:SetJustifyH("LEFT")
  parent.items[idx] = fs
  return fs
end

local function RenderBar(frameDef, frame, entries)
  local maxItems = tonumber(frameDef.maxItems) or 6
  local x = 8
  local y = -22

  frame.title:SetText("|cff00ccff[FQT]|r " .. (frameDef.id or "bar"))

  for i = 1, maxItems do
    local e = entries[i]
    local fs = EnsureFontString(frame, i)
    fs:ClearAllPoints()
    fs:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
    if fs.SetWordWrap then fs:SetWordWrap(false) end

    if e then
      local text = e.title
      if e.extra then text = text .. " (" .. e.extra .. ")" end
      fs:SetText(text)
      fs:Show()
      x = x + (fs:GetStringWidth() or 0) + 16
    else
      fs:SetText("")
      fs:Hide()
    end
  end
end

local function RenderList(frameDef, frame, entries)
  local maxItems = tonumber(frameDef.maxItems) or 20
  local rowH = tonumber(frameDef.rowHeight) or 16

  frame.title:SetText("|cff00ccff[FQT]|r " .. (frameDef.id or "list"))

  for i = 1, maxItems do
    local e = entries[i]
    local fs = EnsureFontString(frame, i)
    fs:ClearAllPoints()
    fs:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -22 - (i - 1) * rowH)

    if e then
      local text = e.title
      if e.extra then text = text .. " (" .. e.extra .. ")" end
      fs:SetText(text)
      fs:Show()
    else
      fs:SetText("")
      fs:Hide()
    end
  end
end

local function RefreshAll()
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

  for _, rule in ipairs(rules) do
    local status = BuildRuleStatus(rule)
    if status then
      if type(rule.targets) == "table" then
        for _, frameID in ipairs(rule.targets) do
          AddToFrame(tostring(frameID), status)
        end
      elseif rule.frameID then
        AddToFrame(tostring(rule.frameID), status)
      else
        local display = tostring(rule.display or "list"):lower()
        if display ~= "bar" then display = "list" end
        for _, frameID in ipairs(frameIDsByType[display]) do
          AddToFrame(frameID, status)
        end
      end
    end
  end

  for _, def in ipairs(frames) do
    local id = tostring(def.id or "")
    local f = framesByID[id]
    if f then
      local t = tostring(def.type or "list"):lower()
      local entries = entriesByFrameID[id] or {}
      local hasAny = entries[1] ~= nil

      if not framesEnabled then
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
SlashCmdList["FQT"] = function()
  framesEnabled = not framesEnabled
  RefreshAll()
end
