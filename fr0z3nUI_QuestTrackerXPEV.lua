local addonName, ns = ...

-- Expansion DBEV (Events)
-- Put event-specific baked rules in this file.

ns.rules = ns.rules or {}

local EXPANSION_ID = -2
local EXPANSION_NAME = "Events"

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
  label = "PvP: Southshore vs Tarren Mill", ["frameID"] = "list2", playerLevel = { ">=", 20 }, key = "event:pvp-brawl:southshore-tarren-mill",
  questInfo = "PvP: SS vs TM", noAutoDisplay = true, },

  {aura = { eventKind = "calendar", keywords = { "PvP Brawl: Classic Ashran" }, mustHave = true, rememberWeekly = true },
  label = "PvP Brawl: Classic Ashran", ["frameID"] = "list2", playerLevel = { ">=", 20 }, key = "event:pvp-brawl:classic-ashran",
  questInfo = "PvP: Ashran", noAutoDisplay = true, },

  {aura = { eventKind = "calendar", keywords = { "PvP Brawl: Packed House" }, mustHave = true, rememberWeekly = true },
  label = "PvP Brawl: Packed House", ["frameID"] = "list2", playerLevel = { ">=", 20 }, key = "event:pvp-brawl:packed-house",
  questInfo = "PvP: Packed House", noAutoDisplay = true, },

  {aura = { eventKind = "calendar", keywords = { "PvP Brawl: Deep Six" }, mustHave = true, rememberWeekly = true },
  label = "PvP Brawl: Deep Six", ["frameID"] = "list2", playerLevel = { ">=", 20 }, key = "event:pvp-brawl:deep-six",
  questInfo = "PvP: Deep Six", noAutoDisplay = true, },

-- Levelling Events

  {aura = { eventKind = "calendar", keywords = { "Winds of Mysterious Fortune" }, mustHave = true, rememberWeekly = true },
  label = "Winds of Mysterious Fortune", ["frameID"] = "list2", key = "event:winds-of-mysterious-fortune",
  questInfo = "Level Up Bonus", levelGate = "leveling", hideWhenCompleted = false, },

-- Darkmoon Faire

  {["group"] = "event:darkmoon-faire", ["order"] = 00, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon Faire", ["frameID"] = "list2", key = "event:darkmoon-faire", questInfo = "Darkmoon Faire", hideWhenCompleted = false, },
  {["group"] = "event:darkmoon-faire", ["order"] = 01, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon Adventurer's Guide", ["frameID"] = "list2", key = "custom:seq:item:71634:list2:evdm00",
  itemInfo = "Darkmoon Adventurer's Guide\n- Hidden if in bags/bank", item = {itemID = 71634, includeBank = true, required = { 1, Y, N, 0 }, }, },

  {["group"] = "event:darkmoon-faire", ["order"] = 02, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon Game Tokens", ["frameID"] = "list2", key = "custom:seq:item:71083:list2:evdm01",
  itemInfo = "Game Tokens", item = {itemID = 71083, showWhenBelow = 21, required = { 20, N, Y, 200 }, 
  buy = {enabled = Y, min = 20, target = 100, max = 200, yieldItemID = 71083, yieldCount = 20, cheapestOf = { 78910, 78909, 78908, 78907, 78906, 78905 }, }, }, },

  {["group"] = "event:darkmoon-faire", ["order"] = 03, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Pet Battle: Jeremy", ["frameID"] = "list2", key = "custom:seq:q:32175:list2:evdmPB01",
  questInfo = "Pet Battle: Jeremy", questID = 32175, hideWhenCompleted = false, },

  {["group"] = "event:darkmoon-faire", ["order"] = 04, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Pet Battle: Christoph", ["frameID"] = "list2", key = "custom:seq:q:36471:list2:evdmPB02",
  questInfo = "Pet Battle: Christoph", questID = 36471, hideWhenCompleted = false, },

-- Darkmoon Faire weekly profession quests
  -- Display gate: uses profession spellIDs (spellKnown) so these only show if you
  -- actually know the corresponding profession.

  {["faction"] = "Alliance",
  ["group"] = "event:darkmoon-faire", ["order"] = 05, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Alchemy", ["frameID"] = "list2", key = "custom:seq:q:29506:list2:evdmwk01A",
  questInfo = "Darkmoon: Alchemy\n%sl\n - Vendor Outside Portal", questID = 29506, spellKnownAny = { 264243, 265751, 265792, 265793, 265794, 265795, 265796, 265797, 265798, 265799, 309307, 374620, 433314, 471006, },
  autoBuyShopping = true, shopping = { { itemID = 1645, required = 5, buy = true }, }, },

  {["faction"] = "Horde",
  ["group"] = "event:darkmoon-faire", ["order"] = 06, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Alchemy", ["frameID"] = "list2", key = "custom:seq:q:29506:list2:evdmwk01H",
  questInfo = "Darkmoon: Alchemy\n%sl\n - Vendor Thunder Bluff", questID = 29506, spellKnownAny = { 264243, 265751, 265792, 265793, 265794, 265795, 265796, 265797, 265798, 265799, 309307, 374620, 433314, 471006, },
  autoBuyShopping = true, shopping = { { itemID = 1645, required = 5, buy = true }, }, },

  {["group"] = "event:darkmoon-faire", ["order"] = 07, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Archaeology", ["frameID"] = "list2", key = "custom:seq:q:29507:list2:evdmwk02",
  questInfo = "DMF: Archaeology\n - Fossil Fragments $hv/$rq\n  (or Quest is in Log)", questID = 29507, spellKnownAny = { 78670, 265752, 265800, 265801, 265802, 265803, 265804, 265805, 309308, 374621, 433315, 471007 },
  showIf = { any = { { questInLog = 29507 }, { currencyID = { 393, 15 } }, }, }, },

  {["group"] = "event:darkmoon-faire", ["order"] = 08, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Blacksmithing", ["frameID"] = "list2", key = "custom:seq:q:29508:list2:evdmwk03",
  questInfo = "DMF: Blacksmithing", questID = 29508, spellKnownAny = { 264440, 265753, 265806, 265807, 265808, 265809, 265810, 265811, 265812, 265813, 309309, 374622, 433316, 471008, }, },

  {["faction"] = "Alliance",
  ["group"] = "event:darkmoon-faire", ["order"] = 09, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Cooking", ["frameID"] = "list2", key = "custom:seq:q:29509:list2:evdmwk04A",
  questInfo = "DMF: Cooking\n%sl\n - Old Town Inn Cooking Vendor", questID = 29509, spellKnownAny = { 264638, 265754, 265814, 265815, 265816, 265817, 265818, 282400, 265819, 265820, 309310, 374623, 433317, 471009,},
  autoBuyShopping = true, shopping = {{ itemID = 30817, required = 20, buy = true }, }, },

  {["faction"] = "Horde",
  ["group"] = "event:darkmoon-faire", ["order"] = 10, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Cooking", ["frameID"] = "list2", key = "custom:seq:q:29509:list2:evdmwk04H",
  questInfo = "DMF: Cooking\n%sl\n - Drag Cooking Vendor", questID = 29509, spellKnownAny = { 264638, 265754, 265814, 265815, 265816, 265817, 265818, 282400, 265819, 265820, 309310, 374623, 433317, 471009,},
  autoBuyShopping = true, shopping = {{ itemID = 30817, required = 20, buy = true }, }, },

  {["group"] = "event:darkmoon-faire", ["order"] = 11, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Enchanting", ["frameID"] = "list2", key = "custom:seq:q:29510:list2:evdmwk05",
  questInfo = "DMF: Enchanting", questID = 29510, spellKnownAny = { 264464, 265755, 265821, 265822, 265823, 265824, 265825, 265826, 265827, 265828, 309311, 374625, 433319, 471011, }, },

  {["group"] = "event:darkmoon-faire", ["order"] = 12, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Engineering", ["frameID"] = "list2", key = "custom:seq:q:29511:list2:evdmwk06",
  questInfo = "DMF: Engineering", questID = 29511, spellKnownAny = { 264483, 265756, 265829, 265830, 265831, 265832, 265833, 265834, 265835, 265836, 309313, 374628, 433322, 471014 }, },
  
  {["group"] = "event:darkmoon-faire", ["order"] = 13, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Fishing", ["frameID"] = "list2", key = "custom:seq:q:29513:list2:evdmwk07",
  questInfo = "DMF: Fishing", questID = 29513, spellKnownAny = { 271660, 265757, 265837, 265838, 265839, 265840, 265841, 265842, 265843, 265844, 309314, 374629, 433323, 471015, }, },

  {["group"] = "event:darkmoon-faire", ["order"] = 14, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Herbalism", ["frameID"] = "list2", key = "custom:seq:q:29514:list2:evdmwk08",
  questInfo = "DMF: Herbalism", questID = 29514, spellKnownAny = { 265825, 265756, 265819, 265820, 265821, 265822, 265823, 265824, 265826, 309312, 374626, 433320, 471012, }, },

  {["faction"] = "Alliance",
  ["group"] = "event:darkmoon-faire", ["order"] = 15, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Inscription", ["frameID"] = "list2", key = "custom:seq:q:29515:list2:evdmwk09A",
  questInfo = "DMF: Inscription\n%sl\n - Vendor Outside Portal", questID = 29515, spellKnownAny = { 264500, 265758, 265845, 265846, 265847, 265848, 265849, 265850, 265851, 265852, 309315, 374630, 433324, 471016,},
  autoBuyShopping = true, shopping = { { itemID = 39354, required = 10, buy = true }, }, },

  {["faction"] = "Horde",
  ["group"] = "event:darkmoon-faire", ["order"] = 16, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Inscription", ["frameID"] = "list2", key = "custom:seq:q:29515:list2:evdmwk09H",
  questInfo = "DMF: Inscription\n%sl\n - Vendor Thunder Bluff", questID = 29515, spellKnownAny = { 264500, 265758, 265845, 265846, 265847, 265848, 265849, 265850, 265851, 265852, 309315, 374630, 433324, 471016, },
  autoBuyShopping = true, shopping = { { itemID = 39354, required = 10, buy = true }, }, },

  {["group"] = "event:darkmoon-faire", ["order"] = 17, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Jewelcrafting", ["frameID"] = "list2", key = "custom:seq:q:29516:list2:evdmwk10",
  questInfo = "DMF: Jewelcrafting", questID = 29516, spellKnownAny = { 264539, 265759, 265853, 265854, 265855, 265856, 265857, 265858, 265859, 265860, 309316, 374631, 433325, 471017, }, },

  {["faction"] = "Alliance",
  ["group"] = "event:darkmoon-faire", ["order"] = 18, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Leatherworking", ["frameID"] = "list2", key = "custom:seq:q:29517:list2:evdmwk11A",
  questInfo = "DMF: Leatherworking\n%sl\n - Vendor Outside Portal", questID = 29517, spellKnownAny = { 264583, 265760, 265861, 265862, 265863, 265864, 265865, 265866, 265867, 265868, 309317, 374632, 433326, 471018, },
  autoBuyShopping = true, shopping = { { itemID = 6529, required = 10, buy = true }, { itemID = 2320, required = 5, buy = true }, { itemID = 6260, required = 10, buy = true }, }, },

  {["faction"] = "Horde",
  ["group"] = "event:darkmoon-faire", ["order"] = 19, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Leatherworking", ["frameID"] = "list2", key = "custom:seq:q:29517:list2:evdmwk11H",
  questInfo = "DMF: Leatherworking\n%sl\n - Vendor Thunder Bluff", questID = 29517, spellKnownAny = { 264583, 265760, 265861, 265862, 265863, 265864, 265865, 265866, 265867, 265868, 309317, 374632, 433326, 471018, },
  autoBuyShopping = true, shopping = { { itemID = 6529, required = 10, buy = true }, { itemID = 2320, required = 5, buy = true }, { itemID = 6260, required = 10, buy = true }, }, },

  {["group"] = "event:darkmoon-faire", ["order"] = 20, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Mining", ["frameID"] = "list2", key = "custom:seq:q:29518:list2:evdmwk12",
    questInfo = "DMF: Mining", questID = 29518, spellKnownAny = { 2575, 265757, 265840, 265841, 265843, 265844, 265845, 265846, 265847, 265848, 265849, 309325, 374627, 433321, 471013, }, },

  {["group"] = "event:darkmoon-faire", ["order"] = 21, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Skinning", ["frameID"] = "list2", key = "custom:seq:q:29519:list2:evdmwk13",
  questInfo = "DMF: Skinning", questID = 29519, spellKnownAny = { 265861, 265761, 265869, 265870, 265871, 265872, 265873, 265874, 265875, 265876, 309318, 374633, 433327, 471019, }, },

  {["faction"] = "Alliance",
  ["group"] = "event:darkmoon-faire", ["order"] = 22, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Tailoring", ["frameID"] = "list2", key = "custom:seq:q:29520:list2:evdmwk14A",
  questInfo = "DMF: Tailoring\n%sl\n - Vendor Outside Portal", questID = 29520, spellKnownAny = { 264622, 265762, 265877, 265878, 265879, 265880, 265881, 265882, 265883, 265884, 309319, 374634, 433328, 471020, },
  autoBuyShopping = true, shopping = { { itemID = 2320, required = 6, buy = true }, { itemID = 2604, required = 6, buy = true }, { itemID = 6260, required = 6, buy = true }, }, },

  {["faction"] = "Horde",
  ["group"] = "event:darkmoon-faire", ["order"] = 23, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Darkmoon: Tailoring", ["frameID"] = "list2", key = "custom:seq:q:29520:list2:evdmwk14H",
  questInfo = "DMF: Tailoring\n%sl\n - Vendor Thunder Bluff", questID = 29520, spellKnownAny = { 264622, 265762, 265877, 265878, 265879, 265880, 265881, 265882, 265883, 265884, 309319, 374634, 433328, 471020, },
  autoBuyShopping = true, shopping = { { itemID = 2320, required = 6, buy = true }, { itemID = 2604, required = 6, buy = true }, { itemID = 6260, required = 6, buy = true }, }, },

  {["group"] = "event:darkmoon-faire", ["order"] = 24, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Test Your Strength", ["frameID"] = "list2", playerLevel = { ">=", 20 }, key = "custom:seq:q:29433:list2:evdmSTR",
  questInfo = "Test Your Strength", questID = 29433, hideWhenCompleted = true, },

-- Darkmoon Faire Item Quests
  {["group"] = "event:darkmoon-faire", ["order"] = 25, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "A Treatise on Strategy", ["frameID"] = "list2", key = "custom:seq:q:29451:list2:evdmit01",
  questInfo = "A Treatise on Strategy", questID = 29451, hideWhenCompleted = true, showIf = { itemID = 71715, includeBank = true }, },

  {["group"] = "event:darkmoon-faire", ["order"] = 26, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Imbued Crystal", ["frameID"] = "list2", key = "custom:seq:q:29443:list2:evdmit02",
  questInfo = "Imbued Crystal", questID = 29443, hideWhenCompleted = true, showIf = { itemID = 71635, includeBank = true }, },

  {["group"] = "event:darkmoon-faire", ["order"] = 27, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Monstrous Egg", ["frameID"] = "list2", key = "custom:seq:q:29444:list2:evdmit03",
  questInfo = "Monstrous Egg", questID = 29444, hideWhenCompleted = true, showIf = { itemID = 71636, includeBank = true }, },

  {["group"] = "event:darkmoon-faire", ["order"] = 28, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Mysterious Grimoire", ["frameID"] = "list2", key = "custom:seq:q:29445:list2:evdmit04",
  questInfo = "Mysterious Grimoire", questID = 29445, hideWhenCompleted = true, showIf = { itemID = 71637, includeBank = true }, },

  {["group"] = "event:darkmoon-faire", ["order"] = 29, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Ornate Weapon", ["frameID"] = "list2", key = "custom:seq:q:29446:list2:evdmit05",
  questInfo = "Ornate Weapon", questID = 29446, hideWhenCompleted = true, showIf = { itemID = 71638, includeBank = true }, },

  {["group"] = "event:darkmoon-faire", ["order"] = 30, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Banner of the Fallen", ["frameID"] = "list2", key = "custom:seq:q:29456:list2:evdmit06",
  questInfo = "Banner of the Fallen", questID = 29456, hideWhenCompleted = true, showIf = { itemID = 71951, includeBank = true }, },

  {["group"] = "event:darkmoon-faire", ["order"] = 31, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Captured Insignia", ["frameID"] = "list2", key = "custom:seq:q:29457:list2:evdmit07",
  questInfo = "Captured Insignia", questID = 29457, hideWhenCompleted = true, showIf = { itemID = 71952, includeBank = true }, },

  {["group"] = "event:darkmoon-faire", ["order"] = 32, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Fallen Adventurer's Journal", ["frameID"] = "list2", key = "custom:seq:q:29458:list2:evdmit08",
  questInfo = "Fallen Adventurer's Journal", questID = 29458, hideWhenCompleted = true, showIf = { itemID = 71953, includeBank = true }, },

  {["group"] = "event:darkmoon-faire", ["order"] = 33, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Soothsayer's Runes", ["frameID"] = "list2", key = "custom:seq:q:29464:list2:evdmit09",
  questInfo = "Soothsayer's Runes", questID = 29464, hideWhenCompleted = true, showIf = { itemID = 71716, includeBank = true }, },

  {["group"] = "event:darkmoon-faire", ["order"] = 34, aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, includeHolidayText = true, mustHave = true, rememberDaily = true },
  label = "Moonfang's Pelt", ["frameID"] = "list2", key = "custom:seq:q:33354:list2:evdmit10",
  questInfo = "Moonfang's Pelt", questID = 33354, hideWhenCompleted = true, showIf = { itemID = 105891, includeBank = true }, },

  -- Valentines

  {["group"] = "event:valentines", ["order"] = 00, aura = { eventKind = "calendar", keywords = { "Love is in the Air" }, mustHave = true, rememberDaily = true },
  label = "Love is in the Air", ["frameID"] = "list2", key = "event:love-is-in-the-air",
  questInfo = "Valentines", hideWhenCompleted = false, },

  {["label"] = "Blingtron", ["frameID"] = "list2", ["key"] = "custom:q:44184:list2:BT",
  ["questInfo"] = "BLINGTRON", ["questID"] = 44184, ["hideWhenCompleted"] = true, },




}

for i = 1, #bakedRules do
  local r = bakedRules[i]
  if type(r) == "table" then
    if r._expansionID == nil then r._expansionID = EXPANSION_ID end
    if r._expansionName == nil then r._expansionName = EXPANSION_NAME end
    if type(r.key) == "string" then
      r.key = r.key:gsub("^custom:", "db:")
    end
    ns.rules[#ns.rules + 1] = r
  end
end
