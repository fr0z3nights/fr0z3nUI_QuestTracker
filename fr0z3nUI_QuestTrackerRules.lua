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
      local op = rr.playerLevelOp
      local lvl = tonumber(rr.playerLevel)
      if op and lvl and lvl > 0 then
        return string.format(" [Lvl %s %d]", tostring(op), lvl)
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

    local list
    local sourceOf = nil
    if view == "defaults" then
      list = ns.rules or {}
    elseif view == "trash" then
      list = (type(GetCustomRulesTrash) == "function") and GetCustomRulesTrash() or {}
    elseif view == "custom" then
      list = (type(GetCustomRules) == "function") and GetCustomRules() or {}
    else
      list = {}
      sourceOf = {}
      for _, r in ipairs(ns.rules or {}) do
        list[#list + 1] = r
        sourceOf[r] = "default"
      end
      for _, r in ipairs((type(GetCustomRules) == "function") and GetCustomRules() or {}) do
        list[#list + 1] = r
        sourceOf[r] = "custom"
      end
    end

    local content = optionsFrame._rulesContent
    local rows = optionsFrame._ruleRows
    if not (content and rows) then return end

    if optionsFrame._rulesScroll and content then
      local w = tonumber(optionsFrame._rulesScroll:GetWidth() or 0) or 0
      content:SetWidth(math.max(1, w - 28))
    end
    content:SetHeight(math.max(1, #list * rowH))

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

        row.down = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.down:SetSize(18, 18)
        row.down:SetText("v")

        row.action:SetPoint("RIGHT", -62, 0)

        row.del = CreateFrame("Button", nil, row, "UIPanelCloseButton")
        row.del:SetSize(20, 20)
        row.del:SetPoint("RIGHT", 6, 0)

        row.down:SetPoint("RIGHT", row.del, "LEFT", -2, 0)
        row.up:SetPoint("RIGHT", row.down, "LEFT", -2, 0)

        row.frameDrop:SetPoint("RIGHT", row.action, "LEFT", 0, -2)
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
                toggle(1, nil, row.frameDrop, row.frameDrop, 0, 0)
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
          if type(ToggleRuleDisabled) == "function" then
            ToggleRuleDisabled(r)
          end
          if RefreshAll then RefreshAll() end
          RefreshRulesListImpl()
        end)
      end

      if view == "custom" then
        row.up:Show(); row.down:Show()
        row.action:SetText("Edit")
        row.action:Show()
        row.action:SetScript("OnClick", function()
          local ci = FindCustomIndex(list[idx])
          if not ci then return end
          if OpenCustomRuleInTab then OpenCustomRuleInTab(ci) end
        end)

        do
          local ci = FindCustomIndex(list[idx])
          local n = #((type(GetCustomRules) == "function" and GetCustomRules()) or {})
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

        row.del:Show()
        row.del:SetScript("OnClick", function()
          if not (IsShiftKeyDown and IsShiftKeyDown()) then
            Print("Hold SHIFT and click X to move a rule to Trash.")
            return
          end
          local trash = (type(GetCustomRulesTrash) == "function") and GetCustomRulesTrash() or {}
          trash[#trash + 1] = list[idx]
          table.remove(list, idx)
          if RefreshAll then RefreshAll() end
          RefreshRulesListImpl()
          Print("Moved custom rule to Trash.")
        end)
      elseif view == "defaults" then
        DisableMoveButtons(row)
        row.action:SetText("Edit")
        row.action:Show()
        row.action:SetScript("OnClick", function()
          local base = list[idx]
          if type(base) ~= "table" then return end
          if OpenDefaultRuleInTab then OpenDefaultRuleInTab(base) end
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
          local r2 = trash[idx]
          if type(r2) ~= "table" then return end
          local restored = DeepCopyValue and DeepCopyValue(r2) or r2
          if type(EnsureUniqueKeyForCustomRule) == "function" then
            EnsureUniqueKeyForCustomRule(restored)
          end
          local custom = (type(GetCustomRules) == "function") and GetCustomRules() or {}
          custom[#custom + 1] = restored
          table.remove(trash, idx)
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
          table.remove(list, idx)
          RefreshRulesListImpl()
          Print("Deleted trashed rule permanently.")
        end)
      else
        local src2 = (sourceOf and sourceOf[r]) or "custom"
        if src2 == "default" then
          DisableMoveButtons(row)
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
          row.up:Show(); row.down:Show()
          row.action:SetText("Edit")
          row.action:Show()
          row.action:SetScript("OnClick", function()
            local ci = FindCustomIndex(r)
            if not ci then return end
            if OpenCustomRuleInTab then OpenCustomRuleInTab(ci) end
          end)

          do
            local ci = FindCustomIndex(r)
            local n = #((type(GetCustomRules) == "function" and GetCustomRules()) or {})
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

      row:Show()
    end

    for i = #list + 1, #rows do
      if rows[i] then rows[i]:Hide() end
    end
  end

  optionsFrame._refreshRulesList = RefreshRulesListImpl
  if type(ctx.SetRefreshRulesList) == "function" then
    ctx.SetRefreshRulesList(RefreshRulesListImpl)
  end
end
