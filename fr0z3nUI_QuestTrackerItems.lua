local addonName, ns = ...

ns.FQTOptionsPanels = ns.FQTOptionsPanels or {}

function ns.FQTOptionsPanels.BuildItems(ctx)
  if type(ctx) ~= "table" then return end

  local panels = ctx.panels
  if not (panels and panels.items) then return end

  local Print = ctx.Print or function(...) end
  local CreateFrame = ctx.CreateFrame or CreateFrame

  local UseModernMenuDropDown = ctx.UseModernMenuDropDown
  local GetEffectiveFrames = ctx.GetEffectiveFrames
  local GetFrameDisplayNameByID = ctx.GetFrameDisplayNameByID

  local GetItemNameSafe = ctx.GetItemNameSafe

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
  local HideDropDownMenuArt = ctx.HideDropDownMenuArt
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

  local pItems = panels.items

  local itemsTitle = pItems:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  itemsTitle:SetPoint("TOPLEFT", 12, -40)
  itemsTitle:SetText("Items")

  -- Expansion selector (stamped onto new/edited rules as _expansionID/_expansionName)
  local expLabel = pItems:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  expLabel:SetPoint("TOPRIGHT", pItems, "TOPRIGHT", -12, -40)
  expLabel:SetText("Expansion")

  local expDrop = CreateFrame("Frame", nil, pItems, "UIDropDownMenuTemplate")
  expDrop:SetPoint("TOPRIGHT", pItems, "TOPRIGHT", -6, -54)
  if UDDM_SetWidth then UDDM_SetWidth(expDrop, 180) end
  if UDDM_SetText then UDDM_SetText(expDrop, "") end
  pItems._expansionDrop = expDrop

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

  function pItems:_syncRuleCreateExpansion()
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
  elseif pItems._syncRuleCreateExpansion then
    pItems:_syncRuleCreateExpansion()
  end

  local itemIDBox = CreateFrame("EditBox", nil, pItems, "InputBoxTemplate")
  itemIDBox:SetSize(70, 20)
  itemIDBox:SetPoint("TOPLEFT", 12, -62)
  itemIDBox:SetAutoFocus(false)
  itemIDBox:SetNumeric(true)
  itemIDBox:SetText("")
  itemIDBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  itemIDBox:SetTextInsets(6, 6, 0, 0)
  if AddPlaceholder then AddPlaceholder(itemIDBox, "ItemID") end
  if HideInputBoxTemplateArt then HideInputBoxTemplateArt(itemIDBox) end

  local itemNameBox = CreateFrame("EditBox", nil, pItems, "InputBoxTemplate")
  itemNameBox:SetSize(170, 20)
  itemNameBox:SetPoint("TOPLEFT", 90, -62)
  itemNameBox:SetAutoFocus(false)
  itemNameBox:SetText("")
  itemNameBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  itemNameBox:SetTextInsets(6, 6, 0, 0)
  if AddPlaceholder then AddPlaceholder(itemNameBox, "Item Name") end
  if HideInputBoxTemplateArt then HideInputBoxTemplateArt(itemNameBox) end

  local itemInfoScroll = CreateFrame("ScrollFrame", nil, pItems, "UIPanelScrollFrameTemplate")
  itemInfoScroll:SetPoint("TOPLEFT", 90, -86)
  itemInfoScroll:SetSize(170, 44)

  local itemInfoBox = CreateFrame("EditBox", nil, itemInfoScroll)
  itemInfoBox:SetMultiLine(true)
  itemInfoBox:SetAutoFocus(false)
  itemInfoBox:SetFontObject("ChatFontNormal")
  itemInfoBox:SetWidth(150)
  itemInfoBox:SetTextInsets(6, 6, 6, 6)
  itemInfoBox:SetText("")
  itemInfoBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  itemInfoBox:SetScript("OnCursorChanged", function(self, x, y, w, h)
    if not itemInfoScroll then return end
    itemInfoScroll:UpdateScrollChildRect()
    local offset = itemInfoScroll:GetVerticalScroll() or 0
    local height = itemInfoScroll:GetHeight() or 0
    local top = -y
    if top < offset then
      itemInfoScroll:SetVerticalScroll(top)
    elseif top > offset + height - 20 then
      itemInfoScroll:SetVerticalScroll(top - height + 20)
    end
  end)

  itemInfoScroll:SetScrollChild(itemInfoBox)
  if AddPlaceholder then AddPlaceholder(itemInfoBox, "Item Info") end

  pItems._itemInfoScroll = itemInfoScroll

  local itemQuestIDBox = CreateFrame("EditBox", nil, pItems, "InputBoxTemplate")
  itemQuestIDBox:SetSize(70, 20)
  itemQuestIDBox:SetPoint("TOPLEFT", 270, -62)
  itemQuestIDBox:SetAutoFocus(false)
  itemQuestIDBox:SetNumeric(true)
  itemQuestIDBox:SetText("")
  itemQuestIDBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  itemQuestIDBox:SetTextInsets(6, 6, 0, 0)
  if AddPlaceholder then AddPlaceholder(itemQuestIDBox, "QuestID") end
  if HideInputBoxTemplateArt then HideInputBoxTemplateArt(itemQuestIDBox) end

  local itemAfterQuestIDBox = CreateFrame("EditBox", nil, pItems, "InputBoxTemplate")
  itemAfterQuestIDBox:SetSize(80, 20)
  itemAfterQuestIDBox:SetPoint("TOPLEFT", 350, -62)
  itemAfterQuestIDBox:SetAutoFocus(false)
  itemAfterQuestIDBox:SetNumeric(true)
  itemAfterQuestIDBox:SetText("")
  itemAfterQuestIDBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  itemAfterQuestIDBox:SetTextInsets(6, 6, 0, 0)
  if AddPlaceholder then AddPlaceholder(itemAfterQuestIDBox, "After QuestID") end
  if HideInputBoxTemplateArt then HideInputBoxTemplateArt(itemAfterQuestIDBox) end

  local itemCurrencyIDBox = CreateFrame("EditBox", nil, pItems, "InputBoxTemplate")
  itemCurrencyIDBox:SetSize(70, 20)
  itemCurrencyIDBox:SetPoint("TOPLEFT", 440, -62)
  itemCurrencyIDBox:SetAutoFocus(false)
  itemCurrencyIDBox:SetNumeric(true)
  itemCurrencyIDBox:SetText("")
  itemCurrencyIDBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  itemCurrencyIDBox:SetTextInsets(6, 6, 0, 0)
  if AddPlaceholder then AddPlaceholder(itemCurrencyIDBox, "CurrencyID") end
  if HideInputBoxTemplateArt then HideInputBoxTemplateArt(itemCurrencyIDBox) end

  local itemCurrencyReqBox = CreateFrame("EditBox", nil, pItems, "InputBoxTemplate")
  itemCurrencyReqBox:SetSize(70, 20)
  itemCurrencyReqBox:SetPoint("TOPLEFT", 520, -62)
  itemCurrencyReqBox:SetAutoFocus(false)
  itemCurrencyReqBox:SetNumeric(true)
  itemCurrencyReqBox:SetText("")
  itemCurrencyReqBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  itemCurrencyReqBox:SetTextInsets(6, 6, 0, 0)
  if AddPlaceholder then AddPlaceholder(itemCurrencyReqBox, "MinCur") end
  if HideInputBoxTemplateArt then HideInputBoxTemplateArt(itemCurrencyReqBox) end

  local itemShowBelowBox = CreateFrame("EditBox", nil, pItems, "InputBoxTemplate")
  itemShowBelowBox:SetSize(100, 20)
  itemShowBelowBox:SetPoint("TOPLEFT", 12, -132)
  itemShowBelowBox:SetAutoFocus(false)
  itemShowBelowBox:SetNumeric(true)
  itemShowBelowBox:SetText("")
  itemShowBelowBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  itemShowBelowBox:SetTextInsets(6, 6, 0, 0)
  if AddPlaceholder then AddPlaceholder(itemShowBelowBox, "Show <") end
  if HideInputBoxTemplateArt then HideInputBoxTemplateArt(itemShowBelowBox) end

  pItems._itemIDBox = itemIDBox
  pItems._itemNameBox = itemNameBox
  pItems._itemInfoBox = itemInfoBox
  pItems._itemQuestIDBox = itemQuestIDBox
  pItems._itemAfterQuestIDBox = itemAfterQuestIDBox
  pItems._itemCurrencyIDBox = itemCurrencyIDBox
  pItems._itemCurrencyReqBox = itemCurrencyReqBox
  pItems._itemShowBelowBox = itemShowBelowBox

  local function UpdateItemFieldsFromID(force)
    local id = tonumber(pItems._itemIDBox and pItems._itemIDBox:GetText() or "")
    if not id or id <= 0 then
      pItems._pendingItemLabelID = nil
      pItems._pendingItemLabelForce = nil
      return
    end

    local name = GetItemNameSafe and GetItemNameSafe(id) or nil
    if type(name) ~= "string" or name == "" then
      pItems._pendingItemLabelID = id
      pItems._pendingItemLabelForce = force and true or false
      if C_Item and C_Item.RequestLoadItemDataByID then
        pcall(C_Item.RequestLoadItemDataByID, id)
      end
      return
    end

    local nb = pItems._itemNameBox
    if nb then
      if force then
        nb._autoName = name
        nb:SetText(name)
      else
        local cur = tostring(nb:GetText() or "")
        if cur == "" or (nb._autoName ~= nil and cur == tostring(nb._autoName)) then
          nb._autoName = name
          nb:SetText(name)
        end
      end
    end

    local ib = pItems._itemInfoBox
    if ib then
      if force then
        ib._autoInfo = name
        ib:SetText(name)
      else
        local cur = tostring(ib:GetText() or "")
        if cur == "" or (ib._autoInfo ~= nil and cur == tostring(ib._autoInfo)) then
          ib._autoInfo = name
          ib:SetText(name)
        end
      end
    end
  end

  do
    local nameLoadFrame = CreateFrame("Frame")
    nameLoadFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    nameLoadFrame:RegisterEvent("ITEM_DATA_LOAD_RESULT")
    nameLoadFrame:SetScript("OnEvent", function(_, _, itemID, success)
      itemID = tonumber(itemID)
      if not itemID or success == false then return end
      if pItems._pendingItemLabelID and itemID == tonumber(pItems._pendingItemLabelID) then
        local force = pItems._pendingItemLabelForce and true or false
        UpdateItemFieldsFromID(force)
        local got = GetItemNameSafe and GetItemNameSafe(itemID) or nil
        if type(got) == "string" and got ~= "" then
          pItems._pendingItemLabelID = nil
          pItems._pendingItemLabelForce = nil
        end
      end
    end)
  end

  itemNameBox:HookScript("OnTextChanged", function(self, userInput)
    if not userInput then return end
    local cur = tostring(self:GetText() or "")
    if self._autoName ~= nil and cur ~= tostring(self._autoName) then
      self._autoName = nil
    end
  end)

  itemInfoBox:HookScript("OnTextChanged", function(self, userInput)
    if not userInput then return end
    local cur = tostring(self:GetText() or "")
    if self._autoInfo ~= nil and cur ~= tostring(self._autoInfo) then
      self._autoInfo = nil
    end
  end)

  itemIDBox:HookScript("OnTextChanged", function(self, userInput)
    if not userInput then return end
    UpdateItemFieldsFromID(GetKeepEditFormOpen and GetKeepEditFormOpen())
  end)

  local itemsFrameLabel = pItems:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  itemsFrameLabel:SetPoint("TOPLEFT", 12, -146)
  itemsFrameLabel:SetText("Bar / List")

  local itemsFrameDrop = CreateFrame("Frame", nil, pItems, "UIDropDownMenuTemplate")
  itemsFrameDrop:SetPoint("TOPLEFT", -8, -174)
  if UDDM_SetWidth then UDDM_SetWidth(itemsFrameDrop, 160) end
  if UDDM_SetText then UDDM_SetText(itemsFrameDrop, GetFrameDisplayNameByID("list1")) end
  pItems._targetFrameID = "list1"
  if HideDropDownMenuArt then HideDropDownMenuArt(itemsFrameDrop) end

  local itemsFactionLabel = pItems:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  itemsFactionLabel:SetPoint("TOPLEFT", 180, -146)
  itemsFactionLabel:SetText("Faction")

  local itemsFactionDrop = CreateFrame("Frame", nil, pItems, "UIDropDownMenuTemplate")
  itemsFactionDrop:SetPoint("TOPLEFT", 165, -174)
  if UDDM_SetWidth then UDDM_SetWidth(itemsFactionDrop, 140) end
  if UDDM_SetText then UDDM_SetText(itemsFactionDrop, "Both (Off)") end
  pItems._faction = nil
  if HideDropDownMenuArt then HideDropDownMenuArt(itemsFactionDrop) end

  local itemsColorLabel = pItems:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  itemsColorLabel:SetPoint("TOPLEFT", 340, -146)
  itemsColorLabel:SetText("Color")

  local itemsColorDrop = CreateFrame("Frame", nil, pItems, "UIDropDownMenuTemplate")
  itemsColorDrop:SetPoint("TOPLEFT", 325, -174)
  if UDDM_SetWidth then UDDM_SetWidth(itemsColorDrop, 140) end
  if UDDM_SetText then UDDM_SetText(itemsColorDrop, "None") end
  pItems._color = nil
  if HideDropDownMenuArt then HideDropDownMenuArt(itemsColorDrop) end

  local itemsFontLabel = pItems:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  itemsFontLabel:SetPoint("TOPLEFT", 500, -146)
  itemsFontLabel:SetText("Font")

  local itemsFontDrop = CreateFrame("Frame", nil, pItems, "UIDropDownMenuTemplate")
  itemsFontDrop:SetPoint("TOPLEFT", 485, -174)
  if UDDM_SetWidth then UDDM_SetWidth(itemsFontDrop, 170) end
  if UDDM_SetText then UDDM_SetText(itemsFontDrop, "Inherit") end
  pItems._fontDrop = itemsFontDrop
  pItems._fontKey = "inherit"
  if HideDropDownMenuArt then HideDropDownMenuArt(itemsFontDrop) end

  local itemsSizeLabel = pItems:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  itemsSizeLabel:SetPoint("TOPLEFT", 500, -210)
  itemsSizeLabel:SetText("Size")

  local itemsSizeBox = CreateFrame("EditBox", nil, pItems, "InputBoxTemplate")
  itemsSizeBox:SetSize(50, 20)
  itemsSizeBox:SetPoint("TOPLEFT", 500, -226)
  itemsSizeBox:SetAutoFocus(false)
  itemsSizeBox:SetNumeric(true)
  itemsSizeBox:SetText("0")
  if HideInputBoxTemplateArt then HideInputBoxTemplateArt(itemsSizeBox) end
  pItems._sizeBox = itemsSizeBox

  -- Quick color palette for item text color
  if CreateQuickColorPalette then
    CreateQuickColorPalette(pItems, itemsColorDrop, "TOPLEFT", "BOTTOMLEFT", 26, 12, {
      cols = 5,
      getColor = function()
        if type(pItems._color) == "table" then
          return pItems._color[1], pItems._color[2], pItems._color[3]
        end
        return nil
      end,
      onPick = function(r, g, b)
        pItems._color = { r, g, b }
        if UDDM_SetText then UDDM_SetText(itemsColorDrop, "Custom") end
      end,
    })
  end

  local repFactionLabel = pItems:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  repFactionLabel:SetPoint("TOPLEFT", 12, -210)
  repFactionLabel:SetText("Rep FactionID")

  local repFactionBox = CreateFrame("EditBox", nil, pItems, "InputBoxTemplate")
  repFactionBox:SetSize(90, 20)
  repFactionBox:SetPoint("TOPLEFT", 12, -226)
  repFactionBox:SetAutoFocus(false)
  repFactionBox:SetNumeric(true)
  repFactionBox:SetText("")
  repFactionBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  repFactionBox:SetTextInsets(6, 6, 0, 0)
  if AddPlaceholder then AddPlaceholder(repFactionBox, "Rep FactionID") end
  if HideInputBoxTemplateArt then HideInputBoxTemplateArt(repFactionBox) end

  local repMinLabel = pItems:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  repMinLabel:SetPoint("TOPLEFT", 110, -210)
  repMinLabel:SetText("Min Rep")

  local repMinDrop = CreateFrame("Frame", nil, pItems, "UIDropDownMenuTemplate")
  repMinDrop:SetPoint("TOPLEFT", 95, -238)
  if UDDM_SetWidth then UDDM_SetWidth(repMinDrop, 140) end
  if UDDM_SetText then UDDM_SetText(repMinDrop, "Off") end
  pItems._repMinStanding = nil
  if HideDropDownMenuArt then HideDropDownMenuArt(repMinDrop) end

  local hideAcquired = CreateFrame("CheckButton", nil, pItems, "UICheckButtonTemplate")
  hideAcquired:SetPoint("TOPLEFT", 250, -228)
  if SetCheckButtonLabel then SetCheckButtonLabel(hideAcquired, "Hide when acquired") end
  hideAcquired:SetChecked(false)

  local hideExalted = CreateFrame("CheckButton", nil, pItems, "UICheckButtonTemplate")
  hideExalted:SetPoint("TOPLEFT", 400, -228)
  if SetCheckButtonLabel then SetCheckButtonLabel(hideExalted, "Hide when exalted") end
  hideExalted:SetChecked(false)

  local sellExalted = CreateFrame("CheckButton", nil, pItems, "UICheckButtonTemplate")
  sellExalted:SetPoint("TOPLEFT", 400, -252)
  if SetCheckButtonLabel then SetCheckButtonLabel(sellExalted, "Sell when exalted") end
  sellExalted:SetChecked(false)
  sellExalted:SetScript("OnClick", function()
    if sellExalted:GetChecked() and hideExalted then
      hideExalted:SetChecked(false)
    end
  end)
  hideExalted:HookScript("OnClick", function()
    if hideExalted:GetChecked() and sellExalted then
      sellExalted:SetChecked(false)
    end
  end)

  local restedOnly = CreateFrame("CheckButton", nil, pItems, "UICheckButtonTemplate")
  restedOnly:SetPoint("TOPLEFT", 12, -252)
  if SetCheckButtonLabel then SetCheckButtonLabel(restedOnly, "Rested areas only") end
  restedOnly:SetChecked(false)

  local itemsLevelLabel = pItems:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  itemsLevelLabel:SetPoint("TOPLEFT", 250, -258)
  itemsLevelLabel:SetText("Player level")

  local itemsLevelOpDrop = CreateFrame("Frame", nil, pItems, "UIDropDownMenuTemplate")
  itemsLevelOpDrop:SetPoint("TOPLEFT", 235, -278)
  if UDDM_SetWidth then UDDM_SetWidth(itemsLevelOpDrop, 70) end
  if UDDM_SetText then UDDM_SetText(itemsLevelOpDrop, "Off") end
  pItems._playerLevelOp = nil
  if HideDropDownMenuArt then HideDropDownMenuArt(itemsLevelOpDrop) end

  local itemsLevelBox = CreateFrame("EditBox", nil, pItems, "InputBoxTemplate")
  itemsLevelBox:SetSize(50, 20)
  itemsLevelBox:SetPoint("TOPLEFT", 340, -274)
  itemsLevelBox:SetAutoFocus(false)
  itemsLevelBox:SetNumeric(true)
  itemsLevelBox:SetText("")
  itemsLevelBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  itemsLevelBox:SetTextInsets(6, 6, 0, 0)
  if AddPlaceholder then AddPlaceholder(itemsLevelBox, "Lvl") end
  if HideInputBoxTemplateArt then HideInputBoxTemplateArt(itemsLevelBox) end

  local itemsLocLabel = pItems:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  itemsLocLabel:SetPoint("TOPLEFT", 12, -282)
  itemsLocLabel:SetText("LocationID (uiMapID)")

  local itemsLocBox = CreateFrame("EditBox", nil, pItems, "InputBoxTemplate")
  itemsLocBox:SetSize(90, 20)
  itemsLocBox:SetPoint("TOPLEFT", 12, -298)
  itemsLocBox:SetAutoFocus(false)
  itemsLocBox:SetText("")
  itemsLocBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  itemsLocBox:SetTextInsets(6, 6, 0, 0)
  if AddPlaceholder then AddPlaceholder(itemsLocBox, "uiMapID") end
  if HideInputBoxTemplateArt then HideInputBoxTemplateArt(itemsLocBox) end
  if AttachLocationIDTooltip then AttachLocationIDTooltip(itemsLocBox) end

  if UDDM_Initialize and UDDM_CreateInfo and UDDM_AddButton then
    -- Expansion dropdown
    local modernExpansion = UseModernMenuDropDown and UseModernMenuDropDown(expDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Expansion") end
      local choices = (type(GetRuleExpansionChoices) == "function") and GetRuleExpansionChoices() or { { id = -1, name = "Weekly" } }

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

    local function ColorsMatch(tbl, r, g, b)
      if type(tbl) ~= "table" then return false end
      return (tonumber(tbl[1]) == r) and (tonumber(tbl[2]) == g) and (tonumber(tbl[3]) == b)
    end

    local function SetItemsColor(name)
      if name == "None" then
        pItems._color = nil
      elseif name == "Green" then
        pItems._color = { 0.1, 1.0, 0.1 }
      elseif name == "Blue" then
        pItems._color = { 0.2, 0.6, 1.0 }
      elseif name == "Yellow" then
        pItems._color = { 1.0, 0.9, 0.2 }
      elseif name == "Red" then
        pItems._color = { 1.0, 0.2, 0.2 }
      elseif name == "Cyan" then
        pItems._color = { 0.2, 1.0, 1.0 }
      else
        pItems._color = nil
        name = "None"
      end
      if UDDM_SetText then UDDM_SetText(pItems._itemsColorDrop, name) end
    end

    local function SetFontKey(key)
      key = tostring(key or "inherit")
      if key == "" then key = "inherit" end
      pItems._fontKey = key
      local label = (type(GetFontChoiceLabel) == "function") and GetFontChoiceLabel(key) or key
      if UDDM_SetText then UDDM_SetText(pItems._fontDrop, label) end
    end

    local modernItemsFrame = UseModernMenuDropDown and UseModernMenuDropDown(itemsFrameDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Bar / List") end
      for _, def in ipairs(GetEffectiveFrames()) do
        if type(def) == "table" and def.id and root then
          local id = tostring(def.id)
          local label = GetFrameDisplayNameByID(id)
          if root.CreateRadio then
            root:CreateRadio(label, function() return (pItems._targetFrameID == id) end, function()
              pItems._targetFrameID = id
              if UDDM_SetText then UDDM_SetText(pItems._itemsFrameDrop, GetFrameDisplayNameByID(id)) end
            end)
          elseif root.CreateButton then
            root:CreateButton(label, function()
              pItems._targetFrameID = id
              if UDDM_SetText then UDDM_SetText(pItems._itemsFrameDrop, GetFrameDisplayNameByID(id)) end
            end)
          end
        end
      end
    end)

    local modernItemsFaction = UseModernMenuDropDown and UseModernMenuDropDown(itemsFactionDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Faction") end
      local function Add(name, v)
        if not root then return end
        if root.CreateRadio then
          root:CreateRadio(name, function() return (pItems._faction == v) end, function()
            pItems._faction = v
            if UDDM_SetText then UDDM_SetText(pItems._itemsFactionDrop, name) end
          end)
        elseif root.CreateButton then
          root:CreateButton(name, function()
            pItems._faction = v
            if UDDM_SetText then UDDM_SetText(pItems._itemsFactionDrop, name) end
          end)
        end
      end
      Add("Both (Off)", nil)
      Add("Alliance", "Alliance")
      Add("Horde", "Horde")
    end)

    local modernItemsColor = UseModernMenuDropDown and UseModernMenuDropDown(itemsColorDrop, function(root)
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
          if name == "None" then return pItems._color == nil end
          if not c then return false end
          return ColorsMatch(pItems._color, c[1], c[2], c[3])
        end
        local function SetSelected()
          SetItemsColor(name)
        end
        if root and root.CreateRadio then
          root:CreateRadio(name, IsSelected, SetSelected)
        elseif root and root.CreateButton then
          root:CreateButton(name, SetSelected)
        end
      end
    end)

    local modernItemsFont = UseModernMenuDropDown and UseModernMenuDropDown(itemsFontDrop, function(root)
      if root and root.CreateTitle then root:CreateTitle("Font") end
      local choices = (type(GetFontChoices) == "function") and GetFontChoices() or { { key = "inherit", label = "Inherit" } }
      for _, opt in ipairs(choices) do
        if type(opt) == "table" and opt.key and root then
          local key = tostring(opt.key)
          local label = tostring(opt.label or opt.key)
          if root.CreateRadio then
            root:CreateRadio(label, function() return (pItems._fontKey == key) end, function() SetFontKey(key) end)
          elseif root.CreateButton then
            root:CreateButton(label, function() SetFontKey(key) end)
          end
        end
      end
    end)

    local modernItemsRepMin = UseModernMenuDropDown and UseModernMenuDropDown(repMinDrop, function(root)
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
        local function IsSelected() return (pItems._repMinStanding == standing) end
        local function SetSelected()
          pItems._repMinStanding = standing
          if UDDM_SetText then UDDM_SetText(pItems._repMinDrop, name) end
        end
        if root and root.CreateRadio then
          root:CreateRadio(name, IsSelected, SetSelected)
        elseif root and root.CreateButton then
          root:CreateButton(name, SetSelected)
        end
      end
    end)

    local modernItemsLevelOp = UseModernMenuDropDown and UseModernMenuDropDown(itemsLevelOpDrop, function(root)
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
        local function IsSelected() return (pItems._playerLevelOp == op) end
        local function SetSelected()
          pItems._playerLevelOp = op
          if UDDM_SetText then UDDM_SetText(pItems._itemsLevelOpDrop, name) end
        end
        if root and root.CreateRadio then
          root:CreateRadio(name, IsSelected, SetSelected)
        elseif root and root.CreateButton then
          root:CreateButton(name, SetSelected)
        end
      end
    end)

    if not modernItemsFrame then
      UDDM_Initialize(itemsFrameDrop, function(self, level)
        for _, def in ipairs(GetEffectiveFrames()) do
          if type(def) == "table" and def.id then
            local id = tostring(def.id)
            local info = UDDM_CreateInfo()
            info.text = GetFrameDisplayNameByID(id)
            info.checked = (pItems._targetFrameID == id) and true or false
            info.func = function()
              pItems._targetFrameID = id
              if UDDM_SetText then UDDM_SetText(pItems._itemsFrameDrop, GetFrameDisplayNameByID(id)) end
            end
            UDDM_AddButton(info)
          end
        end
      end)
    end

    if not modernItemsFaction then
      UDDM_Initialize(itemsFactionDrop, function(self, level)
        do
          local info = UDDM_CreateInfo()
          info.text = "Both (Off)"
          info.checked = (pItems._faction == nil) and true or false
          info.func = function()
            pItems._faction = nil
            if UDDM_SetText then UDDM_SetText(pItems._itemsFactionDrop, "Both (Off)") end
          end
          UDDM_AddButton(info)
        end
        do
          local info = UDDM_CreateInfo()
          info.text = "Alliance"
          info.checked = (pItems._faction == "Alliance") and true or false
          info.func = function()
            pItems._faction = "Alliance"
            if UDDM_SetText then UDDM_SetText(pItems._itemsFactionDrop, "Alliance") end
          end
          UDDM_AddButton(info)
        end
        do
          local info = UDDM_CreateInfo()
          info.text = "Horde"
          info.checked = (pItems._faction == "Horde") and true or false
          info.func = function()
            pItems._faction = "Horde"
            if UDDM_SetText then UDDM_SetText(pItems._itemsFactionDrop, "Horde") end
          end
          UDDM_AddButton(info)
        end
      end)
    end

    if not modernItemsColor then
      UDDM_Initialize(itemsColorDrop, function(self, level)
        for _, name in ipairs({ "None", "Green", "Blue", "Yellow", "Red", "Cyan" }) do
          local info = UDDM_CreateInfo()
          info.text = name
          info.func = function() SetItemsColor(name) end
          UDDM_AddButton(info)
        end
      end)
    end

    if not modernItemsFont then
      UDDM_Initialize(itemsFontDrop, function(self, level)
        local choices = (type(GetFontChoices) == "function") and GetFontChoices() or { { key = "inherit", label = "Inherit" } }
        for _, opt in ipairs(choices) do
          if type(opt) == "table" and opt.key then
            local key = tostring(opt.key)
            local info = UDDM_CreateInfo()
            info.text = tostring(opt.label or opt.key)
            info.checked = (pItems._fontKey == key) and true or false
            info.func = function() SetFontKey(key) end
            UDDM_AddButton(info)
          end
        end
      end)
    end

    if not modernItemsRepMin then
      UDDM_Initialize(repMinDrop, function(self, level)
        local function Add(name, standing)
          local info = UDDM_CreateInfo()
          info.text = name
          info.checked = (pItems._repMinStanding == standing) and true or false
          info.func = function()
            pItems._repMinStanding = standing
            if UDDM_SetText then UDDM_SetText(pItems._repMinDrop, name) end
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

    if not modernItemsLevelOp then
      UDDM_Initialize(itemsLevelOpDrop, function(self, level)
        local function Add(name, op)
          local info = UDDM_CreateInfo()
          info.text = name
          info.checked = (pItems._playerLevelOp == op) and true or false
          info.func = function()
            pItems._playerLevelOp = op
            if UDDM_SetText then UDDM_SetText(pItems._itemsLevelOpDrop, name) end
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

  local addItemBtn = CreateFrame("Button", nil, pItems, "UIPanelButtonTemplate")
  addItemBtn:SetSize(140, 22)
  addItemBtn:SetPoint("TOPLEFT", 12, -342)
  addItemBtn:SetText("Add Item Entry")

  pItems._repFactionBox = repFactionBox
  pItems._repMinDrop = repMinDrop
  pItems._hideAcquired = hideAcquired
  pItems._hideExalted = hideExalted
  pItems._sellExalted = sellExalted
  pItems._restedOnly = restedOnly
  pItems._locBox = itemsLocBox
  pItems._itemsFrameDrop = itemsFrameDrop
  pItems._itemsFactionDrop = itemsFactionDrop
  pItems._itemsColorDrop = itemsColorDrop
  pItems._itemsLevelOpDrop = itemsLevelOpDrop
  pItems._itemsLevelBox = itemsLevelBox
  pItems._addItemBtn = addItemBtn

  local cancelItemEditBtn = CreateFrame("Button", nil, pItems, "UIPanelButtonTemplate")
  cancelItemEditBtn:SetSize(120, 22)
  cancelItemEditBtn:SetPoint("LEFT", addItemBtn, "RIGHT", 8, 0)
  cancelItemEditBtn:SetText("Cancel Edit")
  cancelItemEditBtn:Hide()
  pItems._cancelEditBtn = cancelItemEditBtn

  local function ClearItemsInputs()
    pItems._pendingItemLabelID = nil
    pItems._pendingItemLabelForce = nil
    if itemIDBox then itemIDBox:SetText("") end
    if itemNameBox then
      itemNameBox._autoName = nil
      itemNameBox:SetText("")
    end
    if itemInfoBox then
      itemInfoBox._autoInfo = nil
      itemInfoBox:SetText("")
    end
    if itemInfoScroll and itemInfoScroll.SetVerticalScroll then itemInfoScroll:SetVerticalScroll(0) end
    if itemQuestIDBox then itemQuestIDBox:SetText("") end
    if itemAfterQuestIDBox then itemAfterQuestIDBox:SetText("") end
    if itemCurrencyIDBox then itemCurrencyIDBox:SetText("") end
    if itemCurrencyReqBox then itemCurrencyReqBox:SetText("") end
    if itemShowBelowBox then itemShowBelowBox:SetText("") end

    pItems._targetFrameID = "list1"
    if UDDM_SetText and itemsFrameDrop then UDDM_SetText(itemsFrameDrop, GetFrameDisplayNameByID("list1")) end

    pItems._faction = nil
    if UDDM_SetText and itemsFactionDrop then UDDM_SetText(itemsFactionDrop, "Both (Off)") end

    pItems._color = nil
    if UDDM_SetText and itemsColorDrop then UDDM_SetText(itemsColorDrop, "None") end

    pItems._fontKey = "inherit"
    if UDDM_SetText and itemsFontDrop then UDDM_SetText(itemsFontDrop, "Inherit") end
    if itemsSizeBox then itemsSizeBox:SetText("0") end

    pItems._repMinStanding = nil
    if repFactionBox then repFactionBox:SetText("") end
    if UDDM_SetText and repMinDrop then UDDM_SetText(repMinDrop, "Off") end
    if hideAcquired then hideAcquired:SetChecked(false) end
    if hideExalted then hideExalted:SetChecked(false) end
    if sellExalted then sellExalted:SetChecked(false) end
    if restedOnly then restedOnly:SetChecked(false) end
    if itemsLocBox then itemsLocBox:SetText("0") end

    pItems._playerLevelOp = nil
    if UDDM_SetText and itemsLevelOpDrop then UDDM_SetText(itemsLevelOpDrop, "Off") end
    if itemsLevelBox then itemsLevelBox:SetText("0") end

    pItems._editingCustomIndex = nil
    pItems._editingDefaultBase = nil
    pItems._editingDefaultKey = nil
    if addItemBtn then addItemBtn:SetText("Add Item Entry") end
    if cancelItemEditBtn then cancelItemEditBtn:Hide() end
  end

  addItemBtn:SetScript("OnClick", function()
    local itemID = tonumber(itemIDBox:GetText() or "")
    if not itemID or itemID <= 0 then
      Print("Enter an itemID > 0.")
      return
    end

    local questIDGate = tonumber(itemQuestIDBox:GetText() or "")
    if questIDGate and questIDGate <= 0 then questIDGate = nil end
    local afterQuestIDGate = tonumber(itemAfterQuestIDBox:GetText() or "")
    if afterQuestIDGate and afterQuestIDGate <= 0 then afterQuestIDGate = nil end

    local currencyIDGate = tonumber(itemCurrencyIDBox:GetText() or "")
    if currencyIDGate and currencyIDGate <= 0 then currencyIDGate = nil end
    local currencyReqGate = tonumber(itemCurrencyReqBox:GetText() or "")
    if currencyReqGate and currencyReqGate <= 0 then currencyReqGate = nil end
    if currencyIDGate and not currencyReqGate then
      Print("Enter a currency amount (MinCur) or clear CurrencyID.")
      return
    end
    if currencyReqGate and not currencyIDGate then
      Print("Enter a CurrencyID or clear MinCur.")
      return
    end

    local showWhenBelow = tonumber(itemShowBelowBox and itemShowBelowBox:GetText() or "")
    if showWhenBelow and showWhenBelow <= 0 then showWhenBelow = nil end

    local targetFrame = tostring(pItems._targetFrameID or ""):gsub("%s+", "")
    if targetFrame == "" then targetFrame = "list1" end

    local repFactionID = tonumber(repFactionBox:GetText() or "")
    if repFactionID and repFactionID <= 0 then repFactionID = nil end

    local labelText = tostring(itemNameBox:GetText() or "")
    labelText = labelText:gsub("^%s+", ""):gsub("%s+$", "")
    local itemName = GetItemNameSafe and GetItemNameSafe(itemID) or nil
    local label = nil
    if labelText ~= "" and not (type(itemName) == "string" and itemName ~= "" and labelText == itemName) then
      label = labelText
    end

    local infoText = tostring(itemInfoBox:GetText() or "")
    infoText = infoText:gsub("^%s+", ""):gsub("%s+$", "")
    local itemInfo = (infoText ~= "") and infoText or nil

    local rep = nil
    if repFactionID then
      rep = { factionID = repFactionID }
      if pItems._repMinStanding then
        rep.minStanding = pItems._repMinStanding
      end
      if hideExalted:GetChecked() then
        rep.hideWhenExalted = true
      end
      if sellExalted:GetChecked() then
        rep.sellWhenExalted = true
        rep.hideWhenExalted = nil
      end
    end

    local locText = tostring(itemsLocBox:GetText() or ""):gsub("%s+", "")
    local locationID = (locText ~= "" and locText ~= "0") and locText or nil

    local fontKey = tostring(pItems._fontKey or "inherit")
    if fontKey == "" then fontKey = "inherit" end
    local fontSize = (itemsSizeBox and tonumber(itemsSizeBox:GetText() or "")) or 0
    if not fontSize or fontSize < 0 then fontSize = 0 end

    local rules = GetCustomRules()
    local expID, expName = nil, nil
    if type(GetRuleCreateExpansion) == "function" then
      expID, expName = GetRuleCreateExpansion()
    end
    expID = tonumber(expID)
    if not expName and expID then expName = ResolveExpansionNameByID(expID) end
    if expName == "Custom" then expName = nil; expID = nil end

    if pItems._editingCustomIndex and type(rules[pItems._editingCustomIndex]) == "table" then
      local rule = rules[pItems._editingCustomIndex]
      rule.frameID = targetFrame
      rule.faction = pItems._faction
      rule.color = pItems._color
      rule.font = fontKey
      rule.size = fontSize
      rule.restedOnly = restedOnly:GetChecked() and true or false
      rule.label = label
      rule.itemInfo = itemInfo
      rule.rep = rep
      rule.locationID = locationID
      rule._expansionID = expID
      rule._expansionName = expName

      local op = pItems._playerLevelOp
      local lvl = itemsLevelBox and tonumber(itemsLevelBox:GetText() or "") or nil
      if lvl and lvl <= 0 then lvl = nil end
      if op and lvl then
        rule.playerLevelOp = nil
        rule.playerLevel = { op, lvl }
      else
        rule.playerLevelOp = nil
        rule.playerLevel = nil
      end

      rule.item = rule.item or {}
      rule.item.itemID = itemID
      local req = tonumber(rule.item.required)
      if type(rule.item.required) == "table" then req = tonumber(rule.item.required[1]) end
      req = req or 1
      local hide = hideAcquired:GetChecked() and true or false
      rule.item.required = hide and { req, true } or req
      rule.item.hideWhenAcquired = nil
      rule.item.questID = questIDGate
      rule.item.afterQuestID = afterQuestIDGate
      rule.item.currencyID = (currencyIDGate and currencyReqGate) and { currencyIDGate, currencyReqGate } or nil
      rule.item.currencyRequired = nil
      rule.item.showWhenBelow = showWhenBelow
      if rule.hideWhenCompleted == nil then rule.hideWhenCompleted = false end

      pItems._editingCustomIndex = nil
      pItems._editingDefaultBase = nil
      pItems._editingDefaultKey = nil
      addItemBtn:SetText("Add Item Entry")
      cancelItemEditBtn:Hide()
      Print("Saved item entry.")
    elseif pItems._editingDefaultBase and pItems._editingDefaultKey and type(GetDefaultRuleEdits) == "function" then
      local edits = GetDefaultRuleEdits()
      local base = pItems._editingDefaultBase
      local key = tostring(pItems._editingDefaultKey)
      local effective = (type(edits[key]) == "table") and edits[key] or base
      local rule = DeepCopyValue(effective)

      rule.frameID = targetFrame
      rule.faction = pItems._faction
      rule.color = pItems._color
      rule.font = fontKey
      rule.size = fontSize
      rule.restedOnly = restedOnly:GetChecked() and true or false
      rule.label = label
      rule.itemInfo = itemInfo
      rule.rep = rep
      rule.locationID = locationID
      rule._expansionID = expID
      rule._expansionName = expName

      local op = pItems._playerLevelOp
      local lvl = itemsLevelBox and tonumber(itemsLevelBox:GetText() or "") or nil
      if lvl and lvl <= 0 then lvl = nil end
      if op and lvl then
        rule.playerLevelOp = nil
        rule.playerLevel = { op, lvl }
      else
        rule.playerLevelOp = nil
        rule.playerLevel = nil
      end

      rule.item = rule.item or {}
      rule.item.itemID = itemID
      local req2 = tonumber(rule.item.required)
      if type(rule.item.required) == "table" then req2 = tonumber(rule.item.required[1]) end
      req2 = req2 or 1
      local hide2 = hideAcquired:GetChecked() and true or false
      rule.item.required = hide2 and { req2, true } or req2
      rule.item.hideWhenAcquired = nil
      rule.item.questID = questIDGate
      rule.item.afterQuestID = afterQuestIDGate
      rule.item.currencyID = (currencyIDGate and currencyReqGate) and { currencyIDGate, currencyReqGate } or nil
      rule.item.currencyRequired = nil
      rule.item.showWhenBelow = showWhenBelow
      if rule.hideWhenCompleted == nil then rule.hideWhenCompleted = false end

      if base and base.key ~= nil then rule.key = tostring(base.key) end
      edits[key] = rule

      pItems._editingCustomIndex = nil
      pItems._editingDefaultBase = nil
      pItems._editingDefaultKey = nil
      addItemBtn:SetText("Add Item Entry")
      cancelItemEditBtn:Hide()
      Print("Saved default item rule edit.")
    else
      local key = string.format("custom:item:%d:%s:%d", itemID, tostring(targetFrame), (#rules + 1))
      local op = pItems._playerLevelOp
      local lvl = itemsLevelBox and tonumber(itemsLevelBox:GetText() or "") or nil
      if lvl and lvl <= 0 then lvl = nil end
      if not (op and lvl) then op = nil; lvl = nil end
      rules[#rules + 1] = {
        key = key,
        frameID = targetFrame,
        faction = pItems._faction,
        color = pItems._color,
        font = fontKey,
        size = fontSize,
        restedOnly = restedOnly:GetChecked() and true or false,
        label = label,
        itemInfo = itemInfo,
        rep = rep,
        locationID = locationID,
        _expansionID = expID,
        _expansionName = expName,
        playerLevel = (op and lvl) and { op, lvl } or nil,
        item = {
          itemID = itemID,
          required = (hideAcquired:GetChecked() and true or false) and { 1, true } or 1,
          questID = questIDGate,
          afterQuestID = afterQuestIDGate,
          currencyID = (currencyIDGate and currencyReqGate) and { currencyIDGate, currencyReqGate } or nil,
          showWhenBelow = showWhenBelow,
        },
        hideWhenCompleted = false,
      }

      Print("Added item entry for item " .. itemID .. " -> " .. targetFrame)
    end

    if CreateAllFrames then CreateAllFrames() end
    if RefreshAll then RefreshAll() end
    if RefreshRulesList then RefreshRulesList() end
    if not GetKeepEditFormOpen() then
      ClearItemsInputs()
      if SelectTab then SelectTab("rules") end
    end
  end)

  cancelItemEditBtn:SetScript("OnClick", function()
    pItems._editingCustomIndex = nil
    pItems._editingDefaultBase = nil
    pItems._editingDefaultKey = nil
    addItemBtn:SetText("Add Item Entry")
    cancelItemEditBtn:Hide()

    if not GetKeepEditFormOpen() then
      ClearItemsInputs()
      if SelectTab then SelectTab("rules") end
    end
  end)
end
