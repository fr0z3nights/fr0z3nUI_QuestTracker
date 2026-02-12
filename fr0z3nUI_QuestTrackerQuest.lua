local addonName, ns = ...

ns.FQTOptionsPanels = ns.FQTOptionsPanels or {}

function ns.FQTOptionsPanels.BuildQuest(ctx)
  if type(ctx) ~= "table" then return end

  local panels = ctx.panels
  if not (panels and panels.quest) then return end

  local Print = ctx.Print or function(...) end
  local CreateFrame = ctx.CreateFrame or CreateFrame

  local UseModernMenuDropDown = ctx.UseModernMenuDropDown
  local GetEffectiveFrames = ctx.GetEffectiveFrames
  local GetFrameDisplayNameByID = ctx.GetFrameDisplayNameByID

  local CreateQuickColorPalette = ctx.CreateQuickColorPalette

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
  local HideDropDownMenuArt = ctx.HideDropDownMenuArt
  local AttachLocationIDTooltip = ctx.AttachLocationIDTooltip

  local GetFontChoices = ctx.GetFontChoices
  local GetFontChoiceLabel = ctx.GetFontChoiceLabel

  local UDDM_SetWidth = ctx.UDDM_SetWidth
  local UDDM_SetText = ctx.UDDM_SetText
  local UDDM_Initialize = ctx.UDDM_Initialize
  local UDDM_CreateInfo = ctx.UDDM_CreateInfo
  local UDDM_AddButton = ctx.UDDM_AddButton

  local ColorLabel = ctx.ColorLabel
  local FactionLabel = ctx.FactionLabel

  local GetRuleExpansionChoices = ctx.GetRuleExpansionChoices
  local GetRuleCreateExpansion = ctx.GetRuleCreateExpansion
  local SetRuleCreateExpansion = ctx.SetRuleCreateExpansion
  local SyncRuleCreateExpansionDrops = ctx.SyncRuleCreateExpansionDrops

  local pQuest = panels.quest

  local questTitle = pQuest:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  questTitle:SetPoint("TOPLEFT", 12, -40)
  questTitle:SetText("Quest")

  if questTitle.Hide then questTitle:Hide() end

  -- Expansion selector (stamped onto new/edited rules as _expansionID/_expansionName)
  local expLabel = pQuest:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  expLabel:SetPoint("TOPRIGHT", pQuest, "TOPRIGHT", -12, -40)
  expLabel:SetText("Expansion")

  expLabel:SetText("")
  if expLabel.Hide then expLabel:Hide() end

  local expDrop = CreateFrame("Frame", nil, pQuest, "UIDropDownMenuTemplate")
  expDrop:SetPoint("TOPRIGHT", pQuest, "TOPRIGHT", -6, -40)
  if UDDM_SetWidth then UDDM_SetWidth(expDrop, 180) end
  if UDDM_SetText then UDDM_SetText(expDrop, "") end
  pQuest._expansionDrop = expDrop
  if HideDropDownMenuArt then HideDropDownMenuArt(expDrop) end

  do
    local keep = pQuest._keepOpenToggle
    if keep and keep.ClearAllPoints then
      expLabel:ClearAllPoints()
      expLabel:SetPoint("TOPRIGHT", keep, "TOPLEFT", -6, 0)
      expDrop:ClearAllPoints()
      expDrop:SetPoint("TOPRIGHT", keep, "TOPLEFT", -2, -14)
    end
  end

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

  function pQuest:_syncRuleCreateExpansion()
    local id, name = nil, nil
    if type(GetRuleCreateExpansion) == "function" then
      id, name = GetRuleCreateExpansion()
    end
    if not name and id then
      name = ResolveExpansionNameByID(id)
    end
    local label = name or "Choose Expansion"
    if UDDM_SetText and expDrop then UDDM_SetText(expDrop, label) end
  end

  if type(SyncRuleCreateExpansionDrops) == "function" then
    SyncRuleCreateExpansionDrops()
  elseif pQuest._syncRuleCreateExpansion then
    pQuest:_syncRuleCreateExpansion()
  end

  local qiLabel = pQuest:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  qiLabel:SetPoint("TOPLEFT", 12, -70)
  qiLabel:SetText("Quest Info")

  qiLabel:SetText("")
  if qiLabel.Hide then qiLabel:Hide() end

  local qiScroll = CreateFrame("ScrollFrame", nil, pQuest, "UIPanelScrollFrameTemplate")
  qiScroll:SetPoint("TOPLEFT", 12, -70)
  qiScroll:SetSize(530, 80)

  if qiScroll.ScrollBar then
    qiScroll.ScrollBar:Hide()
    qiScroll.ScrollBar.Show = function() end
    if qiScroll.ScrollBar.EnableMouse then qiScroll.ScrollBar:EnableMouse(false) end
  end
  qiScroll:EnableMouseWheel(true)
  qiScroll:SetScript("OnMouseWheel", function(self, delta)
    local cur = tonumber(self:GetVerticalScroll() or 0) or 0
    self:SetVerticalScroll(math.max(0, cur - (delta * 20)))
  end)

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
  if AddPlaceholder then AddPlaceholder(qiBox, "Quest Info (what to display)") end

  pQuest._questInfoScroll = qiScroll

  local qidLabel = pQuest:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  qidLabel:SetPoint("TOPLEFT", 12, -156)
  qidLabel:SetText("QuestID")

  qidLabel:SetText("")
  if qidLabel.Hide then qidLabel:Hide() end

  local questIDBox = CreateFrame("EditBox", nil, pQuest, "InputBoxTemplate")
  questIDBox:SetSize(90, 20)
  questIDBox:SetPoint("TOPLEFT", 12, -172)
  questIDBox:SetAutoFocus(false)
  questIDBox:SetNumeric(true)
  questIDBox:SetText("")
  if AddPlaceholder then AddPlaceholder(questIDBox, "QuestID") end
  if HideInputBoxTemplateArt then HideInputBoxTemplateArt(questIDBox) end

  local afterLabel = pQuest:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  afterLabel:SetPoint("TOPLEFT", 110, -156)
  afterLabel:SetText("After Quest (optional)")

  afterLabel:SetText("")
  if afterLabel.Hide then afterLabel:Hide() end

  local afterBox = CreateFrame("EditBox", nil, pQuest, "InputBoxTemplate")
  afterBox:SetSize(120, 20)
  afterBox:SetPoint("TOPLEFT", 110, -172)
  afterBox:SetAutoFocus(false)
  afterBox:SetNumeric(true)
  afterBox:SetText("")
  if AddPlaceholder then AddPlaceholder(afterBox, "After QuestID") end
  if HideInputBoxTemplateArt then HideInputBoxTemplateArt(afterBox) end

  local barLabel = pQuest:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  barLabel:SetPoint("TOPLEFT", 245, -156)
  barLabel:SetText("Bar / List")

  barLabel:SetText("")
  if barLabel.Hide then barLabel:Hide() end

  local factionLabel = pQuest:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  factionLabel:SetPoint("TOPLEFT", 410, -156)
  factionLabel:SetText("")
  if factionLabel.Hide then factionLabel:Hide() end

  local qTitleLabel = pQuest:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  qTitleLabel:SetPoint("TOPLEFT", 12, -196)
  qTitleLabel:SetText("Title (optional)")

  qTitleLabel:SetText("")
  if qTitleLabel.Hide then qTitleLabel:Hide() end

  local qTitleBox = CreateFrame("EditBox", nil, pQuest, "InputBoxTemplate")
  qTitleBox:SetSize(220, 20)
  qTitleBox:SetPoint("TOPLEFT", 12, -212)
  qTitleBox:SetAutoFocus(false)
  qTitleBox:SetText("")
  if AddPlaceholder then AddPlaceholder(qTitleBox, "Custom title (leave blank for quest name)") end
  if HideInputBoxTemplateArt then HideInputBoxTemplateArt(qTitleBox) end

  local colorLabel = pQuest:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  colorLabel:SetPoint("TOPLEFT", 12, -236)
  colorLabel:SetText("")
  if colorLabel.Hide then colorLabel:Hide() end

  local qLevelLabel = pQuest:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  qLevelLabel:SetPoint("TOPLEFT", 180, -236)
  qLevelLabel:SetText("Player level")

  local questFrameDrop = CreateFrame("Frame", nil, pQuest, "UIDropDownMenuTemplate")
  questFrameDrop:SetPoint("TOPLEFT", 230, -170)

  if UDDM_SetWidth then UDDM_SetWidth(questFrameDrop, 160) end
  if UDDM_SetText then UDDM_SetText(questFrameDrop, "Bar/List") end
  pQuest._questTargetFrameID = nil
  if HideDropDownMenuArt then HideDropDownMenuArt(questFrameDrop) end

  local questFactionDrop = CreateFrame("Frame", nil, pQuest, "UIDropDownMenuTemplate")
  questFactionDrop:SetPoint("TOPLEFT", 395, -166)
  if UDDM_SetWidth then UDDM_SetWidth(questFactionDrop, 140) end
  if UDDM_SetText then UDDM_SetText(questFactionDrop, "Faction") end
  pQuest._questFaction = nil
  if HideDropDownMenuArt then HideDropDownMenuArt(questFactionDrop) end

  local questColorDrop = CreateFrame("Frame", nil, pQuest, "UIDropDownMenuTemplate")
  questColorDrop:SetPoint("TOPLEFT", 12, -258)
  if UDDM_SetWidth then UDDM_SetWidth(questColorDrop, 160) end
  if UDDM_SetText then UDDM_SetText(questColorDrop, "Color") end
  pQuest._questColor = nil
  pQuest._questColorName = "None"
  if HideDropDownMenuArt then HideDropDownMenuArt(questColorDrop) end

  local qLevelOpDrop = CreateFrame("Frame", nil, pQuest, "UIDropDownMenuTemplate")
  qLevelOpDrop:SetPoint("TOPLEFT", 165, -264)
  if UDDM_SetWidth then UDDM_SetWidth(qLevelOpDrop, 70) end
  if UDDM_SetText then UDDM_SetText(qLevelOpDrop, "Off") end
  pQuest._playerLevelOp = nil
  if HideDropDownMenuArt then HideDropDownMenuArt(qLevelOpDrop) end

  local qLevelBox = CreateFrame("EditBox", nil, pQuest, "InputBoxTemplate")
  qLevelBox:SetSize(50, 20)
  qLevelBox:SetPoint("TOPLEFT", 270, -260)
  qLevelBox:SetAutoFocus(false)
  qLevelBox:SetNumeric(true)
  qLevelBox:SetText("0")
  if HideInputBoxTemplateArt then HideInputBoxTemplateArt(qLevelBox) end

  local qLocLabel = pQuest:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  qLocLabel:SetPoint("TOPLEFT", 330, -236)
  qLocLabel:SetText("LocationID (uiMapID)")

  local qLocBox = CreateFrame("EditBox", nil, pQuest, "InputBoxTemplate")
  qLocBox:SetSize(90, 20)
  qLocBox:SetPoint("TOPLEFT", 330, -260)
  qLocBox:SetAutoFocus(false)
  qLocBox:SetText("0")
  if AttachLocationIDTooltip then AttachLocationIDTooltip(qLocBox) end
  if HideInputBoxTemplateArt then HideInputBoxTemplateArt(qLocBox) end

  local fontLabel = pQuest:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  fontLabel:SetPoint("TOPLEFT", 12, -284)
  fontLabel:SetText("")
  if fontLabel.Hide then fontLabel:Hide() end

  local fontDrop = CreateFrame("Frame", nil, pQuest, "UIDropDownMenuTemplate")
  fontDrop:SetPoint("TOPLEFT", 12, -306)
  if UDDM_SetWidth then UDDM_SetWidth(fontDrop, 240) end
  if UDDM_SetText then UDDM_SetText(fontDrop, "Font") end
  pQuest._fontDrop = fontDrop
  pQuest._fontKey = "inherit"
  if HideDropDownMenuArt then HideDropDownMenuArt(fontDrop) end

  local sizeLabel = pQuest:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  sizeLabel:SetPoint("TOPLEFT", 260, -284)
  sizeLabel:SetText("Size")

  local sizeBox = CreateFrame("EditBox", nil, pQuest, "InputBoxTemplate")
  sizeBox:SetSize(50, 20)
  sizeBox:SetPoint("TOPLEFT", 260, -308)
  sizeBox:SetAutoFocus(false)
  sizeBox:SetNumeric(true)
  sizeBox:SetText("0")
  pQuest._sizeBox = sizeBox
  if HideInputBoxTemplateArt then HideInputBoxTemplateArt(sizeBox) end

  local function SetFontKey(key)
    key = tostring(key or "inherit")
    if key == "" then key = "inherit" end
    pQuest._fontKey = key
    if UDDM_SetText then
      if key == "inherit" then
        UDDM_SetText(fontDrop, "Font")
      else
        local label = (type(GetFontChoiceLabel) == "function") and GetFontChoiceLabel(key) or key
        UDDM_SetText(fontDrop, label)
      end
    end
  end

  local function SetQuestColor(name)
    if name == "None" then
      pQuest._questColor = nil
    elseif name == "Green" then
      pQuest._questColor = { 0.1, 1.0, 0.1 }
    elseif name == "Blue" then
      pQuest._questColor = { 0.2, 0.6, 1.0 }
    elseif name == "Yellow" then
      pQuest._questColor = { 1.0, 0.9, 0.2 }
    elseif name == "Red" then
      pQuest._questColor = { 1.0, 0.2, 0.2 }
    elseif name == "Cyan" then
      pQuest._questColor = { 0.2, 1.0, 1.0 }
    else
      pQuest._questColor = nil
      name = "None"
    end
    pQuest._questColorName = name
    if UDDM_SetText then
      if name == "None" then
        UDDM_SetText(questColorDrop, "Color")
      elseif ColorLabel then
        UDDM_SetText(questColorDrop, ColorLabel(name))
      else
        UDDM_SetText(questColorDrop, name)
      end
    end
  end

  if UDDM_Initialize and UDDM_CreateInfo and UDDM_AddButton then
    -- Expansion dropdown
    local modernExpansion = UseModernMenuDropDown and UseModernMenuDropDown(expDrop, function(root)
      local choices = (type(GetRuleExpansionChoices) == "function") and GetRuleExpansionChoices() or { { id = -1, name = "Weekly" } }

      do
        local function IsSelected()
          local curID, curName = nil, nil
          if type(GetRuleCreateExpansion) == "function" then
            curID, curName = GetRuleCreateExpansion()
          end
          curID = tonumber(curID)
          return (curID == nil) and (curName == nil or curName == "")
        end
        local function SetSelected()
          if type(SetRuleCreateExpansion) == "function" then
            SetRuleCreateExpansion(nil, nil)
          end
        end
        if root and root.CreateRadio then
          root:CreateRadio("Choose Expansion", IsSelected, SetSelected)
        elseif root and root.CreateButton then
          root:CreateButton("Choose Expansion", SetSelected)
        end
      end

      for _, opt in ipairs(choices) do
        local id = (type(opt) == "table") and opt.id or -1
        local name = (type(opt) == "table") and opt.name or "Weekly"
        name = (type(name) == "string" and name ~= "") and name or "Weekly"
        local function IsSelected()
          local curID, curName = nil, nil
          if type(GetRuleCreateExpansion) == "function" then
            curID, curName = GetRuleCreateExpansion()
          end
          curID = tonumber(curID)
          return curID == tonumber(id) or (curName ~= nil and curName == name)
        end
        local function SetSelected()
          if type(SetRuleCreateExpansion) == "function" then
            SetRuleCreateExpansion(id, name)
          end
        end
        if root and root.CreateRadio then
          root:CreateRadio(name, IsSelected, SetSelected)
        elseif root and root.CreateButton then
          root:CreateButton(name, SetSelected)
        end
      end
    end)

    if not modernExpansion then
      UDDM_Initialize(expDrop, function(self, level)
        local choices = (type(GetRuleExpansionChoices) == "function") and GetRuleExpansionChoices() or { { id = -1, name = "Weekly" } }

        do
          local info = UDDM_CreateInfo()
          info.text = "Choose Expansion"
          do
            local curID, curName = nil, nil
            if type(GetRuleCreateExpansion) == "function" then
              curID, curName = GetRuleCreateExpansion()
            end
            curID = tonumber(curID)
            info.checked = (curID == nil) and (curName == nil or curName == "")
          end
          info.func = function()
            if type(SetRuleCreateExpansion) == "function" then
              SetRuleCreateExpansion(nil, nil)
            end
          end
          UDDM_AddButton(info)
        end

        for _, opt in ipairs(choices) do
          local id = (type(opt) == "table") and opt.id or -1
          local name = (type(opt) == "table") and opt.name or "Weekly"
          name = (type(name) == "string" and name ~= "") and name or "Weekly"

          local info = UDDM_CreateInfo()
          info.text = name
          do
            local curID, curName = nil, nil
            if type(GetRuleCreateExpansion) == "function" then
              curID, curName = GetRuleCreateExpansion()
            end
            curID = tonumber(curID)
            info.checked = (curID == tonumber(id)) or (curName ~= nil and curName == name)
          end
          info.func = function()
            if type(SetRuleCreateExpansion) == "function" then
              SetRuleCreateExpansion(id, name)
            end
          end
          UDDM_AddButton(info)
        end
      end)
    end

    local modernQuestFrame = UseModernMenuDropDown and UseModernMenuDropDown(questFrameDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Bar / List") end

      if root and root.CreateRadio then
        root:CreateRadio("Bar/List", function() return (pQuest._questTargetFrameID == nil) end, function()
          pQuest._questTargetFrameID = nil
          if UDDM_SetText then UDDM_SetText(questFrameDrop, "Bar/List") end
        end)
      elseif root and root.CreateButton then
        root:CreateButton("Bar/List", function()
          pQuest._questTargetFrameID = nil
          if UDDM_SetText then UDDM_SetText(questFrameDrop, "Bar/List") end
        end)
      end

      for _, def in ipairs(GetEffectiveFrames()) do
        if type(def) == "table" and def.id and root then
          local id = tostring(def.id)
          local label = GetFrameDisplayNameByID(id)
          if root.CreateRadio then
            root:CreateRadio(label, function() return (pQuest._questTargetFrameID == id) end, function()
              pQuest._questTargetFrameID = id
              if UDDM_SetText then UDDM_SetText(questFrameDrop, GetFrameDisplayNameByID(id)) end
            end)
          elseif root.CreateButton then
            root:CreateButton(label, function()
              pQuest._questTargetFrameID = id
              if UDDM_SetText then UDDM_SetText(questFrameDrop, GetFrameDisplayNameByID(id)) end
            end)
          end
        end
      end
    end)

    local modernQuestFaction = UseModernMenuDropDown and UseModernMenuDropDown(questFactionDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Faction") end
      local function Add(name, v)
        if not root then return end
        if root.CreateRadio then
          root:CreateRadio(name, function() return (pQuest._questFaction == v) end, function()
            pQuest._questFaction = v
            if UDDM_SetText then
              if v == nil then
                UDDM_SetText(questFactionDrop, "Faction")
              elseif FactionLabel then
                UDDM_SetText(questFactionDrop, FactionLabel(v))
              else
                UDDM_SetText(questFactionDrop, name)
              end
            end
          end)
        elseif root.CreateButton then
          root:CreateButton(name, function()
            pQuest._questFaction = v
            if UDDM_SetText then
              if v == nil then
                UDDM_SetText(questFactionDrop, "Faction")
              elseif FactionLabel then
                UDDM_SetText(questFactionDrop, FactionLabel(v))
              else
                UDDM_SetText(questFactionDrop, name)
              end
            end
          end)
        end
      end
      Add("Both (Off)", nil)
      Add("Alliance", "Alliance")
      Add("Horde", "Horde")
    end)

    local modernQuestColor = UseModernMenuDropDown and UseModernMenuDropDown(questColorDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Color") end
      for _, name in ipairs({ "None", "Green", "Blue", "Yellow", "Red", "Cyan" }) do
        if root and root.CreateRadio then
          root:CreateRadio(name, function() return (pQuest._questColorName == name) end, function() SetQuestColor(name) end)
        elseif root and root.CreateButton then
          root:CreateButton(name, function() SetQuestColor(name) end)
        end
      end
    end)

    local modernFont = UseModernMenuDropDown and UseModernMenuDropDown(fontDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Font") end
      local choices = (type(GetFontChoices) == "function") and GetFontChoices() or { { key = "inherit", label = "Inherit" } }
      for _, opt in ipairs(choices) do
        if type(opt) == "table" and opt.key and root then
          local key = tostring(opt.key)
          local label = tostring(opt.label or opt.key)
          if root.CreateRadio then
            root:CreateRadio(label, function() return (pQuest._fontKey == key) end, function() SetFontKey(key) end)
          elseif root.CreateButton then
            root:CreateButton(label, function() SetFontKey(key) end)
          end
        end
      end
    end)

    local modernLevelOp = UseModernMenuDropDown and UseModernMenuDropDown(qLevelOpDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Player level") end
      local function Add(name, op)
        if not root then return end
        if root.CreateRadio then
          root:CreateRadio(name, function() return (pQuest._playerLevelOp == op) end, function()
            pQuest._playerLevelOp = op
            if UDDM_SetText then UDDM_SetText(qLevelOpDrop, name) end
          end)
        elseif root.CreateButton then
          root:CreateButton(name, function()
            pQuest._playerLevelOp = op
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

        info.text = "Bar/List"
        info.checked = (pQuest._questTargetFrameID == nil) and true or false
        info.func = function()
          pQuest._questTargetFrameID = nil
          if UDDM_SetText then UDDM_SetText(questFrameDrop, "Bar/List") end
        end
        UDDM_AddButton(info)

        for _, def in ipairs(GetEffectiveFrames()) do
          if type(def) == "table" and def.id then
            local id = tostring(def.id)
            info.text = GetFrameDisplayNameByID(id)
            info.checked = (pQuest._questTargetFrameID == id) and true or false
            info.func = function()
              pQuest._questTargetFrameID = id
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
          info.checked = (pQuest._questFaction == nil) and true or false
          info.func = function()
            pQuest._questFaction = nil
            if UDDM_SetText then UDDM_SetText(questFactionDrop, "Faction") end
          end
          UDDM_AddButton(info)
        end

        do
          local info = UDDM_CreateInfo()
          info.text = "Alliance"
          info.checked = (pQuest._questFaction == "Alliance") and true or false
          info.func = function()
            pQuest._questFaction = "Alliance"
            if UDDM_SetText then
              if FactionLabel then
                UDDM_SetText(questFactionDrop, FactionLabel("Alliance"))
              else
                UDDM_SetText(questFactionDrop, "Alliance")
              end
            end
          end
          UDDM_AddButton(info)
        end

        do
          local info = UDDM_CreateInfo()
          info.text = "Horde"
          info.checked = (pQuest._questFaction == "Horde") and true or false
          info.func = function()
            pQuest._questFaction = "Horde"
            if UDDM_SetText then
              if FactionLabel then
                UDDM_SetText(questFactionDrop, FactionLabel("Horde"))
              else
                UDDM_SetText(questFactionDrop, "Horde")
              end
            end
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
          info.checked = (pQuest._questColorName == name) and true or false
          info.func = function() SetQuestColor(name) end
          UDDM_AddButton(info)
        end
      end)
    end

    if not modernFont then
      UDDM_Initialize(fontDrop, function(self, level)
        local choices = (type(GetFontChoices) == "function") and GetFontChoices() or { { key = "inherit", label = "Inherit" } }
        for _, opt in ipairs(choices) do
          if type(opt) == "table" and opt.key then
            local key = tostring(opt.key)
            local info = UDDM_CreateInfo()
            info.text = tostring(opt.label or opt.key)
            info.checked = (pQuest._fontKey == key) and true or false
            info.func = function() SetFontKey(key) end
            UDDM_AddButton(info)
          end
        end
      end)
    end

    if not modernLevelOp then
      UDDM_Initialize(qLevelOpDrop, function(self, level)
        local function Add(name, op)
          local info = UDDM_CreateInfo()
          info.text = name
          info.checked = (pQuest._playerLevelOp == op) and true or false
          info.func = function()
            pQuest._playerLevelOp = op
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
    local fb = CreateFrame("EditBox", nil, pQuest, "InputBoxTemplate")
    fb:SetSize(80, 20)
    fb:SetPoint("TOPLEFT", 245, -206)
    fb:SetAutoFocus(false)
    fb:SetText("list1")
    fb:SetScript("OnEnterPressed", function(self)
      local v = tostring(self:GetText() or ""):gsub("%s+", "")
      if v == "" then v = "list1" end
      pQuest._questTargetFrameID = v
      self:SetText(v)
      self:ClearFocus()
    end)
    pQuest._questFrameFallbackBox = fb
    questFrameDrop:Hide()

    local fbf = CreateFrame("EditBox", nil, pQuest, "InputBoxTemplate")
    fbf:SetSize(80, 20)
    fbf:SetPoint("TOPLEFT", 410, -206)
    fbf:SetAutoFocus(false)
    fbf:SetText("both")
    fbf:SetScript("OnEnterPressed", function(self)
      local v = tostring(self:GetText() or ""):lower():gsub("%s+", "")
      if v == "a" or v == "alliance" then
        pQuest._questFaction = "Alliance"
        self:SetText("Alliance")
      elseif v == "h" or v == "horde" then
        pQuest._questFaction = "Horde"
        self:SetText("Horde")
      else
        pQuest._questFaction = nil
        self:SetText("both")
      end
      self:ClearFocus()
    end)
    pQuest._questFactionFallbackBox = fbf
    questFactionDrop:Hide()

    local cfb = CreateFrame("EditBox", nil, pQuest, "InputBoxTemplate")
    cfb:SetSize(80, 20)
    cfb:SetPoint("TOPLEFT", 12, -292)
    cfb:SetAutoFocus(false)
    cfb:SetText("none")
    cfb:SetScript("OnEnterPressed", function(self)
      local v = tostring(self:GetText() or ""):lower():gsub("%s+", "")
      if v == "green" then
        pQuest._questColor = { 0.1, 1.0, 0.1 }
      elseif v == "blue" then
        pQuest._questColor = { 0.2, 0.6, 1.0 }
      elseif v == "yellow" then
        pQuest._questColor = { 1.0, 0.9, 0.2 }
      elseif v == "red" then
        pQuest._questColor = { 1.0, 0.2, 0.2 }
      elseif v == "cyan" then
        pQuest._questColor = { 0.2, 1.0, 1.0 }
      else
        pQuest._questColor = nil
        v = "none"
      end
      self:SetText(v)
      self:ClearFocus()
    end)
    pQuest._questColorFallbackBox = cfb
    questColorDrop:Hide()

    qLevelOpDrop:Hide()
    qLevelLabel:Hide()
    qLevelBox:Hide()
  end

  local addQuestBtn = CreateFrame("Button", nil, pQuest, "UIPanelButtonTemplate")
  addQuestBtn:SetSize(140, 22)
  addQuestBtn:SetPoint("TOPLEFT", 12, -390)
  addQuestBtn:SetText("Add Quest Rule")

  pQuest._questIDBox = questIDBox
  pQuest._questInfoBox = qiBox
  pQuest._questAfterBox = afterBox
  pQuest._titleBox = qTitleBox
  pQuest._locBox = qLocBox
  pQuest._questFrameDrop = questFrameDrop
  pQuest._questFactionDrop = questFactionDrop
  pQuest._questColorDrop = questColorDrop
  pQuest._qLevelOpDrop = qLevelOpDrop
  pQuest._qLevelBox = qLevelBox
  pQuest._addQuestBtn = addQuestBtn

  local function ClearQuestInputs()
    if qiBox then qiBox:SetText("") end
    if qiScroll and qiScroll.SetVerticalScroll then qiScroll:SetVerticalScroll(0) end
    if questIDBox then questIDBox:SetText("0") end
    if afterBox then afterBox:SetText("0") end
    if qTitleBox then qTitleBox:SetText("") end
    if qLocBox then qLocBox:SetText("0") end

    pQuest._questTargetFrameID = nil
    if UDDM_SetText and questFrameDrop then UDDM_SetText(questFrameDrop, "Bar/List") end
    if pQuest._questFrameFallbackBox then pQuest._questFrameFallbackBox:SetText("list1") end

    pQuest._questFaction = nil
    if UDDM_SetText and questFactionDrop then UDDM_SetText(questFactionDrop, "Faction") end
    if pQuest._questFactionFallbackBox then pQuest._questFactionFallbackBox:SetText("both") end

    pQuest._questColor = nil
    pQuest._questColorName = "None"
    if UDDM_SetText and questColorDrop then UDDM_SetText(questColorDrop, "Color") end
    if pQuest._questColorFallbackBox then pQuest._questColorFallbackBox:SetText("none") end

    pQuest._playerLevelOp = nil
    if UDDM_SetText and qLevelOpDrop then UDDM_SetText(qLevelOpDrop, "Off") end
    if qLevelBox then qLevelBox:SetText("0") end

    pQuest._fontKey = "inherit"
    if UDDM_SetText and fontDrop then UDDM_SetText(fontDrop, "Font") end
    if sizeBox then sizeBox:SetText("0") end
  end

  local cancelQuestEditBtn = CreateFrame("Button", nil, pQuest, "UIPanelButtonTemplate")
  cancelQuestEditBtn:SetSize(120, 22)
  cancelQuestEditBtn:SetPoint("LEFT", addQuestBtn, "RIGHT", 8, 0)
  cancelQuestEditBtn:SetText("Cancel Edit")
  cancelQuestEditBtn:Hide()
  pQuest._cancelEditBtn = cancelQuestEditBtn

  -- Quick color palette for quest text color
  if CreateQuickColorPalette then
    CreateQuickColorPalette(pQuest, addQuestBtn, "TOPLEFT", "TOPLEFT", 0, 33, {
      cols = 5,
      getColor = function()
        if type(pQuest._questColor) == "table" then
          return pQuest._questColor[1], pQuest._questColor[2], pQuest._questColor[3]
        end
        return nil
      end,
      onPick = function(r, g, b)
        pQuest._questColor = { r, g, b }
        pQuest._questColorName = "Custom"
        if UDDM_SetText and ColorLabel then UDDM_SetText(questColorDrop, ColorLabel("Custom")) end
      end,
    })
  end

  addQuestBtn:SetScript("OnClick", function()
    local questID = tonumber(questIDBox:GetText() or "")
    if not questID or questID <= 0 then
      Print("Enter a questID > 0.")
      return
    end

    ---@type string|nil
    local targetFrame = nil
    do
      local targetFrameID = pQuest._questTargetFrameID
      if targetFrameID ~= nil then
        local tf = tostring(targetFrameID):gsub("%s+", "")
        if tf ~= "" then targetFrame = tf end
      end
    end

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

    local fontKey = tostring(pQuest._fontKey or "inherit")
    if fontKey == "" then fontKey = "inherit" end
    local fontSize = (sizeBox and tonumber(sizeBox:GetText() or "")) or 0
    if not fontSize or fontSize < 0 then fontSize = 0 end

    local rules = GetCustomRules()
    local expID, expName = (type(GetRuleCreateExpansion) == "function") and GetRuleCreateExpansion() or nil, nil
    if type(GetRuleCreateExpansion) == "function" then
      expID, expName = GetRuleCreateExpansion()
    end
    expID = tonumber(expID)
    if not expName and expID then expName = ResolveExpansionNameByID(expID) end
    if expName == "Custom" then expName = nil; expID = nil end

    if pQuest._editingCustomIndex and type(rules[pQuest._editingCustomIndex]) == "table" then
      local rule = rules[pQuest._editingCustomIndex]
      rule.questID = questID
      rule.frameID = targetFrame
      rule.questInfo = questInfo
      rule.label = title
      rule.prereq = prereq
      rule.faction = pQuest._questFaction
      rule.color = pQuest._questColor
      rule.locationID = locationID
      rule.font = fontKey
      rule.size = fontSize
      rule._expansionID = expID
      rule._expansionName = expName

      local op = pQuest._playerLevelOp
      local lvl = qLevelBox and tonumber(qLevelBox:GetText() or "") or nil
      if lvl and lvl <= 0 then lvl = nil end
      if op and lvl then
        rule.playerLevelOp = nil
        rule.playerLevel = { op, lvl }
      else
        rule.playerLevelOp = nil
        rule.playerLevel = nil
      end
      if rule.hideWhenCompleted == nil then rule.hideWhenCompleted = true end

      pQuest._editingCustomIndex = nil
      pQuest._editingDefaultBase = nil
      pQuest._editingDefaultKey = nil
      addQuestBtn:SetText("Add Quest Rule")
      cancelQuestEditBtn:Hide()
      Print("Saved quest rule.")
    elseif pQuest._editingDefaultBase and pQuest._editingDefaultKey and type(GetDefaultRuleEdits) == "function" then
      local edits = GetDefaultRuleEdits()
      local base = pQuest._editingDefaultBase
      local key = tostring(pQuest._editingDefaultKey)
      local effective = (type(edits[key]) == "table") and edits[key] or base
      local rule = DeepCopyValue(effective)

      rule.questID = questID
      rule.frameID = targetFrame
      rule.questInfo = questInfo
      rule.label = title
      rule.prereq = prereq
      rule.faction = pQuest._questFaction
      rule.color = pQuest._questColor
      rule.locationID = locationID
      rule.font = fontKey
      rule.size = fontSize
      rule._expansionID = expID
      rule._expansionName = expName

      local op = pQuest._playerLevelOp
      local lvl = qLevelBox and tonumber(qLevelBox:GetText() or "") or nil
      if lvl and lvl <= 0 then lvl = nil end
      if op and lvl then
        rule.playerLevelOp = nil
        rule.playerLevel = { op, lvl }
      else
        rule.playerLevelOp = nil
        rule.playerLevel = nil
      end
      if rule.hideWhenCompleted == nil then rule.hideWhenCompleted = true end

      if base and base.key ~= nil then rule.key = tostring(base.key) end
      edits[key] = rule

      pQuest._editingCustomIndex = nil
      pQuest._editingDefaultBase = nil
      pQuest._editingDefaultKey = nil
      addQuestBtn:SetText("Add Quest Rule")
      cancelQuestEditBtn:Hide()
      Print("Saved default quest rule edit.")
    else
      local targetFrameKey = (targetFrame ~= nil) and tostring(targetFrame) or "any"
      local key = string.format("custom:q:%d:%s:%d", tostring(questID), targetFrameKey, (#rules + 1))

      local op = pQuest._playerLevelOp
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
        faction = pQuest._questFaction,
        color = pQuest._questColor,
        locationID = locationID,
        font = fontKey,
        size = fontSize,
        _expansionID = expID,
        _expansionName = expName,
        playerLevel = (op and lvl) and { op, lvl } or nil,
        hideWhenCompleted = true,
      }

      local targetLabel = (targetFrame ~= nil) and tostring(targetFrame) or "Bar/List"
      Print("Added quest rule for quest " .. questID .. " -> " .. targetLabel)
    end

    if CreateAllFrames then CreateAllFrames() end
    if RefreshAll then RefreshAll() end
    if RefreshRulesList then RefreshRulesList() end
    if not GetKeepEditFormOpen() then
      ClearQuestInputs()
      if SelectTab then SelectTab("rules") end
    end
  end)

  cancelQuestEditBtn:SetScript("OnClick", function()
    pQuest._editingCustomIndex = nil
    pQuest._editingDefaultBase = nil
    pQuest._editingDefaultKey = nil
    addQuestBtn:SetText("Add Quest Rule")
    cancelQuestEditBtn:Hide()

    if not GetKeepEditFormOpen() then
      ClearQuestInputs()
      if SelectTab then SelectTab("rules") end
    end
  end)
end
