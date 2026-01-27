local addonName, ns = ...

-- Options UI extracted from fr0z3nUI_QuestTracker_Core.lua
-- This file depends on core exports on ns.*

local Print = ns.Print or function(...) end
local GetUISetting = ns.GetUISetting
local SetUISetting = ns.SetUISetting
local SaveWindowPosition = ns.SaveWindowPosition
local RestoreWindowPosition = ns.RestoreWindowPosition
local ApplyFAOBackdrop = ns.ApplyFAOBackdrop
local RefreshAll = ns.RefreshAll or function() end
local CreateAllFrames = ns.CreateAllFrames or function() end
local SaveFramePosition = ns.SaveFramePosition
local GetTrackerFrameByID = ns.GetTrackerFrameByID
local DestroyFrameByID = ns.DestroyFrameByID
local ResetFramePositionsToDefaults = ns.ResetFramePositionsToDefaults

local GetEffectiveRules = ns.GetEffectiveRules
local GetEffectiveFrames = ns.GetEffectiveFrames
local GetCustomRules = ns.GetCustomRules
local GetCustomRulesTrash = ns.GetCustomRulesTrash
local GetCustomFrames = ns.GetCustomFrames
local ShallowCopyTable = ns.ShallowCopyTable
local DeepCopyValue = ns.DeepCopyValue
local MakeUniqueRuleKey = ns.MakeUniqueRuleKey
local EnsureUniqueKeyForCustomRule = ns.EnsureUniqueKeyForCustomRule
local IsRuleDisabled = ns.IsRuleDisabled
local ToggleRuleDisabled = ns.ToggleRuleDisabled
local GetQuestTitle = ns.GetQuestTitle
local GetStandingIDByFactionID = ns.GetStandingIDByFactionID
local GetItemNameSafe = ns.GetItemNameSafe
local AssignRuleToFrame = ns.AssignRuleToFrame
local FindCustomRuleIndex = ns.FindCustomRuleIndex
local UnassignRuleFromFrame = ns.UnassignRuleFromFrame
local GetCalendarDebugEvents = ns.GetCalendarDebugEvents

-- UIDropDownMenu helpers (file-scope so diagnostics don't report undefined globals)
local UDDM_SetWidth = _G and rawget(_G, "UIDropDownMenu_SetWidth")
local UDDM_SetText = _G and rawget(_G, "UIDropDownMenu_SetText")
local UDDM_Initialize = _G and rawget(_G, "UIDropDownMenu_Initialize")
local UDDM_CreateInfo = _G and rawget(_G, "UIDropDownMenu_CreateInfo")
local UDDM_AddButton = _G and rawget(_G, "UIDropDownMenu_AddButton")
local UDDM_Enable = _G and rawget(_G, "UIDropDownMenu_EnableDropDown")
local UDDM_Disable = _G and rawget(_G, "UIDropDownMenu_DisableDropDown")

local function UseModernMenuDropDown(dropdown, build)
  local mu = _G and rawget(_G, "MenuUtil")
  if not (type(mu) == "table" and type(mu.CreateContextMenu) == "function") then
    return false
  end

  local anchor = dropdown and (dropdown.Button or dropdown)
  if not (anchor and anchor.SetScript) then
    return false
  end

  anchor:SetScript("OnClick", function(btn)
    mu.CreateContextMenu(btn, function(_, root)
      if type(build) == "function" then
        build(root)
      end
    end)
  end)
  return true
end

local function SetCoreEditMode(v)
  if ns.SetEditMode then ns.SetEditMode(v and true or false) end
end

local editMode = false

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

local function GetFrameDisplayNameByID(frameID)
  frameID = tostring(frameID or "")
  if frameID == "" then return "" end
  local frames = GetEffectiveFrames and GetEffectiveFrames() or nil
  if type(frames) == "table" then
    for _, def in ipairs(frames) do
      if tostring(def and def.id or "") == frameID then
        local n = tostring(def and def.name or "")
        if n ~= "" then return n end
        break
      end
    end
  end
  return frameID
end

-- Locals populated by EnsureOptionsFrame()
local optionsFrame
local RefreshRulesList
local RefreshFramesList
local RefreshActiveTab

-- Default (safe) implementations so tab switching never hard-errors.
-- When the Rules/Frames modules load, they will replace these via ctx.SetRefresh*.
RefreshRulesList = function()
  local f = optionsFrame
  local fn = f and f._refreshRulesList
  if type(fn) == "function" then
    return fn()
  end
end

RefreshFramesList = function()
  local f = optionsFrame
  local fn = f and f._refreshFramesList
  if type(fn) == "function" then
    return fn()
  end
end

RefreshActiveTab = function()
  local f = optionsFrame
  if not f then return end
  local t = tostring(f._activeTab or "")
  if t == "rules" then
    if RefreshRulesList then return RefreshRulesList() end
  elseif t == "frames" then
    if RefreshFramesList then return RefreshFramesList() end
  end
end

local function EnsureOptionsFrame()
  if optionsFrame then return optionsFrame end

  local f = CreateFrame("Frame", "FR0Z3NUIFQTOptions", UIParent, "BackdropTemplate")
  if not f then
    f = CreateFrame("Frame", "FR0Z3NUIFQTOptions", UIParent)
  end
  if not f then
    Print("Failed to create options frame.")
    return nil
  end

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
    editMode = true
    SetCoreEditMode(true)
  end)

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", 12, -10)
  title:SetText("")
  title:Hide()

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

  local function IsSelectedFrameBar()
    local id = tostring((f and f._selectedFrameID) or (optionsFrame and optionsFrame._selectedFrameID) or "")
    if id == "" then return false end
    local list = (type(GetEffectiveFrames) == "function" and GetEffectiveFrames()) or {}
    if type(list) ~= "table" then return false end
    for _, def in ipairs(list) do
      if type(def) == "table" and tostring(def.id or "") == id then
        return tostring(def.type or "list") == "bar"
      end
    end
    return false
  end

  local function UpdateReverseOrderVisibility(activeTabName)
    local btn = f and f._reverseOrderBtn
    if not (btn and btn.SetShown) then return end
    local tab = tostring(activeTabName or (optionsFrame and optionsFrame._activeTab) or "")
    local show = (tab == "frames") and IsSelectedFrameBar()
    btn:SetShown(show)
    if show and btn.SetChecked then
      btn:SetChecked((GetUISetting("reverseOrder", false) and true or false))
    end
  end

  -- If enabled, Save/Cancel will NOT clear the current form or auto-switch back to the Rules tab.
  local function ReadKeepEditFormOpenSetting()
    return (GetUISetting and GetUISetting("keepEditFormOpen", false)) and true or false
  end

  f._keepEditFormOpen = ReadKeepEditFormOpenSetting()

  local function GetKeepEditFormOpen()
    if f and f._keepEditFormOpen ~= nil then
      return f._keepEditFormOpen and true or false
    end
    return ReadKeepEditFormOpenSetting()
  end

  local keepOpenToggles = {}
  local function SetKeepEditFormOpen(v)
    v = v and true or false
    if f then f._keepEditFormOpen = v end
    if SetUISetting then SetUISetting("keepEditFormOpen", v) end
    for i = 1, #keepOpenToggles do
      local btn = keepOpenToggles[i]
      if btn and btn.SetChecked then btn:SetChecked(v) end
    end
  end

  local function CreateKeepOpenToggle(panel)
    if not panel then return nil end
    local btn = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    btn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -16, -40)
    btn:SetSize(22, 22)
    btn:SetChecked(GetKeepEditFormOpen())
    if btn.text then btn.text:SetText(""); btn.text:Hide() end
    if btn.Text and not btn.text then
      btn.text = btn.Text
      if btn.text then btn.text:SetText(""); btn.text:Hide() end
    end
    btn:SetScript("OnClick", function(self)
      SetKeepEditFormOpen(self:GetChecked() and true or false)
    end)
    btn:SetScript("OnEnter", function(self)
      if not GameTooltip then return end
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText("Keep form open", 1, 1, 1)
      GameTooltip:AddLine("When checked, Save/Cancel will keep this tab open and keep your entered values.", 0.85, 0.85, 0.85, true)
      GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    keepOpenToggles[#keepOpenToggles + 1] = btn
    return btn
  end

  -- Only show this on the edit tabs.
  panels.quest._keepOpenToggle = CreateKeepOpenToggle(panels.quest)
  panels.items._keepOpenToggle = CreateKeepOpenToggle(panels.items)
  panels.text._keepOpenToggle = CreateKeepOpenToggle(panels.text)
  panels.spells._keepOpenToggle = CreateKeepOpenToggle(panels.spells)

  local function SetPanelShown(name)
    for k, p in pairs(panels) do
      p:SetShown(k == name)
    end

    local showKeep = (name == "quest" or name == "items" or name == "text" or name == "spells") and true or false
    local keepVal = GetKeepEditFormOpen()
    for i = 1, #keepOpenToggles do
      local btn = keepOpenToggles[i]
      if btn and btn.SetShown then btn:SetShown(showKeep) end
      if btn and btn.SetChecked then btn:SetChecked(keepVal) end
    end

    local showFooter = (name == "rules" or name == "frames") and true or false
    if f._resetBtn and f._resetBtn.SetShown then f._resetBtn:SetShown(showFooter) end
    if f._reloadBtn and f._reloadBtn.SetShown then f._reloadBtn:SetShown(showFooter) end

    UpdateReverseOrderVisibility(name)

    if optionsFrame then
      optionsFrame._activeTab = name
      SetUISetting("optionsTab", name)
    end
    if name == "rules" then
      if RefreshRulesList then RefreshRulesList() end
    elseif name == "frames" then
      if RefreshFramesList then RefreshFramesList() end
    end
  end

  local tabOrder = { "rules", "items", "quest", "spells", "text", "frames" }
  local tabText = {
    frames = "UI",
    rules = "|cff00ccff[FQT]|r Quest Tracker",
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
    btn:SetSize((name == "rules") and 140 or 70, 18)
    btn:SetText(tabText[name] or name)
    btn._tabName = name

    -- Keep the [FQT] header-looking button readable even when selected (disabled).
    if name == "rules" then
      local gfn = _G and rawget(_G, "GameFontNormal")
      if gfn then
        if btn.SetNormalFontObject then btn:SetNormalFontObject(gfn) end
        if btn.SetDisabledFontObject then btn:SetDisabledFontObject(gfn) end
        if btn.SetHighlightFontObject then btn:SetHighlightFontObject(gfn) end
      end
    end

    if i == 1 then
      btn:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -10)
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
      SetCoreEditMode(false)
      RefreshAll()
    end
  end)

  -- Shared options helpers (used across multiple tabs and module builders)
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

  local function HideInputBoxTemplateArt(frame)
    if not (frame and frame.GetRegions) then return end
    for i = 1, select("#", frame:GetRegions()) do
      local region = select(i, frame:GetRegions())
      if region and region.GetObjectType and region:GetObjectType() == "Texture" and region.Hide then
        region:Hide()
      end
    end
  end

  local function HideDropDownMenuArt(dropdown)
    if not dropdown then return end
    for _, key in ipairs({ "Left", "Middle", "Right" }) do
      local tex = dropdown[key]
      if not tex and dropdown.GetName and dropdown:GetName() and _G then
        tex = _G[dropdown:GetName() .. key]
      end
      if tex and tex.Hide then tex:Hide() end
    end
  end

  local function GetCurrentMapIDSafe()
    if C_Map and C_Map.GetBestMapForUnit then
      local ok, id = pcall(C_Map.GetBestMapForUnit, "player")
      if ok then return tonumber(id) end
    end
    return nil
  end

  local function AttachLocationIDTooltip(editBox)
    if not (editBox and editBox.HookScript) then return end
    editBox:HookScript("OnEnter", function(self)
      if not GameTooltip then return end
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText("LocationID (uiMapID)", 1, 1, 1)
      local id = GetCurrentMapIDSafe()
      if id then
        GameTooltip:AddLine("Current mapID: " .. tostring(id), 0.9, 0.9, 0.9)
      else
        GameTooltip:AddLine("Current mapID: (unknown)", 0.9, 0.9, 0.9)
      end
      GameTooltip:AddLine("You can enter multiple IDs: 1978,2022", 0.7, 0.7, 0.7)
      GameTooltip:Show()
    end)
    editBox:HookScript("OnLeave", function()
      if GameTooltip then GameTooltip:Hide() end
    end)
  end

  local function ColorLabel(v)
    if v == nil then return "None" end
    if type(v) == "string" then return v end
    return "Custom"
  end

  local function FactionLabel(v)
    v = tostring(v or "")
    if v == "Alliance" then return "Alliance" end
    if v == "Horde" then return "Horde" end
    return "Both (Off)"
  end

  local function GetRuleExpansionChoices()
    local base = {
      { id = -2, name = "Events" },
      { id = -1, name = "Weekly" },
      { id = 12, name = "Midnight" },
      { id = 11, name = "The War Within" },
      { id = 10, name = "Dragonflight" },
      { id = 9, name = "Shadowlands" },
      { id = 8, name = "Battle for Azeroth" },
      { id = 7, name = "Legion" },
      { id = 6, name = "Warlords of Draenor" },
      { id = 5, name = "Mists of Pandaria" },
      { id = 4, name = "Cataclysm" },
      { id = 3, name = "Wrath of the Lich King" },
      { id = 2, name = "The Burning Crusade" },
      { id = 1, name = "Classic" },
    }

    -- Extend from loaded packs (so custom pack names show up too).
    local seen = {}
    for _, e in ipairs(base) do
      if e and e.name then seen[tostring(e.name)] = true end
    end
    for _, r in ipairs((type(ns) == "table" and ns.rules) or {}) do
      if type(r) == "table" then
        local n = r._expansionName
        local id = tonumber(r._expansionID)
        if type(n) == "string" then
          n = n:gsub("^%s+", ""):gsub("%s+$", "")
          if n ~= "" and not seen[n] then
            base[#base + 1] = { id = id, name = n }
            seen[n] = true
          end
        end
      end
    end

    local function Weight(id)
      if id == -2 then return 19000 end -- Events first
      if id == -1 then return 18000 end -- Weekly next
      return tonumber(id) or 0
    end
    table.sort(base, function(a, b)
      local wa = Weight(a and a.id)
      local wb = Weight(b and b.id)
      if wa ~= wb then return wa > wb end
      return tostring(a and a.name or "") < tostring(b and b.name or "")
    end)

    return base
  end

  local function ResolveRuleExpansionNameByID(id)
    id = tonumber(id)
    if id == nil then return nil end
    for _, e in ipairs(GetRuleExpansionChoices()) do
      if type(e) == "table" and tonumber(e.id) == id and type(e.name) == "string" and e.name ~= "" then
        return e.name
      end
    end
    return nil
  end

  local function GetDefaultRuleCreateExpansion()
    local bestID, bestName = nil, nil

    -- Prefer the newest expansion actually present in loaded rules.
    for _, r in ipairs((type(ns) == "table" and ns.rules) or {}) do
      if type(r) == "table" then
        local id = tonumber(r._expansionID)
        local name = (type(r._expansionName) == "string") and r._expansionName or nil
        if id and id > 0 then
          if not bestID or id > bestID then
            bestID, bestName = id, name
          end
        end
      end
    end

    -- Fall back to highest known expansion in choices.
    if not bestID then
      for _, e in ipairs(GetRuleExpansionChoices()) do
        if type(e) == "table" then
          local id = tonumber(e.id)
          if id and id > 0 then
            if not bestID or id > bestID then
              bestID, bestName = id, e.name
            end
          end
        end
      end
    end

    -- Absolute fallbacks.
    if not bestID then bestID, bestName = -1, "Weekly" end
    if not bestName then bestName = ResolveRuleExpansionNameByID(bestID) end
    if not bestName then bestName = "Weekly" end
    return bestID, bestName
  end

  local function GetRuleCreateExpansion()
    -- Stored in UI settings so it persists across sessions.
    local id = GetUISetting and GetUISetting("ruleCreateExpansionID", nil) or nil
    local name = GetUISetting and GetUISetting("ruleCreateExpansionName", nil) or nil
    id = tonumber(id)
    if type(name) == "string" then
      name = name:gsub("^%s+", ""):gsub("%s+$", "")
      if name == "" then name = nil end
    else
      name = nil
    end
    -- Ensure there is always a concrete category (Expansion/Weekly/Events).
    local resolvedName = (id ~= nil) and (name or ResolveRuleExpansionNameByID(id)) or nil
    if id == nil or resolvedName == nil then
      local defID, defName = GetDefaultRuleCreateExpansion()
      id, resolvedName = defID, defName
      if SetUISetting then
        SetUISetting("ruleCreateExpansionID", id)
        SetUISetting("ruleCreateExpansionName", resolvedName)
      end
    end
    return id, resolvedName
  end

  local function SyncRuleCreateExpansionDrops()
    for _, p in pairs({ panels and panels.quest, panels and panels.items, panels and panels.spells, panels and panels.text }) do
      if p and type(p._syncRuleCreateExpansion) == "function" then
        p:_syncRuleCreateExpansion()
      end
    end
  end

  local function SetRuleCreateExpansion(id, name)
    id = tonumber(id)
    if type(name) == "string" then
      name = name:gsub("^%s+", ""):gsub("%s+$", "")
      if name == "" then name = nil end
    else
      name = nil
    end

    -- Force concrete category selection.
    if id == nil then
      id, name = GetDefaultRuleCreateExpansion()
    end
    if name == nil then
      name = ResolveRuleExpansionNameByID(id)
    end
    if name == nil then
      local defID, defName = GetDefaultRuleCreateExpansion()
      id, name = defID, defName
    end

    if SetUISetting then
      SetUISetting("ruleCreateExpansionID", id)
      SetUISetting("ruleCreateExpansionName", name)
    end
    SyncRuleCreateExpansionDrops()
  end

  local optionsCtx
  local function GetOptionsCtx()
    if optionsCtx then return optionsCtx end

    local UDDM_SetWidth = _G and rawget(_G, "UIDropDownMenu_SetWidth")
    local UDDM_SetText = _G and rawget(_G, "UIDropDownMenu_SetText")
    local UDDM_Initialize = _G and rawget(_G, "UIDropDownMenu_Initialize")
    local UDDM_CreateInfo = _G and rawget(_G, "UIDropDownMenu_CreateInfo")
    local UDDM_AddButton = _G and rawget(_G, "UIDropDownMenu_AddButton")

    optionsCtx = {
      optionsFrame = f,
      panels = panels,

      Print = Print,
      CreateFrame = CreateFrame,

      ApplyFAOBackdrop = ApplyFAOBackdrop,
      GetCalendarDebugEvents = GetCalendarDebugEvents,

      UseModernMenuDropDown = UseModernMenuDropDown,
      GetEffectiveFrames = GetEffectiveFrames,
      GetCustomFrames = GetCustomFrames,
      GetFrameDisplayNameByID = GetFrameDisplayNameByID,
      GetItemNameSafe = GetItemNameSafe,
      GetQuestTitle = GetQuestTitle,

      GetUISetting = GetUISetting,
      SetUISetting = SetUISetting,

      CreateQuickColorPalette = CreateQuickColorPalette,
      SetCheckButtonLabel = SetCheckButtonLabel,

      GetCustomRules = GetCustomRules,
      GetCustomRulesTrash = GetCustomRulesTrash,
      EnsureUniqueKeyForCustomRule = EnsureUniqueKeyForCustomRule,
      IsRuleDisabled = IsRuleDisabled,
      ToggleRuleDisabled = ToggleRuleDisabled,
      OpenCustomRuleInTab = function(...)
        if ns and ns.OpenCustomRuleInTab then
          return ns.OpenCustomRuleInTab(...)
        end
      end,
      OpenDefaultRuleInTab = function(...)
        if ns and ns.OpenDefaultRuleInTab then
          return ns.OpenDefaultRuleInTab(...)
        end
      end,
      DeepCopyValue = DeepCopyValue,
      GetDefaultRuleEdits = function()
        if ns and ns.GetDefaultRuleEdits then
          return ns.GetDefaultRuleEdits() or {}
        end
        return {}
      end,

      CreateAllFrames = CreateAllFrames,
      DestroyFrameByID = DestroyFrameByID,
      ShallowCopyTable = ShallowCopyTable,
      UpdateReverseOrderVisibility = UpdateReverseOrderVisibility,
      RefreshAll = RefreshAll,
      RefreshFramesList = function() if RefreshFramesList then return RefreshFramesList() end end,
      SetRefreshFramesList = function(fn)
        if type(fn) == "function" then
          RefreshFramesList = fn
        end
      end,
      RefreshRulesList = function() if RefreshRulesList then return RefreshRulesList() end end,
      SetRefreshRulesList = function(fn)
        if type(fn) == "function" then
          RefreshRulesList = fn
        end
      end,

      GetKeepEditFormOpen = GetKeepEditFormOpen,
      SelectTab = SelectTab,

      AddPlaceholder = AddPlaceholder,
      HideInputBoxTemplateArt = HideInputBoxTemplateArt,
      HideDropDownMenuArt = HideDropDownMenuArt,
      AttachLocationIDTooltip = AttachLocationIDTooltip,

      UDDM_SetWidth = UDDM_SetWidth,
      UDDM_SetText = UDDM_SetText,
      UDDM_Initialize = UDDM_Initialize,
      UDDM_CreateInfo = UDDM_CreateInfo,
      UDDM_AddButton = UDDM_AddButton,

      ColorLabel = ColorLabel,
      FactionLabel = FactionLabel,

      GetRuleExpansionChoices = GetRuleExpansionChoices,
      GetRuleCreateExpansion = GetRuleCreateExpansion,
      SetRuleCreateExpansion = SetRuleCreateExpansion,
      SyncRuleCreateExpansionDrops = SyncRuleCreateExpansionDrops,
    }

    return optionsCtx
  end

  -- QUEST tab (Quest module)
  local useQuestModule = type(ns) == "table" and type(ns.FQTOptionsPanels) == "table" and type(ns.FQTOptionsPanels.BuildQuest) == "function"
  if useQuestModule then
    ns.FQTOptionsPanels.BuildQuest(GetOptionsCtx())
  else
    -- Legacy Quest tab UI moved to fr0z3nUI_QuestTrackerQuest.lua
    if false then
  local questTitle = panels.quest:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  questTitle:SetPoint("TOPLEFT", 12, -40)
  questTitle:SetText("Quest")

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

  panels.quest._questInfoScroll = qiScroll

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
  if UDDM_SetText then UDDM_SetText(questFrameDrop, GetFrameDisplayNameByID("list1")) end
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
  AttachLocationIDTooltip(qLocBox)

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

  if UDDM_Initialize and UDDM_CreateInfo and UDDM_AddButton then
    local modernQuestFrame = UseModernMenuDropDown(questFrameDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Bar / List") end
      for _, def in ipairs(GetEffectiveFrames()) do
        if type(def) == "table" and def.id and root then
          local id = tostring(def.id)
          local label = GetFrameDisplayNameByID(id)
          if root.CreateRadio then
            root:CreateRadio(label, function() return (panels.quest._questTargetFrameID == id) end, function()
              panels.quest._questTargetFrameID = id
              if UDDM_SetText then UDDM_SetText(questFrameDrop, GetFrameDisplayNameByID(id)) end
            end)
          elseif root.CreateButton then
            root:CreateButton(label, function()
              panels.quest._questTargetFrameID = id
              if UDDM_SetText then UDDM_SetText(questFrameDrop, GetFrameDisplayNameByID(id)) end
            end)
          end
        end
      end
    end)

    local modernQuestFaction = UseModernMenuDropDown(questFactionDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Faction") end
      local function Add(name, v)
        if not root then return end
        if root.CreateRadio then
          root:CreateRadio(name, function() return (panels.quest._questFaction == v) end, function()
            panels.quest._questFaction = v
            if UDDM_SetText then UDDM_SetText(questFactionDrop, FactionLabel(v)) end
          end)
        elseif root.CreateButton then
          root:CreateButton(name, function()
            panels.quest._questFaction = v
            if UDDM_SetText then UDDM_SetText(questFactionDrop, FactionLabel(v)) end
          end)
        end
      end
      Add("Both (Off)", nil)
      Add("Alliance", "Alliance")
      Add("Horde", "Horde")
    end)

    local modernQuestColor = UseModernMenuDropDown(questColorDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Color") end
      for _, name in ipairs({ "None", "Green", "Blue", "Yellow", "Red", "Cyan" }) do
        if root and root.CreateRadio then
          root:CreateRadio(name, function() return (panels.quest._questColorName == name) end, function() SetQuestColor(name) end)
        elseif root and root.CreateButton then
          root:CreateButton(name, function() SetQuestColor(name) end)
        end
      end
    end)

    local modernLevelOp = UseModernMenuDropDown(qLevelOpDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Player level") end
      local function Add(name, op)
        if not root then return end
        if root.CreateRadio then
          root:CreateRadio(name, function() return (panels.quest._playerLevelOp == op) end, function()
            panels.quest._playerLevelOp = op
            if UDDM_SetText then UDDM_SetText(qLevelOpDrop, name) end
          end)
        elseif root.CreateButton then
          root:CreateButton(name, function()
            panels.quest._playerLevelOp = op
            if UDDM_SetText then UDDM_SetText(qLevelOpDrop, name) end
          end)
        end
      end
      Add("Off", nil)
      Add("<", "<")
      Add("<=", "<=")
      Add("=", "=")
      Add(">=", ">=")
      Add(">", ">")
      Add("!=", "!=")
    end)

    if not modernQuestFrame then
    UDDM_Initialize(questFrameDrop, function(self, level)
      local info = UDDM_CreateInfo()
      for _, def in ipairs(GetEffectiveFrames()) do
        if type(def) == "table" and def.id then
          local id = tostring(def.id)
          info.text = GetFrameDisplayNameByID(id)
          info.checked = (panels.quest._questTargetFrameID == id) and true or false
          info.func = function()
            panels.quest._questTargetFrameID = id
            if UDDM_SetText then UDDM_SetText(questFrameDrop, GetFrameDisplayNameByID(id)) end
          end
          UDDM_AddButton(info)
        end
      end
    end)
    end

    if not modernQuestFaction then
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

    end

    if not modernQuestColor then

    UDDM_Initialize(questColorDrop, function(self, level)
      for _, name in ipairs({ "None", "Green", "Blue", "Yellow", "Red", "Cyan" }) do
        local info = UDDM_CreateInfo()
        info.text = name
        info.checked = (panels.quest._questColorName == name) and true or false
        info.func = function() SetQuestColor(name) end
        UDDM_AddButton(info)
      end
    end)

    end

    if not modernLevelOp then

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

    end
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
    panels.quest._questFrameFallbackBox = fb
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
    panels.quest._questFactionFallbackBox = fbf
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
    panels.quest._questColorFallbackBox = cfb
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

  local function ClearQuestInputs()
    if qiBox then qiBox:SetText("") end
    if qiScroll and qiScroll.SetVerticalScroll then qiScroll:SetVerticalScroll(0) end
    if questIDBox then questIDBox:SetText("0") end
    if afterBox then afterBox:SetText("0") end
    if qTitleBox then qTitleBox:SetText("") end
    if qLocBox then qLocBox:SetText("0") end

    panels.quest._questTargetFrameID = "list1"
    if UDDM_SetText and questFrameDrop then UDDM_SetText(questFrameDrop, GetFrameDisplayNameByID("list1")) end
    if panels.quest._questFrameFallbackBox then panels.quest._questFrameFallbackBox:SetText("list1") end

    panels.quest._questFaction = nil
    if UDDM_SetText and questFactionDrop and FactionLabel then UDDM_SetText(questFactionDrop, FactionLabel(nil)) end
    if panels.quest._questFactionFallbackBox then panels.quest._questFactionFallbackBox:SetText("both") end

    panels.quest._questColor = nil
    panels.quest._questColorName = "None"
    if UDDM_SetText and questColorDrop then UDDM_SetText(questColorDrop, "None") end
    if panels.quest._questColorFallbackBox then panels.quest._questColorFallbackBox:SetText("none") end

    panels.quest._playerLevelOp = nil
    if UDDM_SetText and qLevelOpDrop then UDDM_SetText(qLevelOpDrop, "Off") end
    if qLevelBox then qLevelBox:SetText("0") end
  end

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
      panels.quest._editingDefaultBase = nil
      panels.quest._editingDefaultKey = nil
      addQuestBtn:SetText("Add Quest Rule")
      cancelQuestEditBtn:Hide()
      Print("Saved quest rule.")
    elseif panels.quest._editingDefaultBase and panels.quest._editingDefaultKey and ns and ns.GetDefaultRuleEdits then
      local edits = ns.GetDefaultRuleEdits()
      local base = panels.quest._editingDefaultBase
      local key = tostring(panels.quest._editingDefaultKey)
      local effective = (type(edits[key]) == "table") and edits[key] or base
      local rule = DeepCopyValue(effective)

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

      if base and base.key ~= nil then rule.key = tostring(base.key) end
      edits[key] = rule

      panels.quest._editingCustomIndex = nil
      panels.quest._editingDefaultBase = nil
      panels.quest._editingDefaultKey = nil
      addQuestBtn:SetText("Add Quest Rule")
      cancelQuestEditBtn:Hide()
      Print("Saved default quest rule edit.")
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
    if not GetKeepEditFormOpen() then
      ClearQuestInputs()
      SelectTab("rules")
    end
  end)

  cancelQuestEditBtn:SetScript("OnClick", function()
    panels.quest._editingCustomIndex = nil
    panels.quest._editingDefaultBase = nil
    panels.quest._editingDefaultKey = nil
    addQuestBtn:SetText("Add Quest Rule")
    cancelQuestEditBtn:Hide()

    if not GetKeepEditFormOpen() then
      ClearQuestInputs()
      SelectTab("rules")
    end
  end)

  end

  end

  -- ITEMS tab (Items module)
  local useItemsModule = type(ns) == "table" and type(ns.FQTOptionsPanels) == "table" and type(ns.FQTOptionsPanels.BuildItems) == "function"
  if useItemsModule then
    ns.FQTOptionsPanels.BuildItems(GetOptionsCtx())
  else
    -- Legacy Items tab UI moved to fr0z3nUI_QuestTrackerItems.lua
    if false then
  do
  local pItems = panels.items

  local itemsTitle = pItems:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  itemsTitle:SetPoint("TOPLEFT", 12, -40)
  itemsTitle:SetText("Items")

  local itemIDBox = CreateFrame("EditBox", nil, pItems, "InputBoxTemplate")
  itemIDBox:SetSize(70, 20)
  itemIDBox:SetPoint("TOPLEFT", 12, -62)
  itemIDBox:SetAutoFocus(false)
  itemIDBox:SetNumeric(true)
  itemIDBox:SetText("")
  itemIDBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  itemIDBox:SetTextInsets(6, 6, 0, 0)
  AddPlaceholder(itemIDBox, "ItemID")
  HideInputBoxTemplateArt(itemIDBox)

  local itemNameBox = CreateFrame("EditBox", nil, pItems, "InputBoxTemplate")
  itemNameBox:SetSize(170, 20)
  itemNameBox:SetPoint("TOPLEFT", 90, -62)
  itemNameBox:SetAutoFocus(false)
  itemNameBox:SetText("")
  itemNameBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  itemNameBox:SetTextInsets(6, 6, 0, 0)
  AddPlaceholder(itemNameBox, "Item Name")
  HideInputBoxTemplateArt(itemNameBox)

  local itemInfoScroll = CreateFrame("ScrollFrame", nil, pItems, "UIPanelScrollFrameTemplate")
  itemInfoScroll:SetPoint("TOPLEFT", 90, -86)
  itemInfoScroll:SetSize(170, 44)

  local itemInfoBox = CreateFrame("EditBox", nil, itemInfoScroll)
  itemInfoBox:SetMultiLine(true)
  itemInfoBox:SetAutoFocus(false)
  itemInfoBox:SetFontObject("ChatFontNormal")
  itemInfoBox:SetWidth(150)
  itemInfoBox:SetTextInsets(6, 6, 6, 6)
  itemInfoBox:SetText("")
  itemInfoBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  itemInfoBox:SetScript("OnCursorChanged", function(self, x, y, w, h)
    if not itemInfoScroll then return end
    itemInfoScroll:UpdateScrollChildRect()
    local offset = itemInfoScroll:GetVerticalScroll() or 0
    local height = itemInfoScroll:GetHeight() or 0
    local top = -y
    if top < offset then
      itemInfoScroll:SetVerticalScroll(top)
    elseif top > offset + height - 20 then
      itemInfoScroll:SetVerticalScroll(top - height + 20)
    end
  end)

  itemInfoScroll:SetScrollChild(itemInfoBox)
  AddPlaceholder(itemInfoBox, "Item Info")

  pItems._itemInfoScroll = itemInfoScroll

  local itemQuestIDBox = CreateFrame("EditBox", nil, pItems, "InputBoxTemplate")
  itemQuestIDBox:SetSize(70, 20)
  itemQuestIDBox:SetPoint("TOPLEFT", 270, -62)
  itemQuestIDBox:SetAutoFocus(false)
  itemQuestIDBox:SetNumeric(true)
  itemQuestIDBox:SetText("")
  itemQuestIDBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  itemQuestIDBox:SetTextInsets(6, 6, 0, 0)
  AddPlaceholder(itemQuestIDBox, "QuestID")
  HideInputBoxTemplateArt(itemQuestIDBox)

  local itemAfterQuestIDBox = CreateFrame("EditBox", nil, pItems, "InputBoxTemplate")
  itemAfterQuestIDBox:SetSize(80, 20)
  itemAfterQuestIDBox:SetPoint("TOPLEFT", 350, -62)
  itemAfterQuestIDBox:SetAutoFocus(false)
  itemAfterQuestIDBox:SetNumeric(true)
  itemAfterQuestIDBox:SetText("")
  itemAfterQuestIDBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  itemAfterQuestIDBox:SetTextInsets(6, 6, 0, 0)
  AddPlaceholder(itemAfterQuestIDBox, "After QuestID")
  HideInputBoxTemplateArt(itemAfterQuestIDBox)

  local itemCurrencyIDBox = CreateFrame("EditBox", nil, pItems, "InputBoxTemplate")
  itemCurrencyIDBox:SetSize(70, 20)
  itemCurrencyIDBox:SetPoint("TOPLEFT", 440, -62)
  itemCurrencyIDBox:SetAutoFocus(false)
  itemCurrencyIDBox:SetNumeric(true)
  itemCurrencyIDBox:SetText("")
  itemCurrencyIDBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  itemCurrencyIDBox:SetTextInsets(6, 6, 0, 0)
  AddPlaceholder(itemCurrencyIDBox, "CurrencyID")
  HideInputBoxTemplateArt(itemCurrencyIDBox)

  local itemCurrencyReqBox = CreateFrame("EditBox", nil, pItems, "InputBoxTemplate")
  itemCurrencyReqBox:SetSize(70, 20)
  itemCurrencyReqBox:SetPoint("TOPLEFT", 520, -62)
  itemCurrencyReqBox:SetAutoFocus(false)
  itemCurrencyReqBox:SetNumeric(true)
  itemCurrencyReqBox:SetText("")
  itemCurrencyReqBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  itemCurrencyReqBox:SetTextInsets(6, 6, 0, 0)
  AddPlaceholder(itemCurrencyReqBox, "MinCur")
  HideInputBoxTemplateArt(itemCurrencyReqBox)

  local itemShowBelowBox = CreateFrame("EditBox", nil, pItems, "InputBoxTemplate")
  itemShowBelowBox:SetSize(100, 20)
  itemShowBelowBox:SetPoint("TOPLEFT", 12, -132)
  itemShowBelowBox:SetAutoFocus(false)
  itemShowBelowBox:SetNumeric(true)
  itemShowBelowBox:SetText("")
  itemShowBelowBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  itemShowBelowBox:SetTextInsets(6, 6, 0, 0)
  AddPlaceholder(itemShowBelowBox, "Show <")
  HideInputBoxTemplateArt(itemShowBelowBox)

  pItems._itemIDBox = itemIDBox
  pItems._itemNameBox = itemNameBox
  pItems._itemInfoBox = itemInfoBox
  pItems._itemQuestIDBox = itemQuestIDBox
  pItems._itemAfterQuestIDBox = itemAfterQuestIDBox
  pItems._itemCurrencyIDBox = itemCurrencyIDBox
  pItems._itemCurrencyReqBox = itemCurrencyReqBox
  pItems._itemShowBelowBox = itemShowBelowBox

  local function UpdateItemFieldsFromID(force)
    local id = tonumber(pItems._itemIDBox and pItems._itemIDBox:GetText() or "")
    if not id or id <= 0 then
      pItems._pendingItemLabelID = nil
      pItems._pendingItemLabelForce = nil
      return
    end

    local name = GetItemNameSafe(id)
    if type(name) ~= "string" or name == "" then
      pItems._pendingItemLabelID = id
      pItems._pendingItemLabelForce = force and true or false
      if C_Item and C_Item.RequestLoadItemDataByID then
        pcall(C_Item.RequestLoadItemDataByID, id)
      end
      return
    end

    local nb = pItems._itemNameBox
    if nb then
      if force then
        nb._autoName = name
        nb:SetText(name)
      else
        local cur = tostring(nb:GetText() or "")
        if cur == "" or (nb._autoName ~= nil and cur == tostring(nb._autoName)) then
          nb._autoName = name
          nb:SetText(name)
        end
      end
    end

    local ib = pItems._itemInfoBox
    if ib then
      if force then
        ib._autoInfo = name
        ib:SetText(name)
      else
        local cur = tostring(ib:GetText() or "")
        if cur == "" or (ib._autoInfo ~= nil and cur == tostring(ib._autoInfo)) then
          ib._autoInfo = name
          ib:SetText(name)
        end
      end
    end
  end

  do
    local nameLoadFrame = CreateFrame("Frame")
    nameLoadFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    nameLoadFrame:RegisterEvent("ITEM_DATA_LOAD_RESULT")
    nameLoadFrame:SetScript("OnEvent", function(_, _, itemID, success)
      itemID = tonumber(itemID)
      if not itemID or success == false then return end
      if pItems._pendingItemLabelID and itemID == tonumber(pItems._pendingItemLabelID) then
        local force = pItems._pendingItemLabelForce and true or false
        UpdateItemFieldsFromID(force)
        if type(GetItemNameSafe(itemID)) == "string" then
          pItems._pendingItemLabelID = nil
          pItems._pendingItemLabelForce = nil
        end
      end
    end)
  end

  itemNameBox:HookScript("OnTextChanged", function(self, userInput)
    if not userInput then return end
    local cur = tostring(self:GetText() or "")
    if self._autoName ~= nil and cur ~= tostring(self._autoName) then
      self._autoName = nil
    end
  end)

  itemInfoBox:HookScript("OnTextChanged", function(self, userInput)
    if not userInput then return end
    local cur = tostring(self:GetText() or "")
    if self._autoInfo ~= nil and cur ~= tostring(self._autoInfo) then
      self._autoInfo = nil
    end
  end)

  itemIDBox:HookScript("OnTextChanged", function(self, userInput)
    if not userInput then return end
    UpdateItemFieldsFromID(GetKeepEditFormOpen())
  end)

  local itemsFrameLabel = pItems:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  itemsFrameLabel:SetPoint("TOPLEFT", 12, -146)
  itemsFrameLabel:SetText("Bar / List")

  local itemsFrameDrop = CreateFrame("Frame", nil, pItems, "UIDropDownMenuTemplate")
  itemsFrameDrop:SetPoint("TOPLEFT", -8, -174)
  if UDDM_SetWidth then UDDM_SetWidth(itemsFrameDrop, 160) end
  if UDDM_SetText then UDDM_SetText(itemsFrameDrop, GetFrameDisplayNameByID("list1")) end
  pItems._targetFrameID = "list1"
  HideDropDownMenuArt(itemsFrameDrop)

  local itemsFactionLabel = pItems:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  itemsFactionLabel:SetPoint("TOPLEFT", 180, -146)
  itemsFactionLabel:SetText("Faction")

  local itemsFactionDrop = CreateFrame("Frame", nil, pItems, "UIDropDownMenuTemplate")
  itemsFactionDrop:SetPoint("TOPLEFT", 165, -174)
  if UDDM_SetWidth then UDDM_SetWidth(itemsFactionDrop, 140) end
  if UDDM_SetText then UDDM_SetText(itemsFactionDrop, "Both (Off)") end
  pItems._faction = nil
  HideDropDownMenuArt(itemsFactionDrop)

  local itemsColorLabel = pItems:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  itemsColorLabel:SetPoint("TOPLEFT", 340, -146)
  itemsColorLabel:SetText("Color")

  local itemsColorDrop = CreateFrame("Frame", nil, pItems, "UIDropDownMenuTemplate")
  itemsColorDrop:SetPoint("TOPLEFT", 325, -174)
  if UDDM_SetWidth then UDDM_SetWidth(itemsColorDrop, 140) end
  if UDDM_SetText then UDDM_SetText(itemsColorDrop, "None") end
  pItems._color = nil
  HideDropDownMenuArt(itemsColorDrop)

  -- Quick color palette for item text color
  CreateQuickColorPalette(pItems, itemsColorDrop, "TOPLEFT", "BOTTOMLEFT", 26, 12, {
    cols = 5,
    getColor = function()
      if type(pItems._color) == "table" then
        return pItems._color[1], pItems._color[2], pItems._color[3]
      end
      return nil
    end,
    onPick = function(r, g, b)
      pItems._color = { r, g, b }
      if UDDM_SetText then UDDM_SetText(itemsColorDrop, "Custom") end
    end,
  })

  local repFactionLabel = pItems:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  repFactionLabel:SetPoint("TOPLEFT", 12, -210)
  repFactionLabel:SetText("Rep FactionID")

  local repFactionBox = CreateFrame("EditBox", nil, pItems, "InputBoxTemplate")
  repFactionBox:SetSize(90, 20)
  repFactionBox:SetPoint("TOPLEFT", 12, -226)
  repFactionBox:SetAutoFocus(false)
  repFactionBox:SetNumeric(true)
  repFactionBox:SetText("")
  repFactionBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  repFactionBox:SetTextInsets(6, 6, 0, 0)
  AddPlaceholder(repFactionBox, "Rep FactionID")
  HideInputBoxTemplateArt(repFactionBox)

  local repMinLabel = pItems:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  repMinLabel:SetPoint("TOPLEFT", 110, -210)
  repMinLabel:SetText("Min Rep")

  local repMinDrop = CreateFrame("Frame", nil, pItems, "UIDropDownMenuTemplate")
  repMinDrop:SetPoint("TOPLEFT", 95, -238)
  if UDDM_SetWidth then UDDM_SetWidth(repMinDrop, 140) end
  if UDDM_SetText then UDDM_SetText(repMinDrop, "Off") end
  pItems._repMinStanding = nil
  HideDropDownMenuArt(repMinDrop)

  local hideAcquired = CreateFrame("CheckButton", nil, pItems, "UICheckButtonTemplate")
  hideAcquired:SetPoint("TOPLEFT", 250, -228)
  SetCheckButtonLabel(hideAcquired, "Hide when acquired")
  hideAcquired:SetChecked(false)

  local hideExalted = CreateFrame("CheckButton", nil, pItems, "UICheckButtonTemplate")
  hideExalted:SetPoint("TOPLEFT", 400, -228)
  SetCheckButtonLabel(hideExalted, "Hide when exalted")
  hideExalted:SetChecked(false)

  local sellExalted = CreateFrame("CheckButton", nil, pItems, "UICheckButtonTemplate")
  sellExalted:SetPoint("TOPLEFT", 400, -252)
  SetCheckButtonLabel(sellExalted, "Sell when exalted")
  sellExalted:SetChecked(false)
  sellExalted:SetScript("OnClick", function()
    if sellExalted:GetChecked() and hideExalted then
      hideExalted:SetChecked(false)
    end
  end)
  hideExalted:HookScript("OnClick", function()
    if hideExalted:GetChecked() and sellExalted then
      sellExalted:SetChecked(false)
    end
  end)

  local restedOnly = CreateFrame("CheckButton", nil, pItems, "UICheckButtonTemplate")
  restedOnly:SetPoint("TOPLEFT", 12, -252)
  SetCheckButtonLabel(restedOnly, "Rested areas only")
  restedOnly:SetChecked(false)

  local itemsLevelLabel = pItems:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  itemsLevelLabel:SetPoint("TOPLEFT", 250, -258)
  itemsLevelLabel:SetText("Player level")

  local itemsLevelOpDrop = CreateFrame("Frame", nil, pItems, "UIDropDownMenuTemplate")
  itemsLevelOpDrop:SetPoint("TOPLEFT", 235, -278)
  if UDDM_SetWidth then UDDM_SetWidth(itemsLevelOpDrop, 70) end
  if UDDM_SetText then UDDM_SetText(itemsLevelOpDrop, "Off") end
  pItems._playerLevelOp = nil
  HideDropDownMenuArt(itemsLevelOpDrop)

  local itemsLevelBox = CreateFrame("EditBox", nil, pItems, "InputBoxTemplate")
  itemsLevelBox:SetSize(50, 20)
  itemsLevelBox:SetPoint("TOPLEFT", 340, -274)
  itemsLevelBox:SetAutoFocus(false)
  itemsLevelBox:SetNumeric(true)
  itemsLevelBox:SetText("")
  itemsLevelBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  itemsLevelBox:SetTextInsets(6, 6, 0, 0)
  AddPlaceholder(itemsLevelBox, "Lvl")
  HideInputBoxTemplateArt(itemsLevelBox)

  local itemsLocLabel = pItems:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  itemsLocLabel:SetPoint("TOPLEFT", 12, -282)
  itemsLocLabel:SetText("LocationID (uiMapID)")

  local itemsLocBox = CreateFrame("EditBox", nil, pItems, "InputBoxTemplate")
  itemsLocBox:SetSize(90, 20)
  itemsLocBox:SetPoint("TOPLEFT", 12, -298)
  itemsLocBox:SetAutoFocus(false)
  itemsLocBox:SetText("")
  itemsLocBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  itemsLocBox:SetTextInsets(6, 6, 0, 0)
  AddPlaceholder(itemsLocBox, "uiMapID")
  HideInputBoxTemplateArt(itemsLocBox)
  AttachLocationIDTooltip(itemsLocBox)

  if UDDM_Initialize and UDDM_CreateInfo and UDDM_AddButton then
    local function ColorsMatch(tbl, r, g, b)
      if type(tbl) ~= "table" then return false end
      return (tonumber(tbl[1]) == r) and (tonumber(tbl[2]) == g) and (tonumber(tbl[3]) == b)
    end

    local function SetItemsColor(name)
      if name == "None" then
        pItems._color = nil
      elseif name == "Green" then
        pItems._color = { 0.1, 1.0, 0.1 }
      elseif name == "Blue" then
        pItems._color = { 0.2, 0.6, 1.0 }
      elseif name == "Yellow" then
        pItems._color = { 1.0, 0.9, 0.2 }
      elseif name == "Red" then
        pItems._color = { 1.0, 0.2, 0.2 }
      elseif name == "Cyan" then
        pItems._color = { 0.2, 1.0, 1.0 }
      else
        pItems._color = nil
        name = "None"
      end
      if UDDM_SetText then UDDM_SetText(pItems._itemsColorDrop, name) end
    end

    local modernItemsFrame = UseModernMenuDropDown(itemsFrameDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Bar / List") end
      for _, def in ipairs(GetEffectiveFrames()) do
        if type(def) == "table" and def.id and root then
          local id = tostring(def.id)
          local label = GetFrameDisplayNameByID(id)
          if root.CreateRadio then
            root:CreateRadio(label, function() return (pItems._targetFrameID == id) end, function()
              pItems._targetFrameID = id
              if UDDM_SetText then UDDM_SetText(pItems._itemsFrameDrop, GetFrameDisplayNameByID(id)) end
            end)
          elseif root.CreateButton then
            root:CreateButton(label, function()
              pItems._targetFrameID = id
              if UDDM_SetText then UDDM_SetText(pItems._itemsFrameDrop, GetFrameDisplayNameByID(id)) end
            end)
          end
        end
      end
    end)

    local modernItemsFaction = UseModernMenuDropDown(itemsFactionDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Faction") end
      local function Add(name, v)
        if not root then return end
        if root.CreateRadio then
          root:CreateRadio(name, function() return (pItems._faction == v) end, function()
            pItems._faction = v
            if UDDM_SetText then UDDM_SetText(pItems._itemsFactionDrop, name) end
          end)
        elseif root.CreateButton then
          root:CreateButton(name, function()
            pItems._faction = v
            if UDDM_SetText then UDDM_SetText(pItems._itemsFactionDrop, name) end
          end)
        end
      end
      Add("Both (Off)", nil)
      Add("Alliance", "Alliance")
      Add("Horde", "Horde")
    end)

    local modernItemsColor = UseModernMenuDropDown(itemsColorDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Color") end
      local opts = {
        { "None", nil },
        { "Green", { 0.1, 1.0, 0.1 } },
        { "Blue", { 0.2, 0.6, 1.0 } },
        { "Yellow", { 1.0, 0.9, 0.2 } },
        { "Red", { 1.0, 0.2, 0.2 } },
        { "Cyan", { 0.2, 1.0, 1.0 } },
      }
      for _, opt in ipairs(opts) do
        local name, c = opt[1], opt[2]
        local function IsSelected()
          if name == "None" then return pItems._color == nil end
          if not c then return false end
          return ColorsMatch(pItems._color, c[1], c[2], c[3])
        end
        local function SetSelected()
          SetItemsColor(name)
        end
        if root and root.CreateRadio then
          root:CreateRadio(name, IsSelected, SetSelected)
        elseif root and root.CreateButton then
          root:CreateButton(name, SetSelected)
        end
      end
    end)

    local modernItemsRepMin = UseModernMenuDropDown(repMinDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Min Rep") end
      local opts = {
        { "Off", nil },
        { "Friendly", 5 },
        { "Honored", 6 },
        { "Revered", 7 },
        { "Exalted", 8 },
      }
      for _, opt in ipairs(opts) do
        local name, standing = opt[1], opt[2]
        local function IsSelected() return (pItems._repMinStanding == standing) end
        local function SetSelected()
          pItems._repMinStanding = standing
          if UDDM_SetText then UDDM_SetText(pItems._repMinDrop, name) end
        end
        if root and root.CreateRadio then
          root:CreateRadio(name, IsSelected, SetSelected)
        elseif root and root.CreateButton then
          root:CreateButton(name, SetSelected)
        end
      end
    end)

    local modernItemsLevelOp = UseModernMenuDropDown(itemsLevelOpDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Player level") end
      local opts = {
        { "Off", nil },
        { "<", "<" },
        { "<=", "<=" },
        { "=", "=" },
        { ">=", ">=" },
        { ">", ">" },
        { "!=", "!=" },
      }
      for _, opt in ipairs(opts) do
        local name, op = opt[1], opt[2]
        local function IsSelected() return (pItems._playerLevelOp == op) end
        local function SetSelected()
          pItems._playerLevelOp = op
          if UDDM_SetText then UDDM_SetText(pItems._itemsLevelOpDrop, name) end
        end
        if root and root.CreateRadio then
          root:CreateRadio(name, IsSelected, SetSelected)
        elseif root and root.CreateButton then
          root:CreateButton(name, SetSelected)
        end
      end
    end)

    if not modernItemsFrame then
      UDDM_Initialize(itemsFrameDrop, function(self, level)
        for _, def in ipairs(GetEffectiveFrames()) do
          if type(def) == "table" and def.id then
            local id = tostring(def.id)
            local info = UDDM_CreateInfo()
            info.text = GetFrameDisplayNameByID(id)
            info.checked = (pItems._targetFrameID == id) and true or false
            info.func = function()
              pItems._targetFrameID = id
              if UDDM_SetText then UDDM_SetText(pItems._itemsFrameDrop, GetFrameDisplayNameByID(id)) end
            end
            UDDM_AddButton(info)
          end
        end
      end)
    end

    if not modernItemsFaction then
      UDDM_Initialize(itemsFactionDrop, function(self, level)
        do
          local info = UDDM_CreateInfo()
          info.text = "Both (Off)"
          info.checked = (pItems._faction == nil) and true or false
          info.func = function()
            pItems._faction = nil
            if UDDM_SetText then UDDM_SetText(pItems._itemsFactionDrop, "Both (Off)") end
          end
          UDDM_AddButton(info)
        end
        do
          local info = UDDM_CreateInfo()
          info.text = "Alliance"
          info.checked = (pItems._faction == "Alliance") and true or false
          info.func = function()
            pItems._faction = "Alliance"
            if UDDM_SetText then UDDM_SetText(pItems._itemsFactionDrop, "Alliance") end
          end
          UDDM_AddButton(info)
        end
        do
          local info = UDDM_CreateInfo()
          info.text = "Horde"
          info.checked = (pItems._faction == "Horde") and true or false
          info.func = function()
            pItems._faction = "Horde"
            if UDDM_SetText then UDDM_SetText(pItems._itemsFactionDrop, "Horde") end
          end
          UDDM_AddButton(info)
        end
      end)
    end

    if not modernItemsColor then
      UDDM_Initialize(itemsColorDrop, function(self, level)
        for _, name in ipairs({ "None", "Green", "Blue", "Yellow", "Red", "Cyan" }) do
          local info = UDDM_CreateInfo()
          info.text = name
          info.func = function() SetItemsColor(name) end
          UDDM_AddButton(info)
        end
      end)
    end

    if not modernItemsRepMin then
      UDDM_Initialize(repMinDrop, function(self, level)
        local function Add(name, standing)
          local info = UDDM_CreateInfo()
          info.text = name
          info.checked = (pItems._repMinStanding == standing) and true or false
          info.func = function()
            pItems._repMinStanding = standing
            if UDDM_SetText then UDDM_SetText(pItems._repMinDrop, name) end
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

    if not modernItemsLevelOp then
      UDDM_Initialize(itemsLevelOpDrop, function(self, level)
        local function Add(name, op)
          local info = UDDM_CreateInfo()
          info.text = name
          info.checked = (pItems._playerLevelOp == op) and true or false
          info.func = function()
            pItems._playerLevelOp = op
            if UDDM_SetText then UDDM_SetText(pItems._itemsLevelOpDrop, name) end
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
  end

  local addItemBtn = CreateFrame("Button", nil, pItems, "UIPanelButtonTemplate")
  addItemBtn:SetSize(140, 22)
  addItemBtn:SetPoint("TOPLEFT", 12, -342)
  addItemBtn:SetText("Add Item Entry")

  pItems._repFactionBox = repFactionBox
  pItems._repMinDrop = repMinDrop
  pItems._hideAcquired = hideAcquired
  pItems._hideExalted = hideExalted
  pItems._sellExalted = sellExalted
  pItems._restedOnly = restedOnly
  pItems._locBox = itemsLocBox
  pItems._itemsFrameDrop = itemsFrameDrop
  pItems._itemsFactionDrop = itemsFactionDrop
  pItems._itemsColorDrop = itemsColorDrop
  pItems._itemsLevelOpDrop = itemsLevelOpDrop
  pItems._itemsLevelBox = itemsLevelBox
  pItems._addItemBtn = addItemBtn

  local cancelItemEditBtn = CreateFrame("Button", nil, pItems, "UIPanelButtonTemplate")
  cancelItemEditBtn:SetSize(120, 22)
  cancelItemEditBtn:SetPoint("LEFT", addItemBtn, "RIGHT", 8, 0)
  cancelItemEditBtn:SetText("Cancel Edit")
  cancelItemEditBtn:Hide()
  pItems._cancelEditBtn = cancelItemEditBtn

  local function ClearItemsInputs()
    pItems._pendingItemLabelID = nil
    pItems._pendingItemLabelForce = nil
    if itemIDBox then itemIDBox:SetText("") end
    if itemNameBox then
      itemNameBox._autoName = nil
      itemNameBox:SetText("")
    end
    if itemInfoBox then
      itemInfoBox._autoInfo = nil
      itemInfoBox:SetText("")
    end
    if itemInfoScroll and itemInfoScroll.SetVerticalScroll then itemInfoScroll:SetVerticalScroll(0) end
    if itemQuestIDBox then itemQuestIDBox:SetText("") end
    if itemAfterQuestIDBox then itemAfterQuestIDBox:SetText("") end
    if itemCurrencyIDBox then itemCurrencyIDBox:SetText("") end
    if itemCurrencyReqBox then itemCurrencyReqBox:SetText("") end
    if itemShowBelowBox then itemShowBelowBox:SetText("") end

    pItems._targetFrameID = "list1"
    if UDDM_SetText and itemsFrameDrop then UDDM_SetText(itemsFrameDrop, GetFrameDisplayNameByID("list1")) end

    pItems._faction = nil
    if UDDM_SetText and itemsFactionDrop then UDDM_SetText(itemsFactionDrop, "Both (Off)") end

    pItems._color = nil
    if UDDM_SetText and itemsColorDrop then UDDM_SetText(itemsColorDrop, "None") end

    pItems._repMinStanding = nil
    if repFactionBox then repFactionBox:SetText("") end
    if UDDM_SetText and repMinDrop then UDDM_SetText(repMinDrop, "Off") end
    if hideAcquired then hideAcquired:SetChecked(false) end
    if hideExalted then hideExalted:SetChecked(false) end
    if sellExalted then sellExalted:SetChecked(false) end
    if restedOnly then restedOnly:SetChecked(false) end
    if itemsLocBox then itemsLocBox:SetText("0") end

    pItems._playerLevelOp = nil
    if UDDM_SetText and itemsLevelOpDrop then UDDM_SetText(itemsLevelOpDrop, "Off") end
    if itemsLevelBox then itemsLevelBox:SetText("0") end

    pItems._editingCustomIndex = nil
    pItems._editingDefaultBase = nil
    pItems._editingDefaultKey = nil
    if addItemBtn then addItemBtn:SetText("Add Item Entry") end
    if cancelItemEditBtn then cancelItemEditBtn:Hide() end
  end

  addItemBtn:SetScript("OnClick", function()
    local itemID = tonumber(itemIDBox:GetText() or "")
    if not itemID or itemID <= 0 then
      Print("Enter an itemID > 0.")
      return
    end

    local questIDGate = tonumber(itemQuestIDBox:GetText() or "")
    if questIDGate and questIDGate <= 0 then questIDGate = nil end
    local afterQuestIDGate = tonumber(itemAfterQuestIDBox:GetText() or "")
    if afterQuestIDGate and afterQuestIDGate <= 0 then afterQuestIDGate = nil end

    local currencyIDGate = tonumber(itemCurrencyIDBox:GetText() or "")
    if currencyIDGate and currencyIDGate <= 0 then currencyIDGate = nil end
    local currencyReqGate = tonumber(itemCurrencyReqBox:GetText() or "")
    if currencyReqGate and currencyReqGate <= 0 then currencyReqGate = nil end
    if currencyIDGate and not currencyReqGate then
      Print("Enter a currency amount (MinCur) or clear CurrencyID.")
      return
    end
    if currencyReqGate and not currencyIDGate then
      Print("Enter a CurrencyID or clear MinCur.")
      return
    end

    local showWhenBelow = tonumber(itemShowBelowBox and itemShowBelowBox:GetText() or "")
    if showWhenBelow and showWhenBelow <= 0 then showWhenBelow = nil end

    local targetFrame = tostring(panels.items._targetFrameID or ""):gsub("%s+", "")
    if targetFrame == "" then targetFrame = "list1" end

    local repFactionID = tonumber(repFactionBox:GetText() or "")
    if repFactionID and repFactionID <= 0 then repFactionID = nil end

    local labelText = tostring(itemNameBox:GetText() or "")
    labelText = labelText:gsub("^%s+", ""):gsub("%s+$", "")
    local itemName = GetItemNameSafe(itemID)
    local label = nil
    if labelText ~= "" and not (type(itemName) == "string" and itemName ~= "" and labelText == itemName) then
      label = labelText
    end

    local infoText = tostring(itemInfoBox:GetText() or "")
    infoText = infoText:gsub("^%s+", ""):gsub("%s+$", "")
    local itemInfo = (infoText ~= "") and infoText or nil

    local rep = nil
    if repFactionID then
      rep = { factionID = repFactionID }
      if panels.items._repMinStanding then
        rep.minStanding = panels.items._repMinStanding
      end
      if hideExalted:GetChecked() then
        rep.hideWhenExalted = true
      end
      if sellExalted:GetChecked() then
        rep.sellWhenExalted = true
        rep.hideWhenExalted = nil
      end
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
      rule.itemInfo = itemInfo
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
      rule.item.questID = questIDGate
      rule.item.afterQuestID = afterQuestIDGate
      rule.item.currencyID = currencyIDGate
      rule.item.currencyRequired = currencyReqGate
      rule.item.showWhenBelow = showWhenBelow
      if rule.hideWhenCompleted == nil then rule.hideWhenCompleted = false end

      panels.items._editingCustomIndex = nil
      panels.items._editingDefaultBase = nil
      panels.items._editingDefaultKey = nil
      addItemBtn:SetText("Add Item Entry")
      cancelItemEditBtn:Hide()
      Print("Saved item entry.")
    elseif panels.items._editingDefaultBase and panels.items._editingDefaultKey and ns and ns.GetDefaultRuleEdits then
      local edits = ns.GetDefaultRuleEdits()
      local base = panels.items._editingDefaultBase
      local key = tostring(panels.items._editingDefaultKey)
      local effective = (type(edits[key]) == "table") and edits[key] or base
      local rule = DeepCopyValue(effective)

      rule.frameID = targetFrame
      rule.faction = panels.items._faction
      rule.color = panels.items._color
      rule.restedOnly = restedOnly:GetChecked() and true or false
      rule.label = label
      rule.itemInfo = itemInfo
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
      rule.item.questID = questIDGate
      rule.item.afterQuestID = afterQuestIDGate
      rule.item.currencyID = currencyIDGate
      rule.item.currencyRequired = currencyReqGate
      rule.item.showWhenBelow = showWhenBelow
      if rule.hideWhenCompleted == nil then rule.hideWhenCompleted = false end

      if base and base.key ~= nil then rule.key = tostring(base.key) end
      edits[key] = rule

      panels.items._editingCustomIndex = nil
      panels.items._editingDefaultBase = nil
      panels.items._editingDefaultKey = nil
      addItemBtn:SetText("Add Item Entry")
      cancelItemEditBtn:Hide()
      Print("Saved default item rule edit.")
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
        itemInfo = itemInfo,
        rep = rep,
        locationID = locationID,
        playerLevelOp = op,
        playerLevel = lvl,
        item = {
          itemID = itemID,
          required = 1,
          hideWhenAcquired = hideAcquired:GetChecked() and true or false,
          questID = questIDGate,
          afterQuestID = afterQuestIDGate,
          currencyID = currencyIDGate,
          currencyRequired = currencyReqGate,
          showWhenBelow = showWhenBelow,
        },
        hideWhenCompleted = false,
      }

      Print("Added item entry for item " .. itemID .. " -> " .. targetFrame)
    end

    CreateAllFrames()
    RefreshAll()
    RefreshRulesList()
    if not GetKeepEditFormOpen() then
      ClearItemsInputs()
      SelectTab("rules")
    end
  end)

  cancelItemEditBtn:SetScript("OnClick", function()
    pItems._editingCustomIndex = nil
    pItems._editingDefaultBase = nil
    pItems._editingDefaultKey = nil
    addItemBtn:SetText("Add Item Entry")
    cancelItemEditBtn:Hide()

    if not GetKeepEditFormOpen() then
      ClearItemsInputs()
      SelectTab("rules")
    end
  end)

  end

    end

  end

  -- TEXT tab (Text module)
  local useTextModule = type(ns) == "table" and type(ns.FQTOptionsPanels) == "table" and type(ns.FQTOptionsPanels.BuildText) == "function"
  if useTextModule then
    ns.FQTOptionsPanels.BuildText(GetOptionsCtx())
  else
    -- Legacy Text tab UI moved to fr0z3nUI_QuestTrackerText.lua
    if false then
  do
  local textTitle = panels.text:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  textTitle:SetPoint("TOPLEFT", 12, -40)
  textTitle:SetText("Text")

  local function EnsureCalendarPopout()
    if not f then return nil end
    if f._calendarPopout then return f._calendarPopout end

    local pop = CreateFrame("Frame", nil, f, "BackdropTemplate")
    pop:SetSize(540, 360)
    pop:SetPoint("CENTER", f, "CENTER", 0, 0)
    pop:SetFrameStrata("DIALOG")
    pop:SetClampedToScreen(true)
    ApplyFAOBackdrop(pop, 0.92)
    pop:Hide()

    local title = pop:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 12, -10)
    title:SetText("Calendar")
    pop._title = title

    local close = CreateFrame("Button", nil, pop, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", pop, "TOPRIGHT", 2, 2)
    close:SetScript("OnClick", function() pop:Hide() end)

    local hint = pop:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", 12, -34)
    hint:SetText("Click Copy then Ctrl+C. Shift+Copy includes holiday text.")

    local refreshBtn = CreateFrame("Button", nil, pop, "UIPanelButtonTemplate")
    refreshBtn:SetSize(70, 20)
    refreshBtn:SetPoint("TOPRIGHT", pop, "TOPRIGHT", -34, -34)
    refreshBtn:SetText("Refresh")

    local scroll = CreateFrame("ScrollFrame", nil, pop, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -58)
    scroll:SetSize(516, 210)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)
    pop._scroll = scroll
    pop._content = content

    local rowH = 18
    local rows = {}
    pop._rows = rows
    pop._events = {}

    local function SetCopyText(text)
      if not pop._copyBox then return end
      pop._copyBox:SetText(tostring(text or ""))
      if pop._copyBox.HighlightText then pop._copyBox:HighlightText() end
      if pop._copyBox.SetFocus then pop._copyBox:SetFocus() end
    end

    local function GetRelLabel(relDay)
      relDay = tonumber(relDay) or 0
      if relDay == 0 then return "Today" end
      if relDay == 1 then return "+1" end
      if relDay == -1 then return "-1" end
      return (relDay > 0) and ("+" .. tostring(relDay)) or tostring(relDay)
    end

    local function EnsureRow(i)
      if rows[i] then return rows[i] end
      local r = CreateFrame("Button", nil, content)
      r:SetHeight(rowH)
      r:SetPoint("TOPLEFT", 0, -((i - 1) * rowH))
      r:SetPoint("TOPRIGHT", 0, -((i - 1) * rowH))

      local rel = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
      rel:SetPoint("LEFT", 2, 0)
      rel:SetWidth(36)
      rel:SetJustifyH("LEFT")
      r._rel = rel

      local txt = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      txt:SetPoint("LEFT", rel, "RIGHT", 6, 0)
      txt:SetPoint("RIGHT", r, "RIGHT", -70, 0)
      txt:SetJustifyH("LEFT")
      txt:SetWordWrap(false)
      r._text = txt

      local copyBtn = CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
      copyBtn:SetSize(56, 18)
      copyBtn:SetPoint("RIGHT", -6, 0)
      copyBtn:SetText("Copy")
      r._copy = copyBtn

      local function DoCopy()
        local ev = r._event
        if type(ev) ~= "table" then return end
        local titleText = tostring(ev.title or "")
        local holidayText = tostring(ev.holidayText or "")
        if IsShiftKeyDown and IsShiftKeyDown() and holidayText ~= "" then
          SetCopyText(titleText .. "\n" .. holidayText)
        else
          SetCopyText(titleText)
        end
      end

      r:SetScript("OnClick", DoCopy)
      copyBtn:SetScript("OnClick", DoCopy)

      r:SetScript("OnEnter", function()
        local ev = r._event
        if type(ev) ~= "table" then return end
        if not GameTooltip then return end
        GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
        local t = tostring(ev.title or "")
        local h = tostring(ev.holidayText or "")
        if t ~= "" then GameTooltip:AddLine(t, 1, 1, 1, true) end
        if h ~= "" then GameTooltip:AddLine(h, 0.8, 0.8, 0.8, true) end
        GameTooltip:Show()
      end)
      r:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

      rows[i] = r
      return r
    end

    local function Render()
      local events = {}
      local meta = nil
      if type(GetCalendarDebugEvents) == "function" then
        events, meta = GetCalendarDebugEvents(1, 14)
      end
      if type(events) ~= "table" then events = {} end
      pop._events = events

      if pop._title and pop._title.SetText then
        if type(meta) == "table" and meta.ok and meta.today then
          pop._title:SetText(string.format("Calendar (Day %d)", tonumber(meta.today) or 0))
        else
          pop._title:SetText("Calendar")
        end
      end

      local n = #events
      content:SetHeight(math.max(1, n * rowH))
      for i = 1, n do
        local ev = events[i]
        local r = EnsureRow(i)
        r._event = ev
        if r._rel and r._rel.SetText then r._rel:SetText(GetRelLabel(ev.relDay)) end
        if r._text and r._text.SetText then
          local t = tostring(ev.title or "")
          if t == "" then t = "(no title)" end
          r._text:SetText(t)
        end
        r:Show()
      end
      for i = n + 1, #rows do
        if rows[i] then rows[i]:Hide() end
      end
    end

    refreshBtn:SetScript("OnClick", Render)
    pop._render = Render

    local copyAllBtn = CreateFrame("Button", nil, pop, "UIPanelButtonTemplate")
    copyAllBtn:SetSize(90, 20)
    copyAllBtn:SetPoint("TOPLEFT", 12, -272)
    copyAllBtn:SetText("Copy All")
    copyAllBtn:SetScript("OnClick", function()
      local out = {}
      for _, ev in ipairs(pop._events or {}) do
        local t = tostring(ev.title or "")
        local h = tostring(ev.holidayText or "")
        if IsShiftKeyDown and IsShiftKeyDown() and h ~= "" then
          out[#out + 1] = t .. "\n" .. h
        else
          out[#out + 1] = t
        end
      end
      SetCopyText(table.concat(out, "\n\n"))
    end)

    local copyScroll = CreateFrame("ScrollFrame", nil, pop, "UIPanelScrollFrameTemplate")
    copyScroll:SetPoint("TOPLEFT", 12, -296)
    copyScroll:SetSize(516, 52)

    local copyBox = CreateFrame("EditBox", nil, copyScroll)
    copyBox:SetMultiLine(true)
    copyBox:SetAutoFocus(false)
    copyBox:SetFontObject("ChatFontNormal")
    copyBox:SetWidth(480)
    copyBox:SetTextInsets(6, 6, 6, 6)
    copyBox:SetText("")
    copyBox:SetScript("OnEscapePressed", function(self)
      self:ClearFocus()
      pop:Hide()
    end)
    copyBox:SetScript("OnEditFocusGained", function(self)
      if self.HighlightText then self:HighlightText() end
    end)
    copyScroll:SetScrollChild(copyBox)

    pop._copyBox = copyBox

    f._calendarPopout = pop
    return pop
  end

  local calendarBtn = CreateFrame("Button", nil, panels.text, "UIPanelButtonTemplate")
  calendarBtn:SetSize(90, 20)
  calendarBtn:SetPoint("TOPRIGHT", panels.text, "TOPRIGHT", -12, -38)
  calendarBtn:SetText("Calendar")
  calendarBtn:SetScript("OnClick", function()
    local pop = EnsureCalendarPopout()
    if not pop then return end
    if pop.IsShown and pop:IsShown() then
      pop:Hide()
      return
    end
    pop:Show()
    if pop._render then pop._render() end
  end)

  local textNameBox = CreateFrame("EditBox", nil, panels.text, "InputBoxTemplate")
  textNameBox:SetSize(530, 20)
  textNameBox:SetPoint("TOPLEFT", 12, -70)
  textNameBox:SetAutoFocus(false)
  textNameBox:SetText("")
  textNameBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  textNameBox:SetTextInsets(6, 6, 0, 0)
  AddPlaceholder(textNameBox, "Text Name")
  HideInputBoxTemplateArt(textNameBox)

  local textInfoScroll = CreateFrame("ScrollFrame", nil, panels.text, "UIPanelScrollFrameTemplate")
  textInfoScroll:SetPoint("TOPLEFT", 12, -94)
  textInfoScroll:SetSize(530, 46)

  local textInfoBox = CreateFrame("EditBox", nil, textInfoScroll)
  textInfoBox:SetMultiLine(true)
  textInfoBox:SetAutoFocus(false)
  textInfoBox:SetFontObject("ChatFontNormal")
  textInfoBox:SetWidth(500)
  textInfoBox:SetTextInsets(6, 6, 6, 6)
  textInfoBox:SetText("")
  textInfoBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  textInfoBox:SetScript("OnCursorChanged", function(self, x, y, w, h)
    if not textInfoScroll then return end
    textInfoScroll:UpdateScrollChildRect()
    local offset = textInfoScroll:GetVerticalScroll() or 0
    local height = textInfoScroll:GetHeight() or 0
    local top = -y
    if top < offset then
      textInfoScroll:SetVerticalScroll(top)
    elseif top > offset + height - 20 then
      textInfoScroll:SetVerticalScroll(top - height + 20)
    end
  end)

  textInfoScroll:SetScrollChild(textInfoBox)
  AddPlaceholder(textInfoBox, "Text Info")

  panels.text._textInfoScroll = textInfoScroll

  local textFrameDrop = CreateFrame("Frame", nil, panels.text, "UIDropDownMenuTemplate")
  textFrameDrop:SetPoint("TOPLEFT", -8, -164)
  if UDDM_SetWidth then UDDM_SetWidth(textFrameDrop, 160) end
  if UDDM_SetText then UDDM_SetText(textFrameDrop, GetFrameDisplayNameByID("list1")) end
  panels.text._targetFrameID = "list1"

  local textFactionDrop = CreateFrame("Frame", nil, panels.text, "UIDropDownMenuTemplate")
  textFactionDrop:SetPoint("TOPLEFT", 165, -164)
  if UDDM_SetWidth then UDDM_SetWidth(textFactionDrop, 140) end
  if UDDM_SetText then UDDM_SetText(textFactionDrop, "Both (Off)") end
  panels.text._faction = nil

  local textColorDrop = CreateFrame("Frame", nil, panels.text, "UIDropDownMenuTemplate")
  textColorDrop:SetPoint("TOPLEFT", 325, -164)
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
  textRepFactionBox:SetPoint("TOPLEFT", 12, -220)
  textRepFactionBox:SetAutoFocus(false)
  textRepFactionBox:SetNumeric(true)
  textRepFactionBox:SetText("0")

  local textRepMinDrop = CreateFrame("Frame", nil, panels.text, "UIDropDownMenuTemplate")
  textRepMinDrop:SetPoint("TOPLEFT", 95, -232)
  if UDDM_SetWidth then UDDM_SetWidth(textRepMinDrop, 140) end
  if UDDM_SetText then UDDM_SetText(textRepMinDrop, "Off") end
  panels.text._repMinStanding = nil

  local textRestedOnly = CreateFrame("CheckButton", nil, panels.text, "UICheckButtonTemplate")
  textRestedOnly:SetPoint("TOPLEFT", 250, -246)
  SetCheckButtonLabel(textRestedOnly, "Rested areas only")
  textRestedOnly:SetChecked(false)

  local textLocLabel = panels.text:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  textLocLabel:SetPoint("TOPLEFT", 250, -206)
  textLocLabel:SetText("LocationID (uiMapID)")

  local textLocBox = CreateFrame("EditBox", nil, panels.text, "InputBoxTemplate")
  textLocBox:SetSize(90, 20)
  textLocBox:SetPoint("TOPLEFT", 250, -222)
  textLocBox:SetAutoFocus(false)
  textLocBox:SetText("0")
  AttachLocationIDTooltip(textLocBox)

  local textLevelLabel = panels.text:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  textLevelLabel:SetPoint("TOPLEFT", 400, -206)
  textLevelLabel:SetText("Player level")

  local textLevelOpDrop = CreateFrame("Frame", nil, panels.text, "UIDropDownMenuTemplate")
  textLevelOpDrop:SetPoint("TOPLEFT", 385, -226)
  if UDDM_SetWidth then UDDM_SetWidth(textLevelOpDrop, 70) end
  if UDDM_SetText then UDDM_SetText(textLevelOpDrop, "Off") end
  panels.text._playerLevelOp = nil

  local textLevelBox = CreateFrame("EditBox", nil, panels.text, "InputBoxTemplate")
  textLevelBox:SetSize(50, 20)
  textLevelBox:SetPoint("TOPLEFT", 490, -222)
  textLevelBox:SetAutoFocus(false)
  textLevelBox:SetNumeric(true)
  textLevelBox:SetText("0")

  if UDDM_Initialize and UDDM_CreateInfo and UDDM_AddButton then
    local function ColorsMatch(tbl, r, g, b)
      if type(tbl) ~= "table" then return false end
      return (tonumber(tbl[1]) == r) and (tonumber(tbl[2]) == g) and (tonumber(tbl[3]) == b)
    end

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

    local modernTextFrame = UseModernMenuDropDown(textFrameDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Bar / List") end
      for _, def in ipairs(GetEffectiveFrames()) do
        if type(def) == "table" and def.id and root then
          local id = tostring(def.id)
          local label = GetFrameDisplayNameByID(id)
          if root.CreateRadio then
            root:CreateRadio(label, function() return (panels.text._targetFrameID == id) end, function()
              panels.text._targetFrameID = id
              if UDDM_SetText then UDDM_SetText(textFrameDrop, GetFrameDisplayNameByID(id)) end
            end)
          elseif root.CreateButton then
            root:CreateButton(label, function()
              panels.text._targetFrameID = id
              if UDDM_SetText then UDDM_SetText(textFrameDrop, GetFrameDisplayNameByID(id)) end
            end)
          end
        end
      end
    end)

    local modernTextFaction = UseModernMenuDropDown(textFactionDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Faction") end
      local function Add(name, v)
        if not root then return end
        if root.CreateRadio then
          root:CreateRadio(name, function() return (panels.text._faction == v) end, function()
            panels.text._faction = v
            if UDDM_SetText then UDDM_SetText(textFactionDrop, name) end
          end)
        elseif root.CreateButton then
          root:CreateButton(name, function()
            panels.text._faction = v
            if UDDM_SetText then UDDM_SetText(textFactionDrop, name) end
          end)
        end
      end
      Add("Both (Off)", nil)
      Add("Alliance", "Alliance")
      Add("Horde", "Horde")
    end)

    local modernTextColor = UseModernMenuDropDown(textColorDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Color") end
      local opts = {
        { "None", nil },
        { "Green", { 0.1, 1.0, 0.1 } },
        { "Blue", { 0.2, 0.6, 1.0 } },
        { "Yellow", { 1.0, 0.9, 0.2 } },
        { "Red", { 1.0, 0.2, 0.2 } },
        { "Cyan", { 0.2, 1.0, 1.0 } },
      }
      for _, opt in ipairs(opts) do
        local name, c = opt[1], opt[2]
        local function IsSelected()
          if name == "None" then return panels.text._color == nil end
          if not c then return false end
          return ColorsMatch(panels.text._color, c[1], c[2], c[3])
        end
        local function SetSelected()
          SetTextColor(name)
        end
        if root and root.CreateRadio then
          root:CreateRadio(name, IsSelected, SetSelected)
        elseif root and root.CreateButton then
          root:CreateButton(name, SetSelected)
        end
      end
    end)

    local modernTextRepMin = UseModernMenuDropDown(textRepMinDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Min Rep") end
      local opts = {
        { "Off", nil },
        { "Friendly", 5 },
        { "Honored", 6 },
        { "Revered", 7 },
        { "Exalted", 8 },
      }
      for _, opt in ipairs(opts) do
        local name, standing = opt[1], opt[2]
        local function IsSelected() return (panels.text._repMinStanding == standing) end
        local function SetSelected()
          panels.text._repMinStanding = standing
          if UDDM_SetText then UDDM_SetText(textRepMinDrop, name) end
        end
        if root and root.CreateRadio then
          root:CreateRadio(name, IsSelected, SetSelected)
        elseif root and root.CreateButton then
          root:CreateButton(name, SetSelected)
        end
      end
    end)

    local modernTextLevelOp = UseModernMenuDropDown(textLevelOpDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Player level") end
      local opts = {
        { "Off", nil },
        { "<", "<" },
        { "<=", "<=" },
        { "=", "=" },
        { ">=", ">=" },
        { ">", ">" },
        { "!=", "!=" },
      }
      for _, opt in ipairs(opts) do
        local name, op = opt[1], opt[2]
        local function IsSelected() return (panels.text._playerLevelOp == op) end
        local function SetSelected()
          panels.text._playerLevelOp = op
          if UDDM_SetText then UDDM_SetText(textLevelOpDrop, name) end
        end
        if root and root.CreateRadio then
          root:CreateRadio(name, IsSelected, SetSelected)
        elseif root and root.CreateButton then
          root:CreateButton(name, SetSelected)
        end
      end
    end)

    if not modernTextFrame then
      UDDM_Initialize(textFrameDrop, function(self, level)
        for _, def in ipairs(GetEffectiveFrames()) do
          if type(def) == "table" and def.id then
            local id = tostring(def.id)
            local info = UDDM_CreateInfo()
            info.text = GetFrameDisplayNameByID(id)
            info.checked = (panels.text._targetFrameID == id) and true or false
            info.func = function()
              panels.text._targetFrameID = id
              if UDDM_SetText then UDDM_SetText(textFrameDrop, GetFrameDisplayNameByID(id)) end
            end
            UDDM_AddButton(info)
          end
        end
      end)
    end

    if not modernTextFaction then
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
    end

    if not modernTextColor then
      UDDM_Initialize(textColorDrop, function(self, level)
        for _, name in ipairs({ "None", "Green", "Blue", "Yellow", "Red", "Cyan" }) do
          local info = UDDM_CreateInfo()
          info.text = name
          info.func = function() SetTextColor(name) end
          UDDM_AddButton(info)
        end
      end)
    end

    if not modernTextRepMin then
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

    if not modernTextLevelOp then
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
  end

  local addTextBtn = CreateFrame("Button", nil, panels.text, "UIPanelButtonTemplate")
  addTextBtn:SetSize(140, 22)
  addTextBtn:SetPoint("TOPLEFT", 12, -286)
  addTextBtn:SetText("Add Text Entry")

  panels.text._textNameBox = textNameBox
  panels.text._textInfoBox = textInfoBox
  panels.text._textFrameDrop = textFrameDrop
  panels.text._textFactionDrop = textFactionDrop
  panels.text._textColorDrop = textColorDrop
  panels.text._repFactionBox = textRepFactionBox
  panels.text._repMinDrop = textRepMinDrop
  panels.text._restedOnly = textRestedOnly
  panels.text._locBox = textLocBox
  panels.text._textLevelOpDrop = textLevelOpDrop
  panels.text._textLevelBox = textLevelBox
  panels.text._addTextBtn = addTextBtn

  local cancelTextEditBtn = CreateFrame("Button", nil, panels.text, "UIPanelButtonTemplate")
  cancelTextEditBtn:SetSize(120, 22)
  cancelTextEditBtn:SetPoint("LEFT", addTextBtn, "RIGHT", 8, 0)
  cancelTextEditBtn:SetText("Cancel Edit")
  cancelTextEditBtn:Hide()
  panels.text._cancelEditBtn = cancelTextEditBtn

  local function ClearTextInputs()
    if textNameBox then textNameBox:SetText("") end
    if textInfoBox then textInfoBox:SetText("") end
    if textInfoScroll and textInfoScroll.SetVerticalScroll then textInfoScroll:SetVerticalScroll(0) end

    panels.text._targetFrameID = "list1"
    if UDDM_SetText and textFrameDrop then UDDM_SetText(textFrameDrop, GetFrameDisplayNameByID("list1")) end

    panels.text._faction = nil
    if UDDM_SetText and textFactionDrop then UDDM_SetText(textFactionDrop, "Both (Off)") end

    panels.text._color = nil
    if UDDM_SetText and textColorDrop then UDDM_SetText(textColorDrop, "None") end

    if textRepFactionBox then textRepFactionBox:SetText("0") end
    panels.text._repMinStanding = nil
    if UDDM_SetText and textRepMinDrop then UDDM_SetText(textRepMinDrop, "Off") end

    if textRestedOnly then textRestedOnly:SetChecked(false) end
    if textLocBox then textLocBox:SetText("0") end

    panels.text._playerLevelOp = nil
    if UDDM_SetText and textLevelOpDrop then UDDM_SetText(textLevelOpDrop, "Off") end
    if textLevelBox then textLevelBox:SetText("0") end

    panels.text._editingCustomIndex = nil
    panels.text._editingDefaultBase = nil
    panels.text._editingDefaultKey = nil
    if addTextBtn then addTextBtn:SetText("Add Text Entry") end
    if cancelTextEditBtn then cancelTextEditBtn:Hide() end
  end

  addTextBtn:SetScript("OnClick", function()
    local nameText = tostring(textNameBox:GetText() or "")
    nameText = nameText:gsub("^%s+", ""):gsub("%s+$", "")
    if nameText == "" then
      Print("Enter a Text Name.")
      return
    end

    local infoText = tostring(textInfoBox:GetText() or "")
    infoText = infoText:gsub("^%s+", ""):gsub("%s+$", "")
    local textInfo = (infoText ~= "" and infoText ~= nameText) and infoText or nil

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
      rule.label = nameText
      rule.textInfo = textInfo
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
      panels.text._editingDefaultBase = nil
      panels.text._editingDefaultKey = nil
      addTextBtn:SetText("Add Text Entry")
      cancelTextEditBtn:Hide()
      Print("Saved text entry.")
    elseif panels.text._editingDefaultBase and panels.text._editingDefaultKey and ns and ns.GetDefaultRuleEdits then
      local edits = ns.GetDefaultRuleEdits()
      local base = panels.text._editingDefaultBase
      local key = tostring(panels.text._editingDefaultKey)
      local effective = (type(edits[key]) == "table") and edits[key] or base
      local rule = DeepCopyValue(effective)

      rule.frameID = targetFrame
      rule.label = nameText
      rule.textInfo = textInfo
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
      if base and base.key ~= nil then rule.key = tostring(base.key) end
      edits[key] = rule

      panels.text._editingCustomIndex = nil
      panels.text._editingDefaultBase = nil
      panels.text._editingDefaultKey = nil
      addTextBtn:SetText("Add Text Entry")
      cancelTextEditBtn:Hide()
      Print("Saved default text rule edit.")
    else
      local key = string.format("custom:text:%s:%s:%d", tostring(targetFrame), tostring(nameText), (#rules + 1))
      local op = panels.text._playerLevelOp
      local lvl = textLevelBox and tonumber(textLevelBox:GetText() or "") or nil
      if lvl and lvl <= 0 then lvl = nil end
      if not (op and lvl) then op = nil; lvl = nil end
      rules[#rules + 1] = {
        key = key,
        frameID = targetFrame,
        label = nameText,
        textInfo = textInfo,
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
    if not GetKeepEditFormOpen() then
      ClearTextInputs()
      SelectTab("rules")
    end
  end)

  cancelTextEditBtn:SetScript("OnClick", function()
    panels.text._editingCustomIndex = nil
    panels.text._editingDefaultBase = nil
    panels.text._editingDefaultKey = nil
    addTextBtn:SetText("Add Text Entry")
    cancelTextEditBtn:Hide()

    if not GetKeepEditFormOpen() then
      ClearTextInputs()
      SelectTab("rules")
    end
  end)

  end

    end

  end

  -- SPELLS tab (Spells module)
  do
    local useSpellsModule = type(ns) == "table" and type(ns.FQTOptionsPanels) == "table" and type(ns.FQTOptionsPanels.BuildSpells) == "function"
    if useSpellsModule then
      ns.FQTOptionsPanels.BuildSpells(GetOptionsCtx())
    else
      -- Legacy spells UI moved to fr0z3nUI_QuestTrackerSpells.lua
      if false then
  local spellsTitle = panels.spells:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  spellsTitle:SetPoint("TOPLEFT", 12, -40)
  spellsTitle:SetText("Spells")

  local spellsNameBox = CreateFrame("EditBox", nil, panels.spells, "InputBoxTemplate")
  spellsNameBox:SetSize(530, 20)
  spellsNameBox:SetPoint("TOPLEFT", 12, -70)
  spellsNameBox:SetAutoFocus(false)
  spellsNameBox:SetText("")
  spellsNameBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  spellsNameBox:SetTextInsets(6, 6, 0, 0)
  AddPlaceholder(spellsNameBox, "Spell Name")
  HideInputBoxTemplateArt(spellsNameBox)

  local spellsInfoScroll = CreateFrame("ScrollFrame", nil, panels.spells, "UIPanelScrollFrameTemplate")
  spellsInfoScroll:SetPoint("TOPLEFT", 12, -94)
  spellsInfoScroll:SetSize(530, 46)

  local spellsInfoBox = CreateFrame("EditBox", nil, spellsInfoScroll)
  spellsInfoBox:SetMultiLine(true)
  spellsInfoBox:SetAutoFocus(false)
  spellsInfoBox:SetFontObject("ChatFontNormal")
  spellsInfoBox:SetWidth(500)
  spellsInfoBox:SetTextInsets(6, 6, 6, 6)
  spellsInfoBox:SetText("")
  spellsInfoBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  spellsInfoBox:SetScript("OnCursorChanged", function(self, x, y, w, h)
    if not spellsInfoScroll then return end
    spellsInfoScroll:UpdateScrollChildRect()
    local offset = spellsInfoScroll:GetVerticalScroll() or 0
    local height = spellsInfoScroll:GetHeight() or 0
    local top = -y
    if top < offset then
      spellsInfoScroll:SetVerticalScroll(top)
    elseif top > offset + height - 20 then
      spellsInfoScroll:SetVerticalScroll(top - height + 20)
    end
  end)
  spellsInfoScroll:SetScrollChild(spellsInfoBox)
  AddPlaceholder(spellsInfoBox, "Spell Info")

  local classLabel = panels.spells:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  classLabel:SetPoint("TOPLEFT", 12, -146)
  classLabel:SetText("Class")

  local classDrop = CreateFrame("Frame", nil, panels.spells, "UIDropDownMenuTemplate")
  classDrop:SetPoint("TOPLEFT", -8, -174)
  if UDDM_SetWidth then UDDM_SetWidth(classDrop, 160) end
  if UDDM_SetText then UDDM_SetText(classDrop, "None") end
  panels.spells._class = nil
  panels.spells._classes = {}

  local SPELL_CLASS_TOKENS = {
    "DEATHKNIGHT","DEMONHUNTER","DRUID","EVOKER","HUNTER","MAGE","MONK","PALADIN","PRIEST","ROGUE","SHAMAN","WARLOCK","WARRIOR",
  }

  local function WipeTable(t)
    if type(t) ~= "table" then return end
    for k in pairs(t) do
      t[k] = nil
    end
  end

  local function GetSelectedSpellClasses()
    local out = {}
    if type(panels.spells._classes) ~= "table" then
      panels.spells._classes = {}
    end
    for _, tok in ipairs(SPELL_CLASS_TOKENS) do
      if panels.spells._classes[tok] then
        out[#out + 1] = tok
      end
    end
    return out
  end

  local function RefreshSpellClassDropText()
    if not (UDDM_SetText and classDrop) then return end
    local sel = GetSelectedSpellClasses()
    if #sel == 0 then
      UDDM_SetText(classDrop, "None")
    elseif #sel == 1 then
      UDDM_SetText(classDrop, sel[1])
    else
      UDDM_SetText(classDrop, string.format("Multi (%d)", #sel))
    end
  end

  local function SetSelectedSpellClassesFromRule(value)
    if type(panels.spells._classes) ~= "table" then
      panels.spells._classes = {}
    end
    WipeTable(panels.spells._classes)
    panels.spells._class = nil

    if type(value) == "string" then
      local tok = tostring(value):upper()
      if tok ~= "" and tok ~= "NONE" then
        panels.spells._classes[tok] = true
      end
    elseif type(value) == "table" then
      for _, v in ipairs(value) do
        local tok = tostring(v or ""):upper()
        if tok ~= "" and tok ~= "NONE" then
          panels.spells._classes[tok] = true
        end
      end
    end

    local sel = GetSelectedSpellClasses()
    if #sel == 1 then
      panels.spells._class = sel[1]
    end
    RefreshSpellClassDropText()
  end

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

  local spellsRestedOnlyCheck = CreateFrame("CheckButton", nil, panels.spells, "UICheckButtonTemplate")
  spellsRestedOnlyCheck:SetPoint("LEFT", notInGroupCheck, "RIGHT", 110, 0)
  SetCheckButtonLabel(spellsRestedOnlyCheck, "Rested")
  spellsRestedOnlyCheck:SetChecked(false)

  local spellsMissingProfCheck = CreateFrame("CheckButton", nil, panels.spells, "UICheckButtonTemplate")
  spellsMissingProfCheck:SetPoint("TOPLEFT", 12, -218)
  SetCheckButtonLabel(spellsMissingProfCheck, "Prof")
  spellsMissingProfCheck:SetChecked(false)
  spellsMissingProfCheck:SetScript("OnEnter", function(self)
    if not GameTooltip then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Primary Professions")
    GameTooltip:AddLine("Only show this spell rule if one or both primary professions are missing.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  spellsMissingProfCheck:SetScript("OnLeave", function()
    if GameTooltip then GameTooltip:Hide() end
  end)

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
  if UDDM_SetText then UDDM_SetText(spellsFrameDrop, GetFrameDisplayNameByID("list1")) end
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
    local function ColorsMatch(tbl, r, g, b)
      if type(tbl) ~= "table" then return false end
      return (tonumber(tbl[1]) == r) and (tonumber(tbl[2]) == g) and (tonumber(tbl[3]) == b)
    end

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

    local modernSpellsClass = UseModernMenuDropDown(classDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Class") end
      local function ToggleClass(tok)
        if type(panels.spells._classes) ~= "table" then panels.spells._classes = {} end
        if tok == "None" then
          WipeTable(panels.spells._classes)
          panels.spells._class = nil
          RefreshSpellClassDropText()
          return
        end
        panels.spells._classes[tok] = not panels.spells._classes[tok]
        local sel = GetSelectedSpellClasses()
        panels.spells._class = (#sel == 1) and sel[1] or nil
        RefreshSpellClassDropText()
      end

      if root and root.CreateButton then
        root:CreateButton("None", function() ToggleClass("None") end)
      end

      for _, tok in ipairs(SPELL_CLASS_TOKENS) do
        if root and root.CreateCheckbox then
          root:CreateCheckbox(tok, function() return panels.spells._classes and panels.spells._classes[tok] end, function()
            ToggleClass(tok)
          end)
        elseif root and root.CreateButton then
          root:CreateButton(tok, function()
            ToggleClass(tok)
          end)
        end
      end
    end)

    local modernSpellsFrame = UseModernMenuDropDown(spellsFrameDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Bar / List") end
      for _, def in ipairs(GetEffectiveFrames()) do
        if type(def) == "table" and def.id and root then
          local id = tostring(def.id)
          local label = GetFrameDisplayNameByID(id)
          if root.CreateRadio then
            root:CreateRadio(label, function() return (panels.spells._targetFrameID == id) end, function()
              panels.spells._targetFrameID = id
              if UDDM_SetText then UDDM_SetText(spellsFrameDrop, GetFrameDisplayNameByID(id)) end
            end)
          elseif root.CreateButton then
            root:CreateButton(label, function()
              panels.spells._targetFrameID = id
              if UDDM_SetText then UDDM_SetText(spellsFrameDrop, GetFrameDisplayNameByID(id)) end
            end)
          end
        end
      end
    end)

    local modernSpellsFaction = UseModernMenuDropDown(spellsFactionDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Faction") end
      local function Add(name, v)
        if not root then return end
        if root.CreateRadio then
          root:CreateRadio(name, function() return (panels.spells._faction == v) end, function()
            panels.spells._faction = v
            if UDDM_SetText then UDDM_SetText(spellsFactionDrop, name) end
          end)
        elseif root.CreateButton then
          root:CreateButton(name, function()
            panels.spells._faction = v
            if UDDM_SetText then UDDM_SetText(spellsFactionDrop, name) end
          end)
        end
      end
      Add("Both (Off)", nil)
      Add("Alliance", "Alliance")
      Add("Horde", "Horde")
    end)

    local modernSpellsColor = UseModernMenuDropDown(spellsColorDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Color") end
      local opts = {
        { "None", nil },
        { "Green", { 0.1, 1.0, 0.1 } },
        { "Blue", { 0.2, 0.6, 1.0 } },
        { "Yellow", { 1.0, 0.9, 0.2 } },
        { "Red", { 1.0, 0.2, 0.2 } },
        { "Cyan", { 0.2, 1.0, 1.0 } },
      }
      for _, opt in ipairs(opts) do
        local name, c = opt[1], opt[2]
        local function IsSelected()
          if name == "None" then return panels.spells._color == nil end
          if not c then return false end
          return ColorsMatch(panels.spells._color, c[1], c[2], c[3])
        end
        local function SetSelected()
          SetSpellsColor(name)
        end
        if root and root.CreateRadio then
          root:CreateRadio(name, IsSelected, SetSelected)
        elseif root and root.CreateButton then
          root:CreateButton(name, SetSelected)
        end
      end
    end)

    local modernSpellsLevelOp = UseModernMenuDropDown(spellsLevelOpDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Player level") end
      local opts = {
        { "Off", nil },
        { "<", "<" },
        { "<=", "<=" },
        { "=", "=" },
        { ">=", ">=" },
        { ">", ">" },
        { "!=", "!=" },
      }
      for _, opt in ipairs(opts) do
        local name, op = opt[1], opt[2]
        local function IsSelected() return (panels.spells._playerLevelOp == op) end
        local function SetSelected()
          panels.spells._playerLevelOp = op
          if UDDM_SetText then UDDM_SetText(spellsLevelOpDrop, name) end
        end
        if root and root.CreateRadio then
          root:CreateRadio(name, IsSelected, SetSelected)
        elseif root and root.CreateButton then
          root:CreateButton(name, SetSelected)
        end
      end
    end)

    if not modernSpellsClass then
      UDDM_Initialize(classDrop, function(self, level)
        do
          local info = UDDM_CreateInfo()
          info.text = "None"
          info.notCheckable = true
          info.func = function()
            if type(panels.spells._classes) ~= "table" then panels.spells._classes = {} end
            WipeTable(panels.spells._classes)
            panels.spells._class = nil
            RefreshSpellClassDropText()
          end
          UDDM_AddButton(info)
        end

        for _, tok in ipairs(SPELL_CLASS_TOKENS) do
          local info = UDDM_CreateInfo()
          info.text = tok
          info.isNotRadio = true
          info.keepShownOnClick = true
          info.checked = function() return (type(panels.spells._classes) == "table" and panels.spells._classes[tok]) and true or false end
          info.func = function()
            if type(panels.spells._classes) ~= "table" then panels.spells._classes = {} end
            panels.spells._classes[tok] = not panels.spells._classes[tok]
            local sel = GetSelectedSpellClasses()
            panels.spells._class = (#sel == 1) and sel[1] or nil
            RefreshSpellClassDropText()
          end
          UDDM_AddButton(info)
        end
      end)
    end

    if not modernSpellsFrame then
      UDDM_Initialize(spellsFrameDrop, function(self, level)
        for _, def in ipairs(GetEffectiveFrames()) do
          if type(def) == "table" and def.id then
            local id = tostring(def.id)
            local info = UDDM_CreateInfo()
            info.text = GetFrameDisplayNameByID(id)
            info.checked = (panels.spells._targetFrameID == id) and true or false
            info.func = function()
              panels.spells._targetFrameID = id
              if UDDM_SetText then UDDM_SetText(spellsFrameDrop, GetFrameDisplayNameByID(id)) end
            end
            UDDM_AddButton(info)
          end
        end
      end)
    end

    if not modernSpellsFaction then
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
    end

    if not modernSpellsColor then
      UDDM_Initialize(spellsColorDrop, function(self, level)
        for _, name in ipairs({ "None", "Green", "Blue", "Yellow", "Red", "Cyan" }) do
          local info = UDDM_CreateInfo()
          info.text = name
          info.func = function() SetSpellsColor(name) end
          UDDM_AddButton(info)
        end
      end)
    end

    if not modernSpellsLevelOp then
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
  end

  local addSpellBtn = CreateFrame("Button", nil, panels.spells, "UIPanelButtonTemplate")
  addSpellBtn:SetSize(140, 22)
  addSpellBtn:SetPoint("TOPLEFT", 12, -280)
  addSpellBtn:SetText("Add Spell Rule")

  panels.spells._spellNameBox = spellsNameBox
  panels.spells._spellInfoBox = spellsInfoBox
  panels.spells._spellInfoScroll = spellsInfoScroll
  panels.spells._classDrop = classDrop
  panels.spells._setClassesFromRule = SetSelectedSpellClassesFromRule
  panels.spells._knownBox = knownBox
  panels.spells._notKnownBox = notKnownBox
  panels.spells._locBox = locBox
  panels.spells._notInGroup = notInGroupCheck
  panels.spells._restedOnly = spellsRestedOnlyCheck
  panels.spells._missingPrimaryProf = spellsMissingProfCheck
  panels.spells._spellsFrameDrop = spellsFrameDrop
  panels.spells._spellsFactionDrop = spellsFactionDrop
  panels.spells._spellsColorDrop = spellsColorDrop
  panels.spells._spellsLevelOpDrop = spellsLevelOpDrop
  panels.spells._spellsLevelBox = spellsLevelBox
  panels.spells._addSpellBtn = addSpellBtn

  local cancelSpellEditBtn = CreateFrame("Button", nil, panels.spells, "UIPanelButtonTemplate")
  cancelSpellEditBtn:SetSize(120, 22)
  cancelSpellEditBtn:SetPoint("LEFT", addSpellBtn, "RIGHT", 8, 0)
  cancelSpellEditBtn:SetText("Cancel Edit")
  cancelSpellEditBtn:Hide()
  panels.spells._cancelEditBtn = cancelSpellEditBtn

  local function ClearSpellsInputs()
    if spellsNameBox then
      spellsNameBox._autoName = nil
      spellsNameBox:SetText("")
    end
    if spellsInfoBox then
      spellsInfoBox._autoInfo = nil
      spellsInfoBox:SetText("")
    end
    if spellsInfoScroll and spellsInfoScroll.SetVerticalScroll then spellsInfoScroll:SetVerticalScroll(0) end
    if knownBox then knownBox:SetText("0") end
    if notKnownBox then notKnownBox:SetText("0") end
    if locBox then locBox:SetText("0") end
    if notInGroupCheck then notInGroupCheck:SetChecked(false) end
    if spellsRestedOnlyCheck then spellsRestedOnlyCheck:SetChecked(false) end
    if spellsMissingProfCheck then spellsMissingProfCheck:SetChecked(false) end

    panels.spells._class = nil
    if type(panels.spells._classes) ~= "table" then panels.spells._classes = {} end
    WipeTable(panels.spells._classes)
    RefreshSpellClassDropText()

    panels.spells._targetFrameID = "list1"
    if UDDM_SetText and spellsFrameDrop then UDDM_SetText(spellsFrameDrop, GetFrameDisplayNameByID("list1")) end

    panels.spells._faction = nil
    if UDDM_SetText and spellsFactionDrop then UDDM_SetText(spellsFactionDrop, "Both (Off)") end

    panels.spells._color = nil
    if UDDM_SetText and spellsColorDrop then UDDM_SetText(spellsColorDrop, "None") end

    panels.spells._playerLevelOp = nil
    if UDDM_SetText and spellsLevelOpDrop then UDDM_SetText(spellsLevelOpDrop, "Off") end
    if spellsLevelBox then spellsLevelBox:SetText("0") end

    panels.spells._editingCustomIndex = nil
    panels.spells._editingDefaultBase = nil
    panels.spells._editingDefaultKey = nil
    if addSpellBtn then addSpellBtn:SetText("Add Spell Rule") end
    if cancelSpellEditBtn then cancelSpellEditBtn:Hide() end
  end

  local function GetSpellNameSafeLocal(spellID)
    spellID = tonumber(spellID)
    if not spellID or spellID <= 0 then return nil end
    local CS = _G and rawget(_G, "C_Spell")
    if CS and CS.GetSpellName then
      local ok, n = pcall(CS.GetSpellName, spellID)
      if ok and type(n) == "string" and n ~= "" then return n end
    end
    local GSI = _G and rawget(_G, "GetSpellInfo")
    if GSI then
      local ok, n = pcall(GSI, spellID)
      if ok and type(n) == "string" and n ~= "" then return n end
    end
    return nil
  end

  panels.spells._getSpellNameSafe = GetSpellNameSafeLocal

  local function PickSpellIDFromInputs()
    local known = tonumber(knownBox and knownBox:GetText() or "")
    if known and known > 0 then return known end
    local notKnown = tonumber(notKnownBox and notKnownBox:GetText() or "")
    if notKnown and notKnown > 0 then return notKnown end
    return nil
  end

  local function UpdateSpellFieldsFromID(force)
    local spellID = PickSpellIDFromInputs()
    if not spellID then return end
    local name = GetSpellNameSafeLocal(spellID)
    if type(name) ~= "string" or name == "" then return end

    if spellsNameBox then
      if force then
        spellsNameBox._autoName = name
        spellsNameBox:SetText(name)
      else
        local cur = tostring(spellsNameBox:GetText() or "")
        if cur == "" or (spellsNameBox._autoName ~= nil and cur == tostring(spellsNameBox._autoName)) then
          spellsNameBox._autoName = name
          spellsNameBox:SetText(name)
        end
      end
    end

    if spellsInfoBox then
      if force then
        spellsInfoBox._autoInfo = name
        spellsInfoBox:SetText(name)
      else
        local cur = tostring(spellsInfoBox:GetText() or "")
        if cur == "" or (spellsInfoBox._autoInfo ~= nil and cur == tostring(spellsInfoBox._autoInfo)) then
          spellsInfoBox._autoInfo = name
          spellsInfoBox:SetText(name)
        end
      end
    end
  end

  if spellsNameBox then
    spellsNameBox:HookScript("OnTextChanged", function(self, userInput)
      if not userInput then return end
      local cur = tostring(self:GetText() or "")
      if self._autoName ~= nil and cur ~= tostring(self._autoName) then
        self._autoName = nil
      end
    end)
  end

  if spellsInfoBox then
    spellsInfoBox:HookScript("OnTextChanged", function(self, userInput)
      if not userInput then return end
      local cur = tostring(self:GetText() or "")
      if self._autoInfo ~= nil and cur ~= tostring(self._autoInfo) then
        self._autoInfo = nil
      end
    end)
  end

  if knownBox then
    knownBox:HookScript("OnTextChanged", function(_, userInput)
      if not userInput then return end
      UpdateSpellFieldsFromID(GetKeepEditFormOpen())
    end)
  end
  if notKnownBox then
    notKnownBox:HookScript("OnTextChanged", function(_, userInput)
      if not userInput then return end
      UpdateSpellFieldsFromID(GetKeepEditFormOpen())
    end)
  end

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

    local pickedSpellID = (known and known > 0) and known or ((notKnown and notKnown > 0) and notKnown or nil)
    local resolvedName = pickedSpellID and GetSpellNameSafeLocal(pickedSpellID) or nil

    local nameText = tostring(spellsNameBox and spellsNameBox:GetText() or "")
    nameText = nameText:gsub("^%s+", ""):gsub("%s+$", "")
    local label = nil
    if nameText ~= "" and not (type(resolvedName) == "string" and resolvedName ~= "" and nameText == resolvedName) then
      label = nameText
    end

    local infoText = tostring(spellsInfoBox and spellsInfoBox:GetText() or "")
    infoText = infoText:gsub("^%s+", ""):gsub("%s+$", "")
    local spellInfo = (infoText ~= "") and infoText or nil

    local rules = GetCustomRules()
    if panels.spells._editingCustomIndex and type(rules[panels.spells._editingCustomIndex]) == "table" then
      local rule = rules[panels.spells._editingCustomIndex]
      rule.frameID = targetFrame
      rule.label = label
      rule.spellInfo = spellInfo
      do
        local sel = GetSelectedSpellClasses()
        if #sel == 0 then
          rule.class = nil
        elseif #sel == 1 then
          rule.class = sel[1]
        else
          rule.class = sel
        end
      end
      rule.faction = panels.spells._faction
      rule.color = panels.spells._color
      rule.notInGroup = notInGroupCheck:GetChecked() and true or false
      rule.restedOnly = spellsRestedOnlyCheck:GetChecked() and true or false
      rule.missingPrimaryProfessions = spellsMissingProfCheck:GetChecked() and true or false
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
      panels.spells._editingDefaultBase = nil
      panels.spells._editingDefaultKey = nil
      addSpellBtn:SetText("Add Spell Rule")
      cancelSpellEditBtn:Hide()
      Print("Saved spell rule.")
    elseif panels.spells._editingDefaultBase and panels.spells._editingDefaultKey and ns and ns.GetDefaultRuleEdits then
      local edits = ns.GetDefaultRuleEdits()
      local base = panels.spells._editingDefaultBase
      local key = tostring(panels.spells._editingDefaultKey)
      local effective = (type(edits[key]) == "table") and edits[key] or base
      local rule = DeepCopyValue(effective)

      rule.frameID = targetFrame
      rule.label = label
      rule.spellInfo = spellInfo
      do
        local sel = GetSelectedSpellClasses()
        if #sel == 0 then
          rule.class = nil
        elseif #sel == 1 then
          rule.class = sel[1]
        else
          rule.class = sel
        end
      end
      rule.faction = panels.spells._faction
      rule.color = panels.spells._color
      rule.notInGroup = notInGroupCheck:GetChecked() and true or false
      rule.restedOnly = spellsRestedOnlyCheck:GetChecked() and true or false
      rule.missingPrimaryProfessions = spellsMissingProfCheck:GetChecked() and true or false
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
      if base and base.key ~= nil then rule.key = tostring(base.key) end
      edits[key] = rule

      panels.spells._editingCustomIndex = nil
      panels.spells._editingDefaultBase = nil
      panels.spells._editingDefaultKey = nil
      addSpellBtn:SetText("Add Spell Rule")
      cancelSpellEditBtn:Hide()
      Print("Saved default spell rule edit.")
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
        spellInfo = spellInfo,
        class = nil,
        faction = panels.spells._faction,
        color = panels.spells._color,
        notInGroup = notInGroupCheck:GetChecked() and true or false,
        restedOnly = spellsRestedOnlyCheck:GetChecked() and true or false,
        missingPrimaryProfessions = spellsMissingProfCheck:GetChecked() and true or false,
        locationID = locationID,
        playerLevelOp = op,
        playerLevel = lvl,
        hideWhenCompleted = false,
      }
      do
        local sel = GetSelectedSpellClasses()
        if #sel == 1 then
          r.class = sel[1]
        elseif #sel > 1 then
          r.class = sel
        end
      end
      if known then r.spellKnown = known end
      if notKnown then r.notSpellKnown = notKnown end

      rules[#rules + 1] = r
      Print("Added spell rule -> " .. targetFrame)
    end
    CreateAllFrames()
    RefreshAll()
    RefreshRulesList()
    if not GetKeepEditFormOpen() then
      ClearSpellsInputs()
      SelectTab("rules")
    end
  end)

  cancelSpellEditBtn:SetScript("OnClick", function()
    panels.spells._editingCustomIndex = nil
    panels.spells._editingDefaultBase = nil
    panels.spells._editingDefaultKey = nil
    addSpellBtn:SetText("Add Spell Rule")
    cancelSpellEditBtn:Hide()

    if not GetKeepEditFormOpen() then
      ClearSpellsInputs()
      SelectTab("rules")
    end
  end)

      end

    end
  end

  local function ClearTabEdits()
    if panels.quest then
      panels.quest._editingCustomIndex = nil
      panels.quest._editingDefaultBase = nil
      panels.quest._editingDefaultKey = nil
      if panels.quest._addQuestBtn then panels.quest._addQuestBtn:SetText("Add Quest Rule") end
      if panels.quest._cancelEditBtn then panels.quest._cancelEditBtn:Hide() end
    end
    if panels.items then
      panels.items._editingCustomIndex = nil
      panels.items._editingDefaultBase = nil
      panels.items._editingDefaultKey = nil
      if panels.items._addItemBtn then panels.items._addItemBtn:SetText("Add Item Entry") end
      if panels.items._cancelEditBtn then panels.items._cancelEditBtn:Hide() end
    end
    if panels.text then
      panels.text._editingCustomIndex = nil
      panels.text._editingDefaultBase = nil
      panels.text._editingDefaultKey = nil
      if panels.text._addTextBtn then panels.text._addTextBtn:SetText("Add Text Entry") end
      if panels.text._cancelEditBtn then panels.text._cancelEditBtn:Hide() end
    end
    if panels.spells then
      panels.spells._editingCustomIndex = nil
      panels.spells._editingDefaultBase = nil
      panels.spells._editingDefaultKey = nil
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
    if r.spellKnown or r.notSpellKnown or r.SpellKnown or r.NotSpellKnown or r.locationID or r.class or r.notInGroup or r.restedOnly or r.missingPrimaryProfessions then return "spell" end
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
    -- When editing, keep the rule-create Expansion dropdown in sync with this rule.
    SetRuleCreateExpansion(rule._expansionID, rule._expansionName)
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
      if UDDM_SetText and panels.quest._questFrameDrop then UDDM_SetText(panels.quest._questFrameDrop, GetFrameDisplayNameByID(frameID)) end

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
      if UDDM_SetText and panels.quest._qLevelOpDrop then UDDM_SetText(panels.quest._qLevelOpDrop, panels.quest._playerLevelOp or "Off") end
      if panels.quest._qLevelBox then panels.quest._qLevelBox:SetText(tostring(tonumber(rule.playerLevel) or 0)) end
      return
    end

    if t == "item" then
      SelectTab("items")
      panels.items._editingCustomIndex = customIndex
      if panels.items._addItemBtn then panels.items._addItemBtn:SetText("Save Item Entry") end
      if panels.items._cancelEditBtn then panels.items._cancelEditBtn:Show() end

      local itemID = (type(rule.item) == "table") and tonumber(rule.item.itemID) or 0
      if panels.items._itemIDBox then
        if itemID and itemID > 0 then
          panels.items._itemIDBox:SetText(tostring(itemID))
        else
          panels.items._itemIDBox:SetText("")
        end
      end

      do
        local itemName = (itemID and itemID > 0) and GetItemNameSafe(itemID) or nil

        if panels.items._itemNameBox then
          if rule.label ~= nil and tostring(rule.label or "") ~= "" then
            panels.items._itemNameBox._autoName = nil
            panels.items._itemNameBox:SetText(tostring(rule.label or ""))
          elseif type(itemName) == "string" and itemName ~= "" then
            panels.items._itemNameBox._autoName = itemName
            panels.items._itemNameBox:SetText(itemName)
          else
            panels.items._itemNameBox._autoName = nil
            panels.items._itemNameBox:SetText("")
          end
        end

        if panels.items._itemInfoBox then
          if rule.itemInfo ~= nil and tostring(rule.itemInfo or "") ~= "" then
            panels.items._itemInfoBox._autoInfo = nil
            panels.items._itemInfoBox:SetText(tostring(rule.itemInfo or ""))
          elseif type(itemName) == "string" and itemName ~= "" then
            panels.items._itemInfoBox._autoInfo = itemName
            panels.items._itemInfoBox:SetText(itemName)
          else
            panels.items._itemInfoBox._autoInfo = nil
            panels.items._itemInfoBox:SetText("")
          end
        end

        if panels.items._itemInfoScroll and panels.items._itemInfoScroll.SetVerticalScroll then
          panels.items._itemInfoScroll:SetVerticalScroll(0)
        end
      end

      if panels.items._itemQuestIDBox and type(rule.item) == "table" then
        local qid = tonumber(rule.item.questID) or 0
        panels.items._itemQuestIDBox:SetText((qid > 0) and tostring(qid) or "")
      end
      if panels.items._itemAfterQuestIDBox and type(rule.item) == "table" then
        local aqid = tonumber(rule.item.afterQuestID) or 0
        panels.items._itemAfterQuestIDBox:SetText((aqid > 0) and tostring(aqid) or "")
      end

      if panels.items._itemCurrencyIDBox and type(rule.item) == "table" then
        local cid = tonumber(rule.item.currencyID) or 0
        panels.items._itemCurrencyIDBox:SetText((cid > 0) and tostring(cid) or "")
      end
      if panels.items._itemCurrencyReqBox and type(rule.item) == "table" then
        local creq = tonumber(rule.item.currencyRequired) or 0
        panels.items._itemCurrencyReqBox:SetText((creq > 0) and tostring(creq) or "")
      end

      if panels.items._itemShowBelowBox and type(rule.item) == "table" then
        local sb = tonumber(rule.item.showWhenBelow) or 0
        panels.items._itemShowBelowBox:SetText((sb > 0) and tostring(sb) or "")
      end

      local frameID = tostring(rule.frameID or "list1")
      panels.items._targetFrameID = frameID
      if UDDM_SetText and panels.items._itemsFrameDrop then UDDM_SetText(panels.items._itemsFrameDrop, GetFrameDisplayNameByID(frameID)) end

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
      local repSellEx = false
      if type(rule.rep) == "table" and rule.rep.factionID then
        repFactionID = tonumber(rule.rep.factionID) or 0
        repMin = tonumber(rule.rep.minStanding)
        repHideEx = (rule.rep.hideWhenExalted == true)
        repSellEx = (rule.rep.sellWhenExalted == true)
      end
      if panels.items._repFactionBox then panels.items._repFactionBox:SetText((repFactionID and repFactionID > 0) and tostring(repFactionID) or "") end
      panels.items._repMinStanding = repMin
      if UDDM_SetText and panels.items._repMinDrop then UDDM_SetText(panels.items._repMinDrop, RepStandingLabelLite(repMin)) end
      if panels.items._hideExalted then panels.items._hideExalted:SetChecked(repHideEx and true or false) end
      if panels.items._sellExalted then panels.items._sellExalted:SetChecked(repSellEx and true or false) end

      panels.items._playerLevelOp = (rule.playerLevelOp == "<" or rule.playerLevelOp == "<=" or rule.playerLevelOp == "=" or rule.playerLevelOp == ">=" or rule.playerLevelOp == ">" or rule.playerLevelOp == "!=") and rule.playerLevelOp or nil
      if UDDM_SetText and panels.items._itemsLevelOpDrop then UDDM_SetText(panels.items._itemsLevelOpDrop, panels.items._playerLevelOp or "Off") end
      if panels.items._itemsLevelBox then
        local n = tonumber(rule.playerLevel) or 0
        panels.items._itemsLevelBox:SetText((n > 0) and tostring(n) or "")
      end
      return
    end

    if t == "spell" then
      SelectTab("spells")
      panels.spells._editingCustomIndex = customIndex
      if panels.spells._addSpellBtn then panels.spells._addSpellBtn:SetText("Save Spell Rule") end
      if panels.spells._cancelEditBtn then panels.spells._cancelEditBtn:Show() end

      do
        local knownID = tonumber(rule.spellKnown or rule.SpellKnown) or 0
        local notKnownID = tonumber(rule.notSpellKnown or rule.NotSpellKnown) or 0
        local pick = (knownID and knownID > 0) and knownID or ((notKnownID and notKnownID > 0) and notKnownID or nil)
        local resolver = panels.spells and panels.spells._getSpellNameSafe
        local resolved = (pick and resolver) and resolver(pick) or nil

        if panels.spells._spellNameBox then
          if rule.label ~= nil and tostring(rule.label or "") ~= "" then
            panels.spells._spellNameBox._autoName = nil
            panels.spells._spellNameBox:SetText(tostring(rule.label or ""))
          elseif type(resolved) == "string" and resolved ~= "" then
            panels.spells._spellNameBox._autoName = resolved
            panels.spells._spellNameBox:SetText(resolved)
          else
            panels.spells._spellNameBox._autoName = nil
            panels.spells._spellNameBox:SetText("")
          end
        end

        if panels.spells._spellInfoBox then
          if rule.spellInfo ~= nil and tostring(rule.spellInfo or "") ~= "" then
            panels.spells._spellInfoBox._autoInfo = nil
            panels.spells._spellInfoBox:SetText(tostring(rule.spellInfo or ""))
          elseif type(resolved) == "string" and resolved ~= "" then
            panels.spells._spellInfoBox._autoInfo = resolved
            panels.spells._spellInfoBox:SetText(resolved)
          else
            panels.spells._spellInfoBox._autoInfo = nil
            panels.spells._spellInfoBox:SetText("")
          end
        end

        if panels.spells._spellInfoScroll and panels.spells._spellInfoScroll.SetVerticalScroll then
          panels.spells._spellInfoScroll:SetVerticalScroll(0)
        end
      end
      if panels.spells._knownBox then panels.spells._knownBox:SetText(tostring(tonumber(rule.spellKnown or rule.SpellKnown) or 0)) end
      if panels.spells._notKnownBox then panels.spells._notKnownBox:SetText(tostring(tonumber(rule.notSpellKnown or rule.NotSpellKnown) or 0)) end
      if panels.spells._locBox then panels.spells._locBox:SetText(tostring(rule.locationID or "0")) end
      if panels.spells._notInGroup then panels.spells._notInGroup:SetChecked(rule.notInGroup and true or false) end

      if panels.spells._setClassesFromRule then panels.spells._setClassesFromRule(rule.class) end

      local frameID = tostring(rule.frameID or "list1")
      panels.spells._targetFrameID = frameID
      if UDDM_SetText and panels.spells._spellsFrameDrop then UDDM_SetText(panels.spells._spellsFrameDrop, GetFrameDisplayNameByID(frameID)) end

      panels.spells._faction = (rule.faction == "Alliance" or rule.faction == "Horde") and rule.faction or nil
      if UDDM_SetText and panels.spells._spellsFactionDrop then
        UDDM_SetText(panels.spells._spellsFactionDrop, panels.spells._faction and tostring(panels.spells._faction) or "Both (Off)")
      end

      panels.spells._color = rule.color
      if UDDM_SetText and panels.spells._spellsColorDrop then
        UDDM_SetText(panels.spells._spellsColorDrop, ColorToNameLite(rule.color))
      end

      panels.spells._playerLevelOp = (rule.playerLevelOp == "<" or rule.playerLevelOp == "<=" or rule.playerLevelOp == "=" or rule.playerLevelOp == ">=" or rule.playerLevelOp == ">" or rule.playerLevelOp == "!=") and rule.playerLevelOp or nil
      if UDDM_SetText and panels.spells._spellsLevelOpDrop then UDDM_SetText(panels.spells._spellsLevelOpDrop, panels.spells._playerLevelOp or "Off") end
      if panels.spells._spellsLevelBox then panels.spells._spellsLevelBox:SetText(tostring(tonumber(rule.playerLevel) or 0)) end

      if panels.spells._restedOnly then panels.spells._restedOnly:SetChecked(rule.restedOnly and true or false) end
      if panels.spells._missingPrimaryProf then panels.spells._missingPrimaryProf:SetChecked(rule.missingPrimaryProfessions and true or false) end
      return
    end

    -- text
    SelectTab("text")
    panels.text._editingCustomIndex = customIndex
    if panels.text._addTextBtn then panels.text._addTextBtn:SetText("Save Text Entry") end
    if panels.text._cancelEditBtn then panels.text._cancelEditBtn:Show() end

    if panels.text._textNameBox then panels.text._textNameBox:SetText(tostring(rule.label or "")) end
    if panels.text._textInfoBox then
      local info = (rule.textInfo ~= nil and tostring(rule.textInfo or "") ~= "") and tostring(rule.textInfo or "") or tostring(rule.label or "")
      panels.text._textInfoBox:SetText(info)
    end
    if panels.text._textInfoScroll and panels.text._textInfoScroll.SetVerticalScroll then
      panels.text._textInfoScroll:SetVerticalScroll(0)
    end

    local frameID = tostring(rule.frameID or "list1")
    panels.text._targetFrameID = frameID
    if UDDM_SetText and panels.text._textFrameDrop then UDDM_SetText(panels.text._textFrameDrop, GetFrameDisplayNameByID(frameID)) end

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
    if UDDM_SetText and panels.text._textLevelOpDrop then UDDM_SetText(panels.text._textLevelOpDrop, panels.text._playerLevelOp or "Off") end
    if panels.text._textLevelBox then panels.text._textLevelBox:SetText(tostring(tonumber(rule.playerLevel) or 0)) end
  end

  ns.OpenCustomRuleInTab = OpenCustomRuleInTab

  local function OpenDefaultRuleInTab(baseRule)
    if not optionsFrame then return end
    if type(baseRule) ~= "table" then return end
    if not (ns and ns.RuleKey and ns.GetDefaultRuleEdits) then return end

    local key = ns.RuleKey(baseRule)
    if not key or key == "" then return end

    local edits = ns.GetDefaultRuleEdits() or {}
    local rule = (type(edits[key]) == "table") and edits[key] or baseRule

    if optionsFrame._ruleEditorFrame then
      optionsFrame._ruleEditorFrame._skipRestore = true
      optionsFrame._ruleEditorFrame:Hide()
    end
    ClearTabEdits()

    local t = DetectRuleTypeLite(rule)
    -- When editing, keep the rule-create Expansion dropdown in sync with this rule.
    SetRuleCreateExpansion(rule._expansionID, rule._expansionName)
    if t == "quest" then
      SelectTab("quest")
      panels.quest._editingDefaultBase = baseRule
      panels.quest._editingDefaultKey = key
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
      if UDDM_SetText and panels.quest._questFrameDrop then UDDM_SetText(panels.quest._questFrameDrop, GetFrameDisplayNameByID(frameID)) end

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
      if UDDM_SetText and panels.quest._qLevelOpDrop then UDDM_SetText(panels.quest._qLevelOpDrop, panels.quest._playerLevelOp or "Off") end
      if panels.quest._qLevelBox then panels.quest._qLevelBox:SetText(tostring(tonumber(rule.playerLevel) or 0)) end
      return
    end

    if t == "item" then
      SelectTab("items")
      panels.items._editingDefaultBase = baseRule
      panels.items._editingDefaultKey = key
      if panels.items._addItemBtn then panels.items._addItemBtn:SetText("Save Item Entry") end
      if panels.items._cancelEditBtn then panels.items._cancelEditBtn:Show() end

      local itemID = (type(rule.item) == "table") and tonumber(rule.item.itemID) or 0
      if panels.items._itemIDBox then
        if itemID and itemID > 0 then
          panels.items._itemIDBox:SetText(tostring(itemID))
        else
          panels.items._itemIDBox:SetText("")
        end
      end

      do
        local itemName = (itemID and itemID > 0) and GetItemNameSafe(itemID) or nil

        if panels.items._itemNameBox then
          if rule.label ~= nil and tostring(rule.label or "") ~= "" then
            panels.items._itemNameBox._autoName = nil
            panels.items._itemNameBox:SetText(tostring(rule.label or ""))
          elseif type(itemName) == "string" and itemName ~= "" then
            panels.items._itemNameBox._autoName = itemName
            panels.items._itemNameBox:SetText(itemName)
          else
            panels.items._itemNameBox._autoName = nil
            panels.items._itemNameBox:SetText("")
          end
        end

        if panels.items._itemInfoBox then
          if rule.itemInfo ~= nil and tostring(rule.itemInfo or "") ~= "" then
            panels.items._itemInfoBox._autoInfo = nil
            panels.items._itemInfoBox:SetText(tostring(rule.itemInfo or ""))
          elseif type(itemName) == "string" and itemName ~= "" then
            panels.items._itemInfoBox._autoInfo = itemName
            panels.items._itemInfoBox:SetText(itemName)
          else
            panels.items._itemInfoBox._autoInfo = nil
            panels.items._itemInfoBox:SetText("")
          end
        end

        if panels.items._itemInfoScroll and panels.items._itemInfoScroll.SetVerticalScroll then
          panels.items._itemInfoScroll:SetVerticalScroll(0)
        end
      end

      if panels.items._itemQuestIDBox and type(rule.item) == "table" then
        local qid = tonumber(rule.item.questID) or 0
        panels.items._itemQuestIDBox:SetText((qid > 0) and tostring(qid) or "")
      end
      if panels.items._itemAfterQuestIDBox and type(rule.item) == "table" then
        local aqid = tonumber(rule.item.afterQuestID) or 0
        panels.items._itemAfterQuestIDBox:SetText((aqid > 0) and tostring(aqid) or "")
      end

      if panels.items._itemCurrencyIDBox and type(rule.item) == "table" then
        local cid = tonumber(rule.item.currencyID) or 0
        panels.items._itemCurrencyIDBox:SetText((cid > 0) and tostring(cid) or "")
      end
      if panels.items._itemCurrencyReqBox and type(rule.item) == "table" then
        local creq = tonumber(rule.item.currencyRequired) or 0
        panels.items._itemCurrencyReqBox:SetText((creq > 0) and tostring(creq) or "")
      end

      if panels.items._itemShowBelowBox and type(rule.item) == "table" then
        local sb = tonumber(rule.item.showWhenBelow) or 0
        panels.items._itemShowBelowBox:SetText((sb > 0) and tostring(sb) or "")
      end

      local frameID = tostring(rule.frameID or "list1")
      panels.items._targetFrameID = frameID
      if UDDM_SetText and panels.items._itemsFrameDrop then UDDM_SetText(panels.items._itemsFrameDrop, GetFrameDisplayNameByID(frameID)) end

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
      local repSellEx = false
      if type(rule.rep) == "table" and rule.rep.factionID then
        repFactionID = tonumber(rule.rep.factionID) or 0
        repMin = tonumber(rule.rep.minStanding)
        repHideEx = (rule.rep.hideWhenExalted == true)
        repSellEx = (rule.rep.sellWhenExalted == true)
      end
      if panels.items._repFactionBox then panels.items._repFactionBox:SetText((repFactionID and repFactionID > 0) and tostring(repFactionID) or "") end
      panels.items._repMinStanding = repMin
      if UDDM_SetText and panels.items._repMinDrop then UDDM_SetText(panels.items._repMinDrop, RepStandingLabelLite(repMin)) end
      if panels.items._hideExalted then panels.items._hideExalted:SetChecked(repHideEx and true or false) end
      if panels.items._sellExalted then panels.items._sellExalted:SetChecked(repSellEx and true or false) end

      panels.items._playerLevelOp = (rule.playerLevelOp == "<" or rule.playerLevelOp == "<=" or rule.playerLevelOp == "=" or rule.playerLevelOp == ">=" or rule.playerLevelOp == ">" or rule.playerLevelOp == "!=") and rule.playerLevelOp or nil
      if UDDM_SetText and panels.items._itemsLevelOpDrop then UDDM_SetText(panels.items._itemsLevelOpDrop, panels.items._playerLevelOp or "Off") end
      if panels.items._itemsLevelBox then
        local n = tonumber(rule.playerLevel) or 0
        panels.items._itemsLevelBox:SetText((n > 0) and tostring(n) or "")
      end
      return
    end

    if t == "spell" then
      SelectTab("spells")
      panels.spells._editingDefaultBase = baseRule
      panels.spells._editingDefaultKey = key
      if panels.spells._addSpellBtn then panels.spells._addSpellBtn:SetText("Save Spell Rule") end
      if panels.spells._cancelEditBtn then panels.spells._cancelEditBtn:Show() end

      do
        local knownID = tonumber(rule.spellKnown or rule.SpellKnown) or 0
        local notKnownID = tonumber(rule.notSpellKnown or rule.NotSpellKnown) or 0
        local pick = (knownID and knownID > 0) and knownID or ((notKnownID and notKnownID > 0) and notKnownID or nil)
        local resolver = panels.spells and panels.spells._getSpellNameSafe
        local resolved = (pick and resolver) and resolver(pick) or nil

        if panels.spells._spellNameBox then
          if rule.label ~= nil and tostring(rule.label or "") ~= "" then
            panels.spells._spellNameBox._autoName = nil
            panels.spells._spellNameBox:SetText(tostring(rule.label or ""))
          elseif type(resolved) == "string" and resolved ~= "" then
            panels.spells._spellNameBox._autoName = resolved
            panels.spells._spellNameBox:SetText(resolved)
          else
            panels.spells._spellNameBox._autoName = nil
            panels.spells._spellNameBox:SetText("")
          end
        end

        if panels.spells._spellInfoBox then
          if rule.spellInfo ~= nil and tostring(rule.spellInfo or "") ~= "" then
            panels.spells._spellInfoBox._autoInfo = nil
            panels.spells._spellInfoBox:SetText(tostring(rule.spellInfo or ""))
          elseif type(resolved) == "string" and resolved ~= "" then
            panels.spells._spellInfoBox._autoInfo = resolved
            panels.spells._spellInfoBox:SetText(resolved)
          else
            panels.spells._spellInfoBox._autoInfo = nil
            panels.spells._spellInfoBox:SetText("")
          end
        end

        if panels.spells._spellInfoScroll and panels.spells._spellInfoScroll.SetVerticalScroll then
          panels.spells._spellInfoScroll:SetVerticalScroll(0)
        end
      end
      if panels.spells._knownBox then panels.spells._knownBox:SetText(tostring(tonumber(rule.spellKnown or rule.SpellKnown) or 0)) end
      if panels.spells._notKnownBox then panels.spells._notKnownBox:SetText(tostring(tonumber(rule.notSpellKnown or rule.NotSpellKnown) or 0)) end
      if panels.spells._locBox then panels.spells._locBox:SetText(tostring(rule.locationID or "0")) end
      if panels.spells._notInGroup then panels.spells._notInGroup:SetChecked(rule.notInGroup and true or false) end

      if panels.spells._setClassesFromRule then panels.spells._setClassesFromRule(rule.class) end

      local frameID = tostring(rule.frameID or "list1")
      panels.spells._targetFrameID = frameID
      if UDDM_SetText and panels.spells._spellsFrameDrop then UDDM_SetText(panels.spells._spellsFrameDrop, GetFrameDisplayNameByID(frameID)) end

      panels.spells._faction = (rule.faction == "Alliance" or rule.faction == "Horde") and rule.faction or nil
      if UDDM_SetText and panels.spells._spellsFactionDrop then
        UDDM_SetText(panels.spells._spellsFactionDrop, panels.spells._faction and tostring(panels.spells._faction) or "Both (Off)")
      end

      panels.spells._color = rule.color
      if UDDM_SetText and panels.spells._spellsColorDrop then
        UDDM_SetText(panels.spells._spellsColorDrop, ColorToNameLite(rule.color))
      end

      panels.spells._playerLevelOp = (rule.playerLevelOp == "<" or rule.playerLevelOp == "<=" or rule.playerLevelOp == "=" or rule.playerLevelOp == ">=" or rule.playerLevelOp == ">" or rule.playerLevelOp == "!=") and rule.playerLevelOp or nil
      if UDDM_SetText and panels.spells._spellsLevelOpDrop then UDDM_SetText(panels.spells._spellsLevelOpDrop, panels.spells._playerLevelOp or "Off") end
      if panels.spells._spellsLevelBox then panels.spells._spellsLevelBox:SetText(tostring(tonumber(rule.playerLevel) or 0)) end

      if panels.spells._restedOnly then panels.spells._restedOnly:SetChecked(rule.restedOnly and true or false) end
      if panels.spells._missingPrimaryProf then panels.spells._missingPrimaryProf:SetChecked(rule.missingPrimaryProfessions and true or false) end
      return
    end

    -- text
    SelectTab("text")
    panels.text._editingDefaultBase = baseRule
    panels.text._editingDefaultKey = key
    if panels.text._addTextBtn then panels.text._addTextBtn:SetText("Save Text Entry") end
    if panels.text._cancelEditBtn then panels.text._cancelEditBtn:Show() end

    if panels.text._textNameBox then panels.text._textNameBox:SetText(tostring(rule.label or "")) end
    if panels.text._textInfoBox then
      local info = (rule.textInfo ~= nil and tostring(rule.textInfo or "") ~= "") and tostring(rule.textInfo or "") or tostring(rule.label or "")
      panels.text._textInfoBox:SetText(info)
    end
    if panels.text._textInfoScroll and panels.text._textInfoScroll.SetVerticalScroll then
      panels.text._textInfoScroll:SetVerticalScroll(0)
    end

    local frameID = tostring(rule.frameID or "list1")
    panels.text._targetFrameID = frameID
    if UDDM_SetText and panels.text._textFrameDrop then UDDM_SetText(panels.text._textFrameDrop, GetFrameDisplayNameByID(frameID)) end

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
    if UDDM_SetText and panels.text._textLevelOpDrop then UDDM_SetText(panels.text._textLevelOpDrop, panels.text._playerLevelOp or "Off") end
    if panels.text._textLevelBox then panels.text._textLevelBox:SetText(tostring(tonumber(rule.playerLevel) or 0)) end
  end

  ns.OpenDefaultRuleInTab = OpenDefaultRuleInTab

  -- RULES tab (Rules module)
  local useRulesModule = type(ns) == "table" and type(ns.FQTOptionsPanels) == "table" and type(ns.FQTOptionsPanels.BuildRules) == "function"
  if useRulesModule then
    ns.FQTOptionsPanels.BuildRules(GetOptionsCtx())
  else
    -- Legacy Rules tab UI moved to fr0z3nUI_QuestTrackerRules.lua
    if false then
  local rulesTitle = panels.rules:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  rulesTitle:SetPoint("TOPLEFT", 12, -40)
  rulesTitle:SetText("Rules")
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

  local rulesViewDrop = CreateFrame("Frame", nil, panels.rules, "UIDropDownMenuTemplate")
  rulesViewDrop:SetPoint("TOPRIGHT", panels.rules, "TOPRIGHT", -6, -54)
  if UDDM_SetWidth then UDDM_SetWidth(rulesViewDrop, 120) end
  if UDDM_SetText then UDDM_SetText(rulesViewDrop, "All") end
  f._rulesViewDrop = rulesViewDrop

  -- Make the filter easy to click (dropdown templates often have tiny hit areas).
  local rulesViewDropHit = CreateFrame("Button", nil, panels.rules)
  rulesViewDropHit:EnableMouse(true)
  rulesViewDropHit:SetAlpha(0.01)
  rulesViewDropHit:SetPoint("TOPLEFT", rulesViewDrop, "TOPLEFT", 18, -2)
  rulesViewDropHit:SetPoint("BOTTOMRIGHT", rulesViewDrop, "BOTTOMRIGHT", -18, 2)
  f._rulesViewDropHit = rulesViewDropHit

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
    AttachLocationIDTooltip(loc2Box)
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
      local modernType = UseModernMenuDropDown(typeDrop, function(root)
        if root and root.CreateTitle then root:CreateTitle("Type") end
        local function Add(name, t)
          if not root then return end
          if root.CreateRadio then
            root:CreateRadio(name, function() return (ed._type == t) end, function()
              if UDDM_SetText then UDDM_SetText(typeDrop, name) end
              ShowType(t)
            end)
          elseif root.CreateButton then
            root:CreateButton(name, function()
              if UDDM_SetText then UDDM_SetText(typeDrop, name) end
              ShowType(t)
            end)
          end
        end
        Add("Quest", "quest")
        Add("Item", "item")
        Add("Text", "text")
        Add("Spell", "spell")
      end)

      local modernFaction = UseModernMenuDropDown(factionDrop, function(root)
        if root and root.CreateTitle then root:CreateTitle("Faction") end
        local function Add(name, v)
          if not root then return end
          if root.CreateRadio then
            root:CreateRadio(name, function() return (ed._faction == v) end, function()
              ed._faction = v
              if UDDM_SetText then UDDM_SetText(factionDrop, name) end
            end)
          elseif root.CreateButton then
            root:CreateButton(name, function()
              ed._faction = v
              if UDDM_SetText then UDDM_SetText(factionDrop, name) end
            end)
          end
        end
        Add("Both (Off)", nil)
        Add("Alliance", "Alliance")
        Add("Horde", "Horde")
      end)

      local modernColor = UseModernMenuDropDown(colorDrop, function(root)
        if root and root.CreateTitle then root:CreateTitle("Color") end
        for _, name in ipairs({ "None", "Green", "Blue", "Yellow", "Red", "Cyan" }) do
          local function IsSelected() return (ed._colorName == name) end
          local function SetSelected()
            ed._colorName = name
            if UDDM_SetText then UDDM_SetText(colorDrop, name) end
          end
          if root and root.CreateRadio then
            root:CreateRadio(name, IsSelected, SetSelected)
          elseif root and root.CreateButton then
            root:CreateButton(name, SetSelected)
          end
        end
      end)

      local modernRepMin = UseModernMenuDropDown(repMinDrop, function(root)
        if root and root.CreateTitle then root:CreateTitle("Min Rep") end
        local opts = {
          { "Off", nil },
          { "Friendly", 5 },
          { "Honored", 6 },
          { "Revered", 7 },
          { "Exalted", 8 },
        }
        for _, opt in ipairs(opts) do
          local name, standing = opt[1], opt[2]
          local function IsSelected() return (ed._repMinStanding == standing) end
          local function SetSelected()
            ed._repMinStanding = standing
            if UDDM_SetText then UDDM_SetText(repMinDrop, name) end
          end
          if root and root.CreateRadio then
            root:CreateRadio(name, IsSelected, SetSelected)
          elseif root and root.CreateButton then
            root:CreateButton(name, SetSelected)
          end
        end
      end)

      local modernLevelOp = UseModernMenuDropDown(levelOpDrop, function(root)
        if root and root.CreateTitle then root:CreateTitle("Player level") end
        local opts = {
          { "Off", nil },
          { "<", "<" },
          { "<=", "<=" },
          { "=", "=" },
          { ">=", ">=" },
          { ">", ">" },
          { "!=", "!=" },
        }
        for _, opt in ipairs(opts) do
          local name, op = opt[1], opt[2]
          local function IsSelected() return (ed._playerLevelOp == op) end
          local function SetSelected()
            ed._playerLevelOp = op
            if UDDM_SetText then UDDM_SetText(levelOpDrop, name) end
          end
          if root and root.CreateRadio then
            root:CreateRadio(name, IsSelected, SetSelected)
          elseif root and root.CreateButton then
            root:CreateButton(name, SetSelected)
          end
        end
      end)

      local modernClass = UseModernMenuDropDown(classDrop2, function(root)
        if root and root.CreateTitle then root:CreateTitle("Class") end
        local function Add(tok)
          if not root then return end
          if root.CreateRadio then
            root:CreateRadio(tok, function() return (ed._class == tok or (tok == "None" and ed._class == nil)) end, function()
              ed._class = (tok == "None") and nil or tok
              if UDDM_SetText then UDDM_SetText(classDrop2, tok) end
            end)
          elseif root.CreateButton then
            root:CreateButton(tok, function()
              ed._class = (tok == "None") and nil or tok
              if UDDM_SetText then UDDM_SetText(classDrop2, tok) end
            end)
          end
        end
        Add("None")
        for _, tok in ipairs({
          "DEATHKNIGHT","DEMONHUNTER","DRUID","EVOKER","HUNTER","MAGE","MONK","PALADIN","PRIEST","ROGUE","SHAMAN","WARLOCK","WARRIOR",
        }) do
          Add(tok)
        end
      end)

      if not modernType then
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
      end

      if not modernFaction then
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
      end

      if not modernColor then
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
      end

      if not modernRepMin then
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
      end

      if not modernLevelOp then
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
      end

      if not modernClass then
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

  if UseModernMenuDropDown(rulesViewDrop, function(root)
    if root and root.CreateTitle then root:CreateTitle("Filter") end
    for _, v in ipairs({ "all", "custom", "defaults", "trash" }) do
      local label = (v == "all") and "All" or (v == "defaults") and "Defaults" or (v == "trash") and "Trash" or "Custom"
      if root and root.CreateRadio then
        root:CreateRadio(label, function() return (GetRulesView() == v) end, function() SetRulesView(v) end)
      elseif root and root.CreateButton then
        root:CreateButton(label, function() SetRulesView(v) end)
      end
    end
  end) then
    -- modern menu wired
  elseif UDDM_Initialize and UDDM_CreateInfo and UDDM_AddButton then
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
    -- (dropdown unavailable) nothing else to do
  end

  if rulesViewDropHit then
    rulesViewDropHit:SetScript("OnClick", function()
      local toggle = _G and rawget(_G, "ToggleDropDownMenu")
      if toggle then
        toggle(1, nil, rulesViewDrop, rulesViewDrop, 0, 0)
      end
    end)
  end

  local rulesScroll = CreateFrame("ScrollFrame", nil, panels.rules, "UIPanelScrollFrameTemplate")
  rulesScroll:SetPoint("TOPLEFT", 12, -86)
  rulesScroll:SetPoint("BOTTOMLEFT", 12, 44)
  rulesScroll:SetWidth(530)
  f._rulesScroll = rulesScroll

  local zebraRules = CreateFrame("Slider", nil, panels.rules, "UISliderTemplate")
  zebraRules:ClearAllPoints()
  zebraRules:SetPoint("BOTTOM", f, "BOTTOM", 0, 18)
  zebraRules:SetWidth(180)
  zebraRules:SetHeight(12)
  if zebraRules.Low and zebraRules.Low.Hide then zebraRules.Low:Hide() end
  if zebraRules.High and zebraRules.High.Hide then zebraRules.High:Hide() end
  if zebraRules.Text and zebraRules.Text.Hide then zebraRules.Text:Hide() end
  zebraRules:SetMinMaxValues(0, 0.20)
  zebraRules:SetValueStep(0.01)
  zebraRules:SetObeyStepOnDrag(true)
  zebraRules:SetScript("OnShow", function(self)
    if not optionsFrame or optionsFrame._zebraUpdating then return end
    optionsFrame._zebraUpdating = true
    local v = tonumber(GetUISetting("zebraAlpha", 0.05) or 0.05) or 0.05
    if v < 0 then v = 0 elseif v > 0.20 then v = 0.20 end
    self:SetValue(v)
    optionsFrame._zebraUpdating = false
  end)
  zebraRules:SetScript("OnValueChanged", function(self, value)
    if not optionsFrame or optionsFrame._zebraUpdating then return end
    optionsFrame._zebraUpdating = true
    local v = tonumber(value) or 0
    if v < 0 then v = 0 elseif v > 0.20 then v = 0.20 end
    SetUISetting("zebraAlpha", v)
    if optionsFrame._zebraSliderFrames and optionsFrame._zebraSliderFrames.SetValue then
      optionsFrame._zebraSliderFrames:SetValue(v)
    end
    RefreshFramesList()
    RefreshRulesList()
    optionsFrame._zebraUpdating = false
  end)
  f._zebraSliderRules = zebraRules

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

    end
  end

  -- FRAMES tab (Frames module)
  local useFramesModule = type(ns) == "table" and type(ns.FQTOptionsPanels) == "table" and type(ns.FQTOptionsPanels.BuildFrames) == "function"
  if useFramesModule then
    ns.FQTOptionsPanels.BuildFrames(GetOptionsCtx())
  else
    -- Legacy Frames tab UI moved to fr0z3nUI_QuestTrackerFrames.lua
    if false then

  -- FRAMES tab
  local framesTitle = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  framesTitle:SetPoint("TOPLEFT", 12, -40)
  framesTitle:SetText("")
  framesTitle:Hide()

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

  -- Global padding control (list padding outside edit mode; bar spacing always)
  local listPadLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  listPadLabel:SetPoint("TOPLEFT", 365, -160)
  listPadLabel:SetText("Pad (px)")

  local listPadBox = CreateFrame("EditBox", nil, panels.frames, "InputBoxTemplate")
  listPadBox:SetSize(40, 20)
  listPadBox:SetPoint("TOPLEFT", 365, -176)
  listPadBox:SetAutoFocus(false)
  listPadBox:SetNumeric(true)
  if listPadBox.SetJustifyH then listPadBox:SetJustifyH("RIGHT") end

  local function RefreshListPadBox(self)
    local p = GetUISetting("pad", nil)
    if p == nil then p = GetUISetting("listPadding", 0) end
    local v = tonumber(p or 0) or 0
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
    SetUISetting("pad", v)
    -- Back-compat with older key.
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
  addBarBtn:SetPoint("TOPRIGHT", -110, -40)
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
    if optionsFrame then optionsFrame._selectedFrameID = id end
    if f then f._selectedFrameID = id end
    CreateAllFrames()
    RefreshAll()
    RefreshFramesList()
    Print("Added frame " .. id)
  end)

  local addListBtn = CreateFrame("Button", nil, panels.frames, "UIPanelButtonTemplate")
  addListBtn:SetSize(90, 22)
  addListBtn:SetPoint("TOPRIGHT", -12, -40)
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
    if optionsFrame then optionsFrame._selectedFrameID = id end
    if f then f._selectedFrameID = id end
    CreateAllFrames()
    RefreshAll()
    RefreshFramesList()
    Print("Added frame " .. id)
  end)

  local framesScroll = CreateFrame("ScrollFrame", nil, panels.frames, "UIPanelScrollFrameTemplate")
  framesScroll:SetPoint("TOPLEFT", 12, -182)
  framesScroll:SetPoint("BOTTOMLEFT", 12, 44)
  framesScroll:SetWidth(530)

  local zebraFrames = CreateFrame("Slider", nil, panels.frames, "UISliderTemplate")
  zebraFrames:ClearAllPoints()
  zebraFrames:SetPoint("BOTTOM", f, "BOTTOM", 0, 18)
  zebraFrames:SetWidth(180)
  zebraFrames:SetHeight(12)
  if zebraFrames.Low and zebraFrames.Low.Hide then zebraFrames.Low:Hide() end
  if zebraFrames.High and zebraFrames.High.Hide then zebraFrames.High:Hide() end
  if zebraFrames.Text and zebraFrames.Text.Hide then zebraFrames.Text:Hide() end
  zebraFrames:SetMinMaxValues(0, 0.20)
  zebraFrames:SetValueStep(0.01)
  zebraFrames:SetObeyStepOnDrag(true)
  zebraFrames:SetScript("OnShow", function(self)
    if not optionsFrame or optionsFrame._zebraUpdating then return end
    optionsFrame._zebraUpdating = true
    local v = tonumber(GetUISetting("zebraAlpha", 0.05) or 0.05) or 0.05
    if v < 0 then v = 0 elseif v > 0.20 then v = 0.20 end
    self:SetValue(v)
    optionsFrame._zebraUpdating = false
  end)
  zebraFrames:SetScript("OnValueChanged", function(self, value)
    if not optionsFrame or optionsFrame._zebraUpdating then return end
    optionsFrame._zebraUpdating = true
    local v = tonumber(value) or 0
    if v < 0 then v = 0 elseif v > 0.20 then v = 0.20 end
    SetUISetting("zebraAlpha", v)
    if optionsFrame._zebraSliderRules and optionsFrame._zebraSliderRules.SetValue then
      optionsFrame._zebraSliderRules:SetValue(v)
    end
    RefreshFramesList()
    RefreshRulesList()
    optionsFrame._zebraUpdating = false
  end)
  f._zebraSliderFrames = zebraFrames

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
  frameEditTitle:SetPoint("TOPLEFT", 12, -40)
  frameEditTitle:SetText("Settings")
  f._frameEditTitle = frameEditTitle

  local frameEditLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  frameEditLabel:SetPoint("TOPLEFT", 12, -58)
  frameEditLabel:SetText("Select:")
  f._frameEditLabel = frameEditLabel

  local frameDrop = CreateFrame("Frame", nil, panels.frames, "UIDropDownMenuTemplate")
  frameDrop:SetPoint("TOPLEFT", -8, -68)
  -- reuse dropdown helpers if present (quest tab created its own locals above)

  if UDDM_SetWidth then UDDM_SetWidth(frameDrop, 160) end
  if UDDM_SetText then UDDM_SetText(frameDrop, "(pick)") end
  f._frameDrop = frameDrop
  f._selectedFrameID = nil

  local frameAuto = CreateFrame("CheckButton", nil, panels.frames, "UICheckButtonTemplate")
  frameAuto:SetPoint("TOPLEFT", 200, -72)
  SetCheckButtonLabel(frameAuto, "Auto")
  f._frameAuto = frameAuto

  local nameLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  nameLabel:SetPoint("TOPLEFT", 12, -82)
  nameLabel:SetText("Name")
  f._frameNameLabel = nameLabel

  local nameBox = CreateFrame("EditBox", nil, panels.frames, "InputBoxTemplate")
  nameBox:SetSize(180, 20)
  nameBox:SetPoint("TOPLEFT", 55, -88)
  nameBox:SetAutoFocus(false)
  nameBox:SetText("")
  f._frameNameBox = nameBox

  local frameHideCombat = CreateFrame("CheckButton", nil, panels.frames, "UICheckButtonTemplate")
  frameHideCombat:SetPoint("TOPLEFT", 260, -72)
  SetCheckButtonLabel(frameHideCombat, "Hide in combat")
  frameHideCombat:Hide()
  f._frameHideCombat = frameHideCombat

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

  local function DeriveAnchorCornerFromPoint(point)
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

  local function DeriveGrowDirFromPoint(point)
    point = tostring(point or ""):upper()
    local y = point:find("BOTTOM", 1, true) and "up" or "down"
    local x = point:find("RIGHT", 1, true) and "left" or "right"
    return y .. "-" .. x
  end

  -- Unified corner -> grow mapping (keeps Anchor/Grow consistent).
  local function DeriveGrowDirFromCorner(corner)
    corner = NormalizeAnchorCornerLocal(corner) or "tl"
    if corner == "tl" then return "down-right" end
    if corner == "tr" then return "down-left" end
    if corner == "tc" then return "down-right" end
    if corner == "bl" then return "up-right" end
    if corner == "br" then return "up-left" end
    if corner == "bc" then return "up-right" end
    return "down-right"
  end

  local function DeriveCornerFromGrowDir(dir)
    dir = NormalizeGrowDirLocal(dir) or "down-right"
    if dir == "down-right" then return "tl" end
    if dir == "down-left" then return "tr" end
    if dir == "up-right" then return "bl" end
    if dir == "up-left" then return "br" end
    return "tl"
  end

  local function AnchorCornerLabel(corner)
    corner = NormalizeAnchorCornerLocal(corner) or "tl"
    if corner == "tl" then return "Top Left" end
    if corner == "tr" then return "Top Right" end
    if corner == "tc" then return "Center-Top (Align Center)" end
    if corner == "bl" then return "Bottom Left" end
    if corner == "br" then return "Bottom Right" end
    if corner == "bc" then return "Center-Bottom (Align Center)" end
    return "Top Left"
  end

  local function GrowDirLabel(dir)
    dir = NormalizeGrowDirLocal(dir) or "down-right"
    if dir == "up-left" then return "Up-Left" end
    if dir == "up-right" then return "Up-Right" end
    if dir == "down-left" then return "Down-Left" end
    if dir == "down-right" then return "Down-Right" end
    return "Down-Right"
  end

  local function AnchorGrowLabel(corner)
    corner = NormalizeAnchorCornerLocal(corner) or "tl"
    if corner == "tc" or corner == "bc" then
      return AnchorCornerLabel(corner)
    end
    local dir = DeriveGrowDirFromCorner(corner)
    return string.format("%s (%s)", AnchorCornerLabel(corner), GrowDirLabel(dir))
  end

  local anchorPosLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  anchorPosLabel:SetPoint("TOPLEFT", 365, -82)
  anchorPosLabel:SetText("Anchor/Grow")
  f._frameAnchorPosLabel = anchorPosLabel

  local anchorPosDrop = CreateFrame("Frame", nil, panels.frames, "UIDropDownMenuTemplate")
  anchorPosDrop:SetPoint("TOPLEFT", 340, -68)
  if UDDM_SetWidth then UDDM_SetWidth(anchorPosDrop, 170) end
  if UDDM_SetText then UDDM_SetText(anchorPosDrop, "(auto)") end
  f._frameAnchorPosDrop = anchorPosDrop

  local growDirLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  growDirLabel:SetPoint("TOPLEFT", 365, -112)
  growDirLabel:SetText("Grow")
  f._frameGrowDirLabel = growDirLabel

  local growDirDrop = CreateFrame("Frame", nil, panels.frames, "UIDropDownMenuTemplate")
  growDirDrop:SetPoint("TOPLEFT", 340, -98)
  if UDDM_SetWidth then UDDM_SetWidth(growDirDrop, 130) end
  if UDDM_SetText then UDDM_SetText(growDirDrop, "(auto)") end
  f._frameGrowDirDrop = growDirDrop

  -- Grow is now implied by Anchor/Grow; keep the legacy control hidden.
  growDirLabel:Hide()
  growDirDrop:Hide()

  local widthLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  widthLabel:SetPoint("TOPLEFT", 12, -100)
  widthLabel:SetText("Width")
  f._frameWidthLabel = widthLabel

  local widthBox = CreateFrame("EditBox", nil, panels.frames, "InputBoxTemplate")
  widthBox:SetSize(60, 20)
  widthBox:SetPoint("TOPLEFT", 55, -106)
  widthBox:SetAutoFocus(false)
  widthBox:SetNumeric(true)
  widthBox:SetText("0")
  if widthBox.SetJustifyH then widthBox:SetJustifyH("RIGHT") end
  f._frameWidthBox = widthBox

  local function AddGhostLabel(box, text)
    if not (box and box.CreateFontString) then return nil end
    if box.SetTextInsets then box:SetTextInsets(22, 6, 0, 0) end
    local fs = box:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    fs:SetPoint("LEFT", box, "LEFT", 6, 0)
    fs:SetJustifyH("LEFT")
    fs:SetText(tostring(text or ""))
    box._ghostLabel = fs
    return fs
  end

  AddGhostLabel(widthBox, "W")
  if widthLabel and widthLabel.Hide then widthLabel:Hide() end

  local heightLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  heightLabel:SetPoint("TOPLEFT", 125, -100)
  heightLabel:SetText("Height")
  f._frameHeightLabel = heightLabel

  local heightBox = CreateFrame("EditBox", nil, panels.frames, "InputBoxTemplate")
  heightBox:SetSize(60, 20)
  heightBox:SetPoint("TOPLEFT", 175, -106)
  heightBox:SetAutoFocus(false)
  heightBox:SetNumeric(true)
  heightBox:SetText("0")
  if heightBox.SetJustifyH then heightBox:SetJustifyH("RIGHT") end
  f._frameHeightBox = heightBox

  AddGhostLabel(heightBox, "H")
  if heightLabel and heightLabel.Hide then heightLabel:Hide() end

  local lengthLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  lengthLabel:SetPoint("TOPLEFT", 245, -100)
  lengthLabel:SetText("Length")
  f._frameLengthLabel = lengthLabel

  local lengthBox = CreateFrame("EditBox", nil, panels.frames, "InputBoxTemplate")
  lengthBox:SetSize(60, 20)
  lengthBox:SetPoint("TOPLEFT", 292, -106)
  lengthBox:SetAutoFocus(false)
  lengthBox:SetNumeric(true)
  lengthBox:SetText("0")
  if lengthBox.SetJustifyH then lengthBox:SetJustifyH("RIGHT") end
  f._frameLengthBox = lengthBox

  AddGhostLabel(lengthBox, "Len")
  if lengthLabel and lengthLabel.Hide then lengthLabel:Hide() end

  local maxHLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  maxHLabel:SetPoint("TOPLEFT", 365, -100)
  maxHLabel:SetText("Max H")
  f._frameMaxHLabel = maxHLabel

  local maxHBox = CreateFrame("EditBox", nil, panels.frames, "InputBoxTemplate")
  maxHBox:SetSize(60, 20)
  maxHBox:SetPoint("TOPLEFT", 410, -106)
  maxHBox:SetAutoFocus(false)
  maxHBox:SetNumeric(true)
  maxHBox:SetText("0")
  if maxHBox.SetJustifyH then maxHBox:SetJustifyH("RIGHT") end
  f._frameMaxHBox = maxHBox

  AddGhostLabel(maxHBox, "Max")
  if maxHLabel and maxHLabel.Hide then maxHLabel:Hide() end

  -- Background (per-frame)
  local bgLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  bgLabel:SetPoint("TOPLEFT", 12, -130)
  bgLabel:SetText("Background")
  f._frameBgLabel = bgLabel

  local bgSwatch = CreateFrame("Button", nil, panels.frames)
  bgSwatch:SetSize(18, 18)
  bgSwatch:SetPoint("TOPLEFT", 85, -134)
  bgSwatch:EnableMouse(true)
  local swTex = bgSwatch:CreateTexture(nil, "ARTWORK")
  swTex:SetAllPoints()
  if swTex.SetColorTexture then
    swTex:SetColorTexture(0, 0, 0, 1)
  end
  bgSwatch._tex = swTex
  f._frameBgSwatch = bgSwatch

  local bgAlphaSlider = CreateFrame("Slider", "FR0Z3NUIFQT_BGAlphaSlider", panels.frames, "OptionsSliderTemplate")
  bgAlphaSlider:SetPoint("TOPLEFT", 115, -138)
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
      UpdateReverseOrderVisibility("frames")
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

      if optionsFrame._frameAnchorPosDrop then
        if UDDM_SetText then UDDM_SetText(optionsFrame._frameAnchorPosDrop, "(pick)") end
        SetDropDownEnabled(optionsFrame._frameAnchorPosDrop, false)
      end
      if optionsFrame._frameGrowDirDrop then
        if UDDM_SetText then UDDM_SetText(optionsFrame._frameGrowDirDrop, "(pick)") end
        SetDropDownEnabled(optionsFrame._frameGrowDirDrop, false)
      end
      return
    end

    if UDDM_SetText then UDDM_SetText(optionsFrame._frameDrop, GetFrameDisplayNameByID(def.id)) end

    local t = tostring(def.type or "list")
    UpdateReverseOrderVisibility("frames")
    if t == "list" then
      optionsFrame._frameHeightLabel:SetText("Row")
      optionsFrame._frameLengthLabel:SetText("Rows")
      if optionsFrame._frameHeightBox and optionsFrame._frameHeightBox._ghostLabel then
        optionsFrame._frameHeightBox._ghostLabel:SetText("Row")
      end
      if optionsFrame._frameLengthBox and optionsFrame._frameLengthBox._ghostLabel then
        optionsFrame._frameLengthBox._ghostLabel:SetText("Rows")
      end
      optionsFrame._frameHeightBox:SetText(tostring(tonumber(def.rowHeight) or 16))
      if optionsFrame._frameMaxHBox then
        optionsFrame._frameMaxHBox:SetText(tostring(tonumber(def.maxHeight) or 0))
        optionsFrame._frameMaxHBox:SetEnabled(true)
      end
    else
      optionsFrame._frameHeightLabel:SetText("Height")
      optionsFrame._frameLengthLabel:SetText("Segments")
      if optionsFrame._frameHeightBox and optionsFrame._frameHeightBox._ghostLabel then
        optionsFrame._frameHeightBox._ghostLabel:SetText("H")
      end
      if optionsFrame._frameLengthBox and optionsFrame._frameLengthBox._ghostLabel then
        optionsFrame._frameLengthBox._ghostLabel:SetText("Seg")
      end
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

    if optionsFrame._frameAnchorPosDrop then
      local corner = NormalizeAnchorCornerLocal(def.anchorCorner) or "tl"
      -- Bars support center-top/center-bottom alignment; lists are corners only.
      if t ~= "bar" and (corner == "tc" or corner == "bc") then
        corner = "tl"
      end
      if UDDM_SetText then UDDM_SetText(optionsFrame._frameAnchorPosDrop, AnchorGrowLabel(corner)) end
      SetDropDownEnabled(optionsFrame._frameAnchorPosDrop, true)
    end

    if optionsFrame._frameGrowDirDrop then
      local corner = NormalizeAnchorCornerLocal(def.anchorCorner) or "tl"
      local dir = DeriveGrowDirFromCorner(corner)
      if UDDM_SetText then UDDM_SetText(optionsFrame._frameGrowDirDrop, GrowDirLabel(dir)) end
      SetDropDownEnabled(optionsFrame._frameGrowDirDrop, false)
      if optionsFrame._frameGrowDirLabel then optionsFrame._frameGrowDirLabel:Hide() end
      optionsFrame._frameGrowDirDrop:Hide()
    end

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
    local modernFrameDrop = UseModernMenuDropDown(frameDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Select frame") end
      for _, def in ipairs(GetEffectiveFrames()) do
        if type(def) == "table" and def.id and root then
          local id = tostring(def.id)
          local label = GetFrameDisplayNameByID(id)
          local function IsSelected()
            return (optionsFrame and optionsFrame._selectedFrameID == id) and true or false
          end
          local function SetSelected()
            optionsFrame._selectedFrameID = id
            UpdateFrameEditor()
            UpdateReverseOrderVisibility("frames")
          end
          if root.CreateRadio then
            root:CreateRadio(label, IsSelected, SetSelected)
          elseif root.CreateButton then
            root:CreateButton(label, SetSelected)
          end
        end
      end
    end)

    if not modernFrameDrop then
      UDDM_Initialize(frameDrop, function(self, level)
        local info = UDDM_CreateInfo()
        for _, def in ipairs(GetEffectiveFrames()) do
          if type(def) == "table" and def.id then
            local id = tostring(def.id)
            info.text = GetFrameDisplayNameByID(id)
            info.checked = (optionsFrame and optionsFrame._selectedFrameID == id) and true or false
            info.func = function()
              optionsFrame._selectedFrameID = id
              UpdateFrameEditor()
              UpdateReverseOrderVisibility("frames")
            end
            UDDM_AddButton(info)
          end
        end
      end)
    end
  else
    frameEditLabel:SetText("Select frame: (dropdown unavailable)")
  end

  local function ApplySelectedFrameAnchorCorner(corner)
    if not optionsFrame then return end
    local id = tostring(optionsFrame._selectedFrameID or "")
    if id == "" then return end
    local eff = FindEffectiveFrameDef(id)
    if not eff then return end
    local def = FindOrCreateCustomFrameDef(id)
    if not def then return end

    corner = NormalizeAnchorCornerLocal(corner)
    def.anchorCorner = corner

    -- Unify grow direction with the chosen corner.
    def.growDir = DeriveGrowDirFromCorner(corner)

    -- Follow the configured anchor rules (no screen-coordinate conversion).
    -- Update the frame's stored anchor point and clear any saved dragged position
    -- so the new anchor is actually applied.
    do
      local point
      if corner == "tc" then
        point = "TOP"
      elseif corner == "bc" then
        point = "BOTTOM"
      else
        point = (corner == "tr" and "TOPRIGHT") or (corner == "bl" and "BOTTOMLEFT") or (corner == "br" and "BOTTOMRIGHT") or "TOPLEFT"
      end

      def.point = point
      def.relPoint = point

      if type(ns.ClearSavedFramePosition) == "function" then
        ns.ClearSavedFramePosition(id)
      end
    end

    RefreshAll()
    RefreshFramesList()
  end

  local function ApplySelectedFrameGrowDir(dir)
    if not optionsFrame then return end
    local id = tostring(optionsFrame._selectedFrameID or "")
    if id == "" then return end
    local eff = FindEffectiveFrameDef(id)
    if not eff then return end
    local def = FindOrCreateCustomFrameDef(id)
    if not def then return end
    dir = NormalizeGrowDirLocal(dir)
    def.growDir = dir
    def.anchorCorner = DeriveCornerFromGrowDir(dir)
    RefreshAll()
    RefreshFramesList()
  end

  if UseModernMenuDropDown(anchorPosDrop, function(root)
    if root and root.CreateTitle then root:CreateTitle("Anchor") end
    local cur = nil
    local isBar = false
    do
      local id = tostring(optionsFrame and optionsFrame._selectedFrameID or "")
      local eff = (id ~= "") and FindEffectiveFrameDef(id) or nil
      cur = (type(eff) == "table") and NormalizeAnchorCornerLocal(eff.anchorCorner) or nil
      isBar = (type(eff) == "table" and tostring(eff.type or "list") == "bar") and true or false
      if not cur then cur = "tl" end
      if not isBar and (cur == "tc" or cur == "bc") then cur = "tl" end
    end
    local choices = isBar and { "tl", "tc", "tr", "bl", "bc", "br" } or { "tl", "tr", "bl", "br" }
    for _, v in ipairs(choices) do
      if root and root.CreateRadio then
        root:CreateRadio(AnchorGrowLabel(v), function() return cur == v end, function() ApplySelectedFrameAnchorCorner(v) end)
      elseif root and root.CreateButton then
        root:CreateButton(AnchorGrowLabel(v), function() ApplySelectedFrameAnchorCorner(v) end)
      end
    end
  end) then
    -- modern menu wired
  elseif UDDM_Initialize and UDDM_CreateInfo and UDDM_AddButton then
    UDDM_Initialize(anchorPosDrop, function(self, level)
      local isBar = false
      do
        local id = tostring(optionsFrame and optionsFrame._selectedFrameID or "")
        local eff = (id ~= "") and FindEffectiveFrameDef(id) or nil
        isBar = (type(eff) == "table" and tostring(eff.type or "list") == "bar") and true or false
      end
      local choices = isBar and { "tl", "tc", "tr", "bl", "bc", "br" } or { "tl", "tr", "bl", "br" }
      for _, v in ipairs(choices) do
        local info = UDDM_CreateInfo()
        info.text = AnchorGrowLabel(v)
        info.func = function() ApplySelectedFrameAnchorCorner(v) end
        UDDM_AddButton(info)
      end
    end)
  end

  if UseModernMenuDropDown(growDirDrop, function(root)
    if root and root.CreateTitle then root:CreateTitle("Grow") end
    local cur = nil
    do
      local id = tostring(optionsFrame and optionsFrame._selectedFrameID or "")
      local eff = (id ~= "") and FindEffectiveFrameDef(id) or nil
      cur = (type(eff) == "table") and NormalizeGrowDirLocal(eff.growDir) or nil
      if not cur then cur = "down-right" end
    end
    for _, v in ipairs({ "up-left", "up-right", "down-left", "down-right" }) do
      if root and root.CreateRadio then
        root:CreateRadio(GrowDirLabel(v), function() return cur == v end, function() ApplySelectedFrameGrowDir(v) end)
      elseif root and root.CreateButton then
        root:CreateButton(GrowDirLabel(v), function() ApplySelectedFrameGrowDir(v) end)
      end
    end
  end) then
    -- modern menu wired
  elseif UDDM_Initialize and UDDM_CreateInfo and UDDM_AddButton then
    UDDM_Initialize(growDirDrop, function(self, level)
      for _, v in ipairs({ "up-left", "up-right", "down-left", "down-right" }) do
        local info = UDDM_CreateInfo()
        info.text = GrowDirLabel(v)
        info.func = function() ApplySelectedFrameGrowDir(v) end
        UDDM_AddButton(info)
      end
    end)
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

    local zebraA = tonumber(GetUISetting("zebraAlpha", 0.05) or 0.05) or 0.05
    if zebraA < 0 then zebraA = 0 elseif zebraA > 0.20 then zebraA = 0.20 end

    for i = 1, #frames do
      local def = frames[i]
      local row = frows[i]
      if not row then
        row = CreateFrame("Frame", nil, fcontent)
        row:SetHeight(rowH)

        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        row.bg:Hide()

        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.text:SetPoint("LEFT", 2, 0)
        row.text:SetJustifyH("LEFT")

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

      if row.bg then
        if row.bg.SetColorTexture then
          row.bg:SetColorTexture(1, 1, 1, zebraA)
        elseif row.bg.SetVertexColor then
          row.bg:SetVertexColor(1, 1, 1, zebraA)
        end
        if row.bg.SetShown then
          row.bg:SetShown((i % 2) == 0 and zebraA > 0)
        else
          if (i % 2) == 0 and zebraA > 0 then row.bg:Show() else row.bg:Hide() end
        end
      end

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

    end
  end

  if not (type(ns) == "table" and type(ns.FQTOptionsPanels) == "table" and type(ns.FQTOptionsPanels.BuildRules) == "function") then
  RefreshRulesList = function()
    if not optionsFrame then return end

    local function RuleKey(rule)
      if ns and ns.RuleKey then
        return ns.RuleKey(rule)
      end
      if type(rule) ~= "table" then return nil end
      if rule.key ~= nil then return tostring(rule.key) end
      if rule.questID then return "q:" .. tostring(rule.questID) end
      if rule.label then return "label:" .. tostring(rule.label) end
      if rule.group then return "group:" .. tostring(rule.group) .. ":" .. tostring(rule.order or 0) end
      return nil
    end

    local function GetDefaultRuleEdits()
      if ns and ns.GetDefaultRuleEdits then
        return ns.GetDefaultRuleEdits() or {}
      end
      return {}
    end

    local function GetEffectiveDefaultRule(baseRule)
      local edits = GetDefaultRuleEdits()
      local key = RuleKey(baseRule)
      local r2 = key and edits[key] or nil
      return (type(r2) == "table") and r2 or baseRule
    end

    local function IsDefaultRuleEdited(baseRule)
      local edits = GetDefaultRuleEdits()
      local key = RuleKey(baseRule)
      return (key and type(edits[key]) == "table") and true or false
    end

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
    elseif view == "trash" then
      list = GetCustomRulesTrash()
    elseif view == "custom" then
      list = GetCustomRules()
    else
      -- all: defaults + custom
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
    end

    if optionsFrame._rulesTitle then
      optionsFrame._rulesTitle:SetText("Rules")
    end

    local rowH = 18
    local content = optionsFrame._rulesContent
    local rows = optionsFrame._ruleRows
    if optionsFrame._rulesScroll and content then
      local w = tonumber(optionsFrame._rulesScroll:GetWidth() or 0) or 0
      content:SetWidth(math.max(1, w - 28))
    end
    content:SetHeight(math.max(1, #list * rowH))

    local zebraA = tonumber(GetUISetting("zebraAlpha", 0.05) or 0.05) or 0.05
    if zebraA < 0 then zebraA = 0 elseif zebraA > 0.20 then zebraA = 0.20 end

    local displayByID = {}
    for _, def in ipairs(GetEffectiveFrames() or {}) do
      if type(def) == "table" and def.id then
        local id = tostring(def.id)
        displayByID[id] = GetFrameDisplayNameByID(id)
      end
    end

    local function GetSortedFrameIDs()
      local ids = {}
      for _, def in ipairs(GetEffectiveFrames() or {}) do
        if type(def) == "table" and def.id then
          local id = tostring(def.id)
          if id ~= "" then
            ids[#ids + 1] = id
          end
        end
      end
      table.sort(ids, function(a, b)
        local da = displayByID[a] or a
        local db = displayByID[b] or b
        return tostring(da) < tostring(db)
      end)
      return ids
    end

    local function GetPrimaryFrameID(rule)
      if type(rule) ~= "table" then return nil end
      if rule.frameID ~= nil then return tostring(rule.frameID) end
      if type(rule.targets) == "table" and rule.targets[1] ~= nil then
        return tostring(rule.targets[1])
      end
      return nil
    end

    local function SetRulePrimaryFrame(baseRule, displayRule, newID, src)
      newID = tostring(newID or "")
      if newID == "" then return end

      if src == "default" then
        local key = RuleKey(baseRule)
        if not key or key == "" then return end
        local edits = GetDefaultRuleEdits()
        local edited = DeepCopyValue(displayRule)
        edited.frameID = newID
        edited.targets = nil
        edits[key] = edited
        return
      end

      if type(baseRule) ~= "table" then return end
      baseRule.frameID = newID
      baseRule.targets = nil
    end

    local function GetRuleFramesLabel(rule)
      if type(rule) ~= "table" then return "" end
      local ids = {}
      local seen = {}

      local function AddID(v)
        local id = tostring(v or "")
        if id == "" then return end
        if seen[id] then return end
        seen[id] = true
        ids[#ids + 1] = id
      end

      if rule.frameID then AddID(rule.frameID) end
      if type(rule.targets) == "table" then
        for _, v in ipairs(rule.targets) do
          AddID(v)
        end
      end

      if #ids == 0 then return "" end
      local first = displayByID[ids[1]] or ids[1]
      if #ids == 1 then return first end
      return string.format("%s +%d", tostring(first), (#ids - 1))
    end

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

    local function SetRowRuleText(row, prefix, baseText, suffix, maxW)
      if not (row and row.text and row.text.SetText) then return end
      maxW = tonumber(maxW) or 0
      if maxW <= 0 or not row.text.GetStringWidth then
        row.text:SetText(tostring(prefix or "") .. tostring(baseText or "") .. tostring(suffix or ""))
        return
      end

      local full = tostring(prefix or "") .. tostring(baseText or "") .. tostring(suffix or "")
      row.text:SetText(full)
      if (row.text:GetStringWidth() or 0) <= maxW then return end

      local b = tostring(baseText or "")
      local ell = "..."
      local lo, hi = 0, #b
      local best = ""
      while lo <= hi do
        local mid = math.floor((lo + hi) / 2)
        local candidate = tostring(prefix or "") .. b:sub(1, mid) .. ell .. tostring(suffix or "")
        row.text:SetText(candidate)
        if (row.text:GetStringWidth() or 0) <= maxW then
          best = b:sub(1, mid)
          lo = mid + 1
        else
          hi = mid - 1
        end
      end
      row.text:SetText(tostring(prefix or "") .. best .. ell .. tostring(suffix or ""))
    end

    for i = 1, #list do
      local r = list[i]
      local row = rows[i]
      if not row then
        row = CreateFrame("Frame", nil, content)
        row:SetHeight(rowH)
        row:EnableMouse(true)
        if row.SetClipsChildren then row:SetClipsChildren(true) end

        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        if row.bg.SetColorTexture then
          row.bg:SetColorTexture(1, 1, 1, 0.05)
        end
        row.bg:Hide()

        row.toggle = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        row.toggle:SetSize(18, 18)
        row.toggle:SetPoint("LEFT", 0, 0)

        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.text:SetPoint("LEFT", row.toggle, "RIGHT", 4, 0)
        row.text:SetJustifyH("LEFT")
        if row.text.SetMaxLines then row.text:SetMaxLines(1) end
        if row.text.SetWordWrap then row.text:SetWordWrap(false) end
        if row.text.SetNonSpaceWrap then row.text:SetNonSpaceWrap(false) end

        row.frameDrop = CreateFrame("Frame", nil, row, "UIDropDownMenuTemplate")
        if HideDropDownMenuArt then HideDropDownMenuArt(row.frameDrop) end
        row.frameDrop:SetAlpha(0.85)

        row.frameDropHit = CreateFrame("Button", nil, row)
        row.frameDropHit:EnableMouse(true)
        row.frameDropHit:SetAlpha(0.01)

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

        row.frameDrop:SetPoint("RIGHT", row.action, "LEFT", 0, -2)
        local UDDM_SetWidth = _G and rawget(_G, "UIDropDownMenu_SetWidth")
        if UDDM_SetWidth then UDDM_SetWidth(row.frameDrop, 150) end
        row.frameDropHit:SetPoint("TOPLEFT", row.frameDrop, "TOPLEFT", 18, -2)
        row.frameDropHit:SetPoint("BOTTOMRIGHT", row.frameDrop, "BOTTOMRIGHT", -18, 2)

        row.text:SetPoint("RIGHT", row.frameDrop, "LEFT", -6, 0)

        rows[i] = row
      end

      row:SetPoint("TOPLEFT", 0, -(i - 1) * rowH)
      row:SetPoint("TOPRIGHT", 0, -(i - 1) * rowH)

      if row.bg then
        if row.bg.SetColorTexture then
          row.bg:SetColorTexture(1, 1, 1, zebraA)
        elseif row.bg.SetVertexColor then
          row.bg:SetVertexColor(1, 1, 1, zebraA)
        end
        if row.bg.SetShown then
          row.bg:SetShown((i % 2) == 0 and zebraA > 0)
        else
          if (i % 2) == 0 and zebraA > 0 then row.bg:Show() else row.bg:Hide() end
        end
      end

      local src = (view == "defaults") and "default" or (view == "trash") and "trash" or (view == "custom") and "custom" or (sourceOf and sourceOf[r])
      local displayRule = (src == "default") and GetEffectiveDefaultRule(r) or r

      if row.frameDrop then
        if src == "trash" then
          row.frameDrop:Hide()
          if row.frameDropHit then row.frameDropHit:Hide() end
        else
          row.frameDrop:Show()
          if row.frameDropHit then row.frameDropHit:Show() end

          local primary = GetPrimaryFrameID(displayRule)
          local UDDM_SetText = _G and rawget(_G, "UIDropDownMenu_SetText")
          if UDDM_SetText then
            UDDM_SetText(row.frameDrop, primary and (displayByID[primary] or primary) or "(none)")
          end

          local UDDM_Initialize = _G and rawget(_G, "UIDropDownMenu_Initialize")
          local UDDM_CreateInfo = _G and rawget(_G, "UIDropDownMenu_CreateInfo")
          local UDDM_AddButton = _G and rawget(_G, "UIDropDownMenu_AddButton")

          if UDDM_Initialize and UDDM_CreateInfo and UDDM_AddButton then
            UDDM_Initialize(row.frameDrop, function(_, level)
              if level ~= 1 then return end
              for _, id in ipairs(GetSortedFrameIDs()) do
                local info = UDDM_CreateInfo()
                info.text = displayByID[id] or id
                info.checked = (primary == id)
                info.func = function()
                  SetRulePrimaryFrame(r, displayRule, id, src)
                  RefreshAll()
                  RefreshRulesList()
                end
                UDDM_AddButton(info)
              end
            end)
          end

          if row.frameDropHit then
            row.frameDropHit:SetScript("OnClick", function()
              local toggle = _G and rawget(_G, "ToggleDropDownMenu")
              if toggle then
                toggle(1, nil, row.frameDrop, row.frameDrop, 0, 0)
              end
            end)
          end
        end
      end

      local disabled = IsRuleDisabled(r)
      row.toggle:SetChecked(not disabled)
      if disabled then
        row.text:SetFontObject("GameFontDisableSmall")
      else
        row.text:SetFontObject("GameFontHighlightSmall")
      end

      local function IsItemRule(rr)
        return type(rr) == "table" and type(rr.item) == "table" and rr.item.itemID ~= nil
      end

      local function FactionColor(rr)
        local fac = (type(rr) == "table") and tostring(rr.faction or "") or ""
        if fac == "Alliance" then
          return "|cff3399ff" -- blue
        end
        if fac == "Horde" then
          return "|cffff3333" -- red
        end
        return "|cffffd100" -- yellow (both/off)
      end

      local isDB = (src == "default" or src == "auto")
      local baseText = FormatRuleText(displayRule)
      if isDB and IsItemRule(displayRule) then
        baseText = baseText .. " *"
      end

      local c = FactionColor(displayRule)
      if src == "trash" then
        c = "|cffff3333" -- red
      end

      local editedMark = (src == "default" and IsDefaultRuleEdited(r)) and "|cff00ff00*|r " or ""

      -- Anchor/width depends on whether the enable toggle is shown.
      row.text:ClearAllPoints()
      if view == "trash" then
        row.text:SetPoint("LEFT", row, "LEFT", 2, 0)
      else
        row.text:SetPoint("LEFT", row.toggle, "RIGHT", 4, 0)
      end
      row.text:SetPoint("RIGHT", row.frameDrop, "LEFT", -6, 0)
      if row.text.SetWidth and content and content.GetWidth then
        local totalW = tonumber(content:GetWidth() or 0) or 0
        local leftPad = (view == "trash") and 2 or (18 + 4)
        local rightPad = 6 + 150 + 6
        local maxW = totalW - leftPad - rightPad
        if maxW < 50 then maxW = 50 end
        row.text:SetWidth(maxW)
        SetRowRuleText(row, editedMark .. c, baseText, "|r", maxW)
      else
        row.text:SetText(editedMark .. c .. baseText .. "|r")
      end

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

      -- Always show move arrows for consistent UI; disable them when reordering isn't allowed.
      local function DisableMoveButtons()
        row.up:Show(); row.down:Show()
        row.up:SetEnabled(false)
        row.down:SetEnabled(false)
        row.up:SetScript("OnClick", nil)
        row.down:SetScript("OnClick", nil)
      end

      if view == "custom" then
        row.up:Show(); row.down:Show()
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
        DisableMoveButtons()
        row:SetScript("OnMouseUp", nil)
        row.action:SetText("Edit")
        row.action:Show()
        row.action:SetScript("OnClick", function()
          local base = list[idx]
          if type(base) ~= "table" then return end

          if OpenDefaultRuleInTab then
            OpenDefaultRuleInTab(base)
          end
        end)

        if IsDefaultRuleEdited(list[idx]) then
          row.del:Show()
          row.del:SetScript("OnClick", function()
            if not (IsShiftKeyDown and IsShiftKeyDown()) then
              Print("Hold SHIFT and click X to reset this default rule edit.")
              return
            end
            local base = list[idx]
            local key = RuleKey(base)
            if not key or key == "" then return end
            local edits = GetDefaultRuleEdits()
            edits[key] = nil
            RefreshAll()
            RefreshRulesList()
            Print("Reset default rule edits.")
          end)
        else
          row.del:Hide()
        end
      elseif view == "trash" then
        DisableMoveButtons()
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
          DisableMoveButtons()
          row.action:SetText("Edit")
          row.action:Show()
          row.action:SetScript("OnClick", function()
            local base = r
            if type(base) ~= "table" then return end

            if OpenDefaultRuleInTab then
              OpenDefaultRuleInTab(base)
            end
          end)

          if IsDefaultRuleEdited(r) then
            row.del:Show()
            row.del:SetScript("OnClick", function()
              if not (IsShiftKeyDown and IsShiftKeyDown()) then
                Print("Hold SHIFT and click X to reset this default rule edit.")
                return
              end
              local key = RuleKey(r)
              if not key or key == "" then return end
              local edits = GetDefaultRuleEdits()
              edits[key] = nil
              RefreshAll()
              RefreshRulesList()
              Print("Reset default rule edits.")
            end)
          else
            row.del:Hide()
          end
        elseif src2 == "custom" then
          row.up:Show(); row.down:Show()
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
          DisableMoveButtons()
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
  resetBtn:SetText("Reset Layout")
  resetBtn:SetScript("OnClick", function()
    ResetFramePositionsToDefaults()
    RefreshAll()
    RefreshActiveTab()
    Print("Layout reset to defaults.")
  end)

  resetBtn:SetScript("OnEnter", function(self)
    if not GameTooltip then return end
    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
    GameTooltip:SetText("Reset Layout")
    GameTooltip:AddLine("Resets frame positions for the active layout.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  resetBtn:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

  local reloadBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  reloadBtn:SetSize(160, 22)
  reloadBtn:SetPoint("BOTTOMRIGHT", -12, 12)
  reloadBtn:SetText("Reload UI")
  reloadBtn:SetScript("OnClick", function()
    local r = _G and _G["ReloadUI"]
    if r then r() end
  end)

  -- Unlabeled: reverse display order (bars)
  local reverseOrderBtn = CreateFrame("CheckButton", nil, panels.frames, "UICheckButtonTemplate")
  reverseOrderBtn:SetSize(24, 24)
  reverseOrderBtn:SetPoint("BOTTOMRIGHT", reloadBtn, "TOPRIGHT", 0, 6)
  reverseOrderBtn:Hide()
  reverseOrderBtn:SetScript("OnClick", function(self)
    local v = (self and self.GetChecked and self:GetChecked()) and true or false
    SetUISetting("reverseOrder", v)
    RefreshAll()
  end)
  reverseOrderBtn:SetScript("OnEnter", function(self)
    if not GameTooltip then return end
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Reverse order", 1, 1, 1)
    GameTooltip:AddLine("Bars: left->right (default) becomes right->left.", 0.85, 0.85, 0.85, true)
    GameTooltip:Show()
  end)
  reverseOrderBtn:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

  local function SyncReverseOrderToggle()
    local v = GetUISetting("reverseOrder", false) and true or false
    if reverseOrderBtn and reverseOrderBtn.SetChecked then
      reverseOrderBtn:SetChecked(v)
    end
  end
  SyncReverseOrderToggle()
  f._reverseOrderBtn = reverseOrderBtn

  f._resetBtn = resetBtn
  f._reloadBtn = reloadBtn

  optionsFrame = f
  -- default tab (persisted)
  local initial = tostring(GetUISetting("optionsTab", "frames") or "frames")
  if not panels[initial] then initial = "frames" end
  SelectTab(initial)
  UpdateReverseOrderVisibility(initial)
  return f
end

local function ShowOptions()
  editMode = true
  SetCoreEditMode(true)
  RefreshAll()
  local f = EnsureOptionsFrame()
  if not f then
    Print("Options UI frame unavailable.")
    return
  end
  if RefreshActiveTab then RefreshActiveTab() end
  f:Show()
end

-- WeakAuras tooling is implemented in fr0z3nUI_QuestTracker_WeakAuras.lua.
-- Keep a small shim here so the slash command can still open the importer if the module loaded.

-- Exports for the core and other modules
ns.EnsureOptionsFrame = EnsureOptionsFrame
ns.ShowOptions = ShowOptions
ns.IsOptionsOpen = function() return (optionsFrame and optionsFrame.IsShown and optionsFrame:IsShown()) and true or false end
ns.RefreshOptionsActiveTab = function() if optionsFrame and RefreshActiveTab then return RefreshActiveTab() end end
ns.RefreshRulesList = function() if optionsFrame and RefreshRulesList then return RefreshRulesList() end end
ns.RefreshFramesList = function() if optionsFrame and RefreshFramesList then return RefreshFramesList() end end
