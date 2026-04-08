local addonName, ns = ...

ns.Currency = ns.Currency or {}

local _warbandCurrencyTotals = {}
local _warbandCurrencyRequestAt = 0
local _warbandCurrencyFullRefreshAt = 0

local function GetCurrencyInfoSafe(currencyID)
  currencyID = tonumber(currencyID)
  if not currencyID or currencyID <= 0 then return nil end

  if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
    local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, currencyID)
    if ok and type(info) == "table" then
      return info
    end
  end

  return nil
end

ns.GetCurrencyInfoSafe = GetCurrencyInfoSafe

local function GetCurrencyQuantitySafe(currencyID)
  currencyID = tonumber(currencyID)
  if not currencyID or currencyID <= 0 then return 0 end

  local info = GetCurrencyInfoSafe(currencyID)
  if type(info) == "table" then
    return tonumber(info.quantity) or 0
  end

  return 0
end

ns.GetCurrencyQuantitySafe = GetCurrencyQuantitySafe

local function RequestWarbandCurrencyData()
  if not (C_CurrencyInfo and C_CurrencyInfo.RequestCurrencyDataForAccountCharacters) then
    return false
  end

  local now = (GetTime and GetTime()) or 0
  if now > 0 and _warbandCurrencyRequestAt > 0 and (now - _warbandCurrencyRequestAt) < 30 then
    return false
  end
  _warbandCurrencyRequestAt = now
  pcall(C_CurrencyInfo.RequestCurrencyDataForAccountCharacters)
  return true
end

ns.RequestWarbandCurrencyData = RequestWarbandCurrencyData

local function GetCachedWarbandCurrencyTotal(currencyID)
  local acc = fr0z3nUI_QuestTracker_Acc
  local t = (type(acc) == "table" and type(acc.cache) == "table") and acc.cache.currencyWB or nil
  if type(t) ~= "table" then return nil end

  local e = t[currencyID]
  if type(e) == "table" then
    local total = tonumber(e.total)
    if total ~= nil then return total end
  end
  return nil
end

local function SaveCachedWarbandCurrencyTotal(currencyID, total)
  local acc = fr0z3nUI_QuestTracker_Acc
  if type(acc) ~= "table" then return end
  acc.cache = acc.cache or {}
  acc.cache.currencyWB = acc.cache.currencyWB or {}
  acc.cache.currencyWB[currencyID] = {
    total = tonumber(total) or 0,
    at = (time and time()) or 0,
  }
end

local function ComputeWarbandCurrencyTotalFromAccountData(currencyID)
  if not (C_CurrencyInfo and C_CurrencyInfo.GetAccountCharacterCurrencyData) then
    return nil
  end

  local ok, data = pcall(C_CurrencyInfo.GetAccountCharacterCurrencyData, currencyID)
  if not ok or type(data) ~= "table" then
    return nil
  end

  local total = 0
  local found = false
  for _, row in ipairs(data) do
    if type(row) == "table" then
      local q = row.quantity
      if q == nil then q = row.amount end
      if q == nil then q = row.count end
      if q == nil then q = row.totalQuantity end
      q = tonumber(q)
      if q ~= nil then
        total = total + q
        found = true
      end
    end
  end

  if not found then return nil end
  return total
end

local function GetWarbandCurrencyTotalSafe(currencyID, allowCache)
  currencyID = tonumber(currencyID)
  if not currencyID or currencyID <= 0 then return nil, false end

  if _warbandCurrencyTotals[currencyID] ~= nil then
    return _warbandCurrencyTotals[currencyID], false
  end

  RequestWarbandCurrencyData()

  local total = ComputeWarbandCurrencyTotalFromAccountData(currencyID)
  if total ~= nil then
    _warbandCurrencyTotals[currencyID] = total
    SaveCachedWarbandCurrencyTotal(currencyID, total)
    return total, false
  end

  if allowCache then
    local cached = GetCachedWarbandCurrencyTotal(currencyID)
    if cached ~= nil then
      return cached, true
    end
  end

  return nil, false
end

ns.GetWarbandCurrencyTotalSafe = GetWarbandCurrencyTotalSafe

local function IsCurrencyWarbandTransferableSafe(currencyID)
  local info = GetCurrencyInfoSafe(currencyID)
  return (type(info) == "table" and info.isAccountTransferable == true) and true or false
end

ns.IsCurrencyWarbandTransferableSafe = IsCurrencyWarbandTransferableSafe

function ns.WarbandCurrencyInvalidate(currencyID)
  currencyID = tonumber(currencyID)
  if currencyID and currencyID > 0 then
    _warbandCurrencyTotals[currencyID] = nil
  end
end

local function CollectCurrencyGateIDsFromRules()
  local out = {}

  local function AddFromRule(r)
    if type(r) ~= "table" then return end
    if type(r.item) == "table" then
      local cid = tonumber((type(r.item.currencyID) == "table") and r.item.currencyID[1] or r.item.currencyID)
      if cid and cid > 0 then
        out[cid] = true
      end
    end
  end

  if type(ns.rules) == "table" then
    for _, r in ipairs(ns.rules) do
      AddFromRule(r)
    end
  end

  local acc = fr0z3nUI_QuestTracker_Acc
  local settings = (type(acc) == "table") and acc.settings or nil
  local custom = (type(settings) == "table") and settings.customRules or nil
  if type(custom) == "table" then
    for _, r in ipairs(custom) do
      AddFromRule(r)
    end
  end

  local edits = (type(settings) == "table") and settings.defaultRuleEdits or nil
  if type(edits) == "table" then
    for _, r in pairs(edits) do
      AddFromRule(r)
    end
  end

  return out
end

local function RefreshWarbandCurrencyCacheForAllKnownCurrencies()
  local now = (GetTime and GetTime()) or 0
  if now > 0 and _warbandCurrencyFullRefreshAt > 0 and (now - _warbandCurrencyFullRefreshAt) < 30 then
    return
  end
  _warbandCurrencyFullRefreshAt = now

  RequestWarbandCurrencyData()

  local ids = CollectCurrencyGateIDsFromRules()
  for cid in pairs(ids) do
    if IsCurrencyWarbandTransferableSafe(cid) then
      _warbandCurrencyTotals[cid] = nil
      local total = ComputeWarbandCurrencyTotalFromAccountData(cid)
      if total ~= nil then
        _warbandCurrencyTotals[cid] = total
        SaveCachedWarbandCurrencyTotal(cid, total)
      end
    end
  end
end

ns.RefreshWarbandCurrencyCacheForAllKnownCurrencies = RefreshWarbandCurrencyCacheForAllKnownCurrencies

function ns.Currency.OnCurrencyDisplayUpdate(frame, currencyID)
  currencyID = tonumber(currencyID)
  if currencyID and currencyID > 0 then
    ns.WarbandCurrencyInvalidate(currencyID)
  end

  RequestWarbandCurrencyData()

  if type(frame) ~= "table" then return end
  if frame._wbCurrencyRefreshTimer then
    frame._wbCurrencyRefreshTimer:Cancel()
  end
  if C_Timer and C_Timer.NewTimer then
    frame._wbCurrencyRefreshTimer = C_Timer.NewTimer(1.0, RefreshWarbandCurrencyCacheForAllKnownCurrencies)
  end
end
