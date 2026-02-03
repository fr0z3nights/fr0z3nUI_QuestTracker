local addonName, ns = ...

ns.FQTOptionsPanels = ns.FQTOptionsPanels or {}

function ns.FQTOptionsPanels.BuildFrames(ctx)
  if type(ctx) ~= "table" then return end

  local optionsFrame = ctx.optionsFrame
  local panels = ctx.panels
  if not (optionsFrame and panels and panels.frames) then return end

  local Print = ctx.Print or function(...) end
  local CreateFrame = ctx.CreateFrame or CreateFrame

  local GetUISetting = ctx.GetUISetting
  local SetUISetting = ctx.SetUISetting

  local GetEffectiveFrames = ctx.GetEffectiveFrames
  local GetCustomFrames = ctx.GetCustomFrames
  local GetFrameDisplayNameByID = ctx.GetFrameDisplayNameByID

  local CreateAllFrames = ctx.CreateAllFrames
  local RefreshAll = ctx.RefreshAll

  local RefreshRulesList = ctx.RefreshRulesList

  local DestroyFrameByID = ctx.DestroyFrameByID
  local ShallowCopyTable = ctx.ShallowCopyTable
  local UpdateReverseOrderVisibility = ctx.UpdateReverseOrderVisibility

  local UseModernMenuDropDown = ctx.UseModernMenuDropDown

  local UDDM_SetWidth = ctx.UDDM_SetWidth
  local UDDM_SetText = ctx.UDDM_SetText
  local UDDM_Initialize = ctx.UDDM_Initialize
  local UDDM_CreateInfo = ctx.UDDM_CreateInfo
  local UDDM_AddButton = ctx.UDDM_AddButton

  local SetCheckButtonLabel = ctx.SetCheckButtonLabel

  local UDDM_Enable = _G and rawget(_G, "UIDropDownMenu_EnableDropDown")
  local UDDM_Disable = _G and rawget(_G, "UIDropDownMenu_DisableDropDown")

  local function SafeCall(fn, ...)
    if type(fn) == "function" then
      return fn(...)
    end
  end

  local function SafeFrames()
    return (type(GetEffectiveFrames) == "function" and GetEffectiveFrames()) or {}
  end

  local function SafeCustomFrames()
    return (type(GetCustomFrames) == "function" and GetCustomFrames()) or {}
  end

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

  local function StripEditBox(box)
    if not box then return end

    for _, k in ipairs({ "Left", "Middle", "Right", "LeftDisabled", "MiddleDisabled", "RightDisabled" }) do
      local r = rawget(box, k)
      if r and r.Hide then r:Hide() end
    end

    local regions = { box:GetRegions() }
    for i = 1, #regions do
      local r = regions[i]
      if r and r.GetObjectType and r:GetObjectType() == "Texture" then
        if r.Hide then r:Hide() end
      end
    end
  end

  local function StripDropDown(dropdown)
    if not dropdown then return end
    for _, k in ipairs({ "Left", "Middle", "Right" }) do
      local r = rawget(dropdown, k)
      if r and r.Hide then r:Hide() end
    end

    local regions = { dropdown:GetRegions() }
    for i = 1, #regions do
      local r = regions[i]
      if r and r.GetObjectType and r:GetObjectType() == "Texture" then
        if r.Hide then r:Hide() end
      end
    end
  end

  local function AddDropDownOverlayLabel(dropdown, text)
    if not (dropdown and dropdown.CreateFontString) then return nil end
    if dropdown._overlayLabel then return dropdown._overlayLabel end
    local fs = dropdown:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    fs:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 22, -2)
    fs:SetJustifyH("LEFT")
    fs:SetText(tostring(text or ""))
    dropdown._overlayLabel = fs
    return fs
  end

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

  local function NextFrameID(prefix)
    local used = {}
    for _, def in ipairs(SafeFrames()) do
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
  addBarBtn:SetPoint("TOPRIGHT", -306, -40)
  addBarBtn:SetText("Add Bar")

  local addListBtn = CreateFrame("Button", nil, panels.frames, "UIPanelButtonTemplate")
  addListBtn:SetSize(90, 22)
  addListBtn:SetPoint("TOPRIGHT", -208, -40)
  addListBtn:SetText("Add List")

  local deleteBtn = CreateFrame("Button", nil, panels.frames, "UIPanelButtonTemplate")
  deleteBtn:SetSize(90, 22)
  deleteBtn:SetPoint("TOPRIGHT", -12, -40)
  deleteBtn:SetText("Delete")

  local clearBtn = CreateFrame("Button", nil, panels.frames, "UIPanelButtonTemplate")
  clearBtn:SetSize(90, 22)
  clearBtn:SetPoint("RIGHT", deleteBtn, "LEFT", -6, 0)
  clearBtn:SetText("Clear")

  deleteBtn:SetScript("OnEnter", function(self)
    if not GameTooltip then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Delete selected")
    GameTooltip:AddLine("Hold SHIFT and click to delete the selected Bar/List.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  deleteBtn:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

  clearBtn:SetScript("OnEnter", function(self)
    if not GameTooltip then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Clear selected")
    GameTooltip:AddLine("Hold SHIFT and click to unassign all custom rules from the selected frame.", 1, 1, 1, true)
    GameTooltip:AddLine("This does not delete rules.", 0.85, 0.85, 0.85, true)
    GameTooltip:Show()
  end)
  clearBtn:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

  optionsFrame._addBarBtn = addBarBtn
  optionsFrame._addListBtn = addListBtn
  optionsFrame._deleteFrameBtn = deleteBtn
  optionsFrame._clearFrameRulesBtn = clearBtn

  local reorderBtn = CreateFrame("Button", nil, panels.frames, "UIPanelButtonTemplate")
  reorderBtn:SetSize(90, 22)
  -- Place above the global Reload UI button area.
  reorderBtn:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOMRIGHT", -12, 40)
  reorderBtn:SetText("ReOrder")
  optionsFrame._reorderBtn = reorderBtn

  local clearEventBtn = CreateFrame("Button", nil, panels.frames, "UIPanelButtonTemplate")
  clearEventBtn:SetSize(90, 22)
  clearEventBtn:SetPoint("BOTTOMRIGHT", reorderBtn, "TOPRIGHT", 0, 6)
  clearEventBtn:SetText("Clear Event")
  optionsFrame._clearEventBtn = clearEventBtn

  local resetFrameBtn = CreateFrame("Button", nil, panels.frames, "UIPanelButtonTemplate")
  resetFrameBtn:SetSize(90, 22)
  resetFrameBtn:SetPoint("RIGHT", reorderBtn, "LEFT", -6, 0)
  resetFrameBtn:SetText("Reset Frame")
  resetFrameBtn:Hide()
  optionsFrame._resetFrameBtn = resetFrameBtn

  resetFrameBtn:SetScript("OnEnter", function(self)
    if not GameTooltip then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Reset Frame")
    GameTooltip:AddLine("Resets this frame's position and Scale back to defaults.", 1, 1, 1, true)
    GameTooltip:AddLine("Does not delete the frame.", 0.85, 0.85, 0.85, true)
    GameTooltip:Show()
  end)
  resetFrameBtn:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

  clearEventBtn:SetScript("OnEnter", function(self)
    if not GameTooltip then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Clear Event")
    GameTooltip:AddLine("Clears remembered calendar event state (bonus events etc).", 1, 1, 1, true)
    GameTooltip:AddLine("Use if an event is incorrectly shown as active.", 0.85, 0.85, 0.85, true)
    GameTooltip:AddLine("Reloads the UI after clearing.", 0.85, 0.85, 0.85, true)
    GameTooltip:Show()
  end)
  clearEventBtn:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

  clearEventBtn:SetScript("OnClick", function()
    if type(ns) == "table" and type(ns.ClearRememberedEventState) == "function" then
      ns.ClearRememberedEventState()
      SafeCall(RefreshAll)
      SafeCall(RefreshRulesList)
      Print("Cleared remembered event state. Reloading UI...")
      local r = _G and _G["ReloadUI"]
      if r then r() end
    else
      Print("Clear Event unavailable (core not loaded).")
    end
  end)

  local RefreshFramesList

  addBarBtn:SetScript("OnClick", function()
    local frames = SafeCustomFrames()
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
    SafeCall(CreateAllFrames)
    SafeCall(RefreshAll)
    if RefreshFramesList then RefreshFramesList() end
    Print("Added frame " .. id)
  end)

  addListBtn:SetScript("OnClick", function()
    local frames = SafeCustomFrames()
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
    SafeCall(CreateAllFrames)
    SafeCall(RefreshAll)
    if RefreshFramesList then RefreshFramesList() end
    Print("Added frame " .. id)
  end)

  local function DeleteSelectedFrame()
    if not (IsShiftKeyDown and IsShiftKeyDown()) then
      Print("Hold SHIFT and click Delete.")
      return
    end
    local id = tostring(optionsFrame._selectedFrameID or "")
    if id == "" then
      Print("No frame selected.")
      return
    end

    local frames = SafeCustomFrames()
    for i = #frames, 1, -1 do
      if tostring(frames[i] and frames[i].id or "") == id then
        table.remove(frames, i)
      end
    end
    if type(DestroyFrameByID) == "function" then
      DestroyFrameByID(id)
    end
    optionsFrame._selectedFrameID = nil
    SafeCall(CreateAllFrames)
    SafeCall(RefreshAll)
    if RefreshFramesList then RefreshFramesList() end
    Print("Removed frame " .. id .. ".")
  end

  deleteBtn:SetScript("OnClick", function()
    DeleteSelectedFrame()
  end)

  local function ClearSelectedFrameRules()
    if not (IsShiftKeyDown and IsShiftKeyDown()) then
      Print("Hold SHIFT and click Clear.")
      return
    end
    local id = tostring(optionsFrame._selectedFrameID or "")
    if id == "" then
      Print("No frame selected.")
      return
    end

    local cleared = 0

    -- Clear default rules via defaultRuleEdits (so changes persist).
    do
      local RuleKey = ctx.RuleKey or (ns and ns.RuleKey)
      local DeepCopyValue = ctx.DeepCopyValue or (ns and ns.DeepCopyValue)
      local GetDefaultRuleEdits = ctx.GetDefaultRuleEdits or (ns and ns.GetDefaultRuleEdits)
      local edits = (type(GetDefaultRuleEdits) == "function") and GetDefaultRuleEdits() or nil
      local baseRules = (ns and ns.rules) or nil
      if type(edits) == "table" and type(baseRules) == "table" and type(RuleKey) == "function" and type(DeepCopyValue) == "function" then
        for _, base in ipairs(baseRules) do
          local key = RuleKey(base)
          if key then
            local cur = edits[key] or base
            local shouldClear = false

            if type(cur.targets) == "table" then
              for _, v in ipairs(cur.targets) do
                if tostring(v or "") == id then
                  shouldClear = true
                  break
                end
              end
            end
            if not shouldClear and tostring(cur.frameID or "") == id then
              shouldClear = true
            end

            if shouldClear then
              local copy = DeepCopyValue(cur)
              if type(copy.targets) == "table" then
                for i = #copy.targets, 1, -1 do
                  if tostring(copy.targets[i] or "") == id then
                    table.remove(copy.targets, i)
                  end
                end
                if #copy.targets == 0 then copy.targets = nil end
              end
              if tostring(copy.frameID or "") == id then
                copy.frameID = nil
              end
              edits[key] = copy
              cleared = cleared + 1
            end
          end
        end
      end
    end

    -- Clear custom rules (account-wide) by unassigning them from this frame.
    do
      local GetCustomRules = ctx.GetCustomRules or (ns and ns.GetCustomRules)
      local UnassignRuleFromFrame = ctx.UnassignRuleFromFrame or (ns and ns.UnassignRuleFromFrame)
      local rules = (type(GetCustomRules) == "function") and GetCustomRules() or nil
      if type(rules) == "table" and type(UnassignRuleFromFrame) == "function" then
        for _, rule in ipairs(rules) do
          if UnassignRuleFromFrame(rule, id) then
            cleared = cleared + 1
          end
        end
      end
    end

    SafeCall(RefreshAll)
    if RefreshRulesList then RefreshRulesList() end
    Print(string.format("Cleared %d rule(s) from %s.", cleared, id))
  end

  clearBtn:SetScript("OnClick", function()
    ClearSelectedFrameRules()
  end)

  local framesTitle = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  framesTitle:SetPoint("TOPLEFT", 12, -40)
  framesTitle:SetText("")
  framesTitle:Hide()

  local framesScroll = CreateFrame("ScrollFrame", nil, panels.frames, "UIPanelScrollFrameTemplate")
  framesScroll:SetPoint("TOPLEFT", 12, -182)
  framesScroll:SetPoint("BOTTOMLEFT", 12, 44)
  framesScroll:SetWidth(530)
  -- Legacy always-on list hidden (replaced by ReOrder popout).
  framesScroll:Hide()

  local framesContent = CreateFrame("Frame", nil, framesScroll)
  framesContent:SetSize(1, 1)
  framesScroll:SetScrollChild(framesContent)
  framesScroll:SetScript("OnSizeChanged", function(self)
    if not optionsFrame._framesContent then return end
    local w = tonumber(self:GetWidth() or 0) or 0
    optionsFrame._framesContent:SetWidth(math.max(1, w - 28))
  end)

  optionsFrame._framesContent = framesContent
  optionsFrame._frameRows = optionsFrame._frameRows or {}
  optionsFrame._framesScroll = framesScroll
  optionsFrame._framesTitle = framesTitle

  -- ReOrder popout
  local function ToggleReorderPopup(show)
    local pop = optionsFrame._reorderPopup
    if not pop then
      pop = CreateFrame("Frame", nil, optionsFrame, "BasicFrameTemplateWithInset")
      pop:SetSize(320, 320)
      pop:SetPoint("TOPLEFT", optionsFrame, "TOPRIGHT", 10, -40)
      if pop.SetFrameStrata then pop:SetFrameStrata("DIALOG") end
      if pop.SetClampedToScreen then pop:SetClampedToScreen(true) end
      pop:Hide()

      if pop.TitleText and pop.TitleText.SetText then
        pop.TitleText:SetText("ReOrder")
      else
        local t = pop:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        t:SetPoint("TOPLEFT", 12, -6)
        t:SetText("ReOrder")
        pop._title = t
      end

      do
        local line = pop:CreateTexture(nil, "ARTWORK")
        if line and line.SetColorTexture then
          line:SetColorTexture(1, 1, 1, 0.08)
        else
          line:SetTexture("Interface\\Buttons\\WHITE8X8")
          if line and line.SetVertexColor then line:SetVertexColor(1, 1, 1, 0.08) end
        end
        line:SetPoint("TOPLEFT", 10, -24)
        line:SetPoint("TOPRIGHT", -10, -24)
        line:SetHeight(1)
        pop._headerLine = line
      end

      local zebraFrames = CreateFrame("Slider", nil, pop, "UISliderTemplate")
      zebraFrames:ClearAllPoints()
      zebraFrames:SetPoint("BOTTOM", pop, "BOTTOM", 0, 14)
      zebraFrames:SetWidth(180)
      zebraFrames:SetHeight(12)
      if zebraFrames.Low and zebraFrames.Low.Hide then zebraFrames.Low:Hide() end
      if zebraFrames.High and zebraFrames.High.Hide then zebraFrames.High:Hide() end
      if zebraFrames.Text and zebraFrames.Text.Hide then zebraFrames.Text:Hide() end
      zebraFrames:SetMinMaxValues(0, 0.20)
      zebraFrames:SetValueStep(0.01)
      zebraFrames:SetObeyStepOnDrag(true)
      zebraFrames:SetScript("OnShow", function(self)
        if optionsFrame._zebraUpdating then return end
        optionsFrame._zebraUpdating = true
        local v = (type(GetUISetting) == "function") and (tonumber(GetUISetting("zebraAlpha", 0.05) or 0.05) or 0.05) or 0.05
        if v < 0 then v = 0 elseif v > 0.20 then v = 0.20 end
        self:SetValue(v)
        optionsFrame._zebraUpdating = false
      end)
      zebraFrames:SetScript("OnValueChanged", function(self, value)
        if optionsFrame._zebraUpdating then return end
        optionsFrame._zebraUpdating = true
        local v = tonumber(value) or 0
        if v < 0 then v = 0 elseif v > 0.20 then v = 0.20 end
        if type(SetUISetting) == "function" then
          SetUISetting("zebraAlpha", v)
        end
        if optionsFrame._zebraSliderRules and optionsFrame._zebraSliderRules.SetValue then
          optionsFrame._zebraSliderRules:SetValue(v)
        end
        if RefreshFramesList then RefreshFramesList() end
        SafeCall(RefreshRulesList)
        optionsFrame._zebraUpdating = false
      end)
      optionsFrame._zebraSliderFrames = zebraFrames

      local scroll = CreateFrame("ScrollFrame", nil, pop, "UIPanelScrollFrameTemplate")
      scroll:SetPoint("TOPLEFT", 10, -28)
      scroll:SetPoint("BOTTOMRIGHT", -28, 34)

      local content = CreateFrame("Frame", nil, scroll)
      content:SetSize(1, 1)
      scroll:SetScrollChild(content)
      scroll:SetScript("OnSizeChanged", function(self)
        if not optionsFrame._framesContent then return end
        local w = tonumber(self:GetWidth() or 0) or 0
        optionsFrame._framesContent:SetWidth(math.max(1, w - 28))
      end)

      -- Route the existing list builder into this popout.
      optionsFrame._framesScroll = scroll
      optionsFrame._framesContent = content
      optionsFrame._frameRows = optionsFrame._frameRows or {}

      pop._scroll = scroll
      pop._content = content
      optionsFrame._reorderPopup = pop
    end

    if show == nil then
      show = not (pop.IsShown and pop:IsShown())
    end
    if show then
      pop:Show()
      if RefreshFramesList then RefreshFramesList() end
    else
      pop:Hide()
    end
  end

  if reorderBtn then
    reorderBtn:SetScript("OnClick", function()
      ToggleReorderPopup()
    end)
  end

  -- Frame editor (shown only when Show frame list is enabled)
  local frameEditTitle = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frameEditTitle:SetPoint("TOPLEFT", 12, -40)
  frameEditTitle:SetText("Settings")
  optionsFrame._frameEditTitle = frameEditTitle

  local frameEditLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  frameEditLabel:SetPoint("TOPLEFT", 12, -58)
  frameEditLabel:SetText("Select:")
  frameEditLabel:Hide()
  optionsFrame._frameEditLabel = frameEditLabel

  local frameDrop = CreateFrame("Frame", nil, panels.frames, "UIDropDownMenuTemplate")
  frameDrop:SetPoint("TOPLEFT", -18, -82)
  if UDDM_SetWidth then UDDM_SetWidth(frameDrop, 120) end
  if UDDM_SetText then UDDM_SetText(frameDrop, "(pick)") end
  StripDropDown(frameDrop)
  AddDropDownOverlayLabel(frameDrop, "Select")
  optionsFrame._frameDrop = frameDrop
  optionsFrame._selectedFrameID = nil

  -- Auto sizing toggle removed.
  optionsFrame._frameAuto = nil

  local nameLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  nameLabel:SetPoint("TOPLEFT", 12, -82)
  nameLabel:SetText("Name")
  nameLabel:Hide()
  optionsFrame._frameNameLabel = nameLabel

  local nameBox = CreateFrame("EditBox", nil, panels.frames, "InputBoxTemplate")
  nameBox:SetSize(160, 20)
  nameBox:SetPoint("TOPLEFT", 165, -86)
  nameBox:SetAutoFocus(false)
  nameBox:SetText("")
  StripEditBox(nameBox)
  AddGhostLabel(nameBox, "Name")
  optionsFrame._frameNameBox = nameBox

  local hideAnchor = optionsFrame._resetBtn or panels.frames

  local frameHideCombat = CreateFrame("CheckButton", nil, panels.frames, "UICheckButtonTemplate")
  if hideAnchor == optionsFrame._resetBtn then
    frameHideCombat:SetPoint("BOTTOMLEFT", hideAnchor, "TOPLEFT", 0, 6)
  else
    frameHideCombat:SetPoint("BOTTOMLEFT", panels.frames, "BOTTOMLEFT", 12, 44)
  end
  if SetCheckButtonLabel then SetCheckButtonLabel(frameHideCombat, "Hide in combat") end
  frameHideCombat:Hide()
  optionsFrame._frameHideCombat = frameHideCombat

  local frameHideFrame = CreateFrame("Button", nil, panels.frames, "UIPanelButtonTemplate")
  frameHideFrame:SetSize(110, 18)
  frameHideFrame:SetPoint("BOTTOMLEFT", frameHideCombat, "TOPLEFT", 0, 2)
  frameHideFrame:SetText("Hide Frame")
  frameHideFrame:Hide()
  optionsFrame._frameHideFrame = frameHideFrame

  local function UpdateHideFrameButton(def)
    if not (frameHideFrame and frameHideFrame.GetFontString) then return end
    local hidden = (type(def) == "table" and def.hideFrame == true) and true or false
    if frameHideFrame.SetText then
      frameHideFrame:SetText(hidden and "Show Frame" or "Hide Frame")
    end
    local fs = frameHideFrame:GetFontString()
    if fs and fs.SetTextColor then
      if hidden then
        fs:SetTextColor(1.00, 0.90, 0.20) -- yellow (hidden)
      else
        fs:SetTextColor(0.75, 0.75, 0.75) -- gray (showing)
      end
    end
  end

  -- Per-frame scale (bars/lists)
  local scaleSlider = CreateFrame("Slider", "FR0Z3NUIFQT_FrameScaleSlider", panels.frames, "OptionsSliderTemplate")
  scaleSlider:SetPoint("BOTTOM", panels.frames, "BOTTOM", 0, 18)
  scaleSlider:SetWidth(240)
  scaleSlider:SetHeight(16)
  scaleSlider:SetMinMaxValues(0.50, 2.00)
  scaleSlider:SetValueStep(0.05)
  scaleSlider:SetObeyStepOnDrag(true)
  scaleSlider:SetValue(1)
  if _G["FR0Z3NUIFQT_FrameScaleSliderText"] then
    _G["FR0Z3NUIFQT_FrameScaleSliderText"]:SetText("Scale")
    _G["FR0Z3NUIFQT_FrameScaleSliderText"]:SetFontObject("GameFontDisableSmall")
  end
  if _G["FR0Z3NUIFQT_FrameScaleSliderLow"] then _G["FR0Z3NUIFQT_FrameScaleSliderLow"]:SetText("50%") end
  if _G["FR0Z3NUIFQT_FrameScaleSliderHigh"] then _G["FR0Z3NUIFQT_FrameScaleSliderHigh"]:SetText("200%") end
  scaleSlider:Hide()
  optionsFrame._frameScaleSlider = scaleSlider

  local scaleValue = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  scaleValue:SetPoint("TOP", scaleSlider, "BOTTOM", 0, -2)
  scaleValue:SetJustifyH("CENTER")
  scaleValue:SetText("100%")
  scaleValue:Hide()
  optionsFrame._frameScaleValue = scaleValue

  -- External visibility linking: Off / Hook
  local linkLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  linkLabel:SetPoint("BOTTOMLEFT", frameHideFrame, "TOPLEFT", 4, 10)
  linkLabel:SetText("External Link")
  linkLabel:Hide()
  optionsFrame._frameVisLinkLabel = linkLabel

  local linkModeBtn = CreateFrame("Button", nil, panels.frames, "UIPanelButtonTemplate")
  linkModeBtn:SetSize(86, 18)
  linkModeBtn:SetPoint("LEFT", linkLabel, "RIGHT", 10, -1)
  linkModeBtn:SetText("Off")
  linkModeBtn:Hide()
  optionsFrame._frameVisLinkModeBtn = linkModeBtn

  local linkNameBox = CreateFrame("EditBox", nil, panels.frames, "InputBoxTemplate")
  linkNameBox:SetSize(190, 20)
  linkNameBox:SetPoint("LEFT", linkModeBtn, "RIGHT", 8, 0)
  linkNameBox:SetAutoFocus(false)
  linkNameBox:SetText("")
  StripEditBox(linkNameBox)
  AddGhostLabel(linkNameBox, "Frame name")
  linkNameBox:Hide()
  optionsFrame._frameVisLinkNameBox = linkNameBox

  local linkPickBtn = CreateFrame("Button", nil, panels.frames, "UIPanelButtonTemplate")
  linkPickBtn:SetSize(44, 18)
  linkPickBtn:SetPoint("LEFT", linkNameBox, "RIGHT", 6, 0)
  linkPickBtn:SetText("Pick")
  linkPickBtn:Hide()
  optionsFrame._frameVisLinkPickBtn = linkPickBtn

  local linkStatus = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  linkStatus:SetPoint("TOPLEFT", linkLabel, "BOTTOMLEFT", 0, -2)
  linkStatus:SetText("")
  linkStatus:Hide()
  optionsFrame._frameVisLinkStatus = linkStatus

  local function NormalizeAnchorCornerLocal(v)
    v = tostring(v or ""):lower():gsub("%s+", "")
    if v == "tl" or v == "topleft" then return "tl" end
    if v == "tr" or v == "topright" then return "tr" end
    if v == "bl" or v == "bottomleft" then return "bl" end
    if v == "br" or v == "bottomright" then return "br" end
    return nil
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

  local function DeriveGrowDirFromCorner(corner)
    corner = NormalizeAnchorCornerLocal(corner) or "tl"
    if corner == "tl" then return "down-right" end
    if corner == "tr" then return "down-left" end
    if corner == "bl" then return "up-right" end
    if corner == "br" then return "up-left" end
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
    if corner == "bl" then return "Bottom Left" end
    if corner == "br" then return "Bottom Right" end
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
    local dir = DeriveGrowDirFromCorner(corner)
    return string.format("%s (%s)", AnchorCornerLabel(corner), GrowDirLabel(dir))
  end

  local anchorPosLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  anchorPosLabel:SetPoint("TOPLEFT", 365, -82)
  anchorPosLabel:SetText("Anchor/Grow")
  anchorPosLabel:Hide()
  optionsFrame._frameAnchorPosLabel = anchorPosLabel

  local anchorPosDrop = CreateFrame("Frame", nil, panels.frames, "UIDropDownMenuTemplate")
  anchorPosDrop:SetPoint("TOPLEFT", 330, -82)
  if UDDM_SetWidth then UDDM_SetWidth(anchorPosDrop, 150) end
  if UDDM_SetText then UDDM_SetText(anchorPosDrop, "(auto)") end
  StripDropDown(anchorPosDrop)
  AddDropDownOverlayLabel(anchorPosDrop, "Anchor")
  optionsFrame._frameAnchorPosDrop = anchorPosDrop

  local growDirLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  growDirLabel:SetPoint("TOPLEFT", 365, -112)
  growDirLabel:SetText("Grow")
  optionsFrame._frameGrowDirLabel = growDirLabel

  local growDirDrop = CreateFrame("Frame", nil, panels.frames, "UIDropDownMenuTemplate")
  growDirDrop:SetPoint("TOPLEFT", 340, -98)
  if UDDM_SetWidth then UDDM_SetWidth(growDirDrop, 130) end
  if UDDM_SetText then UDDM_SetText(growDirDrop, "(auto)") end
  optionsFrame._frameGrowDirDrop = growDirDrop

  -- Grow is implied by Anchor/Grow; keep legacy control hidden.
  growDirLabel:Hide()
  growDirDrop:Hide()

  local widthBox = CreateFrame("EditBox", nil, panels.frames, "InputBoxTemplate")
  widthBox:SetSize(60, 20)
  widthBox:SetPoint("TOPLEFT", 12, -128)
  widthBox:SetAutoFocus(false)
  widthBox:SetNumeric(true)
  widthBox:SetText("0")
  if widthBox.SetJustifyH then widthBox:SetJustifyH("RIGHT") end
  optionsFrame._frameWidthBox = widthBox
  StripEditBox(widthBox)
  AddGhostLabel(widthBox, "W")

  -- Re-anchor hide toggles under Width (and keep External Link in the footer).
  if frameHideFrame and frameHideCombat then
    frameHideFrame:ClearAllPoints()
    frameHideFrame:SetPoint("TOPLEFT", widthBox, "BOTTOMLEFT", 0, -8)
    frameHideCombat:ClearAllPoints()
    frameHideCombat:SetPoint("LEFT", frameHideFrame, "RIGHT", 10, 0)
  end

  if linkLabel and hideAnchor then
    linkLabel:ClearAllPoints()
    if hideAnchor == optionsFrame._resetBtn then
      linkLabel:SetPoint("BOTTOMLEFT", hideAnchor, "TOPLEFT", 4, 22)
    else
      linkLabel:SetPoint("BOTTOMLEFT", panels.frames, "BOTTOMLEFT", 16, 72)
    end
  end

  local heightBox = CreateFrame("EditBox", nil, panels.frames, "InputBoxTemplate")
  heightBox:SetSize(60, 20)
  heightBox:SetPoint("TOPLEFT", 82, -128)
  heightBox:SetAutoFocus(false)
  heightBox:SetNumeric(true)
  heightBox:SetText("0")
  if heightBox.SetJustifyH then heightBox:SetJustifyH("RIGHT") end
  optionsFrame._frameHeightBox = heightBox
  StripEditBox(heightBox)
  AddGhostLabel(heightBox, "H")

  local lengthBox = CreateFrame("EditBox", nil, panels.frames, "InputBoxTemplate")
  lengthBox:SetSize(60, 20)
  lengthBox:SetPoint("TOPLEFT", 152, -128)
  lengthBox:SetAutoFocus(false)
  lengthBox:SetNumeric(true)
  lengthBox:SetText("0")
  if lengthBox.SetJustifyH then lengthBox:SetJustifyH("RIGHT") end
  optionsFrame._frameLengthBox = lengthBox
  StripEditBox(lengthBox)
  AddGhostLabel(lengthBox, "Seg")

  optionsFrame._frameMaxHBox = nil

  local padSlider = CreateFrame("Slider", "FR0Z3NUIFQT_PadSlider", panels.frames, "OptionsSliderTemplate")
  padSlider:SetPoint("TOPLEFT", 222, -132)
  padSlider:SetWidth(115)
  padSlider:SetHeight(16)
  padSlider:SetMinMaxValues(-10, 10)
  padSlider:SetValueStep(1)
  padSlider:SetObeyStepOnDrag(true)
  padSlider:SetValue(0)
  if _G["FR0Z3NUIFQT_PadSliderText"] then _G["FR0Z3NUIFQT_PadSliderText"]:SetText("Pad") end
  if _G["FR0Z3NUIFQT_PadSliderLow"] then _G["FR0Z3NUIFQT_PadSliderLow"]:SetText("-10") end
  if _G["FR0Z3NUIFQT_PadSliderHigh"] then _G["FR0Z3NUIFQT_PadSliderHigh"]:SetText("+10") end
  optionsFrame._framePadSlider = padSlider

  local padValue = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  padValue:SetPoint("TOP", padSlider, "BOTTOM", 0, -2)
  padValue:SetJustifyH("CENTER")
  padValue:SetText("0")
  optionsFrame._framePadValue = padValue

  local widthLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  widthLabel:SetPoint("TOPLEFT", 12, -130)
  widthLabel:SetText("Width")
  widthLabel:Hide()
  optionsFrame._frameWidthLabel = widthLabel

  local heightLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  heightLabel:SetPoint("TOPLEFT", 125, -130)
  heightLabel:SetText("Height")
  heightLabel:Hide()
  optionsFrame._frameHeightLabel = heightLabel

  local lengthLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  lengthLabel:SetPoint("TOPLEFT", 245, -130)
  lengthLabel:SetText("Length")
  lengthLabel:Hide()
  optionsFrame._frameLengthLabel = lengthLabel

  local maxHLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  maxHLabel:SetPoint("TOPLEFT", 365, -130)
  maxHLabel:SetText("Max H")
  maxHLabel:Hide()
  optionsFrame._frameMaxHLabel = maxHLabel

  -- Background (per-frame)
  local bgLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  bgLabel:SetPoint("TOPLEFT", anchorPosDrop, "BOTTOMLEFT", 0, -12)
  bgLabel:SetText("Background")
  optionsFrame._frameBgLabel = bgLabel

  local bgAlphaSlider = CreateFrame("Slider", "FR0Z3NUIFQT_BGAlphaSlider", panels.frames, "OptionsSliderTemplate")
  bgAlphaSlider:SetMinMaxValues(0, 1)
  bgAlphaSlider:SetValueStep(0.05)
  bgAlphaSlider:SetObeyStepOnDrag(true)
  bgAlphaSlider:SetValue(0)
  if _G["FR0Z3NUIFQT_BGAlphaSliderText"] then
    _G["FR0Z3NUIFQT_BGAlphaSliderText"]:SetText("Alpha")
    _G["FR0Z3NUIFQT_BGAlphaSliderText"]:SetFontObject("GameFontDisableSmall")
  end
  if _G["FR0Z3NUIFQT_BGAlphaSliderLow"] then _G["FR0Z3NUIFQT_BGAlphaSliderLow"]:SetText("0") end
  if _G["FR0Z3NUIFQT_BGAlphaSliderHigh"] then _G["FR0Z3NUIFQT_BGAlphaSliderHigh"]:SetText("1") end
  optionsFrame._frameBgAlphaSlider = bgAlphaSlider

  local palette = {
    { 0.00, 0.00, 0.00 },
    { 0.20, 0.20, 0.20 },
    { 0.75, 0.75, 0.75 },
    { 1.00, 1.00, 1.00 },
    { 1.00, 0.25, 0.25 },
    { 1.00, 0.55, 0.10 },
    { 1.00, 0.90, 0.20 },
    { 0.20, 1.00, 0.20 },
    { 0.20, 0.60, 1.00 },
  }

  local paletteButtons = {}
  for i = 1, #palette do
    local btn = CreateFrame("Button", nil, panels.frames)
    btn:SetSize(12, 12)
    if i == 1 then
      -- Under Anchor dropdown; aligned with the Anchor label.
      btn:SetPoint("TOPLEFT", anchorPosDrop, "BOTTOMLEFT", 0, -32)
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
  optionsFrame._frameBgPaletteButtons = paletteButtons

  local bgMoreBtn = CreateFrame("Button", nil, panels.frames, "UIPanelButtonTemplate")
  bgMoreBtn:SetSize(48, 18)
  bgMoreBtn:SetPoint("TOPRIGHT", paletteButtons[#paletteButtons], "BOTTOMRIGHT", 0, -6)
  bgMoreBtn:SetText("More...")
  optionsFrame._frameBgMoreBtn = bgMoreBtn

  -- Alpha slider under palette (left-aligned), sized to not overlap the More button.
  bgAlphaSlider:ClearAllPoints()
  bgAlphaSlider:SetPoint("TOPLEFT", paletteButtons[1], "BOTTOMLEFT", 0, -6)
  bgAlphaSlider:SetPoint("TOPRIGHT", bgMoreBtn, "TOPLEFT", -10, 0)
  bgAlphaSlider:SetHeight(16)
  do
    local t = _G["FR0Z3NUIFQT_BGAlphaSliderText"]
    if t and t.ClearAllPoints and t.SetPoint then
      t:ClearAllPoints()
      t:SetPoint("TOP", bgAlphaSlider, "BOTTOM", 0, -2)
    end
  end

  local function FindEffectiveFrameDef(id)
    id = tostring(id or "")
    if id == "" then return nil end
    for _, def in ipairs(SafeFrames()) do
      if type(def) == "table" and tostring(def.id or "") == id then
        return def
      end
    end
    return nil
  end

  local function FindOrCreateCustomFrameDef(id)
    id = tostring(id or "")
    if id == "" then return nil end
    local frames = SafeCustomFrames()
    for _, def in ipairs(frames) do
      if type(def) == "table" and tostring(def.id or "") == id then
        return def
      end
    end
    local base = FindEffectiveFrameDef(id)
    if not base then return nil end
    local copy = (type(ShallowCopyTable) == "function" and ShallowCopyTable(base)) or nil
    copy = copy or { id = id }
    copy.id = id
    frames[#frames + 1] = copy
    return copy
  end

  local function UpdateFrameEditor()
    local id = tostring(optionsFrame._selectedFrameID or "")
    local def = FindEffectiveFrameDef(id)
    if not def then
      SafeCall(UpdateReverseOrderVisibility, "frames")
      if UDDM_SetText and optionsFrame._frameDrop then UDDM_SetText(optionsFrame._frameDrop, "(pick)") end
      -- Auto removed.
      if optionsFrame._frameHideCombat then
        optionsFrame._frameHideCombat:SetChecked(false)
        optionsFrame._frameHideCombat:Hide()
      end
      if optionsFrame._frameHideFrame then
        optionsFrame._frameHideFrame:Hide()
      end

      if optionsFrame._resetFrameBtn then optionsFrame._resetFrameBtn:Hide() end
      if optionsFrame._frameScaleSlider then optionsFrame._frameScaleSlider:Hide() end
      if optionsFrame._frameScaleValue then optionsFrame._frameScaleValue:Hide() end

      if optionsFrame._frameVisLinkLabel then optionsFrame._frameVisLinkLabel:Hide() end
      if optionsFrame._frameVisLinkModeBtn then optionsFrame._frameVisLinkModeBtn:Hide() end
      if optionsFrame._frameVisLinkNameBox then
        optionsFrame._frameVisLinkNameBox:SetText("")
        optionsFrame._frameVisLinkNameBox:SetEnabled(false)
        optionsFrame._frameVisLinkNameBox:Hide()
      end
      if optionsFrame._frameVisLinkPickBtn then optionsFrame._frameVisLinkPickBtn:Hide() end
      if optionsFrame._frameVisLinkStatus then
        optionsFrame._frameVisLinkStatus:SetText("")
        optionsFrame._frameVisLinkStatus:Hide()
      end
      if optionsFrame._frameNameBox then
        optionsFrame._frameNameBox:SetText("")
        optionsFrame._frameNameBox:SetEnabled(false)
      end
      if optionsFrame._framePadSlider then
        optionsFrame._skipPadChange = true
        optionsFrame._framePadSlider:SetValue(0)
        optionsFrame._skipPadChange = false
        optionsFrame._framePadSlider:Disable()
      end
      if optionsFrame._framePadValue then optionsFrame._framePadValue:SetText("0") end

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

      if optionsFrame._frameWidthBox then optionsFrame._frameWidthBox:SetText("0") end
      if optionsFrame._frameHeightBox then optionsFrame._frameHeightBox:SetText("0") end
      if optionsFrame._frameLengthBox then optionsFrame._frameLengthBox:SetText("0") end
      if optionsFrame._framePadSlider then
        optionsFrame._skipPadChange = true
        optionsFrame._framePadSlider:SetValue(0)
        optionsFrame._skipPadChange = false
      end
      if optionsFrame._framePadValue then optionsFrame._framePadValue:SetText("0") end

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

    if UDDM_SetText and optionsFrame._frameDrop and type(GetFrameDisplayNameByID) == "function" then
      UDDM_SetText(optionsFrame._frameDrop, GetFrameDisplayNameByID(def.id))
    end

    local t = tostring(def.type or "list")
    SafeCall(UpdateReverseOrderVisibility, "frames")
    if t == "list" then
      -- List mode: 2nd box = Max height (px), 3rd box = Rows (entry count).
      if optionsFrame._frameHeightLabel then optionsFrame._frameHeightLabel:SetText("H") end
      if optionsFrame._frameLengthLabel then optionsFrame._frameLengthLabel:SetText("Rows") end
      if optionsFrame._frameHeightBox and optionsFrame._frameHeightBox._ghostLabel then
        optionsFrame._frameHeightBox._ghostLabel:SetText("H")
      end
      if optionsFrame._frameLengthBox and optionsFrame._frameLengthBox._ghostLabel then
        optionsFrame._frameLengthBox._ghostLabel:SetText("Rows")
      end
      if optionsFrame._frameHeightBox then optionsFrame._frameHeightBox:SetText(tostring(tonumber(def.maxHeight) or 0)) end
      if optionsFrame._frameLengthBox then optionsFrame._frameLengthBox:SetText(tostring(tonumber(def.maxItems) or 20)) end
    else
      if optionsFrame._frameHeightLabel then optionsFrame._frameHeightLabel:SetText("Height") end
      if optionsFrame._frameLengthLabel then optionsFrame._frameLengthLabel:SetText("Segments") end
      if optionsFrame._frameHeightBox and optionsFrame._frameHeightBox._ghostLabel then
        optionsFrame._frameHeightBox._ghostLabel:SetText("H")
      end
      if optionsFrame._frameLengthBox and optionsFrame._frameLengthBox._ghostLabel then
        optionsFrame._frameLengthBox._ghostLabel:SetText("Seg")
      end
      if optionsFrame._frameHeightBox then optionsFrame._frameHeightBox:SetText(tostring(tonumber(def.height) or 20)) end
    end

    if optionsFrame._frameHideCombat then
      optionsFrame._frameHideCombat:SetChecked(def.hideInCombat == true)
      optionsFrame._frameHideCombat:Show()
    end

    if optionsFrame._frameHideFrame then
      UpdateHideFrameButton(def)
      optionsFrame._frameHideFrame:Show()
    end

    if optionsFrame._resetFrameBtn then optionsFrame._resetFrameBtn:Show() end

    if optionsFrame._frameScaleSlider and optionsFrame._frameScaleValue then
      local sc = tonumber(def.scale)
      if sc == nil then sc = 1 end
      if sc < 0.50 then sc = 0.50 end
      if sc > 2.00 then sc = 2.00 end
      optionsFrame._skipScaleChange = true
      optionsFrame._frameScaleSlider:SetValue(sc)
      optionsFrame._skipScaleChange = false
      optionsFrame._frameScaleValue:SetText(string.format("%d%%", math.floor(sc * 100 + 0.5)))
      optionsFrame._frameScaleSlider:Show()
      optionsFrame._frameScaleValue:Show()
    end

    -- External visibility link controls
    do
      local mode = tostring((type(def) == "table" and def.visibilityLinkMode) or "")
      mode = mode:lower():gsub("%s+", "")
      if mode == "parent" or mode == "reparent" then mode = "hook" end
      if mode ~= "hook" then mode = "off" end
      local nm = (type(def) == "table" and def.visibilityLinkFrame ~= nil) and tostring(def.visibilityLinkFrame) or ""
      nm = nm:gsub("^%s+", ""):gsub("%s+$", "")

      if optionsFrame._frameVisLinkLabel then optionsFrame._frameVisLinkLabel:Show() end
      if optionsFrame._frameVisLinkModeBtn then
        optionsFrame._frameVisLinkModeBtn:SetText((mode == "hook") and "Hook" or "Off")
        optionsFrame._frameVisLinkModeBtn:Show()
      end
      if optionsFrame._frameVisLinkNameBox then
        optionsFrame._frameVisLinkNameBox:SetText(nm)
        optionsFrame._frameVisLinkNameBox:SetEnabled(true)
        optionsFrame._frameVisLinkNameBox:Show()
      end
      if optionsFrame._frameVisLinkPickBtn then optionsFrame._frameVisLinkPickBtn:Show() end
      if optionsFrame._frameVisLinkStatus then
        if nm == "" then
          optionsFrame._frameVisLinkStatus:SetText("")
        else
          local ok = (_G and _G[nm]) and true or false
          optionsFrame._frameVisLinkStatus:SetText(ok and "Found" or "Not found")
        end
        optionsFrame._frameVisLinkStatus:Show()
      end
    end

    if optionsFrame._frameNameBox then
      local nm = (type(def) == "table" and def.name ~= nil) and tostring(def.name) or ""
      optionsFrame._frameNameBox:SetText(nm)
      optionsFrame._frameNameBox:SetEnabled(true)
    end

    if optionsFrame._frameWidthBox then optionsFrame._frameWidthBox:SetText(tostring(tonumber(def.width) or 300)) end
    if t ~= "list" then
      if optionsFrame._frameLengthBox then
        optionsFrame._frameLengthBox:SetText(tostring(tonumber(def.maxItems) or 6))
      end
    end

    if optionsFrame._framePadSlider then
      local v = tonumber(def.pad) or 0
      if v < -10 then v = -10 end
      if v > 10 then v = 10 end
      optionsFrame._skipPadChange = true
      optionsFrame._framePadSlider:SetValue(v)
      optionsFrame._skipPadChange = false
      optionsFrame._framePadSlider:Enable()
      if optionsFrame._framePadValue then optionsFrame._framePadValue:SetText(tostring(v)) end
    end

    if optionsFrame._frameAnchorPosDrop then
      local corner = NormalizeAnchorCornerLocal(def.anchorCorner) or "tl"
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

    -- Auto removed: inputs are always editable when a frame is selected.
    optionsFrame._frameWidthBox:SetEnabled(true)
    optionsFrame._frameHeightBox:SetEnabled(true)
    optionsFrame._frameLengthBox:SetEnabled(true)
    if optionsFrame._framePadSlider then
      optionsFrame._framePadSlider:Enable()
    end
  end

  -- External visibility link interactions
  do
    local function GetOrCreateSelectedCustomDef()
      local id = tostring(optionsFrame._selectedFrameID or "")
      if id == "" then return nil end
      return FindOrCreateCustomFrameDef(id)
    end

    local function NormalizeLinkMode(v)
      v = tostring(v or ""):lower():gsub("%s+", "")
      if v == "hook" then return "hook" end
      if v == "parent" or v == "reparent" then return "hook" end
      return "off"
    end

    local function SetLinkMode(def, mode)
      mode = NormalizeLinkMode(mode)
      if mode == "off" then
        def.visibilityLinkMode = nil
        def.visibilityLinkFrame = nil
        return
      end
      def.visibilityLinkMode = mode
    end

    if optionsFrame._frameVisLinkModeBtn then
      optionsFrame._frameVisLinkModeBtn:SetScript("OnClick", function()
        local def = GetOrCreateSelectedCustomDef()
        if not def then return end
        local cur = NormalizeLinkMode(def.visibilityLinkMode)
        local nextMode = (cur == "off") and "hook" or "off"
        SetLinkMode(def, nextMode)
        SafeCall(CreateAllFrames)
        SafeCall(RefreshAll)
        UpdateFrameEditor()
      end)
    end

    if optionsFrame._frameVisLinkNameBox then
      optionsFrame._frameVisLinkNameBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        local def = GetOrCreateSelectedCustomDef()
        if not def then return end
        local nm = tostring(self:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", "")
        def.visibilityLinkFrame = (nm ~= "") and nm or nil
        SafeCall(CreateAllFrames)
        SafeCall(RefreshAll)
        UpdateFrameEditor()
      end)
    end

    -- Click-to-pick a frame name by clicking it in the UI.
    local function StopPick()
      optionsFrame._frameVisLinkPicking = nil
      if optionsFrame._frameVisLinkPickBtn then
        optionsFrame._frameVisLinkPickBtn:SetText("Pick")
      end
      if optionsFrame._frameVisLinkPickerOverlay and optionsFrame._frameVisLinkPickerOverlay.Hide then
        optionsFrame._frameVisLinkPickerOverlay:Hide()
      end
    end

    local function StartPick()
      optionsFrame._frameVisLinkPicking = true
      if optionsFrame._frameVisLinkPickBtn then
        optionsFrame._frameVisLinkPickBtn:SetText("Cancel")
      end
      Print("Click the target addon's frame to select it (Right-click to cancel).")

      if not optionsFrame._frameVisLinkPickerOverlay then
        local overlay = CreateFrame("Frame", nil, UIParent)
        overlay:SetFrameStrata("TOOLTIP")
        overlay:SetFrameLevel(9999)
        overlay:SetAllPoints(UIParent)
        overlay:EnableMouse(true)
        overlay:SetPropagateMouseClicks(true)
        overlay:SetPropagateKeyboardInput(true)
        overlay:Hide()

        overlay:SetScript("OnMouseDown", function(self, button)
          if not (optionsFrame and optionsFrame._frameVisLinkPicking) then return end
          if button == "RightButton" then
            StopPick()
            return
          end

          -- Hide the overlay first; many frames don't propagate clicks, so UIParent hooks
          -- won't see them. Deferring by one frame lets GetMouseFocus see the real target.
          if self.Hide then self:Hide() end

          C_Timer.After(0, function()
            if not (optionsFrame and optionsFrame._frameVisLinkPicking) then return end

            local function IsBadTarget(w)
              if not w then return true end
              if w == UIParent then return true end
              if optionsFrame and w == optionsFrame then return true end
              if w.IsDescendantOf and optionsFrame and w:IsDescendantOf(optionsFrame) then return true end
              return false
            end

            local function FindNamedParent(w)
              if not w then return nil end
              local nm = (w.GetName and w:GetName()) or ""
              nm = tostring(nm or "")
              if nm ~= "" then return w, nm end
              for _ = 1, 40 do
                if not (w and w.GetParent) then break end
                w = w:GetParent()
                if not w then break end
                local pn = (w.GetName and w:GetName()) or ""
                pn = tostring(pn or "")
                if pn ~= "" then return w, pn end
              end
              return nil
            end

            local picked, nm

            -- Prefer GetMouseFoci() when available.
            local GMFs = _G and rawget(_G, "GetMouseFoci")
            if type(GMFs) == "function" then
              local foci = GMFs()
              if type(foci) == "table" then
                for _, w in ipairs(foci) do
                  if not IsBadTarget(w) then
                    picked, nm = FindNamedParent(w)
                    if picked and nm and nm ~= "" and not IsBadTarget(picked) then
                      break
                    end
                  end
                end
              end
            end

            -- Fallback: plain GetMouseFocus.
            if not nm or nm == "" then
              local GMF = _G and rawget(_G, "GetMouseFocus")
              local w = (type(GMF) == "function") and GMF() or nil
              if not IsBadTarget(w) then
                picked, nm = FindNamedParent(w)
              end
            end

            nm = tostring(nm or "")
            if nm == "" then
              Print("Couldn't find a named frame under the cursor.")
              StopPick()
              return
            end

            local def = GetOrCreateSelectedCustomDef()
            if not def then StopPick(); return end
            def.visibilityLinkFrame = nm
            if optionsFrame._frameVisLinkNameBox then
              optionsFrame._frameVisLinkNameBox:SetText(nm)
            end
            SafeCall(CreateAllFrames)
            SafeCall(RefreshAll)
            UpdateFrameEditor()
            StopPick()
          end)
        end)

        optionsFrame._frameVisLinkPickerOverlay = overlay
      end

      if optionsFrame._frameVisLinkPickerOverlay and optionsFrame._frameVisLinkPickerOverlay.Show then
        optionsFrame._frameVisLinkPickerOverlay:Show()
      end
    end

    if optionsFrame._frameVisLinkPickBtn then
      optionsFrame._frameVisLinkPickBtn:SetScript("OnClick", function()
        if optionsFrame._frameVisLinkPicking then
          StopPick()
        else
          StartPick()
        end
      end)
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

    if CPF.ClearAllPoints and CPF.SetPoint and optionsFrame and optionsFrame.IsShown and optionsFrame:IsShown() then
      CPF:ClearAllPoints()
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

      ---@diagnostic disable-next-line: duplicate-set-field
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

      ---@diagnostic disable-next-line: duplicate-set-field
      CPF.cancelFunc = function(restored)
        local rv = restored or prev
        if onChanged then onChanged(rv[1], rv[2], rv[3], rv[4]) end
      end

      CPF:SetColorRGB(r0, g0, b0)
      CPF:Show()
    end
  end

  local function ApplyBGToSelectedFrame(r, g, b, a)
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
    SafeCall(RefreshAll)
    if RefreshFramesList then RefreshFramesList() end
  end

  for i, btn in ipairs(paletteButtons) do
    btn:SetScript("OnClick", function()
      local c = palette[i]
      if not c then return end
      local a = nil
      if optionsFrame._frameBgAlphaSlider and optionsFrame._frameBgAlphaSlider.GetValue then
        a = tonumber(optionsFrame._frameBgAlphaSlider:GetValue())
      end
      if a == nil then a = 0 end
      if a <= 0 then
        a = 0.25
        if optionsFrame._frameBgAlphaSlider and optionsFrame._frameBgAlphaSlider.SetValue then
          optionsFrame._skipBgAlphaChange = true
          optionsFrame._frameBgAlphaSlider:SetValue(a)
          optionsFrame._skipBgAlphaChange = false
        end
      end
      ApplyBGToSelectedFrame(c[1], c[2], c[3], a)
    end)
  end

  bgMoreBtn:SetScript("OnClick", function()
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
    if optionsFrame._skipBgAlphaChange then return end
    local id = tostring(optionsFrame._selectedFrameID or "")
    if id == "" then return end
    local eff = FindEffectiveFrameDef(id)
    if not eff then return end
    local def = FindOrCreateCustomFrameDef(id)
    if not def then return end
    def.bgAlpha = tonumber(value) or 0
    SafeCall(RefreshAll)
    if RefreshFramesList then RefreshFramesList() end
  end)

  if optionsFrame._frameScaleSlider then
    optionsFrame._frameScaleSlider:SetScript("OnValueChanged", function(self, value)
      if optionsFrame._skipScaleChange then return end
      local id = tostring(optionsFrame._selectedFrameID or "")
      if id == "" then return end
      local eff = FindEffectiveFrameDef(id)
      if not eff then return end
      local def = FindOrCreateCustomFrameDef(id)
      if not def then return end

      local sc = tonumber(value) or 1
      if sc < 0.50 then sc = 0.50 end
      if sc > 2.00 then sc = 2.00 end
      sc = math.floor(sc * 100 + 0.5) / 100

      if math.abs(sc - 1) < 0.001 then
        def.scale = nil
      else
        def.scale = sc
      end

      if optionsFrame._frameScaleValue then
        optionsFrame._frameScaleValue:SetText(string.format("%d%%", math.floor(sc * 100 + 0.5)))
      end

      SafeCall(CreateAllFrames)
      SafeCall(RefreshAll)
      if RefreshFramesList then RefreshFramesList() end
    end)
  end

  if optionsFrame._resetFrameBtn then
    local ClearSavedFramePosition = ctx.ClearSavedFramePosition or (ns and ns.ClearSavedFramePosition)
    optionsFrame._resetFrameBtn:SetScript("OnClick", function()
      local id = tostring(optionsFrame._selectedFrameID or "")
      if id == "" then return end
      local eff = FindEffectiveFrameDef(id)
      if not eff then return end
      local def = FindOrCreateCustomFrameDef(id)
      if def then
        def.scale = nil
      end
      if type(ClearSavedFramePosition) == "function" then
        ClearSavedFramePosition(id)
      end
      SafeCall(CreateAllFrames)
      SafeCall(RefreshAll)
      if RefreshFramesList then RefreshFramesList() end
      UpdateFrameEditor()
      Print("Reset frame " .. id .. ".")
    end)
  end

  frameHideCombat:SetScript("OnClick", function(self)
    local id = tostring(optionsFrame._selectedFrameID or "")
    if id == "" then return end
    local eff = FindEffectiveFrameDef(id)
    if not eff then return end
    local def = FindOrCreateCustomFrameDef(id)
    if not def then return end
    def.hideInCombat = self:GetChecked() and true or nil
    SafeCall(RefreshAll)
    if RefreshFramesList then RefreshFramesList() end
  end)

  if frameHideFrame then
    frameHideFrame:SetScript("OnClick", function(self)
      local id = tostring(optionsFrame._selectedFrameID or "")
      if id == "" then return end
      local eff = FindEffectiveFrameDef(id)
      if not eff then return end
      local def = FindOrCreateCustomFrameDef(id)
      if not def then return end
      -- Toggle based on the CURRENT effective state (not the current custom override).
      -- This is critical for default-hidden frames (e.g. bar2/list2/list3).
      local newHide = (eff.hideFrame ~= true)
      def.hideFrame = newHide

      -- Optional debug: hold SHIFT while clicking to print current state.
      if IsShiftKeyDown and IsShiftKeyDown() then
        Print(string.format("Toggle hideFrame %s: effective=%s -> custom=%s", id, tostring(eff.hideFrame == true), tostring(newHide == true)))
      end

      SafeCall(RefreshAll)

      -- Re-read effective state after refresh so the button reflects what the engine will use.
      local eff2 = FindEffectiveFrameDef(id)
      UpdateHideFrameButton(eff2 or def)
      if RefreshFramesList then RefreshFramesList() end
    end)
  end

  if UDDM_Initialize and UDDM_CreateInfo and UDDM_AddButton and type(UseModernMenuDropDown) == "function" then
    local modernFrameDrop = UseModernMenuDropDown(frameDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Select frame") end
      for _, def in ipairs(SafeFrames()) do
        if type(def) == "table" and def.id and root then
          local id = tostring(def.id)
          local label = type(GetFrameDisplayNameByID) == "function" and GetFrameDisplayNameByID(id) or id
          local function IsSelected()
            return (optionsFrame._selectedFrameID == id) and true or false
          end
          local function SetSelected()
            optionsFrame._selectedFrameID = id
            UpdateFrameEditor()
            SafeCall(UpdateReverseOrderVisibility, "frames")
          end
          if root.CreateRadio then
            root:CreateRadio(label, IsSelected, SetSelected)
          elseif root.CreateButton then
            root:CreateButton(label, SetSelected)
          end
        end
      end

      if root then
        if root.CreateDivider then root:CreateDivider() end
        if root.CreateButton then
          root:CreateButton("ReOrder...", function() ToggleReorderPopup(true) end)
        end
      end
    end)

    if not modernFrameDrop then
      UDDM_Initialize(frameDrop, function(_, level)
        if level ~= 1 then return end
        for _, def in ipairs(SafeFrames()) do
          if type(def) == "table" and def.id then
            local id = tostring(def.id)
            local info = UDDM_CreateInfo()
            info.text = type(GetFrameDisplayNameByID) == "function" and GetFrameDisplayNameByID(id) or id
            info.checked = (optionsFrame._selectedFrameID == id) and true or false
            info.func = function()
              optionsFrame._selectedFrameID = id
              UpdateFrameEditor()
              SafeCall(UpdateReverseOrderVisibility, "frames")
            end
            UDDM_AddButton(info)
          end
        end

        do
          local info = UDDM_CreateInfo()
          info.text = " "
          info.disabled = true
          info.notCheckable = true
          UDDM_AddButton(info)
        end
        do
          local info = UDDM_CreateInfo()
          info.text = "ReOrder..."
          info.notCheckable = true
          info.func = function() ToggleReorderPopup(true) end
          UDDM_AddButton(info)
        end
      end)
    end
  else
    frameEditLabel:SetText("Select frame: (dropdown unavailable)")
  end

  local function ApplySelectedFrameAnchorCorner(corner)
    local id = tostring(optionsFrame._selectedFrameID or "")
    if id == "" then return end
    local eff = FindEffectiveFrameDef(id)
    if not eff then return end
    local def = FindOrCreateCustomFrameDef(id)
    if not def then return end

    corner = NormalizeAnchorCornerLocal(corner)
    def.anchorCorner = corner
    def.growDir = DeriveGrowDirFromCorner(corner)

    -- Follow the configured anchor rules (no screen-coordinate conversion).
    do
      local point = (corner == "tr" and "TOPRIGHT") or (corner == "bl" and "BOTTOMLEFT") or (corner == "br" and "BOTTOMRIGHT") or "TOPLEFT"
      def.point = point
      def.relPoint = point

      -- Ensure any previously saved dragged position does not override the new anchor.
      if type(ns.ClearSavedFramePosition) == "function" then
        ns.ClearSavedFramePosition(id)
      end
    end

    SafeCall(RefreshAll)
    if RefreshFramesList then RefreshFramesList() end
  end

  local function ApplySelectedFrameGrowDir(dir)
    local id = tostring(optionsFrame._selectedFrameID or "")
    if id == "" then return end
    local eff = FindEffectiveFrameDef(id)
    if not eff then return end
    local def = FindOrCreateCustomFrameDef(id)
    if not def then return end
    dir = NormalizeGrowDirLocal(dir)
    def.growDir = dir
    def.anchorCorner = DeriveCornerFromGrowDir(dir)
    SafeCall(RefreshAll)
    if RefreshFramesList then RefreshFramesList() end
  end

  if type(UseModernMenuDropDown) == "function" and UseModernMenuDropDown(anchorPosDrop, function(root)
    if root and root.CreateTitle then root:CreateTitle("Anchor") end
    local cur = nil
    do
      local id = tostring(optionsFrame._selectedFrameID or "")
      local eff = (id ~= "") and FindEffectiveFrameDef(id) or nil
      cur = (type(eff) == "table") and NormalizeAnchorCornerLocal(eff.anchorCorner) or nil
      if not cur then cur = "tl" end
    end
    for _, v in ipairs({ "tl", "tr", "bl", "br" }) do
      if root and root.CreateRadio then
        root:CreateRadio(AnchorGrowLabel(v), function() return cur == v end, function() ApplySelectedFrameAnchorCorner(v) end)
      elseif root and root.CreateButton then
        root:CreateButton(AnchorGrowLabel(v), function() ApplySelectedFrameAnchorCorner(v) end)
      end
    end
  end) then
    -- modern menu wired
  elseif UDDM_Initialize and UDDM_CreateInfo and UDDM_AddButton then
    UDDM_Initialize(anchorPosDrop, function(_, level)
      if level ~= 1 then return end
      for _, v in ipairs({ "tl", "tr", "bl", "br" }) do
        local info = UDDM_CreateInfo()
        info.text = AnchorGrowLabel(v)
        info.func = function() ApplySelectedFrameAnchorCorner(v) end
        UDDM_AddButton(info)
      end
    end)
  end

  if type(UseModernMenuDropDown) == "function" and UseModernMenuDropDown(growDirDrop, function(root)
    if root and root.CreateTitle then root:CreateTitle("Grow") end
    local cur = nil
    do
      local id = tostring(optionsFrame._selectedFrameID or "")
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
    UDDM_Initialize(growDirDrop, function(_, level)
      if level ~= 1 then return end
      for _, v in ipairs({ "up-left", "up-right", "down-left", "down-right" }) do
        local info = UDDM_CreateInfo()
        info.text = GrowDirLabel(v)
        info.func = function() ApplySelectedFrameGrowDir(v) end
        UDDM_AddButton(info)
      end
    end)
  end

  local function ClampPad(v)
    v = tonumber(v)
    if not v then return nil end
    if v < -10 then v = -10 end
    if v > 10 then v = 10 end
    if v == 0 then return nil end
    return v
  end

  local function ApplyFrameSizeFromInputs()
    local id = tostring(optionsFrame._selectedFrameID or "")
    if id == "" then return end
    local eff = FindEffectiveFrameDef(id)
    local def = FindOrCreateCustomFrameDef(id)
    if not (eff and def) then return end

    def.width = tonumber(optionsFrame._frameWidthBox:GetText() or "")
    if tostring(eff.type or "list") == "list" then
      -- List mode: 2nd box = Max height, 3rd box = Rows (maxItems).
      def.maxHeight = (tonumber(optionsFrame._frameHeightBox:GetText() or "") or 0)
      if def.maxHeight and def.maxHeight > 0 then
        -- keep
      else
        def.maxHeight = nil
      end
      def.maxItems = tonumber(optionsFrame._frameLengthBox:GetText() or "")
      -- Row height is not edited here (multi-line wrapping makes fixed row heights awkward).
    else
      def.height = tonumber(optionsFrame._frameHeightBox:GetText() or "")
      def.maxItems = tonumber(optionsFrame._frameLengthBox:GetText() or "")
    end

    if optionsFrame._framePadSlider and optionsFrame._framePadSlider.GetValue then
      def.pad = ClampPad(optionsFrame._framePadSlider:GetValue())
    end

    SafeCall(CreateAllFrames)
    SafeCall(RefreshAll)
    if RefreshFramesList then RefreshFramesList() end
  end

  widthBox:SetScript("OnEnterPressed", function(self) self:ClearFocus(); ApplyFrameSizeFromInputs() end)
  heightBox:SetScript("OnEnterPressed", function(self) self:ClearFocus(); ApplyFrameSizeFromInputs() end)
  lengthBox:SetScript("OnEnterPressed", function(self) self:ClearFocus(); ApplyFrameSizeFromInputs() end)
  if optionsFrame._framePadSlider then
    optionsFrame._framePadSlider:SetScript("OnValueChanged", function(self, value)
      if optionsFrame._skipPadChange then return end
      local id = tostring(optionsFrame._selectedFrameID or "")
      if id == "" then return end
      local def = FindOrCreateCustomFrameDef(id)
      if not def then return end

      def.pad = ClampPad(value)
      if optionsFrame._framePadValue then optionsFrame._framePadValue:SetText(tostring(tonumber(value) or 0)) end

      SafeCall(CreateAllFrames)
      SafeCall(RefreshAll)
      if RefreshFramesList then RefreshFramesList() end
    end)
  end

  nameBox:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
    local id = tostring(optionsFrame._selectedFrameID or "")
    if id == "" then return end
    local def = FindOrCreateCustomFrameDef(id)
    if not def then return end

    local nm = tostring(self:GetText() or "")
    nm = nm:gsub("^%s+", ""):gsub("%s+$", "")
    def.name = (nm ~= "") and nm or nil
    if RefreshFramesList then RefreshFramesList() end
    SafeCall(RefreshAll)
  end)

  RefreshFramesList = function()
    UpdateFrameEditor()

    local frames = SafeCustomFrames()
    local rowH = 20
    local fcontent = optionsFrame._framesContent
    local frows = optionsFrame._frameRows
    if not (fcontent and frows) then return end
    if optionsFrame._framesScroll and fcontent then
      local w = tonumber(optionsFrame._framesScroll:GetWidth() or 0) or 0
      fcontent:SetWidth(math.max(1, w - 28))
    end
    if fcontent then
      fcontent:SetHeight(math.max(1, #frames * rowH))
    end

    local zebraA = (type(GetUISetting) == "function") and (tonumber(GetUISetting("zebraAlpha", 0.05) or 0.05) or 0.05) or 0.05
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
        row.up:SetSize(16, 16)
        row.up:SetText("")
        row.up:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
        row.up:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Down")
        row.up:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Highlight")
        row.up:SetDisabledTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Disabled")
        row.up:SetScript("OnEnter", function(self)
          if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Move up")
            GameTooltip:Show()
          end
        end)
        row.up:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

        row.down = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.down:SetSize(16, 16)
        row.down:SetText("")
        row.down:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
        row.down:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Down")
        row.down:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Highlight")
        row.down:SetDisabledTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Disabled")
        row.down:SetScript("OnEnter", function(self)
          if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Move down")
            GameTooltip:Show()
          end
        end)
        row.down:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

        row.down:SetPoint("RIGHT", -2, 0)
        row.up:SetPoint("RIGHT", row.down, "LEFT", -2, 0)
        row.text:SetPoint("RIGHT", row.up, "LEFT", -4, 0)
        frows[i] = row
      end

      -- If the list container changed (legacy hidden list -> popout), re-parent cached rows.
      if row.GetParent and row.SetParent and row:GetParent() ~= fcontent then
        row:SetParent(fcontent)
        if row.ClearAllPoints then row:ClearAllPoints() end
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
        SafeCall(RefreshAll)
        if RefreshFramesList then RefreshFramesList() end
      end)

      row.down:SetScript("OnClick", function()
        if idx >= #frames then return end
        frames[idx], frames[idx + 1] = frames[idx + 1], frames[idx]
        SafeCall(RefreshAll)
        if RefreshFramesList then RefreshFramesList() end
      end)

      row:Show()
    end

    for i = #frames + 1, #frows do
      if frows[i] then frows[i]:Hide() end
    end
  end

  optionsFrame._refreshFramesList = RefreshFramesList
  if type(ctx.SetRefreshFramesList) == "function" then
    ctx.SetRefreshFramesList(RefreshFramesList)
  end
end
