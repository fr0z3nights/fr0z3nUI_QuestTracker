local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB00 (Unknown/Unclassified)

ns.rules = ns.rules or {}

local EXPANSION_ID = 0
local EXPANSION_NAME = "Unclassified"

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

 

--  12   MIDNIGHT PROFESSIONS         If Not Clearing, Try Loading a Profession's Book After Learning                      /dump C_Map.GetBestMapForUnit("player")
	{key = "XP12:PAlchemy",     xprofSID = 2906,	profSID = 171,		label = "Midnight Alchemy",        frameID = "list1",   mapID = {"MDN"},    textInfo = "Midnight Alchemy", },
	{key = "XP12:PBSmithing",   xprofSID = 2907,	profSID = 164,		label = "Midnight Blacksmithing",  frameID = "list1",   mapID = {"MDN"},    textInfo = "Midnight Blacksmithing", },
	{key = "XP12:PEnchant",     xprofSID = 2909,	profSID = 333,		label = "Midnight Enchanting",     frameID = "list1",   mapID = {"MDN"},    textInfo = "Midnight Enchanting", },
	{key = "XP12:PEngineer",    xprofSID = 2910,	profSID = 202,		label = "Midnight Engineering",    frameID = "list1",   mapID = {"MDN"},    textInfo = "Midnight Engineering", },
	{key = "XP12:PHerbalism",   xprofSID = 2912,	profSID = 182,		label = "Midnight Herbalism",      frameID = "list1",   mapID = {"MDN"},    textInfo = "Midnight Herbalism", },
	{key = "XP12:PInscript",    xprofSID = 2913,	profSID = 773,		label = "Midnight Inscription",    frameID = "list1",   mapID = {"MDN"},    textInfo = "Midnight Inscription", },
	{key = "XP12:PJewelcraft",  xprofSID = 2914,	profSID = 755,		label = "Midnight Jewelcrafting",  frameID = "list1",   mapID = {"MDN"},    textInfo = "Midnight Jewelcrafting", },
	{key = "XP12:PLeatherwork", xprofSID = 2915,	profSID = 165,		label = "Midnight Leatherworking", frameID = "list1",   mapID = {"MDN"},    textInfo = "Midnight Leatherworking", },
	{key = "XP12:PMining",      xprofSID = 2916,	profSID = 186,		label = "Midnight Mining",         frameID = "list1",   mapID = {"MDN"},    textInfo = "Midnight Mining", },
	{key = "XP12:PSkinning",    xprofSID = 2917,	profSID = 393,		label = "Midnight Skinning",       frameID = "list1",   mapID = {"MDN"},    textInfo = "Midnight Skinning", },
	{key = "XP12:PTailoring",   xprofSID = 2918,	profSID = 197,		label = "Midnight Tailoring",      frameID = "list1",   mapID = {"MDN"},    textInfo = "Midnight Tailoring", },
	{key = "XP12:PCooking",     xprofSID = 2908,	profSID = 185,		label = "Midnight Cooking",        frameID = "list1",   mapID = {"MDN"},    textInfo = "Midnight Cooking\n  - Open Profession", },
	{key = "XP12:PFishing",     xprofSID = 2911,	profSID = 356,		label = "Midnight Fishing",        frameID = "list1",   mapID = {"MDN"},    textInfo = "Midnight Fishing", },
	{key = "XP12:PFindFish",						profSID = 356,		label = "Midnight Find Fish",      frameID = "list1",                       textInfo = "Midnight Fish Finder\n - Silvermoon 45,60\n - Buy Angler's Guide", rested = true, missingFindFish = true, showIf = { missingFindFish = true }, },
--  11   KHAZ ALGAR PROFESSIONS       If Not Clearing, Try Loading a Profession's Book After Learning                      /dump C_Map.GetBestMapForUnit("player")
	{key = "XP11:PAlchemy",     xprofSID = 2871,	profSID = 171,		label = "Khaz Alchemy",            frameID = "list1",   mapID = {"TWW"},    textInfo = "Khaz Alchemy", },
	{key = "XP11:PBSmithing",   xprofSID = 2872,	profSID = 164,		label = "Khaz Blacksmithing",      frameID = "list1",   mapID = {"TWW"},    textInfo = "Khaz Blacksmithing", },
	{key = "XP11:PEnchant",     xprofSID = 2874,	profSID = 333,		label = "Khaz Enchanting",         frameID = "list1",   mapID = {"TWW"},    textInfo = "Khaz Enchanting", },
	{key = "XP11:PEngineer",    xprofSID = 2875,	profSID = 202,		label = "Khaz Engineering",        frameID = "list1",   mapID = {"TWW"},    textInfo = "Khaz Engineering", },
	{key = "XP11:PHerbalism",   xprofSID = 2877,	profSID = 182,		label = "Khaz Herbalism",          frameID = "list1",   mapID = {"TWW"},    textInfo = "Khaz Herbalism", },
	{key = "XP11:PInscript",    xprofSID = 2878,	profSID = 773,		label = "Khaz Inscription",        frameID = "list1",   mapID = {"TWW"},    textInfo = "Khaz Inscription", },
	{key = "XP11:PJewelcraft",  xprofSID = 2879,	profSID = 755,		label = "Khaz Jewelcrafting",      frameID = "list1",   mapID = {"TWW"},    textInfo = "Khaz Jewelcrafting", },
	{key = "XP11:PLeatherwork", xprofSID = 2880,	profSID = 165,		label = "Khaz Leatherworking",     frameID = "list1",   mapID = {"TWW"},    textInfo = "Khaz Leatherworking", },
	{key = "XP11:PMining",      xprofSID = 2881,	profSID = 186,		label = "Khaz Mining",             frameID = "list1",   mapID = {"TWW"},    textInfo = "Khaz Mining", },
	{key = "XP11:PSkinning",    xprofSID = 2882,	profSID = 393,		label = "Khaz Skinning",           frameID = "list1",   mapID = {"TWW"},    textInfo = "Khaz Skinning", },
	{key = "XP11:PTailoring",   xprofSID = 2883,	profSID = 197,		label = "Khaz Tailoring",          frameID = "list1",   mapID = {"TWW"},    textInfo = "Khaz Tailoring", },
	{key = "XP11:PCooking",     xprofSID = 2873,	profSID = 185,		label = "Khaz Cooking",            frameID = "list1",   mapID = {"TWW"},    textInfo = "Khaz Cooking\n  - Open Profession", },
	{key = "XP11:PFishing",     xprofSID = 2876,	profSID = 356,		label = "Khaz Fishing",            frameID = "list1",   mapID = {"TWW"},    textInfo = "Khaz Fishing", },
--  10   DRAGONFLIGHT PROFESSIONS     If Not Clearing, Try Loading a Profession's Book After Learning                      /dump C_Map.GetBestMapForUnit("player")
	{key = "XP10:PAlchemy",     xprofSID = 2823,	profSID = 171,		label = "Dragon Alchemy",          frameID = "list1",   mapID = {"DRG"},    textInfo = "Dragon Alchemy", },
	{key = "XP10:PBSmithing",   xprofSID = 2822,	profSID = 164,		label = "Dragon Blacksmithing",    frameID = "list1",   mapID = {"DRG"},    textInfo = "Dragon Blacksmithing", },
	{key = "XP10:PEnchant",     xprofSID = 2825,	profSID = 333,		label = "Dragon Enchanting",       frameID = "list1",   mapID = {"DRG"},    textInfo = "Dragon Enchanting", },
	{key = "XP10:PEngineer",    xprofSID = 2827,	profSID = 202,		label = "Dragon Engineering",      frameID = "list1",   mapID = {"DRG"},    textInfo = "Dragon Engineering", },
	{key = "XP10:PHerbalism",   xprofSID = 2832,	profSID = 182,		label = "Dragon Herbalism",        frameID = "list1",   mapID = {"DRG"},    textInfo = "Dragon Herbalism", },
	{key = "XP10:PInscript",    xprofSID = 2828,	profSID = 773,		label = "Dragon Inscription",      frameID = "list1",   mapID = {"DRG"},    textInfo = "Dragon Inscription", },
	{key = "XP10:PJewelcraft",  xprofSID = 2829,	profSID = 755,		label = "Dragon Jewelcrafting",    frameID = "list1",   mapID = {"DRG"},    textInfo = "Dragon Jewelcrafting", },
	{key = "XP10:PLeatherwork", xprofSID = 2830,	profSID = 165,		label = "Dragon Leatherworking",   frameID = "list1",   mapID = {"DRG"},    textInfo = "Dragon Leatherworking", },
	{key = "XP10:PMining",      xprofSID = 2833,	profSID = 186,		label = "Dragon Mining",           frameID = "list1",   mapID = {"DRG"},    textInfo = "Dragon Mining", },
	{key = "XP10:PSkinning",    xprofSID = 2834,	profSID = 393,		label = "Dragon Skinning",         frameID = "list1",   mapID = {"DRG"},    textInfo = "Dragon Skinning", },
	{key = "XP10:PTailoring",   xprofSID = 2831,	profSID = 197,		label = "Dragon Tailoring",        frameID = "list1",   mapID = {"DRG"},    textInfo = "Dragon Tailoring", },
	{key = "XP10:PCooking",     xprofSID = 2824,	profSID = 185,		label = "Dragon Cooking",          frameID = "list1",   mapID = {"DRG"},    textInfo = "Dragon Cooking\n  - Open Profession", },
	{key = "XP10:PFishing",     xprofSID = 2826,	profSID = 356,		label = "Dragon Fishing",          frameID = "list1",   mapID = {"DRG"},    textInfo = "Dragon Fishing", },
--  09   SHADOWLANDS PROFESSIONS      If Not Clearing, Try Loading a Profession's Book After Learning                      /dump C_Map.GetBestMapForUnit("player")
	{key = "XP09:PAlchemy",     xprofSID = 2750,	profSID = 171,		label = "Shadow Alchemy",          frameID = "list1",   mapID = {"SHD"},    textInfo = "Shadow Alchemy", },
	{key = "XP09:PBSmithing",   xprofSID = 2751,	profSID = 164,		label = "Shadow Blacksmithing",    frameID = "list1",   mapID = {"SHD"},    textInfo = "Shadow Blacksmithing", },
	{key = "XP09:PEnchant",     xprofSID = 2753,	profSID = 333,		label = "Shadow Enchanting",       frameID = "list1",   mapID = {"SHD"},    textInfo = "Shadow Enchanting", },
	{key = "XP09:PEngineer",    xprofSID = 2755,	profSID = 202,		label = "Shadow Engineering",      frameID = "list1",   mapID = {"SHD"},    textInfo = "Shadow Engineering", },
	{key = "XP09:PHerbalism",   xprofSID = 2760,	profSID = 182,		label = "Shadow Herbalism",        frameID = "list1",   mapID = {"SHD"},    textInfo = "Shadow Herbalism", },
	{key = "XP09:PInscript",    xprofSID = 2756,	profSID = 773,		label = "Shadow Inscription",      frameID = "list1",   mapID = {"SHD"},    textInfo = "Shadow Inscription", },
	{key = "XP09:PJewelcraft",  xprofSID = 2757,	profSID = 755,		label = "Shadow Jewelcrafting",    frameID = "list1",   mapID = {"SHD"},    textInfo = "Shadow Jewelcrafting", },
	{key = "XP09:PLeatherwork", xprofSID = 2758,	profSID = 165,		label = "Shadow Leatherworking",   frameID = "list1",   mapID = {"SHD"},    textInfo = "Shadow Leatherworking", },
	{key = "XP09:PMining",      xprofSID = 2761,	profSID = 186,		label = "Shadow Mining",           frameID = "list1",   mapID = {"SHD"},    textInfo = "Shadow Mining", },
	{key = "XP09:PSkinning",    xprofSID = 2762,	profSID = 393,		label = "Shadow Skinning",         frameID = "list1",   mapID = {"SHD"},    textInfo = "Shadow Skinning", },
	{key = "XP09:PTailoring",   xprofSID = 2759,	profSID = 197,		label = "Shadow Tailoring",        frameID = "list1",   mapID = {"SHD"},    textInfo = "Shadow Tailoring", },
	{key = "XP09:PCooking",     xprofSID = 2752,	profSID = 185,		label = "Shadow Cooking",          frameID = "list1",   mapID = {"SHD"},    textInfo = "Shadow Cooking\n  - Open Profession", },
	{key = "XP09:PFishing",     xprofSID = 2754,	profSID = 356,		label = "Shadow Fishing",          frameID = "list1",   mapID = {"SHD"},    textInfo = "Shadow Fishing", },
	{key = "XP09:PFishingRod",											label = "Shadow Fishing Rod",      frameID = "list1",   mapID = {"SHD"},    itemInfo = " - Buy Brokers Angle'r", item = { itemID = 180136, inBank = true, required = { 1, true, N, 0 }, },  },
--  08   BATTLE PROFESSIONS           If Not Clearing, Try Loading a Profession's Book After Learning                      /dump C_Map.GetBestMapForUnit("player")
	{key = "XP08:PArchy",       xprofSID = 794,							label = "Battle Archaeology",      frameID = "list1",   mapID = {"BFA"},    textInfo = "Battle Archaeology", },
	{key = "XP08:PAlchemy",     xprofSID = 2478,	profSID = 171,		label = "Battle Alchemy",          frameID = "list1",   mapID = {"BFA"},    textInfo = "Battle Alchemy", },
	{key = "XP08:PBSmithing",   xprofSID = 2437,	profSID = 164,		label = "Battle Blacksmithing",    frameID = "list1",   mapID = {"BFA"},    textInfo = "Battle Blacksmithing", },
	{key = "XP08:PEnchant",     xprofSID = 2486,	profSID = 333,		label = "Battle Enchanting",       frameID = "list1",   mapID = {"BFA"},    textInfo = "Battle Enchanting", },
	{key = "XP08:PEngineer",    xprofSID = 2499,	profSID = 202,		label = "Battle Engineering",      frameID = "list1",   mapID = {"BFA"},    textInfo = "Battle Engineering", },
	{key = "XP08:PHerbalism",   xprofSID = 2549,	profSID = 182,		label = "Battle Herbalism",        frameID = "list1",   mapID = {"BFA"},    textInfo = "Battle Herbalism", },
	{key = "XP08:PInscript",    xprofSID = 2508,	profSID = 773,		label = "Battle Inscription",      frameID = "list1",   mapID = {"BFA"},    textInfo = "Battle Inscription", },
	{key = "XP08:PJewelcraft",  xprofSID = 2518,	profSID = 755,		label = "Battle Jewelcrafting",    frameID = "list1",   mapID = {"BFA"},    textInfo = "Battle Jewelcrafting", },
	{key = "XP08:PLeatherwork", xprofSID = 2525,	profSID = 165,		label = "Battle Leatherworking",   frameID = "list1",   mapID = {"BFA"},    textInfo = "Battle Leatherworking", },
	{key = "XP08:PMining",      xprofSID = 2565,	profSID = 186,		label = "Battle Mining",           frameID = "list1",   mapID = {"BFA"},    textInfo = "Battle Mining", },
	{key = "XP08:PSkinning",    xprofSID = 2557,	profSID = 393,		label = "Battle Skinning",         frameID = "list1",   mapID = {"BFA"},    textInfo = "Battle Skinning", },
	{key = "XP08:PTailor",      xprofSID = 2533,	profSID = 197,		label = "Battle Tailoring",        frameID = "list1",   mapID = {"BFA"},    textInfo = "Battle Tailoring", },
	{key = "XP08:PCooking",     xprofSID = 2541,	profSID = 185,		label = "Battle Cooking",          frameID = "list1",   mapID = {"BFA"},    textInfo = "Battle Cooking\n  - Open Profession", },
	{key = "XP08:PFishing",     xprofSID = 2585,	profSID = 356,		label = "Battle Fishing",          frameID = "list1",   mapID = {"BFA"},    textInfo = "Battle Fishing", },
--  07  LEGION PROFESSIONS            If Not Clearing, Try Loading a Profession's Book After Learning                      /dump C_Map.GetBestMapForUnit("player")
	{key = "XP07:PAlchemy",     xprofSID = 2479,	profSID = 171,		label = "Legion Alchemy",          frameID = "list1",   mapID = {"LGN"},    textInfo = "Legion Alchemy", },
	{key = "XP07:PBSmithing",   xprofSID = 2454,	profSID = 164,		label = "Legion Blacksmithing",    frameID = "list1",   mapID = {"LGN"},    textInfo = "Legion Blacksmithing", },
	{key = "XP07:PEnchant",     xprofSID = 2487,	profSID = 333,		label = "Legion Enchanting",       frameID = "list1",   mapID = {"LGN"},    textInfo = "Legion Enchanting", },
	{key = "XP07:PEngineer",    xprofSID = 2500,	profSID = 202,		label = "Legion Engineering",      frameID = "list1",   mapID = {"LGN"},    textInfo = "Legion Engineering", },
	{key = "XP07:PHerbalism",   xprofSID = 2550,	profSID = 182,		label = "Legion Herbalism",        frameID = "list1",   mapID = {"LGN"},    textInfo = "Legion Herbalism", },
	{key = "XP07:PInscript",    xprofSID = 2508,	profSID = 773,		label = "Legion Inscription",      frameID = "list1",   mapID = {"LGN"},    textInfo = "Legion Inscription", },
	{key = "XP07:PJewelcraft",  xprofSID = 2518,	profSID = 755,		label = "Legion Jewelcrafting",    frameID = "list1",   mapID = {"LGN"},    textInfo = "Legion Jewelcrafting", },
	{key = "XP07:PLeatherwork", xprofSID = 2526,	profSID = 165,		label = "Legion Leatherworking",   frameID = "list1",   mapID = {"LGN"},    textInfo = "Legion Leatherworking", },
	{key = "XP07:PMining",      xprofSID = 2566,	profSID = 186,		label = "Legion Mining",           frameID = "list1",   mapID = {"LGN"},    textInfo = "Legion Mining", },
	{key = "XP07:PSkinning",    xprofSID = 2558,	profSID = 393,		label = "Legion Skinning",         frameID = "list1",   mapID = {"LGN"},    textInfo = "Legion Skinning", },
	{key = "XP07:PTailoring",   xprofSID = 2534,	profSID = 197,		label = "Legion Tailoring",        frameID = "list1",   mapID = {"LGN"},    textInfo = "Legion Tailoring", },
	{key = "XP07:PCooking",     xprofSID = 2542,	profSID = 185,		label = "Legion Cooking",          frameID = "list1",   mapID = {"LGN"},    textInfo = "Legion Cooking\n  - Open Profession", },
	{key = "XP07:PFishing",     xprofSID = 2586,	profSID = 356,		label = "Legion Fishing",          frameID = "list1",   mapID = {"LGN"},    textInfo = "Legion Fishing", },
--  06  WARLORDS PROFESSIONS          If Not Clearing, Try Opening a Profession's Book After Learning                      /dump C_Map.GetBestMapForUnit("player")
	{key = "XP06:PAlchemy",     xprofSID = 2480,	profSID = 171,		label = "Draenor Alchemy",         frameID = "list1",   mapID = {"WoD"},    textInfo = "Draenor Alchemy", },
	{key = "XP06:PBSmithing",   xprofSID = 2472,	profSID = 164,		label = "Draenor Blacksmithing",   frameID = "list1",   mapID = {"WoD"},    textInfo = "Draenor Blacksmithing", },
	{key = "XP06:PEnchant",     xprofSID = 2488,	profSID = 333,		label = "Draenor Enchanting",      frameID = "list1",   mapID = {"WoD"},    textInfo = "Draenor Enchanting", },
	{key = "XP06:PEngineer",    xprofSID = 2501,	profSID = 202,		label = "Draenor Engineering",     frameID = "list1",   mapID = {"WoD"},    textInfo = "Draenor Engineering", },
	{key = "XP06:PHerbalism",   xprofSID = 2551,	profSID = 182,		label = "Draenor Herbalism",       frameID = "list1",   mapID = {"WoD"},    textInfo = "Draenor Herbalism", },
	{key = "XP06:PInscript",    xprofSID = 2509,	profSID = 773,		label = "Draenor Inscription",     frameID = "list1",   mapID = {"WoD"},    textInfo = "Draenor Inscription", },
	{key = "XP06:PJewelcraft",  xprofSID = 2519,	profSID = 755,		label = "Draenor Jewelcrafting",   frameID = "list1",   mapID = {"WoD"},    textInfo = "Draenor Jewelcrafting", },
	{key = "XP06:PLeatherwork", xprofSID = 2527,	profSID = 165,		label = "Draenor Leatherworking",  frameID = "list1",   mapID = {"WoD"},    textInfo = "Draenor Leatherworking", },
	{key = "XP06:PMining",      xprofSID = 2567,	profSID = 186,		label = "Draenor Mining",          frameID = "list1",   mapID = {"WoD"},    textInfo = "Draenor Mining", },
	{key = "XP06:PSkinning",    xprofSID = 2559,	profSID = 393,		label = "Draenor Skinning",        frameID = "list1",   mapID = {"WoD"},    textInfo = "Draenor Skinning", },
	{key = "XP06:PTailor",      xprofSID = 2535,	profSID = 197,		label = "Draenor Tailoring",       frameID = "list1",   mapID = {"WoD"},    textInfo = "Draenor Tailoring",},
	{key = "XP06:PCooking",     xprofSID = 2543,	profSID = 185,		label = "Draenor Cooking",         frameID = "list1",   mapID = {"WoD"},    textInfo = "Draenor Cooking\n  - Open Profession", },
	{key = "XP06:PFishing",     xprofSID = 2587,	profSID = 356,		label = "Draenor Fishing",         frameID = "list1",   mapID = {"WoD"},    textInfo = "Draenor Fishing", },
--  05  PANDARIA PROFESSIONS          If Not Clearing, Try Loading a Profession's Book After Learning                      /dump C_Map.GetBestMapForUnit("player")
	{key = "XP05:PAlchemy",     xprofSID = 2481,	profSID = 171,		label = "Mists Alchemy",           frameID = "list1",   mapID = {"MoP"},    textInfo = "Mists Alchemy", },
	{key = "XP05:PBSmithing",   xprofSID = 2473,	profSID = 164,		label = "Mists Blacksmithing",     frameID = "list1",   mapID = {"MoP"},    textInfo = "Mists Blacksmithing",},
	{key = "XP05:PEnchant",     xprofSID = 2489,	profSID = 333,		label = "Mists Enchanting",        frameID = "list1",   mapID = {"MoP"},    textInfo = "Mists Enchanting",},
	{key = "XP05:PEngineer",    xprofSID = 2502,	profSID = 202,		label = "Mists Engineering",       frameID = "list1",   mapID = {"MoP"},    textInfo = "Mists Engineering", },
	{key = "XP05:PHerbalism",   xprofSID = 2552,	profSID = 182,		label = "Mists Herbalism",         frameID = "list1",   mapID = {"MoP"},    textInfo = "Mists Herbalism", },
	{key = "XP05:PInscript",    xprofSID = 2510,	profSID = 773,		label = "Mists Inscription",       frameID = "list1",   mapID = {"MoP"},    textInfo = "Mists Inscription", },
	{key = "XP05:PJewelcraft",  xprofSID = 2520,	profSID = 755,		label = "Mists Jewelcrafting",     frameID = "list1",   mapID = {"MoP"},    textInfo = "Mists Jewelcrafting", },
	{key = "XP05:PLeatherwork", xprofSID = 2528,	profSID = 165,		label = "Mists Leatherworking",    frameID = "list1",   mapID = {"MoP"},    textInfo = "Mists Leatherworking", },
	{key = "XP05:PMining",      xprofSID = 2568,	profSID = 186,		label = "Mists Mining",            frameID = "list1",   mapID = {"MoP"},    textInfo = "Mists Mining", },
	{key = "XP05:PSkinning",    xprofSID = 2560,	profSID = 393,		label = "Mists Skinning",          frameID = "list1",   mapID = {"MoP"},    textInfo = "Mists Skinning", },
	{key = "XP05:PTailor",      xprofSID = 2536,	profSID = 197,		label = "Mists Tailoring",         frameID = "list1",   mapID = {"MoP"},    textInfo = "Mists Tailoring", },
	{key = "XP05:PCooking",     xprofSID = 2544,	profSID = 185,		label = "Mists Cooking",           frameID = "list1",   mapID = {"MoP"},    textInfo = "Mists Cooking\n  - Open Profession", },
	{key = "XP05:PFishing",     xprofSID = 2588,	profSID = 356,		label = "Mists Fishing",           frameID = "list1",   mapID = {"MoP"},    textInfo = "Mists Fishing", },
--  04  CATACLYSM PROFESSIONS         If Not Clearing, Try Loading a Profession's Book After Learning                      /dump C_Map.GetBestMapForUnit("player")
	{key = "XP04:PAlchemy",     xprofSID = 2482,	profSID = 171,		label = "Cata Alchemy",            frameID = "list1",   mapID = {"CAT"},    textInfo = "Cata Alchemy", },
	{key = "XP04:PBSmithing",   xprofSID = 2474,	profSID = 164,		label = "Cata Blacksmithing",      frameID = "list1",   mapID = {"CAT"},    textInfo = "Cata Blacksmithing", },
	{key = "XP04:PEnchant",     xprofSID = 2491,	profSID = 333,		label = "Cata Enchanting",         frameID = "list1",   mapID = {"CAT"},    textInfo = "Cata Enchanting", },
	{key = "XP04:PEngineer",    xprofSID = 2503,	profSID = 202,		label = "Cata Engineering",        frameID = "list1",   mapID = {"CAT"},    textInfo = "Cata Engineering", },
	{key = "XP04:PHerbalism",   xprofSID = 2553,	profSID = 182,		label = "Cata Herbalism",          frameID = "list1",   mapID = {"CAT"},    textInfo = "Cata Herbalism", },
	{key = "XP04:PInscript",    xprofSID = 2511,	profSID = 773,		label = "Cata Inscription",        frameID = "list1",   mapID = {"CAT"},    textInfo = "Cata Inscription", },
	{key = "XP04:PJewelcraft",  xprofSID = 2521,	profSID = 755,		label = "Cata Jewelcrafting",      frameID = "list1",   mapID = {"CAT"},    textInfo = "Cata Jewelcrafting", },
	{key = "XP04:PLeatherwork", xprofSID = 2529,	profSID = 165,		label = "Cata Leatherworking",     frameID = "list1",   mapID = {"CAT"},    textInfo = "Cata Leatherworking", },
	{key = "XP04:PMining",      xprofSID = 2569,	profSID = 186,		label = "Cata Mining",             frameID = "list1",   mapID = {"CAT"},    textInfo = "Cata Mining", },
	{key = "XP04:PSkinning",    xprofSID = 2561,	profSID = 393,		label = "Cata Skinning",           frameID = "list1",   mapID = {"CAT"},    textInfo = "Cata Skinning", },
	{key = "XP04:PTailor",      xprofSID = 2537,	profSID = 197,		label = "Cata Tailoring",          frameID = "list1",   mapID = {"CAT"},    textInfo = "Cata Tailoring", },
	{key = "XP04:PCooking",     xprofSID = 2545,	profSID = 185,		label = "Cata Cooking",            frameID = "list1",   mapID = {"CAT"},    textInfo = "Cata Cooking\n  - Open Profession", },
	{key = "XP04:PFishing",     xprofSID = 2589,	profSID = 356,		label = "Cata Fishing",            frameID = "list1",   mapID = {"CAT"},    textInfo = "Cata Fishing", },
--  01  CLASSIC PROFESSIONS           If Not Clearing, Try Loading a Profession's Book After Learning                      /dump C_Map.GetBestMapForUnit("player")
	{key = "XP01:PAlchemy",     xprofSID = 171,		xprofPRI = true,	label = "Classic Alchemy",         frameID = "list1",                       textInfo = "Professions\n  - Alchemy", },
	{key = "XP01:PBSmithing",   xprofSID = 164,		xprofPRI = true,	label = "Classic Blacksmithing",   frameID = "list1",                       textInfo = " - Blacksmithing", },
	{key = "XP01:PEnchant",     xprofSID = 333,		xprofPRI = true,	label = "Classic Enchanting",      frameID = "list1",                       textInfo = " - Enchanting", },
	{key = "XP01:PEngineer",    xprofSID = 202,		xprofPRI = true,	label = "Classic Engineering",     frameID = "list1",                       textInfo = " - Engineering", },
	{key = "XP01:PHerbalism",   xprofSID = 182,		xprofPRI = true,	label = "Classic Herbalism",       frameID = "list1",                       textInfo = " - Herbalism", },
	{key = "XP01:PInscript",    xprofSID = 773,		xprofPRI = true,	label = "Classic Inscription",     frameID = "list1",                       textInfo = " - Inscription", },
	{key = "XP01:PJewelcraft",  xprofSID = 755,		xprofPRI = true,	label = "Classic Jewelcrafting",   frameID = "list1",                       textInfo = " - Jewelcrafting", },
	{key = "XP01:PLeatherwork", xprofSID = 165,		xprofPRI = true,	label = "Classic Leatherworking",  frameID = "list1",                       textInfo = " - Leatherworking", },
	{key = "XP01:PMining",      xprofSID = 186,		xprofPRI = true,	label = "Classic Mining",          frameID = "list1",                       textInfo = " - Mining", },
	{key = "XP01:PSkinning",    xprofSID = 393,		xprofPRI = true,	label = "Classic Skinning",        frameID = "list1",                       textInfo = " - Skinning", },
	{key = "XP01:PTailor",      xprofSID = 197,		xprofPRI = true,	label = "Classic Tailoring",       frameID = "list1",                       textInfo = " - Tailoring\n ", },
	{key = "XP01:PCooking",     xprofSID = 185,							label = "Classic Cooking",         frameID = "list1",                       textInfo = " - Cooking", },
	{key = "XP01:PFishing",     xprofSID = 356,							label = "Classic Fishing",         frameID = "list1",                       textInfo = " - Fishing", },
--  Guild Cloaks
	{key = "XP04:GuildCloak1A",	faction = "A",							label = "Guild Cloak A1",          frameID = "list2",    mapID = {"STW"},   textInfo = "GUILD CLOAK",			size = 22, color = "1eff00", align = "center", showIf = { factionID = 1168, minStanding = 6 },                                                              complete = { any = { { itemIDs = { 63352 }, includeBank = true }, }, }, },
	{key = "XP04:GuildCloak2A", faction = "A",							label = "Guild Cloak A2",          frameID = "list2",    mapID = {"STW"},   textInfo = "GUILD CLOAK",			size = 22, color = "0070dd", align = "center", showIf = { all = { { factionID = 1168, minStanding = 7 }, { itemIDs = { 63352 }, includeBank = true }, }, }, complete = { any = { { itemIDs = { 63206 }, includeBank = true }, }, }, },
	{key = "XP04:GuildCloak3A", faction = "A",							label = "Guild Cloak A3",          frameID = "list2",    mapID = {"STW"},   textInfo = "GUILD CLOAK",			size = 22, color = "a335ee", align = "center", showIf = { all = { { factionID = 1168, minStanding = 8 }, { itemIDs = { 63206 }, includeBank = true }, }, }, complete = { any = { { itemIDs = { 65360 }, includeBank = true }, }, }, },
	{key = "XP04:GuildCloak1H", faction = "H",							label = "Guild Cloak H1",          frameID = "list2",    mapID = {"ORG"},   textInfo = "GUILD CLOAK",			size = 22, color = "1eff00", align = "center", showIf = { factionID = 1168, minStanding = 6 },                                                              complete = { any = { { itemIDs = { 63353 }, includeBank = true }, }, }, },
	{key = "XP04:GuildCloak2H", faction = "H",							label = "Guild Cloak H2",          frameID = "list2",    mapID = {"ORG"},   textInfo = "GUILD CLOAK",			size = 22, color = "0070dd", align = "center", showIf = { all = { { factionID = 1168, minStanding = 7 }, { itemIDs = { 63353 }, includeBank = true }, }, }, complete = { any = { { itemIDs = { 63207 }, includeBank = true }, }, }, },
	{key = "XP04:GuildCloak3H", faction = "H",							label = "Guild Cloak H3",          frameID = "list2",    mapID = {"ORG"},   textInfo = "GUILD CLOAK",			size = 22, color = "a335ee", align = "center", showIf = { all = { { factionID = 1168, minStanding = 8 }, { itemIDs = { 63207 }, includeBank = true }, }, }, complete = { any = { { itemIDs = { 65274 }, includeBank = true }, }, }, },
--  Phazed Zones (Try)
	{key = "XP06:PZBlasted",    questID = 66560,						label = "Blasted Phaze WoD",       frameID = "list2",   mapID = 17,         questInfo = "WARLORDS PHAZED",		size = 22,	color = "a335ee",	align = "center", },
	{key = "XP08:PZSilithus",   questID = 50659,						label = "Silithus Phaze BFA",      frameID = "list2",   mapID = 81,         questInfo = "BATTLE PHAZED",		size = 22,	color = "a335ee",	align = "center", },
	{key = "XP08:PZArathi",     questID = 50659,						label = "Arathi Phaze BFA",        frameID = "list2",   mapID = 14,         questInfo = "BATTLE PHAZED",		size = 22,	color = "a335ee",	align = "center", },
	{key = "XP08:PZTirisfal",   questID = 52758,						label = "Tirisfal Phaze BFA",      frameID = "list2",   mapID = {18,2070},  questInfo = "BATTLE PHAZED",		size = 22,	color = "a335ee",	align = "center", },
	{key = "XP08:PZDarkshore",  questID = 52758,						label = "Darkshore Phaze BFA",     frameID = "list2",   mapID = 62,         questInfo = "BATTLE PHAZED",		size = 22,	color = "a335ee",	align = "center", },
--{label = "Phaze Blasted Cata", textInfo = "|cffa335eeCATACLYSM PHAZED|r", mapID = 17, frameID = "list2", questID = 66560, showIf = { completedQuestID = 66560 }, key = "zone:blastedlands:cataclysm", },

--	Lumberaxe (Housing)
	{key = "XP12:I253580",	group = "housing:vendor:lumberaxe", order = 1, label = "No Axe (Housing)", frameID = "bar1", itemInfo = "Housing Axe", restedOnly = Y, item = { itemID = 253580, required = { 1, Y, Y, 1 }, cachePurchased = Y, cachePurchasedFromBag = N, knownTooltip = Y, }, complete = { any = { { item = { itemID = 253580, count = 1, cachePurchased = Y, cachePurchasedFromBag = N } }, }, }, },



}


for i = 1, #bakedRules do
  local r = bakedRules[i]
  if type(r) == "table" then
		ns.GuideHelpers.NormalizeRule(r, EXPANSION_ID, EXPANSION_NAME)
    ns.rules[#ns.rules + 1] = r
  end
end
