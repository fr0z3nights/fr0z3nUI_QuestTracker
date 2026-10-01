local addonName, ns = ...

-- Expansion DB02 (The Burning Crusade)

ns.rules = ns.rules or {}

local EXPANSION_ID = 2
local EXPANSION_NAME = "The Burning Crusade"

local Y, N = true, false
local M = "mustHave"

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

--                                                                                                                                       -- mapIDs: fUI_QTUsage.lua
--	charLI = "Name-Realm" (or {list}): only shows while logged in on that character
	{key = "XPPB:Q-31922",	questID = 31922,	charLI = "Bullseyeshot-Barthilas",		label = "APB Nicki Tinytech",		frameID = "list2",	hideDone = true,	questInfo = ".\nNicki Tinytech\nHellfire, Outland",													font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XPPB:Q-31924",	questID = 31924,	charLI = "Frozenlegion-Frostmourne",	label = "APB Narrok",				frameID = "list2",	hideDone = true,	questInfo = ".\nNarrok\nNagrand, Outland",													font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XPPB:Q-31926",	questID = 31926,	charLI = "Shadowswings-Caelestrasz",	label = "APB Bloodknight Antari",	frameID = "list2",	hideDone = true,	questInfo = ".\nBloodknight Antari\nShadowmoon, Outland",													font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XPPB:Q-31925",	questID = 31925,	charLI = "Shadowardenz-Dath'Remar",		label = "APB Morulu The Elder",		frameID = "list2",	hideDone = true,	questInfo = ".\nMorulu The Elder\nShattrath, Outland",													font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XPPB:Q-31923",	questID = 31923,	charLI = "Shadowizards-Barthilas",		label = "APB Ras'an",				frameID = "list2",	hideDone = true,	questInfo = ".\nRas'an\nZangarmarsh, Outland",													font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },





}


bakedRules = ns.GuideHelpers.ExpandQuestGroups(bakedRules)
for i = 1, #bakedRules do
  local r = bakedRules[i]
  if type(r) == "table" and not r.questGroup then
    ns.GuideHelpers.NormalizeRule(r, EXPANSION_ID, EXPANSION_NAME)
    ns.rules[#ns.rules + 1] = r
  end
end
