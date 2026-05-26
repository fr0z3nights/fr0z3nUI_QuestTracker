local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB00 (Unknown/Unclassified)

ns.rules = ns.rules or {}

local EXPANSION_ID = 0
local EXPANSION_NAME = "Unclassified"

local Y, N = true, false

-- Currency gates (optional):
--   item.currencyID = { currencyID, required }
-- Amount sources (Retail):
--   Character amount: C_CurrencyInfo.GetCurrencyInfo(id).quantity
--   Warband total: C_CurrencyInfo.GetAccountCharacterCurrencyData(id)
--     (requires RequestCurrencyDataForAccountCharacters() to be called earlier)
--   Transferability: C_CurrencyInfo.GetCurrencyInfo(id).isAccountTransferable
-- Notes:
--   If isAccountTransferable is true, the tracker gates using the warband total (falls back to a cached
--   account saved-variable snapshot if the live data isn't available yet).
-- Placeholders usable in itemInfo/textInfo/spellInfo:
--   {currency:name} {currency:req} {currency:char} {currency:wb} {currency} (gate amount)
-- Shorthand (DB convenience):
--   %p  -> {progress}
--   $rq -> {currency:req}
--   $nm -> {currency:name}
--   $hv -> {currency} (gate/have amount)
--   $ga -> {currency} (gate/have amount)
--   $cc -> {currency:char}
--   $wb -> {currency:wb}


-- item.required tuple keys:
--   item.required = { count, hideWhenAcquired, autoBuyEnabled, autoBuyMax }
local REQ_COUNT, REQ_HIDE, REQ_BUY_ON, REQ_BUY_MAX = 1, 2, 3, 4
local bakedRules = {


{label = "Guild Cloak A1", frameID = "bar1", showIf = { factionID = 1168, minStanding = 6 }, key = "rep:guild:alliance:cloak1",
textInfo = "|cff1eff00Guild Cloak|r", faction = "alliance", locationID = 84, complete = { any = { { itemIDs = { 63352 }, includeBank = true }, }, }, },

{label = "Guild Cloak A2", frameID = "bar1", showIf = { all = { { factionID = 1168, minStanding = 7 }, { itemIDs = { 63352 }, includeBank = true }, }, }, key = "rep:guild:alliance:cloak2",
textInfo = "|cff0070ddGuild Cloak|r", faction = "alliance", locationID = 84, complete = { any = { { itemIDs = { 63206 }, includeBank = true }, }, }, },

{label = "Guild Cloak A3", frameID = "bar1", showIf = { all = { { factionID = 1168, minStanding = 8 }, { itemIDs = { 63206 }, includeBank = true }, }, }, key = "rep:guild:alliance:cloak3",
textInfo = "|cffa335eeGuild Cloak|r", faction = "alliance", locationID = 84, complete = { any = { { itemIDs = { 65360 }, includeBank = true }, }, }, },

{label = "Guild Cloak H1", frameID = "bar1", showIf = { factionID = 1168, minStanding = 6 }, key = "rep:guild:horde:cloak1",
textInfo = "|cff1eff00Guild Cloak|r", faction = "horde", locationID = 85, complete = { any = { { itemIDs = { 63353 }, includeBank = true }, }, }, },

{label = "Guild Cloak H2", frameID = "bar1", showIf = { all = { { factionID = 1168, minStanding = 7 }, { itemIDs = { 63353 }, includeBank = true }, }, }, key = "rep:guild:horde:cloak2",
textInfo = "|cff0070ddGuild Cloak|r", faction = "horde", locationID = 85, complete = { any = { { itemIDs = { 63207 }, includeBank = true }, }, }, },

{label = "Guild Cloak H3", frameID = "bar1", showIf = { all = { { factionID = 1168, minStanding = 8 }, { itemIDs = { 63207 }, includeBank = true }, }, }, key = "rep:guild:horde:cloak3",
textInfo = "|cffa335eeGuild Cloak|r", faction = "horde", locationID = 85, complete = { any = { { itemIDs = { 65274 }, includeBank = true }, }, }, },

--  /dump C_Map.GetBestMapForUnit("player") 
--{label = "Phaze Blasted Cata", textInfo = "|cffa335eeCATACLYSM PHAZED|r", locationID = 17, frameID = "list2", questID = 66560, showIf = { completedQuestID = 66560 }, key = "zone:blastedlands:cataclysm", },
{label = "Phaze Blasted WoD",  questInfo = "|cffa335eeWARLORDS PHAZED|r",  locationID = 17, frameID = "list2", questID = 66560, key = "zone:blastedlands:warlords", }



}

for i = 1, #bakedRules do
  local r = bakedRules[i]
  if type(r) == "table" then
    if r._expansionID == nil then r._expansionID = EXPANSION_ID end
    if r._expansionName == nil then r._expansionName = EXPANSION_NAME end
    if r.questXY == nil and tonumber(r.questID) and r.qXept == nil then r.qXept = "N" end
    if type(r.key) == "string" then
      r.key = r.key:gsub("^custom:", "db:")
    end
    ns.rules[#ns.rules + 1] = r
  end
end
