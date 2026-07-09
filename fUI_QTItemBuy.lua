local addonName, ns = ...

local Print = ns.Print

local function AutoSellItemsAtMerchant()
  if InCombatLockdown and InCombatLockdown() then return end

  if not (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemID and C_Container.UseContainerItem) then
    return
  end

  local GetEffectiveRules = ns.GetEffectiveRules
  if type(GetEffectiveRules) ~= "function" then return end

  local rules = GetEffectiveRules()
  if type(rules) ~= "table" or not rules[1] then return end

  local IsRuleDisabled = ns.IsRuleDisabled
  local GetStandingIDByFactionID = ns.GetStandingIDByFactionID
  if type(IsRuleDisabled) ~= "function" or type(GetStandingIDByFactionID) ~= "function" then return end

  local shouldSellByItemID = {}
  for _, rule in ipairs(rules) do
    if type(rule) == "table" and type(rule.rep) == "table" and rule.rep.sellWhenExalted == true and rule.rep.factionID then
      if not IsRuleDisabled(rule) then
        local sid = GetStandingIDByFactionID(rule.rep.factionID)
        if sid and sid >= 8 then
          local itemID
          if type(rule.item) == "table" and rule.item.itemID then
            itemID = tonumber(rule.item.itemID)
          elseif rule.itemID then
            itemID = tonumber(rule.itemID)
          end
          if itemID and itemID > 0 then
            shouldSellByItemID[itemID] = true
          end
        end
      end
    end
  end

  if not next(shouldSellByItemID) then return end

  local soldCountsByItemID = {}
  for bag = 0, 4 do
    local n = C_Container.GetContainerNumSlots(bag) or 0
    for slot = 1, n do
      local itemID = C_Container.GetContainerItemID(bag, slot)
      if itemID and shouldSellByItemID[itemID] then
        local info = C_Container.GetContainerItemInfo and C_Container.GetContainerItemInfo(bag, slot) or nil
        local locked = (type(info) == "table" and info.isLocked == true)
        local noValue = (type(info) == "table" and info.hasNoValue == true)
        if not locked and not noValue then
          C_Container.UseContainerItem(bag, slot)
          soldCountsByItemID[itemID] = (soldCountsByItemID[itemID] or 0) + 1
        end
      end
    end
  end

  if not next(soldCountsByItemID) then return end

  local parts = {}
  for itemID, count in pairs(soldCountsByItemID) do
    local name
    if C_Item and C_Item.GetItemNameByID then
      local ok, n = pcall(C_Item.GetItemNameByID, itemID)
      if ok and n and n ~= "" then
        name = n
      end
    end
    parts[#parts + 1] = tostring(count) .. "x " .. tostring(name or ("itemID:" .. tostring(itemID)))
  end
  table.sort(parts)
  if type(Print) == "function" then
    Print("Sold (Exalted): " .. table.concat(parts, ", "))
  end
end

local function AutoBuyItemsAtMerchant(frame)
  if InCombatLockdown and InCombatLockdown() then return end
  if type(frame) ~= "table" then return end

  local NormalizeSV = ns.NormalizeSV
  if type(NormalizeSV) == "function" then
    NormalizeSV()
  end

  local debugSetting = _G.fr0z3nUI_QuestTracker_Acc
    and _G.fr0z3nUI_QuestTracker_Acc.settings
    and _G.fr0z3nUI_QuestTracker_Acc.settings.debugAutoBuy == true
  local debug = debugSetting and true or false
  local function Debug(msg)
    if not debug then return end
    if type(Print) == "function" then
      Print("AutoBuy: " .. tostring(msg))
    end
  end

  frame._autoBuyBaselineHave = (type(frame._autoBuyBaselineHave) == "table") and frame._autoBuyBaselineHave or {}
  frame._autoBuySessionBought = (type(frame._autoBuySessionBought) == "table") and frame._autoBuySessionBought or {}
  frame._autoBuyPlanned = (type(frame._autoBuyPlanned) == "table") and frame._autoBuyPlanned or {}

  local function IsMerchantSessionOpen()
    if frame and frame._merchantOpen == true then return true end
    local mf = rawget(_G, "MerchantFrame")
    if mf and mf.IsShown and mf:IsShown() then return true end
    return false
  end

  local function CanRetry()
    if not IsMerchantSessionOpen() then return false end
    local attempts = tonumber(frame and frame._autoBuyAttempts) or 0
    return attempts < 12
  end

  local function ScheduleRetry(delay, reason)
    if not (C_Timer and C_Timer.After) then return end
    if not CanRetry() then
      Debug("retry blocked (merchant closed or attempts exceeded)")
      return
    end
    if frame and frame._autoBuyRetryPending then
      return
    end
    frame._autoBuyRetryPending = true
    frame._autoBuyAttempts = (tonumber(frame._autoBuyAttempts) or 0) + 1
    Debug("scheduled retry in " .. tostring(delay) .. "s" .. (reason and (" (" .. tostring(reason) .. ")") or ""))
    C_Timer.After(tonumber(delay) or 0.2, function()
      if frame then frame._autoBuyRetryPending = nil end
      if IsMerchantSessionOpen() then
        AutoBuyItemsAtMerchant(frame)
      end
    end)
  end

  local function ResolveMerchantAPI()
    local cmf = rawget(_G, "C_MerchantFrame")
    if type(cmf) == "table" and type(cmf.GetItemInfo) == "function" then
      local getNum = cmf.GetNumItems or cmf.GetNumMerchantItems
      if type(getNum) == "function" then
        return {
          kind = "C_MerchantFrame",
          getNum = function() return getNum() end,
          getInfo = function(index) return cmf.GetItemInfo(index) end,
        }
      end

      return {
        kind = "C_MerchantFrame(probe)",
        getNum = function()
          local maxProbe = 200
          local count = 0
          local sawAny = false
          for i = 1, maxProbe do
            local ok, info = pcall(cmf.GetItemInfo, i)
            if ok and type(info) == "table" then
              sawAny = true
              count = i
            else
              if sawAny then
                break
              end
            end
          end
          return count
        end,
        getInfo = function(index) return cmf.GetItemInfo(index) end,
      }
    end

    local getNumFn = rawget(_G, "GetMerchantNumItems") or rawget(_G, "GetNumMerchantItems")
    local getInfoFn = rawget(_G, "GetMerchantItemInfo")
    local getLinkFn = rawget(_G, "GetMerchantItemLink")
    if type(getNumFn) == "function" and type(getInfoFn) == "function" then
      return {
        kind = "legacy",
        getNum = function() return getNumFn() end,
        getInfo = function(index)
          local name, texture, price, quantity, numAvailable, isPurchasable, isUsable, extendedCost = getInfoFn(index)
          local link = (type(getLinkFn) == "function") and getLinkFn(index) or nil
          return {
            name = name,
            texture = texture,
            price = price,
            quantity = quantity,
            stackCount = quantity,
            numAvailable = numAvailable,
            isPurchasable = isPurchasable,
            isUsable = isUsable,
            extendedCost = extendedCost,
            hasExtendedCost = extendedCost,
            itemLink = link,
          }
        end,
      }
    end

    local candidates
    for k, v in pairs(_G) do
      if type(k) == "string" and k:find("Merchant") and type(v) == "table" then
        local getInfo = v.GetItemInfo or v.GetMerchantItemInfo
        local getNum = v.GetNumItems or v.GetNumMerchantItems
        if type(getInfo) == "function" and type(getNum) == "function" then
          return {
            kind = k,
            getNum = function() return getNum() end,
            getInfo = function(index) return getInfo(index) end,
          }
        end
        if debug then
          candidates = candidates or {}
          if (v.GetItemInfo or v.GetMerchantItemInfo or v.GetNumItems or v.GetNumMerchantItems) then
            candidates[#candidates + 1] = k
          end
        end
      end
    end

    if debug and candidates and candidates[1] then
      table.sort(candidates)
      if #candidates > 25 then
        local trimmed = {}
        for i = 1, 25 do trimmed[i] = candidates[i] end
        candidates = trimmed
      end
      Debug("merchant namespace candidates: " .. table.concat(candidates, ", "))
    end

    return nil
  end

  local api = ResolveMerchantAPI()
  if not api then
    Debug("Merchant API missing (no supported namespace/functions found)")
    return
  end
  Debug("merchant api=" .. tostring(api.kind))

  local GetNumMerchantItems = api.getNum
  local GetMerchantItemInfoSafe = api.getInfo

  if not (C_Item and C_Item.GetItemCount) then
    Debug("C_Item.GetItemCount missing")
    return
  end

  if type(ns.EnsureDefaultRulesMigrated) == "function" then ns.EnsureDefaultRulesMigrated() end
  if type(ns.EnsureRulesNormalized) == "function" then ns.EnsureRulesNormalized() end

  local GetEffectiveRules = ns.GetEffectiveRules
  if type(GetEffectiveRules) ~= "function" then return end

  local rules = GetEffectiveRules()
  if type(rules) ~= "table" or not rules[1] then
    Debug("no rules")
    return
  end

  Debug("rules=" .. tostring(#rules))

  local BuildRuleStatus = ns.BuildRuleStatus
  local IsRuleDisabled = ns.IsRuleDisabled
  local GetStandingIDByFactionID = ns.GetStandingIDByFactionID

  local function IsBlockedByExaltedSell(rule)
    if type(rule) ~= "table" then return false end
    if type(rule.rep) ~= "table" then return false end
    if rule.rep.sellWhenExalted ~= true then return false end
    local factionID = tonumber(rule.rep.factionID)
    if not factionID or factionID <= 0 then return false end
    if type(GetStandingIDByFactionID) ~= "function" then return false end
    local standingID = GetStandingIDByFactionID(factionID)
    return (standingID and standingID >= 8) and true or false
  end

  local wantByItemID = {}
  local wantCheapestGroups = {}

  local function MergeBuySpec(dst, src)
    if type(dst) ~= "table" then dst = {} end
    if type(src) ~= "table" then return dst end

    local function pickMax(a, b)
      a = tonumber(a) or 0
      b = tonumber(b) or 0
      return (b > a) and b or a
    end

    dst.max = pickMax(dst.max, src.max)
    dst.min = pickMax(dst.min, src.min)
    dst.target = pickMax(dst.target, src.target)

    local yieldItemID = tonumber(src.yieldItemID)
    local yieldCount = tonumber(src.yieldCount)
    if yieldItemID and yieldItemID > 0 then
      dst.yieldItemID = yieldItemID
      dst.yieldCount = (yieldCount and yieldCount > 0) and yieldCount or (tonumber(dst.yieldCount) or 1)
      if dst.yieldCount <= 0 then dst.yieldCount = 1 end
    end

    if src.cachePurchased == true then
      dst.cachePurchased = true
    end
    if src.cachePurchasedFromBag == false then
      dst.cachePurchasedFromBag = false
    end
    if src.knownTooltip == true then
      dst.knownTooltip = true
      dst.cachePurchased = true
    end
    return dst
  end

  local function NormalizeIDList(t)
    local tmp = {}
    if type(t) == "table" then
      for _, v in pairs(t) do
        local id = tonumber(v)
        if id and id > 0 then
          tmp[#tmp + 1] = id
        end
      end
    end
    if not tmp[1] then return nil end
    table.sort(tmp)
    local out = {}
    local last
    for i = 1, #tmp do
      local id = tmp[i]
      if id ~= last then
        out[#out + 1] = id
        last = id
      end
    end
    return out
  end

  for _, rule in ipairs(rules) do
    if type(rule) == "table" and type(IsRuleDisabled) == "function" and not IsRuleDisabled(rule) then
      local blockedByExaltedSell = IsBlockedByExaltedSell(rule)
      local ruleCompleted = false
      if (not blockedByExaltedSell) and type(BuildRuleStatus) == "function" then
        local status = BuildRuleStatus(rule, nil, { forceNormalVisibility = true })
        ruleCompleted = (type(status) == "table" and status.completed == true)
      end

      if type(rule.item) == "table" then
        local buy = rule.item.buy
        if type(buy) == "table" and buy.enabled == true and not blockedByExaltedSell and not ruleCompleted then
          local itemID = tonumber(rule.item.itemID)
          local maxQty = tonumber(buy.max) or 0
          local minQty = tonumber(buy.min) or 0
          local targetQty = tonumber(buy.target) or 0

          local yieldItemID = tonumber(buy.yieldItemID)
          local yieldCount = tonumber(buy.yieldCount)

          if itemID and itemID > 0 and maxQty and maxQty > 0 then
            local spec = {
              max = maxQty,
              min = minQty,
              target = targetQty,
              yieldItemID = yieldItemID,
              yieldCount = yieldCount,
              cachePurchased = (rule.item.cachePurchased == true) and true or false,
              cachePurchasedFromBag = (rule.item.cachePurchasedFromBag == false) and false or true,
              knownTooltip = (rule.item.knownTooltip == true) and true or false,
            }
            if spec.knownTooltip then
              spec.cachePurchased = true
            end

            local cheapestIDs = NormalizeIDList(buy.cheapestOf)
            if cheapestIDs and cheapestIDs[1] then
              cheapestIDs[#cheapestIDs + 1] = itemID
              cheapestIDs = NormalizeIDList(cheapestIDs)
              local key = table.concat(cheapestIDs, ",")
              wantCheapestGroups[key] = wantCheapestGroups[key] or { ids = cheapestIDs, max = 0, min = 0, target = 0 }
              MergeBuySpec(wantCheapestGroups[key], spec)
            else
              wantByItemID[itemID] = MergeBuySpec(wantByItemID[itemID], spec)
            end
          end
        end
      end

      if rule.autoBuyShopping == true and type(rule.shopping) == "table" and rule.shopping[1] ~= nil and rule.questID ~= nil then
        if type(BuildRuleStatus) == "function" then
          local status = BuildRuleStatus(rule, nil, { forceNormalVisibility = true })
          if status and status.completed ~= true then
            for _, it in ipairs(rule.shopping) do
              if type(it) == "table" and it.buy == true then
                local itemID = tonumber(it.itemID or it.id)
                local req = tonumber(it.required or it.count or it.need)
                if itemID and itemID > 0 and req and req > 0 then
                  wantByItemID[itemID] = MergeBuySpec(wantByItemID[itemID], { max = req, target = req, min = 0 })
                end
              end
            end
          end
        end
      end
    end
  end

  if not (next(wantByItemID) or next(wantCheapestGroups)) then return end

  do
    local sample = {}
    for id, spec in pairs(wantByItemID) do
      sample[#sample + 1] = tostring(id) .. "->" .. tostring(spec and spec.max or 0)
      if #sample >= 8 then break end
    end
    table.sort(sample)
    Debug("wantByItemID sample=" .. table.concat(sample, ", "))
  end

  local function GetItemIDFromMerchantInfo(info, merchantIndex)
    if type(info) ~= "table" then return nil end

    local function ItemIDFromLink(link)
      if type(link) ~= "string" or link == "" then return nil end
      if C_Item and C_Item.GetItemInfoInstant then
        local ok, iid = pcall(function()
          return select(1, C_Item.GetItemInfoInstant(link))
        end)
        iid = ok and tonumber(iid) or nil
        if iid and iid > 0 then return iid end
      end
      local iid = tonumber((tostring(link):match("item:(%d+)") or ""))
      if iid and iid > 0 then return iid end
      return nil
    end

    local itemID = tonumber(info["itemID"] or info["itemId"] or info["itemid"])
    if itemID and itemID > 0 then return itemID end

    local link = info["itemLink"] or info["link"] or info["hyperlink"]
    if type(link) == "string" and link ~= "" then
      local iid = ItemIDFromLink(link)
      if iid and iid > 0 then return iid end
      if C_Item and C_Item.GetItemIDForItemInfo then
        local ok, iid2 = pcall(C_Item.GetItemIDForItemInfo, link)
        iid2 = ok and tonumber(iid2) or nil
        if iid2 and iid2 > 0 then return iid2 end
      end
    end

    if type(GetMerchantItemLink) == "function" and merchantIndex then
      local ok, l2 = pcall(GetMerchantItemLink, merchantIndex)
      local iid3 = ok and ItemIDFromLink(l2) or nil
      if iid3 and iid3 > 0 then return iid3 end
    end

    return nil
  end

  local okN, n = pcall(GetNumMerchantItems)
  n = (okN and tonumber(n)) or 0
  if n <= 0 then
    Debug("merchant has 0 items; will retry")
    ScheduleRetry(0.25, "merchant has 0 items")
    return
  end

  Debug("merchant items=" .. tostring(n))

  local merchantIndexByItemID = {}
  local merchantInfoByIndex = {}
  local missingItemID = 0
  for i = 1, n do
    local okInfo, info = pcall(GetMerchantItemInfoSafe, i)
    if okInfo and type(info) == "table" then
      local itemID = GetItemIDFromMerchantInfo(info, i)
      if itemID and itemID > 0 then
        local prev = merchantIndexByItemID[itemID]
        if not prev then
          merchantIndexByItemID[itemID] = i
        else
          local prevInfo = merchantInfoByIndex[prev]
          local prevPrice = (type(prevInfo) == "table") and (tonumber(prevInfo["price"]) or 0) or 0
          local newPrice = tonumber(info["price"]) or 0
          if newPrice < prevPrice then
            merchantIndexByItemID[itemID] = i
          end
        end
        merchantInfoByIndex[i] = info
      else
        missingItemID = missingItemID + 1
      end
    end
  end

  if not next(merchantIndexByItemID) then
    Debug("merchant itemID map empty; missingItemID=" .. tostring(missingItemID))
    ScheduleRetry(0.25, "itemID map empty")
    return
  end

  do
    local missingWants = 0
    for itemID in pairs(wantByItemID) do
      if not merchantIndexByItemID[itemID] then
        missingWants = missingWants + 1
        if missingWants >= 3 then break end
      end
    end
    if missingWants > 0 then
      Debug("merchant missing " .. tostring(missingWants) .. " wanted itemIDs; will retry")
      ScheduleRetry(0.25, "wanted itemID not mapped")
    end
  end

  local function CanBuyFromMerchantInfo(info)
    if type(info) ~= "table" then return false end
    local isPurchasable = (info["isPurchasable"] ~= false)
    local extendedCost = (info["extendedCost"] == true) or (info["hasExtendedCost"] == true)
    return (isPurchasable and not extendedCost) and true or false
  end

  local function GetRawHaveCount(itemID)
    local have = 0
    local okCount, c = pcall(C_Item.GetItemCount, itemID, false, false, false)
    have = (okCount and tonumber(c)) or 0
    if have < 0 then have = 0 end
    return have
  end

  local function ScheduleAutoBuyReport(delay, reason)
    if not (C_Timer and C_Timer.NewTimer) then return end
    delay = tonumber(delay) or 0.35
    if not IsMerchantSessionOpen() then return end

    if frame._autoBuyReportTimer then
      frame._autoBuyReportTimer:Cancel()
      frame._autoBuyReportTimer = nil
    end

    frame._autoBuyReportAttempts = (tonumber(frame._autoBuyReportAttempts) or 0) + 1
    Debug("scheduled report in " .. tostring(delay) .. "s" .. (reason and (" (" .. tostring(reason) .. ")") or ""))

    frame._autoBuyReportTimer = C_Timer.NewTimer(delay, function()
      frame._autoBuyReportTimer = nil
      if not IsMerchantSessionOpen() then return end

      local planned = frame._autoBuyPlanned
      if type(planned) ~= "table" or not next(planned) then return end

      local parts = {}
      local pending = false

      for itemID, plannedCount in pairs(planned) do
        itemID = tonumber(itemID)
        plannedCount = tonumber(plannedCount) or 0
        if itemID and itemID > 0 and plannedCount > 0 then
          local base = frame._autoBuyBaselineHave and frame._autoBuyBaselineHave[itemID] or nil
          if base == nil then
            base = GetRawHaveCount(itemID)
            if frame._autoBuyBaselineHave then
              frame._autoBuyBaselineHave[itemID] = base
            end
          end

          local rawNow = GetRawHaveCount(itemID)
          local got = rawNow - (tonumber(base) or 0)
          if got < 0 then got = 0 end

          if got < plannedCount then
            pending = true
          end

          if got > 0 then
            local name
            if C_Item and C_Item.GetItemNameByID then
              local ok, n2 = pcall(C_Item.GetItemNameByID, itemID)
              if ok and n2 and n2 ~= "" then
                name = n2
              end
            end
            parts[#parts + 1] = tostring(got) .. "x " .. tostring(name or ("itemID:" .. tostring(itemID)))
          end
        end
      end

      if pending then
        local attempts = tonumber(frame._autoBuyReportAttempts) or 0
        if attempts < 10 then
          ScheduleAutoBuyReport(0.25, "waiting for bag counts")
          return
        end
      end

      if not parts[1] then
        frame._autoBuyPlanned = {}
        frame._autoBuyReportAttempts = 0
        return
      end

      table.sort(parts)
      local key = table.concat(parts, ", ")
      if frame._autoBuyLastReportKey == key then
        frame._autoBuyPlanned = {}
        frame._autoBuyReportAttempts = 0
        return
      end

      frame._autoBuyLastReportKey = key
      frame._autoBuyPlanned = {}
      frame._autoBuyReportAttempts = 0

      if type(Print) == "function" then
        Print("Bought (Auto): " .. key)
      end
    end)
  end

  local function GetHaveCount(itemID, spec)
    itemID = tonumber(itemID)
    if not itemID or itemID <= 0 then return 0 end

    local raw = GetRawHaveCount(itemID)

    if type(spec) == "table" and spec.cachePurchased == true then
      if raw > 0 and spec.cachePurchasedFromBag ~= false and type(ns.MarkItemCachedPurchased) == "function" then
        ns.MarkItemCachedPurchased(itemID)
      end
      if type(ns.IsItemCachedPurchased) == "function" and ns.IsItemCachedPurchased(itemID) then
        raw = math.max(raw, 1)
      end
    end

    local base = frame._autoBuyBaselineHave[itemID]
    if base == nil then
      base = raw
      frame._autoBuyBaselineHave[itemID] = base
    end

    local bought = tonumber(frame._autoBuySessionBought[itemID]) or 0
    local expected = (tonumber(base) or 0) + bought

    local have = raw
    if expected > have then
      have = expected
    end
    return have
  end

  local function GetEffectiveHaveForSpec(spec, itemIDs)
    if type(spec) ~= "table" then return 0 end
    if type(itemIDs) ~= "table" or not itemIDs[1] then
      local itemID = tonumber(spec.itemID)
      return (itemID and itemID > 0) and GetHaveCount(itemID, spec) or 0
    end

    local yieldItemID = tonumber(spec.yieldItemID)
    local yieldCount = tonumber(spec.yieldCount) or 1
    if yieldCount <= 0 then yieldCount = 1 end

    if yieldItemID and yieldItemID > 0 then
      local haveYield = GetHaveCount(yieldItemID, spec)
      local haveContainers = 0
      for i = 1, #itemIDs do
        local id = tonumber(itemIDs[i])
        if id and id > 0 and id ~= yieldItemID then
          haveContainers = haveContainers + GetHaveCount(id, spec)
        end
      end
      return haveYield + (haveContainers * yieldCount)
    end

    local haveTotal = 0
    for i = 1, #itemIDs do
      haveTotal = haveTotal + GetHaveCount(itemIDs[i], spec)
    end
    return haveTotal
  end

  local function ComputeNeed(spec, have)
    if type(spec) ~= "table" then return 0 end
    local maxQty = tonumber(spec.max) or 0
    local minQty = tonumber(spec.min) or 0
    local targetQty = tonumber(spec.target) or 0
    if maxQty <= 0 then return 0 end
    if have < 0 then have = 0 end

    local desired = (targetQty > 0) and targetQty or ((minQty > 0) and minQty or maxQty)
    if desired > maxQty then desired = maxQty end
    local need = desired - have
    if need < 0 then need = 0 end
    return need
  end

  local function BuyFromMerchant(merchantIndex, info, itemID, need)
    itemID = tonumber(itemID)
    if not itemID or itemID <= 0 then return end
    if need <= 0 then return end
    if not (merchantIndex and info) then return end

    local buyCount = math.floor(tonumber(need) or 0)
    if buyCount <= 0 then return end

    local numAvailable = tonumber(info["numAvailable"])
    if numAvailable and numAvailable >= 0 then
      buyCount = math.min(buyCount, numAvailable)
    end

    local price = tonumber(info["price"]) or 0
    if price > 0 and type(GetMoney) == "function" then
      local money = tonumber(GetMoney()) or 0
      buyCount = math.min(buyCount, math.floor(money / price))
    end

    if buyCount > 200 then buyCount = 200 end

    if buyCount > 0 then
      if frame._autoBuyBaselineHave and frame._autoBuyBaselineHave[itemID] == nil then
        frame._autoBuyBaselineHave[itemID] = GetRawHaveCount(itemID)
      end
      local remaining = buyCount
      while remaining > 0 do
        local chunk = math.min(remaining, 100)
        BuyMerchantItem(merchantIndex, chunk)
        remaining = remaining - chunk
      end
      frame._autoBuySessionBought[itemID] = (tonumber(frame._autoBuySessionBought[itemID]) or 0) + buyCount
      frame._autoBuyPlanned[itemID] = (tonumber(frame._autoBuyPlanned[itemID]) or 0) + buyCount
      frame._autoBuyReportAttempts = 0
      ScheduleAutoBuyReport(0.35, "post-purchase")

      if debug then
        Debug(string.format("buy: idx=%s itemID=%s need=%s buy=%s", tostring(merchantIndex), tostring(itemID), tostring(need), tostring(buyCount)))
      end
    end
  end

  for _, g in pairs(wantCheapestGroups) do
    if type(g) == "table" and type(g.ids) == "table" and g.ids[1] then
      local chosenItemID
      local chosenIndex
      local chosenInfo
      local chosenPrice

      for i = 1, #g.ids do
        local id = g.ids[i]
        local idx = merchantIndexByItemID[id]
        if idx then
          local info = merchantInfoByIndex[idx]
          if CanBuyFromMerchantInfo(info) then
            local price = tonumber(info["price"]) or 0
            if (chosenItemID == nil) or (price < (chosenPrice or 0)) or (price == (chosenPrice or 0) and id < chosenItemID) then
              chosenItemID = id
              chosenIndex = idx
              chosenInfo = info
              chosenPrice = price
            end
          end
        end
      end

      if chosenItemID and chosenIndex and chosenInfo then
        if g.knownTooltip == true and type(ns.MerchantItemIsAlreadyKnown) == "function" and ns.MerchantItemIsAlreadyKnown(chosenIndex) then
          if type(ns.MarkItemCachedPurchased) == "function" then ns.MarkItemCachedPurchased(chosenItemID) end
        end
        local haveTotal = GetEffectiveHaveForSpec(g, g.ids)
        local need = ComputeNeed(g, haveTotal)
        if need > 0 then
          local yieldItemID = tonumber(g.yieldItemID)
          local yieldCount = tonumber(g.yieldCount) or 1
          if yieldCount <= 0 then yieldCount = 1 end

          if yieldItemID and yieldItemID > 0 then
            local maxQty = tonumber(g.max) or 0
            local capacity = maxQty - haveTotal
            if capacity < yieldCount then
              need = 0
            else
              local purchasesNeeded = math.floor((need + yieldCount - 1) / yieldCount)
              local maxPurchases = math.floor(capacity / yieldCount)
              need = math.min(purchasesNeeded, maxPurchases)
            end
          end

          if need > 0 then
            Debug(string.format("cheapestOf: chose itemID=%d price=%s need=%d", chosenItemID, tostring(chosenPrice), need))
            BuyFromMerchant(chosenIndex, chosenInfo, chosenItemID, need)
            if type(ns.SchedulePostBuyCacheCheck) == "function" then
              ns.SchedulePostBuyCacheCheck(chosenItemID, chosenIndex, g)
            end
          end
        end
      end
    end
  end

  for itemID, spec in pairs(wantByItemID) do
    local merchantIndex = merchantIndexByItemID[itemID]
    if merchantIndex then
      local info = merchantInfoByIndex[merchantIndex]
      if CanBuyFromMerchantInfo(info) then
        if spec.knownTooltip == true and type(ns.MerchantItemIsAlreadyKnown) == "function" and ns.MerchantItemIsAlreadyKnown(merchantIndex) then
          if type(ns.MarkItemCachedPurchased) == "function" then ns.MarkItemCachedPurchased(itemID) end
        end

        local have = GetHaveCount(itemID, spec)
        local need = ComputeNeed(spec, have)

        local yieldItemID = tonumber(spec.yieldItemID)
        local yieldCount = tonumber(spec.yieldCount) or 1
        if yieldCount <= 0 then yieldCount = 1 end
        if yieldItemID and yieldItemID > 0 then
          local maxQty = tonumber(spec.max) or 0
          local capacity = maxQty - have
          if capacity < yieldCount then
            need = 0
          else
            local purchasesNeeded = math.floor((need + yieldCount - 1) / yieldCount)
            local maxPurchases = math.floor(capacity / yieldCount)
            need = math.min(purchasesNeeded, maxPurchases)
          end
        end

        if need > 0 then
          BuyFromMerchant(merchantIndex, info, itemID, need)
          if type(ns.SchedulePostBuyCacheCheck) == "function" then
            ns.SchedulePostBuyCacheCheck(itemID, merchantIndex, spec)
          end
        end
      end
    end
  end

  if not (frame._autoBuyPlanned and next(frame._autoBuyPlanned)) then return end

  ScheduleRetry(0.25, "post-purchase refresh")
  ScheduleAutoBuyReport(0.35, "post-purchase")
end

local function OnMerchantShow(frame)
  if type(frame) ~= "table" then return end

  frame._didDumpMerchantInfoKeys = nil
  frame._merchantOpen = true
  frame._autoBuyRetryPending = nil
  frame._autoBuyAttempts = 0
  frame._autoBuyBaselineHave = {}
  frame._autoBuySessionBought = {}
  frame._autoBuyPlanned = {}
  frame._autoBuyLastReportKey = nil
  frame._autoBuyReportAttempts = 0
  if frame._autoBuyReportTimer then
    frame._autoBuyReportTimer:Cancel()
    frame._autoBuyReportTimer = nil
  end

  AutoSellItemsAtMerchant()
  AutoBuyItemsAtMerchant(frame)
end

local function OnMerchantClosed(frame)
  if type(frame) ~= "table" then return end

  frame._merchantOpen = nil
  frame._autoBuyRetryPending = nil
  frame._autoBuyAttempts = nil
  frame._autoBuyBaselineHave = nil
  frame._autoBuySessionBought = nil
  frame._autoBuyPlanned = nil
  frame._autoBuyLastReportKey = nil
  frame._autoBuyReportAttempts = nil
  if frame._autoBuyReportTimer then
    frame._autoBuyReportTimer:Cancel()
    frame._autoBuyReportTimer = nil
  end
  if frame._autoBuyUpdateTimer then
    frame._autoBuyUpdateTimer:Cancel()
    frame._autoBuyUpdateTimer = nil
  end
end

local function OnMerchantUpdate(frame)
  if InCombatLockdown and InCombatLockdown() then return end
  if type(frame) ~= "table" then return end
  if frame._autoBuyUpdateTimer then return end
  if not (C_Timer and C_Timer.NewTimer) then return end

  frame._autoBuyUpdateTimer = C_Timer.NewTimer(0.15, function()
    frame._autoBuyUpdateTimer = nil
    if frame._merchantOpen == true then
      AutoBuyItemsAtMerchant(frame)
    end
  end)
end

ns.Merchant = ns.Merchant or {}
ns.Merchant.AutoSellItemsAtMerchant = AutoSellItemsAtMerchant
ns.Merchant.AutoBuyItemsAtMerchant = AutoBuyItemsAtMerchant
ns.Merchant.OnMerchantShow = OnMerchantShow
ns.Merchant.OnMerchantClosed = OnMerchantClosed
ns.Merchant.OnMerchantUpdate = OnMerchantUpdate
