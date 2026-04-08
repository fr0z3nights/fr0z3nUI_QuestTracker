local addonName, ns = ...

ns.Calendar = ns.Calendar or {}
local Cal = ns.Calendar

local function SafeToString(v)
  if v == nil then return "" end
  if type(issecretvalue) == "function" and issecretvalue(v) then
    return ""
  end
  local ok, s = pcall(tostring, v)
  if ok and type(s) == "string" then
    return s
  end
  return ""
end

local function SafeLowerString(v)
  if v == nil then return "" end
  if type(issecretvalue) == "function" and issecretvalue(v) then
    return ""
  end
  local ok, s = pcall(string.lower, v)
  if ok and type(s) == "string" then
    return s
  end
  return SafeLowerString(SafeToString(v))
end

local function HasAuraSpellID(spellID)
  if not spellID then return false end

  if AuraUtil and AuraUtil.FindAuraBySpellId then
    local name = AuraUtil.FindAuraBySpellId(spellID, "player", "HELPFUL")
    if name then return true end
    name = AuraUtil.FindAuraBySpellId(spellID, "player", "HARMFUL")
    return name and true or false
  end

  return false
end

-- Remembered event state (weekly/daily auras + timewalking kind)
-- Kept here with other Calendar/Timewalking logic.

local function NormalizeSV()
  if type(ns) == "table" and type(ns.NormalizeSV) == "function" then
    return ns.NormalizeSV()
  end
  if type(_G) == "table" and type(_G.NormalizeSV) == "function" then
    return _G.NormalizeSV()
  end
end

local function GetServerTimeSafe()
  if GetServerTime then
    return tonumber(GetServerTime()) or 0
  end
  return 0
end

local function GetWeeklyResetAt()
  local now = GetServerTimeSafe()
  if C_DateAndTime and C_DateAndTime.GetSecondsUntilWeeklyReset then
    local s = tonumber(C_DateAndTime.GetSecondsUntilWeeklyReset())
    -- Sanity clamp: weekly resets should never be weeks/months away.
    -- If Blizzard returns bogus values, don't persist remembered weekly state.
    if s and s > 0 and s < (60 * 60 * 24 * 8) then
      return now + s
    end
  end
  return 0
end

local function GetDailyResetAt()
  local now = GetServerTimeSafe()
  local s = nil
  if C_DateAndTime and C_DateAndTime.GetSecondsUntilDailyReset then
    s = tonumber(C_DateAndTime.GetSecondsUntilDailyReset())
  elseif GetQuestResetTime then
    s = tonumber(GetQuestResetTime())
  end
  -- Sanity clamp: daily reset should be within ~48 hours.
  if s and s > 0 and s < (60 * 60 * 48) then
    return now + s
  end
  return 0
end

local function RememberWeeklyAura(spellID)
  if spellID == nil then return end
  NormalizeSV()
  local resetAt = GetWeeklyResetAt()
  if resetAt and resetAt > 0 then
    fr0z3nUI_QuestTracker_Acc.cache.weeklyAuras[tostring(spellID)] = resetAt
  end
end

local function HasRememberedWeeklyAura(spellID)
  if spellID == nil then return false end
  NormalizeSV()
  local now = GetServerTimeSafe()
  local exp = fr0z3nUI_QuestTracker_Acc.cache.weeklyAuras[tostring(spellID)]
  exp = tonumber(exp) or 0
  -- If expiration is absurdly far in the future, treat as corrupt/stale.
  if exp > (now + (60 * 60 * 24 * 8)) then
    fr0z3nUI_QuestTracker_Acc.cache.weeklyAuras[tostring(spellID)] = nil
    return false
  end
  if exp > now then
    return true
  end
  if exp ~= 0 then
    fr0z3nUI_QuestTracker_Acc.cache.weeklyAuras[tostring(spellID)] = nil
  end
  return false
end

local function RememberDailyAura(spellID)
  if spellID == nil then return end
  NormalizeSV()
  local resetAt = GetDailyResetAt()
  if resetAt and resetAt > 0 then
    fr0z3nUI_QuestTracker_Acc.cache.dailyAuras[tostring(spellID)] = resetAt
  end
end

local function HasRememberedDailyAura(spellID)
  if spellID == nil then return false end
  NormalizeSV()
  local now = GetServerTimeSafe()
  local exp = fr0z3nUI_QuestTracker_Acc.cache.dailyAuras[tostring(spellID)]
  exp = tonumber(exp) or 0
  -- If expiration is absurdly far in the future, treat as corrupt/stale.
  if exp > (now + (60 * 60 * 48)) then
    fr0z3nUI_QuestTracker_Acc.cache.dailyAuras[tostring(spellID)] = nil
    return false
  end
  if exp > now then
    return true
  end
  if exp ~= 0 then
    fr0z3nUI_QuestTracker_Acc.cache.dailyAuras[tostring(spellID)] = nil
  end
  return false
end

local function RememberWeeklyTimewalkingKind(kind)
  kind = tostring(kind or "")
  if kind == "" then return end
  NormalizeSV()
  -- Timewalking kind memory is intentionally short-lived.
  -- Store it only until the next DAILY reset to avoid stale/incorrect kinds persisting.
  local resetAt = GetDailyResetAt()
  if resetAt and resetAt > 0 then
    fr0z3nUI_QuestTracker_Acc.cache.twWeekly.kind = kind
    fr0z3nUI_QuestTracker_Acc.cache.twWeekly.exp = resetAt
  end
end

local function HasRememberedWeeklyTimewalkingKind(kind)
  NormalizeSV()
  local now = GetServerTimeSafe()
  local cache = fr0z3nUI_QuestTracker_Acc.cache.twWeekly
  if type(cache) ~= "table" then return false end
  local exp = tonumber(cache.exp) or 0
  -- If expiration is absurdly far in the future, treat as corrupt/stale.
  -- Daily reset should be within ~48 hours.
  if exp > (now + (60 * 60 * 48)) then
    cache.kind = nil
    cache.exp = nil
    return false
  end
  if exp <= now then
    if exp ~= 0 then
      cache.kind = nil
      cache.exp = nil
    end
    return false
  end
  if kind == nil then
    return cache.kind ~= nil and tostring(cache.kind) ~= ""
  end
  kind = tostring(kind or "")
  if kind == "" then return false end
  return tostring(cache.kind or "") == kind
end

local function ClearRememberedTimewalkingKind()
  NormalizeSV()
  if fr0z3nUI_QuestTracker_Acc and type(fr0z3nUI_QuestTracker_Acc.cache) == "table" then
    local cache = fr0z3nUI_QuestTracker_Acc.cache.twWeekly
    if type(cache) == "table" then
      cache.kind = nil
      cache.exp = nil
    end
  end
end

local function ClearRememberedEventState()
  NormalizeSV()
  if not (fr0z3nUI_QuestTracker_Acc and type(fr0z3nUI_QuestTracker_Acc.cache) == "table") then return end
  local cache = fr0z3nUI_QuestTracker_Acc.cache

  if type(cache.weeklyAuras) == "table" then
    for k in pairs(cache.weeklyAuras) do
      if type(k) == "string" and k:find("^event:") then
        cache.weeklyAuras[k] = nil
      end
    end
  end

  if type(cache.dailyAuras) == "table" then
    for k in pairs(cache.dailyAuras) do
      if type(k) == "string" and k:find("^event:") then
        cache.dailyAuras[k] = nil
      end
    end
  end

  if type(cache.twWeekly) == "table" then
    cache.twWeekly.kind = nil
    cache.twWeekly.exp = nil
  end
end

-- First character per account to log in after daily reset: clear remembered event state.
-- We store the *next daily reset timestamp* (GetDailyResetAt) as a stable per-day stamp.
local function MaybeAutoResetEventsOncePerDay()
  NormalizeSV()
  local acc = fr0z3nUI_QuestTracker_Acc
  if not (type(acc) == "table" and type(acc.cache) == "table") then
    return
  end

  local dailyResetAt = tonumber(GetDailyResetAt()) or 0
  if dailyResetAt <= 0 then
    return
  end

  local cache = acc.cache
  local lastStamp = tonumber(cache.eventAutoResetDailyStamp) or 0
  if lastStamp == dailyResetAt then
    return
  end

  ClearRememberedEventState()
  cache.eventAutoResetDailyStamp = dailyResetAt
end

Cal.RememberWeeklyAura = RememberWeeklyAura
Cal.HasRememberedWeeklyAura = HasRememberedWeeklyAura
Cal.RememberDailyAura = RememberDailyAura
Cal.HasRememberedDailyAura = HasRememberedDailyAura
Cal.RememberWeeklyTimewalkingKind = RememberWeeklyTimewalkingKind
Cal.HasRememberedWeeklyTimewalkingKind = HasRememberedWeeklyTimewalkingKind
Cal.ClearRememberedTimewalkingKind = ClearRememberedTimewalkingKind
Cal.ClearRememberedEventState = ClearRememberedEventState
Cal.MaybeAutoResetEventsOncePerDay = MaybeAutoResetEventsOncePerDay

ns.ClearRememberedTimewalkingKind = ClearRememberedTimewalkingKind
ns.ClearRememberedEventState = ClearRememberedEventState

local timewalkingSpellToKeywords = {
  [452307] = { "Classic" },
  [335148] = { "Outland", "Burning Crusade" },
  [335149] = { "Wrath", "Northrend", "Lich King" },
  [335150] = { "Cataclysm", "Cata" },
  [335151] = { "Pandaria", "Mists" },
  [335152] = { "Draenor", "Warlords" },
  [359082] = { "Legion" },
  [1223878] = { "Azeroth", "BFA", "Battle for Azeroth" },
  [1256081] = { "Shadowlands" },
}

local _calendarOpened = false
local _twEventCache = { at = 0, active = {} }
local _anyTWCache = { at = 0, active = false }
local _calendarKeywordCache = { at = 0, active = {}, unknown = {} }

local function EnsureCalendarOpened()
  if _calendarOpened then return end
  if C_Calendar and C_Calendar.OpenCalendar then
    pcall(C_Calendar.OpenCalendar)
    _calendarOpened = true
  end
end

local function OnCalendarUpdate(frame)
  if type(frame) ~= "table" then return end
  if not (C_Timer and C_Timer.NewTimer) then return end

  -- Calendar can fire a burst of events; avoid constant timer churn.
  if frame._refreshTimer then
    return
  end
  frame._refreshTimer = C_Timer.NewTimer(1.5, function()
    if frame then frame._refreshTimer = nil end
    if type(ns) == "table" and type(ns.RefreshAll) == "function" then
      ns.RefreshAll()
    end
  end)
end

local function GetCurrentCalendarDay()
  if C_DateAndTime and C_DateAndTime.GetCurrentCalendarTime then
    local ok, t = pcall(C_DateAndTime.GetCurrentCalendarTime)
    if ok and type(t) == "table" and tonumber(t.monthDay) then
      return tonumber(t.monthDay)
    end
  end
  if C_Calendar and C_Calendar.GetDate then
    local ok, t = pcall(C_Calendar.GetDate)
    if ok and type(t) == "table" and tonumber(t.monthDay) then
      return tonumber(t.monthDay)
    end
  end
  return nil
end

local function GetCurrentMonthNumDays()
  if C_Calendar and C_Calendar.GetMonthInfo then
    local ok, info = pcall(C_Calendar.GetMonthInfo, 0)
    if ok and type(info) == "table" and tonumber(info.numDays) then
      local n = tonumber(info.numDays)
      if n and n > 0 then return n end
    end
  end
  return 31
end

local function GetCalendarEventText(monthOffset, day, index)
  if not (C_Calendar and C_Calendar.GetDayEvent) then return nil end
  local ok, ev = pcall(C_Calendar.GetDayEvent, monthOffset, day, index)
  if not ok or type(ev) ~= "table" then return nil end
  local title = rawget(ev, "title")
  if title then
    local s = SafeToString(title)
    if s ~= "" then return s end
  end
  return nil
end

local function GetDayEventSafe(monthOffset, day, index)
  if not (C_Calendar and C_Calendar.GetDayEvent) then return nil end
  local ok, ev = pcall(C_Calendar.GetDayEvent, monthOffset, day, index)
  if ok and type(ev) == "table" then
    return ev
  end
  return nil
end

local function CalendarTimeToEpoch(ct)
  if type(ct) ~= "table" then return nil end
  local year = tonumber(rawget(ct, "year"))
  local month = tonumber(rawget(ct, "month"))
  local day = tonumber(rawget(ct, "monthDay")) or tonumber(rawget(ct, "day"))
  local hour = tonumber(rawget(ct, "hour")) or 0
  local minute = tonumber(rawget(ct, "minute")) or 0
  if not (year and month and day) then return nil end

  if type(time) ~= "function" then return nil end
  local ok, epoch = pcall(time, { year = year, month = month, day = day, hour = hour, min = minute, sec = 0 })
  if ok and type(epoch) == "number" then
    return epoch
  end
  return nil
end

local function IsDayEventEnded(ev, nowEpoch)
  if type(ev) ~= "table" then return false end
  if nowEpoch == nil then
    if GetServerTime then
      nowEpoch = tonumber(GetServerTime()) or 0
    elseif type(time) == "function" then
      nowEpoch = tonumber(time()) or 0
    else
      nowEpoch = 0
    end
  end

  local endTime = rawget(ev, "endTime")
  local endEpoch = CalendarTimeToEpoch(endTime)
  if endEpoch and endEpoch > 0 and nowEpoch > 0 then
    return nowEpoch >= endEpoch
  end

  return false
end

local function IsDayEventActiveNow(ev, nowEpoch)
  if type(ev) ~= "table" then return true end
  if nowEpoch == nil then
    if GetServerTime then
      nowEpoch = tonumber(GetServerTime()) or 0
    elseif type(time) == "function" then
      nowEpoch = tonumber(time()) or 0
    else
      nowEpoch = 0
    end
  end
  if not nowEpoch or nowEpoch <= 0 then
    return true
  end

  local startEpoch = CalendarTimeToEpoch(rawget(ev, "startTime"))
  local endEpoch = CalendarTimeToEpoch(rawget(ev, "endTime"))

  if startEpoch and endEpoch and startEpoch > 0 and endEpoch > 0 then
    return (nowEpoch >= startEpoch) and (nowEpoch < endEpoch)
  end
  if endEpoch and endEpoch > 0 then
    return nowEpoch < endEpoch
  end
  if startEpoch and startEpoch > 0 then
    return nowEpoch >= startEpoch
  end

  -- No usable time bounds; treat as active and rely on day-window + keyword logic.
  return true
end

local function IsHolidayDayEvent(monthOffset, day, index)
  if not (C_Calendar and C_Calendar.GetDayEvent) then return false end
  local ok, ev = pcall(C_Calendar.GetDayEvent, monthOffset, day, index)
  if not ok or type(ev) ~= "table" then return false end

  local eventType = rawget(ev, "eventType")
  do
    local et = Enum and Enum.CalendarEventType
    local holidayEnum = et and (rawget(et, "Holiday") or rawget(et, "HOLIDAY"))
    if holidayEnum ~= nil and eventType == holidayEnum then
      return true
    end
  end
  if type(eventType) == "string" and SafeLowerString(eventType) == "holiday" then
    return true
  end

  local calendarType = rawget(ev, "calendarType")
  if type(calendarType) == "string" and SafeLowerString(calendarType) == "holiday" then
    return true
  end

  return false
end

local function GetCalendarHolidayText(monthOffset, day, index)
  if not (C_Calendar and C_Calendar.GetHolidayInfo) then return nil end
  -- IMPORTANT: holiday indices are not the same as day-event indices.
  -- Only query holiday info for day-events that are actually holiday-type;
  -- otherwise we can accidentally attach unrelated holiday text to normal events
  -- and get false positives (e.g., stale bonus events / wrong Timewalking kind).
  if not IsHolidayDayEvent(monthOffset, day, index) then
    return nil
  end
  local ok, info = pcall(C_Calendar.GetHolidayInfo, monthOffset, day, index)
  if not ok or type(info) ~= "table" then return nil end
  local name = rawget(info, "name")
  local desc = rawget(info, "description")
  local out = ""
  if name then out = out .. SafeToString(name) end
  if desc then
    local d = SafeToString(desc)
    if d ~= "" then out = out .. "\n" .. d end
  end
  if out == "" then return nil end
  return out
end

local function IsAnyTimewalkingEventActive()
  local isWednesday = false
  if type(date) == "function" then
    isWednesday = (tonumber(date("%w")) == 3)
  end

  local function IsWednesdayEndsTitle(titleLower)
    if not isWednesday then return false end
    -- Ignore stale calendar entries on local Wednesday that still show as "... End" or "... Ends".
    -- This avoids timezone drift around the Tuesday reset.
    return (type(titleLower) == "string") and (string.match(titleLower, "[%s]ends?%s*$") ~= nil)
  end

  local function HolidayNameLowerFromText(holidayText)
    if type(holidayText) ~= "string" or holidayText == "" then return "" end
    local firstLine = holidayText:match("^([^\n]+)")
    return (firstLine and firstLine ~= "") and string.lower(firstLine) or string.lower(holidayText)
  end

  local now = 0
  if GetServerTime then now = tonumber(GetServerTime()) or 0 end
  if _anyTWCache.at and (now - (_anyTWCache.at or 0)) < 60 then
    return _anyTWCache.active and true or false
  end

  EnsureCalendarOpened()
  if not (C_Calendar and C_Calendar.GetNumDayEvents and C_Calendar.GetDayEvent) then
    _anyTWCache.at = now
    _anyTWCache.active = false
    return false
  end

  local today = GetCurrentCalendarDay()
  if not today then
    _anyTWCache.at = now
    _anyTWCache.active = false
    return false
  end

  local numDays = GetCurrentMonthNumDays()
  local startDay = today
  local endDay = today
  if startDay < 1 then startDay = 1 end
  if endDay > numDays then endDay = numDays end

  local found = false
  for day = startDay, endDay do
    local okNum, n = pcall(C_Calendar.GetNumDayEvents, 0, day)
    n = okNum and tonumber(n) or 0
    for i = 1, n do
      repeat
        local ev = GetDayEventSafe(0, day, i)
        if not IsDayEventActiveNow(ev, now) then
          break
        end

        local title = GetCalendarEventText(0, day, i) or ""
        local titleLower = string.lower(title)
        local holidayText = GetCalendarHolidayText(0, day, i) or ""
        local holidayNameLower = HolidayNameLowerFromText(holidayText)
        local suppressed = IsWednesdayEndsTitle(titleLower) or IsWednesdayEndsTitle(holidayNameLower)
        if suppressed then
          break
        end

        local hay = titleLower .. "\n" .. string.lower(holidayText)
        if string.find(hay, "timewalking", 1, true) or string.find(hay, "turbulent timeways", 1, true) then
          found = true
        end
      until true

      if found then
        break
      end
    end
    if found then break end
  end

  _anyTWCache.at = now
  _anyTWCache.active = found and true or false
  return found and true or false
end

local function NormalizeCalendarKeywords(keywords)
  if keywords == nil then return nil end
  if type(keywords) == "string" then
    keywords = { keywords }
  end
  if type(keywords) ~= "table" then return nil end

  local out = {}
  for _, kw in ipairs(keywords) do
    local s = tostring(kw or "")
    s = s:gsub("%s+", " ")
    s = s:gsub("^%s+", "")
    s = s:gsub("%s+$", "")
    if s ~= "" then
      out[#out + 1] = s
    end
  end
  return out[1] and out or nil
end

local function CalendarKeywordCacheKey(keywords)
  local list = NormalizeCalendarKeywords(keywords)
  if not list then return nil end
  for i = 1, #list do
    list[i] = tostring(list[i] or ""):lower()
  end
  table.sort(list)
  return table.concat(list, "|")
end

local function IsCalendarEventActiveByKeywords(keywords, includeHolidayText)
  local isWednesday = false
  if type(date) == "function" then
    isWednesday = (tonumber(date("%w")) == 3)
  end

  local function IsWednesdayEndsTitle(titleLower)
    if not isWednesday then return false end
    return (type(titleLower) == "string") and (string.match(titleLower, "[%s]ends?%s*$") ~= nil)
  end

  local function HolidayNameLowerFromText(holidayText)
    if type(holidayText) ~= "string" or holidayText == "" then return "" end
    local firstLine = holidayText:match("^([^\n]+)")
    return (firstLine and firstLine ~= "") and string.lower(firstLine) or string.lower(holidayText)
  end

  local kwList = NormalizeCalendarKeywords(keywords)
  if not kwList then return false, false end

  local cacheKeyBase = CalendarKeywordCacheKey(kwList)
  if not cacheKeyBase then return false, false end
  local cacheKey = (includeHolidayText == true and "h:" or "t:") .. cacheKeyBase

  local needles = {}
  for i = 1, #kwList do
    needles[i] = tostring(kwList[i] or ""):lower()
  end

  local now = 0
  if GetServerTime then now = tonumber(GetServerTime()) or 0 end
  if _calendarKeywordCache.at and (now - (_calendarKeywordCache.at or 0)) < 60 and _calendarKeywordCache.active[cacheKey] ~= nil then
    local unk = (_calendarKeywordCache.unknown and _calendarKeywordCache.unknown[cacheKey]) and true or false
    return _calendarKeywordCache.active[cacheKey] and true or false, unk
  end

  EnsureCalendarOpened()
  if not (C_Calendar and C_Calendar.GetNumDayEvents and C_Calendar.GetDayEvent) then
    _calendarKeywordCache.at = now
    _calendarKeywordCache.active[cacheKey] = false
    if _calendarKeywordCache.unknown then _calendarKeywordCache.unknown[cacheKey] = true end
    return false, true
  end

  local today = GetCurrentCalendarDay()
  if not today then
    _calendarKeywordCache.at = now
    _calendarKeywordCache.active[cacheKey] = false
    if _calendarKeywordCache.unknown then _calendarKeywordCache.unknown[cacheKey] = true end
    return false, true
  end

  -- Daily check only: only treat an event as active if it appears on *today*.
  -- This avoids false positives from upcoming/previous calendar entries.
  local startDay = today
  local endDay = today

  local found = false
  for day = startDay, endDay do
    local okNum, n = pcall(C_Calendar.GetNumDayEvents, 0, day)
    n = okNum and tonumber(n) or 0
    for i = 1, n do
      local holidayText = ""
      if includeHolidayText == true then
        holidayText = GetCalendarHolidayText(0, day, i) or ""
      end
      repeat
        local ev = GetDayEventSafe(0, day, i)
        if not IsDayEventActiveNow(ev, now) then
          break
        end

        local title = GetCalendarEventText(0, day, i) or ""
        local titleLower = string.lower(title)
        local holidayNameLower = HolidayNameLowerFromText(holidayText)
        if IsWednesdayEndsTitle(titleLower) or IsWednesdayEndsTitle(holidayNameLower) then
          titleLower = ""
          holidayText = ""
        end

        local hay = titleLower
        if string.len(holidayText) > 0 then
          hay = (hay .. "\n" .. string.lower(holidayText))
        end

        for j = 1, #needles do
          local k = needles[j]
          if k ~= "" and string.find(hay, k, 1, true) then
            found = true
            break
          end
        end
      until true

      if found then
        break
      end
    end
    if found then break end
  end

  _calendarKeywordCache.at = now
  _calendarKeywordCache.active[cacheKey] = found and true or false
  if _calendarKeywordCache.unknown then _calendarKeywordCache.unknown[cacheKey] = false end
  return found and true or false, false
end

local function GetCalendarDebugEvents(daysBack, daysForward)
  daysBack = tonumber(daysBack) or 1
  daysForward = tonumber(daysForward) or 7
  if daysBack < 0 then daysBack = 0 end
  if daysForward < 0 then daysForward = 0 end

  EnsureCalendarOpened()
  if not (C_Calendar and C_Calendar.GetNumDayEvents and C_Calendar.GetDayEvent) then
    return {}, { ok = false, reason = "calendar_api_unavailable" }
  end

  local today = GetCurrentCalendarDay()
  if not today then
    return {}, { ok = false, reason = "no_today" }
  end

  local numDays = GetCurrentMonthNumDays()
  local startDay = today - daysBack
  local endDay = today + daysForward
  if startDay < 1 then startDay = 1 end
  if endDay > numDays then endDay = numDays end

  local events = {}
  for day = startDay, endDay do
    local okNum, n = pcall(C_Calendar.GetNumDayEvents, 0, day)
    n = okNum and tonumber(n) or 0
    for i = 1, n do
      local title = GetCalendarEventText(0, day, i)
      local holidayText = GetCalendarHolidayText(0, day, i)
      if (type(title) == "string" and title ~= "") or (type(holidayText) == "string" and holidayText ~= "") then
        local ev = GetDayEventSafe(0, day, i)
        local startEpoch = ev and CalendarTimeToEpoch(rawget(ev, "startTime")) or nil
        local endEpoch = ev and CalendarTimeToEpoch(rawget(ev, "endTime")) or nil
        local nowEpoch = 0
        if GetServerTime then nowEpoch = tonumber(GetServerTime()) or 0 end
        events[#events + 1] = {
          monthOffset = 0,
          day = day,
          index = i,
          title = title,
          holidayText = holidayText,
          relDay = day - today,
          startEpoch = startEpoch,
          endEpoch = endEpoch,
          ended = (endEpoch and nowEpoch > 0) and (nowEpoch >= endEpoch) or false,
          activeNow = (ev ~= nil and nowEpoch > 0) and (IsDayEventActiveNow(ev, nowEpoch) and true or false) or nil,
        }
      end
    end
  end

  return events, {
    ok = true,
    today = today,
    startDay = startDay,
    endDay = endDay,
    numDays = numDays,
  }
end

local function IsTimewalkingBonusEventActive(spellID)
  spellID = tonumber(spellID)
  if not spellID then return false end

  local keywords = timewalkingSpellToKeywords[spellID]
  if type(keywords) ~= "table" then
    return false
  end

  local now = 0
  if GetServerTime then now = tonumber(GetServerTime()) or 0 end
  local cacheKey = tostring(spellID)
  if _twEventCache.at and (now - (_twEventCache.at or 0)) < 60 and _twEventCache.active[cacheKey] ~= nil then
    return _twEventCache.active[cacheKey] and true or false
  end

  if HasAuraSpellID(spellID) then
    _twEventCache.at = now
    _twEventCache.active[cacheKey] = true
    return true
  end

  local found = false

  local isWednesday = false
  if type(date) == "function" then
    isWednesday = (tonumber(date("%w")) == 3)
  end
  local function IsWednesdayEndsTitle(titleLower)
    if not isWednesday then return false end
    return (type(titleLower) == "string") and (string.match(titleLower, "[%s]ends?%s*$") ~= nil)
  end

  local function HolidayNameLowerFromText(holidayText)
    if type(holidayText) ~= "string" or holidayText == "" then return "" end
    local firstLine = holidayText:match("^([^\n]+)")
    return (firstLine and firstLine ~= "") and string.lower(firstLine) or string.lower(holidayText)
  end

  EnsureCalendarOpened()
  if C_Calendar and C_Calendar.GetNumDayEvents and C_Calendar.GetDayEvent then
    local today = GetCurrentCalendarDay()
    if today then
      local numDays = GetCurrentMonthNumDays()
      local startDay = today - 1
      local endDay = today + 7
      if startDay < 1 then startDay = 1 end
      if endDay > numDays then endDay = numDays end

      for day = startDay, endDay do
        local okNum, n = pcall(C_Calendar.GetNumDayEvents, 0, day)
        n = okNum and tonumber(n) or 0
        for i = 1, n do
          local ev = GetDayEventSafe(0, day, i)
          if IsDayEventActiveNow(ev, now) then
            local title = GetCalendarEventText(0, day, i) or ""
            local titleLower = string.lower(title)
            local holidayText = GetCalendarHolidayText(0, day, i) or ""
            local holidayNameLower = HolidayNameLowerFromText(holidayText)
            if IsWednesdayEndsTitle(titleLower) or IsWednesdayEndsTitle(holidayNameLower) then
              titleLower = ""
              holidayText = ""
            end
            local hay = (titleLower .. "\n" .. string.lower(holidayText))

            if hay:find("timewalking", 1, true) then
              for _, kw in ipairs(keywords) do
                local k = tostring(kw):lower()
                if k ~= "" and hay:find(k, 1, true) then
                  found = true
                  break
                end
              end
            end
          end

          if found then break end
        end
        if found then break end
      end
    end
  end

  _twEventCache.at = now
  _twEventCache.active[cacheKey] = found and true or false
  return found and true or false
end

ns.Calendar.IsAnyTimewalkingEventActive = IsAnyTimewalkingEventActive
ns.Calendar.IsCalendarEventActiveByKeywords = IsCalendarEventActiveByKeywords
ns.Calendar.IsTimewalkingBonusEventActive = IsTimewalkingBonusEventActive
ns.Calendar.CalendarKeywordCacheKey = CalendarKeywordCacheKey
ns.Calendar.EnsureCalendarOpened = EnsureCalendarOpened
ns.Calendar.OnCalendarUpdate = OnCalendarUpdate
ns.GetCalendarDebugEvents = GetCalendarDebugEvents
