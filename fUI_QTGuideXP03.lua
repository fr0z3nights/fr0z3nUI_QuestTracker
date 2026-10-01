local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB03 (Wrath of the Lich King)

ns.rules = ns.rules or {}

local EXPANSION_ID = 3
local EXPANSION_NAME = "Wrath of the Lich King"

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

{label = "Kirin Tor Ring",            frameID = "list1", key = "XP03:Port:KirinTor",      playerLevel = { ">", 80, }, mapID = {84,85,125,}, gold = 9500, complete = { any = { { itemIDs = {40586,44935,40585,44934,45688,45690,45691,45689,48954,48955,48956,48957,51557,51558,51559,51560,}, includeBank = true }, }, },  itemInfo = "Kirin Tor Ring\n + 8500 |TInterface\\MoneyFrame\\UI-GoldIcon:16:16:0:0|t",  },
{label = "Argent Crusader's Tabard",  frameID = "list1", key = "XP03:Port:ArgentTabard",  playerLevel = { ">", 80, }, mapID = {84,85,125,}, item = { itemID = 46874, required = { 1, Y, N, 0 }, currencyID = { 241, 50 }, },                                                                                                itemInfo = "Argent Crusader's Tabard\n+ WBT $nm $cc / $rq ($wb)", },



-- itemInfo = "Orgrimmar Tabard", 
-- mapID = "999999", 
--                                                                                                                                       -- mapIDs: fUI_QTUsage.lua

--	charLI = "Name-Realm" (or {list}): only shows while logged in on that character

	{key = "XPPB:Q-31934",	questID = 31934,	charLI = "Shadowyclawz-Frostmourne",	label = "APB Gutretch",				frameID = "list2",	hideDone = true,	questInfo = ".\nGutretch\nZul'Drak",													font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XPPB:Q-31932",	questID = 31932,	charLI = "Shadowsmashr-Caelestrasz",	label = "APB Nearly Headless Jacob",frameID = "list2",	hideDone = true,	questInfo = ".\nNearly Headless Jacob\nCrystalsong Forest",													font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XPPB:Q-31935",	questID = 31935,	charLI = "Bullseyekick-Dath'Remar",		label = "APB Major Payne",			frameID = "list2",	hideDone = true,	questInfo = ".\nMajor Payne\nIcecrown",													font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XPPB:Q-31933",	questID = 31933,	charLI = "Bullseyeshot-Frostmourne",	label = "APB Okrut Dragonwaste",	frameID = "list2",	hideDone = true,	questInfo = ".\nOkrut Dragonwaste\nDragonblight",													font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },
	{key = "XPPB:Q-31931",	questID = 31931,	charLI = "Frozenlegion-Caelestrasz",	label = "APB Beegle Blastfuse",		frameID = "list2",	hideDone = true,	questInfo = ".\nBeegle Blastfuse\nHowling Fjord",													font = "lsm:Bazooka", size = 15, color = "ffe633", align = "center", list = "bottom", },












}


bakedRules = ns.GuideHelpers.ExpandQuestGroups(bakedRules)
for i = 1, #bakedRules do
  local r = bakedRules[i]
  if type(r) == "table" and not r.questGroup then
    ns.GuideHelpers.NormalizeRule(r, EXPANSION_ID, EXPANSION_NAME)
    ns.rules[#ns.rules + 1] = r
  end
end
