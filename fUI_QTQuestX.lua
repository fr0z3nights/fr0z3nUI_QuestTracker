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

  -- Main mode button (QuestX/QuestY/Keep) styled like LootIt's Trade tab mode selector
  local btnMode = CreateFrame("Button", nil, p)
  btnMode:SetSize(320, 28)
  -- Place below the options tab row (avoid overlapping the tabs/header area)
  btnMode:SetPoint("TOP", p, "TOP", 0, -48)

  local btnModeText = btnMode:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  btnModeText:SetPoint("CENTER", btnMode, "CENTER", 0, 0)

  local function SetFontStringSize(fs, size)
    if not (fs and fs.GetFont and fs.SetFont) then return end
    local font, _, flags = fs:GetFont()
    if type(font) ~= "string" or font == "" then
      font = "Fonts\\FRIZQT__.TTF"
    end
    fs:SetFont(font, size, flags)
  end

  SetFontStringSize(btnModeText, 18)

  p._modeBtn = btnMode
  p._modeBtnText = btnModeText

  do
    local xy = tostring(p._questXY or ""):upper():gsub("%s+", "")
    if xy ~= "Y" and xy ~= "K" then xy = "X" end
    p._questXY = xy
  end

  local function GetModeLabel(xy)
    xy = tostring(xy or "X"):upper():gsub("%s+", "")
    if xy == "Y" then return "Auto Accept Quest" end
    if xy == "K" then return "Abandon All Quests" end
    return "Auto Abandon Quest"
  end

  local function RefreshModeButton()
    local xy = tostring(p._questXY or "X"):upper():gsub("%s+", "")
    if xy ~= "Y" and xy ~= "K" then xy = "X" end
    btnModeText:SetText(GetModeLabel(xy))
    if btnModeText and btnModeText.SetTextColor then
      if xy == "K" then
        btnModeText:SetTextColor(0.85, 0.85, 0.85, 1)
      else
        btnModeText:SetTextColor(1.0, 0.82, 0.0, 1)
      end
    end
  end

  function p:_syncModeUI()
    local xy = tostring(self._questXY or "X"):upper():gsub("%s+", "")
    if xy ~= "Y" and xy ~= "K" then xy = "X" end
    self._questXY = xy
    if self._modeBtnText and self._modeBtnText.SetText then
      self._modeBtnText:SetText(GetModeLabel(xy))
      RefreshModeButton()
    end

    -- Update QuestID placeholder (ghost text) per mode.
    if self._questIDPlaceholder and self._questIDPlaceholder.SetText then
      if xy == "K" then
        self._questIDPlaceholder:SetText("Enter QuestID to Exclude")
      elseif xy == "Y" then
        self._questIDPlaceholder:SetText("Enter QuestID to Accept")
      else
        self._questIDPlaceholder:SetText("Enter QuestID to Abandon")
      end
    end
    if self._questIDPlaceholder and self._questIDBox and self._questIDPlaceholder.SetShown then
      local txt = tostring(self._questIDBox.GetText and self._questIDBox:GetText() or "")
      local hasText = (txt ~= "")
      local focused = (self._questIDBox.HasFocus and self._questIDBox:HasFocus()) and true or false
      self._questIDPlaceholder:SetShown((not hasText) and (not focused))
    end

    if self._scopeBtn and self._scopeBtn.SetShown then
      -- Keep visible for consistent layout; only applies to Auto Abandon.
      self._scopeBtn:SetShown(true)
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
      -- Visible on all modes; hidden while editing.
      self._runKeepAbandonBtn:SetShown((not isEditing))
    end

    if self._updateScopeButtons then
      pcall(self._updateScopeButtons)
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

  btnMode:SetScript("OnEnter", function(self)
    if btnModeText and btnModeText.SetTextColor then
      btnModeText:SetTextColor(1, 1, 1, 1)
    end
    if not (GameTooltip and GameTooltip.SetOwner and GameTooltip.SetText) then return end
    GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
    GameTooltip:SetText("Click to Change")
    GameTooltip:Show()
  end)
  btnMode:SetScript("OnLeave", function()
    if GameTooltip and GameTooltip.Hide then GameTooltip:Hide() end
    RefreshModeButton()
  end)

  -- MAP/RESTING toggle (only for Auto Abandon). Keep it, but keep it out of the main layout.
  local scopeBtn = CreateFrame("Button", nil, p)
  scopeBtn:SetSize(90, 22)
  scopeBtn:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 12, 12)
  p._scopeBtn = scopeBtn

  local scopeBtnText = scopeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  scopeBtnText:SetPoint("CENTER", scopeBtn, "CENTER", 0, 0)
  SetFontStringSize(scopeBtnText, 14)
  p._scopeBtnText = scopeBtnText

  if scopeBtn.SetShown then scopeBtn:SetShown(p._questXY == "X") end

  p._questXScopeMode = NormalizeScopeMode((type(GetUISetting) == "function" and GetUISetting("questxScopeMode", "RESTING")) or "RESTING")

  local function UpdateScopeButton()
    local mode = NormalizeScopeMode(p._questXScopeMode)
    p._questXScopeMode = mode
    if scopeBtnText and scopeBtnText.SetText then scopeBtnText:SetText(mode) end
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
    GameTooltip:SetOwner(scopeBtn, "ANCHOR_CURSOR")
    GameTooltip:SetText("Auto-Abandon Scope")
    GameTooltip:AddLine("(Applies to Auto Abandon only)", 0.85, 0.85, 0.85, true)
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
  questIDBox:SetPoint("TOP", btnMode, "BOTTOM", 0, -18)
  questIDBox:SetAutoFocus(false)
  questIDBox:SetMaxLetters(10)
  questIDBox:SetTextInsets(6, 6, 0, 0)
  questIDBox:SetJustifyH("CENTER")
  if questIDBox.SetJustifyV then questIDBox:SetJustifyV("MIDDLE") end
  if questIDBox.SetNumeric then questIDBox:SetNumeric(true) end
  questIDBox:SetText("")
  if HideInputBoxTemplateArt then HideInputBoxTemplateArt(questIDBox) end
  if questIDBox.GetFont and questIDBox.SetFont then
    local fontPath, _, fontFlags = questIDBox:GetFont()
    if fontPath then questIDBox:SetFont(fontPath, 18, fontFlags) end
  end

  local ph = p:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  ph:SetPoint("CENTER", questIDBox, "CENTER", 0, 0)
  ph:SetText("Enter QuestID to Abandon")
  ph:SetTextColor(1, 1, 1, 0.35)
  p._questIDPlaceholder = ph

  local function UpdateQuestIDPlaceholder()
    if not (questIDBox and ph) then return end
    local txt = tostring(questIDBox:GetText() or "")
    local hasText = (txt ~= "")
    local focused = (questIDBox.HasFocus and questIDBox:HasFocus()) and true or false
    ph:SetShown((not hasText) and (not focused))
  end

  local questName = p:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  questName:SetPoint("TOP", questIDBox, "BOTTOM", 0, -6)
  questName:SetJustifyH("CENTER")
  questName:SetWidth(520)
  questName:SetWordWrap(true)
  SetFontStringSize(questName, 16)
  -- Keep a fixed title area so the Character/Account buttons don't shift
  -- when a long quest title wraps to additional lines.
  questName:SetHeight(42)
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

  -- Action buttons (LootIt Trade-style row): Character / Account.
  local BTN_W, BTN_H = 110, 22
  local BTN_GAP = 12
  local ROW_TOP_PAD = 14

  local btnChar = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
  btnChar:SetSize(BTN_W, BTN_H)
  btnChar:SetPoint("TOP", questName, "BOTTOM", -((BTN_W / 2) + (BTN_GAP / 2)), -ROW_TOP_PAD)
  btnChar:SetText("Character")
  if btnChar.RegisterForClicks then btnChar:RegisterForClicks("LeftButtonUp", "RightButtonUp") end

  local btnAcc = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
  btnAcc:SetSize(BTN_W, BTN_H)
  btnAcc:SetPoint("TOP", questName, "BOTTOM", ((BTN_W / 2) + (BTN_GAP / 2)), -ROW_TOP_PAD)
  btnAcc:SetText("Account")
  if btnAcc.RegisterForClicks then btnAcc:RegisterForClicks("LeftButtonUp", "RightButtonUp") end

  -- Move MAP/RESTING scope next to Character.
  if scopeBtn and scopeBtn.ClearAllPoints and scopeBtn.SetPoint then
    scopeBtn:ClearAllPoints()
    scopeBtn:SetPoint("RIGHT", btnChar, "LEFT", -12, 0)
  end

  -- Completed toggle (skip completed quests during Abandon All)
  local completedBtn = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
  completedBtn:SetSize(110, 22)
  completedBtn:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 12, 12)
  p._completedBtn = completedBtn

  local function GetSkipCompletedSetting()
    return (type(GetUISetting) == "function") and (GetUISetting("keepAbandonSkipCompleted", true) == true) or false
  end

  local function SetSkipCompletedSetting(v)
    if type(SetUISetting) == "function" then
      SetUISetting("keepAbandonSkipCompleted", v == true)
    end
  end

  local function UpdateCompletedButton()
    local on = GetSkipCompletedSetting()
    if on then
      completedBtn:SetText("|cffffd100Completed|r")
    else
      completedBtn:SetText("|cff999999Completed|r")
    end
  end

  completedBtn:SetScript("OnClick", function()
    SetSkipCompletedSetting(not GetSkipCompletedSetting())
    UpdateCompletedButton()
  end)

  completedBtn:SetScript("OnEnter", function(self)
    if not GameTooltip then return end
    GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
    GameTooltip:SetText("Skips completed quests when Abandoning All")
    GameTooltip:Show()
  end)
  completedBtn:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

  UpdateCompletedButton()

  -- Abandon All action button: match the main top mode/scope button (text-only) but orange.
  local runKeepAbandonBtn = CreateFrame("Button", nil, p)
  runKeepAbandonBtn:SetSize(320, 28)
  runKeepAbandonBtn:SetPoint("BOTTOM", p, "BOTTOM", 0, 12)
  runKeepAbandonBtn:Hide()

  local runKeepAbandonBtnText = runKeepAbandonBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  runKeepAbandonBtnText:SetPoint("CENTER", runKeepAbandonBtn, "CENTER", 0, 0)
  SetFontStringSize(runKeepAbandonBtnText, 18)
  runKeepAbandonBtnText:SetText("|cffff9900Abandon All Quests|r")
  runKeepAbandonBtn._text = runKeepAbandonBtnText

  runKeepAbandonBtn:SetScript("OnClick", function()
    if type(ns.RunQuestXKeepListAbandon) == "function" then
      ns.RunQuestXKeepListAbandon()
    else
      Print("Keep List abandon is unavailable.")
    end
  end)

  runKeepAbandonBtn:SetScript("OnEnter", function()
    if not GameTooltip then return end
    GameTooltip:SetOwner(runKeepAbandonBtn, "ANCHOR_CURSOR")
    GameTooltip:SetText("Abandons all quests except excluded quests")
    GameTooltip:Show()
  end)
  runKeepAbandonBtn:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

  -- Reload UI button (match other tabs)
  local reloadBtn = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
  reloadBtn:SetSize(90, 22)
  reloadBtn:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -12, 12)
  reloadBtn:SetText("Reload UI")
  reloadBtn:SetScript("OnClick", function()
    local r = _G and _G["ReloadUI"]
    if r then r() end
  end)

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

  -- _syncModeUI() is invoked earlier during panel construction, before some of the
  -- bottom/action controls exist. Sync once more so initial visibility is correct.
  if p and p._syncModeUI then pcall(p._syncModeUI, p) end

  local function ClearInputs()
    if questIDBox then questIDBox:SetText("") end

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

  local function SetButtonColor(btn, label, state)
    if not (btn and btn.SetText) then return end
    if state == "inactive" then
      btn:SetText("|cffffff00" .. label .. "|r")
      return
    end
    if state == "active" then
      btn:SetText("|cff00ff00" .. label .. "|r")
      return
    end
    if state == "disabled" then
      btn:SetText("|cffff9900" .. label .. "|r")
      return
    end
    btn:SetText(label)
  end

  local function SetDynamicTip(btn, getLines)
    if not (btn and btn.SetScript and getLines) then return end
    btn:SetScript("OnEnter", function(self)
      if not GameTooltip then return end
      local t0, l1, l2, l3 = getLines()
      if not t0 then return end
      GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
      GameTooltip:SetText(t0)
      if l1 then GameTooltip:AddLine(l1, 1, 1, 1, true) end
      if l2 then GameTooltip:AddLine(l2, 1, 1, 1, true) end
      if l3 then GameTooltip:AddLine(l3, 1, 1, 1, true) end
      GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
  end

  local function MakeKeyRule(qid, questXY)
    qid = tonumber(qid)
    questXY = tostring(questXY or "X"):upper():gsub("%s+", "")
    return { questID = qid, questXY = questXY }
  end

  local function GetDesiredQuestXGate()
    local scopeMode = NormalizeScopeMode(p._questXScopeMode)
    if scopeMode == "RESTING" then
      return { restedOnly = true, locationID = nil }
    end
    local mapID = GetCurrentMapIDSafe()
    return { restedOnly = nil, locationID = mapID and tostring(mapID) or nil }
  end

  local function GateMatches(rule, questXY)
    if questXY ~= "X" then
      return true
    end
    local desired = GetDesiredQuestXGate()
    local rRested = (type(rule) == "table") and (rule.restedOnly == true) or false
    local rLoc = (type(rule) == "table") and rule.locationID or nil
    if rLoc ~= nil then rLoc = tostring(rLoc) end
    local dLoc = desired.locationID
    if dLoc ~= nil then dLoc = tostring(dLoc) end

    if desired.restedOnly == true then
      return rRested and (rLoc == nil or rLoc == "")
    end

    -- MAP gate (or global if mapID unavailable)
    if dLoc == nil then
      return (not rRested) and (rLoc == nil or rLoc == "")
    end
    return (not rRested) and (rLoc == dLoc)
  end

  local function FindMatchingCustomRule(rules, questXY, qid)
    if type(rules) ~= "table" then return nil end
    for idx, r in ipairs(rules) do
      if type(r) == "table" and tonumber(r.questID) == qid and NormalizeQuestXY(r.questXY) == questXY and GateMatches(r, questXY) then
        return idx, r
      end
    end
    return nil
  end

  local function RemoveMatchingCustomRules(rules, questXY, qid)
    if type(rules) ~= "table" then return 0 end
    local removed = 0
    if questXY == "X" then
      local idx = (FindMatchingCustomRule(rules, questXY, qid))
      if type(idx) == "number" then
        table.remove(rules, idx)
        return 1
      end
      return 0
    end

    for i = #rules, 1, -1 do
      local r = rules[i]
      if type(r) == "table" and tonumber(r.questID) == qid and NormalizeQuestXY(r.questXY) == questXY then
        table.remove(rules, i)
        removed = removed + 1
      end
    end
    return removed
  end

  local function BuiltInRuleExists(questXY, qid)
    questXY = NormalizeQuestXY(questXY)
    if not questXY then return false end

    -- Default pack rules
    for _, r in ipairs((type(ns) == "table" and type(ns.rules) == "table" and ns.rules) or {}) do
      if type(r) == "table" and tonumber(r.questID) == qid and NormalizeQuestXY(r.questXY) == questXY and GateMatches(r, questXY) then
        return true
      end
    end

    -- Default edits (if any)
    local edits = (type(GetDefaultRuleEdits) == "function") and (GetDefaultRuleEdits() or {}) or {}
    for _, r in pairs(edits) do
      if type(r) == "table" and tonumber(r.questID) == qid and NormalizeQuestXY(r.questXY) == questXY and GateMatches(r, questXY) then
        return true
      end
    end

    return false
  end

  local function IsEditing()
    return (p._editingCustomIndex or p._editingDefaultKey or p._editingDefaultBase) and true or false
  end

  local function UpdateScopeButtons()
    local isEditing = IsEditing()
    local qid = tonumber(questIDBox and questIDBox.GetText and questIDBox:GetText() or "")
    local questXY = tostring(p._questXY or "X"):upper():gsub("%s+", "")
    if questXY ~= "Y" and questXY ~= "K" then questXY = "X" end

    -- Edit mode: keep legacy Save/Add behavior.
    if isEditing then
      if btnAcc and btnAcc.Enable then btnAcc:Enable() end
      if btnChar and btnChar.SetShown then btnChar:SetShown(false) end
      btnAcc:SetScript("OnClick", function(_, mouseButton)
        if mouseButton ~= "LeftButton" then return end
        AddOrSaveRule(true)
      end)
      SetDynamicTip(btnAcc, function()
        return "Save", "Left-click: save edits"
      end)
      return
    end

    if btnChar and btnChar.SetShown then btnChar:SetShown(true) end

    if not qid or qid <= 0 then
      if btnAcc and btnAcc.Disable then btnAcc:Disable() end
      if btnChar and btnChar.Disable then btnChar:Disable() end
      SetButtonColor(btnAcc, "Account", nil)
      SetButtonColor(btnChar, "Character", nil)
      SetDynamicTip(btnAcc, function() return "Account", "Enter a QuestID first." end)
      SetDynamicTip(btnChar, function() return "Character", "Enter a QuestID first." end)
      btnAcc:SetScript("OnClick", nil)
      btnChar:SetScript("OnClick", nil)
      return
    end

    local accRules = GetRuleStore(true)
    local charRules = GetRuleStore(false)
    local inAccIdx = FindMatchingCustomRule(accRules, questXY, qid)
    local inCharIdx = FindMatchingCustomRule(charRules, questXY, qid)
    local inAcc = (type(inAccIdx) == "number")
    local inChar = (type(inCharIdx) == "number")
    local inDB = BuiltInRuleExists(questXY, qid)

    local accRuleExists = inDB or inAcc
    local charRuleExists = inDB or inChar

    local keyRule = MakeKeyRule(qid, questXY)
    local isDisabledAcc = (type(ns) == "table" and type(ns.IsRuleDisabledInScope) == "function") and ns.IsRuleDisabledInScope(keyRule, true) or false
    local isDisabledChar = (type(ns) == "table" and type(ns.IsRuleDisabledInScope) == "function") and ns.IsRuleDisabledInScope(keyRule, false) or false

    if btnAcc then
      if btnAcc.Enable then btnAcc:Enable() end
      local aState
      if not accRuleExists then aState = "inactive" else aState = isDisabledAcc and "disabled" or "active" end
      SetButtonColor(btnAcc, "Account", aState)
      btnAcc:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
          if inAcc then
            local removed = RemoveMatchingCustomRules(accRules, questXY, qid)
            if type(ns) == "table" and type(ns.ClearRuleDisabledInScope) == "function" then
              ns.ClearRuleDisabledInScope(keyRule, true)
            end
            if removed > 0 then
              Print(string.format("Removed %s for quest %d from Account.", GetModeLabel(questXY), qid))
            end
            if RefreshAll then RefreshAll() end
            if RefreshRulesList then RefreshRulesList() end
            if RefreshXRulesList then RefreshXRulesList() end
            UpdateScopeButtons()
            return
          end
          Print("Built-in rules can't be removed. Left-click to disable instead.")
          return
        end

        if not accRuleExists then
          AddOrSaveRule(true)
          UpdateScopeButtons()
          return
        end

        if type(ns) == "table" and type(ns.ToggleRuleDisabledInScope) == "function" then
          ns.ToggleRuleDisabledInScope(keyRule, true)
        end
        UpdateScopeButtons()
      end)

      SetDynamicTip(btnAcc, function()
        if not accRuleExists then
          return "Account (Inactive)", "Left-click: add Account rule"
        end
        if isDisabledAcc then
          return "Account (Disabled)", "Left-click: re-enable on Account", (inAcc and "Right-click: remove Account rule" or nil)
        end
        return "Account (Active)", "Left-click: disable on Account", (inAcc and "Right-click: remove Account rule" or "(Built-in rule)")
      end)
    end

    if btnChar then
      if btnChar.Enable then btnChar:Enable() end
      local cState
      if not charRuleExists then cState = "inactive" else cState = isDisabledChar and "disabled" or "active" end
      SetButtonColor(btnChar, "Character", cState)
      btnChar:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
          if inChar then
            local removed = RemoveMatchingCustomRules(charRules, questXY, qid)
            if type(ns) == "table" and type(ns.ClearRuleDisabledInScope) == "function" then
              ns.ClearRuleDisabledInScope(keyRule, false)
            end
            if removed > 0 then
              Print(string.format("Removed %s for quest %d from Character.", GetModeLabel(questXY), qid))
            end
            if RefreshAll then RefreshAll() end
            if RefreshRulesList then RefreshRulesList() end
            if RefreshXRulesList then RefreshXRulesList() end
            UpdateScopeButtons()
            return
          end
          Print("Built-in rules can't be removed. Left-click to disable instead.")
          return
        end

        if not charRuleExists then
          AddOrSaveRule(false)
          UpdateScopeButtons()
          return
        end

        if type(ns) == "table" and type(ns.ToggleRuleDisabledInScope) == "function" then
          ns.ToggleRuleDisabledInScope(keyRule, false)
        end
        UpdateScopeButtons()
      end)

      SetDynamicTip(btnChar, function()
        if not charRuleExists then
          return "Character (Inactive)", "Left-click: add Character rule"
        end
        if isDisabledChar then
          return "Character (Disabled)", "Left-click: re-enable on this character", (inChar and "Right-click: remove Character rule" or nil)
        end
        return "Character (Active)", "Left-click: disable on this character", (inChar and "Right-click: remove Character rule" or "(Built-in rule)")
      end)
    end
  end

  btnAcc:SetScript("OnClick", function(_, mouseButton)
    if mouseButton ~= "LeftButton" then return end
    AddOrSaveRule(true)
  end)
  btnChar:SetScript("OnClick", function(_, mouseButton)
    if mouseButton ~= "LeftButton" then return end
    AddOrSaveRule(false)
  end)

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

  -- Keep scope buttons in sync as user edits input / swaps mode / changes QuestX scope.
  p._updateScopeButtons = UpdateScopeButtons
  if questIDBox and questIDBox.HookScript then
    questIDBox:HookScript("OnTextChanged", function() UpdateScopeButtons() end)
    questIDBox:HookScript("OnShow", function() UpdateScopeButtons() end)
  end

  if scopeBtn and scopeBtn.HookScript then
    scopeBtn:HookScript("OnClick", function() UpdateScopeButtons() end)
  end

  UpdateScopeButtons()
end
