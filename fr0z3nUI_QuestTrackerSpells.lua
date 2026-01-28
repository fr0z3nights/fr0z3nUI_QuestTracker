local addonName, ns = ...

ns.FQTOptionsPanels = ns.FQTOptionsPanels or {}

function ns.FQTOptionsPanels.BuildSpells(ctx)
  if type(ctx) ~= "table" then return end

  local panels = ctx.panels
  if not (panels and panels.spells) then return end

  local Print = ctx.Print or function(...) end
  local CreateFrame = ctx.CreateFrame or CreateFrame

  local UseModernMenuDropDown = ctx.UseModernMenuDropDown
  local GetEffectiveFrames = ctx.GetEffectiveFrames
  local GetFrameDisplayNameByID = ctx.GetFrameDisplayNameByID

  local CreateQuickColorPalette = ctx.CreateQuickColorPalette
  local SetCheckButtonLabel = ctx.SetCheckButtonLabel

  local GetCustomRules = ctx.GetCustomRules
  local DeepCopyValue = ctx.DeepCopyValue
  local GetDefaultRuleEdits = ctx.GetDefaultRuleEdits

  local CreateAllFrames = ctx.CreateAllFrames
  local RefreshAll = ctx.RefreshAll
  local RefreshRulesList = ctx.RefreshRulesList

  local GetKeepEditFormOpen = ctx.GetKeepEditFormOpen
  local SelectTab = ctx.SelectTab

  local AddPlaceholder = ctx.AddPlaceholder
  local HideInputBoxTemplateArt = ctx.HideInputBoxTemplateArt
  local AttachLocationIDTooltip = ctx.AttachLocationIDTooltip

  local GetFontChoices = ctx.GetFontChoices
  local GetFontChoiceLabel = ctx.GetFontChoiceLabel

  local UDDM_SetWidth = ctx.UDDM_SetWidth
  local UDDM_SetText = ctx.UDDM_SetText
  local UDDM_Initialize = ctx.UDDM_Initialize
  local UDDM_CreateInfo = ctx.UDDM_CreateInfo
  local UDDM_AddButton = ctx.UDDM_AddButton

  local GetRuleExpansionChoices = ctx.GetRuleExpansionChoices
  local GetRuleCreateExpansion = ctx.GetRuleCreateExpansion
  local SetRuleCreateExpansion = ctx.SetRuleCreateExpansion
  local SyncRuleCreateExpansionDrops = ctx.SyncRuleCreateExpansionDrops

  local pSpells = panels.spells

  local spellsTitle = pSpells:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  spellsTitle:SetPoint("TOPLEFT", 12, -40)
  spellsTitle:SetText("Spells")

  -- Expansion selector (stamped onto new/edited rules as _expansionID/_expansionName)
  local expLabel = pSpells:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  expLabel:SetPoint("TOPRIGHT", pSpells, "TOPRIGHT", -12, -40)
  expLabel:SetText("Expansion")

  local expDrop = CreateFrame("Frame", nil, pSpells, "UIDropDownMenuTemplate")
  expDrop:SetPoint("TOPRIGHT", pSpells, "TOPRIGHT", -6, -54)
  if UDDM_SetWidth then UDDM_SetWidth(expDrop, 180) end
  if UDDM_SetText then UDDM_SetText(expDrop, "") end
  pSpells._expansionDrop = expDrop

  local function ResolveExpansionNameByID(id)
    id = tonumber(id)
    if not id then return nil end
    local list = (type(GetRuleExpansionChoices) == "function") and GetRuleExpansionChoices() or {}
    for _, e in ipairs(list) do
      if type(e) == "table" and tonumber(e.id) == id and type(e.name) == "string" and e.name ~= "" then
        return e.name
      end
    end
    return nil
  end

  function pSpells:_syncRuleCreateExpansion()
    local id, name = nil, nil
    if type(GetRuleCreateExpansion) == "function" then
      id, name = GetRuleCreateExpansion()
    end
    if not name and id then
      name = ResolveExpansionNameByID(id)
    end
    local label = name or "Weekly"
    if UDDM_SetText and expDrop then UDDM_SetText(expDrop, label) end
  end

  if type(SyncRuleCreateExpansionDrops) == "function" then
    SyncRuleCreateExpansionDrops()
  elseif pSpells._syncRuleCreateExpansion then
    pSpells:_syncRuleCreateExpansion()
  end

  local spellsNameBox = CreateFrame("EditBox", nil, pSpells, "InputBoxTemplate")
  spellsNameBox:SetSize(530, 20)
  spellsNameBox:SetPoint("TOPLEFT", 12, -70)
  spellsNameBox:SetAutoFocus(false)
  spellsNameBox:SetText("")
  spellsNameBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  spellsNameBox:SetTextInsets(6, 6, 0, 0)
  if AddPlaceholder then AddPlaceholder(spellsNameBox, "Spell Name") end
  if HideInputBoxTemplateArt then HideInputBoxTemplateArt(spellsNameBox) end

  local spellsInfoScroll = CreateFrame("ScrollFrame", nil, pSpells, "UIPanelScrollFrameTemplate")
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
  if AddPlaceholder then AddPlaceholder(spellsInfoBox, "Spell Info") end

  local classLabel = pSpells:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  classLabel:SetPoint("TOPLEFT", 12, -146)
  classLabel:SetText("Class")

  local classDrop = CreateFrame("Frame", nil, pSpells, "UIDropDownMenuTemplate")
  classDrop:SetPoint("TOPLEFT", -8, -174)
  if UDDM_SetWidth then UDDM_SetWidth(classDrop, 160) end
  if UDDM_SetText then UDDM_SetText(classDrop, "None") end
  panels.spells._class = nil
  panels.spells._classes = panels.spells._classes or {}

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

  local knownLabel = pSpells:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  knownLabel:SetPoint("TOPLEFT", 180, -146)
  knownLabel:SetText("Spell Known")

  local knownBox = CreateFrame("EditBox", nil, pSpells, "InputBoxTemplate")
  knownBox:SetSize(90, 20)
  knownBox:SetPoint("TOPLEFT", 180, -162)
  knownBox:SetAutoFocus(false)
  knownBox:SetNumeric(true)
  knownBox:SetText("0")

  local notKnownLabel = pSpells:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  notKnownLabel:SetPoint("TOPLEFT", 280, -146)
  notKnownLabel:SetText("Not Spell Known")

  local notKnownBox = CreateFrame("EditBox", nil, pSpells, "InputBoxTemplate")
  notKnownBox:SetSize(90, 20)
  notKnownBox:SetPoint("TOPLEFT", 280, -162)
  notKnownBox:SetAutoFocus(false)
  notKnownBox:SetNumeric(true)
  notKnownBox:SetText("0")

  local locLabel = pSpells:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  locLabel:SetPoint("TOPLEFT", 380, -146)
  locLabel:SetText("LocationID (uiMapID)")

  local locBox = CreateFrame("EditBox", nil, pSpells, "InputBoxTemplate")
  locBox:SetSize(90, 20)
  locBox:SetPoint("TOPLEFT", 380, -162)
  locBox:SetAutoFocus(false)
  locBox:SetText("0")
  if AttachLocationIDTooltip then AttachLocationIDTooltip(locBox) end

  local notInGroupCheck = CreateFrame("CheckButton", nil, pSpells, "UICheckButtonTemplate")
  notInGroupCheck:SetPoint("TOPLEFT", 12, -198)
  if SetCheckButtonLabel then SetCheckButtonLabel(notInGroupCheck, "Not in group") end
  notInGroupCheck:SetChecked(false)

  local spellsRestedOnlyCheck = CreateFrame("CheckButton", nil, pSpells, "UICheckButtonTemplate")
  spellsRestedOnlyCheck:SetPoint("LEFT", notInGroupCheck, "RIGHT", 110, 0)
  if SetCheckButtonLabel then SetCheckButtonLabel(spellsRestedOnlyCheck, "Rested") end
  spellsRestedOnlyCheck:SetChecked(false)

  local spellsMissingProfCheck = CreateFrame("CheckButton", nil, pSpells, "UICheckButtonTemplate")
  spellsMissingProfCheck:SetPoint("TOPLEFT", 12, -218)
  if SetCheckButtonLabel then SetCheckButtonLabel(spellsMissingProfCheck, "Prof") end
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

  local spellsLevelLabel = pSpells:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  spellsLevelLabel:SetPoint("TOPLEFT", 180, -202)
  spellsLevelLabel:SetText("Player level")

  local spellsLevelOpDrop = CreateFrame("Frame", nil, pSpells, "UIDropDownMenuTemplate")
  spellsLevelOpDrop:SetPoint("TOPLEFT", 165, -222)
  if UDDM_SetWidth then UDDM_SetWidth(spellsLevelOpDrop, 70) end
  if UDDM_SetText then UDDM_SetText(spellsLevelOpDrop, "Off") end
  panels.spells._playerLevelOp = nil

  local spellsLevelBox = CreateFrame("EditBox", nil, pSpells, "InputBoxTemplate")
  spellsLevelBox:SetSize(50, 20)
  spellsLevelBox:SetPoint("TOPLEFT", 270, -218)
  spellsLevelBox:SetAutoFocus(false)
  spellsLevelBox:SetNumeric(true)
  spellsLevelBox:SetText("0")

  local spellsFrameDrop = CreateFrame("Frame", nil, pSpells, "UIDropDownMenuTemplate")
  spellsFrameDrop:SetPoint("TOPLEFT", -8, -238)
  if UDDM_SetWidth then UDDM_SetWidth(spellsFrameDrop, 160) end
  if UDDM_SetText and GetFrameDisplayNameByID then UDDM_SetText(spellsFrameDrop, GetFrameDisplayNameByID("list1")) end
  panels.spells._targetFrameID = "list1"

  local spellsFactionDrop = CreateFrame("Frame", nil, pSpells, "UIDropDownMenuTemplate")
  spellsFactionDrop:SetPoint("TOPLEFT", 165, -238)
  if UDDM_SetWidth then UDDM_SetWidth(spellsFactionDrop, 140) end
  if UDDM_SetText then UDDM_SetText(spellsFactionDrop, "Both (Off)") end
  panels.spells._faction = nil

  local spellsColorDrop = CreateFrame("Frame", nil, pSpells, "UIDropDownMenuTemplate")
  spellsColorDrop:SetPoint("TOPLEFT", 325, -238)
  if UDDM_SetWidth then UDDM_SetWidth(spellsColorDrop, 140) end
  if UDDM_SetText then UDDM_SetText(spellsColorDrop, "None") end
  panels.spells._color = nil

  local spellsFontLabel = pSpells:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  spellsFontLabel:SetPoint("TOPLEFT", 500, -222)
  spellsFontLabel:SetText("Font")

  local spellsFontDrop = CreateFrame("Frame", nil, pSpells, "UIDropDownMenuTemplate")
  spellsFontDrop:SetPoint("TOPLEFT", 485, -238)
  if UDDM_SetWidth then UDDM_SetWidth(spellsFontDrop, 170) end
  if UDDM_SetText then UDDM_SetText(spellsFontDrop, "Inherit") end
  panels.spells._fontDrop = spellsFontDrop
  panels.spells._fontKey = "inherit"

  local spellsSizeLabel = pSpells:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  spellsSizeLabel:SetPoint("TOPLEFT", 500, -202)
  spellsSizeLabel:SetText("Size")

  local spellsSizeBox = CreateFrame("EditBox", nil, pSpells, "InputBoxTemplate")
  spellsSizeBox:SetSize(50, 20)
  spellsSizeBox:SetPoint("TOPLEFT", 500, -218)
  spellsSizeBox:SetAutoFocus(false)
  spellsSizeBox:SetNumeric(true)
  spellsSizeBox:SetText("0")
  panels.spells._sizeBox = spellsSizeBox

  -- Quick color palette for spell text color
  if CreateQuickColorPalette then
    CreateQuickColorPalette(pSpells, spellsColorDrop, "TOPLEFT", "BOTTOMLEFT", 26, 20, {
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
  end

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

    local function SetFontKey(key)
      key = tostring(key or "inherit")
      if key == "" then key = "inherit" end
      panels.spells._fontKey = key
      local label = (type(GetFontChoiceLabel) == "function") and GetFontChoiceLabel(key) or key
      if UDDM_SetText then UDDM_SetText(spellsFontDrop, label) end
    end

    local modernSpellsExpansion = type(UseModernMenuDropDown) == "function" and UseModernMenuDropDown(expDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Expansion") end
      local choices = (type(GetRuleExpansionChoices) == "function") and GetRuleExpansionChoices() or { { id = -1, name = "Weekly" } }
      for _, e in ipairs(choices) do
        if type(e) == "table" then
          local id, name = e.id, e.name
          local function IsSelected()
            local curID, curName = nil, nil
            if type(GetRuleCreateExpansion) == "function" then
              curID, curName = GetRuleCreateExpansion()
            end
            return (tonumber(curID) == tonumber(id)) or (curName ~= nil and curName == name)
          end
          local function SetSelected()
            if type(SetRuleCreateExpansion) == "function" then
              SetRuleCreateExpansion(id, name)
            end
          end
          if root and root.CreateRadio then
            root:CreateRadio(name or "Weekly", IsSelected, SetSelected)
          elseif root and root.CreateButton then
            root:CreateButton(name or "Weekly", SetSelected)
          end
        end
      end
    end)

    local modernSpellsClass = type(UseModernMenuDropDown) == "function" and UseModernMenuDropDown(classDrop, function(root)
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

    local modernSpellsFrame = type(UseModernMenuDropDown) == "function" and UseModernMenuDropDown(spellsFrameDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Bar / List") end
      for _, def in ipairs((type(GetEffectiveFrames) == "function" and GetEffectiveFrames()) or {}) do
        if type(def) == "table" and def.id and root then
          local id = tostring(def.id)
          local label = (type(GetFrameDisplayNameByID) == "function") and GetFrameDisplayNameByID(id) or id
          if root.CreateRadio then
            root:CreateRadio(label, function() return (panels.spells._targetFrameID == id) end, function()
              panels.spells._targetFrameID = id
              if UDDM_SetText and GetFrameDisplayNameByID then UDDM_SetText(spellsFrameDrop, GetFrameDisplayNameByID(id)) end
            end)
          elseif root.CreateButton then
            root:CreateButton(label, function()
              panels.spells._targetFrameID = id
              if UDDM_SetText and GetFrameDisplayNameByID then UDDM_SetText(spellsFrameDrop, GetFrameDisplayNameByID(id)) end
            end)
          end
        end
      end
    end)

    local modernSpellsFaction = type(UseModernMenuDropDown) == "function" and UseModernMenuDropDown(spellsFactionDrop, function(root)
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

    local modernSpellsColor = type(UseModernMenuDropDown) == "function" and UseModernMenuDropDown(spellsColorDrop, function(root)
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

    local modernSpellsFont = type(UseModernMenuDropDown) == "function" and UseModernMenuDropDown(spellsFontDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Font") end
      local choices = (type(GetFontChoices) == "function") and GetFontChoices() or { { key = "inherit", label = "Inherit" } }
      for _, opt in ipairs(choices) do
        if type(opt) == "table" and opt.key and root then
          local key = tostring(opt.key)
          local label = tostring(opt.label or opt.key)
          if root.CreateRadio then
            root:CreateRadio(label, function() return (panels.spells._fontKey == key) end, function() SetFontKey(key) end)
          elseif root.CreateButton then
            root:CreateButton(label, function() SetFontKey(key) end)
          end
        end
      end
    end)

    local modernSpellsLevelOp = type(UseModernMenuDropDown) == "function" and UseModernMenuDropDown(spellsLevelOpDrop, function(root)
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

    if not modernSpellsExpansion then
      UDDM_Initialize(expDrop, function(self, level)
        local choices = (type(GetRuleExpansionChoices) == "function") and GetRuleExpansionChoices() or { { id = nil, name = "Custom" } }
        for _, e in ipairs(choices) do
          if type(e) == "table" then
            local id, name = e.id, e.name
            local info = UDDM_CreateInfo()
            info.text = name or "Custom"
            info.checked = function()
              local curID, curName = nil, nil
              if type(GetRuleCreateExpansion) == "function" then
                curID, curName = GetRuleCreateExpansion()
              end
              if curID == nil and (curName == nil or curName == "" or curName == "Custom") then
                return (id == nil) and true or false
              end
              return (curID ~= nil and id ~= nil and tonumber(curID) == tonumber(id))
            end
            info.func = function()
              if type(SetRuleCreateExpansion) == "function" then
                if id == nil or name == "Custom" then
                  SetRuleCreateExpansion(nil, nil)
                else
                  SetRuleCreateExpansion(id, name)
                end
              end
            end
            UDDM_AddButton(info)
          end
        end
      end)
    end

    if not modernSpellsFrame then
      UDDM_Initialize(spellsFrameDrop, function(self, level)
        for _, def in ipairs((type(GetEffectiveFrames) == "function" and GetEffectiveFrames()) or {}) do
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

    if not modernSpellsFont then
      UDDM_Initialize(spellsFontDrop, function(self, level)
        local choices = (type(GetFontChoices) == "function") and GetFontChoices() or { { key = "inherit", label = "Inherit" } }
        for _, opt in ipairs(choices) do
          if type(opt) == "table" and opt.key then
            local key = tostring(opt.key)
            local info = UDDM_CreateInfo()
            info.text = tostring(opt.label or opt.key)
            info.checked = (panels.spells._fontKey == key) and true or false
            info.func = function() SetFontKey(key) end
            UDDM_AddButton(info)
          end
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

  local addSpellBtn = CreateFrame("Button", nil, pSpells, "UIPanelButtonTemplate")
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
  panels.spells._fontDrop = spellsFontDrop
  panels.spells._sizeBox = spellsSizeBox
  panels.spells._spellsLevelOpDrop = spellsLevelOpDrop
  panels.spells._spellsLevelBox = spellsLevelBox
  panels.spells._addSpellBtn = addSpellBtn

  local cancelSpellEditBtn = CreateFrame("Button", nil, pSpells, "UIPanelButtonTemplate")
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
    if UDDM_SetText and spellsFrameDrop and GetFrameDisplayNameByID then UDDM_SetText(spellsFrameDrop, GetFrameDisplayNameByID("list1")) end

    panels.spells._faction = nil
    if UDDM_SetText and spellsFactionDrop then UDDM_SetText(spellsFactionDrop, "Both (Off)") end

    panels.spells._color = nil
    if UDDM_SetText and spellsColorDrop then UDDM_SetText(spellsColorDrop, "None") end

    panels.spells._fontKey = "inherit"
    if UDDM_SetText and spellsFontDrop then UDDM_SetText(spellsFontDrop, "Inherit") end
    if spellsSizeBox then spellsSizeBox:SetText("0") end

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
      UpdateSpellFieldsFromID(type(GetKeepEditFormOpen) == "function" and GetKeepEditFormOpen() or false)
    end)
  end
  if notKnownBox then
    notKnownBox:HookScript("OnTextChanged", function(_, userInput)
      if not userInput then return end
      UpdateSpellFieldsFromID(type(GetKeepEditFormOpen) == "function" and GetKeepEditFormOpen() or false)
    end)
  end

  addSpellBtn:SetScript("OnClick", function()
    local targetFrame = tostring(panels.spells._targetFrameID or ""):gsub("%s+", "")
    if targetFrame == "" then targetFrame = "list1" end

    local known = tonumber(knownBox and knownBox:GetText() or "")
    if known and known <= 0 then known = nil end
    local notKnown = tonumber(notKnownBox and notKnownBox:GetText() or "")
    if notKnown and notKnown <= 0 then notKnown = nil end
    if not known and not notKnown then
      Print("Enter Spell Known and/or Not Spell Known.")
      return
    end

    local locText = tostring(locBox and locBox:GetText() or ""):gsub("%s+", "")
    local locationID = (locText ~= "" and locText ~= "0") and locText or nil

    local fontKey = tostring(panels.spells._fontKey or "inherit")
    if fontKey == "" then fontKey = "inherit" end
    local fontSize = (spellsSizeBox and tonumber(spellsSizeBox:GetText() or "")) or 0
    if not fontSize or fontSize < 0 then fontSize = 0 end

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

    local rules = type(GetCustomRules) == "function" and GetCustomRules() or {}

    -- Expansion selection (shared across all rule create tabs)
    local expID, expName = nil, nil
    if type(GetRuleCreateExpansion) == "function" then
      expID, expName = GetRuleCreateExpansion()
    end
    if not expName and expID then expName = ResolveExpansionNameByID(expID) end

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
      rule.font = fontKey
      rule.size = fontSize
      rule.notInGroup = notInGroupCheck:GetChecked() and true or false
      rule.restedOnly = spellsRestedOnlyCheck:GetChecked() and true or false
      rule.missingPrimaryProfessions = spellsMissingProfCheck:GetChecked() and true or false
      rule.locationID = locationID
      rule.spellKnown = known
      rule.notSpellKnown = notKnown

      if expID then
        rule._expansionID = expID
        rule._expansionName = expName
      else
        rule._expansionID = nil
        rule._expansionName = nil
      end

      local op = panels.spells._playerLevelOp
      local lvl = spellsLevelBox and tonumber(spellsLevelBox:GetText() or "") or nil
      if lvl and lvl <= 0 then lvl = nil end
      if op and lvl then
        rule.playerLevelOp = nil
        rule.playerLevel = { op, lvl }
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
    elseif panels.spells._editingDefaultBase and panels.spells._editingDefaultKey and type(GetDefaultRuleEdits) == "function" then
      local edits = GetDefaultRuleEdits() or {}
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
      rule.font = fontKey
      rule.size = fontSize
      rule.notInGroup = notInGroupCheck:GetChecked() and true or false
      rule.restedOnly = spellsRestedOnlyCheck:GetChecked() and true or false
      rule.missingPrimaryProfessions = spellsMissingProfCheck:GetChecked() and true or false
      rule.locationID = locationID
      rule.spellKnown = known
      rule.notSpellKnown = notKnown

      if expID then
        rule._expansionID = expID
        rule._expansionName = expName
      else
        rule._expansionID = nil
        rule._expansionName = nil
      end

      local op = panels.spells._playerLevelOp
      local lvl = spellsLevelBox and tonumber(spellsLevelBox:GetText() or "") or nil
      if lvl and lvl <= 0 then lvl = nil end
      if op and lvl then
        rule.playerLevelOp = nil
        rule.playerLevel = { op, lvl }
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
        font = fontKey,
        size = fontSize,
        notInGroup = notInGroupCheck:GetChecked() and true or false,
        restedOnly = spellsRestedOnlyCheck:GetChecked() and true or false,
        missingPrimaryProfessions = spellsMissingProfCheck:GetChecked() and true or false,
        locationID = locationID,
        playerLevel = (op and lvl) and { op, lvl } or nil,
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

      if expID then
        r._expansionID = expID
        r._expansionName = expName
      end

      rules[#rules + 1] = r
      Print("Added spell rule -> " .. targetFrame)
    end

    if CreateAllFrames then CreateAllFrames() end
    if RefreshAll then RefreshAll() end
    if RefreshRulesList then RefreshRulesList() end

    if not (type(GetKeepEditFormOpen) == "function" and GetKeepEditFormOpen()) then
      ClearSpellsInputs()
      if SelectTab then SelectTab("rules") end
    end
  end)

  cancelSpellEditBtn:SetScript("OnClick", function()
    panels.spells._editingCustomIndex = nil
    panels.spells._editingDefaultBase = nil
    panels.spells._editingDefaultKey = nil
    addSpellBtn:SetText("Add Spell Rule")
    cancelSpellEditBtn:Hide()

    if not (type(GetKeepEditFormOpen) == "function" and GetKeepEditFormOpen()) then
      ClearSpellsInputs()
      if SelectTab then SelectTab("rules") end
    end
  end)
end
