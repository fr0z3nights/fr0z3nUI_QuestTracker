local addonName, ns = ...

ns.FQTOptionsPanels = ns.FQTOptionsPanels or {}

local function NormalizeQuestXY(v)
  v = tostring(v or "X"):upper():gsub("%s+", "")
  if v == "QUESTX" then v = "X" end
  if v ~= "Y" and v ~= "K" then v = "X" end
  return v
end

local function IsXQuestRule(rule)
  if type(rule) ~= "table" then return false end
  local xy = NormalizeQuestXY(rule.questXY)
  return xy == "X" or xy == "Y" or xy == "K"
end

local function EntryKey(xy, questID)
  return tostring(NormalizeQuestXY(xy)) .. ":" .. tostring(tonumber(questID) or 0)
end

local function Trim(s)
  s = tostring(s or "")
  s = s:gsub("^%s+", ""):gsub("%s+$", "")
  return s
end

local function ParseZoneMeta(zoneText)
  zoneText = Trim(zoneText)
  if zoneText == "" then return nil end

  local a, b = zoneText:match("^(.-),%s*(.-)$")
  a = Trim(a)
  b = Trim(b)
  if a ~= "" and b ~= "" then
    return { zone = a, continent = b }
  end
  return { zone = zoneText, continent = nil }
end

function ns.FQTOptionsPanels.BuildXRules(ctx)
  if type(ctx) ~= "table" then return end

  local optionsFrame = ctx.optionsFrame
  local panels = ctx.panels
  if not (optionsFrame and panels and panels.xrules) then return end

  local CreateFrame = ctx.CreateFrame or CreateFrame
  local Print = ctx.Print or function(...) end

  local GetCustomRules = ctx.GetCustomRules
  local GetCharCustomRules = ctx.GetCharCustomRules
  local GetEffectiveDefaultRules = ctx.GetEffectiveDefaultRules
  local OpenCustomRuleInTab = ctx.OpenCustomRuleInTab
  local OpenCharCustomRuleInTab = ctx.OpenCharCustomRuleInTab
  local ToggleRuleDisabled = ctx.ToggleRuleDisabled
  local IsRuleDisabled = ctx.IsRuleDisabled
  local GetQuestTitle = ctx.GetQuestTitle

  local SetRefreshXRulesList = ctx.SetRefreshXRulesList

  local p = panels.xrules

  local title = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", 12, -40)
  title:SetText("XRules")

  local hint = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  hint:SetPoint("TOPLEFT", 12, -60)
  hint:SetText("XQuest rules live here (separate from Tracking rules). Use +/- to expand, A/C to toggle scope rules, Del removes custom rules.")

  local browserArea = CreateFrame("Frame", nil, p, "BackdropTemplate")
  browserArea:SetPoint("TOPLEFT", p, "TOPLEFT", 10, -74)
  browserArea:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -10, 44)
  browserArea:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    tile = true,
    tileSize = 16,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
  })
  browserArea:SetBackdropColor(0, 0, 0, 0.25)

  local browserEmpty = browserArea:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  browserEmpty:SetPoint("CENTER", browserArea, "CENTER", 0, 0)
  browserEmpty:SetText("No XQuest rules")

  local scroll = CreateFrame("ScrollFrame", nil, browserArea, "FauxScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", browserArea, "TOPLEFT", 4, -4)
  scroll:SetPoint("BOTTOMRIGHT", browserArea, "BOTTOMRIGHT", -4, 4)

  local ROW_H = 18
  local ROWS = 18
  local rows = {}

  local function SetScopeText(btn, label, state)
    if not (btn and btn.SetText) then return end
    if state == "active" then
      btn:SetText("|cff00ff00" .. label .. "|r")
    elseif state == "inactive" then
      btn:SetText("|cffffff00" .. label .. "|r")
    elseif state == "disabled" then
      btn:SetText("|cffff9900" .. label .. "|r")
    else
      btn:SetText("|cff666666" .. label .. "|r")
    end
  end

  for i = 1, ROWS do
    local row = CreateFrame("Frame", nil, browserArea)
    row:SetHeight(ROW_H)
    row:SetPoint("TOPLEFT", browserArea, "TOPLEFT", 8, -6 - (i - 1) * ROW_H)
    row:SetPoint("TOPRIGHT", browserArea, "TOPRIGHT", -8, -6 - (i - 1) * ROW_H)

    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(row)
    bg:Hide()
    row.bg = bg

    local expBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    expBtn:SetSize(18, ROW_H - 2)
    expBtn:SetPoint("LEFT", row, "LEFT", 0, 0)
    expBtn:SetText("+")
    row.btnExpand = expBtn

    local del = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    del:SetSize(34, ROW_H - 2)
    del:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    del:SetText("Del")
    row.btnDel = del

    local btnChar = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    btnChar:SetSize(22, ROW_H - 2)
    btnChar:SetPoint("RIGHT", del, "LEFT", -4, 0)
    btnChar:SetText("C")
    row.btnChar = btnChar

    local btnAcc = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    btnAcc:SetSize(22, ROW_H - 2)
    btnAcc:SetPoint("RIGHT", btnChar, "LEFT", -4, 0)
    btnAcc:SetText("A")
    row.btnAcc = btnAcc

    local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("LEFT", expBtn, "RIGHT", 6, 0)
    fs:SetPoint("RIGHT", btnAcc, "LEFT", -6, 0)
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(false)
    row.text = fs

    local click = CreateFrame("Button", nil, row)
    click:SetPoint("TOPLEFT", expBtn, "TOPRIGHT", 0, 0)
    click:SetPoint("BOTTOMRIGHT", btnAcc, "BOTTOMLEFT", 0, 0)
    click:RegisterForClicks("LeftButtonUp")
    row.btnClick = click

    row:Hide()
    rows[i] = row
  end

  local function EnsureTreeState()
    if type(p._xrulesTreeExpanded) ~= "table" then
      p._xrulesTreeExpanded = {}
    end
  end

  local function GetMapInfoSafe(mapID)
    mapID = tonumber(mapID)
    if not mapID or mapID <= 0 then return nil end
    if not (C_Map and C_Map.GetMapInfo) then return nil end
    local ok, info = pcall(C_Map.GetMapInfo, mapID)
    if not ok or type(info) ~= "table" then return nil end
    return info
  end

  local function ExtractFirstMapID(rule)
    if type(rule) ~= "table" or rule.locationID == nil then return nil end
    local s = tostring(rule.locationID or "")
    local n = tonumber((s:match("%d+")))
    return (n and n > 0) and n or nil
  end

  local function ResolveZoneAndContinent(mapID)
    mapID = tonumber(mapID)
    if not mapID or mapID <= 0 then return nil end

    local UIMapType = (Enum and Enum.UIMapType) or nil
    local zoneID, zoneName = nil, nil
    local contID, contName = nil, nil

    local visited = {}
    local curID = mapID
    local cur = GetMapInfoSafe(curID)
    while cur and not visited[curID] do
      visited[curID] = true

      if not zoneID then
        if UIMapType and cur.mapType == UIMapType.Zone then
          zoneID, zoneName = curID, tostring(cur.name or "")
        elseif not UIMapType then
          -- Best-effort fallback: treat the starting map as the zone.
          zoneID, zoneName = curID, tostring(cur.name or "")
        end
      end

      if UIMapType and cur.mapType == UIMapType.Continent then
        contID, contName = curID, tostring(cur.name or "")
      end

      local parentID = tonumber(cur.parentMapID or 0) or 0
      if parentID <= 0 then break end
      curID = parentID
      cur = GetMapInfoSafe(curID)
    end

    -- Fallbacks if mapTypes aren't available/weren't hit.
    if not zoneID then
      local mi = GetMapInfoSafe(mapID)
      if mi and mi.name then
        zoneID, zoneName = mapID, tostring(mi.name)
      end
    end

    if not contID then
      -- Try "one hop up" as continent-ish (works reasonably for most zone mapIDs).
      local mi = GetMapInfoSafe(mapID)
      local parentID = mi and tonumber(mi.parentMapID or 0) or 0
      local parent = (parentID and parentID > 0) and GetMapInfoSafe(parentID) or nil
      if parent and parent.name then
        contID, contName = parentID, tostring(parent.name)
      end
    end

    if zoneName == "" then zoneName = nil end
    if contName == "" then contName = nil end

    return {
      zoneID = zoneID,
      zoneName = zoneName,
      continentID = contID,
      continentName = contName,
    }
  end

  local function GetDbZoneMetaForQuest(qid)
    qid = tonumber(qid)
    if not qid or qid <= 0 then return nil end
    local qdb = ns and ns.db and ns.db.xquest and ns.db.xquest.quests
    if type(qdb) ~= "table" then return nil end
    local entry = qdb[qid]
    if type(entry) ~= "table" then return nil end
    local meta = entry.__meta
    if type(meta) ~= "table" then return nil end

    if meta.zone then
      local parsed = ParseZoneMeta(meta.zone)
      if parsed then
        return {
          zoneName = parsed.zone,
          continentName = parsed.continent,
        }
      end
    end

    -- Alternate explicit fields.
    local zn = meta.zoneName or meta.zone
    local cn = meta.continentName or meta.continent
    zn = Trim(zn)
    cn = Trim(cn)
    if zn ~= "" or cn ~= "" then
      return {
        zoneName = (zn ~= "") and zn or nil,
        continentName = (cn ~= "") and cn or nil,
      }
    end

    return nil
  end

  local function CollectByKey()
    local byKey = {}

    local function ensure(xy, questID)
      local key = EntryKey(xy, questID)
      local e = byKey[key]
      if not e then
        e = { key = key, questID = tonumber(questID) or 0, questXY = NormalizeQuestXY(xy) }
        byKey[key] = e
      end
      return e
    end

    local function add(scope, idx, rule)
      if not IsXQuestRule(rule) then return end
      local questID = tonumber(rule.questID) or 0
      local xy = NormalizeQuestXY(rule.questXY)
      local e = ensure(xy, questID)

      if scope == "default" then
        if not e.defRule then e.defRule = rule end
      elseif scope == "acc" then
        e.accIndex = idx
        e.accRule = rule
      elseif scope == "char" then
        e.charIndex = idx
        e.charRule = rule
      end
    end

    local defs = (type(GetEffectiveDefaultRules) == "function") and GetEffectiveDefaultRules() or nil
    if type(defs) == "table" then
      for i = 1, #defs do
        add("default", i, defs[i])
      end
    end

    local acc = (type(GetCustomRules) == "function") and GetCustomRules() or nil
    if type(acc) == "table" then
      for i = 1, #acc do
        add("acc", i, acc[i])
      end
    end

    local chr = (type(GetCharCustomRules) == "function") and GetCharCustomRules() or nil
    if type(chr) == "table" then
      for i = 1, #chr do
        add("char", i, chr[i])
      end
    end

    return byKey
  end

  local function TreeKey(kind, a, b, c)
    local parts = { tostring(kind or "") }
    if a ~= nil then parts[#parts + 1] = tostring(a) end
    if b ~= nil then parts[#parts + 1] = tostring(b) end
    if c ~= nil then parts[#parts + 1] = tostring(c) end
    return table.concat(parts, ":")
  end

  local function IsExpanded(key, defaultVal)
    EnsureTreeState()
    if p._xrulesTreeExpanded[key] == nil then
      p._xrulesTreeExpanded[key] = defaultVal and true or false
    end
    return p._xrulesTreeExpanded[key] and true or false
  end

  local function SetExpanded(key, val)
    EnsureTreeState()
    p._xrulesTreeExpanded[key] = val and true or false
  end

  local function BuildNodes(byKey)
    EnsureTreeState()

    local roots = {
      { xy = "X", label = "XQuest" },
      { xy = "Y", label = "YQuest" },
      { xy = "K", label = "Keep" },
    }

    local groups = {}
    for _, r in ipairs(roots) do
      groups[r.xy] = {}
    end

    for _, e in pairs(byKey) do
      local xy = NormalizeQuestXY(e.questXY)

      local mapID = ExtractFirstMapID(e.accRule) or ExtractFirstMapID(e.charRule) or ExtractFirstMapID(e.defRule)
      local continentLabel, zoneLabel = nil, nil
      local continentKey, zoneKey = nil, nil

      if mapID then
        local resolved = ResolveZoneAndContinent(mapID)
        continentLabel = (resolved and resolved.continentName) or "Global/Unknown"
        zoneLabel = (resolved and resolved.zoneName) or "Global/Unknown"
        continentKey = tostring((resolved and resolved.continentID) or "global")
        zoneKey = tostring((resolved and resolved.zoneID) or "global")
      else
        local dbm = GetDbZoneMetaForQuest(e.questID)
        continentLabel = (dbm and dbm.continentName) or "Global/Unknown"
        zoneLabel = (dbm and dbm.zoneName) or "Global/Unknown"
        continentKey = tostring(continentLabel)
        zoneKey = tostring(zoneLabel)
      end

      local cont = groups[xy][continentKey]
      if not cont then
        cont = { key = continentKey, label = continentLabel, zones = {} }
        groups[xy][continentKey] = cont
      end

      local zn = cont.zones[zoneKey]
      if not zn then
        zn = { key = zoneKey, label = zoneLabel, entries = {} }
        cont.zones[zoneKey] = zn
      end

      zn.entries[#zn.entries + 1] = e
    end

    local function SortedKeys(t)
      local keys = {}
      for k in pairs(t or {}) do keys[#keys + 1] = k end
      table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
      return keys
    end

    local nodes = {}

    for _, root in ipairs(roots) do
      local xy = root.xy
      local groupNodeKey = TreeKey("xy", xy)
      local groupExpanded = IsExpanded(groupNodeKey, true)
      nodes[#nodes + 1] = { kind = "xy", key = groupNodeKey, label = root.label, level = 0, expanded = groupExpanded, questXY = xy }

      if groupExpanded then
        local contKeys = SortedKeys(groups[xy])
        table.sort(contKeys, function(a, b)
          local la = tostring((groups[xy][a] and groups[xy][a].label) or "")
          local lb = tostring((groups[xy][b] and groups[xy][b].label) or "")
          if la ~= lb then return la < lb end
          return tostring(a) < tostring(b)
        end)

        for _, ck in ipairs(contKeys) do
          local cont = groups[xy][ck]
          local contNodeKey = TreeKey("cont", xy, cont.label)
          local contExpanded = IsExpanded(contNodeKey, true)
          nodes[#nodes + 1] = { kind = "continent", key = contNodeKey, label = cont.label, level = 1, expanded = contExpanded, questXY = xy }

          if contExpanded then
            local zoneKeys = SortedKeys(cont.zones)
            table.sort(zoneKeys, function(a, b)
              local la = tostring((cont.zones[a] and cont.zones[a].label) or "")
              local lb = tostring((cont.zones[b] and cont.zones[b].label) or "")
              if la ~= lb then return la < lb end
              return tostring(a) < tostring(b)
            end)

            for _, zk in ipairs(zoneKeys) do
              local zn = cont.zones[zk]
              local zoneNodeKey = TreeKey("zone", xy, cont.label, zn.label)
              local zoneExpanded = IsExpanded(zoneNodeKey, true)
              nodes[#nodes + 1] = { kind = "zone", key = zoneNodeKey, label = zn.label, level = 2, expanded = zoneExpanded, questXY = xy }

              if zoneExpanded then
                table.sort(zn.entries, function(a, b)
                  if (a.questID or 0) ~= (b.questID or 0) then return (a.questID or 0) < (b.questID or 0) end
                  return tostring(a.key) < tostring(b.key)
                end)

                for _, e in ipairs(zn.entries) do
                  nodes[#nodes + 1] = { kind = "rule", key = e.key, entry = e, level = 3, questXY = xy }
                end
              end
            end
          end
        end
      end
    end

    return nodes
  end

  local function RefreshImpl()
    local byKey = CollectByKey()
    local nodes = BuildNodes(byKey)
    p._xruleNodes = nodes

    browserEmpty:SetShown(#nodes == 0)

    if FauxScrollFrame_Update then
      FauxScrollFrame_Update(scroll, #nodes, ROWS, ROW_H)
    end

    local offset = 0
    if FauxScrollFrame_GetOffset then
      offset = FauxScrollFrame_GetOffset(scroll)
    end

    for i = 1, ROWS do
      local idx = offset + i
      local row = rows[i]
      local node = nodes[idx]

      if not node then
        row:Hide()
      else
        row:Show()

        local zebra = (idx % 2) == 0
        row.bg:SetShown(zebra)
        row.bg:SetColorTexture(1, 1, 1, zebra and 0.05 or 0)

        local indent = tonumber(node.level or 0) * 14
        row.btnExpand:ClearAllPoints()
        row.btnExpand:SetPoint("LEFT", row, "LEFT", indent, 0)

        if node.kind == "xy" or node.kind == "continent" or node.kind == "zone" then
          row.btnExpand:Show()
          row.btnExpand:SetText(node.expanded and "-" or "+")
          row.btnAcc:Hide()
          row.btnChar:Hide()
          row.btnDel:Hide()
          row.btnAcc:SetScript("OnClick", nil)
          row.btnChar:SetScript("OnClick", nil)
          row.btnDel:SetScript("OnClick", nil)
          row.btnAcc:SetEnabled(false)
          row.btnChar:SetEnabled(false)
          row.text:SetText(node.label)
          if node.kind == "xy" then
            row.text:SetTextColor(0.8, 0.9, 1, 1)
          elseif node.kind == "continent" then
            row.text:SetTextColor(0.75, 0.85, 1, 1)
          else
            row.text:SetTextColor(1, 1, 1, 1)
          end

          local function toggle()
            SetExpanded(node.key, not (IsExpanded(node.key, true) and true or false))
            RefreshImpl()
          end

          row.btnExpand:SetScript("OnClick", toggle)
          row.btnClick:SetScript("OnClick", toggle)
        else
          local e = node.entry
          local xy = NormalizeQuestXY(e.questXY)
          local qid = tonumber(e.questID) or 0

          row.btnExpand:Hide()
          row.btnAcc:Show()
          row.btnChar:Show()
          row.btnDel:Show()

          local qTitle
          if type(GetQuestTitle) == "function" and qid > 0 then
            qTitle = GetQuestTitle(qid)
          end
          if type(qTitle) ~= "string" or qTitle == "" then
            qTitle = (qid > 0) and ("Quest " .. tostring(qid)) or "(no questID)"
          end

          local selectedKey = p._xrulesSelectedKey
          if selectedKey and selectedKey == e.key then
            row.bg:SetShown(true)
            row.bg:SetColorTexture(1, 1, 1, 0.12)
          end

          local hasDef = e.defRule ~= nil
          local hasAcc = e.accRule ~= nil
          local hasChar = e.charRule ~= nil

          local dbOnly = hasDef and (not hasAcc) and (not hasChar)

          local defDisabled = false
          if hasDef and type(IsRuleDisabled) == "function" then
            local ok, v = pcall(IsRuleDisabled, e.defRule)
            if ok and v then defDisabled = true end
          end

          local accDisabled = false
          if hasAcc and type(IsRuleDisabled) == "function" then
            local ok, v = pcall(IsRuleDisabled, e.accRule)
            if ok and v then accDisabled = true end
          end
          local charDisabled = false
          if hasChar and type(IsRuleDisabled) == "function" then
            local ok, v = pcall(IsRuleDisabled, e.charRule)
            if ok and v then charDisabled = true end
          end

          local line = string.format("%s: %s |cff999999(%d)|r", (xy == "K") and "Keep" or (xy == "Y") and "YQuest" or "XQuest", tostring(qTitle), qid)
          if hasDef and not dbOnly then
            line = line .. " |cff999999[DB]|r"
          end
          local anyDisabled = (dbOnly and defDisabled) or (hasAcc and accDisabled) or (hasChar and charDisabled)
          row.text:SetTextColor(anyDisabled and 0.67 or 1, anyDisabled and 0.67 or 1, anyDisabled and 0.67 or 1, 1)
          row.text:SetText(line)

          if dbOnly then
            -- DB-only: A/C are proxies for toggling the default rule on this character.
            local function ConfigureDbProxy(btn, label)
              btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
              SetScopeText(btn, label, defDisabled and "disabled" or "active")
              btn:SetEnabled(true)
              btn:SetScript("OnClick", function(_, mouseButton)
                if mouseButton == "RightButton" then return end
                if type(ToggleRuleDisabled) == "function" then
                  pcall(ToggleRuleDisabled, e.defRule)
                end
                RefreshImpl()
              end)
            end
            ConfigureDbProxy(row.btnAcc, "A")
            ConfigureDbProxy(row.btnChar, "C")

            row.btnDel:Disable()
            row.btnDel:SetText("DB")
            row.btnDel:SetScript("OnClick", nil)
          else
            if hasAcc then
            SetScopeText(row.btnAcc, "A", accDisabled and "disabled" or "active")
            row.btnAcc:SetEnabled(true)
            row.btnAcc:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            row.btnAcc:SetScript("OnClick", function(_, mouseButton)
              if mouseButton == "RightButton" then return end
              if type(ToggleRuleDisabled) == "function" then
                pcall(ToggleRuleDisabled, e.accRule)
              end
              RefreshImpl()
            end)
            else
            SetScopeText(row.btnAcc, "A", "inactive")
            row.btnAcc:SetEnabled(hasChar and true or false)
            row.btnAcc:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            row.btnAcc:SetScript("OnClick", function(_, mouseButton)
              if mouseButton == "RightButton" then return end
              if not hasChar then return end
              local src = (type(GetCharCustomRules) == "function") and GetCharCustomRules() or nil
              local dst = (type(GetCustomRules) == "function") and GetCustomRules() or nil
              if type(src) ~= "table" or type(dst) ~= "table" then return end
              local n = tonumber(e.charIndex)
              if not n or n < 1 or n > #src then return end
              dst[#dst + 1] = src[n]
              table.remove(src, n)
              RefreshImpl()
            end)
            end

            if hasChar then
            SetScopeText(row.btnChar, "C", charDisabled and "disabled" or "active")
            row.btnChar:SetEnabled(true)
            row.btnChar:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            row.btnChar:SetScript("OnClick", function(_, mouseButton)
              if mouseButton == "RightButton" then return end
              if type(ToggleRuleDisabled) == "function" then
                pcall(ToggleRuleDisabled, e.charRule)
              end
              RefreshImpl()
            end)
            else
            SetScopeText(row.btnChar, "C", "inactive")
            row.btnChar:SetEnabled(hasAcc and true or false)
            row.btnChar:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            row.btnChar:SetScript("OnClick", function(_, mouseButton)
              if mouseButton == "RightButton" then return end
              if not hasAcc then return end
              local src = (type(GetCustomRules) == "function") and GetCustomRules() or nil
              local dst = (type(GetCharCustomRules) == "function") and GetCharCustomRules() or nil
              if type(src) ~= "table" or type(dst) ~= "table" then return end
              local n = tonumber(e.accIndex)
              if not n or n < 1 or n > #src then return end
              dst[#dst + 1] = src[n]
              table.remove(src, n)
              RefreshImpl()
            end)
            end

            row.btnDel:Enable()
            row.btnDel:SetText("Del")
            row.btnDel:SetScript("OnClick", function()
              local acc = (type(GetCustomRules) == "function") and GetCustomRules() or nil
              local chr = (type(GetCharCustomRules) == "function") and GetCharCustomRules() or nil

              if hasAcc and type(acc) == "table" then
                local n = tonumber(e.accIndex)
                if n and n >= 1 and n <= #acc then
                  table.remove(acc, n)
                end
              end
              if hasChar and type(chr) == "table" then
                local n = tonumber(e.charIndex)
                if n and n >= 1 and n <= #chr then
                  table.remove(chr, n)
                end
              end
              RefreshImpl()
            end)
          end

          -- Row click selects (Talk-style). Editing is done on the XQuest tab.
          row.btnClick:SetScript("OnClick", function()
            p._xrulesSelectedKey = e.key
            RefreshImpl()
          end)
        end
      end
    end
  end

  p._refreshXRulesList = RefreshImpl
  optionsFrame._refreshXRulesList = RefreshImpl

  if type(SetRefreshXRulesList) == "function" then
    SetRefreshXRulesList(function() return RefreshImpl() end)
  end

  scroll:SetScript("OnVerticalScroll", function(self, offset)
    if FauxScrollFrame_OnVerticalScroll then
      FauxScrollFrame_OnVerticalScroll(self, offset, ROW_H, RefreshImpl)
    end
  end)

  scroll:SetScript("OnShow", function() RefreshImpl() end)
  p:SetScript("OnShow", function() RefreshImpl() end)
end
