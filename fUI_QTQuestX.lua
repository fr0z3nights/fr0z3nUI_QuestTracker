local addonName, ns = ...

ns.FQTOptionsPanels = ns.FQTOptionsPanels or {}

-- NOTE: QuestX/Y/K helper utilities live here with the QuestX UI.
local function NormalizeQuestXY(v)
  v = tostring(v or ""):upper():gsub("%s+", "")
  if v == "QUESTX" then v = "X" end
  if v == "QUESTY" then v = "Y" end
  if v == "X" or v == "Y" or v == "K" then
    return v
  end
  return nil
end

local function BuildQuestIDSet(rules, xy)
  xy = NormalizeQuestXY(xy)
  if not xy then return {} end
  if type(rules) ~= "table" then return {} end

  local out = {}
  for _, rule in ipairs(rules) do
    if type(rule) == "table" and NormalizeQuestXY(rule.questXY) == xy then
      local qid = tonumber(rule.questID)
      if qid and qid > 0 then
        out[qid] = true
      end
    end
  end
  return out
end

local function BuildKeepSet(rules)
  return BuildQuestIDSet(rules, "K")
end

function ns.FQTOptionsPanels.BuildQuestX(ctx)
  if type(ctx) ~= "table" then return end

  local panels = ctx.panels
  if not (panels and panels.questx) then return end

  local Print = ctx.Print or function(...) end
  local CreateFrame = ctx.CreateFrame or CreateFrame

  local GetUISetting = ctx.GetUISetting
  local SetUISetting = ctx.SetUISetting

  local UseModernMenuDropDown = ctx.UseModernMenuDropDown

  local GetCustomRules = ctx.GetCustomRules
  local GetCharCustomRules = ctx.GetCharCustomRules
  local DeepCopyValue = ctx.DeepCopyValue
  local GetDefaultRuleEdits = ctx.GetDefaultRuleEdits

  local GetRuleCreateExpansion = ctx.GetRuleCreateExpansion

  local CreateAllFrames = ctx.CreateAllFrames
  local RefreshAll = ctx.RefreshAll
  local RefreshRulesList = ctx.RefreshRulesList
  local RefreshXRulesList = ctx.RefreshXRulesList

  local GetKeepEditFormOpen = ctx.GetKeepEditFormOpen
  local SelectTab = ctx.SelectTab

  local HideInputBoxTemplateArt = ctx.HideInputBoxTemplateArt

  local UDDM_Initialize = ctx.UDDM_Initialize

  local p = panels.questx

  local function GetRuleStore(isAccount)
    if isAccount then
      return (type(GetCustomRules) == "function") and GetCustomRules() or {}
    end
    if type(GetCharCustomRules) == "function" then
      return GetCharCustomRules() or {}
    end
    -- Fallback: if character storage isn't available, behave like account.
    return (type(GetCustomRules) == "function") and GetCustomRules() or {}
  end

  local function GetQuestTitleSafe(qid)
    qid = tonumber(qid)
    if not qid or qid <= 0 then return nil end
    if C_QuestLog and C_QuestLog.GetTitleForQuestID then
      local ok, title = pcall(C_QuestLog.GetTitleForQuestID, qid)
      if ok and type(title) == "string" and title ~= "" then
        return title
      end
    end
    return nil
  end

  local function GetCurrentMapIDSafe()
    if C_Map and C_Map.GetBestMapForUnit then
      local ok, id = pcall(C_Map.GetBestMapForUnit, "player")
      if ok and type(id) == "number" and id > 0 then
        return id
      end
    end
    return nil
  end

  local function NormalizeScopeMode(v)
    v = tostring(v or ""):upper():gsub("%s+", "")
    if v ~= "MAP" and v ~= "RESTING" then
      v = "RESTING"
    end
    return v
  end

  local btnMode = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
  btnMode:SetHeight(18)
  btnMode:SetPoint("TOPLEFT", 12, -40)
  btnMode:SetText("XQuest")
  p._modeBtn = btnMode

  local modeHelp = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  modeHelp:SetPoint("LEFT", btnMode, "RIGHT", 10, 0)
  modeHelp:SetText("Mode")

  do
    local xy = tostring(p._questXY or ""):upper():gsub("%s+", "")
    if xy ~= "Y" and xy ~= "K" then xy = "X" end
    p._questXY = xy
  end

  local function GetModeLabel(xy)
    xy = tostring(xy or "X"):upper():gsub("%s+", "")
    if xy == "Y" then return "Auto Accept Quest" end
    if xy == "K" then return "Abandon Quests Keep List" end
    return "Auto Abandon Quest"
  end

  local function GetModeShort(xy)
    xy = tostring(xy or "X"):upper():gsub("%s+", "")
    if xy == "Y" then return "QuestY" end
    if xy == "K" then return "Keep" end
    return "XQuest"
  end

  function p:_syncModeUI()
    local xy = tostring(self._questXY or "X"):upper():gsub("%s+", "")
    if xy ~= "Y" and xy ~= "K" then xy = "X" end
    self._questXY = xy
    local isX = (xy == "X")
    if self._modeBtn and self._modeBtn.SetText then
      self._modeBtn:SetText(GetModeLabel(xy))
    end

    do
      local fs = (self._modeBtn and self._modeBtn.GetFontString and self._modeBtn:GetFontString()) or nil
      local w = (fs and fs.GetStringWidth and fs:GetStringWidth()) or 0
      w = (tonumber(w) or 0) + 24
      if w < 70 then w = 70 end
      if self._modeBtn and self._modeBtn.SetSize then
        self._modeBtn:SetSize(w, 18)
      end
    end

    if self._scopeBtn and self._scopeBtn.SetShown then
      self._scopeBtn:SetShown(isX)
    end

    if self._syncScopeUI then
      pcall(self._syncScopeUI, self)
    end

    -- When editing (opened from Rules tab), allow saving via the Account button.
    local isEditing = (self._editingCustomIndex or self._editingDefaultKey or self._editingDefaultBase) and true or false
    if self._addQuestXBtnAcc and self._addQuestXBtnAcc.SetText then
      self._addQuestXBtnAcc:SetText(isEditing and "Save" or "Add to Account")
    end
    if self._addQuestXBtnChar and self._addQuestXBtnChar.SetShown then
      self._addQuestXBtnChar:SetShown(not isEditing)
    end

    if self._runKeepAbandonBtn and self._runKeepAbandonBtn.SetShown then
      self._runKeepAbandonBtn:SetShown((xy == "K") and (not isEditing))
    end
  end
  p._syncModeUI = p._syncModeUI
  p:_syncModeUI()

  btnMode:SetScript("OnClick", function()
    local cur = tostring(p._questXY or "X"):upper():gsub("%s+", "")
    local nextMode
    if cur == "X" then
      nextMode = "Y"
    elseif cur == "Y" then
      nextMode = "K"
    else
      nextMode = "X"
    end
    p._questXY = nextMode
    p:_syncModeUI()
  end)

  local scopeBtn = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
  scopeBtn:SetSize(90, 22)
  scopeBtn:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 12, 12)
  p._scopeBtn = scopeBtn
  if scopeBtn.SetShown then scopeBtn:SetShown(p._questXY == "X") end

  p._questXScopeMode = NormalizeScopeMode((type(GetUISetting) == "function" and GetUISetting("questxScopeMode", "RESTING")) or "RESTING")

  local function UpdateScopeButton()
    local mode = NormalizeScopeMode(p._questXScopeMode)
    p._questXScopeMode = mode
    if scopeBtn and scopeBtn.SetText then
      scopeBtn:SetText(mode)
    end
  end

  p._updateScopeButton = function()
    UpdateScopeButton()
  end

  scopeBtn:SetScript("OnClick", function()
    local cur = NormalizeScopeMode(p._questXScopeMode)
    local nextMode = (cur == "MAP") and "RESTING" or "MAP"
    p._questXScopeMode = nextMode
    if type(SetUISetting) == "function" then
      SetUISetting("questxScopeMode", nextMode)
    end
    UpdateScopeButton()
    if p and p._syncScopeUI then
      pcall(p._syncScopeUI, p)
    end
  end)

  scopeBtn:SetScript("OnEnter", function()
    if not GameTooltip then return end
    GameTooltip:SetOwner(p, "ANCHOR_NONE")
    GameTooltip:ClearAllPoints()
    GameTooltip:SetPoint("BOTTOM", scopeBtn, "TOP", 0, 8)
    GameTooltip:SetText("Auto-Abandon Scope")
    if NormalizeScopeMode(p._questXScopeMode) == "MAP" then
      GameTooltip:AddLine("MAP: rule is gated to LocationID (uiMapID)", 1, 1, 1, true)
    else
      GameTooltip:AddLine("RESTING: rule runs only in rested areas", 1, 1, 1, true)
    end
    GameTooltip:Show()
  end)
  scopeBtn:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

  UpdateScopeButton()

  -- Now that scope controls exist, ensure mode-dependent visibility is correct.
  if p and p._syncModeUI then pcall(p._syncModeUI, p) end

  local questIDBox = CreateFrame("EditBox", nil, p, "InputBoxTemplate")
  questIDBox:SetSize(175, 38)
  questIDBox:SetPoint("TOP", p, "TOP", 0, -72)
  questIDBox:SetAutoFocus(false)
  questIDBox:SetMaxLetters(10)
  questIDBox:SetTextInsets(6, 6, 0, 0)
  questIDBox:SetJustifyH("CENTER")
  if questIDBox.SetJustifyV then questIDBox:SetJustifyV("MIDDLE") end
  if questIDBox.SetNumeric then questIDBox:SetNumeric(true) end
  questIDBox:SetText("0")
  if HideInputBoxTemplateArt then HideInputBoxTemplateArt(questIDBox) end
  if questIDBox.GetFont and questIDBox.SetFont then
    local fontPath, _, fontFlags = questIDBox:GetFont()
    if fontPath then questIDBox:SetFont(fontPath, 16, fontFlags) end
  end

  local ph = p:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  ph:SetPoint("CENTER", questIDBox, "CENTER", 0, 0)
  ph:SetText("Enter QuestID")
  ph:SetTextColor(1, 1, 1, 0.35)
  p._questIDPlaceholder = ph

  local function UpdateQuestIDPlaceholder()
    if not (questIDBox and ph) then return end
    local txt = tostring(questIDBox:GetText() or "")
    local hasText = (txt ~= "" and txt ~= "0")
    local focused = (questIDBox.HasFocus and questIDBox:HasFocus()) and true or false
    ph:SetShown((not hasText) and (not focused))
  end

  local questName = p:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  questName:SetPoint("TOP", questIDBox, "BOTTOM", 0, -6)
  questName:SetJustifyH("CENTER")
  questName:SetWidth(520)
  questName:SetWordWrap(true)
  questName:SetText("")
  p._questNameLabel = questName

  local function SyncQuestName()
    if not (questName and questName.SetText and questIDBox) then return end
    local qid = tonumber(questIDBox:GetText() or "")
    local title = GetQuestTitleSafe(qid)
    if title then
      questName:SetText(title)
    else
      questName:SetText("")
    end
  end

  questIDBox:SetScript("OnEditFocusGained", function()
    UpdateQuestIDPlaceholder()
  end)
  questIDBox:SetScript("OnEditFocusLost", function()
    UpdateQuestIDPlaceholder()
  end)
  questIDBox:SetScript("OnTextChanged", function()
    UpdateQuestIDPlaceholder()
    SyncQuestName()
  end)
  questIDBox:SetScript("OnShow", function()
    UpdateQuestIDPlaceholder()
    SyncQuestName()
  end)

  function p:_syncScopeUI()
    -- Original FQX did not expose LocationID; scope is handled implicitly.
    -- Keep this hook so other parts can safely call it.
  end

  -- Action buttons (like original FQX): Add to Character / Add to Account.
  local btnChar = CreateFrame("Button", nil, p, "GameMenuButtonTemplate")
  btnChar:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 12, 42)
  btnChar:SetSize(135, 25)
  btnChar:SetText("Add to Character")

  local btnAcc = CreateFrame("Button", nil, p, "GameMenuButtonTemplate")
  btnAcc:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -12, 42)
  btnAcc:SetSize(135, 25)
  btnAcc:SetText("Add to Account")

  local runKeepAbandonBtn = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
  runKeepAbandonBtn:SetSize(170, 22)
  runKeepAbandonBtn:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -12, 12)
  runKeepAbandonBtn:SetText("Abandon (Keep List)")
  runKeepAbandonBtn:Hide()

  runKeepAbandonBtn:SetScript("OnClick", function()
    if type(ns.RunQuestXKeepListAbandon) == "function" then
      ns.RunQuestXKeepListAbandon()
    else
      Print("Keep List abandon is unavailable.")
    end
  end)

  runKeepAbandonBtn:SetScript("OnEnter", function()
    if not GameTooltip then return end
    GameTooltip:SetOwner(p, "ANCHOR_NONE")
    GameTooltip:ClearAllPoints()
    GameTooltip:SetPoint("BOTTOM", runKeepAbandonBtn, "TOP", 0, 8)
    GameTooltip:SetText("Keep List")
    GameTooltip:AddLine("Manually abandons all quests except QuestIDs in the Keep List.", 1, 1, 1, true)
    GameTooltip:AddLine("Confirmation appears for 2+ quests (hold SHIFT to bypass).", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  runKeepAbandonBtn:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

  local cancelBtn = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
  cancelBtn:SetSize(120, 22)
  cancelBtn:SetPoint("BOTTOM", p, "BOTTOM", 0, 12)
  cancelBtn:SetText("Cancel Edit")
  cancelBtn:Hide()

  p._questIDBox = questIDBox
  p._titleBox = nil
  p._locBox = nil
  p._addQuestXBtn = nil
  p._addQuestXBtnChar = btnChar
  p._addQuestXBtnAcc = btnAcc
  p._runKeepAbandonBtn = runKeepAbandonBtn
  p._cancelEditBtn = cancelBtn

  local function ClearInputs()
    if questIDBox then questIDBox:SetText("0") end

    -- Preserve the selected mode; original FQX did not force-reset.

    UpdateQuestIDPlaceholder()
    SyncQuestName()
    p:_syncScopeUI()
  end

  local function AddOrSaveRule(isAccount)
    local questID = tonumber(questIDBox:GetText() or "")
    if not questID or questID <= 0 then
      Print("Enter a questID > 0.")
      return
    end

    local questXY = tostring(p._questXY or "X"):upper():gsub("%s+", "")
    if questXY ~= "Y" and questXY ~= "K" then questXY = "X" end

    local ruleTitle = nil
    local locationID = nil

    local restedOnly = nil
    do
      if questXY == "X" then
        local scopeMode = NormalizeScopeMode(p._questXScopeMode)
        if scopeMode == "RESTING" then
          restedOnly = true
          locationID = nil
        else
          restedOnly = nil
          if locationID == nil then
            local mapID = GetCurrentMapIDSafe()
            if mapID then
              locationID = tostring(mapID)
            end
          end
        end
      else
        -- QuestY and Keep List entries are always global (no location/resting gate)
        locationID = nil
        restedOnly = nil
      end
    end

    local hideWhenCompleted = (questXY == "K") and false or true

    local expID, expName = nil, nil
    if type(GetRuleCreateExpansion) == "function" then
      expID, expName = GetRuleCreateExpansion()
    end
    expID = tonumber(expID)
    if expName == "Custom" then expName = nil; expID = nil end

    local isEditingAny = (p._editingCustomIndex or p._editingDefaultKey or p._editingDefaultBase) and true or false
    local rules
    if isEditingAny then
      if p._editingCustomIndex and p._editingCustomIsChar and type(GetCharCustomRules) == "function" then
        rules = GetCharCustomRules() or {}
      else
        rules = (type(GetCustomRules) == "function" and GetCustomRules()) or {}
      end
    else
      rules = GetRuleStore(isAccount)
    end

    if p._editingCustomIndex and type(rules[p._editingCustomIndex]) == "table" then
      local rule = rules[p._editingCustomIndex]
      rule.questID = questID
      rule.questXY = questXY
      rule.frameID = nil
      rule.targets = nil
      rule.display = nil
      rule.label = ruleTitle
      rule.locationID = locationID
      rule.restedOnly = restedOnly
      rule._expansionID = expID
      rule._expansionName = expName
      rule.hideWhenCompleted = hideWhenCompleted

      p._editingCustomIndex = nil
      p._editingCustomIsChar = nil
      p._editingDefaultBase = nil
      p._editingDefaultKey = nil
      p:_syncModeUI()
      cancelBtn:Hide()
      Print("Saved XQuest/YQuest rule.")
    elseif p._editingDefaultBase and p._editingDefaultKey and type(GetDefaultRuleEdits) == "function" then
      local edits = GetDefaultRuleEdits()
      local base = p._editingDefaultBase
      local key = tostring(p._editingDefaultKey)
      local effective = (type(edits[key]) == "table") and edits[key] or base
      local rule = DeepCopyValue(effective)

      rule.questID = questID
      rule.questXY = questXY
      rule.frameID = nil
      rule.targets = nil
      rule.display = nil
      rule.label = ruleTitle
      rule.locationID = locationID
      rule.restedOnly = restedOnly
      rule._expansionID = expID
      rule._expansionName = expName
      rule.hideWhenCompleted = hideWhenCompleted

      if base and base.key ~= nil then rule.key = tostring(base.key) end
      edits[key] = rule

      p._editingCustomIndex = nil
      p._editingCustomIsChar = nil
      p._editingDefaultBase = nil
      p._editingDefaultKey = nil
      p:_syncModeUI()
      cancelBtn:Hide()
      Print("Saved default XQuest/YQuest rule edit.")
    else
      local key = (type(ns) == "table" and type(ns.MakeUniqueRuleKey) == "function") and ns.MakeUniqueRuleKey("custom") or string.format("custom:qxy:%s:%d:%d", tostring(questXY), questID, (#rules + 1))

      rules[#rules + 1] = {
        key = key,
        questID = questID,
        questXY = questXY,
        frameID = nil,
        label = ruleTitle,
        locationID = locationID,
        restedOnly = restedOnly,
        display = nil,
        _expansionID = expID,
        _expansionName = expName,
        hideWhenCompleted = hideWhenCompleted,
      }

      Print(string.format("Added %s for quest %d", GetModeLabel(questXY), questID))
    end

    if RefreshAll then RefreshAll() end
    if RefreshRulesList then RefreshRulesList() end
    if RefreshXRulesList then RefreshXRulesList() end

    ClearInputs()
  end

  btnAcc:SetScript("OnClick", function() AddOrSaveRule(true) end)
  btnChar:SetScript("OnClick", function() AddOrSaveRule(false) end)

  cancelBtn:SetScript("OnClick", function()
    p._editingCustomIndex = nil
    p._editingCustomIsChar = nil
    p._editingDefaultBase = nil
    p._editingDefaultKey = nil
    p:_syncModeUI()
    cancelBtn:Hide()

    if not GetKeepEditFormOpen() then
      ClearInputs()
      if SelectTab then SelectTab("xrules") end
    end
  end)
end
