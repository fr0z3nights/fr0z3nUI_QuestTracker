local addonName, ns = ...

local deps = (type(ns) == "table" and ns._FQTRender and ns._FQTRender.deps) or nil
if type(deps) ~= "table" then
  return
end

ns.Render = ns.Render or {}

local Print = deps.Print or (type(ns) == "table" and ns.Print) or function(...) end

local function IsEditMode()
  if type(deps.IsEditMode) == "function" then
    return deps.IsEditMode() and true or false
  end
  return false
end

local function IsOptionsOpen()
  if type(deps.IsOptionsOpen) == "function" then
    return deps.IsOptionsOpen() and true or false
  end
  return false
end

local function RefreshAll()
  if type(deps.RefreshAll) == "function" then
    return deps.RefreshAll()
  end
  if type(ns) == "table" and type(ns.RefreshAll) == "function" then
    return ns.RefreshAll()
  end
end

local function RefreshActiveTab()
  if type(deps.RefreshActiveTab) == "function" then
    return deps.RefreshActiveTab()
  end
  local fn = _G and rawget(_G, "RefreshActiveTab")
  if type(fn) == "function" then
    return fn()
  end
end

local ClampPadPx = deps.ClampPadPx
local NormalizeAnchorCorner = deps.NormalizeAnchorCorner
local PointToAnchorCorner = deps.PointToAnchorCorner

local EnsureFontString = deps.EnsureFontString
local ApplyFontStyle = deps.ApplyFontStyle
local GetRuleFontDef = deps.GetRuleFontDef

local GetIndicatorsWidth = deps.GetIndicatorsWidth
local RenderIndicators = deps.RenderIndicators

local EnsureRowButton = deps.EnsureRowButton
local EnsureRemoveButton = deps.EnsureRemoveButton
local EnsureMoveButton = deps.EnsureMoveButton
local HideExtraFrameRows = deps.HideExtraFrameRows

local GetFrameScrollOffset = deps.GetFrameScrollOffset
local SetFrameScrollOffset = deps.SetFrameScrollOffset

local function RuleKey(rule)
  if type(ns) == "table" and type(ns.RuleKey) == "function" then
    return ns.RuleKey(rule)
  end
  if type(deps.RuleKey) == "function" then
    return deps.RuleKey(rule)
  end
  return nil
end

local function GetEffectiveFrames()
  if type(deps.GetEffectiveFrames) == "function" then
    return deps.GetEffectiveFrames()
  end
  return nil
end

local function GetFrameByID(frameID)
  if type(deps.GetFrameByID) == "function" then
    return deps.GetFrameByID(frameID)
  end
  return nil
end

local function GetFramesEnabled()
  if type(deps.GetFramesEnabled) == "function" then
    return deps.GetFramesEnabled() and true or false
  end
  return false
end

local function ToggleRuleDisabled(rule)
  if type(ns) == "table" and type(ns.ToggleRuleDisabled) == "function" then
    return ns.ToggleRuleDisabled(rule)
  end
  local fn = _G and rawget(_G, "ToggleRuleDisabled")
  if type(fn) == "function" then
    return fn(rule)
  end
end

local function UnassignRuleFromFrame(rule, frameID)
  if type(ns) == "table" and type(ns.UnassignRuleFromFrame) == "function" then
    return ns.UnassignRuleFromFrame(rule, frameID)
  end
  if type(deps.UnassignRuleFromFrame) == "function" then
    return deps.UnassignRuleFromFrame(rule, frameID)
  end
  return false
end

local function ReorderCustomRulesInFrame(frame, rule, destAbsIndex)
  if type(deps.ReorderCustomRulesInFrame) == "function" then
    return deps.ReorderCustomRulesInFrame(frame, rule, destAbsIndex)
  end
  local fn = _G and rawget(_G, "ReorderCustomRulesInFrame")
  if type(fn) == "function" then
    return fn(frame, rule, destAbsIndex)
  end
  return false
end

local function ApplyFAOBackdrop(frame, alpha, color)
  if type(deps.ApplyFAOBackdrop) == "function" then
    return deps.ApplyFAOBackdrop(frame, alpha, color)
  end
end

local function RestoreWindowPosition(key, frame, point, relPoint, x, y)
  if type(deps.RestoreWindowPosition) == "function" then
    return deps.RestoreWindowPosition(key, frame, point, relPoint, x, y)
  end
end

local function SaveWindowPosition(key, frame)
  if type(deps.SaveWindowPosition) == "function" then
    return deps.SaveWindowPosition(key, frame)
  end
end

function ns.Render.RenderBar(frameDef, frame, entries)
  local editMode = IsEditMode()

  local maxItems = tonumber(frameDef.maxItems) or 6
  local uiPad = ClampPadPx and ClampPadPx((type(frameDef) == "table") and frameDef.pad or nil) or nil
  if uiPad == nil and type(ns) == "table" and type(ns.GetUISetting) == "function" then
    local v = ns.GetUISetting("pad", nil)
    if v == nil then v = ns.GetUISetting("listPadding", 0) end
    uiPad = ClampPadPx and (ClampPadPx(v) or 0) or (tonumber(v) or 0)
  end
  uiPad = uiPad or 0

  local pad = 8 + uiPad
  local y = -2
  if type(entries) ~= "table" then entries = {} end

  if frame.title then frame.title:Hide() end

  local reverse = (type(ns) == "table" and type(ns.GetUISetting) == "function" and ns.GetUISetting("reverseOrder", false) == true) and true or false
  local corner = (type(frameDef) == "table") and (NormalizeAnchorCorner and NormalizeAnchorCorner(frameDef.anchorCorner) or nil) or nil
  if not corner and frame and frame.GetPoint then
    local p = frame:GetPoint(1)
    corner = PointToAnchorCorner and PointToAnchorCorner(p) or nil
  end
  local align
  if corner == "tc" or corner == "bc" then
    align = "center"
  else
    align = (corner == "tr" or corner == "br") and "right" or "left"
  end

  local offset = (type(GetFrameScrollOffset) == "function") and (GetFrameScrollOffset(frame and frame._id) or 0) or 0
  local maxOffset = 0
  if type(entries) == "table" then
    maxOffset = math.max(0, (#entries) - maxItems)
  end
  if offset > maxOffset then
    offset = maxOffset
    if type(SetFrameScrollOffset) == "function" then
      SetFrameScrollOffset(frame and frame._id, offset)
    end
  end

  local function EntryForSlot(i)
    i = tonumber(i) or 1
    if i < 1 then return nil end
    local idx
    if reverse then
      idx = offset + (maxItems - i + 1)
    else
      idx = offset + i
    end
    return entries[idx]
  end

  if frame.prefix then
    frame.prefix:SetText("")
    frame.prefix:Hide()
  end

  local tempTextByIndex = {}
  local tempIndicatorsByIndex = {}
  local tempIndicatorsWByIndex = {}
  for i = 1, maxItems do
    local e = EntryForSlot(i)
    if e then
      local text = (editMode and e.title) or e.title
      if e.extra then text = text .. "  " .. e.extra end
      tempTextByIndex[i] = text
      tempIndicatorsByIndex[i] = e.indicators
      tempIndicatorsWByIndex[i] = 0
    end
  end

  local spacingPrefix = 12 + uiPad
  local spacingItem = 16 + uiPad
  local total = 0
  local prefixW = (frame.prefix and frame.prefix.GetStringWidth and frame.prefix:GetStringWidth()) or 0
  if prefixW > 0 then
    total = total + prefixW
  end
  for i = 1, maxItems do
    local txt = tempTextByIndex[i]
    if txt then
      local fs = EnsureFontString and EnsureFontString(frame, i, frameDef and frameDef.font) or nil
      if fs then
        if ApplyFontStyle then ApplyFontStyle(fs, frameDef and frameDef.font) end
        local e = EntryForSlot(i)
        if e and e.rule and GetRuleFontDef and ApplyFontStyle then
          ApplyFontStyle(fs, GetRuleFontDef(e.rule))
        end
        fs:SetText(txt)
        fs:Show()
        local indW = (type(GetIndicatorsWidth) == "function") and GetIndicatorsWidth(fs, tempIndicatorsByIndex[i], uiPad) or 0
        tempIndicatorsWByIndex[i] = indW
        total = total + (fs.GetStringWidth and fs:GetStringWidth() or 0) + indW
      end
    end
  end

  local visibleCount = 0
  if prefixW > 0 then visibleCount = visibleCount + 1 end
  for i = 1, maxItems do
    if tempTextByIndex[i] then visibleCount = visibleCount + 1 end
  end
  if visibleCount > 1 then
    if prefixW > 0 then
      total = total + spacingPrefix
      if visibleCount > 2 then
        total = total + (visibleCount - 2) * spacingItem
      end
    else
      total = total + (visibleCount - 1) * spacingItem
    end
  end

  local frameW = (frame and frame.GetWidth and frame:GetWidth()) or 0
  local start = pad
  if frameW and frameW > 0 then
    if align == "right" then
      start = math.max(pad, frameW - pad - total)
    elseif align == "center" then
      local desired = math.floor((frameW - total) / 2 + 0.5)
      local minStart = pad
      local maxStart = math.max(pad, frameW - pad - total)
      if desired < minStart then desired = minStart end
      if desired > maxStart then desired = maxStart end
      start = desired
    end
  end

  local cursor = start

  if frame.prefix and prefixW > 0 then
    frame.prefix:ClearAllPoints()
    frame.prefix:SetPoint("TOPLEFT", frame, "TOPLEFT", cursor, y)
    cursor = cursor + prefixW + spacingPrefix
  end

  for i = 1, maxItems do
    local fs = EnsureFontString and EnsureFontString(frame, i, frameDef and frameDef.font) or nil
    if fs then
      fs:ClearAllPoints()
      fs:SetPoint("TOPLEFT", frame, "TOPLEFT", cursor, y)
      if fs.SetWordWrap then fs:SetWordWrap(false) end

      if ApplyFontStyle then ApplyFontStyle(fs, frameDef and frameDef.font) end
      local e = EntryForSlot(i)
      if e and e.rule and GetRuleFontDef and ApplyFontStyle then
        ApplyFontStyle(fs, GetRuleFontDef(e.rule))
      end

      local txt = tempTextByIndex[i]
      if txt then
        fs:SetText(txt)
        fs:Show()
        local indW = tempIndicatorsWByIndex[i] or 0
        if type(RenderIndicators) == "function" then
          RenderIndicators(frame, i, fs, tempIndicatorsByIndex[i], uiPad)
        end

        local btn = EnsureRowButton and EnsureRowButton(frame, i) or nil
        if btn then
          btn:ClearAllPoints()
          btn:SetPoint("TOPLEFT", fs, "TOPLEFT", -2, 2)
          btn:SetPoint("BOTTOMRIGHT", fs, "BOTTOMRIGHT", 2 + indW, -2)
          btn._entry = EntryForSlot(i)
          btn:EnableMouse(editMode and true or false)
          if editMode then btn:Show() else btn:Hide() end
        end

        local rm = EnsureRemoveButton and EnsureRemoveButton(frame, i) or nil
        if rm and rm.Hide then rm:Hide() end

        cursor = cursor + (fs.GetStringWidth and fs:GetStringWidth() or 0) + indW + spacingItem
      else
        fs:SetText("")
        fs:Hide()
        if type(RenderIndicators) == "function" then
          RenderIndicators(frame, i, fs, nil, uiPad)
        end

        local btn = EnsureRowButton and EnsureRowButton(frame, i) or nil
        if btn then
          btn._entry = nil
          btn:Hide()
        end

        local rm = EnsureRemoveButton and EnsureRemoveButton(frame, i) or nil
        if rm and rm.Hide then rm:Hide() end
      end
    end
  end

  if type(HideExtraFrameRows) == "function" then
    HideExtraFrameRows(frame, maxItems + 1)
  end

  if frameDef and frameDef.autoSize and frame and frame.SetHeight then
    frame:SetHeight(tonumber(frameDef.height) or 20)
  end
end

function ns.Render.RenderList(frameDef, frame, entries)
  local editMode = IsEditMode()

  local maxItems = tonumber(frameDef.maxItems) or 20
  local rowH = tonumber(frameDef.rowHeight) or 16
  if type(entries) ~= "table" then entries = {} end

  local debugHitboxes = (editMode and (type(ns) == "table") and type(ns.GetUISetting) == "function" and (ns.GetUISetting("debugHitboxes", false) == true)) and true or false

  local zebra = (editMode and true) or ((type(frameDef) == "table" and frameDef.zebra == true) and true or false)
  local zebraA = (type(ns) == "table" and type(ns.GetUISetting) == "function") and (tonumber(ns.GetUISetting("zebraAlpha", 0.05) or 0.05) or 0.05) or 0.05
  if zebraA < 0 then zebraA = 0 elseif zebraA > 0.20 then zebraA = 0.20 end

  local uiPad = ClampPadPx and ClampPadPx((type(frameDef) == "table") and frameDef.pad or nil) or nil
  if uiPad == nil and type(ns) == "table" and type(ns.GetUISetting) == "function" then
    local v = ns.GetUISetting("pad", nil)
    if v == nil then v = ns.GetUISetting("listPadding", 0) end
    uiPad = ClampPadPx and (ClampPadPx(v) or 0) or (tonumber(v) or 0)
  end
  uiPad = uiPad or 0

  local listPad = editMode and 0 or uiPad

  if frame.title then
    frame.title:Hide()
  end

  local padTop = 8
  local padBottom = 8

  local visibleRows = maxItems
  if type(frameDef) == "table" and tonumber(frameDef.maxHeight) and tonumber(frameDef.maxHeight) > 0 then
    local mh = tonumber(frameDef.maxHeight) or 0
    local can = math.floor((mh - padTop - padBottom) / rowH)
    if can < 1 then can = 1 end
    if can < visibleRows then visibleRows = can end
    if frame and frame.SetHeight then
      frame:SetHeight(mh)
    end
  end

  local offset = (type(GetFrameScrollOffset) == "function") and (GetFrameScrollOffset(frame and frame._id) or 0) or 0
  local maxOffset = 0
  if type(entries) == "table" then
    local count = #entries

    local wrapText0 = not editMode
    local maxY0 = nil
    if wrapText0 then
      local limit = nil
      if type(frameDef) == "table" and tonumber(frameDef.maxHeight) and tonumber(frameDef.maxHeight) > 0 then
        limit = tonumber(frameDef.maxHeight) or nil
      elseif frame and frame.GetHeight then
        limit = frame:GetHeight()
      end
      if limit and limit > 0 then
        maxY0 = limit - padTop - padBottom
        if maxY0 < rowH then maxY0 = rowH end
      end
    end

    local textW0
    do
      local w = (frame and frame.GetWidth and frame:GetWidth()) or (frameDef and frameDef.width) or 300
      local rightPad = editMode and 62 or 12
      local leftPad = 16
      local tw = w - leftPad - rightPad
      if tw < 50 then tw = 50 end
      textW0 = tw
    end

    maxOffset = math.max(0, count - visibleRows)

    if (not editMode) and wrapText0 and maxY0 and count > 0 and frame and frame.CreateFontString then
      local function GetEntryText(e)
        if not e then return nil end
        local text = e.title
        if text == nil then return nil end
        text = tostring(text)
        if e.extra then text = text .. "  " .. tostring(e.extra) .. " " end
        return " " .. text .. " "
      end

      local measure = frame._measureFS
      if not (measure and measure.SetText and measure.GetStringHeight) then
        measure = frame:CreateFontString(nil, "OVERLAY", frame._itemFont or "GameFontHighlight")
        frame._measureFS = measure
        if measure.SetJustifyH then measure:SetJustifyH("LEFT") end
        if measure.SetJustifyV then measure:SetJustifyV("TOP") end
      end
      if ApplyFontStyle then ApplyFontStyle(measure, frameDef and frameDef.font) end
      if measure.SetWordWrap then measure:SetWordWrap(true) end
      if measure.SetNonSpaceWrap then measure:SetNonSpaceWrap(true) end
      if measure.SetWidth then measure:SetWidth(textW0) end

      local gapWrap = 2
      local total = 0
      local fitCount = 0
      for i = count, 1, -1 do
        local e = entries[i]
        if e and e.rule and GetRuleFontDef and ApplyFontStyle then
          ApplyFontStyle(measure, GetRuleFontDef(e.rule))
        else
          if ApplyFontStyle then ApplyFontStyle(measure, frameDef and frameDef.font) end
        end
        local t = GetEntryText(e)
        measure:SetText(t or "")
        local h = (measure:GetStringHeight() or 0)
        if h < rowH then h = rowH end

        local add = h + gapWrap
        if fitCount > 0 and listPad > 0 then
          add = add + listPad
        end

        if fitCount > 0 and (total + add) > maxY0 then
          break
        end

        total = total + add
        fitCount = fitCount + 1
        if fitCount >= visibleRows then
          break
        end
      end
      if fitCount < 1 then fitCount = 1 end

      local wrapMaxOffset = math.max(0, count - fitCount)
      maxOffset = wrapMaxOffset
    end
  end

  if frame then
    frame._canScroll = (maxOffset > 0) and true or false
    frame._maxScrollOffset = maxOffset
  end

  if maxOffset <= 0 and offset ~= 0 then
    offset = 0
    if frame and frame._id and type(SetFrameScrollOffset) == "function" then
      SetFrameScrollOffset(frame._id, 0)
    end
  end
  if offset > maxOffset then
    offset = maxOffset
    if type(SetFrameScrollOffset) == "function" then
      SetFrameScrollOffset(frame and frame._id, offset)
    end
  end

  do
    local wantDebug = (type(ns) == "table") and type(ns.GetUISetting) == "function" and (ns.GetUISetting("debugListLayout", false) == true) and true or false
    if wantDebug or editMode then
      local c = (type(entries) == "table") and #entries or 0
      frame._fqtListLayout = {
        editMode = editMode and true or false,
        count = c,
        visibleRows = visibleRows,
        offset = offset,
        maxOffset = maxOffset,
        first = (c > 0) and (offset + 1) or 0,
        last = (c > 0) and math.min(c, offset + visibleRows) or 0,
        rowH = rowH,
        maxItems = maxItems,
        maxHeight = (type(frameDef) == "table") and tonumber(frameDef.maxHeight) or nil,
        wrapText = (not editMode) and true or false,
        padTop = padTop,
        padBottom = padBottom,
        listPad = listPad,
        frameW = (frame and frame.GetWidth and frame:GetWidth()) or nil,
        frameH = (frame and frame.GetHeight and frame:GetHeight()) or nil,
      }
    elseif frame then
      frame._fqtListLayout = nil
    end
  end

  if frame and frame._listScrollUp and frame._listScrollUp.Hide then frame._listScrollUp:Hide() end
  if frame and frame._listScrollDown and frame._listScrollDown.Hide then frame._listScrollDown:Hide() end

  local shown = 0
  local wrapText = not editMode

  local wantZebra = (zebra and (not wrapText) and zebraA > 0) and true or false
  if frame and type(frame._zebraRows) == "table" and (not wantZebra) then
    for _, t in pairs(frame._zebraRows) do
      if t and t.Hide then t:Hide() end
    end
  end

  local growY = "down"
  local yCursor = 0
  local maxY = nil
  if wrapText and type(frameDef) == "table" and tonumber(frameDef.maxHeight) and tonumber(frameDef.maxHeight) > 0 then
    maxY = (tonumber(frameDef.maxHeight) or 0) - padTop - padBottom
    if maxY < rowH then maxY = rowH end
  end

  local function GetTextWidth()
    local w = (frame and frame.GetWidth and frame:GetWidth()) or (frameDef and frameDef.width) or 300
    local rightPad = editMode and 62 or 12
    local leftPad = 16
    local tw = w - leftPad - rightPad
    if tw < 50 then tw = 50 end
    return tw
  end

  local textW = GetTextWidth()

  local function HideDebugRects()
    if not frame then return end
    if type(frame._debugHitRects) ~= "table" then return end
    for _, byIdx in pairs(frame._debugHitRects) do
      if type(byIdx) == "table" then
        for _, t in pairs(byIdx) do
          if t and t.Hide then t:Hide() end
        end
      end
    end
  end

  local function EnsureDebugRect(kind, i, r, g, b, a)
    if not (frame and frame.CreateTexture) then return nil end
    frame._debugHitRects = frame._debugHitRects or {}
    frame._debugHitRects[kind] = frame._debugHitRects[kind] or {}
    local t = frame._debugHitRects[kind][i]
    if t then return t end
    t = frame:CreateTexture(nil, "OVERLAY")
    frame._debugHitRects[kind][i] = t
    if t.SetColorTexture then
      t:SetColorTexture(r or 1, g or 1, b or 1, a or 0.15)
    elseif t.SetVertexColor then
      t:SetVertexColor(r or 1, g or 1, b or 1, a or 0.15)
    end
    t:Hide()
    return t
  end

  if not debugHitboxes then
    HideDebugRects()
  end

  local function EnsureZebraRow(i)
    if not (zebra and frame and frame.CreateTexture) then return nil end
    frame._zebraRows = frame._zebraRows or {}
    local t = frame._zebraRows[i]
    if t then return t end
    t = frame:CreateTexture(nil, "BACKGROUND")
    frame._zebraRows[i] = t
    if t.SetColorTexture then
      t:SetColorTexture(1, 1, 1, zebraA)
    elseif t.SetVertexColor then
      t:SetVertexColor(1, 1, 1, zebraA)
    end
    t:Hide()
    return t
  end

  for i = 1, visibleRows do
    local e = entries[i + offset]
    local yBefore = yCursor
    local fs = EnsureFontString and EnsureFontString(frame, i, frameDef and frameDef.font) or nil
    if not fs then
      break
    end

    if fs._defaultFont and fs.SetFont then
      local d = fs._defaultFont
      if d[1] or d[2] or d[3] then
        local curP, curS, curF = fs:GetFont()
        fs:SetFont(d[1] or curP, d[2] or curS or 12, d[3] or curF)
      end
    end
    if fs._defaultTextColor and fs.SetTextColor then
      local c = fs._defaultTextColor
      fs:SetTextColor(c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1)
    end
    if fs.SetJustifyH then fs:SetJustifyH("LEFT") end

    fs:ClearAllPoints()
    if wrapText then
      if fs.SetJustifyV then fs:SetJustifyV((growY == "up") and "BOTTOM" or "TOP") end
      if fs.SetWordWrap then fs:SetWordWrap(true) end
      if fs.SetNonSpaceWrap then fs:SetNonSpaceWrap(true) end
      if fs.SetWidth then fs:SetWidth(textW) end
    else
      if fs.SetJustifyV then fs:SetJustifyV("MIDDLE") end
      if fs.SetWordWrap then fs:SetWordWrap(false) end
      if fs.SetNonSpaceWrap then fs:SetNonSpaceWrap(false) end
      if fs.SetWidth then fs:SetWidth(textW) end
    end
    if growY == "up" then
      fs:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, padBottom + yCursor)
    else
      fs:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -padTop - yCursor)
    end

    local zb = EnsureZebraRow(i)
    if zb then
      if (not wrapText) and zebraA > 0 and ((i % 2) == 0) then
        zb:ClearAllPoints()
        if growY == "up" then
          zb:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 4, padBottom + yBefore)
          zb:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", -4, padBottom + yBefore + rowH)
        else
          zb:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -padTop - yBefore)
          zb:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -4, -padTop - yBefore - rowH)
        end
        zb:Show()
      else
        zb:Hide()
      end
    end

    if ApplyFontStyle then ApplyFontStyle(fs, frameDef and frameDef.font) end

    local btn = EnsureRowButton and EnsureRowButton(frame, i) or nil
    if btn then
      btn:ClearAllPoints()
      btn:SetPoint("TOPLEFT", fs, "TOPLEFT", -2, 2)
      btn:SetPoint("BOTTOMRIGHT", fs, "BOTTOMRIGHT", 2, -2)
      btn._entry = e
      btn._entryAbsIndex = i + offset
      btn:EnableMouse(editMode and true or false)
      if editMode then btn:Show() else btn:Hide() end
    end

    local rm = EnsureRemoveButton and EnsureRemoveButton(frame, i) or nil
    if rm then
      rm:ClearAllPoints()
      if growY == "up" then
        rm:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, padBottom + (i - 1) * rowH + 2)
      else
        rm:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -padTop - (i - 1) * rowH + 2)
      end
      rm._entry = e
      rm:SetScript("OnClick", function(self)
        if not (IsShiftKeyDown and IsShiftKeyDown()) then
          Print("Hold SHIFT and click X to remove from this frame.")
          return
        end
        local ent = self and self._entry
        if not (ent and ent.rule) then return end
        local ok = UnassignRuleFromFrame(ent.rule, frame and frame._id)
        if not ok then
          Print("That rule isn't custom; use disable toggle instead.")
          ToggleRuleDisabled(ent.rule)
        end
        RefreshAll()
        if IsOptionsOpen() then RefreshActiveTab() end
      end)
      rm:SetShown(editMode and e ~= nil)
    end

    local mvDown = EnsureMoveButton and EnsureMoveButton(frame, i, "down") or nil
    local mvUp = EnsureMoveButton and EnsureMoveButton(frame, i, "up") or nil
    if mvDown and mvUp and rm then
      mvDown:ClearAllPoints()
      mvUp:ClearAllPoints()
      mvDown:SetPoint("RIGHT", rm, "LEFT", -2, 0)
      mvUp:SetPoint("RIGHT", mvDown, "LEFT", -2, 0)

      local absIdx = i + offset
      local entriesCount = (type(entries) == "table") and #entries or 0

      mvUp._entry = e
      mvUp._entryAbsIndex = absIdx
      mvDown._entry = e
      mvDown._entryAbsIndex = absIdx

      mvUp:SetShown(editMode and e ~= nil)
      mvDown:SetShown(editMode and e ~= nil)
      if editMode and e ~= nil then
        mvUp:SetEnabled(absIdx > 1)
        mvDown:SetEnabled(absIdx < entriesCount)
      end

      local function DoMove(selfBtn, delta)
        if not IsEditMode() then return end
        local ent = selfBtn and selfBtn._entry
        local r = ent and ent.rule
        if type(r) ~= "table" then return end

        local realFrame = frame
        if frame and frame._targetID then
          local tgt = GetFrameByID(tostring(frame._targetID))
          if tgt then realFrame = tgt end
        end
        if not (realFrame and realFrame._lastEntries) then return end

        local curAbs = tonumber(selfBtn and selfBtn._entryAbsIndex) or 1
        local destAbs = curAbs + (tonumber(delta) or 0)
        if destAbs < 1 then destAbs = 1 end

        local ok = ReorderCustomRulesInFrame(realFrame, r, destAbs)
        if not ok then return end
        RefreshAll()
        if IsOptionsOpen() then RefreshActiveTab() end
      end

      mvUp:SetScript("OnClick", function(selfBtn) DoMove(selfBtn, -1) end)
      mvDown:SetScript("OnClick", function(selfBtn) DoMove(selfBtn, 1) end)
    end

    if debugHitboxes then
      local tRow = EnsureDebugRect("row", i, 1, 0, 0, 0.12)
      if tRow and tRow.SetAllPoints and btn then
        tRow:ClearAllPoints()
        tRow:SetAllPoints(btn)
        tRow:SetShown(editMode and e ~= nil)
      end

      local tX = EnsureDebugRect("x", i, 0, 1, 0, 0.18)
      if tX and tX.SetAllPoints and rm then
        tX:ClearAllPoints()
        tX:SetAllPoints(rm)
        tX:SetShown(editMode and e ~= nil)
      end

      local tUp = EnsureDebugRect("up", i, 0, 0.65, 1, 0.18)
      if tUp and tUp.SetAllPoints and mvUp then
        tUp:ClearAllPoints()
        tUp:SetAllPoints(mvUp)
        tUp:SetShown(editMode and e ~= nil)
      end

      local tDown = EnsureDebugRect("down", i, 0, 0.65, 1, 0.18)
      if tDown and tDown.SetAllPoints and mvDown then
        tDown:ClearAllPoints()
        tDown:SetAllPoints(mvDown)
        tDown:SetShown(editMode and e ~= nil)
      end
    end

    if e then
      local isDMFHeader = false
      do
        local r = e.rule
        local grp = (type(r) == "table") and (r.group or r["group"]) or nil
        if grp == "event:darkmoon-faire" then
          local k = (type(r) == "table") and tostring(r.key or "") or ""
          if k == "event:darkmoon-faire" then
            isDMFHeader = true
            if ApplyFontStyle then ApplyFontStyle(fs, { name = "lsm:Bazooka", size = 20, color = "6b21a8" }) end
            if fs.SetJustifyH then fs:SetJustifyH("CENTER") end
          else
            if fs.SetTextColor then fs:SetTextColor(0.72, 0.56, 0.90, 1) end
          end
        end
      end

      local text
      if editMode then
        if tostring(frame and frame._id or ""):find("^inspect:") then
          local lbl = (e.rule and e.rule.label ~= nil) and tostring(e.rule.label) or ""
          if lbl ~= "" then
            text = lbl
          else
            text = e.rawTitle or e.editText or e.title
          end
        else
          text = e.editText or e.title
        end
      else
        text = e.title
      end
      if (not editMode) and e.extra then text = text .. "  " .. e.extra .. " " end
      if isDMFHeader then
        fs:SetText(tostring(text or ""))
      else
        fs:SetText(" " .. tostring(text or "") .. " ")
      end
      if fs.Show then fs:Show() end
      if type(RenderIndicators) == "function" then
        RenderIndicators(frame, i, fs, e.indicators, uiPad)
      end
      shown = shown + 1

      local h = rowH
      if wrapText then
        local sh = (fs.GetStringHeight and fs:GetStringHeight()) or (fs.GetHeight and fs:GetHeight()) or nil
        if sh and sh > h then h = sh end
      end
      yCursor = yCursor + h
      if wrapText then yCursor = yCursor + 2 end

      if wrapText and listPad > 0 and entries[i + offset + 1] ~= nil then
        yCursor = yCursor + listPad
      end

      if maxY and yCursor > maxY and shown > 0 then
        for j = i + 1, visibleRows do
          local fs2 = EnsureFontString and EnsureFontString(frame, j, frameDef and frameDef.font) or nil
          if fs2 then
            fs2:SetText("")
            fs2:Hide()
            if type(RenderIndicators) == "function" then
              RenderIndicators(frame, j, fs2, nil, uiPad)
            end
          end
          local btn2 = EnsureRowButton and EnsureRowButton(frame, j) or nil
          if btn2 then
            btn2._entry = nil
            btn2:Hide()
          end
          local rm2 = EnsureRemoveButton and EnsureRemoveButton(frame, j) or nil
          if rm2 and rm2.Hide then rm2:Hide() end
        end
        break
      end
    else
      fs:SetText("")
      fs:Hide()
      if type(RenderIndicators) == "function" then
        RenderIndicators(frame, i, fs, nil, uiPad)
      end

      local zb2 = frame and frame._zebraRows and frame._zebraRows[i]
      if zb2 then zb2:Hide() end
    end
  end

  for i = visibleRows + 1, maxItems do
    local fs = EnsureFontString and EnsureFontString(frame, i, frameDef and frameDef.font) or nil
    if fs then
      fs:SetText("")
      fs:Hide()
      if type(RenderIndicators) == "function" then
        RenderIndicators(frame, i, fs, nil, uiPad)
      end
    end
    local btn = EnsureRowButton and EnsureRowButton(frame, i) or nil
    if btn then
      btn._entry = nil
      btn:Hide()
    end

    local rm = EnsureRemoveButton and EnsureRemoveButton(frame, i) or nil
    if rm and rm.Hide then rm:Hide() end

    local zb = frame and frame._zebraRows and frame._zebraRows[i]
    if zb then zb:Hide() end
  end

  if frameDef and frameDef.autoSize and frame and frame.SetHeight then
    local minRows = tonumber(frameDef.minRows) or 0
    local want
    if wrapText then
      local minH = (minRows > 0) and (minRows * rowH) or 0
      want = padTop + padBottom + math.max(minH, yCursor)
    else
      local rows = shown
      if editMode then rows = visibleRows end
      if rows < minRows then rows = minRows end
      want = padTop + padBottom + rows * rowH
    end
    if type(frameDef) == "table" and tonumber(frameDef.maxHeight) and tonumber(frameDef.maxHeight) > 0 then
      want = math.min(want, tonumber(frameDef.maxHeight))
    end
    frame:SetHeight(want)
  end
end

-- Bar contents inspector (instead of transforming bars into lists in edit mode)
local function GetFrameDisplayNameForInspector(frameID)
  frameID = tostring(frameID or "")
  if frameID == "" then return "" end
  local defs = GetEffectiveFrames()
  if type(defs) == "table" then
    for _, def in ipairs(defs) do
      if tostring(def and def.id or "") == frameID then
        local n = tostring(def and def.name or "")
        if n ~= "" then return n end
        break
      end
    end
  end
  return frameID
end

local barContentsFrame

function ns.Render.RefreshBarContentsFrame()
  if not (barContentsFrame and barContentsFrame.IsShown and barContentsFrame:IsShown()) then return end
  local targetID = tostring(barContentsFrame._targetFrameID or "")
  if targetID == "" then return end

  local target = GetFrameByID(targetID)
  local entries = (target and (target._lastAllEntries or target._lastEntries)) or {}

  local host = barContentsFrame._host
  if not host then return end
  if host.EnableMouseWheel then host:EnableMouseWheel(IsEditMode() and true or false) end
  host._targetID = targetID
  host._id = "inspect:" .. targetID

  if barContentsFrame._title and barContentsFrame._title.SetText then
    barContentsFrame._title:SetText("|cff00ccff[FQT]|r Contents: " .. tostring(GetFrameDisplayNameForInspector(targetID)))
  end

  local tmp = {
    id = host._id,
    type = "list",
    rowHeight = 16,
    maxItems = 24,
    zebra = true,
  }

  if barContentsFrame._scrollUp and barContentsFrame._scrollDown then
    barContentsFrame._scrollUp:Hide()
    barContentsFrame._scrollDown:Hide()
    barContentsFrame._scrollUp:SetScript("OnClick", nil)
    barContentsFrame._scrollDown:SetScript("OnClick", nil)
  end

  ns.Render.RenderList(tmp, host, entries)
end

local function EnsureBarContentsFrame()
  if barContentsFrame then return barContentsFrame end

  local f = CreateFrame("Frame", "FR0Z3NUIFQTBarContents", UIParent, "BackdropTemplate")
  f:SetSize(420, 520)
  f:SetPoint("CENTER")
  f:SetFrameStrata("DIALOG")
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:EnableMouse(true)
  RestoreWindowPosition("barContents", f, "CENTER", "CENTER", 0, 0)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", function(self)
    if self.StopMovingOrSizing then self:StopMovingOrSizing() end
    SaveWindowPosition("barContents", self)
  end)
  ApplyFAOBackdrop(f, 0.90)

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", 12, -10)
  title:SetText("|cff00ccff[FQT]|r Bar Contents")
  f._title = title

  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", f, "TOPRIGHT", 2, 2)

  local up = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  up:SetSize(16, 16)
  up:SetText("")
  up:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
  up:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Down")
  up:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Highlight")
  up:SetDisabledTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Disabled")
  up:SetPoint("TOPRIGHT", close, "BOTTOMRIGHT", 0, -2)
  up:Hide()

  local down = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  down:SetSize(16, 16)
  down:SetText("")
  down:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
  down:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Down")
  down:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Highlight")
  down:SetDisabledTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Disabled")
  down:SetPoint("TOPRIGHT", up, "BOTTOMRIGHT", 0, -2)
  down:Hide()

  f._scrollUp = up
  f._scrollDown = down

  local host = CreateFrame("Frame", nil, f)
  host:SetPoint("TOPLEFT", 12, -34)
  host:SetPoint("BOTTOMRIGHT", -12, 12)
  host._isTrackerFrame = true
  f._host = host

  host:EnableMouseWheel(true)
  host:SetScript("OnMouseWheel", function(_, delta)
    if not IsEditMode() then return end
    local off = (type(GetFrameScrollOffset) == "function") and (GetFrameScrollOffset(host and host._id) or 0) or 0
    off = off + ((delta and delta < 0) and 1 or -1)
    if off < 0 then off = 0 end
    if type(SetFrameScrollOffset) == "function" then
      SetFrameScrollOffset(host and host._id, off)
    end
    ns.Render.RefreshBarContentsFrame()
  end)

  f:HookScript("OnShow", function(self)
    RestoreWindowPosition("barContents", self, "CENTER", "CENTER", 0, 0)
  end)

  barContentsFrame = f
  return f
end

local function ShowBarContentsForFrameID(frameID)
  frameID = tostring(frameID or "")
  if frameID == "" then return end
  local f = EnsureBarContentsFrame()
  f._targetFrameID = frameID
  ns.Render.RefreshBarContentsFrame()
  f:Show()
end

function ns.Render.EnsureBarInspectButton(frame)
  if not frame then return nil end
  if frame._barInspectBtn then return frame._barInspectBtn end
  local b = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  b:SetSize(44, 16)
  b:SetText("List")
  b:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
  b:SetFrameLevel((frame.GetFrameLevel and frame:GetFrameLevel() or 1) + 40)
  b:SetScript("OnClick", function()
    if not IsEditMode() then return end
    local id = tostring(frame and frame._id or "")
    if id == "" then return end
    if barContentsFrame and barContentsFrame.IsShown and barContentsFrame:IsShown() then
      local cur = tostring(barContentsFrame._targetFrameID or "")
      if cur == id then
        barContentsFrame:Hide()
        return
      end
    end
    ShowBarContentsForFrameID(id)
  end)
  frame._barInspectBtn = b
  return b
end
