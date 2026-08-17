local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB10 (Dragonflight)

ns.rules = ns.rules or {}

local EXPANSION_ID = 10
local EXPANSION_NAME = "Dragonflight"

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

{label = "SU  10  Dragon Isles  Q-67700  65445  Horde", frameID = "list1", key = "custom:q:67700:list1:XP10085",
questID = 67700, prereq = { 30515, }, hideWhenCompleted = true,
questInfo = "Dragon Isles  (H)\n + Use Dragon Scale\n    or Cata Portal Area\n + Do Initial Quests\n + Take Portal\n ",
faction = "Horde", },

{label = "SU  10  Dragon Isles  Q-67700  65444  Alliance", frameID = "list1", key = "custom:q:67700:list1:XP10086",
questID = 67700, prereq = { 30515, }, hideWhenCompleted = true,
questInfo = "Dragon Isles\n + Use Dragon Scale\n    or Castle Balcony\n + Do Initial Quests\n + Take Portal\n ",
faction = "Alliance", },

{label = "SU  10  Dragon Isles  34 Slot Bag", frameID = "list1", key = "custom:q:65646:list1:XP10084",
questID = 65646, hideWhenCompleted = true,
questInfo = "Dragon Isles\n + 34 Slot Bag\n   - Waking Shore 58,53", rested = true , }, -- prereq = { 67700, }, 

{label = "SU  11  N  01  Q-82819  AQ-  34 Slot Bag", frameID = "list1", key = "custom:q:82819:list1:XP11071",
questID = 82819, prereq = { 65646, }, hideWhenCompleted = true,
questInfo = "War Within\n + 34 Slot Bag (1)  3-4-1-2\n   - Camp Murroch, Ringing Deeps", rested = true , },

{label = "SU  11  N  01  Q-81972  AQ-82819  34 Slot Bag", frameID = "list1", key = "custom:q:81972:list1:XP11070",
questID = 81972, prereq = { 65646, 82819, }, hideWhenCompleted = true,
questInfo = "The War Within\n + 34 Slot Bag (2)\n   - Priory, Hallowfall 30, 38", rested = true , }, --prereq = { 82819, }, 



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
