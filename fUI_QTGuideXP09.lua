local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB09 (Shadowlands)

ns.rules = ns.rules or {}

local EXPANSION_ID = 9
local EXPANSION_NAME = "Shadowlands"

local Y, N = true, false

local WHITE = "ffffff"
local RED = "ff4040"
local ORANGE = "ff8c1a"
local YELLOW = "ffe633"
local GREEN = "33ff33"
local BLUE = "3399ff"
local PURPLE = "9933ff"
local CYAN = "33ffff"
local GREY = "bfbfbf"

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

{label = "SU  09  Open", faction = "alliance", frameID = "list1", key = "custom:q:60151:list1:XP09011a",
questID = 60150, hideWhenCompleted = true, hideIfAnyQuestCompleted = { 60151, 61874, 999999 },
questInfo = "Shadowlands\n + Chromie: Shadowlands\n + Enter Shadowlands\n  - Castle Entryway\n  - Skip Quests If Possible\n + Learn Professions\n ", },
--Warboard   (Accept if there)\n    - Chromie\n    - Legion\n    - Warlords\n    - Jade Forest\n\n
{label = "SU  09  Open", faction = "horde", frameID = "list1", key = "custom:q:60151:list1:XP09011h",
questID = 60150, hideWhenCompleted = true, hideIfAnyQuestCompleted = { 60151, 61874, 999999 },
questInfo = "Shadowlands\n + Chromie: Shadowlands\n + Enter Shadowlands\n  - Valley of Strength\n  - Skip Quests If Possible\n + Learn Professions\n ", },




--{label = "Warboard   (Accept if there)\n    - Chromie\n    - Legion\n    - Warlords\n    - Jade Forest\n\nShadowlands\n + Chromie: Shadowlands\n + Enter Shadowlands\n    - Skip Quests at Broker NPC\n    - Learn Professions", frameID = "list1", key = "custom:spell:list1:152",
--hideWhenCompleted = false,
--notInGroup = false,
--["notSpellKnown"] = 310542, },

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
