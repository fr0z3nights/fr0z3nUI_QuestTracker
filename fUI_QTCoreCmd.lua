local addonName, ns = ...

local deps = (type(ns) == "table" and ns._FQTSlash and ns._FQTSlash.deps) or nil
if type(deps) ~= "table" then
  return
end

local Print = deps.Print or (type(ns) == "table" and ns.Print) or nil
local function Say(msg)
  if type(Print) == "function" then
    Print(msg)
  end
end

local function NormalizeSV()
  if type(deps.NormalizeSV) == "function" then
    return deps.NormalizeSV()
  end
end

local function RefreshAll()
  if type(deps.RefreshAll) == "function" then
    return deps.RefreshAll()
  end
  if type(ns) == "table" and type(ns.RefreshAll) == "function" then
    return ns.RefreshAll()
  end
end

local function GetFramesEnabled()
  if type(deps.GetFramesEnabled) == "function" then
    return deps.GetFramesEnabled() and true or false
  end
  return false
end

local function SetFramesEnabled(v)
  if type(deps.SetFramesEnabled) == "function" then
    deps.SetFramesEnabled(v == true)
    return
  end
end

local function GetEditMode()
  if type(deps.GetEditMode) == "function" then
    return deps.GetEditMode() and true or false
  end
  return false
end

local function HasSkillLineID(id)
  id = tonumber(id)
  if not id or id <= 0 then return false end
  if type(ns) == "table" and type(ns.Profs) == "table" and type(ns.Profs.HasSkillLineID) == "function" then
    return ns.Profs.HasSkillLineID(id) and true or false
  end
  if type(deps.HasProfessionSkillLineID) == "function" then
    return deps.HasProfessionSkillLineID(id) and true or false
  end
  return false
end

local function PlayerIsOnQuestID(questID)
  questID = tonumber(questID)
  if not questID or questID <= 0 then return false end

  if C_QuestLog and type(C_QuestLog.IsOnQuest) == "function" then
    local ok, on = pcall(C_QuestLog.IsOnQuest, questID)
    if ok then return on and true or false end
  end

  if C_QuestLog and type(C_QuestLog.GetLogIndexForQuestID) == "function" then
    local ok, idx = pcall(C_QuestLog.GetLogIndexForQuestID, questID)
    if ok and type(idx) == "number" and idx > 0 then
      return true
    end
  end

  if type(GetQuestLogIndexByID) == "function" then
    local ok, idx = pcall(GetQuestLogIndexByID, questID)
    if ok and type(idx) == "number" and idx > 0 then
      return true
    end
  end

  return false
end

local function QuestIsCompleted(questID)
  questID = tonumber(questID)
  if not questID or questID <= 0 then return false end

  if C_QuestLog and type(C_QuestLog.IsQuestFlaggedCompleted) == "function" then
    local ok, done = pcall(C_QuestLog.IsQuestFlaggedCompleted, questID)
    if ok then return done and true or false end
  end

  if type(IsQuestFlaggedCompleted) == "function" then
    local ok, done = pcall(IsQuestFlaggedCompleted, questID)
    if ok then return done and true or false end
  end

  return false
end

local function QuestReadyForTurnIn(questID)
  questID = tonumber(questID)
  if not questID or questID <= 0 then return false end

  if C_QuestLog and type(C_QuestLog.ReadyForTurnIn) == "function" then
    local ok, ready = pcall(C_QuestLog.ReadyForTurnIn, questID)
    if ok then return ready and true or false end
  end

  return false
end

local function PrintProfStatusFallback()
  NormalizeSV()
  local c = _G.fr0z3nUI_QuestTracker_Char and _G.fr0z3nUI_QuestTracker_Char.cache or nil
  c = (type(c) == "table") and c or {}

  local function CountKeys(t)
    local n = 0
    if type(t) == "table" then
      for _, v in pairs(t) do
        if v == true then n = n + 1 end
      end
    end
    return n
  end

  local keysN = CountKeys(c.knownProfessionKeys)
  local linesN = CountKeys(c.knownProfessionSkillLines)
  Say(string.format(
    "profsCache: keys=%d at=%s; lines=%d at=%s",
    tonumber(keysN) or 0,
    tostring(c.knownProfessionKeysAt or 0),
    tonumber(linesN) or 0,
    tostring(c.knownProfessionSkillLinesAt or 0)
  ))

  if type(ns) == "table" and type(ns.Profs) == "table" and type(ns.Profs.HasSkillLineID) == "function" then
    local has185 = ns.Profs.HasSkillLineID(185) and true or false
    local has356 = ns.Profs.HasSkillLineID(356) and true or false
    local has2908 = ns.Profs.HasSkillLineID(2908) and true or false
    local has2911 = ns.Profs.HasSkillLineID(2911) and true or false
    Say(string.format(
      "profsHas: Cooking(185)=%s, Fishing(356)=%s, 2908=%s, 2911=%s",
      tostring(has185), tostring(has356), tostring(has2908), tostring(has2911)
    ))
  end
end

local function DispatchDebugCommand(cmd, rest)
  cmd = tostring(cmd or ""):lower()
  rest = tostring(rest or "")

  local function HasRememberedDailyAura(key)
    if type(ns) == "table" and type(ns.Calendar) == "table" and type(ns.Calendar.HasRememberedDailyAura) == "function" then
      return ns.Calendar.HasRememberedDailyAura(key) and true or false
    end
    if type(deps.HasRememberedDailyAura) == "function" then
      return deps.HasRememberedDailyAura(key) and true or false
    end
    return false
  end

  local function GetUISetting(key, default)
    if type(ns) == "table" and type(ns.GetUISetting) == "function" then
      return ns.GetUISetting(key, default)
    end
    if type(deps.GetUISetting) == "function" then
      return deps.GetUISetting(key, default)
    end
    return default
  end

  local function SetUISetting(key, value)
    if type(ns) == "table" and type(ns.SetUISetting) == "function" then
      return ns.SetUISetting(key, value)
    end
    if type(deps.SetUISetting) == "function" then
      return deps.SetUISetting(key, value)
    end
  end

  local function EnsureFramesCreated()
    if type(deps.CreateAllFrames) == "function" then
      return deps.CreateAllFrames()
    end
    if type(ns) == "table" and type(ns.CreateAllFrames) == "function" then
      return ns.CreateAllFrames()
    end
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

  local function GetFrameScrollOffset(frameID)
    if type(deps.GetFrameScrollOffset) == "function" then
      return tonumber(deps.GetFrameScrollOffset(frameID) or 0) or 0
    end
    return 0
  end

  if cmd == "twdebug" then
    Say("Timewalking debug:")
    if ns and ns.Calendar and ns.Calendar.EnsureCalendarOpened then
      ns.Calendar.EnsureCalendarOpened()
    elseif C_Calendar and C_Calendar.OpenCalendar then
      pcall(C_Calendar.OpenCalendar)
    end

    if not (ns and ns.GetCalendarDebugEvents) then
      Say("Calendar debug unavailable (calendar module missing).")
      return true
    end

    local events, meta = ns.GetCalendarDebugEvents(0, 0)
    if type(meta) == "table" and meta.ok == false then
      Say("Calendar debug unavailable: " .. tostring(meta.reason or "unknown"))
      return true
    end

    local isWednesday = false
    if type(date) == "function" then
      isWednesday = (tonumber(date("%w")) == 3)
    end
    Say(string.format(
      "Local weekday=%s (0=Sun..6=Sat); isWednesday=%s",
      tostring(type(date) == "function" and date("%w") or "?"),
      tostring(isWednesday and true or false)
    ))

    do
      NormalizeSV()
      local anyTW = (ns and ns.Calendar and ns.Calendar.IsAnyTimewalkingEventActive) or nil
      local eventActive = (type(anyTW) == "function" and anyTW()) and true or false

      local rememberedAny = false
      local rememberedFn = (ns and ns.Calendar and ns.Calendar.HasRememberedWeeklyTimewalkingKind) or nil
      if type(rememberedFn) == "function" then
        rememberedAny = rememberedFn() and true or false
      end

      local kind = _G.fr0z3nUI_QuestTracker_Acc
        and _G.fr0z3nUI_QuestTracker_Acc.cache
        and _G.fr0z3nUI_QuestTracker_Acc.cache.twWeekly
        and _G.fr0z3nUI_QuestTracker_Acc.cache.twWeekly.kind
      local exp = _G.fr0z3nUI_QuestTracker_Acc
        and _G.fr0z3nUI_QuestTracker_Acc.cache
        and _G.fr0z3nUI_QuestTracker_Acc.cache.twWeekly
        and _G.fr0z3nUI_QuestTracker_Acc.cache.twWeekly.exp

      Say(string.format(
        "twWeekly: rememberedAny=%s kind=%s exp=%s; eventActiveNow=%s",
        tostring(rememberedAny and true or false),
        tostring(kind or ""),
        tostring(exp or 0),
        tostring(eventActive and true or false)
      ))
    end

    local function EndsSuffix(titleLower)
      if type(titleLower) ~= "string" then return false end
      return (string.match(titleLower, "[%s]ends?%s*$") ~= nil)
    end

    local function HolidayNameLowerFromText(holidayText)
      if type(holidayText) ~= "string" or holidayText == "" then return "" end
      local firstLine = holidayText:match("^([^\n]+)")
      return (firstLine and firstLine ~= "") and string.lower(firstLine) or string.lower(holidayText)
    end

    local function TWHitWhere(titleLower, holidayLower)
      if type(titleLower) ~= "string" then titleLower = "" end
      if type(holidayLower) ~= "string" then holidayLower = "" end
      if titleLower:find("timewalking", 1, true) or titleLower:find("turbulent timeways", 1, true) then
        return "title"
      end
      if holidayLower:find("timewalking", 1, true) or holidayLower:find("turbulent timeways", 1, true) then
        return "holiday"
      end
      return nil
    end

    local any = false
    if type(events) == "table" then
      for _, ev in ipairs(events) do
        local title = tostring(ev.title or "")
        local holidayText = tostring(ev.holidayText or "")
        local titleLower = title:lower()
        local holidayLower = holidayText:lower()

        local holidayNameLower = HolidayNameLowerFromText(holidayText)
        local suppressed = isWednesday and (EndsSuffix(titleLower) or EndsSuffix(holidayNameLower))
        local ended = (type(ev) == "table" and ev.ended == true) and true or false
        local activeNow = (type(ev) == "table" and ev.activeNow ~= nil) and (ev.activeNow and true or false) or nil
        local isActive = (activeNow == nil and not ended) or (activeNow == true)
        local where = (suppressed or (not isActive)) and nil or TWHitWhere(titleLower, holidayLower)

        if where then
          any = true
          Say(string.format(
            "Day %s idx %s: %s | TW_MATCH=%s%s",
            tostring(ev.day or "?"),
            tostring(ev.index or "?"),
            title ~= "" and title or "(no title)",
            where,
            suppressed and " | SUPPRESSED(Ends/End titleOrHolidayName)" or ""
          ))
        end

        if (suppressed or ended or activeNow == false) and (titleLower:find("timewalking", 1, true) or holidayLower:find("timewalking", 1, true)) then
          Say(string.format(
            "Day %s idx %s: %s | SKIPPED(%s) (would-have-matched timewalking)",
            tostring(ev.day or "?"),
            tostring(ev.index or "?"),
            title ~= "" and title or "(no title)",
            suppressed and "Ends/End" or (ended and "ENDED" or "activeNow=false")
          ))
        end
      end
    end

    if not any then
      Say("No timewalking found in today's calendar day-events.")
    end
    return true
  end

  if cmd == "evdebug" then
    Say("Event debug:")
    if ns and ns.Calendar and ns.Calendar.EnsureCalendarOpened then
      ns.Calendar.EnsureCalendarOpened()
    elseif C_Calendar and C_Calendar.OpenCalendar then
      pcall(C_Calendar.OpenCalendar)
    end

    local events, meta
    if ns and ns.GetCalendarDebugEvents then
      events, meta = ns.GetCalendarDebugEvents(0, 0)
    else
      events, meta = nil, { ok = false, reason = "calendar module missing" }
    end
    if type(meta) == "table" and meta.ok == false then
      Say("Calendar debug unavailable: " .. tostring(meta.reason or "unknown"))
    else
      local isWednesday = false
      if type(date) == "function" then
        isWednesday = (tonumber(date("%w")) == 3)
      end
      Say(string.format(
        "Local weekday=%s (0=Sun..6=Sat); isWednesday=%s",
        tostring(type(date) == "function" and date("%w") or "?"),
        tostring(isWednesday and true or false)
      ))

      local function EndsSuffix(titleLower)
        if type(titleLower) ~= "string" then return false end
        return (string.match(titleLower, "[%s]ends?%s*$") ~= nil)
      end

      local function HolidayNameLowerFromText(holidayText)
        if type(holidayText) ~= "string" or holidayText == "" then return "" end
        local firstLine = holidayText:match("^([^\n]+)")
        return (firstLine and firstLine ~= "") and string.lower(firstLine) or string.lower(holidayText)
      end

      local function TWHitWhere(titleLower, holidayLower)
        if type(titleLower) ~= "string" then titleLower = "" end
        if type(holidayLower) ~= "string" then holidayLower = "" end
        if titleLower:find("timewalking", 1, true) or titleLower:find("turbulent timeways", 1, true) then
          return "title"
        end
        if holidayLower:find("timewalking", 1, true) or holidayLower:find("turbulent timeways", 1, true) then
          return "holiday"
        end
        return nil
      end

      if type(events) ~= "table" or events[1] == nil then
        Say("Today: no calendar day-events returned.")
      else
        for _, ev in ipairs(events) do
          local title = tostring(ev.title or "")
          local ht = tostring(ev.holidayText or "")

          local titleLower = title:lower()
          local htLower = ht:lower()
          local holidayNameLower = HolidayNameLowerFromText(ht)
          local suppressed = isWednesday and (EndsSuffix(titleLower) or EndsSuffix(holidayNameLower))
          local ended = (type(ev) == "table" and ev.ended == true) and true or false
          local activeNow = (type(ev) == "table" and ev.activeNow ~= nil) and (ev.activeNow and true or false) or nil
          local isActive = (activeNow == nil and not ended) or (activeNow == true)
          local twWhere = (suppressed or (not isActive)) and nil or TWHitWhere(titleLower, htLower)
          local startEpoch = (type(ev) == "table") and ev.startEpoch or nil
          local endEpoch = (type(ev) == "table") and ev.endEpoch or nil
          local tInfo = ""
          if startEpoch ~= nil then tInfo = tInfo .. " | startEpoch=" .. tostring(startEpoch) end
          if endEpoch ~= nil then tInfo = tInfo .. " | endEpoch=" .. tostring(endEpoch) end
          if activeNow ~= nil then tInfo = tInfo .. " | activeNow=" .. tostring(activeNow and true or false) end
          if ended then tInfo = tInfo .. " | ENDED" end

          Say(string.format(
            "Day %s idx %s: %s%s%s%s%s",
            tostring(ev.day or "?"),
            tostring(ev.index or "?"),
            title ~= "" and title or "(no title)",
            (ht ~= "" and " | holidayText=Y" or " | holidayText=N"),
            (twWhere and (" | TW_MATCH=" .. tostring(twWhere)) or ""),
            (suppressed and " | SUPPRESSED(Ends/End titleOrHolidayName)" or ""),
            tInfo
          ))
        end
      end
    end

    do
      local found, unknown = false, true
      if ns and ns.Calendar and ns.Calendar.IsCalendarEventActiveByKeywords then
        found, unknown = ns.Calendar.IsCalendarEventActiveByKeywords({ "Darkmoon Faire" }, true)
      end
      Say("DMF keyword match today: " .. tostring(found and true or false) .. "; calendarUnknown=" .. tostring(unknown and true or false))

      NormalizeSV()
      local disabled = _G.fr0z3nUI_QuestTracker_Char
        and _G.fr0z3nUI_QuestTracker_Char.settings
        and _G.fr0z3nUI_QuestTracker_Char.settings.disabledRules
        and _G.fr0z3nUI_QuestTracker_Char.settings.disabledRules["event:darkmoon-faire"]
      Say("DMF title rule disabledRules['event:darkmoon-faire']=" .. tostring(disabled and true or false))

      local ck = (ns and ns.Calendar and ns.Calendar.CalendarKeywordCacheKey) and ns.Calendar.CalendarKeywordCacheKey({ "Darkmoon Faire" }) or nil
      if ck and ck ~= "" then
        local rememberedKey = "event:calendar:" .. ck
        Say("DMF remembered daily aura state: " .. tostring(HasRememberedDailyAura(rememberedKey) and true or false))
      end
    end

    return true
  end

  if cmd == "framedebug" then
    NormalizeSV()
    local frameID, sub = tostring(rest or ""):match("^(%S*)%s*(.-)$")
    frameID = tostring(frameID or ""):gsub("^%s+", ""):gsub("%s+$", "")
    sub = tostring(sub or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
    if frameID == "" then frameID = "list2" end

    Say("Frame debug: " .. frameID)
    Say("framesEnabled=" .. tostring(GetFramesEnabled() and true or false) .. "; editMode=" .. tostring(GetEditMode() and true or false))

    local def
    local defs = GetEffectiveFrames()
    if type(defs) == "table" then
      for _, d in ipairs(defs) do
        if tostring(d and d.id or "") == frameID then
          def = d
          break
        end
      end
    end

    if not def then
      Say("No effective frame def for id='" .. frameID .. "'.")
    else
      Say(string.format(
        "type=%s hideFrame=%s hideWhenEmpty=%s parentFrame=%s visLink=%s",
        tostring(def.type or "list"),
        tostring(def.hideFrame == true),
        tostring(def.hideWhenEmpty ~= false),
        tostring(def.parentFrame or ""),
        tostring(def.visLink or "")
      ))
    end

    local f = GetFrameByID(frameID)
    if not f then
      Say("Frame object not created (framesByID['" .. frameID .. "']=nil).")
      EnsureFramesCreated()
      f = GetFrameByID(frameID)
      Say("CreateAllFrames() attempted; frame now " .. (f and "exists" or "missing") .. ".")
    end

    if f then
      local shown = (f.IsShown and f:IsShown()) and true or false
      Say("IsShown=" .. tostring(shown))

      local scrollOffset = GetFrameScrollOffset(frameID)
      Say("scrollOffset=" .. tostring(scrollOffset))

      Say(
        "wheelEnabled=" .. tostring((f._wheelEnabled == true) and true or false)
        .. "; canScroll=" .. tostring((f._canScroll == true) and true or false)
        .. "; maxScrollOffset=" .. tostring(f._maxScrollOffset)
      )

      if sub == "reset" or sub == "resetscroll" or sub == "top" then
        if type(SetFrameScrollOffset) == "function" then
          SetFrameScrollOffset(frameID, 0)
        end
        RefreshAll()
        Say("scrollOffset reset to 0")
      end

      do
        local w = (f.GetWidth and f:GetWidth()) or nil
        local h = (f.GetHeight and f:GetHeight()) or nil
        Say("size=" .. tostring(w or "?") .. "x" .. tostring(h or "?"))
        if f.GetPoint then
          local p, rel, rp, x, y = f:GetPoint(1)
          Say("point=" .. tostring(p or "") .. " relPoint=" .. tostring(rp or "") .. " x=" .. tostring(x or "") .. " y=" .. tostring(y or ""))
        end
      end

      local ll = f._fqtListLayout
      if type(ll) == "table" then
        Say(string.format(
          "layout: count=%s visibleRows=%s offset=%s maxOffset=%s range=%s-%s wrapText=%s maxHeight=%s rowH=%s",
          tostring(ll.count),
          tostring(ll.visibleRows),
          tostring(ll.offset),
          tostring(ll.maxOffset),
          tostring(ll.first),
          tostring(ll.last),
          tostring(ll.wrapText),
          tostring(ll.maxHeight),
          tostring(ll.rowH)
        ))
      else
        Say("layout: (no renderer diagnostics yet) -- try /reload then /fqt framedebug " .. frameID)
      end

      local entries = f._lastEntries or {}
      local allEntries = f._lastAllEntries or nil
      Say("entries=" .. tostring(type(entries) == "table" and #entries or 0) .. "; allEntries=" .. tostring(type(allEntries) == "table" and #allEntries or "(nil)"))

      local maxDump = 12
      for i = 1, math.min(maxDump, (type(entries) == "table" and #entries or 0)) do
        local e = entries[i]
        local r = e and e.rule
        local k
        if type(deps.RuleKey) == "function" and r then
          k = deps.RuleKey(r)
        else
          k = (type(r) == "table" and r.key) or nil
        end
        local title = (e and (e.rawTitle or e.title or e.editText)) or ""
        if type(title) == "string" then
          title = title:gsub("\n", " ")
          if #title > 120 then title = title:sub(1, 120) .. "..." end
        end
        Say(string.format("%d) %s  key=%s", i, tostring(title), tostring(k or "")))
      end

      if type(f.items) == "table" then
        local maxRows = 12
        for i = 1, maxRows do
          local fs = f.items[i]
          if fs and fs.GetText then
            local t = fs:GetText() or ""
            if type(t) == "string" then
              t = t:gsub("\n", " ")
              if #t > 120 then t = t:sub(1, 120) .. "..." end
            end
            local fsShown = (fs.IsShown and fs:IsShown()) and true or false
            Say(string.format("rowFS %d shown=%s text=%s", i, tostring(fsShown), tostring(t)))
          end
        end
      end
    end

    return true
  end

  if cmd == "ruledebug" then
    NormalizeSV()
    local key = tostring(rest or "")
    key = key:gsub("^%s+", ""):gsub("%s+$", "")
    if key == "" then
      Say("Usage: /fqt ruledebug <ruleKey>")
      return true
    end

    local rules = (type(deps.GetEffectiveRules) == "function") and deps.GetEffectiveRules() or nil
    local found
    if type(rules) == "table" then
      for _, r in ipairs(rules) do
        if type(r) == "table" then
          local rk
          if type(deps.RuleKey) == "function" then
            rk = deps.RuleKey(r)
          else
            rk = r.key
          end
          if tostring(rk or "") == key then
            found = r
            break
          end
        end
      end
    end

    if not found then
      Say("Rule not found for key='" .. key .. "'.")
      return true
    end

    if type(deps.BuildRuleStatus) ~= "function" or type(deps.BuildEvalContext) ~= "function" then
      Say("Rule debug unavailable (core status builder missing).")
      return true
    end

    local status = deps.BuildRuleStatus(found, deps.BuildEvalContext(), { forceNormalVisibility = true })
    if not status then
      Say("BuildRuleStatus: nil (gated/disabled/prereq/etc)")
      if found.professionSkillLineID ~= nil then
        Say("  professionSkillLineID=" .. tostring(found.professionSkillLineID) .. "; has=" .. tostring(HasSkillLineID(found.professionSkillLineID)))
      end
      return true
    end

    Say("Rule debug key='" .. key .. "':")
    Say("  completed=" .. tostring(status.completed and true or false) .. "; hideWhenCompleted=" .. tostring(status.hideWhenCompleted and true or false))
    Say("  title=" .. tostring((status.rawTitle or status.title) or ""))
    return true
  end

  if cmd == "cache" then
    NormalizeSV()
    local sub, rest2 = rest:match("^(%S+)%s*(.-)$")
    sub = tostring(sub or ""):lower()
    rest2 = tostring(rest2 or "")
    local itemID = tonumber((rest2:match("^(%d+)") or ""))

    if sub == "status" or sub == "show" then
      if not itemID then
        Say("Usage: /fqt cache status <itemID>")
        return true
      end
      local t = (ns and ns.GetPurchasedItemsCacheTable) and ns.GetPurchasedItemsCacheTable() or nil
      local cached = (type(t) == "table" and t[itemID] ~= nil) and true or false
      local have = (type(C_Item) == "table" and C_Item.GetItemCount) and (tonumber(C_Item.GetItemCount(itemID, false, false, false, false)) or 0) or 0
      Say(string.format("Cache status itemID=%d cached=%s have=%d", itemID, tostring(cached), tonumber(have) or 0))
      return true
    end

    if sub == "clear" or sub == "rm" or sub == "del" then
      if not itemID then
        Say("Usage: /fqt cache clear <itemID>")
        return true
      end
      local t = (ns and ns.GetPurchasedItemsCacheTable) and ns.GetPurchasedItemsCacheTable() or nil
      if type(t) == "table" then
        t[itemID] = nil
      end
      RefreshAll()
      Say("Cleared cached purchased flag for itemID=" .. tostring(itemID))
      return true
    end

    Say("Usage: /fqt cache status <itemID> | /fqt cache clear <itemID>")
    return true
  end

  if cmd == "twclear" then
    if type(ns) == "table" and type(ns.ClearRememberedTimewalkingKind) == "function" then
      ns.ClearRememberedTimewalkingKind()
    end
    RefreshAll()
    Say("Cleared remembered Timewalking weekly kind.")
    return true
  end

  if cmd == "evclear" then
    if type(ns) == "table" and type(ns.ClearRememberedEventState) == "function" then
      ns.ClearRememberedEventState()
    end
    RefreshAll()
    Say("Cleared remembered calendar/timewalking event state.")
    return true
  end

  if cmd == "debug" then
    NormalizeSV()
    local sub, rest2 = rest:match("^(%S+)%s*(.-)$")
    sub = tostring(sub or ""):lower()
    rest2 = tostring(rest2 or ""):lower()
    if sub == "autobuy" or sub == "buy" then
      local v
      if rest2 == "on" or rest2 == "1" or rest2 == "true" then
        v = true
      elseif rest2 == "off" or rest2 == "0" or rest2 == "false" then
        v = false
      else
        v = not (_G.fr0z3nUI_QuestTracker_Acc and _G.fr0z3nUI_QuestTracker_Acc.settings and _G.fr0z3nUI_QuestTracker_Acc.settings.debugAutoBuy == true)
      end
      if _G.fr0z3nUI_QuestTracker_Acc and _G.fr0z3nUI_QuestTracker_Acc.settings then
        _G.fr0z3nUI_QuestTracker_Acc.settings.debugAutoBuy = (v == true)
        Say("AutoBuy debug: " .. (_G.fr0z3nUI_QuestTracker_Acc.settings.debugAutoBuy and "ON" or "OFF"))
      else
        Say("AutoBuy debug: unavailable (SV missing)")
      end
      return true
    end

    if sub == "hitboxes" or sub == "hitbox" or sub == "hb" then
      local v
      if rest2 == "on" or rest2 == "1" or rest2 == "true" then
        v = true
      elseif rest2 == "off" or rest2 == "0" or rest2 == "false" then
        v = false
      else
        v = not (GetUISetting("debugHitboxes", false) == true)
      end
      SetUISetting("debugHitboxes", v == true)
      RefreshAll()
      Say("Hitbox debug: " .. ((GetUISetting("debugHitboxes", false) == true) and "ON" or "OFF"))
      return true
    end

    Say("Usage: /fqt debug autobuy [on|off] | hitboxes [on|off]")
    return true
  end

  return false
end

SLASH_FR0Z3NUIFQT1 = "/fqt"
if not SlashCmdList["FR0Z3NUIFQT"] then
  rawset(SlashCmdList, "FR0Z3NUIFQT", function(msg)
    local raw = tostring(msg or "")
    local trimmed = raw:gsub("^%s+", ""):gsub("%s+$", "")
    local cmd, rest = trimmed:match("^(%S+)%s*(.-)$")
    cmd = tostring(cmd or ""):lower()
    rest = tostring(rest or "")

    do
      local qid = nil
      if cmd == "qc" then
        qid = tonumber((rest:match("^(%d+)")))
        if not qid then
          Say("Usage: /fqt qc12345")
          return
        end
      else
        qid = tonumber((cmd:match("^qc(%d+)$")))
      end

      if qid then
        local done = QuestIsCompleted(qid)
        local ready = QuestReadyForTurnIn(qid)
        local onQuest = PlayerIsOnQuestID(qid)
        Say(string.format(
          "Quest %d: %s (onQuest=%s, readyForTurnIn=%s)",
          qid,
          done and "Complete" or "Not complete",
          onQuest and "yes" or "no",
          ready and "yes" or "no"
        ))
        return
      end
    end

    if cmd == "" then
      if ns and ns.ShowOptions then
        ns.ShowOptions()
      else
        Say("Options UI module not loaded.")
      end
      return
    end

    if cmd == "on" then
      SetFramesEnabled(true)
      RefreshAll()
      Say("Enabled.")
      return
    end

    if cmd == "off" then
      SetFramesEnabled(false)
      RefreshAll()
      Say("Disabled.")
      return
    end

    if cmd == "status" then
      local version
      do
        local api = _G and rawget(_G, "C_AddOns")
        if type(api) == "table" and type(api.GetAddOnMetadata) == "function" then
          local ok, r = pcall(api.GetAddOnMetadata, addonName, "Version")
          if ok and type(r) == "string" and r ~= "" then version = r end
        end
        if not version and type(GetAddOnMetadata) == "function" then
          local ok, r = pcall(GetAddOnMetadata, addonName, "Version")
          if ok and type(r) == "string" and r ~= "" then version = r end
        end
      end

      Say(string.format(
        "version=%s, enabled=%s, editMode=%s",
        tostring(version or "?"),
        (GetFramesEnabled() and "on" or "off"),
        (GetEditMode() and "on" or "off")
      ))

      do
        local canTS = (C_TradeSkillUI and C_TradeSkillUI.GetAllProfessionTradeSkillLines) and true or false
        Say("tradeSkillUI=" .. (canTS and "ready" or "unavailable"))
      end

      PrintProfStatusFallback()
      return
    end

    if cmd == "prof" or cmd == "profs" or cmd == "profession" or cmd == "professions" then
      NormalizeSV()

      local sub, rest2 = rest:match("^(%S+)%s*(.-)$")
      sub = tostring(sub or "status"):lower()
      rest2 = tostring(rest2 or "")

      local function CanonicalProfKeyFromToken(token)
        token = tostring(token or "")
        token = token:gsub("%s+", "")
        if token == "" then return nil end

        local want = token:lower()
        if type(ns) == "table" and type(ns.Profs) == "table" and type(ns.Profs.SKILLLINE_TO_PROFKEY) == "table" then
          for _, k in pairs(ns.Profs.SKILLLINE_TO_PROFKEY) do
            if type(k) == "string" and k:lower() == want then
              return k
            end
          end
        end

        return nil
      end

      local function PrintProfessionStatus(profToken, xp)
        if not (type(ns) == "table" and type(ns.Profs) == "table" and type(ns.Profs.HasSkillLineID) == "function") then
          Say("prof: profession module unavailable")
          return
        end

        local key = CanonicalProfKeyFromToken(profToken)
        if not key then
          Say("prof: unknown profession (try full name like mining, tailoring, enchanting)")
          return
        end

        local baseID = (type(ns.Profs.BASE_SKILLLINE_BY_PROFKEY) == "table") and ns.Profs.BASE_SKILLLINE_BY_PROFKEY[key] or nil
        baseID = tonumber(baseID)
        if not baseID or baseID <= 0 then
          Say("prof: base id missing for " .. tostring(key))
          return
        end

        local base = ns.Profs.HasSkillLineID(baseID) and true or false
        local label = tostring(profToken or key):lower()
        if not xp then
          Say(string.format("%s: base(%d)=%s", label, baseID, tostring(base)))
          return
        end

        local tier
        if type(ns.Profs.TIERS_BY_PROFKEY) == "table" and type(ns.Profs.TIERS_BY_PROFKEY[key]) == "table" then
          tier = ns.Profs.TIERS_BY_PROFKEY[key][tonumber(xp) or -1]
        end
        if not tier then
          Say(string.format("%s%02d: no tier mapping (known: 01-12 where defined)", label, tonumber(xp) or 0))
          return
        end

        local hasTier = ns.Profs.HasSkillLineID(tier) and true or false
        Say(string.format("%s%02d: base(%d)=%s, tier(%d)=%s", label, tonumber(xp) or 0, baseID, tostring(base), tonumber(tier) or 0, tostring(hasTier)))
      end

      if sub == "?" or sub == "help" then
        Say("Usage: /fqt prof status | refresh | has <skillLineID...> | dump | api | dmf | <profession> | <profession>##")
        return
      end

      if sub == "status" then
        PrintProfStatusFallback()
        return
      end

      if sub == "refresh" or sub == "force" or sub == "update" or sub == "forceupdate" then
        if type(ns) == "table" and type(ns.Profs) == "table" and type(ns.Profs.RefreshKnownProfessionSkillLines) == "function" then
          local ok, refreshed = pcall(ns.Profs.RefreshKnownProfessionSkillLines, true)
          Say("profsRefresh: ok=" .. tostring(ok and true or false) .. "; updated=" .. tostring(refreshed and true or false))
        else
          Say("profsRefresh: profession module unavailable")
        end
        PrintProfStatusFallback()
        return
      end

      if sub == "has" or sub == "check" then
        if not (type(ns) == "table" and type(ns.Profs) == "table" and type(ns.Profs.HasSkillLineID) == "function") then
          Say("profsHas: profession module unavailable")
          return
        end

        local any = false
        for token in rest2:gmatch("%S+") do
          local id = tonumber(token)
          if id and id > 0 then
            any = true
            Say(string.format("%d => %s", id, tostring(ns.Profs.HasSkillLineID(id) and true or false)))
          end
        end

        if not any then
          Say("Usage: /fqt prof has <skillLineID...>")
        end
        return
      end

      if sub == "dmf" then
        local rows = {
          { label = "Mining", questID = 29518, profID = 186 },
          { label = "Tailoring", questID = 29520, profID = 197 },
          { label = "Cooking", questID = 29506, profID = 185 },
          { label = "Fishing", questID = 29513, profID = 356 },
        }

        Say("DMF profession debug (note: DMF rules hide when completed):")
        for _, r in ipairs(rows) do
          local qid = tonumber(r.questID)
          local pid = tonumber(r.profID)
          local completed = (qid and IsQuestCompleted and IsQuestCompleted(qid)) and true or false
          local inLog = (qid and IsQuestInLog and IsQuestInLog(qid)) and true or false
          local has = (pid and HasSkillLineID(pid)) and true or false
          Say(string.format("%s: prof(%d)=%s, quest(%d) completed=%s inLog=%s", tostring(r.label), pid or 0, tostring(has), qid or 0, tostring(completed), tostring(inLog)))
        end
        return
      end

      if sub == "dump" or sub == "list" then
        local c = _G.fr0z3nUI_QuestTracker_Char and _G.fr0z3nUI_QuestTracker_Char.cache or nil
        c = (type(c) == "table") and c or {}

        local keys = {}
        if type(c.knownProfessionKeys) == "table" then
          for k, v in pairs(c.knownProfessionKeys) do
            if v == true then keys[#keys + 1] = tostring(k) end
          end
        end
        table.sort(keys, function(a, b) return tostring(a):lower() < tostring(b):lower() end)
        Say("profsKeys: " .. (#keys > 0 and table.concat(keys, ", ") or "(none cached)"))
        PrintProfStatusFallback()
        return
      end

      if sub == "api" or sub == "live" then
        local GP = _G and rawget(_G, "GetProfessions")
        local GPI = _G and rawget(_G, "GetProfessionInfo")
        if type(GP) ~= "function" or type(GPI) ~= "function" then
          Say("profsApi: GetProfessions/GetProfessionInfo unavailable")
          return
        end

        local ok, p1, p2, a, f, c2 = pcall(GP)
        if not ok then
          Say("profsApi: GetProfessions errored")
          return
        end

        Say(string.format("GetProfessions: p1=%s p2=%s arch=%s fish=%s cook=%s", tostring(p1), tostring(p2), tostring(a), tostring(f), tostring(c2)))
        local indices = { p1, p2, a, f, c2 }
        local labels = { "p1", "p2", "arch", "fish", "cook" }
        for i = 1, 5 do
          local idx = indices[i]
          if idx ~= nil then
            local ok2,
              name, icon, rank, maxRank, numSpells, spelloffset,
              skillLine, rankModifier, specializationIndex, specializationOffset,
              skillLineName, skillLineDescription, _, _, _ = pcall(GPI, idx)

            if ok2 then
              Say(string.format(
                "%s idx=%s name=%s skillLine=%s rank=%s/%s",
                tostring(labels[i]),
                tostring(idx),
                tostring(name),
                tostring(skillLine),
                tostring(rank),
                tostring(maxRank)
              ))
            else
              Say(string.format("%s idx=%s GetProfessionInfo errored", tostring(labels[i]), tostring(idx)))
            end
          else
            Say(string.format("%s idx=nil", tostring(labels[i])))
          end
        end

        if C_TradeSkillUI and type(C_TradeSkillUI.GetProfessionInfoBySkillLineID) == "function" then
          local quick = { 186, 197, 185, 356, 2908, 2911 }
          for _, id in ipairs(quick) do
            local ok3, info = pcall(C_TradeSkillUI.GetProfessionInfoBySkillLineID, id)
            if ok3 and type(info) == "table" then
              Say(string.format("TS id=%d max=%s lvl=%s name=%s", id, tostring(info.maxSkillLevel), tostring(info.skillLevel), tostring(info.professionName or info.name)))
            else
              Say(string.format("TS id=%d info=nil", id))
            end
          end
        else
          Say("TS: GetProfessionInfoBySkillLineID unavailable")
        end

        return
      end

      do
        local token, xp = sub:match("^([%a]+)(%d%d)$")
        if token and xp then
          PrintProfessionStatus(token, tonumber(xp))
          return
        end
        if sub:match("^[%a]+$") then
          PrintProfessionStatus(sub, nil)
          return
        end
      end

      Say("Usage: /fqt prof status | refresh | has <skillLineID...> | dump | api | dmf | <profession> | <profession>##")
      return
    end

    if cmd == "reset" then
      if type(deps.ResetFramePositionsToDefaults) == "function" then
        deps.ResetFramePositionsToDefaults()
      elseif type(ns) == "table" and type(ns.ResetFramePositionsToDefaults) == "function" then
        ns.ResetFramePositionsToDefaults()
      end
      RefreshAll()
      Say("Frame positions reset to defaults.")
      return
    end

    if cmd == "rgb" then
      if ns and ns.ShowRGBPicker then
        ns.ShowRGBPicker()
      else
        Say("RGB Picker module not loaded.")
      end
      return
    end

    if cmd == "aaq" then
      if type(ns) == "table" and type(ns.RunQuestXKeepListAbandon) == "function" then
        ns.RunQuestXKeepListAbandon()
      else
        Say("Abandon All Quests is unavailable.")
      end
      return
    end

    if cmd == "aaqs" then
      if type(ns) == "table" and type(ns.RunQuestXKeepListAbandonNoConfirm) == "function" then
        ns.RunQuestXKeepListAbandonNoConfirm()
      else
        Say("Abandon All Quests is unavailable.")
      end
      return
    end

    if cmd == "twdebug" or cmd == "evdebug" or cmd == "framedebug" or cmd == "ruledebug" or cmd == "cache" or cmd == "twclear" or cmd == "evclear" or cmd == "debug" then
      if DispatchDebugCommand(cmd, rest) then
        return
      end
    end

    Say("CoreCmd: /fqt (options), /fqt status, /fqt qc12345, /fqt prof ..., /fqt on, /fqt off, /fqt reset, /fqt rgb, /fqt aaq, /fqt aaqs, /fqt debug ..., /fqt twdebug, /fqt twclear, /fqt evdebug, /fqt framedebug [frameID], /fqt ruledebug <ruleKey>, /fqt evclear")
  end)
end
