local addonName, ns = ...

ns.FQTOptionsPanels = ns.FQTOptionsPanels or {}

function ns.FQTOptionsPanels.BuildRules(ctx)
  if type(ctx) ~= "table" then return end

  local optionsFrame = ctx.optionsFrame
  local panels = ctx.panels
  if not (optionsFrame and panels and panels.rules) then return end

  local Print = ctx.Print or function(...) end
  local CreateFrame = ctx.CreateFrame or CreateFrame

  local GetUISetting = ctx.GetUISetting
  local SetUISetting = ctx.SetUISetting

  local GetCustomRules = ctx.GetCustomRules
  local GetCustomRulesTrash = ctx.GetCustomRulesTrash
  local GetEffectiveFrames = ctx.GetEffectiveFrames
  local GetFrameDisplayNameByID = ctx.GetFrameDisplayNameByID
  local GetItemNameSafe = ctx.GetItemNameSafe
  local GetQuestTitle = ctx.GetQuestTitle

  local DeepCopyValue = ctx.DeepCopyValue
  local EnsureUniqueKeyForCustomRule = ctx.EnsureUniqueKeyForCustomRule

  local IsRuleDisabled = ctx.IsRuleDisabled
  local ToggleRuleDisabled = ctx.ToggleRuleDisabled

  local UseModernMenuDropDown = ctx.UseModernMenuDropDown
  local HideDropDownMenuArt = ctx.HideDropDownMenuArt

  local RefreshAll = ctx.RefreshAll
  local RefreshFramesList = ctx.RefreshFramesList

  local OpenCustomRuleInTab = ctx.OpenCustomRuleInTab
  local OpenDefaultRuleInTab = ctx.OpenDefaultRuleInTab

  local GetDefaultRuleEdits = ctx.GetDefaultRuleEdits

  local UDDM_SetWidth = ctx.UDDM_SetWidth
  local UDDM_SetText = ctx.UDDM_SetText
  local UDDM_Initialize = ctx.UDDM_Initialize
  local UDDM_CreateInfo = ctx.UDDM_CreateInfo
  local UDDM_AddButton = ctx.UDDM_AddButton

  local rowH = 18

  local rulesTitle = panels.rules:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  rulesTitle:SetPoint("TOPLEFT", 12, -40)
  rulesTitle:SetText("Rules")
  optionsFrame._rulesTitle = rulesTitle

  local rulesViewDrop = CreateFrame("Frame", nil, panels.rules, "UIDropDownMenuTemplate")
  rulesViewDrop:SetPoint("TOPRIGHT", panels.rules, "TOPRIGHT", -6, -54)
  if UDDM_SetWidth then UDDM_SetWidth(rulesViewDrop, 120) end
  if UDDM_SetText then UDDM_SetText(rulesViewDrop, "All") end
  optionsFrame._rulesViewDrop = rulesViewDrop

  local rulesCategoryDrop = CreateFrame("Frame", nil, panels.rules, "UIDropDownMenuTemplate")
  rulesCategoryDrop:SetPoint("TOPRIGHT", rulesViewDrop, "TOPLEFT", -6, 0)
  if UDDM_SetWidth then UDDM_SetWidth(rulesCategoryDrop, 120) end
  if UDDM_SetText then UDDM_SetText(rulesCategoryDrop, "Any Category") end
  optionsFrame._rulesCategoryDrop = rulesCategoryDrop

  local rulesCategoryDropHit = CreateFrame("Button", nil, panels.rules)
  rulesCategoryDropHit:EnableMouse(true)
  rulesCategoryDropHit:SetAlpha(0.01)
  rulesCategoryDropHit:SetPoint("TOPLEFT", rulesCategoryDrop, "TOPLEFT", 18, -2)
  rulesCategoryDropHit:SetPoint("BOTTOMRIGHT", rulesCategoryDrop, "BOTTOMRIGHT", -18, 2)
  optionsFrame._rulesCategoryDropHit = rulesCategoryDropHit

  local rulesExpansionDrop = CreateFrame("Frame", nil, panels.rules, "UIDropDownMenuTemplate")
  rulesExpansionDrop:SetPoint("TOPRIGHT", rulesCategoryDrop, "TOPLEFT", -6, 0)
  if UDDM_SetWidth then UDDM_SetWidth(rulesExpansionDrop, 140) end
  if UDDM_SetText then UDDM_SetText(rulesExpansionDrop, "Any Expansion") end
  optionsFrame._rulesExpansionDrop = rulesExpansionDrop

  local rulesExpansionDropHit = CreateFrame("Button", nil, panels.rules)
  rulesExpansionDropHit:EnableMouse(true)
  rulesExpansionDropHit:SetAlpha(0.01)
  rulesExpansionDropHit:SetPoint("TOPLEFT", rulesExpansionDrop, "TOPLEFT", 18, -2)
  rulesExpansionDropHit:SetPoint("BOTTOMRIGHT", rulesExpansionDrop, "BOTTOMRIGHT", -18, 2)
  optionsFrame._rulesExpansionDropHit = rulesExpansionDropHit

  local rulesSearch = CreateFrame("EditBox", nil, panels.rules, "InputBoxTemplate")
  rulesSearch:SetAutoFocus(false)
  rulesSearch:SetSize(220, 18)
  rulesSearch:SetPoint("TOPLEFT", 12, -56)
  rulesSearch:SetTextInsets(6, 6, 2, 2)
  optionsFrame._rulesSearch = rulesSearch

  local rulesSearchHint = rulesSearch:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  rulesSearchHint:SetPoint("LEFT", rulesSearch, "LEFT", 8, 0)
  rulesSearchHint:SetText("Search…")
  optionsFrame._rulesSearchHint = rulesSearchHint

  local rulesViewDropHit = CreateFrame("Button", nil, panels.rules)
  rulesViewDropHit:EnableMouse(true)
  rulesViewDropHit:SetAlpha(0.01)
  rulesViewDropHit:SetPoint("TOPLEFT", rulesViewDrop, "TOPLEFT", 18, -2)
  rulesViewDropHit:SetPoint("BOTTOMRIGHT", rulesViewDrop, "BOTTOMRIGHT", -18, 2)
  optionsFrame._rulesViewDropHit = rulesViewDropHit

  local hint = panels.rules:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  hint:SetPoint("TOPLEFT", 12, -74)
  hint:SetText("Create rules using the Quest / Items / Spell / Text tabs. Use this list to enable/disable and edit.")

  local rulesScroll = CreateFrame("ScrollFrame", nil, panels.rules, "UIPanelScrollFrameTemplate")
  rulesScroll:SetPoint("TOPLEFT", 12, -86)
  rulesScroll:SetPoint("BOTTOMLEFT", 12, 44)
  rulesScroll:SetWidth(530)
  optionsFrame._rulesScroll = rulesScroll

  local zebraRules = CreateFrame("Slider", nil, panels.rules, "UISliderTemplate")
  zebraRules:ClearAllPoints()
  zebraRules:SetPoint("BOTTOM", optionsFrame, "BOTTOM", 0, 18)
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
    local v = (type(GetUISetting) == "function") and (tonumber(GetUISetting("zebraAlpha", 0.05) or 0.05) or 0.05) or 0.05
    if v < 0 then v = 0 elseif v > 0.20 then v = 0.20 end
    self:SetValue(v)
    optionsFrame._zebraUpdating = false
  end)
  zebraRules:SetScript("OnValueChanged", function(self, value)
    if not optionsFrame or optionsFrame._zebraUpdating then return end
    optionsFrame._zebraUpdating = true
    local v = tonumber(value) or 0
    if v < 0 then v = 0 elseif v > 0.20 then v = 0.20 end
    if type(SetUISetting) == "function" then
      SetUISetting("zebraAlpha", v)
    end
    if optionsFrame._zebraSliderFrames and optionsFrame._zebraSliderFrames.SetValue then
      optionsFrame._zebraSliderFrames:SetValue(v)
    end
    if RefreshFramesList then RefreshFramesList() end
    if optionsFrame._refreshRulesList then optionsFrame._refreshRulesList() end
    optionsFrame._zebraUpdating = false
  end)
  optionsFrame._zebraSliderRules = zebraRules

  local rulesContent = CreateFrame("Frame", nil, rulesScroll)
  rulesContent:SetSize(1, 1)
  rulesScroll:SetScrollChild(rulesContent)
  rulesScroll:SetScript("OnSizeChanged", function(self)
    if not optionsFrame or not optionsFrame._rulesContent then return end
    local w = tonumber(self:GetWidth() or 0) or 0
    optionsFrame._rulesContent:SetWidth(math.max(1, w - 28))
  end)
  optionsFrame._rulesContent = rulesContent
  optionsFrame._ruleRows = optionsFrame._ruleRows or {}

  local function GetRulesView()
    if not optionsFrame then return "all" end
    local v = tostring(optionsFrame._rulesView or (type(GetUISetting) == "function" and GetUISetting("rulesView", "all")) or "all")
    if v ~= "all" and v ~= "custom" and v ~= "defaults" and v ~= "trash" then v = "all" end
    optionsFrame._rulesView = v
    return v
  end

  local function SetRulesView(v)
    if not optionsFrame then return end
    v = tostring(v or "all")
    if v ~= "all" and v ~= "custom" and v ~= "defaults" and v ~= "trash" then v = "all" end
    optionsFrame._rulesView = v
    if type(SetUISetting) == "function" then
      SetUISetting("rulesView", v)
    end
    if UDDM_SetText then
      UDDM_SetText(rulesViewDrop, (v == "all") and "All" or (v == "defaults") and "Defaults" or (v == "trash") and "Trash" or "Custom")
    end
    if optionsFrame._refreshRulesList then optionsFrame._refreshRulesList() end
  end

  optionsFrame._rulesView = tostring((type(GetUISetting) == "function" and GetUISetting("rulesView", "all")) or "all")

  local function GetRulesSearchText()
    if not optionsFrame then return "" end
    local s = tostring(optionsFrame._rulesSearchText or ((type(GetUISetting) == "function") and GetUISetting("rulesSearch", "") or ""))
    optionsFrame._rulesSearchText = s
    return s
  end

  local function SetRulesSearchText(s)
    if not optionsFrame then return end
    s = tostring(s or "")
    optionsFrame._rulesSearchText = s
    if type(SetUISetting) == "function" then
      SetUISetting("rulesSearch", s)
    end
  end

  local function GetRulesExpansionFilter()
    if not optionsFrame then return "all" end
    local v = tostring(optionsFrame._rulesExpansionFilter or ((type(GetUISetting) == "function") and GetUISetting("rulesExpansionFilter", "all") or "all"))
    if v == "" then v = "all" end
    optionsFrame._rulesExpansionFilter = v
    return v
  end

  local function SetRulesExpansionFilter(v)
    if not optionsFrame then return end
    v = tostring(v or "all")
    if v == "" then v = "all" end
    optionsFrame._rulesExpansionFilter = v
    if type(SetUISetting) == "function" then
      SetUISetting("rulesExpansionFilter", v)
    end
    if optionsFrame._refreshRulesList then optionsFrame._refreshRulesList() end
  end

  local function GetRulesCategoryFilter()
    if not optionsFrame then return "all" end
    local v = tostring(optionsFrame._rulesCategoryFilter or ((type(GetUISetting) == "function") and GetUISetting("rulesCategoryFilter", "all") or "all"))
    if v == "" then v = "all" end
    optionsFrame._rulesCategoryFilter = v
    return v
  end

  local function SetRulesCategoryFilter(v)
    if not optionsFrame then return end
    v = tostring(v or "all")
    if v == "" then v = "all" end
    optionsFrame._rulesCategoryFilter = v
    if type(SetUISetting) == "function" then
      SetUISetting("rulesCategoryFilter", v)
    end
    if optionsFrame._refreshRulesList then optionsFrame._refreshRulesList() end
  end

  do
    local v = GetRulesView()
    if UDDM_SetText then
      UDDM_SetText(rulesViewDrop, (v == "all") and "All" or (v == "defaults") and "Defaults" or (v == "trash") and "Trash" or "Custom")
    end
  end

  if type(UseModernMenuDropDown) == "function" and UseModernMenuDropDown(rulesViewDrop, function(root)
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
    UDDM_Initialize(rulesViewDrop, function(_, level)
      if level ~= 1 then return end
      for _, v in ipairs({ "all", "custom", "defaults", "trash" }) do
        local info = UDDM_CreateInfo()
        info.text = (v == "all") and "All" or (v == "defaults") and "Defaults" or (v == "trash") and "Trash" or "Custom"
        info.checked = (GetRulesView() == v) and true or false
        info.func = function() SetRulesView(v) end
        UDDM_AddButton(info)
      end
    end)
  end

  if rulesViewDropHit then
    rulesViewDropHit:SetScript("OnClick", function()
      local toggle = _G and rawget(_G, "ToggleDropDownMenu")
      if toggle then
        toggle(1, nil, rulesViewDrop, rulesViewDrop, 0, 0)
      end
    end)
  end

  if rulesSearch then
    rulesSearch:SetScript("OnShow", function(self)
      local s = GetRulesSearchText()
      if self.SetText then self:SetText(s) end
      if optionsFrame and optionsFrame._rulesSearchHint and optionsFrame._rulesSearchHint.SetShown then
        optionsFrame._rulesSearchHint:SetShown((s or "") == "")
      end
    end)
    rulesSearch:SetScript("OnTextChanged", function(self)
      local s = tostring(self.GetText and self:GetText() or "")
      SetRulesSearchText(s)
      if optionsFrame and optionsFrame._rulesSearchHint and optionsFrame._rulesSearchHint.SetShown then
        optionsFrame._rulesSearchHint:SetShown((s or "") == "")
      end
      if optionsFrame and optionsFrame._refreshRulesList then optionsFrame._refreshRulesList() end
    end)
    rulesSearch:SetScript("OnEscapePressed", function(self)
      self:ClearFocus()
      if self.SetText then self:SetText("") end
      SetRulesSearchText("")
      if optionsFrame and optionsFrame._refreshRulesList then optionsFrame._refreshRulesList() end
    end)
    rulesSearch:SetScript("OnEnterPressed", function(self)
      self:ClearFocus()
    end)
  end

  local function InitRulesExpansionDrop()
    local v = GetRulesExpansionFilter()
    if UDDM_SetText then
      UDDM_SetText(rulesExpansionDrop, (v == "all") and "Any Expansion" or v)
    end
  end

  local function InitRulesCategoryDrop()
    local v = GetRulesCategoryFilter()
    if UDDM_SetText then
      UDDM_SetText(rulesCategoryDrop, (v == "all") and "Any Category" or v)
    end
  end

  InitRulesExpansionDrop()
  InitRulesCategoryDrop()

  if type(UseModernMenuDropDown) == "function" and UseModernMenuDropDown(rulesExpansionDrop, function(root)
    if root and root.CreateTitle then root:CreateTitle("Expansion") end
    local choices = (optionsFrame and optionsFrame._rulesExpansionChoices) or { "all" }
    for _, val in ipairs(choices) do
      local label = (val == "all") and "Any" or tostring(val)
      if root and root.CreateRadio then
        root:CreateRadio(label, function() return (GetRulesExpansionFilter() == tostring(val)) end, function() SetRulesExpansionFilter(val) end)
      elseif root and root.CreateButton then
        root:CreateButton(label, function() SetRulesExpansionFilter(val) end)
      end
    end
  end) then
    -- modern menu wired
  elseif UDDM_Initialize and UDDM_CreateInfo and UDDM_AddButton then
    UDDM_Initialize(rulesExpansionDrop, function(_, level)
      if level ~= 1 then return end
      local choices = (optionsFrame and optionsFrame._rulesExpansionChoices) or { "all" }
      for _, val in ipairs(choices) do
        local info = UDDM_CreateInfo()
        info.text = (val == "all") and "Any" or tostring(val)
        info.checked = (GetRulesExpansionFilter() == tostring(val)) and true or false
        info.func = function() SetRulesExpansionFilter(val) end
        UDDM_AddButton(info)
      end
    end)
  end

  if rulesExpansionDropHit then
    rulesExpansionDropHit:SetScript("OnClick", function()
      local toggle = _G and rawget(_G, "ToggleDropDownMenu")
      if toggle then
        toggle(1, nil, rulesExpansionDrop, rulesExpansionDrop, 0, 0)
      end
    end)
  end

  if type(UseModernMenuDropDown) == "function" and UseModernMenuDropDown(rulesCategoryDrop, function(root)
    if root and root.CreateTitle then root:CreateTitle("Category") end
    local choices = (optionsFrame and optionsFrame._rulesCategoryChoices) or { "all" }
    for _, val in ipairs(choices) do
      local label = (val == "all") and "Any" or tostring(val)
      if root and root.CreateRadio then
        root:CreateRadio(label, function() return (GetRulesCategoryFilter() == tostring(val)) end, function() SetRulesCategoryFilter(val) end)
      elseif root and root.CreateButton then
        root:CreateButton(label, function() SetRulesCategoryFilter(val) end)
      end
    end
  end) then
    -- modern menu wired
  elseif UDDM_Initialize and UDDM_CreateInfo and UDDM_AddButton then
    UDDM_Initialize(rulesCategoryDrop, function(_, level)
      if level ~= 1 then return end
      local choices = (optionsFrame and optionsFrame._rulesCategoryChoices) or { "all" }
      for _, val in ipairs(choices) do
        local info = UDDM_CreateInfo()
        info.text = (val == "all") and "Any" or tostring(val)
        info.checked = (GetRulesCategoryFilter() == tostring(val)) and true or false
        info.func = function() SetRulesCategoryFilter(val) end
        UDDM_AddButton(info)
      end
    end)
  end

  if rulesCategoryDropHit then
    rulesCategoryDropHit:SetScript("OnClick", function()
      local toggle = _G and rawget(_G, "ToggleDropDownMenu")
      if toggle then
        toggle(1, nil, rulesCategoryDrop, rulesCategoryDrop, 0, 0)
      end
    end)
  end

  local function SafeZebraAlpha()
    local zebraA = 0.05
    if type(GetUISetting) == "function" then
      zebraA = tonumber(GetUISetting("zebraAlpha", 0.05) or 0.05) or 0.05
    end
    if zebraA < 0 then zebraA = 0 elseif zebraA > 0.20 then zebraA = 0.20 end
    return zebraA
  end

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

  local function GetEffectiveDefaultRule(baseRule)
    local edits = (type(GetDefaultRuleEdits) == "function") and (GetDefaultRuleEdits() or {}) or {}
    local key = RuleKey(baseRule)
    local r2 = key and edits[key] or nil
    return (type(r2) == "table") and r2 or baseRule
  end

  local function IsDefaultRuleEdited(baseRule)
    local edits = (type(GetDefaultRuleEdits) == "function") and (GetDefaultRuleEdits() or {}) or {}
    local key = RuleKey(baseRule)
    return (key and type(edits[key]) == "table") and true or false
  end

  local function GetSortedFrameIDs(displayByID)
    local ids = {}
    for _, def in ipairs((type(GetEffectiveFrames) == "function" and GetEffectiveFrames()) or {}) do
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
      local edits = (type(GetDefaultRuleEdits) == "function") and (GetDefaultRuleEdits() or {}) or {}
      local edited = DeepCopyValue and DeepCopyValue(displayRule) or displayRule
      if type(edited) == "table" then
        edited.frameID = newID
        edited.targets = nil
        edits[key] = edited
      end
      return
    end

    if type(baseRule) ~= "table" then return end
    baseRule.frameID = newID
    baseRule.targets = nil
  end

  local function FormatRuleText(r)
    local label = (type(r) == "table" and r.label ~= nil) and tostring(r.label) or ""
    label = label:gsub("\n", " "):gsub("^%s+", ""):gsub("%s+$", "")

    local function LevelSuffix(rr)
      if type(rr) ~= "table" then return "" end

      local function NormalizeOp(op)
        return (op == "<" or op == "<=" or op == "=" or op == ">=" or op == ">" or op == "!=") and op or nil
      end

      local op, lvl
      if type(rr.playerLevel) == "table" then
        op = rr.playerLevel[1]
        lvl = tonumber(rr.playerLevel[2])
      else
        op = rr.playerLevelOp
        lvl = tonumber(rr.playerLevel)
      end

      op = NormalizeOp(op)
      if op and lvl and lvl > 0 then
        return string.format(" [Lvl %s %d]", op, lvl)
      end
      return ""
    end

    if type(r) == "table" and type(r.item) == "table" and r.item.itemID then
      local itemID = tonumber(r.item.itemID) or 0
      local base = (label ~= "") and label or ((type(GetItemNameSafe) == "function" and GetItemNameSafe(itemID)) or ("Item " .. tostring(itemID)))
      return string.format("I: %s%s", base, LevelSuffix(r))
    elseif tonumber(r and r.questID) and tonumber(r.questID) > 0 then
      local q = tonumber(r.questID) or 0
      local base = (label ~= "") and label or ((type(GetQuestTitle) == "function" and GetQuestTitle(q)) or ("Quest " .. tostring(q)))
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

  local function RefreshRulesListImpl()
    if not optionsFrame then return end

    local view = GetRulesView()

    local list = {}
    local sourceOf = nil
    if view == "defaults" then
      for _, r in ipairs(ns.rules or {}) do
        list[#list + 1] = r
      end
    elseif view == "trash" then
      for _, r in ipairs(((type(GetCustomRulesTrash) == "function") and GetCustomRulesTrash()) or {}) do
        list[#list + 1] = r
      end
    elseif view == "custom" then
      for _, r in ipairs(((type(GetCustomRules) == "function") and GetCustomRules()) or {}) do
        list[#list + 1] = r
      end
    else
      sourceOf = {}
      for _, r in ipairs(ns.rules or {}) do
        list[#list + 1] = r
        sourceOf[r] = "default"
      end
      for _, r in ipairs(((type(GetCustomRules) == "function") and GetCustomRules()) or {}) do
        list[#list + 1] = r
        sourceOf[r] = "custom"
      end
    end

    -- Build filter choices (expansion/category) from the unfiltered set for this view.
    local function RuleExpansionName(rule, src)
      if type(rule) == "table" then
        local n = rule._expansionName
        if type(n) == "string" and n ~= "" then return n end
      end
      if src == "custom" or src == "trash" then return "Custom" end
      if src == "default" then return "Unclassified" end
      return "Unclassified"
    end

    local function RuleCategory(rule)
      if type(rule) ~= "table" then return "Other" end
      local c = rule.category or rule._category
      if type(c) == "string" and c ~= "" then return c end
      if rule.questID ~= nil then return "Quest" end
      if type(rule.item) == "table" and rule.item.itemID ~= nil then return "Item" end
      if rule.spellKnown ~= nil or rule.notSpellKnown ~= nil then return "Spell" end
      if type(rule.aura) == "table" then
        if rule.aura.eventKind ~= nil or rule.aura.keywords ~= nil then return "Event" end
        return "Aura"
      end
      if rule.locationID ~= nil then return "Location" end
      return "Other"
    end

    do
      local expSet, expList = {}, { "all" }
      local expIDByName = {}
      local catSet, catList = {}, { "all" }
      for i = 1, #list do
        local r = list[i]
        local src = (view == "defaults") and "default" or (view == "trash") and "trash" or (view == "custom") and "custom" or (sourceOf and sourceOf[r])
        local exp = RuleExpansionName(r, src)
        if exp and not expSet[exp] then
          expSet[exp] = true
          expList[#expList + 1] = exp
        end

        if exp and exp ~= "" then
          local eid = nil
          if exp == "Weekly / Events" then
            eid = 10000
          elseif exp == "Custom" then
            eid = -10000
          else
            eid = (type(r) == "table" and tonumber(r._expansionID)) or nil
          end
          if eid ~= nil then
            local prev = expIDByName[exp]
            if prev == nil or eid > prev then
              expIDByName[exp] = eid
            end
          end
        end

        local rr = (src == "default") and GetEffectiveDefaultRule(r) or r
        local cat = RuleCategory(rr)
        if cat and not catSet[cat] then
          catSet[cat] = true
          catList[#catList + 1] = cat
        end
      end
      table.sort(expList, function(a, b)
        if a == "all" then return true end
        if b == "all" then return false end
        local ia = expIDByName[a]
        local ib = expIDByName[b]
        ia = (type(ia) == "number") and ia or 0
        ib = (type(ib) == "number") and ib or 0
        if ia ~= ib then return ia > ib end
        return tostring(a) > tostring(b)
      end)
      table.sort(catList, function(a, b)
        if a == "all" then return true end
        if b == "all" then return false end
        return tostring(a) < tostring(b)
      end)
      optionsFrame._rulesExpansionChoices = expList
      optionsFrame._rulesCategoryChoices = catList
    end

    -- Apply filters (search + expansion + category) before ordering.
    do
      local q = tostring(GetRulesSearchText() or "")
      q = q:gsub("^%s+", ""):gsub("%s+$", "")
      local ql = q:lower()
      local expFilter = tostring(GetRulesExpansionFilter() or "all")
      local catFilter = tostring(GetRulesCategoryFilter() or "all")

      if UDDM_SetText then
        UDDM_SetText(rulesExpansionDrop, (expFilter == "all") and "Any Expansion" or expFilter)
        UDDM_SetText(rulesCategoryDrop, (catFilter == "all") and "Any Category" or catFilter)
      end

      local function MatchesSearch(rr)
        if ql == "" then return true end
        if type(rr) ~= "table" then return false end
        local parts = {}
        if rr.label then parts[#parts + 1] = tostring(rr.label) end
        if rr.questInfo then parts[#parts + 1] = tostring(rr.questInfo) end
        if rr.key then parts[#parts + 1] = tostring(rr.key) end
        if rr.questID ~= nil then parts[#parts + 1] = tostring(rr.questID) end
        if type(rr.item) == "table" and rr.item.itemID ~= nil then parts[#parts + 1] = tostring(rr.item.itemID) end
        if rr.spellKnown ~= nil then parts[#parts + 1] = tostring(rr.spellKnown) end
        if rr.notSpellKnown ~= nil then parts[#parts + 1] = tostring(rr.notSpellKnown) end
        if rr.locationID ~= nil then parts[#parts + 1] = tostring(rr.locationID) end
        if rr.group ~= nil then parts[#parts + 1] = tostring(rr.group) end
        if type(rr.aura) == "table" then
          if rr.aura.spellID ~= nil then parts[#parts + 1] = tostring(rr.aura.spellID) end
          if rr.aura.eventKind ~= nil then parts[#parts + 1] = tostring(rr.aura.eventKind) end
          if type(rr.aura.keywords) == "table" then
            for _, kw in ipairs(rr.aura.keywords) do parts[#parts + 1] = tostring(kw) end
          end
        end
        local hay = table.concat(parts, " "):lower()
        return hay:find(ql, 1, true) ~= nil
      end

      if ql ~= "" or expFilter ~= "all" or catFilter ~= "all" then
        local filtered = {}
        for i = 1, #list do
          local r = list[i]
          local src = (view == "defaults") and "default" or (view == "trash") and "trash" or (view == "custom") and "custom" or (sourceOf and sourceOf[r])
          local rr = (src == "default") and GetEffectiveDefaultRule(r) or r

          local ok = true
          if expFilter ~= "all" then
            ok = (RuleExpansionName(r, src) == expFilter)
          end
          if ok and catFilter ~= "all" then
            ok = (RuleCategory(rr) == catFilter)
          end
          if ok and ql ~= "" then
            ok = MatchesSearch(rr)
          end

          if ok then
            filtered[#filtered + 1] = r
          end
        end
        list = filtered
      end
    end

    -- Rules-tab ordering (independent of any frame contents ordering).
    -- Stored as an array of RuleKey() strings in account UI settings.
    local function GetRulesTabOrder()
      if type(GetUISetting) ~= "function" or type(SetUISetting) ~= "function" then
        return {}
      end
      local o = GetUISetting("rulesTabOrder", nil)
      if type(o) ~= "table" then
        o = {}
        SetUISetting("rulesTabOrder", o)
      end
      return o
    end

    local function IndexOfKey(order, key)
      if type(order) ~= "table" then return nil end
      key = tostring(key or "")
      if key == "" then return nil end
      for i = 1, #order do
        if tostring(order[i]) == key then return i end
      end
      return nil
    end

    local function EnsureKeyInOrder(order, key)
      if type(order) ~= "table" then return end
      key = tostring(key or "")
      if key == "" then return end
      if not IndexOfKey(order, key) then
        order[#order + 1] = key
      end
    end

    local function SwapKeysInOrder(aKey, bKey)
      local order = GetRulesTabOrder()
      aKey = tostring(aKey or "")
      bKey = tostring(bKey or "")
      if aKey == "" or bKey == "" or aKey == bKey then return false end
      EnsureKeyInOrder(order, aKey)
      EnsureKeyInOrder(order, bKey)
      local ai = IndexOfKey(order, aKey)
      local bi = IndexOfKey(order, bKey)
      if not (ai and bi) then return false end
      order[ai], order[bi] = order[bi], order[ai]
      if type(SetUISetting) == "function" then
        SetUISetting("rulesTabOrder", order)
      end
      return true
    end

    local function SortListByRulesTabOrder()
      if view == "trash" then return end
      local order = GetRulesTabOrder()

      -- Seed: ensure all currently-visible keys exist in the saved order list.
      -- This prevents a first-time move from appending keys to the end (which looks like a random jump).
      for i = 1, #list do
        local k = RuleKey(list[i])
        if k then
          EnsureKeyInOrder(order, k)
        end
      end
      if type(SetUISetting) == "function" then
        SetUISetting("rulesTabOrder", order)
      end

      local orderIndex = {}
      for i = 1, #order do
        local k = tostring(order[i] or "")
        if k ~= "" and not orderIndex[k] then
          orderIndex[k] = i
        end
      end
      local orig = {}
      for i = 1, #list do orig[list[i]] = i end
      table.sort(list, function(a, b)
        local ka = RuleKey(a)
        local kb = RuleKey(b)
        local pa = ka and orderIndex[tostring(ka)] or nil
        local pb = kb and orderIndex[tostring(kb)] or nil
        if pa and pb and pa ~= pb then return pa < pb end
        if pa and not pb then return true end
        if pb and not pa then return false end
        return (orig[a] or 0) < (orig[b] or 0)
      end)
    end

    SortListByRulesTabOrder()

    -- Expansion grouping (Rules tab): build a display list with expandable headers.
    local function GetRulesExpansionCollapsed()
      if type(GetUISetting) ~= "function" or type(SetUISetting) ~= "function" then
        return {}
      end
      local o = GetUISetting("rulesExpCollapsed", nil)
      if type(o) ~= "table" then
        o = {}
        SetUISetting("rulesExpCollapsed", o)
      end
      return o
    end

    local function SetExpansionCollapsed(expName, collapsed)
      expName = tostring(expName or "")
      if expName == "" then return end
      if type(GetUISetting) ~= "function" or type(SetUISetting) ~= "function" then return end
      local o = GetRulesExpansionCollapsed()
      o[expName] = collapsed and true or nil
      SetUISetting("rulesExpCollapsed", o)
    end

    local function GetRulesCategoryCollapsed()
      if type(GetUISetting) ~= "function" or type(SetUISetting) ~= "function" then
        return {}
      end
      local o = GetUISetting("rulesCatCollapsed", nil)
      if type(o) ~= "table" then
        o = {}
        SetUISetting("rulesCatCollapsed", o)
      end
      return o
    end

    local function CatKey(expName, catName)
      expName = tostring(expName or "")
      catName = tostring(catName or "")
      return expName .. "\031" .. catName
    end

    local function SetCategoryCollapsed(expName, catName, collapsed)
      expName = tostring(expName or "")
      catName = tostring(catName or "")
      if expName == "" or catName == "" then return end
      if type(GetUISetting) ~= "function" or type(SetUISetting) ~= "function" then return end
      local o = GetRulesCategoryCollapsed()
      o[CatKey(expName, catName)] = collapsed and true or nil
      SetUISetting("rulesCatCollapsed", o)
    end

    local displayItems = {}
    if view ~= "trash" then
      local groups = {}
      local expOrder = {}
      local seen = {}
      local collapsedMap = GetRulesExpansionCollapsed()

      local function ExpansionID(rule, src)
        if type(rule) == "table" then
          local n = tonumber(rule._expansionID)
          if n ~= nil then return n end
        end
        if src == "custom" then return 9999 end
        return 0
      end

      for i = 1, #list do
        local r = list[i]
        local src = (view == "defaults") and "default" or (view == "custom") and "custom" or ((sourceOf and sourceOf[r]) or "custom")
        local expName = RuleExpansionName(r, src)
        local g = groups[expName]
        if not g then
          g = { id = ExpansionID(r, src), items = {} }
          groups[expName] = g
        end
        g.items[#g.items + 1] = { rule = r, src = src }
        if not seen[expName] then
          seen[expName] = true
          expOrder[#expOrder + 1] = expName
        end
      end

      table.sort(expOrder, function(a, b)
        local ga = groups[a]
        local gb = groups[b]
        local ia = (ga and ga.id) or 0
        local ib = (gb and gb.id) or 0
        -- Reverse expansion order: EV first, then 12..01.
        local ra = ia
        local rb = ib
        if tostring(a) == "Weekly / Events" then ra = 10000 end
        if tostring(b) == "Weekly / Events" then rb = 10000 end
        if tostring(a) == "Custom" then ra = -10000 end
        if tostring(b) == "Custom" then rb = -10000 end
        if ra ~= rb then return ra > rb end
        return tostring(a) > tostring(b)
      end)

      local catCollapsedMap = GetRulesCategoryCollapsed()

      local function CategoryPriority(cat)
        cat = tostring(cat or "")
        if cat == "Quest" then return 1 end
        if cat == "Item" then return 2 end
        if cat == "Spell" then return 3 end
        if cat == "Event" then return 4 end
        if cat == "Aura" then return 5 end
        if cat == "Location" then return 6 end
        if cat == "Other" then return 99 end
        return 50
      end

      for _, expName in ipairs(expOrder) do
        local g = groups[expName]
        local isCollapsed = (type(collapsedMap) == "table" and collapsedMap[expName] == true) or false
        displayItems[#displayItems + 1] = {
          kind = "header",
          expName = expName,
          expID = g and g.id or 0,
          count = g and #g.items or 0,
          collapsed = isCollapsed,
        }
        if not isCollapsed and g and type(g.items) == "table" then
          local cats = {}
          local catOrder = {}
          local catSeen = {}
          for ii = 1, #g.items do
            local entry = g.items[ii]
            local rr = (type(entry) == "table") and entry.rule or nil
            local src = (type(entry) == "table") and entry.src or nil
            local eff = (src == "default") and GetEffectiveDefaultRule(rr) or rr
            local cat = RuleCategory(eff)
            if type(cat) ~= "string" or cat == "" then cat = "Other" end
            local cg = cats[cat]
            if not cg then
              cg = { items = {} }
              cats[cat] = cg
            end
            cg.items[#cg.items + 1] = entry
            if not catSeen[cat] then
              catSeen[cat] = true
              catOrder[#catOrder + 1] = cat
            end
          end

          table.sort(catOrder, function(a, b)
            local pa = CategoryPriority(a)
            local pb = CategoryPriority(b)
            if pa ~= pb then return pa < pb end
            return tostring(a) < tostring(b)
          end)

          for _, catName in ipairs(catOrder) do
            local cg = cats[catName]
            local isCatCollapsed = (type(catCollapsedMap) == "table") and (catCollapsedMap[CatKey(expName, catName)] == true) or false
            displayItems[#displayItems + 1] = {
              kind = "catHeader",
              expName = expName,
              catName = catName,
              count = cg and cg.items and #cg.items or 0,
              collapsed = isCatCollapsed,
            }

            if not isCatCollapsed and cg and type(cg.items) == "table" then
              for jj = 1, #cg.items do
                local entry = cg.items[jj]
                if type(entry) == "table" and type(entry.rule) == "table" then
                  displayItems[#displayItems + 1] = { kind = "rule", rule = entry.rule, expName = expName, catName = catName }
                end
              end
            end
          end
        end
      end
    else
      for i = 1, #list do
        displayItems[#displayItems + 1] = { kind = "rule", rule = list[i], expName = "Trash", catName = "Trash" }
      end
    end

    local content = optionsFrame._rulesContent
    local rows = optionsFrame._ruleRows
    if not (content and rows) then return end

    if optionsFrame._rulesScroll and content then
      local w = tonumber(optionsFrame._rulesScroll:GetWidth() or 0) or 0
      content:SetWidth(math.max(1, w - 28))
    end
    content:SetHeight(math.max(1, #displayItems * rowH))

    local zebraA = SafeZebraAlpha()

    local displayByID = {}
    for _, def in ipairs((type(GetEffectiveFrames) == "function" and GetEffectiveFrames()) or {}) do
      if type(def) == "table" and def.id then
        local id = tostring(def.id)
        displayByID[id] = (type(GetFrameDisplayNameByID) == "function") and GetFrameDisplayNameByID(id) or id
      end
    end

    local function FindCustomIndex(rule)
      local custom = (type(GetCustomRules) == "function") and GetCustomRules() or {}
      for ci, cr in ipairs(custom) do
        if cr == rule then return ci end
      end
      return nil
    end

    local function FindTrashIndex(rule)
      local trash = (type(GetCustomRulesTrash) == "function") and GetCustomRulesTrash() or {}
      for ti, tr in ipairs(trash) do
        if tr == rule then return ti end
      end
      return nil
    end

    local function MoveCustomByIndex(ci, delta)
      local custom = (type(GetCustomRules) == "function") and GetCustomRules() or {}
      if type(ci) ~= "number" then return end
      local ni = ci + delta
      if ni < 1 or ni > #custom then return end
      custom[ci], custom[ni] = custom[ni], custom[ci]
      if RefreshAll then RefreshAll() end
      RefreshRulesListImpl()
    end

    local function DisableMoveButtons(row)
      row.up:Show(); row.down:Show()
      row.up:SetEnabled(false)
      row.down:SetEnabled(false)
      row.up:SetScript("OnClick", nil)
      row.down:SetScript("OnClick", nil)
    end

    for i = 1, #displayItems do
      local item = displayItems[i]
      local r = (type(item) == "table" and item.kind == "rule") and item.rule or nil
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
        -- Positioned after the move buttons (up/down).

        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.text:SetPoint("LEFT", row.toggle, "RIGHT", 4, 0)
        row.text:SetJustifyH("LEFT")
        if row.text.SetMaxLines then row.text:SetMaxLines(1) end
        if row.text.SetWordWrap then row.text:SetWordWrap(false) end
        if row.text.SetNonSpaceWrap then row.text:SetNonSpaceWrap(false) end

        row.headerHit = CreateFrame("Button", nil, row)
        row.headerHit:SetAllPoints(row)
        row.headerHit:SetAlpha(0.01)
        row.headerHit:EnableMouse(true)
        row.headerHit:Hide()

        row.frameDrop = CreateFrame("Frame", nil, row, "UIDropDownMenuTemplate")
        if HideDropDownMenuArt then HideDropDownMenuArt(row.frameDrop) end
        row.frameDrop:SetAlpha(0.85)

        row.frameDropHit = CreateFrame("Button", nil, row)
        row.frameDropHit:EnableMouse(true)
        row.frameDropHit:SetAlpha(0.01)

        row.action = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.action:SetSize(52, 18)

        row.up = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.up:SetSize(16, 16)
        row.up:SetText("")
        row.up:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
        row.up:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Down")
        row.up:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Highlight")
        row.up:SetDisabledTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Disabled")

        row.down = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.down:SetSize(16, 16)
        row.down:SetText("")
        row.down:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
        row.down:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Down")
        row.down:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Highlight")
        row.down:SetDisabledTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Disabled")

        row.del = CreateFrame("Button", nil, row, "UIPanelCloseButton")
        row.del:SetSize(20, 20)

        -- Right side actions (X, Edit, then frame dropdown).
        row.del:SetPoint("RIGHT", 0, 0)
        row.action:SetPoint("RIGHT", row.del, "LEFT", -2, 0)

        row.frameDrop:SetPoint("RIGHT", row.action, "LEFT", 0, -2)
        row._frameDropW = 100
        if UDDM_SetWidth then UDDM_SetWidth(row.frameDrop, row._frameDropW) end

        -- Right-align the dropdown text (the arrow is hidden, so this looks cleaner).
        do
          local just = _G and rawget(_G, "UIDropDownMenu_SetJustifyText")
          if type(just) == "function" then
            just(row.frameDrop, "RIGHT")
          end
          local t = row.frameDrop and rawget(row.frameDrop, "Text")
          if t and t.SetJustifyH then t:SetJustifyH("RIGHT") end
        end

        -- Remove the dropdown arrow/button; clicking the label still opens the menu.
        do
          local btn = row.frameDrop and rawget(row.frameDrop, "Button")
          if btn and btn.Hide then btn:Hide() end
          if btn and btn.EnableMouse then btn:EnableMouse(false) end
        end

        -- Anchor the drop-down menu below the dropdown so it opens down (not sideways).
        row.frameDropAnchor = CreateFrame("Frame", nil, row)
        row.frameDropAnchor:SetSize(1, 1)
        row.frameDropAnchor:SetPoint("TOPLEFT", row.frameDrop, "BOTTOMLEFT", 0, 0)

        row.frameDropHit:SetPoint("TOPLEFT", row.frameDrop, "TOPLEFT", 0, -2)
        row.frameDropHit:SetPoint("BOTTOMRIGHT", row.frameDrop, "BOTTOMRIGHT", 0, 2)

        -- Left side order controls before enable checkbox.
        row.up:SetPoint("LEFT", row, "LEFT", 0, 0)
        row.down:SetPoint("LEFT", row.up, "RIGHT", 2, 0)
        row.toggle:SetPoint("LEFT", row.down, "RIGHT", 2, 0)

        row.text:SetPoint("RIGHT", row.frameDrop, "LEFT", -2, 0)

        rows[i] = row
      end

      row:SetPoint("TOPLEFT", 0, -(i - 1) * rowH)
      row:SetPoint("TOPRIGHT", 0, -(i - 1) * rowH)

      local kind = (type(item) == "table") and tostring(item.kind or "") or ""
      if kind == "header" then
        local expName = tostring(item.expName or "")
        local count = tonumber(item.count or 0) or 0
        local isCollapsed = item.collapsed and true or false

        if row.headerHit then
          row.headerHit:Show()
          row.headerHit:SetScript("OnClick", function()
            SetExpansionCollapsed(expName, not isCollapsed)
            RefreshRulesListImpl()
          end)
        end

        if row.up then row.up:Hide() end
        if row.down then row.down:Hide() end
        if row.toggle then row.toggle:Hide() end
        if row.frameDrop then row.frameDrop:Hide() end
        if row.frameDropHit then row.frameDropHit:Hide() end
        if row.action then row.action:Hide() end
        if row.del then row.del:Hide() end

        if row.bg then
          if row.bg.SetColorTexture then
            row.bg:SetColorTexture(0.2, 0.7, 1.0, 0.10)
          elseif row.bg.SetVertexColor then
            row.bg:SetVertexColor(0.2, 0.7, 1.0, 0.10)
          end
          row.bg:Show()
        end

        if row.text then
          row.text:SetFontObject("GameFontNormal")
          row.text:ClearAllPoints()
          row.text:SetPoint("LEFT", row, "LEFT", 4, 0)
          row.text:SetPoint("RIGHT", row, "RIGHT", -4, 0)
          local prefix = isCollapsed and "+ " or "- "
          row.text:SetText(prefix .. expName .. " (" .. tostring(count) .. ")")
          row.text:Show()
        end
      elseif kind == "catHeader" then
        local expName = tostring(item.expName or "")
        local catName = tostring(item.catName or "")
        local count = tonumber(item.count or 0) or 0
        local isCollapsed = item.collapsed and true or false

        if row.headerHit then
          row.headerHit:Show()
          row.headerHit:SetScript("OnClick", function()
            SetCategoryCollapsed(expName, catName, not isCollapsed)
            RefreshRulesListImpl()
          end)
        end

        if row.up then row.up:Hide() end
        if row.down then row.down:Hide() end
        if row.toggle then row.toggle:Hide() end
        if row.frameDrop then row.frameDrop:Hide() end
        if row.frameDropHit then row.frameDropHit:Hide() end
        if row.action then row.action:Hide() end
        if row.del then row.del:Hide() end

        if row.bg then
          if row.bg.SetColorTexture then
            row.bg:SetColorTexture(1, 1, 1, 0.06)
          elseif row.bg.SetVertexColor then
            row.bg:SetVertexColor(1, 1, 1, 0.06)
          end
          row.bg:Show()
        end

        if row.text then
          row.text:SetFontObject("GameFontDisableSmall")
          row.text:ClearAllPoints()
          row.text:SetPoint("LEFT", row, "LEFT", 18, 0)
          row.text:SetPoint("RIGHT", row, "RIGHT", -4, 0)
          local prefix = isCollapsed and "+ " or "- "
          row.text:SetText(prefix .. catName .. " (" .. tostring(count) .. ")")
          row.text:Show()
        end
      else
        if row.headerHit then
          row.headerHit:Hide()
          row.headerHit:SetScript("OnClick", nil)
        end

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
          if UDDM_SetText then
            UDDM_SetText(row.frameDrop, primary and (displayByID[primary] or primary) or "(none)")
          end

          if UDDM_Initialize and UDDM_CreateInfo and UDDM_AddButton then
            UDDM_Initialize(row.frameDrop, function(_, level)
              if level ~= 1 then return end
              for _, id in ipairs(GetSortedFrameIDs(displayByID)) do
                local info = UDDM_CreateInfo()
                info.text = displayByID[id] or id
                info.checked = (primary == id)
                info.func = function()
                  SetRulePrimaryFrame(r, displayRule, id, src)
                  if RefreshAll then RefreshAll() end
                  RefreshRulesListImpl()
                end
                UDDM_AddButton(info)
              end
            end)
          end

          if row.frameDropHit then
            row.frameDropHit:SetScript("OnClick", function()
              local toggle = _G and rawget(_G, "ToggleDropDownMenu")
              if toggle then
                toggle(1, nil, row.frameDrop, row.frameDropAnchor or row.frameDrop, 0, 0)
              end
            end)
          end
        end
      end

      local disabled = (type(IsRuleDisabled) == "function") and IsRuleDisabled(r) or false
      row.toggle:SetChecked(not disabled)
      if disabled then
        row.text:SetFontObject("GameFontDisableSmall")
      else
        row.text:SetFontObject("GameFontHighlightSmall")
      end

      local function FactionColor(rr)
        local fac = (type(rr) == "table") and tostring(rr.faction or "") or ""
        if fac == "Alliance" then return "|cff3399ff" end
        if fac == "Horde" then return "|cffff3333" end
        return "|cffffd100"
      end

      local isDB = (src == "default" or src == "auto")
      local baseText = FormatRuleText(displayRule)
      if isDB and type(displayRule) == "table" and type(displayRule.item) == "table" and displayRule.item.itemID ~= nil then
        baseText = baseText .. " *"
      end

      local c = FactionColor(displayRule)
      if src == "trash" then c = "|cffff3333" end

      local editedMark = (src == "default" and IsDefaultRuleEdited(r)) and "|cff00ff00*|r " or ""

      row.text:ClearAllPoints()
      if view == "trash" then
        row.text:SetPoint("LEFT", row.down, "RIGHT", 4, 0)
      else
        row.text:SetPoint("LEFT", row.toggle, "RIGHT", 4, 0)
      end
      row.text:SetPoint("RIGHT", row.frameDrop, "LEFT", -2, 0)

      if row.text.SetWidth and content and content.GetWidth then
        local totalW = tonumber(content:GetWidth() or 0) or 0
        local dropW = (type(row) == "table" and tonumber(row._frameDropW or 0) or 0) or 0
        if dropW <= 0 then dropW = 110 end
        -- Left side: up/down + (optional) checkbox.
        local leftPad = (view == "trash") and (18 + 2 + 18 + 4) or (18 + 2 + 18 + 2 + 18 + 4)
        local rightPad = 2 + dropW + 4
        local maxW = totalW - leftPad - rightPad
        if maxW < 50 then maxW = 50 end
        row.text:SetWidth(maxW)
        SetRowRuleText(row, editedMark .. c, baseText, "|r", maxW)
      else
        row.text:SetText(editedMark .. c .. baseText .. "|r")
      end

      local idx = i
      local thisExpName = tostring((type(item) == "table" and item.expName) or "")
      if thisExpName == "" then
        thisExpName = RuleExpansionName(r, src)
      end
      local thisCatName = tostring((type(item) == "table" and item.catName) or "")
      if thisCatName == "" then
        thisCatName = RuleCategory(displayRule)
      end
      if view == "trash" then
        row.toggle:Hide()
      else
        row.toggle:Show()
        row.toggle:SetScript("OnClick", function()
          if type(ToggleRuleDisabled) == "function" then
            ToggleRuleDisabled(r)
          end
          if RefreshAll then RefreshAll() end
          RefreshRulesListImpl()
        end)
      end

      local function NeighborRule(delta)
        local di = tonumber(delta) or 0
        if di == 0 then return nil end
        local step = (di > 0) and 1 or -1
        local j = idx + step
        while j >= 1 and j <= #displayItems do
          local it = displayItems[j]
          if type(it) == "table" and it.kind == "rule" and tostring(it.expName or "") == thisExpName and tostring(it.catName or "") == thisCatName then
            return it.rule
          end
          j = j + step
        end
        return nil
      end

      local function ApplyRulesTabReorderButtons()
        if view == "trash" then
          DisableMoveButtons(row)
          return
        end

        local k = RuleKey(r)
        if not k then
          DisableMoveButtons(row)
          return
        end

        local prev = NeighborRule(-1)
        local next = NeighborRule(1)
        local prevKey = prev and RuleKey(prev) or nil
        local nextKey = next and RuleKey(next) or nil

        row.up:Show(); row.down:Show()
        row.up:SetEnabled(prevKey ~= nil)
        row.down:SetEnabled(nextKey ~= nil)

        row.up:SetScript("OnClick", function()
          local prev2 = NeighborRule(-1)
          local k2 = prev2 and RuleKey(prev2) or nil
          if not k2 then return end
          if SwapKeysInOrder(k, k2) then
            RefreshRulesListImpl()
          end
        end)
        row.down:SetScript("OnClick", function()
          local next2 = NeighborRule(1)
          local k2 = next2 and RuleKey(next2) or nil
          if not k2 then return end
          if SwapKeysInOrder(k, k2) then
            RefreshRulesListImpl()
          end
        end)
      end

      if view == "custom" then
        ApplyRulesTabReorderButtons()
        row.action:SetText("Edit")
        row.action:Show()
        row.action:SetScript("OnClick", function()
          local ci = FindCustomIndex(r)
          if not ci then return end
          if OpenCustomRuleInTab then OpenCustomRuleInTab(ci) end
        end)

        row.del:Show()
        row.del:SetScript("OnClick", function()
          if not (IsShiftKeyDown and IsShiftKeyDown()) then
            Print("Hold SHIFT and click X to move a rule to Trash.")
            return
          end
          local ruleToTrash = r
          if type(ruleToTrash) ~= "table" then return end
          local ci = FindCustomIndex(ruleToTrash)
          if not ci then return end
          local custom = (type(GetCustomRules) == "function") and GetCustomRules() or {}
          local trash = (type(GetCustomRulesTrash) == "function") and GetCustomRulesTrash() or {}
          trash[#trash + 1] = custom[ci]
          table.remove(custom, ci)
          if RefreshAll then RefreshAll() end
          RefreshRulesListImpl()
          Print("Moved custom rule to Trash.")
        end)
      elseif view == "defaults" then
        ApplyRulesTabReorderButtons()

        row.action:SetText("Edit")
        row.action:Show()
        row.action:SetScript("OnClick", function()
          local base = r
          if type(base) ~= "table" then return end
          if OpenDefaultRuleInTab then OpenDefaultRuleInTab(base) end
        end)

        if IsDefaultRuleEdited(r) then
          row.del:Show()
          row.del:SetScript("OnClick", function()
            if not (IsShiftKeyDown and IsShiftKeyDown()) then
              Print("Hold SHIFT and click X to reset this default rule edit.")
              return
            end
            local base = r
            local key = RuleKey(base)
            if not key or key == "" then return end
            local edits = (type(GetDefaultRuleEdits) == "function") and (GetDefaultRuleEdits() or {}) or {}
            edits[key] = nil
            if RefreshAll then RefreshAll() end
            RefreshRulesListImpl()
            Print("Reset default rule edits.")
          end)
        else
          row.del:Hide()
        end
      elseif view == "trash" then
        DisableMoveButtons(row)
        row.action:SetText("Restore")
        row.action:Show()
        row.action:SetScript("OnClick", function()
          local trash = (type(GetCustomRulesTrash) == "function") and GetCustomRulesTrash() or {}
          local ti = FindTrashIndex(r)
          local r2 = ti and trash[ti] or nil
          if type(r2) ~= "table" then return end
          local restored = DeepCopyValue and DeepCopyValue(r2) or r2
          if type(EnsureUniqueKeyForCustomRule) == "function" then
            EnsureUniqueKeyForCustomRule(restored)
          end
          local custom = (type(GetCustomRules) == "function") and GetCustomRules() or {}
          custom[#custom + 1] = restored
          if ti then table.remove(trash, ti) end
          if RefreshAll then RefreshAll() end
          RefreshRulesListImpl()
          Print("Restored custom rule.")
        end)

        row.del:Show()
        row.del:SetScript("OnClick", function()
          if not (IsShiftKeyDown and IsShiftKeyDown()) then
            Print("Hold SHIFT and click X to delete permanently.")
            return
          end
          local trash = (type(GetCustomRulesTrash) == "function") and GetCustomRulesTrash() or {}
          local ti = FindTrashIndex(r)
          if ti then table.remove(trash, ti) end
          RefreshRulesListImpl()
          Print("Deleted trashed rule permanently.")
        end)
      else
        local src2 = (sourceOf and sourceOf[r]) or "custom"
        if src2 == "default" then
          ApplyRulesTabReorderButtons()
          row.action:SetText("Edit")
          row.action:Show()
          row.action:SetScript("OnClick", function()
            local base = r
            if type(base) ~= "table" then return end
            if OpenDefaultRuleInTab then OpenDefaultRuleInTab(base) end
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
              local edits = (type(GetDefaultRuleEdits) == "function") and (GetDefaultRuleEdits() or {}) or {}
              edits[key] = nil
              if RefreshAll then RefreshAll() end
              RefreshRulesListImpl()
              Print("Reset default rule edits.")
            end)
          else
            row.del:Hide()
          end
        elseif src2 == "custom" then
          ApplyRulesTabReorderButtons()
          row.action:SetText("Edit")
          row.action:Show()
          row.action:SetScript("OnClick", function()
            local ci = FindCustomIndex(r)
            if not ci then return end
            if OpenCustomRuleInTab then OpenCustomRuleInTab(ci) end
          end)

          row.del:Show()
          row.del:SetScript("OnClick", function()
            if not (IsShiftKeyDown and IsShiftKeyDown()) then
              Print("Hold SHIFT and click X to move a rule to Trash.")
              return
            end
            local ci = FindCustomIndex(r)
            if not ci then return end
            local custom = (type(GetCustomRules) == "function") and GetCustomRules() or {}
            local trash = (type(GetCustomRulesTrash) == "function") and GetCustomRulesTrash() or {}
            trash[#trash + 1] = custom[ci]
            table.remove(custom, ci)
            if RefreshAll then RefreshAll() end
            RefreshRulesListImpl()
            Print("Moved custom rule to Trash.")
          end)
        else
          DisableMoveButtons(row)
          row.action:Hide()
          row.del:Hide()
        end
      end

      end

      row:Show()
    end

    for i = #displayItems + 1, #rows do
      if rows[i] then rows[i]:Hide() end
    end
  end

  optionsFrame._refreshRulesList = RefreshRulesListImpl
  if type(ctx.SetRefreshRulesList) == "function" then
    ctx.SetRefreshRulesList(RefreshRulesListImpl)
  end
end
