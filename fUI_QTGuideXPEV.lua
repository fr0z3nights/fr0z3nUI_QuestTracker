local addonName, ns = ...

-- Expansion DBEV (Events)
-- Put event-specific baked rules in this file.

ns.rules = ns.rules or {}

local EXPANSION_ID = -2
local EXPANSION_NAME = "Events"

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
--   %sl -> {shoppingList}
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

-- Player vs Player Brawls

  {aura = { eventKind = "calendar", keywords = { "PvP Brawl: Southshore vs. Tarren Mill" }, mustHave = true, rememberWeekly = true },
  label = "PvP: Southshore vs Tarren Mill", frameID = "list2", playerLevel = { ">=", 20 }, key = "event:pvp-brawl:southshore-tarren-mill",
  questInfo = "PvP: SS vs TM", noAutoDisplay = true, },

  {aura = { eventKind = "calendar", keywords = { "PvP Brawl: Classic Ashran" }, mustHave = true, rememberWeekly = true },
  label = "PvP Brawl: Classic Ashran", frameID = "list2", playerLevel = { ">=", 20 }, key = "event:pvp-brawl:classic-ashran",
  questInfo = "PvP: Ashran", noAutoDisplay = true, },

  {aura = { eventKind = "calendar", keywords = { "PvP Brawl: Packed House" }, mustHave = true, rememberWeekly = true },
  label = "PvP Brawl: Packed House", frameID = "list2", playerLevel = { ">=", 20 }, key = "event:pvp-brawl:packed-house",
  questInfo = "PvP: Packed House", noAutoDisplay = true, },

  {aura = { eventKind = "calendar", keywords = { "PvP Brawl: Deep Six" }, mustHave = true, rememberWeekly = true },
  label = "PvP Brawl: Deep Six", frameID = "list2", playerLevel = { ">=", 20 }, key = "event:pvp-brawl:deep-six",
  questInfo = "PvP: Deep Six", noAutoDisplay = true, },

-- Levelling Events

  {aura = { eventKind = "calendar", keywords = { "Winds of Mysterious Fortune" }, mustHave = true, rememberWeekly = true },
  label = "Winds of Mysterious Fortune", frameID = "list2", key = "event:winds-of-mysterious-fortune",
  questInfo = "Level Up Bonus", levelGate = "leveling", hideDone = false, },

-- Darkmoon Faire

  {group = "event:darkmoon-faire", order = 00, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon Faire", frameID = "list2", key = "event:darkmoon-faire", questInfo = "Darkmoon Faire", hideDone = false, },

  {group = "event:darkmoon-faire", order = 01, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon Adventurer's Guide", frameID = "list2", key = "custom:seq:item:71634:list2:evdm00",
  itemInfo = "Darkmoon Adventurer's Guide\n- Hidden if in bags/bank", item = {itemID = 71634, includeBank = true, required = { 1, Y, N, 0 }, }, },

  {group = "event:darkmoon-faire", order = 02, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon Game Tokens", frameID = "list2", key = "custom:seq:item:71083:list2:evdm01",
  itemInfo = "Game Tokens", item = {itemID = 71083, showWhenBelow = 21, required = { 20, N, Y, 200 }, 
  buy = {enabled = Y, min = 20, target = 100, max = 200, yieldItemID = 71083, yieldCount = 20, cheapestOf = { 78910, 78909, 78908, 78907, 78906, 78905 }, }, }, },

  {group = "event:darkmoon-faire", order = 03, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Pet Battle: Jeremy", frameID = "list2", key = "custom:seq:q:32175:list2:evdmPB01",
  questInfo = "Pet Battle: Jeremy", questID = 32175, hideDone = true, },

  {group = "event:darkmoon-faire", order = 04, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Pet Battle: Christoph", frameID = "list2", key = "custom:seq:q:36471:list2:evdmPB02",
  questInfo = "Pet Battle: Christoph", questID = 36471, hideDone = true, },

-- Darkmoon Faire weekly profession quests
  -- Display gate: uses base profession skillLineIDs so these only show if you
  -- actually know the corresponding profession (more reliable than spellID lists).

  {faction = "A",
  group = "event:darkmoon-faire", order = 05, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Alchemy", frameID = "list2", key = "custom:seq:q:29506:list2:evdmwk01A",
  questInfo = "Darkmoon: Alchemy\n%sl\n - Vendor Outside Portal", questID = 29506, profSID = 171,
  autoBuyShopping = false, shopping = { { itemID = 1645, required = 5, buy = false }, }, },

  {faction = "H",
  group = "event:darkmoon-faire", order = 06, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Alchemy", frameID = "list2", key = "custom:seq:q:29506:list2:evdmwk01H",
  questInfo = "Darkmoon: Alchemy\n%sl\n - Vendor Thunder Bluff", questID = 29506, profSID = 171,
  autoBuyShopping = false, shopping = { { itemID = 1645, required = 5, buy = false }, }, },

  {group = "event:darkmoon-faire", order = 07, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Archaeology", frameID = "list2", key = "custom:seq:q:29507:list2:evdmwk02",
  questInfo = "DMF: Archaeology\n - Fossil Fragments $hv/$rq\n  (or Quest is in Log)", questID = 29507, profSID = 794, item = { itemID = 111245, currencyID = { 393, 15 }, required = { 20, N, Y, 200 }, },
  showIf = { any = { { questInLog = 29507 }, { currencyID = { 393, 15 } }, }, }, },

  {group = "event:darkmoon-faire", order = 08, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Blacksmithing", frameID = "list2", key = "custom:seq:q:29508:list2:evdmwk03",
  questInfo = "DMF: Blacksmithing", questID = 29508, profSID = 164, },

  {faction = "A",
  group = "event:darkmoon-faire", order = 09, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Cooking", frameID = "list2", key = "custom:seq:q:29509:list2:evdmwk04A",
  questInfo = "DMF: Cooking\n%sl\n - Old Town Inn Cooking Vendor", questID = 29509, profSID = 185,
  autoBuyShopping = false, shopping = {{ itemID = 30817, required = 20, buy = false }, }, },

  {faction = "H",
  group = "event:darkmoon-faire", order = 10, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Cooking", frameID = "list2", key = "custom:seq:q:29509:list2:evdmwk04H",
  questInfo = "DMF: Cooking\n%sl\n - Drag Cooking Vendor", questID = 29509, profSID = 185,
  autoBuyShopping = false, shopping = {{ itemID = 30817, required = 20, buy = false }, }, },

  {group = "event:darkmoon-faire", order = 11, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Enchanting", frameID = "list2", key = "custom:seq:q:29510:list2:evdmwk05",
  questInfo = "DMF: Enchanting", questID = 29510, profSID = 333, },

  {group = "event:darkmoon-faire", order = 12, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Engineering", frameID = "list2", key = "custom:seq:q:29511:list2:evdmwk06",
  questInfo = "DMF: Engineering", questID = 29511, profSID = 202, },

  {group = "event:darkmoon-faire", order = 13, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Fishing", frameID = "list2", key = "custom:seq:q:29513:list2:evdmwk07",
  questInfo = "DMF: Fishing", questID = 29513, profSID = 356, },

  {group = "event:darkmoon-faire", order = 14, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Herbalism", frameID = "list2", key = "custom:seq:q:29514:list2:evdmwk08",
  questInfo = "DMF: Herbalism", questID = 29514, profSID = 182, },

  {faction = "A",
  group = "event:darkmoon-faire", order = 15, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Inscription", frameID = "list2", key = "custom:seq:q:29515:list2:evdmwk09A",
  questInfo = "DMF: Inscription\n%sl\n - Vendor Outside Portal", questID = 29515, profSID = 773,
  autoBuyShopping = false, shopping = { { itemID = 39354, required = 10, buy = false }, }, },

  {faction = "H",
  group = "event:darkmoon-faire", order = 16, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Inscription", frameID = "list2", key = "custom:seq:q:29515:list2:evdmwk09H",
  questInfo = "DMF: Inscription\n%sl\n - Vendor Thunder Bluff", questID = 29515, profSID = 773,
  autoBuyShopping = false, shopping = { { itemID = 39354, required = 10, buy = false }, }, },

  {group = "event:darkmoon-faire", order = 17, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Jewelcrafting", frameID = "list2", key = "custom:seq:q:29516:list2:evdmwk10",
  questInfo = "DMF: Jewelcrafting", questID = 29516, profSID = 755, },

  {faction = "A",
  group = "event:darkmoon-faire", order = 18, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Leatherworking", frameID = "list2", key = "custom:seq:q:29517:list2:evdmwk11A",
  questInfo = "DMF: Leatherworking\n%sl\n - Vendor Outside Portal", questID = 29517, profSID = 165,
  autoBuyShopping = false, shopping = { { itemID = 6529, required = 10, buy = false }, { itemID = 2320, required = 5, buy = false }, { itemID = 6260, required = 10, buy = false }, }, },
  {faction = "H",
  group = "event:darkmoon-faire", order = 19, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Leatherworking", frameID = "list2", key = "custom:seq:q:29517:list2:evdmwk11H",
  questInfo = "DMF: Leatherworking\n%sl\n - Vendor Thunder Bluff", questID = 29517, profSID = 165,
  autoBuyShopping = false, shopping = { { itemID = 6529, required = 10, buy = false }, { itemID = 2320, required = 5, buy = false }, { itemID = 6260, required = 10, buy = false }, }, },

  {group = "event:darkmoon-faire", order = 20, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Mining", frameID = "list2", key = "custom:seq:q:29518:list2:evdmwk12",
    questInfo = "DMF: Mining", questID = 29518, profSID = 186, },

    {group = "event:darkmoon-faire", order = 21, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Skinning", frameID = "list2", key = "custom:seq:q:29519:list2:evdmwk13",
  questInfo = "DMF: Skinning", questID = 29519, profSID = 393, },

  {faction = "A",
  group = "event:darkmoon-faire", order = 22, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Tailoring", frameID = "list2", key = "custom:seq:q:29520:list2:evdmwk14A",
  questInfo = "DMF: Tailoring\n%sl\n - Vendor Outside Portal", questID = 29520, profSID = 197,
  autoBuyShopping = false, shopping = { { itemID = 2320, required = 6, buy = false }, { itemID = 2604, required = 6, buy = false }, { itemID = 6260, required = 6, buy = false }, }, },

  {faction = "H",
  group = "event:darkmoon-faire", order = 23, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Tailoring", frameID = "list2", key = "custom:seq:q:29520:list2:evdmwk14H",
  questInfo = "DMF: Tailoring\n%sl\n - Vendor Thunder Bluff", questID = 29520, profSID = 197,
  autoBuyShopping = false, shopping = { { itemID = 2320, required = 6, buy = false }, { itemID = 2604, required = 6, buy = false }, { itemID = 6260, required = 6, buy = false }, }, },

  {group = "event:darkmoon-faire", order = 24, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Test Your Strength", frameID = "list2", playerLevel = { ">=", 20 }, key = "custom:seq:q:29433:list2:evdmSTR",
  questInfo = "Test Your Strength", questID = 29433, hideDone = true, },

-- Darkmoon Faire Item Quests
  {group = "event:darkmoon-faire", order = 25, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "A Treatise on Strategy", frameID = "list2", key = "custom:seq:q:29451:list2:evdmit01",
  questInfo = "A Treatise on Strategy", questID = 29451, hideDone = true, showIf = { itemID = 71715, includeBank = true }, },

  {group = "event:darkmoon-faire", order = 26, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Imbued Crystal", frameID = "list2", key = "custom:seq:q:29443:list2:evdmit02",
  questInfo = "Imbued Crystal", questID = 29443, hideDone = true, showIf = { itemID = 71635, includeBank = true }, },

  {group = "event:darkmoon-faire", order = 27, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Monstrous Egg", frameID = "list2", key = "custom:seq:q:29444:list2:evdmit03",
  questInfo = "Monstrous Egg", questID = 29444, hideDone = true, showIf = { itemID = 71636, includeBank = true }, },

  {group = "event:darkmoon-faire", order = 28, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Mysterious Grimoire", frameID = "list2", key = "custom:seq:q:29445:list2:evdmit04",
  questInfo = "Mysterious Grimoire", questID = 29445, hideDone = true, showIf = { itemID = 71637, includeBank = true }, },

  {group = "event:darkmoon-faire", order = 29, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Ornate Weapon", frameID = "list2", key = "custom:seq:q:29446:list2:evdmit05",
  questInfo = "Ornate Weapon", questID = 29446, hideDone = true, showIf = { itemID = 71638, includeBank = true }, },

  {group = "event:darkmoon-faire", order = 30, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Banner of the Fallen", frameID = "list2", key = "custom:seq:q:29456:list2:evdmit06",
  questInfo = "Banner of the Fallen", questID = 29456, hideDone = true, showIf = { itemID = 71951, includeBank = true }, },

  {group = "event:darkmoon-faire", order = 31, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Captured Insignia", frameID = "list2", key = "custom:seq:q:29457:list2:evdmit07",
  questInfo = "Captured Insignia", questID = 29457, hideDone = true, showIf = { itemID = 71952, includeBank = true }, },

  {group = "event:darkmoon-faire", order = 32, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Fallen Adventurer's Journal", frameID = "list2", key = "custom:seq:q:29458:list2:evdmit08",
  questInfo = "Fallen Adventurer's Journal", questID = 29458, hideDone = true, showIf = { itemID = 71953, includeBank = true }, },

  {group = "event:darkmoon-faire", order = 33, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Soothsayer's Runes", frameID = "list2", key = "custom:seq:q:29464:list2:evdmit09",
  questInfo = "Soothsayer's Runes", questID = 29464, hideDone = true, showIf = { itemID = 71716, includeBank = true }, },

  {group = "event:darkmoon-faire", order = 34, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Moonfang's Pelt", frameID = "list2", key = "custom:seq:q:33354:list2:evdmit10",
  questInfo = "Moonfang's Pelt", questID = 33354, hideDone = true, showIf = { itemID = 105891, includeBank = true }, },

  -- Valentines

  {group = "event:valentines", order = 00, aura = { eventKind = "calendar", keywords = { "Love is in the Air" }, mustHave = true, rememberDaily = true },
  label = "Love is in the Air", frameID = "list2", key = "event:love-is-in-the-air",
  questInfo = "Valentines", hideDone = false, },

  {group = "event:midsummer", order = 00, aura = { eventKind = "calendar", keywords = { "Midsummer Fire Festival" }, mustHave = true, rememberDaily = true },
  label = "Midsummer Fire Festival", frameID = "list2", key = "event:midsummer-fire-festival", size = 22, color = "ffe633",
  itemInfo = "Midsummer", hideDone = false, item = { itemID = 23247, required = { 999, N, N, 0 }, },},

  {group = "event:childrens", order = 00, aura = { eventKind = "calendar", keywords = { "Children's Week" }, mustHave = true, rememberDaily = true },
  label = "Children's Week", frameID = "list2", key = "event:childrens",
  questInfo = "Children's Week", questID = 99999999, hideDone = true, },

  {label = "Blingtron", frameID = "list2", key = "custom:q:44184:list2:XPEVBT",
  questInfo = "BLINGTRON", questID = 44184, hideDone = true, },


 

}
-- mapIDs: fUI_QTUsage.lua

for i = 1, #bakedRules do
  local r = bakedRules[i]
  if type(r) == "table" then
    if r._expansionID == nil then r._expansionID = EXPANSION_ID end
    if r._expansionName == nil then r._expansionName = EXPANSION_NAME end
    if r.questXY == nil and tonumber(r.questID) and r.qXept == nil then r.qXept = "N" end
    if type(r.key) == "string" then
      r.key = r.key:gsub("^custom:", "db:")
    end
    r.mapID = ns.ExpandMapIDs(r.mapID)
    ns.rules[#ns.rules + 1] = r
  end
end
