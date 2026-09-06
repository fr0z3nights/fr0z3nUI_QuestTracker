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

--  84    Stormwind City
--  85    Orgrimmar
--  2022  The Waking Shores
--  2112  Valdrakken (Dragon Isles Capital)

--                                                                                                                                       -- mapIDs: fUI_QTUsage.lua
	{key = "XP10:Q67700A",  questID = 67700, prereq = {30515,}, faction = "A",  label = "10  Dragon Isles A", frameID = "list1",  hideDone = true, mapID = {84,85,2022,2112,},  questInfo = "Dragon Isles\n + The Waking Shores (Zygor)\n + Cata Portal Balcony\n + Do Initial Quests\n + Take Portal", },
	{key = "XP10:Q67700H",  questID = 67700, prereq = {30515,}, faction = "H",  label = "10  Dragon Isles H", frameID = "list1",  hideDone = true, mapID = {84,85,2022,2112,},  questInfo = "Dragon Isles\n + The Waking Shores (Zygor)\n + Cata Portal Area   \n + Do Initial Quests\n + Take Portal", },
	{key = "XP10:Q65646",   questID = 65646,                                    label = "10  34 Slot Bag",    frameID = "list1",  hideDone = true, rested = true,               questInfo = "Dragon Isles\n + Misty Satchel BH Waterfall\n - Waking Shores @ 58,53", },




}


for i = 1, #bakedRules do
  local r = bakedRules[i]
  if type(r) == "table" then
    ns.GuideHelpers.NormalizeRule(r, EXPANSION_ID, EXPANSION_NAME)
    ns.rules[#ns.rules + 1] = r
  end
end
