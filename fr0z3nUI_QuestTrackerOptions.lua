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

local function NormalizePlayerLevelOpLite(op)
  op = tostring(op or ""):gsub("%s+", "")
  if op == "" then return nil end
  if op == "==" then op = "=" end
  if op == "~=" then op = "!=" end
  if op == "<" or op == "<=" or op == "=" or op == ">=" or op == ">" or op == "!=" then
    return op
  end
  return nil
end

local function GetPlayerLevelGateFromRule(rule)
  if type(rule) ~= "table" then return nil, nil end

  local op, lvl
  if type(rule.playerLevel) == "table" then
    op = rule.playerLevel[1]
    lvl = rule.playerLevel[2]
  else
    op = rule.playerLevelOp
    lvl = rule.playerLevel
  end

  op = NormalizePlayerLevelOpLite(op)
  lvl = tonumber(lvl)
  if not op or not lvl or lvl <= 0 then return nil, nil end
  return op, lvl
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

  local tabBarBG = CreateFrame("Frame", nil, f, "BackdropTemplate")
  tabBarBG:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -4)
  tabBarBG:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
  tabBarBG:SetHeight(26)
  tabBarBG:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    tile = true,
    tileSize = 16,
    insets = { left = 0, right = 0, top = 0, bottom = 0 },
  })
  tabBarBG:SetBackdropColor(0, 0, 0, 0.92)
  tabBarBG:SetFrameLevel((f.GetFrameLevel and f:GetFrameLevel() or 0) + 1)
  f._tabBarBG = tabBarBG

  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)

  local title = tabBarBG:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("RIGHT", close, "LEFT", -6, 0)
  title:SetJustifyH("RIGHT")
  title:SetText("|cff00ccff[FQT]|r")
  do
    local fontPath, fontSize, fontFlags = title:GetFont()
    if fontPath and fontSize then
      title:SetFont(fontPath, fontSize + 2, fontFlags)
    end
  end
  title:Show()

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

  local function HideStrayEditTabScrollbars(activePanel)
    if not (activePanel and activePanel.GetHeight and activePanel.GetNumChildren and activePanel.GetChildren) then return end

    local C_Timer = _G and rawget(_G, "C_Timer")

    local panelH = tonumber(activePanel:GetHeight() or 0) or 0
    if panelH <= 0 then return end

    local function ShouldHideTallSlider(slider)
      if not (slider and slider.IsShown and slider:IsShown()) then return false end
      if slider._fqtHiddenStrayScrollbar then return false end
      if not (slider.GetObjectType and slider:GetObjectType() == "Slider") then return false end

      local w, h = 0, 0
      if slider.GetSize then
        w, h = slider:GetSize()
      end
      w = tonumber(w or 0) or 0
      h = tonumber(h or 0) or 0

      -- Only target the reported artifact: tall + narrow (roughly panel height).
      -- Avoid legitimate edit-tab scrollframes (they are much shorter: ~40-100px).
      if not (w > 0 and w <= 30 and h >= (panelH - 50)) then
        return false
      end

      -- Prefer geometric detection: a full-height scrollbar hugging the panel's right edge.
      local sr = slider.GetRight and slider:GetRight() or nil
      local pr = activePanel.GetRight and activePanel:GetRight() or nil
      if sr and pr and math.abs(sr - pr) <= 6 then
        return true
      end

      -- Fall back to anchor inspection.
      if slider.GetPoint then
        local p1, rel, p2 = slider:GetPoint(1)
        p1 = tostring(p1 or "")
        p2 = tostring(p2 or "")
        if (p1:find("RIGHT") or p2:find("RIGHT")) and (rel == activePanel or rel == f) then
          return true
        end
      end

      return false
    end

    local function ScanForTallRightSliders(parent, depth)
      if not (parent and parent.GetNumChildren and parent.GetChildren) then return end
      depth = tonumber(depth or 0) or 0
      if depth > 4 then return end

      local children = { parent:GetChildren() }
      for i = 1, #children do
        local child = children[i]
        if child and child.IsShown and child:IsShown() then
          if ShouldHideTallSlider(child) then
            child:Hide()
            child._fqtHiddenStrayScrollbar = true
          end
          if child.GetNumChildren and child.GetChildren then
            ScanForTallRightSliders(child, depth + 1)
          end
        end
      end
    end

    -- The reported artifact looks like a full-height scrollbar on the right edge.
    -- It may be nested (e.g., scrollframe -> ScrollBar slider), so scan a few levels deep.
    ScanForTallRightSliders(activePanel, 0)
    ScanForTallRightSliders(f, 0)

    -- Some UI widgets appear a frame later; run again on the next frame.
    if C_Timer and C_Timer.After then
      C_Timer.After(0, function()
        if activePanel and activePanel.IsShown and activePanel:IsShown() then
          ScanForTallRightSliders(activePanel, 0)
          ScanForTallRightSliders(f, 0)
        end
      end)
    end
  end

  do
    local function HookEditPanelScrollbarHide(panel)
      if not (panel and panel.HookScript) then return end
      if panel._fqtHookedStrayScrollbarHide then return end
      panel._fqtHookedStrayScrollbarHide = true
      panel:HookScript("OnShow", function(self)
        HideStrayEditTabScrollbars(self)
      end)
    end
    HookEditPanelScrollbarHide(panels.quest)
    HookEditPanelScrollbarHide(panels.items)
    HookEditPanelScrollbarHide(panels.text)
    HookEditPanelScrollbarHide(panels.spells)
  end

  local function SetPanelShown(name)
    for k, p in pairs(panels) do
      p:SetShown(k == name)
    end

    if name == "quest" or name == "items" or name == "text" or name == "spells" then
      HideStrayEditTabScrollbars(panels[name])
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
    rules = "Tracking",
    items = "Items",
    quest = "Quest",
    spells = "Spell",
    text = "Text",
  }
  local tabs = {}

  local function SizeTabToText(btn)
    if not btn then return end
    local fs = (btn.GetFontString and btn:GetFontString()) or btn.Text or btn.text
    local w = fs and fs.GetStringWidth and fs:GetStringWidth() or 0
    w = (tonumber(w) or 0) + 24
    if w < 60 then w = 60 end
    btn:SetSize(w, 18)
  end

  local function SelectTab(name)
    SetPanelShown(name)
    for _, btn in ipairs(tabs) do
      btn:SetEnabled(btn._tabName ~= name)
    end
  end

  for i, name in ipairs(tabOrder) do
    local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btn:SetText(tabText[name] or name)
    btn._tabName = name

    SizeTabToText(btn)

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
      btn:SetPoint("LEFT", tabBarBG, "LEFT", 8, 0)
    else
      btn:SetPoint("LEFT", tabs[i - 1], "RIGHT", -8, 0)
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

      ---@diagnostic disable-next-line: duplicate-set-field
      CPF.func = function()
        local r, g, b = CPF:GetColorRGB()
        r, g, b = NormalizeRGB(r, g, b)
        if onChanged then onChanged(r, g, b) end
      end

      ---@diagnostic disable-next-line: duplicate-set-field
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

    local function LibStubGetLibrary(major, silent)
      if type(major) ~= "string" then return nil end
      local ls = _G and rawget(_G, "LibStub")
      if not ls then return nil end

      if type(ls) == "table" and type(ls.GetLibrary) == "function" then
        local ok, lib = pcall(ls.GetLibrary, ls, major, silent)
        if ok and lib ~= nil then return lib end
      end

      local mt = (type(ls) == "table") and getmetatable(ls) or nil
      if type(ls) == "function" or (mt and type(mt.__call) == "function") then
        local ok, lib = pcall(ls, major, silent)
        if ok and lib ~= nil then return lib end
      end
      return nil
    end

    local function GetLibSharedMedia()
      do
        local la = _G and rawget(_G, "LoadAddOn")
        if type(la) == "function" then
          pcall(la, "LibSharedMedia-3.0")
        end
      end
      local lib = LibStubGetLibrary("LibSharedMedia-3.0", true)
      if type(lib) == "table" then return lib end
      return nil
    end

    local function GetFontChoiceLabel(key)
      key = tostring(key or "inherit")
      if key == "" or key:lower() == "inherit" then
        return "Inherit"
      end
      local lsmName = key:match("^lsm:(.+)$")
      if lsmName and lsmName ~= "" then
        return "LSM: " .. lsmName
      end
      return key
    end

    local function GetFontChoices()
      local out = {}
      out[#out + 1] = { key = "inherit", label = "Inherit" }

      -- Common Blizzard font objects (only include those that exist).
      for _, name in ipairs({
        "GameFontNormal",
        "GameFontHighlight",
        "GameFontNormalLarge",
        "GameFontNormalSmall",
        "GameFontDisableSmall",
        "ChatFontNormal",
      }) do
        local obj = _G and rawget(_G, name)
        if obj and obj.GetFont then
          out[#out + 1] = { key = name, label = name }
        end
      end

      local lsm = GetLibSharedMedia()
      if lsm and lsm.List then
        local ok, list = pcall(lsm.List, lsm, "font")
        if ok and type(list) == "table" then
          table.sort(list)
          for _, n in ipairs(list) do
            if type(n) == "string" and n ~= "" then
              out[#out + 1] = { key = "lsm:" .. n, label = "LSM: " .. n }
            end
          end
        end
      end

      return out
    end

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

      GetFontChoices = GetFontChoices,
      GetFontChoiceLabel = GetFontChoiceLabel,

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
    -- (legacy block removed)\r\n

  end

  -- ITEMS tab (Items module)
  local useItemsModule = type(ns) == "table" and type(ns.FQTOptionsPanels) == "table" and type(ns.FQTOptionsPanels.BuildItems) == "function"
  if useItemsModule then
    ns.FQTOptionsPanels.BuildItems(GetOptionsCtx())
  else
    -- Legacy Items tab UI moved to fr0z3nUI_QuestTrackerItems.lua
    -- (legacy block removed)\r\n

  end

  -- TEXT tab (Text module)
  local useTextModule = type(ns) == "table" and type(ns.FQTOptionsPanels) == "table" and type(ns.FQTOptionsPanels.BuildText) == "function"
  if useTextModule then
    ns.FQTOptionsPanels.BuildText(GetOptionsCtx())
  else
    -- Legacy Text tab UI moved to fr0z3nUI_QuestTrackerText.lua
    -- (legacy block removed)\r\n

  end

  -- SPELLS tab (Spells module)
  do
    local useSpellsModule = type(ns) == "table" and type(ns.FQTOptionsPanels) == "table" and type(ns.FQTOptionsPanels.BuildSpells) == "function"
    if useSpellsModule then
      ns.FQTOptionsPanels.BuildSpells(GetOptionsCtx())
    else
      -- Legacy spells UI moved to fr0z3nUI_QuestTrackerSpells.lua
    -- (legacy block removed)\r\n

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

  local function FontKeyToLabelLite(key)
    key = tostring(key or "inherit")
    if key == "" or key:lower() == "inherit" then
      return "Inherit"
    end
    local lsmName = key:match("^lsm:(.+)$")
    if lsmName and lsmName ~= "" then
      return "LSM: " .. lsmName
    end
    return key
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

      local qc = (type(rule.color) == "table") and rule.color or nil
      panels.quest._questColor = qc
      panels.quest._questColorName = ColorToNameLite(qc)
      if UDDM_SetText and panels.quest._questColorDrop and ColorLabel then
        local name = ColorToNameLite(qc)
        if name == "Custom" then name = ColorLabel("Custom") end
        UDDM_SetText(panels.quest._questColorDrop, ColorLabel(name == "Custom" and "Custom" or name))
      end

      if panels.quest._fontDrop then
        local key = tostring(rule.font or "inherit")
        if key == "" then key = "inherit" end
        panels.quest._fontKey = key
        if UDDM_SetText then UDDM_SetText(panels.quest._fontDrop, FontKeyToLabelLite(key)) end
      end
      if panels.quest._sizeBox and panels.quest._sizeBox.SetText then
        local sz = tonumber(rule.size) or 0
        if sz < 0 then sz = 0 end
        panels.quest._sizeBox:SetText(tostring(sz))
      end

      do
        local op, lvl = GetPlayerLevelGateFromRule(rule)
        panels.quest._playerLevelOp = op
        if UDDM_SetText and panels.quest._qLevelOpDrop then UDDM_SetText(panels.quest._qLevelOpDrop, op or "Off") end
        if panels.quest._qLevelBox then panels.quest._qLevelBox:SetText(tostring(lvl or 0)) end
      end
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
        local cid, creq
        if type(ns) == "table" and type(ns.GetItemCurrencyGate) == "function" then
          cid, creq = ns.GetItemCurrencyGate(rule.item)
        else
          if type(rule.item.currencyID) == "table" then
            cid = tonumber(rule.item.currencyID[1])
            creq = tonumber(rule.item.currencyID[2]) or tonumber(rule.item.currencyRequired)
          else
            cid = tonumber(rule.item.currencyID)
            creq = tonumber(rule.item.currencyRequired)
          end
        end
        cid = tonumber(cid) or 0
        panels.items._itemCurrencyIDBox:SetText((cid > 0) and tostring(cid) or "")
      end
      if panels.items._itemCurrencyReqBox and type(rule.item) == "table" then
        local cid, creq
        if type(ns) == "table" and type(ns.GetItemCurrencyGate) == "function" then
          cid, creq = ns.GetItemCurrencyGate(rule.item)
        else
          if type(rule.item.currencyID) == "table" then
            cid = tonumber(rule.item.currencyID[1])
            creq = tonumber(rule.item.currencyID[2]) or tonumber(rule.item.currencyRequired)
          else
            cid = tonumber(rule.item.currencyID)
            creq = tonumber(rule.item.currencyRequired)
          end
        end
        creq = tonumber(creq) or 0
        panels.items._itemCurrencyReqBox:SetText((creq > 0) and tostring(creq) or "")
      end

      if panels.items._itemShowBelowBox and type(rule.item) == "table" then
        local sb = tonumber(rule.item.showWhenBelow) or 0
        panels.items._itemShowBelowBox:SetText((sb > 0) and tostring(sb) or "")
      end

      do
        local enabled, maxQty = false, 0
        if type(rule.item) == "table" and type(rule.item.buy) == "table" then
          enabled = (rule.item.buy.enabled == true)
          maxQty = tonumber(rule.item.buy.max) or 0
        end
        if panels.items._buyEnabled then panels.items._buyEnabled:SetChecked(enabled and true or false) end
        if panels.items._buyMaxBox and panels.items._buyMaxBox.SetText then
          panels.items._buyMaxBox:SetText((maxQty and maxQty > 0) and tostring(maxQty) or "0")
        end
      end

      local frameID = tostring(rule.frameID or "list1")
      panels.items._targetFrameID = frameID
      if UDDM_SetText and panels.items._itemsFrameDrop then UDDM_SetText(panels.items._itemsFrameDrop, GetFrameDisplayNameByID(frameID)) end

      panels.items._faction = (rule.faction == "Alliance" or rule.faction == "Horde") and rule.faction or nil
      if UDDM_SetText and panels.items._itemsFactionDrop then
        UDDM_SetText(panels.items._itemsFactionDrop, panels.items._faction and tostring(panels.items._faction) or "Both (Off)")
      end

      panels.items._color = (type(rule.color) == "table") and rule.color or nil
      if UDDM_SetText and panels.items._itemsColorDrop then
        UDDM_SetText(panels.items._itemsColorDrop, ColorToNameLite(rule.color))
      end

      if panels.items._fontDrop then
        local key = tostring(rule.font or "inherit")
        if key == "" then key = "inherit" end
        panels.items._fontKey = key
        if UDDM_SetText then UDDM_SetText(panels.items._fontDrop, FontKeyToLabelLite(key)) end
      end
      if panels.items._sizeBox and panels.items._sizeBox.SetText then
        local sz = tonumber(rule.size) or 0
        if sz < 0 then sz = 0 end
        panels.items._sizeBox:SetText(tostring(sz))
      end

      if panels.items._restedOnly then panels.items._restedOnly:SetChecked(rule.restedOnly and true or false) end
      if panels.items._locBox then panels.items._locBox:SetText(tostring(rule.locationID or "0")) end
      if panels.items._hideAcquired and type(rule.item) == "table" then
        local hide = false
        if type(ns) == "table" and type(ns.GetItemRequiredGate) == "function" then
          local _, h = ns.GetItemRequiredGate(rule.item)
          hide = (h == true)
        elseif type(rule.item.required) == "table" then
          hide = (rule.item.required[2] == true)
        else
          hide = (rule.item.hideWhenAcquired == true)
        end
        panels.items._hideAcquired:SetChecked(hide and true or false)
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

      do
        local op, lvl = GetPlayerLevelGateFromRule(rule)
        panels.items._playerLevelOp = op
        if UDDM_SetText and panels.items._itemsLevelOpDrop then UDDM_SetText(panels.items._itemsLevelOpDrop, op or "Off") end
        if panels.items._itemsLevelBox then
          panels.items._itemsLevelBox:SetText((lvl and lvl > 0) and tostring(lvl) or "")
        end
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

      panels.spells._color = (type(rule.color) == "table") and rule.color or nil
      if UDDM_SetText and panels.spells._spellsColorDrop then
        UDDM_SetText(panels.spells._spellsColorDrop, ColorToNameLite(rule.color))
      end

      if panels.spells._fontDrop then
        local key = tostring(rule.font or "inherit")
        if key == "" then key = "inherit" end
        panels.spells._fontKey = key
        if UDDM_SetText then UDDM_SetText(panels.spells._fontDrop, FontKeyToLabelLite(key)) end
      end
      if panels.spells._sizeBox and panels.spells._sizeBox.SetText then
        local sz = tonumber(rule.size) or 0
        if sz < 0 then sz = 0 end
        panels.spells._sizeBox:SetText(tostring(sz))
      end

      do
        local op, lvl = GetPlayerLevelGateFromRule(rule)
        panels.spells._playerLevelOp = op
        if UDDM_SetText and panels.spells._spellsLevelOpDrop then UDDM_SetText(panels.spells._spellsLevelOpDrop, op or "Off") end
        if panels.spells._spellsLevelBox then panels.spells._spellsLevelBox:SetText(tostring(lvl or 0)) end
      end

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

    panels.text._color = (type(rule.color) == "table") and rule.color or nil
    if UDDM_SetText and panels.text._textColorDrop then
      UDDM_SetText(panels.text._textColorDrop, ColorToNameLite(rule.color))
    end

    if panels.text._fontDrop then
      local key = tostring(rule.font or "inherit")
      if key == "" then key = "inherit" end
      panels.text._fontKey = key
      if UDDM_SetText then UDDM_SetText(panels.text._fontDrop, FontKeyToLabelLite(key)) end
    end
    if panels.text._sizeBox and panels.text._sizeBox.SetText then
      local sz = tonumber(rule.size) or 0
      if sz < 0 then sz = 0 end
      panels.text._sizeBox:SetText(tostring(sz))
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

    do
      local op, lvl = GetPlayerLevelGateFromRule(rule)
      panels.text._playerLevelOp = op
      if UDDM_SetText and panels.text._textLevelOpDrop then UDDM_SetText(panels.text._textLevelOpDrop, op or "Off") end
      if panels.text._textLevelBox then panels.text._textLevelBox:SetText(tostring(lvl or 0)) end
    end
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

      local qc2 = (type(rule.color) == "table") and rule.color or nil
      panels.quest._questColor = qc2
      panels.quest._questColorName = ColorToNameLite(qc2)
      if UDDM_SetText and panels.quest._questColorDrop and ColorLabel then
        local name = ColorToNameLite(qc2)
        if name == "Custom" then name = ColorLabel("Custom") end
        UDDM_SetText(panels.quest._questColorDrop, ColorLabel(name == "Custom" and "Custom" or name))
      end

      if panels.quest._fontDrop then
        local key2 = tostring(rule.font or "inherit")
        if key2 == "" then key2 = "inherit" end
        panels.quest._fontKey = key2
        if UDDM_SetText then UDDM_SetText(panels.quest._fontDrop, FontKeyToLabelLite(key2)) end
      end
      if panels.quest._sizeBox and panels.quest._sizeBox.SetText then
        local sz2 = tonumber(rule.size) or 0
        if sz2 < 0 then sz2 = 0 end
        panels.quest._sizeBox:SetText(tostring(sz2))
      end

      do
        local op, lvl = GetPlayerLevelGateFromRule(rule)
        panels.quest._playerLevelOp = op
        if UDDM_SetText and panels.quest._qLevelOpDrop then UDDM_SetText(panels.quest._qLevelOpDrop, op or "Off") end
        if panels.quest._qLevelBox then panels.quest._qLevelBox:SetText(tostring(lvl or 0)) end
      end
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
        local cid, creq
        if type(ns) == "table" and type(ns.GetItemCurrencyGate) == "function" then
          cid, creq = ns.GetItemCurrencyGate(rule.item)
        else
          if type(rule.item.currencyID) == "table" then
            cid = tonumber(rule.item.currencyID[1])
            creq = tonumber(rule.item.currencyID[2]) or tonumber(rule.item.currencyRequired)
          else
            cid = tonumber(rule.item.currencyID)
            creq = tonumber(rule.item.currencyRequired)
          end
        end
        cid = tonumber(cid) or 0
        panels.items._itemCurrencyIDBox:SetText((cid > 0) and tostring(cid) or "")
      end
      if panels.items._itemCurrencyReqBox and type(rule.item) == "table" then
        local cid, creq
        if type(ns) == "table" and type(ns.GetItemCurrencyGate) == "function" then
          cid, creq = ns.GetItemCurrencyGate(rule.item)
        else
          if type(rule.item.currencyID) == "table" then
            cid = tonumber(rule.item.currencyID[1])
            creq = tonumber(rule.item.currencyID[2]) or tonumber(rule.item.currencyRequired)
          else
            cid = tonumber(rule.item.currencyID)
            creq = tonumber(rule.item.currencyRequired)
          end
        end
        creq = tonumber(creq) or 0
        panels.items._itemCurrencyReqBox:SetText((creq > 0) and tostring(creq) or "")
      end

      if panels.items._itemShowBelowBox and type(rule.item) == "table" then
        local sb = tonumber(rule.item.showWhenBelow) or 0
        panels.items._itemShowBelowBox:SetText((sb > 0) and tostring(sb) or "")
      end

      do
        local enabled, maxQty = false, 0
        if type(rule.item) == "table" and type(rule.item.buy) == "table" then
          enabled = (rule.item.buy.enabled == true)
          maxQty = tonumber(rule.item.buy.max) or 0
        end
        if panels.items._buyEnabled then panels.items._buyEnabled:SetChecked(enabled and true or false) end
        if panels.items._buyMaxBox and panels.items._buyMaxBox.SetText then
          panels.items._buyMaxBox:SetText((maxQty and maxQty > 0) and tostring(maxQty) or "0")
        end
      end

      local frameID = tostring(rule.frameID or "list1")
      panels.items._targetFrameID = frameID
      if UDDM_SetText and panels.items._itemsFrameDrop then UDDM_SetText(panels.items._itemsFrameDrop, GetFrameDisplayNameByID(frameID)) end

      panels.items._faction = (rule.faction == "Alliance" or rule.faction == "Horde") and rule.faction or nil
      if UDDM_SetText and panels.items._itemsFactionDrop then
        UDDM_SetText(panels.items._itemsFactionDrop, panels.items._faction and tostring(panels.items._faction) or "Both (Off)")
      end

      panels.items._color = (type(rule.color) == "table") and rule.color or nil
      if UDDM_SetText and panels.items._itemsColorDrop then
        UDDM_SetText(panels.items._itemsColorDrop, ColorToNameLite(rule.color))
      end

      if panels.items._fontDrop then
        local key2 = tostring(rule.font or "inherit")
        if key2 == "" then key2 = "inherit" end
        panels.items._fontKey = key2
        if UDDM_SetText then UDDM_SetText(panels.items._fontDrop, FontKeyToLabelLite(key2)) end
      end
      if panels.items._sizeBox and panels.items._sizeBox.SetText then
        local sz2 = tonumber(rule.size) or 0
        if sz2 < 0 then sz2 = 0 end
        panels.items._sizeBox:SetText(tostring(sz2))
      end

      if panels.items._restedOnly then panels.items._restedOnly:SetChecked(rule.restedOnly and true or false) end
      if panels.items._locBox then panels.items._locBox:SetText(tostring(rule.locationID or "0")) end
      if panels.items._hideAcquired and type(rule.item) == "table" then
        local hide2 = false
        if type(ns) == "table" and type(ns.GetItemRequiredGate) == "function" then
          local _, h2 = ns.GetItemRequiredGate(rule.item)
          hide2 = (h2 == true)
        elseif type(rule.item.required) == "table" then
          hide2 = (rule.item.required[2] == true)
        else
          hide2 = (rule.item.hideWhenAcquired == true)
        end
        panels.items._hideAcquired:SetChecked(hide2 and true or false)
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

      do
        local op, lvl = GetPlayerLevelGateFromRule(rule)
        panels.items._playerLevelOp = op
        if UDDM_SetText and panels.items._itemsLevelOpDrop then UDDM_SetText(panels.items._itemsLevelOpDrop, op or "Off") end
        if panels.items._itemsLevelBox then
          panels.items._itemsLevelBox:SetText((lvl and lvl > 0) and tostring(lvl) or "")
        end
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

      panels.spells._color = (type(rule.color) == "table") and rule.color or nil
      if UDDM_SetText and panels.spells._spellsColorDrop then
        UDDM_SetText(panels.spells._spellsColorDrop, ColorToNameLite(rule.color))
      end

      if panels.spells._fontDrop then
        local key2 = tostring(rule.font or "inherit")
        if key2 == "" then key2 = "inherit" end
        panels.spells._fontKey = key2
        if UDDM_SetText then UDDM_SetText(panels.spells._fontDrop, FontKeyToLabelLite(key2)) end
      end
      if panels.spells._sizeBox and panels.spells._sizeBox.SetText then
        local sz2 = tonumber(rule.size) or 0
        if sz2 < 0 then sz2 = 0 end
        panels.spells._sizeBox:SetText(tostring(sz2))
      end

      do
        local op, lvl = GetPlayerLevelGateFromRule(rule)
        panels.spells._playerLevelOp = op
        if UDDM_SetText and panels.spells._spellsLevelOpDrop then UDDM_SetText(panels.spells._spellsLevelOpDrop, op or "Off") end
        if panels.spells._spellsLevelBox then panels.spells._spellsLevelBox:SetText(tostring(lvl or 0)) end
      end

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

    panels.text._color = (type(rule.color) == "table") and rule.color or nil
    if UDDM_SetText and panels.text._textColorDrop then
      UDDM_SetText(panels.text._textColorDrop, ColorToNameLite(rule.color))
    end

    if panels.text._fontDrop then
      local key2 = tostring(rule.font or "inherit")
      if key2 == "" then key2 = "inherit" end
      panels.text._fontKey = key2
      if UDDM_SetText then UDDM_SetText(panels.text._fontDrop, FontKeyToLabelLite(key2)) end
    end
    if panels.text._sizeBox and panels.text._sizeBox.SetText then
      local sz2 = tonumber(rule.size) or 0
      if sz2 < 0 then sz2 = 0 end
      panels.text._sizeBox:SetText(tostring(sz2))
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

    do
      local op, lvl = GetPlayerLevelGateFromRule(rule)
      panels.text._playerLevelOp = op
      if UDDM_SetText and panels.text._textLevelOpDrop then UDDM_SetText(panels.text._textLevelOpDrop, op or "Off") end
      if panels.text._textLevelBox then panels.text._textLevelBox:SetText(tostring(lvl or 0)) end
    end
  end

  ns.OpenDefaultRuleInTab = OpenDefaultRuleInTab

  -- RULES tab (Rules module)
  local useRulesModule = type(ns) == "table" and type(ns.FQTOptionsPanels) == "table" and type(ns.FQTOptionsPanels.BuildRules) == "function"
  if useRulesModule then
    ns.FQTOptionsPanels.BuildRules(GetOptionsCtx())
  else
    -- Legacy Rules tab UI moved to fr0z3nUI_QuestTrackerRules.lua
    -- (legacy block removed)\r\n
  end

  -- FRAMES tab (Frames module)
  local useFramesModule = type(ns) == "table" and type(ns.FQTOptionsPanels) == "table" and type(ns.FQTOptionsPanels.BuildFrames) == "function"
  if useFramesModule then
    ns.FQTOptionsPanels.BuildFrames(GetOptionsCtx())
  else
    -- Legacy Frames tab UI moved to fr0z3nUI_QuestTrackerFrames.lua
    -- (legacy block removed)\r\n
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
        local op, lvl = GetPlayerLevelGateFromRule(rr)
        if op and lvl then
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
  reloadBtn:SetSize(90, 22)
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
