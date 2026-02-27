local addonName, ns = ...

ns.FQTOptionsPanels = ns.FQTOptionsPanels or {}

function ns.FQTOptionsPanels.BuildQuestX(ctx)
  if type(ctx) ~= "table" then return end

  local panels = ctx.panels
  if not (panels and panels.questx) then return end

  local Print = ctx.Print or function(...) end
  local CreateFrame = ctx.CreateFrame or CreateFrame

  local UseModernMenuDropDown = ctx.UseModernMenuDropDown
  local GetEffectiveFrames = ctx.GetEffectiveFrames
  local GetFrameDisplayNameByID = ctx.GetFrameDisplayNameByID

  local GetCustomRules = ctx.GetCustomRules
  local DeepCopyValue = ctx.DeepCopyValue
  local GetDefaultRuleEdits = ctx.GetDefaultRuleEdits

  local GetRuleCreateExpansion = ctx.GetRuleCreateExpansion

  local CreateAllFrames = ctx.CreateAllFrames
  local RefreshAll = ctx.RefreshAll
  local RefreshRulesList = ctx.RefreshRulesList

  local GetKeepEditFormOpen = ctx.GetKeepEditFormOpen
  local SelectTab = ctx.SelectTab

  local AddPlaceholder = ctx.AddPlaceholder
  local HideInputBoxTemplateArt = ctx.HideInputBoxTemplateArt
  local HideDropDownMenuArt = ctx.HideDropDownMenuArt
  local AttachLocationIDTooltip = ctx.AttachLocationIDTooltip

  local UDDM_SetWidth = ctx.UDDM_SetWidth
  local UDDM_SetText = ctx.UDDM_SetText
  local UDDM_Initialize = ctx.UDDM_Initialize
  local UDDM_CreateInfo = ctx.UDDM_CreateInfo
  local UDDM_AddButton = ctx.UDDM_AddButton

  local p = panels.questx

  local title = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", 12, -40)
  title:SetText("QuestX")
  if title.Hide then title:Hide() end

  local btnMode = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
  btnMode:SetSize(90, 20)
  btnMode:SetPoint("TOPLEFT", 12, -40)
  btnMode:SetText("QuestX")
  p._modeBtn = btnMode

  local modeHelp = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  modeHelp:SetPoint("LEFT", btnMode, "RIGHT", 10, 0)
  modeHelp:SetText("Mode")
  if modeHelp.Hide then modeHelp:Hide() end

  p._questXY = (p._questXY == "Y") and "Y" or "X"

  function p:_syncModeUI()
    local isX = (self._questXY ~= "Y")
    if self._modeBtn and self._modeBtn.SetText then
      self._modeBtn:SetText(isX and "QuestX" or "QuestY")
    end
  end
  p._syncModeUI = p._syncModeUI
  p:_syncModeUI()

  btnMode:SetScript("OnClick", function()
    p._questXY = (p._questXY == "Y") and "X" or "Y"
    p:_syncModeUI()
  end)

  local qidLabel = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  qidLabel:SetPoint("TOPLEFT", 12, -70)
  qidLabel:SetText("QuestID")
  qidLabel:SetText("")
  if qidLabel.Hide then qidLabel:Hide() end

  local questIDBox = CreateFrame("EditBox", nil, p, "InputBoxTemplate")
  questIDBox:SetSize(90, 20)
  questIDBox:SetPoint("TOPLEFT", 12, -86)
  questIDBox:SetAutoFocus(false)
  questIDBox:SetNumeric(true)
  questIDBox:SetText("0")
  if AddPlaceholder then AddPlaceholder(questIDBox, "QuestID") end
  if HideInputBoxTemplateArt then HideInputBoxTemplateArt(questIDBox) end

  local tLabel = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  tLabel:SetPoint("TOPLEFT", 110, -70)
  tLabel:SetText("Title (optional)")
  tLabel:SetText("")
  if tLabel.Hide then tLabel:Hide() end

  local titleBox = CreateFrame("EditBox", nil, p, "InputBoxTemplate")
  titleBox:SetSize(220, 20)
  titleBox:SetPoint("TOPLEFT", 110, -86)
  titleBox:SetAutoFocus(false)
  titleBox:SetText("")
  if AddPlaceholder then AddPlaceholder(titleBox, "Custom title (leave blank for quest name)") end
  if HideInputBoxTemplateArt then HideInputBoxTemplateArt(titleBox) end

  local locLabel = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  locLabel:SetPoint("TOPLEFT", 12, -116)
  locLabel:SetText("LocationID (uiMapID)")
  locLabel:SetText("")
  if locLabel.Hide then locLabel:Hide() end

  local locBox = CreateFrame("EditBox", nil, p, "InputBoxTemplate")
  locBox:SetSize(140, 20)
  locBox:SetPoint("TOPLEFT", 12, -132)
  locBox:SetAutoFocus(false)
  locBox:SetNumeric(true)
  locBox:SetText("0")
  if AddPlaceholder then AddPlaceholder(locBox, "uiMapID (optional)") end
  if HideInputBoxTemplateArt then HideInputBoxTemplateArt(locBox) end
  if AttachLocationIDTooltip then AttachLocationIDTooltip(locBox) end

  local frameLabel = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  frameLabel:SetPoint("TOPLEFT", 180, -116)
  frameLabel:SetText("List")
  frameLabel:SetText("")
  if frameLabel.Hide then frameLabel:Hide() end

  local frameDrop = CreateFrame("Frame", nil, p, "UIDropDownMenuTemplate")
  frameDrop:SetPoint("TOPLEFT", 170, -132)
  if UDDM_SetWidth then UDDM_SetWidth(frameDrop, 180) end
  if UDDM_SetText then UDDM_SetText(frameDrop, "List") end
  if HideDropDownMenuArt then HideDropDownMenuArt(frameDrop) end

  p._questFrameDrop = frameDrop

  local function GetListFrameChoices()
    local out = {}
    local defs = (type(GetEffectiveFrames) == "function" and GetEffectiveFrames()) or {}
    if type(defs) == "table" then
      for _, def in ipairs(defs) do
        if type(def) == "table" and tostring(def.type or "list") ~= "bar" then
          local id = tostring(def.id or "")
          if id ~= "" then
            out[#out + 1] = { id = id, label = (type(GetFrameDisplayNameByID) == "function" and GetFrameDisplayNameByID(id)) or id }
          end
        end
      end
    end
    table.sort(out, function(a, b)
      return tostring(a.label or a.id or "") < tostring(b.label or b.id or "")
    end)
    if out[1] == nil then
      out[1] = { id = "list1", label = "list1" }
    end
    return out
  end

  function p:_syncFrameDrop()
    local id = tostring(self._questTargetFrameID or "list1")
    if UDDM_SetText and frameDrop then
      UDDM_SetText(frameDrop, (type(GetFrameDisplayNameByID) == "function" and GetFrameDisplayNameByID(id)) or id)
    end
    if self._questFrameFallbackBox then
      self._questFrameFallbackBox:SetText(id)
    end
  end

  do
    local okModern = false
    if type(UseModernMenuDropDown) == "function" then
      okModern = UseModernMenuDropDown(frameDrop, function(root)
        local choices = GetListFrameChoices()
        for _, opt in ipairs(choices) do
          root:CreateButton(tostring(opt.label), function()
            p._questTargetFrameID = tostring(opt.id)
            p:_syncFrameDrop()
          end)
        end
      end)
    end

    if not okModern and type(UDDM_Initialize) == "function" and type(UDDM_CreateInfo) == "function" and type(UDDM_AddButton) == "function" then
      UDDM_Initialize(frameDrop, function()
        local choices = GetListFrameChoices()
        for _, opt in ipairs(choices) do
          local info = UDDM_CreateInfo()
          info.text = tostring(opt.label)
          info.func = function()
            p._questTargetFrameID = tostring(opt.id)
            p:_syncFrameDrop()
          end
          UDDM_AddButton(info)
        end
      end)
    end
  end

  local fb = CreateFrame("EditBox", nil, p, "InputBoxTemplate")
  fb:SetSize(90, 18)
  fb:SetPoint("LEFT", frameDrop, "RIGHT", 0, 2)
  fb:SetAutoFocus(false)
  fb:SetText("list1")
  fb:SetScript("OnEnterPressed", function(self)
    local v = tostring(self:GetText() or ""):gsub("%s+", "")
    if v == "" then v = "list1" end
    p._questTargetFrameID = v
    p:_syncFrameDrop()
    self:ClearFocus()
  end)
  if HideInputBoxTemplateArt then HideInputBoxTemplateArt(fb) end
  p._questFrameFallbackBox = fb
  frameDrop:Hide()

  p._questTargetFrameID = p._questTargetFrameID or "list1"
  p:_syncFrameDrop()

  local addBtn = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
  addBtn:SetSize(160, 22)
  addBtn:SetPoint("TOPLEFT", 12, -190)
  addBtn:SetText("Add QuestX/Y Rule")

  local cancelBtn = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
  cancelBtn:SetSize(120, 22)
  cancelBtn:SetPoint("LEFT", addBtn, "RIGHT", 8, 0)
  cancelBtn:SetText("Cancel Edit")
  cancelBtn:Hide()

  p._questIDBox = questIDBox
  p._titleBox = titleBox
  p._locBox = locBox
  p._addQuestXBtn = addBtn
  p._cancelEditBtn = cancelBtn

  local function ClearInputs()
    if questIDBox then questIDBox:SetText("0") end
    if titleBox then titleBox:SetText("") end
    if locBox then locBox:SetText("0") end

    p._questXY = "X"
    p:_syncModeUI()

    p._questTargetFrameID = "list1"
    p:_syncFrameDrop()
  end

  local function ReadTargetFrameID()
    local v = p._questTargetFrameID
    if v ~= nil then
      local tf = tostring(v):gsub("%s+", "")
      if tf ~= "" then return tf end
    end
    if fb then
      local tf = tostring(fb:GetText() or ""):gsub("%s+", "")
      if tf ~= "" then return tf end
    end
    return "list1"
  end

  addBtn:SetScript("OnClick", function()
    local questID = tonumber(questIDBox:GetText() or "")
    if not questID or questID <= 0 then
      Print("Enter a questID > 0.")
      return
    end

    local questXY = (p._questXY == "Y") and "Y" or "X"
    local targetFrame = ReadTargetFrameID()

    local titleText = tostring(titleBox:GetText() or "")
    titleText = titleText:gsub("^%s+", ""):gsub("%s+$", "")
    local ruleTitle = (titleText ~= "") and titleText or nil

    local locText = tostring(locBox:GetText() or "")
    locText = locText:gsub("%s+", "")
    local locationID = (locText ~= "" and locText ~= "0") and locText or nil

    local expID, expName = nil, nil
    if type(GetRuleCreateExpansion) == "function" then
      expID, expName = GetRuleCreateExpansion()
    end
    expID = tonumber(expID)
    if expName == "Custom" then expName = nil; expID = nil end

    local rules = GetCustomRules()

    if p._editingCustomIndex and type(rules[p._editingCustomIndex]) == "table" then
      local rule = rules[p._editingCustomIndex]
      rule.questID = questID
      rule.questXY = questXY
      rule.frameID = targetFrame
      rule.label = ruleTitle
      rule.locationID = locationID
      rule._expansionID = expID
      rule._expansionName = expName
      if rule.hideWhenCompleted == nil then rule.hideWhenCompleted = true end

      p._editingCustomIndex = nil
      p._editingDefaultBase = nil
      p._editingDefaultKey = nil
      addBtn:SetText("Add QuestX/Y Rule")
      cancelBtn:Hide()
      Print("Saved QuestX/Y rule.")
    elseif p._editingDefaultBase and p._editingDefaultKey and type(GetDefaultRuleEdits) == "function" then
      local edits = GetDefaultRuleEdits()
      local base = p._editingDefaultBase
      local key = tostring(p._editingDefaultKey)
      local effective = (type(edits[key]) == "table") and edits[key] or base
      local rule = DeepCopyValue(effective)

      rule.questID = questID
      rule.questXY = questXY
      rule.frameID = targetFrame
      rule.label = ruleTitle
      rule.locationID = locationID
      rule._expansionID = expID
      rule._expansionName = expName
      if rule.hideWhenCompleted == nil then rule.hideWhenCompleted = true end

      if base and base.key ~= nil then rule.key = tostring(base.key) end
      edits[key] = rule

      p._editingCustomIndex = nil
      p._editingDefaultBase = nil
      p._editingDefaultKey = nil
      addBtn:SetText("Add QuestX/Y Rule")
      cancelBtn:Hide()
      Print("Saved default QuestX/Y rule edit.")
    else
      local targetFrameKey = tostring(targetFrame or "list1")
      local key = string.format("custom:qxy:%s:%d:%s:%d", tostring(questXY), questID, targetFrameKey, (#rules + 1))

      rules[#rules + 1] = {
        key = key,
        questID = questID,
        questXY = questXY,
        frameID = targetFrame,
        label = ruleTitle,
        locationID = locationID,
        display = "list",
        _expansionID = expID,
        _expansionName = expName,
        hideWhenCompleted = true,
      }

      Print(string.format("Added %s rule for quest %d -> %s", (questXY == "Y") and "QuestY" or "QuestX", questID, tostring(targetFrame)))
    end

    if CreateAllFrames then CreateAllFrames() end
    if RefreshAll then RefreshAll() end
    if RefreshRulesList then RefreshRulesList() end

    if not GetKeepEditFormOpen() then
      ClearInputs()
      if SelectTab then SelectTab("rules") end
    end
  end)

  cancelBtn:SetScript("OnClick", function()
    p._editingCustomIndex = nil
    p._editingDefaultBase = nil
    p._editingDefaultKey = nil
    addBtn:SetText("Add QuestX/Y Rule")
    cancelBtn:Hide()

    if not GetKeepEditFormOpen() then
      ClearInputs()
      if SelectTab then SelectTab("rules") end
    end
  end)
end
