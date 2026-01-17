local addonName, ns = ...

-- WeakAuras import/export tooling (split from fr0z3nUI_QuestTracker_Core.lua)
-- Depends on shared helpers exposed on ns by fr0z3nUI_QuestTracker_Core.lua.
local Print = (ns and ns.Print) or function(msg) print(tostring(msg or "")) end
local CopyArray = ns and ns.CopyArray
local PrereqListKey = ns and ns.PrereqListKey
local GetCustomRules = ns and ns.GetCustomRules
local GetWAExportDB = ns and ns.GetWAExportDB
local SaveWAExportSnapshot = ns and ns.SaveWAExportSnapshot
local CreateAllFrames = ns and ns.CreateAllFrames
local RefreshAll = ns and ns.RefreshAll
local RefreshRulesList = ns and ns.RefreshRulesList
local GetUISetting = ns and ns.GetUISetting
local SetUISetting = ns and ns.SetUISetting
local RestoreWindowPosition = ns and ns.RestoreWindowPosition
local SaveWindowPosition = ns and ns.SaveWindowPosition
local ApplyFAOBackdrop = ns and ns.ApplyFAOBackdrop
local GetQuestTitle = ns and ns.GetQuestTitle

local weakAuraImportFrame

local function GetWeakAuraDataByIdOrUid(idOrUid)
  idOrUid = tostring(idOrUid or "")
  if idOrUid == "" then return nil end

  local WA = _G and _G["WeakAuras"]
  local WASaved = _G and _G["WeakAurasSaved"]

  if WASaved and type(WASaved.displays) == "table" then
    for id, data in pairs(WASaved.displays) do
      if type(data) == "table" then
        if tostring(data.uid or "") == idOrUid or tostring(id or "") == idOrUid or tostring(data.id or "") == idOrUid then
          return data, tostring(id or data.id or idOrUid)
        end
      end
    end
  end

  -- Fallback: ask WeakAuras API (may return a processed view that omits some raw strings).
  if WA and WA.GetData then
    local ok, data = pcall(WA.GetData, idOrUid)
    if ok and type(data) == "table" then
      return data, idOrUid
    end
  end

  return nil
end

local function ExtractQuestIDsFromWeakAura(auraData, includeChildren)
  local set = {}
  local primarySet = {}
  local visited = {}

  local function AddQuestIDsFromString(s)
    s = tostring(s or "")
    if s == "" then return end

    -- Strong patterns first (very low false-positive rate)
    for id in s:gmatch("IsQuestFlaggedCompleted%s*%(%s*(%d+)%s*%)") do
      local qid = tonumber(id)
      if qid and qid > 0 then set[qid] = true end
    end
    for id in s:gmatch("GetLogIndexForQuestID%s*%(%s*(%d+)%s*%)") do
      local qid = tonumber(id)
      if qid and qid > 0 then set[qid] = true end
    end
    for id in s:gmatch("GetTitleForQuestID%s*%(%s*(%d+)%s*%)") do
      local qid = tonumber(id)
      if qid and qid > 0 then set[qid] = true end
    end
    for id in s:gmatch("allstates%s*%[%s*(%d+)%s*%]") do
      local qid = tonumber(id)
      if qid and qid > 0 then
        set[qid] = true
        primarySet[qid] = true
      end
    end
  end

  local function AddQuestID(v)
    local id = tonumber(v)
    if id and id > 0 then
      set[id] = true
    end
  end

  local function Walk(node)
    if type(node) ~= "table" then return end
    if visited[node] then return end
    visited[node] = true

    for k, v in pairs(node) do
      local key = tostring(k or ""):lower()
      if key:find("quest", 1, true) and key:find("id", 1, true) then
        if type(v) == "number" then
          AddQuestID(v)
          primarySet[tonumber(v)] = true
        elseif type(v) == "string" and v:match("^%d+$") then
          AddQuestID(v)
          primarySet[tonumber(v)] = true
        elseif type(v) == "table" then
          for _, q in ipairs(v) do
            AddQuestID(q)
            local qid = tonumber(q)
            if qid and qid > 0 then primarySet[qid] = true end
          end
        end
      end

      if type(v) == "string" then
        -- Custom triggers/conditions often store Lua source in strings.
        -- Only scan strings that look quest-related to keep it cheap.
        local hay = v:lower()
        if hay:find("quest", 1, true) or hay:find("c_questlog", 1, true) or hay:find("isquestflaggedcompleted", 1, true) then
          AddQuestIDsFromString(v)
        end
      end

      if type(v) == "table" then
        Walk(v)
      end
    end
  end

  Walk(auraData)

  if includeChildren and type(auraData) == "table" and type(auraData.controlledChildren) == "table" then
    for _, childID in ipairs(auraData.controlledChildren) do
      local child = GetWeakAuraDataByIdOrUid(childID)
      if type(child) == "table" then
        Walk(child)
      end
    end
  end

  local allList = {}
  for qid in pairs(set) do
    allList[#allList + 1] = qid
  end
  table.sort(allList)

  local primaryList = {}
  for qid in pairs(primarySet) do
    primaryList[#primaryList + 1] = qid
  end
  table.sort(primaryList)

  return allList, primaryList
end

local function ExtractQuestRuleSpecsFromWeakAura(auraData, includeChildren)
  local specs = {}

  local function UnescapeLuaString(s)
    s = tostring(s or "")
    s = s:gsub("\\\\n", "\n")
    s = s:gsub("\\\\r", "\r")
    s = s:gsub("\\\\t", "\t")
    s = s:gsub("\\\\\"", "\"")
    s = s:gsub("\\\\'", "'")
    s = s:gsub("\\\\\\\\", "\\")
    return s
  end

  local function TryCaptureTriggerLabelFromString(s, labelHolder)
    if not labelHolder or labelHolder.name then return end
    s = UnescapeLuaString(s)
    if s == "" then return end

    -- This is intentionally heuristic (different auras store this differently).
    -- Must support embedded newlines in the quoted string.
    local _, name = s:match("aura_env%.name%s*=%s*(['\"])([%s%S]-)%1")
    if not name then _, name = s:match("local%s+name%s*=%s*(['\"])([%s%S]-)%1") end
    if not name then _, name = s:match("[^%w_]name%s*=%s*(['\"])([%s%S]-)%1") end

    -- If we still didn't find anything, fall back to the first allstates[...] name= assignment.
    -- This is the most common pattern in custom triggers like:
    --   allstates[45727] = { ..., name = '...', ... }
    if not name then
      _, name = s:match("allstates%s*%[%s*[^%]]+%s*%][%s%S]-name%s*=%s*(['\"])([%s%S]-)%1")
    end

    if type(name) == "string" then
      name = name:gsub("^%s+", ""):gsub("%s+$", "")
      if name ~= "" then
        labelHolder.name = name
      end
    end
  end

  local function TryCaptureFactionFromString(s, out)
    if not out or out.faction then return end
    s = UnescapeLuaString(s)
    if s == "" then return end

    -- Common patterns used in WeakAuras custom triggers/conditions.
    -- UnitFactionGroup("player") returns "Alliance" or "Horde".
    local fac = s:match("UnitFactionGroup%s*%(%s*['\"]player['\"]%s*%)%s*==%s*['\"](Alliance|Horde)['\"]")
    if not fac then
      fac = s:match("UnitFactionGroup%s*%(%s*['\"]player['\"]%s*%)%s*~=%s*['\"](Alliance|Horde)['\"]")
      if fac == "Alliance" then fac = "Horde" elseif fac == "Horde" then fac = "Alliance" end
    end
    if not fac then
      fac = s:match("GetFactionGroup%s*%(%s*%)%s*==%s*['\"](Alliance|Horde)['\"]")
    end

    if fac == "Alliance" or fac == "Horde" then
      out.faction = fac
    end
  end

  local function AddQuestIDsFromString(s, set, mainSet, prereqSet, nameByID)
    s = UnescapeLuaString(s)
    if s == "" then return end

    -- Prereq-style checks (quests referenced as completion/title/log-index checks)
    for id in s:gmatch("IsQuestFlaggedCompleted%s*%(%s*(%d+)%s*%)") do
      local qid = tonumber(id)
      if qid and qid > 0 then
        set[qid] = true
        prereqSet[qid] = true
      end
    end
    for id in s:gmatch("C_QuestLog%.IsQuestFlaggedCompleted%s*%(%s*(%d+)%s*%)") do
      local qid = tonumber(id)
      if qid and qid > 0 then
        set[qid] = true
        prereqSet[qid] = true
      end
    end
    for id in s:gmatch("GetLogIndexForQuestID%s*%(%s*(%d+)%s*%)") do
      local qid = tonumber(id)
      if qid and qid > 0 then
        set[qid] = true
        prereqSet[qid] = true
      end
    end
    for id in s:gmatch("C_QuestLog%.GetLogIndexForQuestID%s*%(%s*(%d+)%s*%)") do
      local qid = tonumber(id)
      if qid and qid > 0 then
        set[qid] = true
        prereqSet[qid] = true
      end
    end
    for id in s:gmatch("GetTitleForQuestID%s*%(%s*(%d+)%s*%)") do
      local qid = tonumber(id)
      if qid and qid > 0 then
        set[qid] = true
        prereqSet[qid] = true
      end
    end
    for id in s:gmatch("C_QuestLog%.GetTitleForQuestID%s*%(%s*(%d+)%s*%)") do
      local qid = tonumber(id)
      if qid and qid > 0 then
        set[qid] = true
        prereqSet[qid] = true
      end
    end

    -- Main-quest-style checks (quests referenced as allstates keys)
    for id in s:gmatch("allstates%s*%[%s*(%d+)%s*%]") do
      local qid = tonumber(id)
      if qid and qid > 0 then
        set[qid] = true
        mainSet[qid] = true
      end
    end

    for qid, _, name in s:gmatch("allstates%s*%[%s*(%d+)%s*%][%s%S]-name%s*=%s*(['\"])([%s%S]-)%2") do
      local idn = tonumber(qid)
      if idn and idn > 0 and type(name) == "string" and name ~= "" then
        nameByID[idn] = name
      end
    end

    -- Alternate common style: allstates[123].name = "..."
    for qid, _, name in s:gmatch("allstates%s*%[%s*(%d+)%s*%]%s*%.%s*name%s*=%s*(['\"])([%s%S]-)%2") do
      local idn = tonumber(qid)
      if idn and idn > 0 and type(name) == "string" and name ~= "" then
        nameByID[idn] = name
      end
    end
  end

  local function CollectStrings(root, out)
    if type(root) ~= "table" then return end
    local visited = {}
    local function Walk(node)
      if type(node) ~= "table" then return end
      if visited[node] then return end
      visited[node] = true
      for _, v in pairs(node) do
        if type(v) == "string" then
          out[#out + 1] = v
        elseif type(v) == "table" then
          Walk(v)
        end
      end
    end
    Walk(root)
  end

  local function ProcessTrigger(trig)
    if type(trig) ~= "table" then return end
    local strings = {}
    CollectStrings(trig, strings)

    local set = {}
    local mainSet = {}
    local mainCandidateSet = {}
    local prereqSet = {}
    local nameByID = {}
    local labelHolder = {}
    local factionHolder = {}

    for _, s in ipairs(strings) do
      -- Label capture shouldn't depend on quest keyword heuristics.
      TryCaptureTriggerLabelFromString(s, labelHolder)
      TryCaptureFactionFromString(s, factionHolder)

      local hay = s:lower()
      if hay:find("quest", 1, true) or hay:find("c_questlog", 1, true) or hay:find("isquestflaggedcompleted", 1, true) or hay:find("allstates", 1, true) then
        AddQuestIDsFromString(s, set, mainSet, prereqSet, nameByID)
      end
    end

    for k, v in pairs(trig) do
      local key = tostring(k or ""):lower()
      if key:find("quest", 1, true) and key:find("id", 1, true) then
        local qid = tonumber(v)
        if qid and qid > 0 then
          set[qid] = true
          mainCandidateSet[qid] = true
        end
      end

      if not factionHolder.faction and key:find("faction", 1, true) and type(v) == "string" then
        local vv = tostring(v)
        if vv == "Alliance" or vv == "Horde" then
          factionHolder.faction = vv
        end
      end
    end

    local mains = {}
    for qid in pairs(mainSet) do mains[#mains + 1] = qid end
    table.sort(mains)

    if #mains == 0 then
      for qid in pairs(mainCandidateSet) do mains[#mains + 1] = qid end
      table.sort(mains)
    end

    local all = {}
    for qid in pairs(set) do all[#all + 1] = qid end
    table.sort(all)

    if #mains == 0 and #all == 1 then
      mains[1] = all[1]
    end
    if #mains == 0 then return end

    local prereqList = {}
    for qid in pairs(prereqSet) do prereqList[#prereqList + 1] = qid end
    table.sort(prereqList)

    local mainLookup = {}
    for _, qid in ipairs(mains) do mainLookup[qid] = true end

    for _, mainID in ipairs(mains) do
      local prereq = nil
      for _, qid in ipairs(prereqList) do
        if qid ~= mainID and not mainLookup[qid] then
          prereq = prereq or {}
          prereq[#prereq + 1] = qid
        end
      end

      specs[#specs + 1] = {
        questID = mainID,
        prereq = prereq,
        label = nameByID[mainID] or labelHolder.name,
        faction = factionHolder.faction,
      }
    end
  end

  local function ProcessOneAura(data)
    if type(data) ~= "table" then return end

    local triggers = data.triggers or rawget(data, "triggers")
    if type(triggers) == "table" then
      -- Modern WeakAuras stores the trigger list under triggers.triggers
      local list = rawget(triggers, "triggers")
      if type(list) == "table" and #list > 0 then
        for i = 1, #list do
          ProcessTrigger(list[i])
        end
        return
      end

      local keys = {}
      for k in pairs(triggers) do
        local n = tonumber(k)
        if n and n > 0 and n == math.floor(n) then
          keys[#keys + 1] = n
        end
      end
      table.sort(keys)
      for _, idx in ipairs(keys) do
        ProcessTrigger(triggers[idx])
      end
      return
    end

    -- Legacy/single-trigger format (older WeakAuras versions)
    if type(data.trigger) == "table" then
      ProcessTrigger({
        trigger = data.trigger,
        untrigger = data.untrigger,
        conditions = data.conditions,
        actions = data.actions,
      })
    end
  end

  ProcessOneAura(auraData)
  if includeChildren and type(auraData) == "table" and type(auraData.controlledChildren) == "table" then
    for _, childID in ipairs(auraData.controlledChildren) do
      local child = GetWeakAuraDataByIdOrUid(childID)
      if type(child) == "table" then
        ProcessOneAura(child)
      end
    end
  end

  return specs
end

local function ExtractDisplayTextsFromWeakAura(auraData, includeChildren)
  local seen = {}
  local list = {}
  local visited = {}

  local function UnescapeLuaString(s)
    s = tostring(s or "")
    -- minimal unescape for common WA strings
    s = s:gsub("\\\\n", "\n")
    s = s:gsub("\\\\r", "\r")
    s = s:gsub("\\\\t", "\t")
    s = s:gsub("\\\\\\\\", "\\")
    return s
  end

  local function AddText(t)
    if type(t) ~= "string" then return end
    t = UnescapeLuaString(t)
    if t == "" then return end
    if seen[t] then return end
    seen[t] = true
    list[#list + 1] = t
  end

  local function Walk(node)
    if type(node) ~= "table" then return end
    if visited[node] then return end
    visited[node] = true

    -- Common top-level / sub-region fields WeakAuras uses for text display.
    AddText(rawget(node, "text"))
    AddText(rawget(node, "displayText"))
    AddText(rawget(node, "customText"))
    AddText(rawget(node, "text_text"))
    AddText(rawget(node, "displayTextText"))

    local sub = rawget(node, "subRegions")
    if type(sub) == "table" then
      for _, sr in ipairs(sub) do
        if type(sr) == "table" then
          AddText(rawget(sr, "text"))
          AddText(rawget(sr, "displayText"))
          AddText(rawget(sr, "customText"))
          AddText(rawget(sr, "text_text"))
        end
      end
    end

    for _, v in pairs(node) do
      if type(v) == "table" then
        Walk(v)
      end
    end
  end

  Walk(auraData)

  if includeChildren and type(auraData) == "table" and type(auraData.controlledChildren) == "table" then
    for _, childID in ipairs(auraData.controlledChildren) do
      local child = GetWeakAuraDataByIdOrUid(childID)
      if type(child) == "table" then
        Walk(child)
      end
    end
  end

  return list
end

local function ExtractSpellIDsFromWeakAura(auraData, includeChildren)
  local knownSet = {}
  local notKnownSet = {}
  local visited = {}

  local function AddKnown(v)
    local id = tonumber(v)
    if id and id > 0 then knownSet[id] = true end
  end

  local function AddNotKnown(v)
    local id = tonumber(v)
    if id and id > 0 then notKnownSet[id] = true end
  end

  local function ScanString(s)
    if type(s) ~= "string" or s == "" then return end

    -- Negated patterns first
    for id in s:gmatch("not%s+IsSpellKnown%s*%(%s*(%d+)%s*%)") do
      AddNotKnown(id)
    end
    for id in s:gmatch("not%s+IsPlayerSpell%s*%(%s*(%d+)%s*%)") do
      AddNotKnown(id)
    end
    for id in s:gmatch("IsSpellKnown%s*%(%s*(%d+)%s*%)%s*==%s*false") do
      AddNotKnown(id)
    end
    for id in s:gmatch("IsPlayerSpell%s*%(%s*(%d+)%s*%)%s*==%s*false") do
      AddNotKnown(id)
    end

    -- Positive patterns
    for id in s:gmatch("IsSpellKnown%s*%(%s*(%d+)%s*%)") do
      AddKnown(id)
    end
    for id in s:gmatch("IsPlayerSpell%s*%(%s*(%d+)%s*%)") do
      AddKnown(id)
    end
  end

  local function Walk(node)
    if type(node) ~= "table" then return end
    if visited[node] then return end
    visited[node] = true

    for k, v in pairs(node) do
      local key = tostring(k or ""):lower()

      -- Heuristics for WA trigger fields
      if type(v) == "number" or (type(v) == "string" and v:match("^%d+$")) then
        if (key:find("spell", 1, true) and key:find("known", 1, true)) or key == "spellknown" then
          AddKnown(v)
        elseif (key:find("spell", 1, true) and key:find("not", 1, true) and key:find("known", 1, true)) or key == "notspellknown" then
          AddNotKnown(v)
        elseif key == "spellid" or key == "spell_id" then
          -- ambiguous; treat as known for convenience
          AddKnown(v)
        end
      end

      if type(v) == "string" then
        local hay = v:lower()
        if hay:find("isspellknown", 1, true) or hay:find("isplayerspell", 1, true) then
          ScanString(v)
        end
      end

      if type(v) == "table" then
        Walk(v)
      end
    end
  end

  Walk(auraData)

  if includeChildren and type(auraData) == "table" and type(auraData.controlledChildren) == "table" then
    for _, childID in ipairs(auraData.controlledChildren) do
      local child = GetWeakAuraDataByIdOrUid(childID)
      if type(child) == "table" then
        Walk(child)
      end
    end
  end

  local knownList = {}
  for id in pairs(knownSet) do knownList[#knownList + 1] = id end
  table.sort(knownList)

  local notKnownList = {}
  for id in pairs(notKnownSet) do notKnownList[#notKnownList + 1] = id end
  table.sort(notKnownList)

  return knownList, notKnownList
end

function EnsureWeakAuraImportFrame()
  if weakAuraImportFrame then return weakAuraImportFrame end

  local function ParseQuestIDList(text)
    local out = nil
    local t = tostring(text or "")
    t = t:gsub(";", ",")
    for token in t:gmatch("[^,%s]+") do
      local n = tonumber(token)
      if n and n > 0 then
        out = out or {}
        out[#out + 1] = n
      end
    end
    return out
  end

  local f = CreateFrame("Frame", "FR0Z3NUIFQTWeakAuraImport", UIParent, "BackdropTemplate")
  f:SetSize(520, 520)
  f:SetPoint("CENTER")
  f:SetFrameStrata("DIALOG")
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:EnableMouse(true)
  RestoreWindowPosition("weakauraImport", f, "CENTER", "CENTER", 0, 0)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", function(self)
    if self.StopMovingOrSizing then self:StopMovingOrSizing() end
    SaveWindowPosition("weakauraImport", self)
  end)
  ApplyFAOBackdrop(f, 0.9)

  f:HookScript("OnShow", function(self)
    RestoreWindowPosition("weakauraImport", self, "CENTER", "CENTER", 0, 0)
  end)
  f:HookScript("OnHide", function(self)
    SaveWindowPosition("weakauraImport", self)
  end)

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", 12, -10)
  title:SetText("|cff00ccff[FQT]|r WeakAuras Import |cffffffff(Module)|r")

  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", f, "TOPRIGHT", 2, 2)

  local auraLabel = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  auraLabel:SetPoint("TOPLEFT", 12, -40)
  auraLabel:SetText("Aura ID (WeakAuras name in the list):")

  local auraBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
  auraBox:SetSize(250, 20)
  auraBox:SetPoint("TOPLEFT", 12, -56)
  auraBox:SetAutoFocus(false)
  auraBox:SetText("")
  auraBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  f._auraBox = auraBox

  local includeChildren = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
  includeChildren:SetPoint("LEFT", auraBox, "RIGHT", 16, 0)
  includeChildren.text:SetText("Include children")
  includeChildren:SetChecked(true)
  f._includeChildren = includeChildren

  local primaryOnly = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
  primaryOnly:SetPoint("TOPLEFT", includeChildren, "BOTTOMLEFT", 0, 2)
  primaryOnly.text:SetText("Only import primary questIDs")
  primaryOnly:SetChecked(false)
  f._primaryOnly = primaryOnly

  local importSpellRule = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
  importSpellRule:SetPoint("TOPLEFT", primaryOnly, "BOTTOMLEFT", 0, 2)
  importSpellRule.text:SetText("Import Spell rule")
  importSpellRule:SetChecked(false)
  f._importSpellRule = importSpellRule

  local exportOnly = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
  exportOnly:SetPoint("TOPLEFT", importSpellRule, "BOTTOMLEFT", 0, 2)
  exportOnly.text:SetText("Export only (don't create rules)")
  exportOnly:SetChecked(false)
  f._exportOnly = exportOnly

  local frameLabel = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  frameLabel:SetPoint("TOPLEFT", 12, -82)
  frameLabel:SetText("Target frameID:")

  local frameBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
  frameBox:SetSize(90, 20)
  frameBox:SetPoint("TOPLEFT", 12, -98)
  frameBox:SetAutoFocus(false)
  frameBox:SetText("list1")
  frameBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  f._frameBox = frameBox

  local labelLabel = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  labelLabel:SetPoint("LEFT", frameBox, "RIGHT", 16, 0)
  labelLabel:SetText("Label prefix (optional):")

  local prefixBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
  prefixBox:SetSize(160, 20)
  prefixBox:SetPoint("LEFT", labelLabel, "RIGHT", 8, 0)
  prefixBox:SetAutoFocus(false)
  prefixBox:SetText("[WA] ")
  prefixBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  f._prefixBox = prefixBox

  local mainQuestLabel = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  mainQuestLabel:SetPoint("TOPLEFT", 12, -122)
  mainQuestLabel:SetText("Main questID:")

  local mainQuestBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
  mainQuestBox:SetSize(90, 20)
  mainQuestBox:SetPoint("TOPLEFT", 12, -138)
  mainQuestBox:SetAutoFocus(false)
  mainQuestBox:SetNumeric(true)
  mainQuestBox:SetText("0")
  mainQuestBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  f._mainQuestBox = mainQuestBox

  local prereqImportLabel = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  prereqImportLabel:SetPoint("LEFT", mainQuestBox, "RIGHT", 16, 0)
  prereqImportLabel:SetText("Prereq questIDs (comma-separated):")

  local prereqImportBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
  prereqImportBox:SetSize(240, 20)
  prereqImportBox:SetPoint("LEFT", prereqImportLabel, "RIGHT", 8, 0)
  prereqImportBox:SetAutoFocus(false)
  prereqImportBox:SetText("")
  prereqImportBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  f._prereqImportBox = prereqImportBox

  local resultsLabel = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  resultsLabel:SetPoint("TOPLEFT", 12, -166)
  resultsLabel:SetText("Detected questIDs:")

  local resultsScroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
  resultsScroll:SetPoint("TOPLEFT", 12, -184)
  resultsScroll:SetSize(490, 120)

  local resultsBox = CreateFrame("EditBox", nil, resultsScroll)
  resultsBox:SetMultiLine(true)
  resultsBox:SetAutoFocus(false)
  resultsBox:SetFontObject("ChatFontNormal")
  resultsBox:SetWidth(470)
  resultsBox:SetTextInsets(6, 6, 6, 6)
  resultsBox:SetText("")
  resultsBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  resultsScroll:SetScrollChild(resultsBox)
  f._resultsBox = resultsBox

  local displayLabel = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  displayLabel:SetPoint("TOPLEFT", 12, -310)
  displayLabel:SetText("Display text (from WeakAuras):")

  local displayScroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
  displayScroll:SetPoint("TOPLEFT", 12, -328)
  displayScroll:SetSize(490, 90)

  local displayBox = CreateFrame("EditBox", nil, displayScroll)
  displayBox:SetMultiLine(true)
  displayBox:SetAutoFocus(false)
  displayBox:SetFontObject("ChatFontNormal")
  displayBox:SetWidth(470)
  displayBox:SetTextInsets(6, 6, 6, 6)
  displayBox:SetText("")
  displayBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  displayScroll:SetScrollChild(displayBox)
  f._displayBox = displayBox

  local spellsLabel = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  spellsLabel:SetPoint("TOPLEFT", 12, -426)
  spellsLabel:SetText("Detected spells (optional):")

  local knownSpellLabel = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  knownSpellLabel:SetPoint("TOPLEFT", 12, -448)
  knownSpellLabel:SetText("Spell Known")

  local knownSpellBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
  knownSpellBox:SetSize(90, 20)
  knownSpellBox:SetPoint("TOPLEFT", 12, -464)
  knownSpellBox:SetAutoFocus(false)
  knownSpellBox:SetNumeric(true)
  knownSpellBox:SetText("0")
  knownSpellBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  f._knownSpellBox = knownSpellBox

  local notKnownSpellLabel = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  notKnownSpellLabel:SetPoint("LEFT", knownSpellBox, "RIGHT", 16, 0)
  notKnownSpellLabel:SetText("Not Spell Known")

  local notKnownSpellBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
  notKnownSpellBox:SetSize(90, 20)
  notKnownSpellBox:SetPoint("LEFT", notKnownSpellLabel, "RIGHT", 8, 0)
  notKnownSpellBox:SetAutoFocus(false)
  notKnownSpellBox:SetNumeric(true)
  notKnownSpellBox:SetText("0")
  notKnownSpellBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  f._notKnownSpellBox = notKnownSpellBox

  local scanBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  scanBtn:SetSize(120, 22)
  scanBtn:SetPoint("BOTTOMLEFT", 12, 12)
  scanBtn:SetText("Scan")

  local importBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  importBtn:SetSize(160, 22)
  importBtn:SetPoint("LEFT", scanBtn, "RIGHT", 8, 0)
  importBtn:SetText("Create Quest Rule")

  local status = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  status:SetPoint("BOTTOMRIGHT", -12, 16)
  status:SetText("")
  f._status = status

  local function RenderResults(questIDs, auraName, totalCount, primaryCount)
    auraName = tostring(auraName or "")
    local specs = f._questRuleSpecs
    if (type(questIDs) ~= "table" or #questIDs == 0) and (type(specs) ~= "table" or #specs == 0) then
      resultsBox:SetText("")
      status:SetText("No questIDs found.")
      f._questIDsAll = {}
      f._questIDsPrimary = {}
      f._questRuleSpecs = {}
      f._displayTexts = {}
      f._spellKnownIDs = {}
      f._spellNotKnownIDs = {}
      if f._displayBox then f._displayBox:SetText("") end
      if f._knownSpellBox then f._knownSpellBox:SetText("0") end
      if f._notKnownSpellBox then f._notKnownSpellBox:SetText("0") end
      f._auraName = auraName
      return
    end

    local lines = {}
    if type(specs) == "table" and #specs > 0 then
      for _, spec in ipairs(specs) do
        if type(spec) == "table" and tonumber(spec.questID) then
          local qid = tonumber(spec.questID)
          local titleTxt = qid and GetQuestTitle(qid)
          local base = tostring(qid or "")
          if titleTxt and titleTxt ~= "" then
            base = base .. "  -  " .. tostring(titleTxt)
          end
          if type(spec.prereq) == "table" and #spec.prereq > 0 then
            local pp = {}
            for _, q in ipairs(spec.prereq) do pp[#pp + 1] = tostring(q) end
            base = base .. " | prereq: " .. table.concat(pp, ",")
          end
          if type(spec.label) == "string" and spec.label ~= "" then
            base = base .. " | text: " .. tostring(spec.label)
          end
          lines[#lines + 1] = base
        end
      end
    else
      for _, qid in ipairs(questIDs) do
        local titleTxt = GetQuestTitle(qid)
        if titleTxt and titleTxt ~= "" then
          lines[#lines + 1] = tostring(qid) .. "  -  " .. tostring(titleTxt)
        else
          lines[#lines + 1] = tostring(qid)
        end
      end
    end
    resultsBox:SetText(table.concat(lines, "\n"))
    totalCount = tonumber(totalCount) or #questIDs
    primaryCount = tonumber(primaryCount) or 0
    if type(specs) == "table" and #specs > 0 then
      local withText = 0
      for _, sp in ipairs(specs) do
        if type(sp) == "table" and type(sp.label) == "string" and sp.label ~= "" then
          withText = withText + 1
        end
      end
      if withText > 0 then
        status:SetText(string.format("Detected %d quest rule(s) from triggers (%d with text).", #specs, withText))
      else
        status:SetText(string.format("Detected %d quest rule(s) from triggers.", #specs))
      end
    elseif primaryCount > 0 and totalCount ~= primaryCount then
      status:SetText(string.format("Found %d questIDs (%d primary).", totalCount, primaryCount))
    else
      status:SetText(string.format("Found %d questIDs.", totalCount))
    end
    f._auraName = auraName
  end

  scanBtn:SetScript("OnClick", function()
    local WA = _G and _G["WeakAuras"]
    local WASaved = _G and _G["WeakAurasSaved"]
    if not (WA or WASaved) then
      Print("WeakAuras not found.")
      RenderResults({}, "")
      return
    end

    local auraID = tostring(auraBox:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if auraID == "" then
      Print("Enter a WeakAuras aura ID (its name in the WA list).")
      RenderResults({}, "")
      return
    end

    local data, resolvedID = GetWeakAuraDataByIdOrUid(auraID)
    if type(data) ~= "table" then
      Print("Aura not found: " .. auraID)
      RenderResults({}, auraID)
      return
    end

    local include = includeChildren:GetChecked() and true or false
    local allIDs, primaryIDs = ExtractQuestIDsFromWeakAura(data, include)
    f._questIDsAll = allIDs or {}
    f._questIDsPrimary = primaryIDs or {}

    local ruleSpecs = ExtractQuestRuleSpecsFromWeakAura(data, include)
    f._questRuleSpecs = (type(ruleSpecs) == "table") and ruleSpecs or {}

    -- If every detected trigger agrees on faction, remember it as an aura-level hint.
    do
      local fac = nil
      local mixed = false
      for _, spec in ipairs(f._questRuleSpecs) do
        if type(spec) == "table" and (spec.faction == "Alliance" or spec.faction == "Horde") then
          if not fac then
            fac = spec.faction
          elseif fac ~= spec.faction then
            mixed = true
            break
          end
        end
      end
      f._factionDetected = (not mixed) and fac or nil
    end

    local knownIDs, notKnownIDs = ExtractSpellIDsFromWeakAura(data, include)
    f._spellKnownIDs = knownIDs or {}
    f._spellNotKnownIDs = notKnownIDs or {}
    if f._knownSpellBox then
      f._knownSpellBox:SetText(tostring(tonumber((knownIDs and knownIDs[1]) or 0) or 0))
    end
    if f._notKnownSpellBox then
      f._notKnownSpellBox:SetText(tostring(tonumber((notKnownIDs and notKnownIDs[1]) or 0) or 0))
    end

    local displayTexts = ExtractDisplayTextsFromWeakAura(data, include)
    f._displayTexts = displayTexts or {}
    if f._displayBox then
      if type(displayTexts) == "table" and #displayTexts > 0 then
        f._displayBox:SetText(table.concat(displayTexts, "\n"))
      else
        f._displayBox:SetText("")
      end
    end

    local showList = f._questIDsAll
    if primaryOnly:GetChecked() and type(f._questIDsPrimary) == "table" and #f._questIDsPrimary > 0 then
      showList = f._questIDsPrimary
    end

    do
      local ids = showList
      local spec = (type(f._questRuleSpecs) == "table" and #f._questRuleSpecs == 1) and f._questRuleSpecs[1] or nil
      if type(spec) == "table" and tonumber(spec.questID) then
        if f._mainQuestBox then
          f._mainQuestBox:SetText(tostring(tonumber(spec.questID) or 0))
        end
        if f._prereqImportBox then
          local prereq = {}
          if type(spec.prereq) == "table" and #spec.prereq > 0 then
            for _, q in ipairs(spec.prereq) do
              prereq[#prereq + 1] = tostring(q)
            end
          end
          f._prereqImportBox:SetText(table.concat(prereq, ","))
        end
      else
        local mainID = (type(ids) == "table" and ids[1]) or 0
        if f._mainQuestBox then
          f._mainQuestBox:SetText(tostring(tonumber(mainID) or 0))
        end
        if f._prereqImportBox then
          local prereq = {}
          if type(ids) == "table" and #ids > 1 then
            for i = 2, #ids do
              prereq[#prereq + 1] = tostring(ids[i])
            end
          end
          f._prereqImportBox:SetText(table.concat(prereq, ","))
        end
      end
    end

    RenderResults(showList, resolvedID or auraID, #(f._questIDsAll or {}), #(f._questIDsPrimary or {}))
  end)

  importBtn:SetScript("OnClick", function()
    local exportOnlyMode = f._exportOnly and f._exportOnly.GetChecked and f._exportOnly:GetChecked() and true or false

    local allIDs = f._questIDsAll
    local primaryIDs = f._questIDsPrimary
    if not exportOnlyMode then
      if type(allIDs) ~= "table" or #allIDs == 0 then
        Print("Nothing to import (Scan first).")
        return
      end
    end

    local setIDs = allIDs
    if primaryOnly:GetChecked() and type(primaryIDs) == "table" and #primaryIDs > 0 then
      setIDs = primaryIDs
    end

    local auraIDInput = tostring(auraBox and auraBox.GetText and auraBox:GetText() or "")
    auraIDInput = auraIDInput:gsub("^%s+", ""):gsub("%s+$", "")

    local targetFrame = tostring(frameBox:GetText() or ""):gsub("%s+", "")
    if targetFrame == "" then targetFrame = "list1" end

    local prefixText = tostring(prefixBox:GetText() or "")
    prefixText = prefixText:gsub("^%s+", "")
    local prefix = (prefixText ~= "") and prefixText or nil

    local displayText = ""
    if f._displayBox then
      displayText = tostring(f._displayBox:GetText() or "")
      displayText = displayText:gsub("^%s+", ""):gsub("%s+$", "")
    end

    local importSpell = f._importSpellRule and f._importSpellRule:GetChecked() and true or false
    local knownSpellID = f._knownSpellBox and tonumber(f._knownSpellBox:GetText() or "") or nil
    if knownSpellID and knownSpellID <= 0 then knownSpellID = nil end
    local notKnownSpellID = f._notKnownSpellBox and tonumber(f._notKnownSpellBox:GetText() or "") or nil
    if notKnownSpellID and notKnownSpellID <= 0 then notKnownSpellID = nil end

    do
      local snapshot = {
        createdAt = (time and time()) or nil,
        auraInput = auraIDInput,
        auraName = f._auraName,
        includeChildren = includeChildren and includeChildren.GetChecked and includeChildren:GetChecked() and true or false,
        primaryOnly = primaryOnly and primaryOnly.GetChecked and primaryOnly:GetChecked() and true or false,
        targetFrameID = targetFrame,
        prefix = prefix,
        questIDsAll = CopyArray(allIDs),
        questIDsPrimary = CopyArray(primaryIDs),
        spellKnownDetected = CopyArray(f._spellKnownIDs),
        spellNotKnownDetected = CopyArray(f._spellNotKnownIDs),
        spellKnown = knownSpellID,
        notSpellKnown = notKnownSpellID,
        displayText = (displayText ~= "") and displayText or nil,
      }
      SaveWAExportSnapshot(snapshot)
      local exportCount = 0
      local db = GetWAExportDB()
      if db and type(db.exports) == "table" then exportCount = #db.exports end
      if exportOnlyMode then
        Print(string.format("Exported snapshot #%d (no rules created).", exportCount))
      else
        Print(string.format("Saved export snapshot #%d.", exportCount))
      end
    end

    if exportOnlyMode then
      return
    end

    local function NormalizeInfoText(s)
      if s == nil then return nil end
      s = tostring(s or "")
      s = s:gsub("\r\n?", "\n")
      s = s:gsub("^%s+", ""):gsub("%s+$", "")
      return (s ~= "") and s or nil
    end

    local function NormalizeInfoKey(s)
      s = NormalizeInfoText(s)
      if not s then return "" end
      -- Make duplicate matching resilient to cosmetic whitespace differences.
      s = s:gsub("[ \t]+", " ")
      s = s:gsub("\n+", "\n")
      return s
    end

    local existingQuest = {}
    local existingSpell = {}
    for i, r in ipairs(GetCustomRules()) do
      if type(r) == "table" and tonumber(r.questID) and tostring(r.frameID or "") ~= "" then
        local pk = PrereqListKey(r.prereq)
        local fac = (r.faction == "Alliance" or r.faction == "Horde") and r.faction or ""
        local infoKey = NormalizeInfoKey(r.questInfo)
        local k = tostring(r.questID) .. "|" .. tostring(r.frameID) .. "|" .. pk .. "|" .. fac .. "|" .. infoKey
        existingQuest[k] = i
      end
      if type(r) == "table" and tostring(r.frameID or "") ~= "" and (r.spellKnown or r.notSpellKnown) then
        local k3 = tostring(r.frameID) .. "|" .. tostring(tonumber(r.spellKnown) or 0) .. "|" .. tostring(tonumber(r.notSpellKnown) or 0)
        existingSpell[k3] = true
      end
    end

    local rules = GetCustomRules()

    if importSpell and (knownSpellID or notKnownSpellID) then
      local label = nil
      if displayText ~= "" then
        label = displayText
      elseif type(f._displayTexts) == "table" and f._displayTexts[1] then
        label = tostring(f._displayTexts[1])
      elseif type(f._auraName) == "string" and f._auraName ~= "" then
        label = "[WA] " .. f._auraName
      end

      local k3 = tostring(targetFrame) .. "|" .. tostring(tonumber(knownSpellID) or 0) .. "|" .. tostring(tonumber(notKnownSpellID) or 0)
      if not existingSpell[k3] then
        local key = string.format("custom:spell:%s:%d", tostring(targetFrame), (#rules + 1))
        local r = {
          key = key,
          frameID = targetFrame,
          label = label,
          faction = (f._factionDetected == "Alliance" or f._factionDetected == "Horde") and f._factionDetected or nil,
          hideWhenCompleted = false,
        }
        if knownSpellID then r.spellKnown = knownSpellID end
        if notKnownSpellID then r.notSpellKnown = notKnownSpellID end
        rules[#rules + 1] = r
        existingSpell[k3] = true
      end
    end

    local created = 0
    local skipped = 0
    local updated = 0
    local createdWithInfo = 0

    local function GetWAImportBaseLabel()
      local base = tostring(f._auraName or "")
      base = base:gsub("^%s+", ""):gsub("%s+$", "")
      if base == "" then
        base = tostring(auraIDInput or "")
        base = base:gsub("^%s+", ""):gsub("%s+$", "")
      end
      if base == "" then
        return nil
      end
      if prefix and prefix ~= "" then
        return tostring(prefix) .. tostring(base)
      end
      return base
    end

    local specs = (type(f._questRuleSpecs) == "table") and f._questRuleSpecs or nil
    if specs and #specs > 0 then
      local baseLabel = GetWAImportBaseLabel()
      local displayTextNorm = NormalizeInfoText(displayText)
      if not displayTextNorm and type(f._displayTexts) == "table" and f._displayTexts[1] then
        displayTextNorm = NormalizeInfoText(tostring(f._displayTexts[1]))
      end

      for _, spec in ipairs(specs) do
        local mainQuestID = (type(spec) == "table") and tonumber(spec.questID) or nil
        if mainQuestID and mainQuestID > 0 then
          local prereq = (type(spec.prereq) == "table" and #spec.prereq > 0) and CopyArray(spec.prereq) or nil
          local ruleFaction = (type(spec) == "table" and (spec.faction == "Alliance" or spec.faction == "Horde")) and spec.faction or nil

          -- If trigger parsing couldn't associate prereqs but this is a single-trigger import,
          -- fall back to the overall detected questIDs (minus the main).
          if (not prereq or #prereq == 0) and #specs == 1 and type(allIDs) == "table" and #allIDs > 0 then
            local fb = {}
            for _, q in ipairs(allIDs) do
              local n = tonumber(q)
              if n and n > 0 and n ~= mainQuestID then
                fb[#fb + 1] = n
              end
            end
            prereq = (#fb > 0) and fb or nil
          end

          local questLabel = nil
          if baseLabel then
            if #specs > 1 then
              questLabel = string.format("%s %02d", tostring(baseLabel), tonumber(created + skipped + 1) or 1)
            else
              questLabel = tostring(baseLabel)
            end
          end

          local triggerText = (type(spec.label) == "string" and spec.label ~= "") and tostring(spec.label) or nil
          triggerText = NormalizeInfoText(triggerText)

          local questInfo = nil
          if displayTextNorm and triggerText then
            questInfo = displayTextNorm .. "\n" .. triggerText
          else
            questInfo = displayTextNorm or triggerText
          end

          local dkBase = tostring(mainQuestID) .. "|" .. tostring(targetFrame) .. "|" .. PrereqListKey(prereq) .. "|" .. (ruleFaction or "") .. "|"
          local infoKey = NormalizeInfoKey(questInfo)
          local dk = dkBase .. infoKey
          local existingIndex = existingQuest[dk]
          -- If the only difference is that the existing rule has no questInfo yet, treat it as the same rule and fill it.
          if not existingIndex and infoKey ~= "" then
            existingIndex = existingQuest[dkBase]
          end
          if existingIndex then
            -- Update existing rule's questInfo if we found something new.
            local existingRule = rules[existingIndex]
            if type(existingRule) == "table" and questInfo and questInfo ~= "" then
              local cur = tostring(existingRule.questInfo or "")
              cur = cur:gsub("^%s+", ""):gsub("%s+$", "")
              if cur == "" then
                existingRule.questInfo = questInfo
                updated = updated + 1
                existingQuest[dk] = existingIndex
              end
            end
            if type(existingRule) == "table" and not existingRule.faction and ruleFaction then
              existingRule.faction = ruleFaction
              updated = updated + 1
            end
            skipped = skipped + 1
          else
            local key = string.format("custom:q:%d:%s:%d", tonumber(mainQuestID) or 0, tostring(targetFrame), (#rules + 1))
            rules[#rules + 1] = {
              key = key,
              questID = mainQuestID,
              frameID = targetFrame,
              label = questLabel,
              questInfo = questInfo,
              faction = ruleFaction,
              prereq = prereq,
              hideWhenCompleted = true,
            }
            existingQuest[dk] = #rules
            if questInfo and tostring(questInfo or "") ~= "" then
              createdWithInfo = createdWithInfo + 1
            end
            created = created + 1
          end
        end
      end
    else
      -- Fallback: single rule from the manual boxes.
      local mainQuestID = f._mainQuestBox and tonumber(f._mainQuestBox:GetText() or "") or nil
      if not (mainQuestID and mainQuestID > 0) then
        if type(setIDs) ~= "table" or #setIDs == 0 then
          Print("Nothing to import (no questIDs detected).")
          return
        end
        mainQuestID = tonumber(setIDs[1])
      end
      if not (mainQuestID and mainQuestID > 0) then
        Print("Nothing to import (invalid main questID).")
        return
      end

      local prereq = nil
      if f._prereqImportBox then
        prereq = ParseQuestIDList(f._prereqImportBox:GetText() or "")
      end

      if type(prereq) == "table" then
        local filtered = {}
        for _, q in ipairs(prereq) do
          local n = tonumber(q)
          if n and n > 0 and n ~= mainQuestID then
            filtered[#filtered + 1] = n
          end
        end
        prereq = (#filtered > 0) and filtered or nil
      end

      local questLabel = nil
      local baseLabel = GetWAImportBaseLabel()
      if baseLabel then
        questLabel = tostring(baseLabel)
      end

      local questInfo = NormalizeInfoText(displayText)
      local dkBase = tostring(mainQuestID) .. "|" .. tostring(targetFrame) .. "|" .. PrereqListKey(prereq) .. "|" .. "" .. "|"
      local infoKey = NormalizeInfoKey(questInfo)
      local dk = dkBase .. infoKey
      if existingQuest[dk] or (infoKey ~= "" and existingQuest[dkBase]) then
        skipped = skipped + 1
      else
        local key = string.format("custom:q:%d:%s:%d", tonumber(mainQuestID) or 0, tostring(targetFrame), (#rules + 1))
        rules[#rules + 1] = {
          key = key,
          questID = mainQuestID,
          frameID = targetFrame,
          label = questLabel,
          questInfo = questInfo,
          prereq = prereq,
          hideWhenCompleted = true,
        }
        existingQuest[dk] = #rules
        created = 1
      end
    end

    CreateAllFrames()
    RefreshAll()
    RefreshRulesList()
    if updated > 0 then
      Print(string.format("Created %d quest rule(s) (%d with Quest Info), updated %d existing, (%d skipped as duplicates).", tonumber(created) or 0, tonumber(createdWithInfo) or 0, tonumber(updated) or 0, tonumber(skipped) or 0))
    else
      Print(string.format("Created %d quest rule(s) (%d with Quest Info), (%d skipped as duplicates).", tonumber(created) or 0, tonumber(createdWithInfo) or 0, tonumber(skipped) or 0))
    end
  end)

  weakAuraImportFrame = f
  return f
end

