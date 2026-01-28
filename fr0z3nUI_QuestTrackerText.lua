local addonName, ns = ...

ns.FQTOptionsPanels = ns.FQTOptionsPanels or {}

function ns.FQTOptionsPanels.BuildText(ctx)
  if type(ctx) ~= "table" then return end

  local panels = ctx.panels
  if not (panels and panels.text) then return end

  local Print = ctx.Print or function(...) end
  local CreateFrame = ctx.CreateFrame or CreateFrame

  local f = ctx.optionsFrame

  local ApplyFAOBackdrop = ctx.ApplyFAOBackdrop
  local GetCalendarDebugEvents = ctx.GetCalendarDebugEvents

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

  local textTitle = panels.text:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  textTitle:SetPoint("TOPLEFT", 12, -40)
  textTitle:SetText("Text")

  -- Expansion selector (stamped onto new/edited rules as _expansionID/_expansionName)
  local expLabel = panels.text:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  expLabel:SetPoint("TOPRIGHT", panels.text, "TOPRIGHT", -12, -40)
  expLabel:SetText("Expansion")

  local expDrop = CreateFrame("Frame", nil, panels.text, "UIDropDownMenuTemplate")
  expDrop:SetPoint("TOPRIGHT", panels.text, "TOPRIGHT", -6, -54)
  if UDDM_SetWidth then UDDM_SetWidth(expDrop, 180) end
  if UDDM_SetText then UDDM_SetText(expDrop, "") end
  panels.text._expansionDrop = expDrop

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

  function panels.text:_syncRuleCreateExpansion()
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
  elseif panels.text._syncRuleCreateExpansion then
    panels.text:_syncRuleCreateExpansion()
  end

  local function EnsureCalendarPopout()
    if not f then return nil end
    if f._calendarPopout then return f._calendarPopout end

    local pop = CreateFrame("Frame", nil, f, "BackdropTemplate")
    pop:SetSize(540, 360)
    pop:SetPoint("CENTER", f, "CENTER", 0, 0)
    pop:SetFrameStrata("DIALOG")
    pop:SetClampedToScreen(true)
    if ApplyFAOBackdrop then ApplyFAOBackdrop(pop, 0.92) end
    pop:Hide()

    local title = pop:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 12, -10)
    title:SetText("Calendar")
    pop._title = title

    local close = CreateFrame("Button", nil, pop, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", pop, "TOPRIGHT", 2, 2)
    close:SetScript("OnClick", function() pop:Hide() end)

    local hint = pop:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", 12, -34)
    hint:SetText("Click Copy then Ctrl+C. Shift+Copy includes holiday text.")

    local refreshBtn = CreateFrame("Button", nil, pop, "UIPanelButtonTemplate")
    refreshBtn:SetSize(70, 20)
    refreshBtn:SetPoint("TOPRIGHT", pop, "TOPRIGHT", -34, -34)
    refreshBtn:SetText("Refresh")

    local scroll = CreateFrame("ScrollFrame", nil, pop, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -58)
    scroll:SetSize(516, 210)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)
    pop._scroll = scroll
    pop._content = content

    local rowH = 18
    local rows = {}
    pop._rows = rows
    pop._events = {}

    local function SetCopyText(text)
      if not pop._copyBox then return end
      pop._copyBox:SetText(tostring(text or ""))
      if pop._copyBox.HighlightText then pop._copyBox:HighlightText() end
      if pop._copyBox.SetFocus then pop._copyBox:SetFocus() end
    end

    local function GetRelLabel(relDay)
      relDay = tonumber(relDay) or 0
      if relDay == 0 then return "Today" end
      if relDay == 1 then return "+1" end
      if relDay == -1 then return "-1" end
      return (relDay > 0) and ("+" .. tostring(relDay)) or tostring(relDay)
    end

    local function EnsureRow(i)
      if rows[i] then return rows[i] end
      local r = CreateFrame("Button", nil, content)
      r:SetHeight(rowH)
      r:SetPoint("TOPLEFT", 0, -((i - 1) * rowH))
      r:SetPoint("TOPRIGHT", 0, -((i - 1) * rowH))

      local rel = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
      rel:SetPoint("LEFT", 2, 0)
      rel:SetWidth(36)
      rel:SetJustifyH("LEFT")
      r._rel = rel

      local txt = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      txt:SetPoint("LEFT", rel, "RIGHT", 6, 0)
      txt:SetPoint("RIGHT", r, "RIGHT", -70, 0)
      txt:SetJustifyH("LEFT")
      txt:SetWordWrap(false)
      r._text = txt

      local copyBtn = CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
      copyBtn:SetSize(56, 18)
      copyBtn:SetPoint("RIGHT", -6, 0)
      copyBtn:SetText("Copy")
      r._copy = copyBtn

      local function DoCopy()
        local ev = r._event
        if type(ev) ~= "table" then return end
        local titleText = tostring(ev.title or "")
        local holidayText = tostring(ev.holidayText or "")
        if IsShiftKeyDown and IsShiftKeyDown() and holidayText ~= "" then
          SetCopyText(titleText .. "\n" .. holidayText)
        else
          SetCopyText(titleText)
        end
      end

      r:SetScript("OnClick", DoCopy)
      copyBtn:SetScript("OnClick", DoCopy)

      r:SetScript("OnEnter", function()
        local ev = r._event
        if type(ev) ~= "table" then return end
        if not GameTooltip then return end
        GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
        local t = tostring(ev.title or "")
        local h = tostring(ev.holidayText or "")
        if t ~= "" then GameTooltip:AddLine(t, 1, 1, 1, true) end
        if h ~= "" then GameTooltip:AddLine(h, 0.8, 0.8, 0.8, true) end
        GameTooltip:Show()
      end)
      r:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

      rows[i] = r
      return r
    end

    local function Render()
      local events = {}
      local meta = nil
      if type(GetCalendarDebugEvents) == "function" then
        events, meta = GetCalendarDebugEvents(1, 14)
      end
      if type(events) ~= "table" then events = {} end
      pop._events = events

      if pop._title and pop._title.SetText then
        if type(meta) == "table" and meta.ok and meta.today then
          pop._title:SetText(string.format("Calendar (Day %d)", tonumber(meta.today) or 0))
        else
          pop._title:SetText("Calendar")
        end
      end

      local n = #events
      content:SetHeight(math.max(1, n * rowH))
      for i = 1, n do
        local ev = events[i]
        local r = EnsureRow(i)
        r._event = ev
        if r._rel and r._rel.SetText then r._rel:SetText(GetRelLabel(ev.relDay)) end
        if r._text and r._text.SetText then
          local t = tostring(ev.title or "")
          if t == "" then t = "(no title)" end
          r._text:SetText(t)
        end
        r:Show()
      end
      for i = n + 1, #rows do
        if rows[i] then rows[i]:Hide() end
      end
    end

    refreshBtn:SetScript("OnClick", Render)
    pop._render = Render

    local copyAllBtn = CreateFrame("Button", nil, pop, "UIPanelButtonTemplate")
    copyAllBtn:SetSize(90, 20)
    copyAllBtn:SetPoint("TOPLEFT", 12, -272)
    copyAllBtn:SetText("Copy All")
    copyAllBtn:SetScript("OnClick", function()
      local out = {}
      for _, ev in ipairs(pop._events or {}) do
        local t = tostring(ev.title or "")
        local h = tostring(ev.holidayText or "")
        if IsShiftKeyDown and IsShiftKeyDown() and h ~= "" then
          out[#out + 1] = t .. "\n" .. h
        else
          out[#out + 1] = t
        end
      end
      SetCopyText(table.concat(out, "\n\n"))
    end)

    local copyScroll = CreateFrame("ScrollFrame", nil, pop, "UIPanelScrollFrameTemplate")
    copyScroll:SetPoint("TOPLEFT", 12, -296)
    copyScroll:SetSize(516, 52)

    local copyBox = CreateFrame("EditBox", nil, copyScroll)
    copyBox:SetMultiLine(true)
    copyBox:SetAutoFocus(false)
    copyBox:SetFontObject("ChatFontNormal")
    copyBox:SetWidth(480)
    copyBox:SetTextInsets(6, 6, 6, 6)
    copyBox:SetText("")
    copyBox:SetScript("OnEscapePressed", function(self)
      self:ClearFocus()
      pop:Hide()
    end)
    copyBox:SetScript("OnEditFocusGained", function(self)
      if self.HighlightText then self:HighlightText() end
    end)
    copyScroll:SetScrollChild(copyBox)

    pop._copyBox = copyBox

    f._calendarPopout = pop
    return pop
  end

  local calendarBtn = CreateFrame("Button", nil, panels.text, "UIPanelButtonTemplate")
  calendarBtn:SetSize(90, 20)
  calendarBtn:SetPoint("TOPRIGHT", panels.text, "TOPRIGHT", -12, -38)
  calendarBtn:SetText("Calendar")
  calendarBtn:SetScript("OnClick", function()
    local pop = EnsureCalendarPopout()
    if not pop then return end
    if pop.IsShown and pop:IsShown() then
      pop:Hide()
      return
    end
    pop:Show()
    if pop._render then pop._render() end
  end)

  local textNameBox = CreateFrame("EditBox", nil, panels.text, "InputBoxTemplate")
  textNameBox:SetSize(530, 20)
  textNameBox:SetPoint("TOPLEFT", 12, -70)
  textNameBox:SetAutoFocus(false)
  textNameBox:SetText("")
  textNameBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  textNameBox:SetTextInsets(6, 6, 0, 0)
  if AddPlaceholder then AddPlaceholder(textNameBox, "Text Name") end
  if HideInputBoxTemplateArt then HideInputBoxTemplateArt(textNameBox) end

  local textInfoScroll = CreateFrame("ScrollFrame", nil, panels.text, "UIPanelScrollFrameTemplate")
  textInfoScroll:SetPoint("TOPLEFT", 12, -94)
  textInfoScroll:SetSize(530, 46)

  local textInfoBox = CreateFrame("EditBox", nil, textInfoScroll)
  textInfoBox:SetMultiLine(true)
  textInfoBox:SetAutoFocus(false)
  textInfoBox:SetFontObject("ChatFontNormal")
  textInfoBox:SetWidth(500)
  textInfoBox:SetTextInsets(6, 6, 6, 6)
  textInfoBox:SetText("")
  textInfoBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  textInfoBox:SetScript("OnCursorChanged", function(self, x, y, w, h)
    if not textInfoScroll then return end
    textInfoScroll:UpdateScrollChildRect()
    local offset = textInfoScroll:GetVerticalScroll() or 0
    local height = textInfoScroll:GetHeight() or 0
    local top = -y
    if top < offset then
      textInfoScroll:SetVerticalScroll(top)
    elseif top > offset + height - 20 then
      textInfoScroll:SetVerticalScroll(top - height + 20)
    end
  end)

  textInfoScroll:SetScrollChild(textInfoBox)
  if AddPlaceholder then AddPlaceholder(textInfoBox, "Text Info") end

  panels.text._textInfoScroll = textInfoScroll

  local textFrameDrop = CreateFrame("Frame", nil, panels.text, "UIDropDownMenuTemplate")
  textFrameDrop:SetPoint("TOPLEFT", -8, -164)
  if UDDM_SetWidth then UDDM_SetWidth(textFrameDrop, 160) end
  if UDDM_SetText then UDDM_SetText(textFrameDrop, GetFrameDisplayNameByID("list1")) end
  panels.text._targetFrameID = "list1"

  local textFactionDrop = CreateFrame("Frame", nil, panels.text, "UIDropDownMenuTemplate")
  textFactionDrop:SetPoint("TOPLEFT", 165, -164)
  if UDDM_SetWidth then UDDM_SetWidth(textFactionDrop, 140) end
  if UDDM_SetText then UDDM_SetText(textFactionDrop, "Both (Off)") end
  panels.text._faction = nil

  local textColorDrop = CreateFrame("Frame", nil, panels.text, "UIDropDownMenuTemplate")
  textColorDrop:SetPoint("TOPLEFT", 325, -164)
  if UDDM_SetWidth then UDDM_SetWidth(textColorDrop, 140) end
  if UDDM_SetText then UDDM_SetText(textColorDrop, "None") end
  panels.text._color = nil

  local textFontLabel = panels.text:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  textFontLabel:SetPoint("TOPLEFT", 500, -146)
  textFontLabel:SetText("Font")

  local textFontDrop = CreateFrame("Frame", nil, panels.text, "UIDropDownMenuTemplate")
  textFontDrop:SetPoint("TOPLEFT", 485, -164)
  if UDDM_SetWidth then UDDM_SetWidth(textFontDrop, 170) end
  if UDDM_SetText then UDDM_SetText(textFontDrop, "Inherit") end
  panels.text._fontDrop = textFontDrop
  panels.text._fontKey = "inherit"

  local textSizeLabel = panels.text:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  textSizeLabel:SetPoint("TOPLEFT", 500, -246)
  textSizeLabel:SetText("Size")

  local textSizeBox = CreateFrame("EditBox", nil, panels.text, "InputBoxTemplate")
  textSizeBox:SetSize(50, 20)
  textSizeBox:SetPoint("TOPLEFT", 500, -262)
  textSizeBox:SetAutoFocus(false)
  textSizeBox:SetNumeric(true)
  textSizeBox:SetText("0")
  if HideInputBoxTemplateArt then HideInputBoxTemplateArt(textSizeBox) end
  panels.text._sizeBox = textSizeBox

  -- Quick color palette for text entry color
  if CreateQuickColorPalette then
    CreateQuickColorPalette(panels.text, textColorDrop, "TOPLEFT", "BOTTOMLEFT", 26, 12, {
      cols = 5,
      getColor = function()
        if type(panels.text._color) == "table" then
          return panels.text._color[1], panels.text._color[2], panels.text._color[3]
        end
        return nil
      end,
      onPick = function(r, g, b)
        panels.text._color = { r, g, b }
        if UDDM_SetText then UDDM_SetText(textColorDrop, "Custom") end
      end,
    })
  end

  local textRepFactionBox = CreateFrame("EditBox", nil, panels.text, "InputBoxTemplate")
  textRepFactionBox:SetSize(90, 20)
  textRepFactionBox:SetPoint("TOPLEFT", 12, -220)
  textRepFactionBox:SetAutoFocus(false)
  textRepFactionBox:SetNumeric(true)
  textRepFactionBox:SetText("0")

  local textRepMinDrop = CreateFrame("Frame", nil, panels.text, "UIDropDownMenuTemplate")
  textRepMinDrop:SetPoint("TOPLEFT", 95, -232)
  if UDDM_SetWidth then UDDM_SetWidth(textRepMinDrop, 140) end
  if UDDM_SetText then UDDM_SetText(textRepMinDrop, "Off") end
  panels.text._repMinStanding = nil

  local textRestedOnly = CreateFrame("CheckButton", nil, panels.text, "UICheckButtonTemplate")
  textRestedOnly:SetPoint("TOPLEFT", 250, -246)
  if SetCheckButtonLabel then SetCheckButtonLabel(textRestedOnly, "Rested areas only") end
  textRestedOnly:SetChecked(false)

  local textLocLabel = panels.text:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  textLocLabel:SetPoint("TOPLEFT", 250, -206)
  textLocLabel:SetText("LocationID (uiMapID)")

  local textLocBox = CreateFrame("EditBox", nil, panels.text, "InputBoxTemplate")
  textLocBox:SetSize(90, 20)
  textLocBox:SetPoint("TOPLEFT", 250, -222)
  textLocBox:SetAutoFocus(false)
  textLocBox:SetText("0")
  if AttachLocationIDTooltip then AttachLocationIDTooltip(textLocBox) end

  local textLevelLabel = panels.text:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  textLevelLabel:SetPoint("TOPLEFT", 400, -206)
  textLevelLabel:SetText("Player level")

  local textLevelOpDrop = CreateFrame("Frame", nil, panels.text, "UIDropDownMenuTemplate")
  textLevelOpDrop:SetPoint("TOPLEFT", 385, -226)
  if UDDM_SetWidth then UDDM_SetWidth(textLevelOpDrop, 70) end
  if UDDM_SetText then UDDM_SetText(textLevelOpDrop, "Off") end
  panels.text._playerLevelOp = nil

  local textLevelBox = CreateFrame("EditBox", nil, panels.text, "InputBoxTemplate")
  textLevelBox:SetSize(50, 20)
  textLevelBox:SetPoint("TOPLEFT", 490, -222)
  textLevelBox:SetAutoFocus(false)
  textLevelBox:SetNumeric(true)
  textLevelBox:SetText("0")

  if UDDM_Initialize and UDDM_CreateInfo and UDDM_AddButton then
    local function ColorsMatch(tbl, r, g, b)
      if type(tbl) ~= "table" then return false end
      return (tonumber(tbl[1]) == r) and (tonumber(tbl[2]) == g) and (tonumber(tbl[3]) == b)
    end

    local function SetTextColor(name)
      if name == "None" then
        panels.text._color = nil
      elseif name == "Green" then
        panels.text._color = { 0.1, 1.0, 0.1 }
      elseif name == "Blue" then
        panels.text._color = { 0.2, 0.6, 1.0 }
      elseif name == "Yellow" then
        panels.text._color = { 1.0, 0.9, 0.2 }
      elseif name == "Red" then
        panels.text._color = { 1.0, 0.2, 0.2 }
      elseif name == "Cyan" then
        panels.text._color = { 0.2, 1.0, 1.0 }
      else
        panels.text._color = nil
        name = "None"
      end
      if UDDM_SetText then UDDM_SetText(textColorDrop, name) end
    end

    local function SetFontKey(key)
      key = tostring(key or "inherit")
      if key == "" then key = "inherit" end
      panels.text._fontKey = key
      local label = (type(GetFontChoiceLabel) == "function") and GetFontChoiceLabel(key) or key
      if UDDM_SetText then UDDM_SetText(textFontDrop, label) end
    end

    local modernTextExpansion = UseModernMenuDropDown and UseModernMenuDropDown(expDrop, function(root)
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

    if not modernTextExpansion then
      UDDM_Initialize(expDrop, function(self, level)
        local choices = (type(GetRuleExpansionChoices) == "function") and GetRuleExpansionChoices() or { { id = -1, name = "Weekly" } }
        for _, e in ipairs(choices) do
          if type(e) == "table" then
            local id, name = e.id, e.name
            local info = UDDM_CreateInfo()
            info.text = name or "Weekly"
            info.checked = function()
              local curID, curName = nil, nil
              if type(GetRuleCreateExpansion) == "function" then
                curID, curName = GetRuleCreateExpansion()
              end
              return (tonumber(curID) == tonumber(id)) or (curName ~= nil and curName == name)
            end
            info.func = function()
              if type(SetRuleCreateExpansion) == "function" then
                SetRuleCreateExpansion(id, name)
              end
            end
            UDDM_AddButton(info)
          end
        end
      end)
    end

    local modernTextFrame = UseModernMenuDropDown and UseModernMenuDropDown(textFrameDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Bar / List") end
      for _, def in ipairs(GetEffectiveFrames()) do
        if type(def) == "table" and def.id and root then
          local id = tostring(def.id)
          local label = GetFrameDisplayNameByID(id)
          if root.CreateRadio then
            root:CreateRadio(label, function() return (panels.text._targetFrameID == id) end, function()
              panels.text._targetFrameID = id
              if UDDM_SetText then UDDM_SetText(textFrameDrop, GetFrameDisplayNameByID(id)) end
            end)
          elseif root.CreateButton then
            root:CreateButton(label, function()
              panels.text._targetFrameID = id
              if UDDM_SetText then UDDM_SetText(textFrameDrop, GetFrameDisplayNameByID(id)) end
            end)
          end
        end
      end
    end)

    local modernTextFaction = UseModernMenuDropDown and UseModernMenuDropDown(textFactionDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Faction") end
      local function Add(name, v)
        if not root then return end
        if root.CreateRadio then
          root:CreateRadio(name, function() return (panels.text._faction == v) end, function()
            panels.text._faction = v
            if UDDM_SetText then UDDM_SetText(textFactionDrop, name) end
          end)
        elseif root.CreateButton then
          root:CreateButton(name, function()
            panels.text._faction = v
            if UDDM_SetText then UDDM_SetText(textFactionDrop, name) end
          end)
        end
      end
      Add("Both (Off)", nil)
      Add("Alliance", "Alliance")
      Add("Horde", "Horde")
    end)

    local modernTextColor = UseModernMenuDropDown and UseModernMenuDropDown(textColorDrop, function(root)
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
          if name == "None" then return panels.text._color == nil end
          if not c then return false end
          return ColorsMatch(panels.text._color, c[1], c[2], c[3])
        end
        local function SetSelected()
          SetTextColor(name)
        end
        if root and root.CreateRadio then
          root:CreateRadio(name, IsSelected, SetSelected)
        elseif root and root.CreateButton then
          root:CreateButton(name, SetSelected)
        end
      end
    end)

    local modernTextFont = UseModernMenuDropDown and UseModernMenuDropDown(textFontDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Font") end
      local choices = (type(GetFontChoices) == "function") and GetFontChoices() or { { key = "inherit", label = "Inherit" } }
      for _, opt in ipairs(choices) do
        if type(opt) == "table" and opt.key and root then
          local key = tostring(opt.key)
          local label = tostring(opt.label or opt.key)
          if root.CreateRadio then
            root:CreateRadio(label, function() return (panels.text._fontKey == key) end, function() SetFontKey(key) end)
          elseif root.CreateButton then
            root:CreateButton(label, function() SetFontKey(key) end)
          end
        end
      end
    end)

    local modernTextRepMin = UseModernMenuDropDown and UseModernMenuDropDown(textRepMinDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Min Rep") end
      local opts = {
        { "Off", nil },
        { "Friendly", 5 },
        { "Honored", 6 },
        { "Revered", 7 },
        { "Exalted", 8 },
      }
      for _, opt in ipairs(opts) do
        local name, standing = opt[1], opt[2]
        local function IsSelected() return (panels.text._repMinStanding == standing) end
        local function SetSelected()
          panels.text._repMinStanding = standing
          if UDDM_SetText then UDDM_SetText(textRepMinDrop, name) end
        end
        if root and root.CreateRadio then
          root:CreateRadio(name, IsSelected, SetSelected)
        elseif root and root.CreateButton then
          root:CreateButton(name, SetSelected)
        end
      end
    end)

    local modernTextLevelOp = UseModernMenuDropDown and UseModernMenuDropDown(textLevelOpDrop, function(root)
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
        local function IsSelected() return (panels.text._playerLevelOp == op) end
        local function SetSelected()
          panels.text._playerLevelOp = op
          if UDDM_SetText then UDDM_SetText(textLevelOpDrop, name) end
        end
        if root and root.CreateRadio then
          root:CreateRadio(name, IsSelected, SetSelected)
        elseif root and root.CreateButton then
          root:CreateButton(name, SetSelected)
        end
      end
    end)

    if not modernTextFrame then
      UDDM_Initialize(textFrameDrop, function(self, level)
        for _, def in ipairs(GetEffectiveFrames()) do
          if type(def) == "table" and def.id then
            local id = tostring(def.id)
            local info = UDDM_CreateInfo()
            info.text = GetFrameDisplayNameByID(id)
            info.checked = (panels.text._targetFrameID == id) and true or false
            info.func = function()
              panels.text._targetFrameID = id
              if UDDM_SetText then UDDM_SetText(textFrameDrop, GetFrameDisplayNameByID(id)) end
            end
            UDDM_AddButton(info)
          end
        end
      end)
    end

    if not modernTextFaction then
      UDDM_Initialize(textFactionDrop, function(self, level)
        do
          local info = UDDM_CreateInfo()
          info.text = "Both (Off)"
          info.checked = (panels.text._faction == nil) and true or false
          info.func = function()
            panels.text._faction = nil
            if UDDM_SetText then UDDM_SetText(textFactionDrop, "Both (Off)") end
          end
          UDDM_AddButton(info)
        end
        do
          local info = UDDM_CreateInfo()
          info.text = "Alliance"
          info.checked = (panels.text._faction == "Alliance") and true or false
          info.func = function()
            panels.text._faction = "Alliance"
            if UDDM_SetText then UDDM_SetText(textFactionDrop, "Alliance") end
          end
          UDDM_AddButton(info)
        end
        do
          local info = UDDM_CreateInfo()
          info.text = "Horde"
          info.checked = (panels.text._faction == "Horde") and true or false
          info.func = function()
            panels.text._faction = "Horde"
            if UDDM_SetText then UDDM_SetText(textFactionDrop, "Horde") end
          end
          UDDM_AddButton(info)
        end
      end)
    end

    if not modernTextColor then
      UDDM_Initialize(textColorDrop, function(self, level)
        for _, name in ipairs({ "None", "Green", "Blue", "Yellow", "Red", "Cyan" }) do
          local info = UDDM_CreateInfo()
          info.text = name
          info.func = function() SetTextColor(name) end
          UDDM_AddButton(info)
        end
      end)
    end

    if not modernTextFont then
      UDDM_Initialize(textFontDrop, function(self, level)
        local choices = (type(GetFontChoices) == "function") and GetFontChoices() or { { key = "inherit", label = "Inherit" } }
        for _, opt in ipairs(choices) do
          if type(opt) == "table" and opt.key then
            local key = tostring(opt.key)
            local info = UDDM_CreateInfo()
            info.text = tostring(opt.label or opt.key)
            info.checked = (panels.text._fontKey == key) and true or false
            info.func = function() SetFontKey(key) end
            UDDM_AddButton(info)
          end
        end
      end)
    end

    if not modernTextRepMin then
      UDDM_Initialize(textRepMinDrop, function(self, level)
        local function Add(name, standing)
          local info = UDDM_CreateInfo()
          info.text = name
          info.checked = (panels.text._repMinStanding == standing) and true or false
          info.func = function()
            panels.text._repMinStanding = standing
            if UDDM_SetText then UDDM_SetText(textRepMinDrop, name) end
          end
          UDDM_AddButton(info)
        end
        Add("Off", nil)
        Add("Friendly", 5)
        Add("Honored", 6)
        Add("Revered", 7)
        Add("Exalted", 8)
      end)
    end

    if not modernTextLevelOp then
      UDDM_Initialize(textLevelOpDrop, function(self, level)
        local function Add(name, op)
          local info = UDDM_CreateInfo()
          info.text = name
          info.checked = (panels.text._playerLevelOp == op) and true or false
          info.func = function()
            panels.text._playerLevelOp = op
            if UDDM_SetText then UDDM_SetText(textLevelOpDrop, name) end
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

  local addTextBtn = CreateFrame("Button", nil, panels.text, "UIPanelButtonTemplate")
  addTextBtn:SetSize(140, 22)
  addTextBtn:SetPoint("TOPLEFT", 12, -286)
  addTextBtn:SetText("Add Text Entry")

  panels.text._textNameBox = textNameBox
  panels.text._textInfoBox = textInfoBox
  panels.text._textFrameDrop = textFrameDrop
  panels.text._textFactionDrop = textFactionDrop
  panels.text._textColorDrop = textColorDrop
  panels.text._fontDrop = textFontDrop
  panels.text._sizeBox = textSizeBox
  panels.text._repFactionBox = textRepFactionBox
  panels.text._repMinDrop = textRepMinDrop
  panels.text._restedOnly = textRestedOnly
  panels.text._locBox = textLocBox
  panels.text._textLevelOpDrop = textLevelOpDrop
  panels.text._textLevelBox = textLevelBox
  panels.text._addTextBtn = addTextBtn

  local cancelTextEditBtn = CreateFrame("Button", nil, panels.text, "UIPanelButtonTemplate")
  cancelTextEditBtn:SetSize(120, 22)
  cancelTextEditBtn:SetPoint("LEFT", addTextBtn, "RIGHT", 8, 0)
  cancelTextEditBtn:SetText("Cancel Edit")
  cancelTextEditBtn:Hide()
  panels.text._cancelEditBtn = cancelTextEditBtn

  local function ClearTextInputs()
    if textNameBox then textNameBox:SetText("") end
    if textInfoBox then textInfoBox:SetText("") end
    if textInfoScroll and textInfoScroll.SetVerticalScroll then textInfoScroll:SetVerticalScroll(0) end

    panels.text._targetFrameID = "list1"
    if UDDM_SetText and textFrameDrop then UDDM_SetText(textFrameDrop, GetFrameDisplayNameByID("list1")) end

    panels.text._faction = nil
    if UDDM_SetText and textFactionDrop then UDDM_SetText(textFactionDrop, "Both (Off)") end

    panels.text._color = nil
    if UDDM_SetText and textColorDrop then UDDM_SetText(textColorDrop, "None") end

    panels.text._fontKey = "inherit"
    if UDDM_SetText and textFontDrop then UDDM_SetText(textFontDrop, "Inherit") end
    if textSizeBox then textSizeBox:SetText("0") end

    if textRepFactionBox then textRepFactionBox:SetText("0") end
    panels.text._repMinStanding = nil
    if UDDM_SetText and textRepMinDrop then UDDM_SetText(textRepMinDrop, "Off") end

    if textRestedOnly then textRestedOnly:SetChecked(false) end
    if textLocBox then textLocBox:SetText("0") end

    panels.text._playerLevelOp = nil
    if UDDM_SetText and textLevelOpDrop then UDDM_SetText(textLevelOpDrop, "Off") end
    if textLevelBox then textLevelBox:SetText("0") end

    panels.text._editingCustomIndex = nil
    panels.text._editingDefaultBase = nil
    panels.text._editingDefaultKey = nil
    if addTextBtn then addTextBtn:SetText("Add Text Entry") end
    if cancelTextEditBtn then cancelTextEditBtn:Hide() end
  end

  addTextBtn:SetScript("OnClick", function()
    local nameText = tostring(textNameBox:GetText() or "")
    nameText = nameText:gsub("^%s+", ""):gsub("%s+$", "")
    if nameText == "" then
      Print("Enter a Text Name.")
      return
    end

    local infoText = tostring(textInfoBox:GetText() or "")
    infoText = infoText:gsub("^%s+", ""):gsub("%s+$", "")
    local textInfo = (infoText ~= "" and infoText ~= nameText) and infoText or nil

    local targetFrame = tostring(panels.text._targetFrameID or ""):gsub("%s+", "")
    if targetFrame == "" then targetFrame = "list1" end

    local repFactionID = tonumber(textRepFactionBox:GetText() or "")
    if repFactionID and repFactionID <= 0 then repFactionID = nil end
    local rep = nil
    if repFactionID and panels.text._repMinStanding then
      rep = { factionID = repFactionID, minStanding = panels.text._repMinStanding }
    end

    local locText = tostring(textLocBox:GetText() or ""):gsub("%s+", "")
    local locationID = (locText ~= "" and locText ~= "0") and locText or nil

    local fontKey = tostring(panels.text._fontKey or "inherit")
    if fontKey == "" then fontKey = "inherit" end
    local fontSize = (textSizeBox and tonumber(textSizeBox:GetText() or "")) or 0
    if not fontSize or fontSize < 0 then fontSize = 0 end

    -- Expansion selection (shared across all rule create tabs)
    local expID, expName = nil, nil
    if type(GetRuleCreateExpansion) == "function" then
      expID, expName = GetRuleCreateExpansion()
    end
    if not expName and expID then expName = ResolveExpansionNameByID(expID) end

    local rules = GetCustomRules()
    if panels.text._editingCustomIndex and type(rules[panels.text._editingCustomIndex]) == "table" then
      local rule = rules[panels.text._editingCustomIndex]
      rule.frameID = targetFrame
      rule.label = nameText
      rule.textInfo = textInfo
      rule.faction = panels.text._faction
      rule.color = panels.text._color
      rule.font = fontKey
      rule.size = fontSize
      rule.rep = rep
      rule.restedOnly = textRestedOnly:GetChecked() and true or false
      rule.locationID = locationID

      if expID then
        rule._expansionID = expID
        rule._expansionName = expName
      else
        rule._expansionID = nil
        rule._expansionName = nil
      end

      local op = panels.text._playerLevelOp
      local lvl = textLevelBox and tonumber(textLevelBox:GetText() or "") or nil
      if lvl and lvl <= 0 then lvl = nil end
      if op and lvl then
        rule.playerLevelOp = nil
        rule.playerLevel = { op, lvl }
      else
        rule.playerLevelOp = nil
        rule.playerLevel = nil
      end

      if rule.hideWhenCompleted == nil then rule.hideWhenCompleted = false end

      panels.text._editingCustomIndex = nil
      panels.text._editingDefaultBase = nil
      panels.text._editingDefaultKey = nil
      addTextBtn:SetText("Add Text Entry")
      cancelTextEditBtn:Hide()
      Print("Saved text entry.")
    elseif panels.text._editingDefaultBase and panels.text._editingDefaultKey and type(GetDefaultRuleEdits) == "function" then
      local edits = GetDefaultRuleEdits()
      local base = panels.text._editingDefaultBase
      local key = tostring(panels.text._editingDefaultKey)
      local effective = (type(edits[key]) == "table") and edits[key] or base
      local rule = DeepCopyValue(effective)

      rule.frameID = targetFrame
      rule.label = nameText
      rule.textInfo = textInfo
      rule.faction = panels.text._faction
      rule.color = panels.text._color
      rule.font = fontKey
      rule.size = fontSize
      rule.rep = rep
      rule.restedOnly = textRestedOnly:GetChecked() and true or false
      rule.locationID = locationID

      if expID then
        rule._expansionID = expID
        rule._expansionName = expName
      else
        rule._expansionID = nil
        rule._expansionName = nil
      end

      local op = panels.text._playerLevelOp
      local lvl = textLevelBox and tonumber(textLevelBox:GetText() or "") or nil
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

      panels.text._editingCustomIndex = nil
      panels.text._editingDefaultBase = nil
      panels.text._editingDefaultKey = nil
      addTextBtn:SetText("Add Text Entry")
      cancelTextEditBtn:Hide()
      Print("Saved default text rule edit.")
    else
      local key = string.format("custom:text:%s:%s:%d", tostring(targetFrame), tostring(nameText), (#rules + 1))
      local op = panels.text._playerLevelOp
      local lvl = textLevelBox and tonumber(textLevelBox:GetText() or "") or nil
      if lvl and lvl <= 0 then lvl = nil end
      if not (op and lvl) then op = nil; lvl = nil end
      local r = {
        key = key,
        frameID = targetFrame,
        label = nameText,
        textInfo = textInfo,
        faction = panels.text._faction,
        color = panels.text._color,
        font = fontKey,
        size = fontSize,
        rep = rep,
        restedOnly = textRestedOnly:GetChecked() and true or false,
        locationID = locationID,
        playerLevel = (op and lvl) and { op, lvl } or nil,
        hideWhenCompleted = false,
      }

      if expID then
        r._expansionID = expID
        r._expansionName = expName
      end

      rules[#rules + 1] = r

      Print("Added text entry -> " .. targetFrame)
    end

    if CreateAllFrames then CreateAllFrames() end
    if RefreshAll then RefreshAll() end
    if RefreshRulesList then RefreshRulesList() end
    if not GetKeepEditFormOpen() then
      ClearTextInputs()
      if SelectTab then SelectTab("rules") end
    end
  end)

  cancelTextEditBtn:SetScript("OnClick", function()
    panels.text._editingCustomIndex = nil
    panels.text._editingDefaultBase = nil
    panels.text._editingDefaultKey = nil
    addTextBtn:SetText("Add Text Entry")
    cancelTextEditBtn:Hide()

    if not GetKeepEditFormOpen() then
      ClearTextInputs()
      if SelectTab then SelectTab("rules") end
    end
  end)
end
