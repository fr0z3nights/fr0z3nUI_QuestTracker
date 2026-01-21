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

  -- Global List Padding control
  local listPadLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  listPadLabel:SetPoint("TOPLEFT", 365, -160)
  listPadLabel:SetText("List padding (px)  (non-Edit Mode)")

  local listPadBox = CreateFrame("EditBox", nil, panels.frames, "InputBoxTemplate")
  listPadBox:SetSize(40, 20)
  listPadBox:SetPoint("TOPLEFT", 365, -176)
  listPadBox:SetAutoFocus(false)
  listPadBox:SetNumeric(true)
  if listPadBox.SetJustifyH then listPadBox:SetJustifyH("RIGHT") end

  local function RefreshListPadBox(self)
    local v = (type(GetUISetting) == "function") and (tonumber(GetUISetting("listPadding", 0) or 0) or 0) or 0
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
    if type(SetUISetting) == "function" then
      SetUISetting("listPadding", v)
    end
    RefreshListPadBox(self)
    if self.ClearFocus then self:ClearFocus() end
    SafeCall(RefreshAll)
  end)
  listPadBox:SetScript("OnEscapePressed", function(self)
    RefreshListPadBox(self)
    if self.ClearFocus then self:ClearFocus() end
  end)

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
  addBarBtn:SetPoint("TOPRIGHT", -110, -40)
  addBarBtn:SetText("Add Bar")

  local addListBtn = CreateFrame("Button", nil, panels.frames, "UIPanelButtonTemplate")
  addListBtn:SetSize(90, 22)
  addListBtn:SetPoint("TOPRIGHT", -12, -40)
  addListBtn:SetText("Add List")

  optionsFrame._addBarBtn = addBarBtn
  optionsFrame._addListBtn = addListBtn

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

  local framesTitle = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  framesTitle:SetPoint("TOPLEFT", 12, -40)
  framesTitle:SetText("")
  framesTitle:Hide()

  local framesScroll = CreateFrame("ScrollFrame", nil, panels.frames, "UIPanelScrollFrameTemplate")
  framesScroll:SetPoint("TOPLEFT", 12, -182)
  framesScroll:SetPoint("BOTTOMLEFT", 12, 44)
  framesScroll:SetWidth(530)

  local zebraFrames = CreateFrame("Slider", nil, panels.frames, "UISliderTemplate")
  zebraFrames:ClearAllPoints()
  zebraFrames:SetPoint("BOTTOM", optionsFrame, "BOTTOM", 0, 18)
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

  -- Frame editor (shown only when Show frame list is enabled)
  local frameEditTitle = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frameEditTitle:SetPoint("TOPLEFT", 12, -40)
  frameEditTitle:SetText("Settings")
  optionsFrame._frameEditTitle = frameEditTitle

  local frameEditLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  frameEditLabel:SetPoint("TOPLEFT", 12, -58)
  frameEditLabel:SetText("Select:")
  optionsFrame._frameEditLabel = frameEditLabel

  local frameDrop = CreateFrame("Frame", nil, panels.frames, "UIDropDownMenuTemplate")
  frameDrop:SetPoint("TOPLEFT", -8, -68)
  if UDDM_SetWidth then UDDM_SetWidth(frameDrop, 160) end
  if UDDM_SetText then UDDM_SetText(frameDrop, "(pick)") end
  optionsFrame._frameDrop = frameDrop
  optionsFrame._selectedFrameID = nil

  local frameAuto = CreateFrame("CheckButton", nil, panels.frames, "UICheckButtonTemplate")
  frameAuto:SetPoint("TOPLEFT", 200, -72)
  if SetCheckButtonLabel then SetCheckButtonLabel(frameAuto, "Auto") end
  optionsFrame._frameAuto = frameAuto

  local nameLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  nameLabel:SetPoint("TOPLEFT", 12, -82)
  nameLabel:SetText("Name")
  optionsFrame._frameNameLabel = nameLabel

  local nameBox = CreateFrame("EditBox", nil, panels.frames, "InputBoxTemplate")
  nameBox:SetSize(180, 20)
  nameBox:SetPoint("TOPLEFT", 55, -88)
  nameBox:SetAutoFocus(false)
  nameBox:SetText("")
  optionsFrame._frameNameBox = nameBox

  local frameHideCombat = CreateFrame("CheckButton", nil, panels.frames, "UICheckButtonTemplate")
  frameHideCombat:SetPoint("TOPLEFT", 260, -72)
  if SetCheckButtonLabel then SetCheckButtonLabel(frameHideCombat, "Hide in combat") end
  frameHideCombat:Hide()
  optionsFrame._frameHideCombat = frameHideCombat

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
  optionsFrame._frameAnchorPosLabel = anchorPosLabel

  local anchorPosDrop = CreateFrame("Frame", nil, panels.frames, "UIDropDownMenuTemplate")
  anchorPosDrop:SetPoint("TOPLEFT", 340, -68)
  if UDDM_SetWidth then UDDM_SetWidth(anchorPosDrop, 170) end
  if UDDM_SetText then UDDM_SetText(anchorPosDrop, "(auto)") end
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

  local widthBox = CreateFrame("EditBox", nil, panels.frames, "InputBoxTemplate")
  widthBox:SetSize(60, 20)
  widthBox:SetPoint("TOPLEFT", 55, -106)
  widthBox:SetAutoFocus(false)
  widthBox:SetNumeric(true)
  widthBox:SetText("0")
  if widthBox.SetJustifyH then widthBox:SetJustifyH("RIGHT") end
  optionsFrame._frameWidthBox = widthBox
  AddGhostLabel(widthBox, "W")

  local heightBox = CreateFrame("EditBox", nil, panels.frames, "InputBoxTemplate")
  heightBox:SetSize(60, 20)
  heightBox:SetPoint("TOPLEFT", 175, -106)
  heightBox:SetAutoFocus(false)
  heightBox:SetNumeric(true)
  heightBox:SetText("0")
  if heightBox.SetJustifyH then heightBox:SetJustifyH("RIGHT") end
  optionsFrame._frameHeightBox = heightBox
  AddGhostLabel(heightBox, "H")

  local lengthBox = CreateFrame("EditBox", nil, panels.frames, "InputBoxTemplate")
  lengthBox:SetSize(60, 20)
  lengthBox:SetPoint("TOPLEFT", 292, -106)
  lengthBox:SetAutoFocus(false)
  lengthBox:SetNumeric(true)
  lengthBox:SetText("0")
  if lengthBox.SetJustifyH then lengthBox:SetJustifyH("RIGHT") end
  optionsFrame._frameLengthBox = lengthBox
  AddGhostLabel(lengthBox, "Len")

  local maxHBox = CreateFrame("EditBox", nil, panels.frames, "InputBoxTemplate")
  maxHBox:SetSize(60, 20)
  maxHBox:SetPoint("TOPLEFT", 410, -106)
  maxHBox:SetAutoFocus(false)
  maxHBox:SetNumeric(true)
  maxHBox:SetText("0")
  if maxHBox.SetJustifyH then maxHBox:SetJustifyH("RIGHT") end
  optionsFrame._frameMaxHBox = maxHBox
  AddGhostLabel(maxHBox, "Max")

  local widthLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  widthLabel:SetPoint("TOPLEFT", 12, -100)
  widthLabel:SetText("Width")
  widthLabel:Hide()
  optionsFrame._frameWidthLabel = widthLabel

  local heightLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  heightLabel:SetPoint("TOPLEFT", 125, -100)
  heightLabel:SetText("Height")
  heightLabel:Hide()
  optionsFrame._frameHeightLabel = heightLabel

  local lengthLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  lengthLabel:SetPoint("TOPLEFT", 245, -100)
  lengthLabel:SetText("Length")
  lengthLabel:Hide()
  optionsFrame._frameLengthLabel = lengthLabel

  local maxHLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  maxHLabel:SetPoint("TOPLEFT", 365, -100)
  maxHLabel:SetText("Max H")
  maxHLabel:Hide()
  optionsFrame._frameMaxHLabel = maxHLabel

  -- Background (per-frame)
  local bgLabel = panels.frames:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  bgLabel:SetPoint("TOPLEFT", 12, -130)
  bgLabel:SetText("Background")
  optionsFrame._frameBgLabel = bgLabel

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
  optionsFrame._frameBgSwatch = bgSwatch

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
  optionsFrame._frameBgPaletteButtons = paletteButtons

  local bgMoreBtn = CreateFrame("Button", nil, panels.frames, "UIPanelButtonTemplate")
  bgMoreBtn:SetSize(56, 18)
  bgMoreBtn:SetPoint("LEFT", paletteButtons[#paletteButtons], "RIGHT", 6, 0)
  bgMoreBtn:SetText("More...")
  optionsFrame._frameBgMoreBtn = bgMoreBtn

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
      if optionsFrame._frameAuto then optionsFrame._frameAuto:SetChecked(false) end
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

      if optionsFrame._frameWidthBox then optionsFrame._frameWidthBox:SetText("0") end
      if optionsFrame._frameHeightBox then optionsFrame._frameHeightBox:SetText("0") end
      if optionsFrame._frameLengthBox then optionsFrame._frameLengthBox:SetText("0") end

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
      if optionsFrame._frameHeightLabel then optionsFrame._frameHeightLabel:SetText("Row") end
      if optionsFrame._frameLengthLabel then optionsFrame._frameLengthLabel:SetText("Rows") end
      if optionsFrame._frameHeightBox and optionsFrame._frameHeightBox._ghostLabel then
        optionsFrame._frameHeightBox._ghostLabel:SetText("Row")
      end
      if optionsFrame._frameLengthBox and optionsFrame._frameLengthBox._ghostLabel then
        optionsFrame._frameLengthBox._ghostLabel:SetText("Rows")
      end
      if optionsFrame._frameHeightBox then optionsFrame._frameHeightBox:SetText(tostring(tonumber(def.rowHeight) or 16)) end
      if optionsFrame._frameMaxHBox then
        optionsFrame._frameMaxHBox:SetText(tostring(tonumber(def.maxHeight) or 0))
        optionsFrame._frameMaxHBox:SetEnabled(true)
      end
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

    if optionsFrame._frameWidthBox then optionsFrame._frameWidthBox:SetText(tostring(tonumber(def.width) or 300)) end
    if optionsFrame._frameLengthBox then
      optionsFrame._frameLengthBox:SetText(tostring(tonumber(def.maxItems) or (t == "list" and 20 or 6)))
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
    for _, c in ipairs(SafeCustomFrames()) do
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

  bgSwatch:SetScript("OnClick", function()
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

  frameHideCombat:SetScript("OnClick", function(self)
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
    SafeCall(RefreshAll)
    if RefreshFramesList then RefreshFramesList() end
  end)

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

  frameAuto:SetScript("OnClick", function(self)
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
    SafeCall(CreateAllFrames)
    SafeCall(RefreshAll)
    if RefreshFramesList then RefreshFramesList() end
  end)

  local function ApplyFrameSizeFromInputs()
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

    SafeCall(CreateAllFrames)
    SafeCall(RefreshAll)
    if RefreshFramesList then RefreshFramesList() end
  end

  widthBox:SetScript("OnEnterPressed", function(self) self:ClearFocus(); ApplyFrameSizeFromInputs() end)
  heightBox:SetScript("OnEnterPressed", function(self) self:ClearFocus(); ApplyFrameSizeFromInputs() end)
  lengthBox:SetScript("OnEnterPressed", function(self) self:ClearFocus(); ApplyFrameSizeFromInputs() end)
  maxHBox:SetScript("OnEnterPressed", function(self) self:ClearFocus(); ApplyFrameSizeFromInputs() end)

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
        row.up:SetSize(22, 20)
        row.up:SetText("▲")
        if row.up.SetNormalFontObject then row.up:SetNormalFontObject("GameFontHighlightSmall") end
        if row.up.SetHighlightFontObject then row.up:SetHighlightFontObject("GameFontHighlightSmall") end
        if row.up.SetDisabledFontObject then row.up:SetDisabledFontObject("GameFontDisableSmall") end
        row.up:SetScript("OnEnter", function(self)
          if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Move up")
            GameTooltip:Show()
          end
        end)
        row.up:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

        row.down = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.down:SetSize(22, 20)
        row.down:SetText("▼")
        if row.down.SetNormalFontObject then row.down:SetNormalFontObject("GameFontHighlightSmall") end
        if row.down.SetHighlightFontObject then row.down:SetHighlightFontObject("GameFontHighlightSmall") end
        if row.down.SetDisabledFontObject then row.down:SetDisabledFontObject("GameFontDisableSmall") end
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
        -- Keep controls inside the scroll frame's clipped region.
        row.del:SetPoint("RIGHT", -2, 0)

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
        SafeCall(RefreshAll)
        if RefreshFramesList then RefreshFramesList() end
      end)

      row.down:SetScript("OnClick", function()
        if idx >= #frames then return end
        frames[idx], frames[idx + 1] = frames[idx + 1], frames[idx]
        SafeCall(RefreshAll)
        if RefreshFramesList then RefreshFramesList() end
      end)

      row.del:SetScript("OnClick", function()
        if not (IsShiftKeyDown and IsShiftKeyDown()) then
          Print("Hold SHIFT and click X to delete a frame.")
          return
        end
        local id = tostring(frames[idx] and frames[idx].id or "")
        table.remove(frames, idx)
        if id ~= "" and type(DestroyFrameByID) == "function" then DestroyFrameByID(id) end
        SafeCall(RefreshAll)
        if RefreshFramesList then RefreshFramesList() end
        Print("Removed frame " .. (id ~= "" and id or "(unknown)") .. ".")
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
