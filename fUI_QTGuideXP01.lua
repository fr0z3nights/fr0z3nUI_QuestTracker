local addonName, ns = ...

-- Expansion DB01 (Classic)

ns.rules = ns.rules or {}

local EXPANSION_ID = 1
local EXPANSION_NAME = "Classic"

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

-- Item fields
--   item.required = { count, hideWhenAcquired, autoBuyEnabled, autoBuyMax }
--     count = N: show the owned amount without /count
--     hideWhenAcquired = M: show only when the item is owned
--     REQ_COUNT  = 1
--     REQ_HIDE   = 2
--     REQ_BUY_ON = 3
--     REQ_BUY_MAX= 4
--   item.buy      = { enabled = Y/N, max = number }  -- mirrored to required tuple (default off)

local REQ_COUNT, REQ_HIDE, REQ_BUY_ON, REQ_BUY_MAX = 1, 2, 3, 4

local bakedRules = {

--                                                                                                                                       -- mapIDs: fUI_QTUsage.lua
-- ALLIANCE TABARDS     (Stormwind 84 - Darnassus 89)
	{key = "XP01:I-45574",	group = "XP01:ATabards", order = 1, label = "Tabard Stormwind ",	faction = "A", frameID = "list1", itemInfo = "Stormwind Tabard",		item = { itemID = 45574, required = { 1, Y, Y, 1 }, }, rep = { sellWhenExalted = Y, factionID =   72, }, mapID = {84},				complete = { any = { { item = { itemID = 45574, count = 1 } }, { rep = { factionID =   72, minStanding = 8 } }, }, }, },
	{key = "XP01:I-83079",	group = "XP01:ATabards", order = 2, label = "Tabard Tushui ",		faction = "A", frameID = "list1", itemInfo = "Tushui Tabard",			item = { itemID = 83079, required = { 1, Y, Y, 1 }, }, rep = { sellWhenExalted = Y, factionID = 1353, }, mapID = {84},				complete = { any = { { item = { itemID = 83079, count = 1 } }, { rep = { factionID = 1353, minStanding = 8 } }, }, }, },
	{key = "XP01:I-45579",	group = "XP01:ATabards", order = 3, label = "Tabard Darnassus ",	faction = "A", frameID = "list1", itemInfo = "Darnassus Tabard",		item = { itemID = 45579, required = { 1, Y, Y, 1 }, }, rep = { sellWhenExalted = Y, factionID =   69, }, mapID = {84,62,57,89},		complete = { any = { { item = { itemID = 45579, count = 1 } }, { rep = { factionID =   69, minStanding = 8 } }, }, }, },
	{key = "XP01:I-64882",	group = "XP01:ATabards", order = 4, label = "Tabard Gilneas ",		faction = "A", frameID = "list1", itemInfo = "Gilneas Tabard",			item = { itemID = 64882, required = { 1, Y, Y, 1 }, }, rep = { sellWhenExalted = Y, factionID = 1134, }, mapID = {84,62,57,89},		complete = { any = { { item = { itemID = 64882, count = 1 } }, { rep = { factionID = 1134, minStanding = 8 } }, }, }, },
	{key = "XP01:I-45580",	group = "XP01:ATabards", order = 5, label = "Tabard Exodar ",		faction = "A", frameID = "list1", itemInfo = "Exodar Tabard",			item = { itemID = 45580, required = { 1, Y, Y, 1 }, }, rep = { sellWhenExalted = Y, factionID =  930, }, mapID = {84,57,62,89,103}, complete = { any = { { item = { itemID = 45580, count = 1 } }, { rep = { factionID =  930, minStanding = 8 } }, }, }, },
	{key = "XP01:I-45577",	group = "XP01:ATabards", order = 6, label = "Tabard Ironforge ",	faction = "A", frameID = "list1", itemInfo = "Ironforge Tabard",		item = { itemID = 45577, required = { 1, Y, Y, 1 }, }, rep = { sellWhenExalted = Y, factionID =   47, }, mapID = {84,87,1161},		complete = { any = { { item = { itemID = 45577, count = 1 } }, { rep = { factionID =   47, minStanding = 8 } }, }, }, },
	{key = "XP01:I-45578",	group = "XP01:ATabards", order = 7, label = "Tabard Gnomeregan ",	faction = "A", frameID = "list1", itemInfo = "Gnomeregan Tabard",		item = { itemID = 45578, required = { 1, Y, Y, 1 }, }, rep = { sellWhenExalted = Y, factionID =   54, }, mapID = {84,87,1161},		complete = { any = { { item = { itemID = 45578, count = 1 } }, { rep = { factionID =   54, minStanding = 8 } }, }, }, },
-- HORDE TABARDS     (Orgrimmar 85)
	{key = "XP01:I-45581",	group = "XP01:HTabards", order = 1, label = "Tabard Orgrimmar ",	faction = "H", frameID = "list1", itemInfo = "Orgrimmar Tabard",		item = { itemID = 45581, required = { 1, Y, Y, 1 }, }, rep = { sellWhenExalted = Y, factionID =   76, }, mapID = {85},				complete = { any = { { item = { itemID = 45581, count = 1 } }, { rep = { factionID =   76, minStanding = 8 } }, }, }, },
	{key = "XP01:I-45582",	group = "XP01:HTabards", order = 2, label = "Tabard Darkspear",		faction = "H", frameID = "list1", itemInfo = "Darkspear Tabard",		item = { itemID = 45582, required = { 1, Y, Y, 1 }, }, rep = { sellWhenExalted = Y, factionID =  530, }, mapID = {85},				complete = { any = { { item = { itemID = 45582, count = 1 } }, { rep = { factionID =  530, minStanding = 8 } }, }, }, },
	{key = "XP01:I-64884",	group = "XP01:HTabards", order = 3, label = "Tabard Bilgewater",	faction = "H", frameID = "list1", itemInfo = "Bilgewater Tabard",		item = { itemID = 64884, required = { 1, Y, Y, 1 }, }, rep = { sellWhenExalted = Y, factionID = 1133, }, mapID = {85},				complete = { any = { { item = { itemID = 64884, count = 1 } }, { rep = { factionID = 1133, minStanding = 8 } }, }, }, },
	{key = "XP01:I-83080",	group = "XP01:HTabards", order = 4, label = "Tabard Huojin",		faction = "H", frameID = "list1", itemInfo = "Huojin Tabard",			item = { itemID = 83080, required = { 1, Y, Y, 1 }, }, rep = { sellWhenExalted = Y, factionID = 1352, }, mapID = {85},				complete = { any = { { item = { itemID = 83080, count = 1 } }, { rep = { factionID = 1352, minStanding = 8 } }, }, }, },
	{key = "XP01:I-45583",	group = "XP01:HTabards", order = 5,	label = "Tabard Undercity",		faction = "H", frameID = "list1", itemInfo = "Undercity Tabard",		item = { itemID = 45583, required = { 1, Y, Y, 1 }, }, rep = { sellWhenExalted = Y, factionID =   68, }, mapID = {85},				complete = { any = { { item = { itemID = 45583, count = 1 } }, { rep = { factionID =   68, minStanding = 8 } }, }, }, },
	{key = "XP01:I-45585",  group = "XP01:HTabards", order = 6,	label = "Tabard Silvermoon",	faction = "H", frameID = "list1", itemInfo = "Silvermoon Tabard",		item = { itemID = 45585, required = { 1, Y, Y, 1 }, }, rep = { sellWhenExalted = Y, factionID =  911, }, mapID = {85},				complete = { any = { { item = { itemID = 45585, count = 1 } }, { rep = { factionID =  911, minStanding = 8 } }, }, }, },
	{key = "XP01:I-45584",  group = "XP01:HTabards", order = 7,	label = "Tabard Thunder Bluff", faction = "H", frameID = "list1", itemInfo = "Thunder Bluff Tabard",	item = { itemID = 45584, required = { 1, Y, Y, 1 }, }, rep = { sellWhenExalted = Y, factionID =   81, }, mapID = {85},				complete = { any = { { item = { itemID = 45584, count = 1 } }, { rep = { factionID =   81, minStanding = 8 } }, }, }, },

-- NEUTRAL ITEMS
	{key = "XP01:I46725",   item = {itemID =  46725, required = {1,Y,Y,1},},	label = "Red Rider Air RIfle",	mapID = {"CAP"},    frameID = "list1",	itemInfo = "Red Rider Air RIfle",								complete = {any={{item={itemID= 46725,count=1}},},},	group = "XP01:RedRider", order = 1, },
	{key = "XP01:I48601",   item = {itemID =  48601, required = {1,Y,Y,1},},	label = "Red Rider Air Ammo", 	mapID = {"CAP"},    frameID = "list1",	itemInfo = "Red Rider Air Ammo",								complete = {any={{item={itemID= 48601,count=1}},},},	group = "XP01:RedRider", order = 2, },
	{key = "XP01:I109076",  item = {itemID = 109076, required = {5,Y,N,0},},	label = "Goblin Gliders", 		restedOnly = Y,     frameID = "list1",	itemInfo = "Goblin Gliders"},
--	charLI = "Name-Realm" (or {list}): only shows while logged in on that character



}
      bakedRules = ns.GuideHelpers.ExpandQuestGroups(bakedRules)
for i = 1, #bakedRules do
  local r = bakedRules[i]
  if type(r) == "table" and not r.questGroup then
    ns.GuideHelpers.NormalizeRule(r, EXPANSION_ID, EXPANSION_NAME)
    ns.rules[#ns.rules + 1] = r
  end
end
