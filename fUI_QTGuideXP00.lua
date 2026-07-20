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
  {label = "Midnight Alchemy",        frameID = "list1", professionSkillLineID = 171, missingProfessionSkillLineID = 2906,         textInfo = "Midnight Alchemy",         key = "XP12:Prof:Alchemy",              locationID = {2393, }, },
  {label = "Midnight Blacksmithing",  frameID = "list1", professionSkillLineID = 164, missingProfessionSkillLineID = 2907,         textInfo = "Midnight Blacksmithing",   key = "XP12:Prof:Blacksmithing",        locationID = {2393, }, },
  {label = "Midnight Enchanting",     frameID = "list1", professionSkillLineID = 333, missingProfessionSkillLineID = 2909,         textInfo = "Midnight Enchanting",      key = "XP12:Prof:Enchanting",           locationID = {2393, }, },
  {label = "Midnight Engineering",    frameID = "list1", professionSkillLineID = 202, missingProfessionSkillLineID = 2910,         textInfo = "Midnight Engineering",     key = "XP12:Prof:Engineering",          locationID = {2393, }, },
  {label = "Midnight Herbalism",      frameID = "list1", professionSkillLineID = 182, missingProfessionSkillLineID = 2912,         textInfo = "Midnight Herbalism",       key = "XP12:Prof:Herbalism",            locationID = {2393, }, },
  {label = "Midnight Inscription",    frameID = "list1", professionSkillLineID = 773, missingProfessionSkillLineID = 2913,         textInfo = "Midnight Inscription",     key = "XP12:Prof:Inscription",          locationID = {2393, }, },
  {label = "Midnight Jewelcrafting",  frameID = "list1", professionSkillLineID = 755, missingProfessionSkillLineID = 2914,         textInfo = "Midnight Jewelcrafting",   key = "XP12:Prof:Jewelcrafting",        locationID = {2393, }, },
  {label = "Midnight Leatherworking", frameID = "list1", professionSkillLineID = 165, missingProfessionSkillLineID = 2915,         textInfo = "Midnight Leatherworking",  key = "XP12:Prof:Leatherworking",       locationID = {2393, }, },
  {label = "Midnight Mining",         frameID = "list1", professionSkillLineID = 186, missingProfessionSkillLineID = 2916,         textInfo = "Midnight Mining",          key = "XP12:Prof:Mining",               locationID = {2393, }, },
  {label = "Midnight Skinning",       frameID = "list1", professionSkillLineID = 393, missingProfessionSkillLineID = 2917,         textInfo = "Midnight Skinning",        key = "XP12:Prof:Skinning",             locationID = {2393, }, },
  {label = "Midnight Tailoring",      frameID = "list1", professionSkillLineID = 197, missingProfessionSkillLineID = 2918,         textInfo = "Midnight Tailoring",       key = "XP12:Prof:Tailoring",            locationID = {2393, }, },
  {label = "Midnight Cooking",        frameID = "list1", professionSkillLineID = 185, missingProfessionSkillLineID = 2908,         textInfo = "Midnight Cooking\n  - Open Prof Book", key = "XP12:Prof:Cooking",  locationID = {2393, }, },
  {label = "Midnight Fishing",        frameID = "list1", professionSkillLineID = 356, missingProfessionSkillLineID = 2911,         textInfo = "Midnight Fishing",         key = "XP12:Prof:Fishing",              locationID = {2393, }, },
  {label = "Midnight Find Fish",      frameID = "list1", professionSkillLineID = 356, missingFindFish = true, showIf = { missingFindFish = true }, textInfo = "Midnight Fish Finder\n - Olirea @ Fountain 45,60\n - Buy Angler's Guide", key = "XP12:Prof:FindFish", rested = true },

--  11   KHAZ ALGAR PROFESSIONS       If Not Clearing, Try Loading a Profession's Book After Learning                      /dump C_Map.GetBestMapForUnit("player")
  {label = "Khaz Alchemy",            frameID = "list1", professionSkillLineID = 171, missingProfessionSkillLineID = 2871,         textInfo = "Khaz Alchemy",             key = "XP11:Prof:Alchemy",              locationID = {2339, }, },
  {label = "Khaz Blacksmithing",      frameID = "list1", professionSkillLineID = 164, missingProfessionSkillLineID = 2872,         textInfo = "Khaz Blacksmithing",       key = "XP11:Prof:Blacksmithing",        locationID = {2339, }, },
  {label = "Khaz Enchanting",         frameID = "list1", professionSkillLineID = 333, missingProfessionSkillLineID = 2874,         textInfo = "Khaz Enchanting",          key = "XP11:Prof:Enchanting",           locationID = {2339, }, },
  {label = "Khaz Engineering",        frameID = "list1", professionSkillLineID = 202, missingProfessionSkillLineID = 2875,         textInfo = "Khaz Engineering",         key = "XP11:Prof:Engineering",          locationID = {2339, }, },
  {label = "Khaz Herbalism",          frameID = "list1", professionSkillLineID = 182, missingProfessionSkillLineID = 2877,         textInfo = "Khaz Herbalism",           key = "XP11:Prof:Herbalism",            locationID = {2339, }, },
  {label = "Khaz Inscription",        frameID = "list1", professionSkillLineID = 773, missingProfessionSkillLineID = 2878,         textInfo = "Khaz Inscription",         key = "XP11:Prof:Inscription",          locationID = {2339, }, },
  {label = "Khaz Jewelcrafting",      frameID = "list1", professionSkillLineID = 755, missingProfessionSkillLineID = 2879,         textInfo = "Khaz Jewelcrafting",       key = "XP11:Prof:Jewelcrafting",        locationID = {2339, }, },
  {label = "Khaz Leatherworking",     frameID = "list1", professionSkillLineID = 165, missingProfessionSkillLineID = 2880,         textInfo = "Khaz Leatherworking",      key = "XP11:Prof:Leatherworking",       locationID = {2339, }, },
  {label = "Khaz Mining",             frameID = "list1", professionSkillLineID = 186, missingProfessionSkillLineID = 2881,         textInfo = "Khaz Mining",              key = "XP11:Prof:Mining",               locationID = {2339, }, },
  {label = "Khaz Skinning",           frameID = "list1", professionSkillLineID = 393, missingProfessionSkillLineID = 2882,         textInfo = "Khaz Skinning",            key = "XP11:Prof:Skinning",             locationID = {2339, }, },
  {label = "Khaz Tailoring",          frameID = "list1", professionSkillLineID = 197, missingProfessionSkillLineID = 2883,         textInfo = "Khaz Tailoring",           key = "XP11:Prof:Tailoring",            locationID = {2339, }, },
  {label = "Khaz Cooking",            frameID = "list1", professionSkillLineID = 185, missingProfessionSkillLineID = 2873,         textInfo = "Khaz Cooking\n  - Open Prof Book", key = "XP11:Prof:Cooking",      locationID = {2339, }, },
  {label = "Khaz Fishing",            frameID = "list1", professionSkillLineID = 356, missingProfessionSkillLineID = 2876,         textInfo = "Khaz Fishing",             key = "XP11:Prof:Fishing",              locationID = {2339, }, },

--  10   DRAGONFLIGHT PROFESSIONS     If Not Clearing, Try Loading a Profession's Book After Learning                      /dump C_Map.GetBestMapForUnit("player")
  {label = "Dragon Alchemy",          frameID = "list1", professionSkillLineID = 171, missingProfessionSkillLineID = 2823,         textInfo = "Dragon Alchemy",           key = "XP10:Prof:Alchemy",              locationID = {1978, }, },
  {label = "Dragon Blacksmithing",    frameID = "list1", professionSkillLineID = 164, missingProfessionSkillLineID = 2822,         textInfo = "Dragon Blacksmithing",     key = "XP10:Prof:Blacksmithing",        locationID = {1978, }, },
  {label = "Dragon Enchanting",       frameID = "list1", professionSkillLineID = 333, missingProfessionSkillLineID = 2825,         textInfo = "Dragon Enchanting",        key = "XP10:Prof:Enchanting",           locationID = {1978, }, },
  {label = "Dragon Engineering",      frameID = "list1", professionSkillLineID = 202, missingProfessionSkillLineID = 2827,         textInfo = "Dragon Engineering",       key = "XP10:Prof:Engineering",          locationID = {1978, }, },
  {label = "Dragon Herbalism",        frameID = "list1", professionSkillLineID = 182, missingProfessionSkillLineID = 2832,         textInfo = "Dragon Herbalism",         key = "XP10:Prof:Herbalism",            locationID = {1978, }, },
  {label = "Dragon Inscription",      frameID = "list1", professionSkillLineID = 773, missingProfessionSkillLineID = 2828,         textInfo = "Dragon Inscription",       key = "XP10:Prof:Inscription",          locationID = {1978, }, },
  {label = "Dragon Jewelcrafting",    frameID = "list1", professionSkillLineID = 755, missingProfessionSkillLineID = 2829,         textInfo = "Dragon Jewelcrafting",     key = "XP10:Prof:Jewelcrafting",        locationID = {1978, }, },
  {label = "Dragon Leatherworking",   frameID = "list1", professionSkillLineID = 165, missingProfessionSkillLineID = 2830,         textInfo = "Dragon Leatherworking",    key = "XP10:Prof:Leatherworking",       locationID = {1978, }, },
  {label = "Dragon Mining",           frameID = "list1", professionSkillLineID = 186, missingProfessionSkillLineID = 2833,         textInfo = "Dragon Mining",            key = "XP10:Prof:Mining",               locationID = {1978, }, },
  {label = "Dragon Skinning",         frameID = "list1", professionSkillLineID = 393, missingProfessionSkillLineID = 2834,         textInfo = "Dragon Skinning",          key = "XP10:Prof:Skinning",             locationID = {1978, }, },
  {label = "Dragon Tailoring",        frameID = "list1", professionSkillLineID = 197, missingProfessionSkillLineID = 2831,         textInfo = "Dragon Tailoring",         key = "XP10:Prof:Tailoring",            locationID = {1978, }, },
  {label = "Dragon Cooking",          frameID = "list1", professionSkillLineID = 185, missingProfessionSkillLineID = 2824,         textInfo = "Dragon Cooking\n  - Open Prof Book", key = "XP10:Prof:Cooking",    locationID = {1978, }, },
  {label = "Dragon Fishing",          frameID = "list1", professionSkillLineID = 356, missingProfessionSkillLineID = 2826,         textInfo = "Dragon Fishing",           key = "XP10:Prof:Fishing",              locationID = {1978, }, },

--  09   SHADOWLANDS PROFESSIONS      If Not Clearing, Try Loading a Profession's Book After Learning                      /dump C_Map.GetBestMapForUnit("player")
  {label = "Shadow Alchemy",          frameID = "list1", professionSkillLineID = 171, missingProfessionSkillLineID = 2750,         textInfo = "Shadow Alchemy",           key = "XP09:Prof:Alchemy",              locationID = {1670, }, },
  {label = "Shadow Blacksmithing",    frameID = "list1", professionSkillLineID = 164, missingProfessionSkillLineID = 2751,         textInfo = "Shadow Blacksmithing",     key = "XP09:Prof:Blacksmithing",        locationID = {1670, }, },
  {label = "Shadow Enchanting",       frameID = "list1", professionSkillLineID = 333, missingProfessionSkillLineID = 2753,         textInfo = "Shadow Enchanting",        key = "XP09:Prof:Enchanting",           locationID = {1670, }, },
  {label = "Shadow Engineering",      frameID = "list1", professionSkillLineID = 202, missingProfessionSkillLineID = 2755,         textInfo = "Shadow Engineering",       key = "XP09:Prof:Engineering",          locationID = {1670, }, },
  {label = "Shadow Herbalism",        frameID = "list1", professionSkillLineID = 182, missingProfessionSkillLineID = 2760,         textInfo = "Shadow Herbalism",         key = "XP09:Prof:Herbalism",            locationID = {1670, }, },
  {label = "Shadow Inscription",      frameID = "list1", professionSkillLineID = 773, missingProfessionSkillLineID = 2756,         textInfo = "Shadow Inscription",       key = "XP09:Prof:Inscription",          locationID = {1670, }, },
  {label = "Shadow Jewelcrafting",    frameID = "list1", professionSkillLineID = 755, missingProfessionSkillLineID = 2757,         textInfo = "Shadow Jewelcrafting",     key = "XP09:Prof:Jewelcrafting",        locationID = {1670, }, },
  {label = "Shadow Leatherworking",   frameID = "list1", professionSkillLineID = 165, missingProfessionSkillLineID = 2758,         textInfo = "Shadow Leatherworking",    key = "XP09:Prof:Leatherworking",       locationID = {1670, }, },
  {label = "Shadow Mining",           frameID = "list1", professionSkillLineID = 186, missingProfessionSkillLineID = 2761,         textInfo = "Shadow Mining",            key = "XP09:Prof:Mining",               locationID = {1670, }, },
  {label = "Shadow Skinning",         frameID = "list1", professionSkillLineID = 393, missingProfessionSkillLineID = 2762,         textInfo = "Shadow Skinning",          key = "XP09:Prof:Skinning",             locationID = {1670, }, },
  {label = "Shadow Tailoring",        frameID = "list1", professionSkillLineID = 197, missingProfessionSkillLineID = 2759,         textInfo = "Shadow Tailoring",         key = "XP09:Prof:Tailoring",            locationID = {1670, }, },
  {label = "Shadow Cooking",          frameID = "list1", professionSkillLineID = 185, missingProfessionSkillLineID = 2752,         textInfo = "Shadow Cooking\n  - Open Prof Book", key = "XP09:Prof:Cooking",    locationID = {1670, }, },
  {label = "Shadow Fishing",          frameID = "list1", professionSkillLineID = 356, missingProfessionSkillLineID = 2754,         textInfo = "Shadow Fishing",           key = "XP09:Prof:Fishing",              locationID = {1670, }, },
  {label = "Shadow Fishing Rod",      frameID = "list1", item = { itemID = 180136, inBank = true, required = { 1, true, N, 0 }, }, itemInfo = " - Buy Brokers Angle'r",   key = "XP09:Prof:FishingRod",           locationID = {1670, }, },

--  08   BATTLE PROFESSIONS           If Not Clearing, Try Loading a Profession's Book After Learning                      /dump C_Map.GetBestMapForUnit("player")
  {label = "Battle Archaeology",      frameID = "list1",                              missingProfessionSkillLineID = 794,          textInfo = "Battle Archaeology",       key = "XP08:Prof:Archaeology",          locationID = {1161, 1163,}, },
  {label = "Battle Alchemy",          frameID = "list1", professionSkillLineID = 171, missingProfessionSkillLineID = 2478,         textInfo = "Battle Alchemy",           key = "XP08:Prof:Alchemy",              locationID = {1161, 1163,}, },
  {label = "Battle Blacksmithing",    frameID = "list1", professionSkillLineID = 164, missingProfessionSkillLineID = 2437,         textInfo = "Battle Blacksmithing",     key = "XP08:Prof:Blacksmithing",        locationID = {1161, 1163,}, },
  {label = "Battle Enchanting",       frameID = "list1", professionSkillLineID = 333, missingProfessionSkillLineID = 2486,         textInfo = "Battle Enchanting",        key = "XP08:Prof:Enchanting",           locationID = {1161, 1163,}, },
  {label = "Battle Engineering",      frameID = "list1", professionSkillLineID = 202, missingProfessionSkillLineID = 2499,         textInfo = "Battle Engineering",       key = "XP08:Prof:Engineering",          locationID = {1161, 1163,}, },
  {label = "Battle Herbalism",        frameID = "list1", professionSkillLineID = 182, missingProfessionSkillLineID = 2549,         textInfo = "Battle Herbalism",         key = "XP08:Prof:Herbalism",            locationID = {1161, 1163,}, },
  {label = "Battle Inscription",      frameID = "list1", professionSkillLineID = 773, missingProfessionSkillLineID = 2508,         textInfo = "Battle Inscription",       key = "XP08:Prof:Inscription",          locationID = {1161, 1163,}, },
  {label = "Battle Jewelcrafting",    frameID = "list1", professionSkillLineID = 755, missingProfessionSkillLineID = 2518,         textInfo = "Battle Jewelcrafting",     key = "XP08:Prof:Jewelcrafting",        locationID = {1161, 1163,}, },
  {label = "Battle Leatherworking",   frameID = "list1", professionSkillLineID = 165, missingProfessionSkillLineID = 2525,         textInfo = "Battle Leatherworking",    key = "XP08:Prof:Leatherworking",       locationID = {1161, 1163,}, },
  {label = "Battle Mining",           frameID = "list1", professionSkillLineID = 186, missingProfessionSkillLineID = 2565,         textInfo = "Battle Mining",            key = "XP08:Prof:Mining",               locationID = {1161, 1163,}, },
  {label = "Battle Skinning",         frameID = "list1", professionSkillLineID = 393, missingProfessionSkillLineID = 2557,         textInfo = "Battle Skinning",          key = "XP08:Prof:Skinning",             locationID = {1161, 1163,}, },
  {label = "Battle Tailoring",        frameID = "list1", professionSkillLineID = 197, missingProfessionSkillLineID = 2533,         textInfo = "Battle Tailoring",         key = "XP08:Prof:Tailoring",            locationID = {1161, 1163,}, },
  {label = "Battle Cooking",          frameID = "list1", professionSkillLineID = 185, missingProfessionSkillLineID = 2541,         textInfo = "Battle Cooking\n  - Open Prof Book", key = "XP08:Prof:Cooking",    locationID = {1161, 1163,}, },
  {label = "Battle Fishing",          frameID = "list1", professionSkillLineID = 356, missingProfessionSkillLineID = 2585,         textInfo = "Battle Fishing",           key = "XP08:Prof:Fishing",              locationID = {1161, 1163,}, },

--  07  LEGION PROFESSIONS            If Not Clearing, Try Loading a Profession's Book After Learning                      /dump C_Map.GetBestMapForUnit("player")
  {label = "Legion Alchemy",          frameID = "list1", professionSkillLineID = 171, missingProfessionSkillLineID = 2479,         textInfo = "Legion Alchemy",           key = "XP07:Prof:Alchemy",              locationID = {6666666,}, },
  {label = "Legion Blacksmithing",    frameID = "list1", professionSkillLineID = 164, missingProfessionSkillLineID = 2454,         textInfo = "Legion Blacksmithing",     key = "XP07:Prof:Blacksmithing",        locationID = {6666666,}, },
  {label = "Legion Enchanting",       frameID = "list1", professionSkillLineID = 333, missingProfessionSkillLineID = 2487,         textInfo = "Legion Enchanting",        key = "XP07:Prof:Enchanting",           locationID = {6666666,}, },
  {label = "Legion Engineering",      frameID = "list1", professionSkillLineID = 202, missingProfessionSkillLineID = 2500,         textInfo = "Legion Engineering",       key = "XP07:Prof:Engineering",          locationID = {6666666,}, },
  {label = "Legion Herbalism",        frameID = "list1", professionSkillLineID = 182, missingProfessionSkillLineID = 2550,         textInfo = "Legion Herbalism",         key = "XP07:Prof:Herbalism",            locationID = {6666666,}, },
  {label = "Legion Inscription",      frameID = "list1", professionSkillLineID = 773, missingProfessionSkillLineID = 2508,         textInfo = "Legion Inscription",       key = "XP07:Prof:Inscription",          locationID = {6666666,}, },
  {label = "Legion Jewelcrafting",    frameID = "list1", professionSkillLineID = 755, missingProfessionSkillLineID = 2518,         textInfo = "Legion Jewelcrafting",     key = "XP07:Prof:Jewelcrafting",        locationID = {6666666,}, },
  {label = "Legion Leatherworking",   frameID = "list1", professionSkillLineID = 165, missingProfessionSkillLineID = 2526,         textInfo = "Legion Leatherworking",    key = "XP07:Prof:Leatherworking",       locationID = {6666666,}, },
  {label = "Legion Mining",           frameID = "list1", professionSkillLineID = 186, missingProfessionSkillLineID = 2566,         textInfo = "Legion Mining",            key = "XP07:Prof:Mining",               locationID = {6666666,}, },
  {label = "Legion Skinning",         frameID = "list1", professionSkillLineID = 393, missingProfessionSkillLineID = 2558,         textInfo = "Legion Skinning",          key = "XP07:Prof:Skinning",             locationID = {6666666,}, },
  {label = "Legion Tailoring",        frameID = "list1", professionSkillLineID = 197, missingProfessionSkillLineID = 2534,         textInfo = "Legion Tailoring",         key = "XP07:Prof:Tailoring",            locationID = {6666666,}, },
  {label = "Legion Cooking",          frameID = "list1", professionSkillLineID = 185, missingProfessionSkillLineID = 2542,         textInfo = "Legion Cooking\n  - Open Prof Book", key = "XP07:Prof:Cooking",    locationID = {6666666,}, },
  {label = "Legion Fishing",          frameID = "list1", professionSkillLineID = 356, missingProfessionSkillLineID = 2586,         textInfo = "Legion Fishing",           key = "XP07:Prof:Fishing",              locationID = {6666666,}, },

--  06  WARLORDS PROFESSIONS          If Not Clearing, Try Loading a Profession's Book After Learning                      /dump C_Map.GetBestMapForUnit("player")
  {label = "Draenor Alchemy",         frameID = "list1", professionSkillLineID = 171, missingProfessionSkillLineID = 2480,         textInfo = "Draenor Alchemy",          key = "XP06:Prof:Alchemy",              locationID = {6666666,}, },
  {label = "Draenor Blacksmithing",   frameID = "list1", professionSkillLineID = 164, missingProfessionSkillLineID = 2472,         textInfo = "Draenor Blacksmithing",    key = "XP06:Prof:Blacksmithing",        locationID = {6666666,}, },
  {label = "Draenor Enchanting",      frameID = "list1", professionSkillLineID = 333, missingProfessionSkillLineID = 2488,         textInfo = "Draenor Enchanting",       key = "XP06:Prof:Enchanting",           locationID = {6666666,}, },
  {label = "Draenor Engineering",     frameID = "list1", professionSkillLineID = 202, missingProfessionSkillLineID = 2501,         textInfo = "Draenor Engineering",      key = "XP06:Prof:Engineering",          locationID = {6666666,}, },
  {label = "Draenor Herbalism",       frameID = "list1", professionSkillLineID = 182, missingProfessionSkillLineID = 2551,         textInfo = "Draenor Herbalism",        key = "XP06:Prof:Herbalism",            locationID = {6666666,}, },
  {label = "Draenor Inscription",     frameID = "list1", professionSkillLineID = 773, missingProfessionSkillLineID = 2509,         textInfo = "Draenor Inscription",      key = "XP06:Prof:Inscription",          locationID = {6666666,}, },
  {label = "Draenor Jewelcrafting",   frameID = "list1", professionSkillLineID = 755, missingProfessionSkillLineID = 2519,         textInfo = "Draenor Jewelcrafting",    key = "XP06:Prof:Jewelcrafting",        locationID = {6666666,}, },
  {label = "Draenor Leatherworking",  frameID = "list1", professionSkillLineID = 165, missingProfessionSkillLineID = 2527,         textInfo = "Draenor Leatherworking",   key = "XP06:Prof:Leatherworking",       locationID = {6666666,}, },
  {label = "Draenor Mining",          frameID = "list1", professionSkillLineID = 186, missingProfessionSkillLineID = 2567,         textInfo = "Draenor Mining",           key = "XP06:Prof:Mining",               locationID = {6666666,}, },
  {label = "Draenor Skinning",        frameID = "list1", professionSkillLineID = 393, missingProfessionSkillLineID = 2559,         textInfo = "Draenor Skinning",         key = "XP06:Prof:Skinning",             locationID = {6666666,}, },
  {label = "Draenor Tailoring",       frameID = "list1", professionSkillLineID = 197, missingProfessionSkillLineID = 2535,         textInfo = "Draenor Tailoring",        key = "XP06:Prof:Tailoring",            locationID = {6666666,}, },
  {label = "Draenor Cooking",         frameID = "list1", professionSkillLineID = 185, missingProfessionSkillLineID = 2543,         textInfo = "Draenor Cooking\n  - Open Prof Book", key = "XP06:Prof:Cooking",   locationID = {6666666,}, },
  {label = "Draenor Fishing",         frameID = "list1", professionSkillLineID = 356, missingProfessionSkillLineID = 2587,         textInfo = "Draenor Fishing",          key = "XP06:Prof:Fishing",              locationID = {6666666,}, },

--  05  PANDARIA PROFESSIONS          If Not Clearing, Try Loading a Profession's Book After Learning                      /dump C_Map.GetBestMapForUnit("player")
  {label = "Mists Alchemy",           frameID = "list1", professionSkillLineID = 171, missingProfessionSkillLineID = 2481,         textInfo = "Mists Alchemy",            key = "XP05:Prof:Alchemy",              locationID = {371, 376, 379, 388, 390, 391, 393, 418, 422,}, },
  {label = "Mists Blacksmithing",     frameID = "list1", professionSkillLineID = 164, missingProfessionSkillLineID = 2473,         textInfo = "Mists Blacksmithing",      key = "XP05:Prof:Blacksmithing",        locationID = {371, 376, 379, 388, 390, 391, 393, 418, 422,}, },
  {label = "Mists Enchanting",        frameID = "list1", professionSkillLineID = 333, missingProfessionSkillLineID = 2489,         textInfo = "Mists Enchanting",         key = "XP05:Prof:Enchanting",           locationID = {371, 376, 379, 388, 390, 391, 393, 418, 422,}, },
  {label = "Mists Engineering",       frameID = "list1", professionSkillLineID = 202, missingProfessionSkillLineID = 2502,         textInfo = "Mists Engineering",        key = "XP05:Prof:Engineering",          locationID = {371, 376, 379, 388, 390, 391, 393, 418, 422,}, },
  {label = "Mists Herbalism",         frameID = "list1", professionSkillLineID = 182, missingProfessionSkillLineID = 2552,         textInfo = "Mists Herbalism",          key = "XP05:Prof:Herbalism",            locationID = {371, 376, 379, 388, 390, 391, 393, 418, 422,}, },
  {label = "Mists Inscription",       frameID = "list1", professionSkillLineID = 773, missingProfessionSkillLineID = 2510,         textInfo = "Mists Inscription",        key = "XP05:Prof:Inscription",          locationID = {371, 376, 379, 388, 390, 391, 393, 418, 422,}, },
  {label = "Mists Jewelcrafting",     frameID = "list1", professionSkillLineID = 755, missingProfessionSkillLineID = 2520,         textInfo = "Mists Jewelcrafting",      key = "XP05:Prof:Jewelcrafting",        locationID = {371, 376, 379, 388, 390, 391, 393, 418, 422,}, },
  {label = "Mists Leatherworking",    frameID = "list1", professionSkillLineID = 165, missingProfessionSkillLineID = 2528,         textInfo = "Mists Leatherworking",     key = "XP05:Prof:Leatherworking",       locationID = {371, 376, 379, 388, 390, 391, 393, 418, 422,}, },
  {label = "Mists Mining",            frameID = "list1", professionSkillLineID = 186, missingProfessionSkillLineID = 2568,         textInfo = "Mists Mining",             key = "XP05:Prof:Mining",               locationID = {371, 376, 379, 388, 390, 391, 393, 418, 422,}, },
  {label = "Mists Skinning",          frameID = "list1", professionSkillLineID = 393, missingProfessionSkillLineID = 2560,         textInfo = "Mists Skinning",           key = "XP05:Prof:Skinning",             locationID = {371, 376, 379, 388, 390, 391, 393, 418, 422,}, },
  {label = "Mists Tailoring",         frameID = "list1", professionSkillLineID = 197, missingProfessionSkillLineID = 2536,         textInfo = "Mists Tailoring",          key = "XP05:Prof:Tailoring",            locationID = {371, 376, 379, 388, 390, 391, 393, 418, 422,}, },
  {label = "Mists Cooking",           frameID = "list1", professionSkillLineID = 185, missingProfessionSkillLineID = 2544,         textInfo = "Mists Cooking\n  - Open Prof Book", key = "XP05:Prof:Cooking",     locationID = {371, 376, 379, 388, 390, 391, 393, 418, 422,}, },
  {label = "Mists Fishing",           frameID = "list1", professionSkillLineID = 356, missingProfessionSkillLineID = 2588,         textInfo = "Mists Fishing",            key = "XP05:Prof:Fishing",              locationID = {371, 376, 379, 388, 390, 391, 393, 418, 422,}, },

--  04  CATACLYSM PROFESSIONS         If Not Clearing, Try Loading a Profession's Book After Learning                      /dump C_Map.GetBestMapForUnit("player")
  {label = "Cata Alchemy",            frameID = "list1", professionSkillLineID = 171, missingProfessionSkillLineID = 2482,         textInfo = "Cata Alchemy",             key = "XP04:Prof:Alchemy",              locationID = { 84, 85, }, },
  {label = "Cata Blacksmithing",      frameID = "list1", professionSkillLineID = 164, missingProfessionSkillLineID = 2474,         textInfo = "Cata Blacksmithing",       key = "XP04:Prof:Blacksmithing",        locationID = { 84, 85, }, },
  {label = "Cata Enchanting",         frameID = "list1", professionSkillLineID = 333, missingProfessionSkillLineID = 2491,         textInfo = "Cata Enchanting",          key = "XP04:Prof:Enchanting",           locationID = { 84, 85, }, },
  {label = "Cata Engineering",        frameID = "list1", professionSkillLineID = 202, missingProfessionSkillLineID = 2503,         textInfo = "Cata Engineering",         key = "XP04:Prof:Engineering",          locationID = { 84, 85, }, },
  {label = "Cata Herbalism",          frameID = "list1", professionSkillLineID = 182, missingProfessionSkillLineID = 2553,         textInfo = "Cata Herbalism",           key = "XP04:Prof:Herbalism",            locationID = { 84, 85, }, },
  {label = "Cata Inscription",        frameID = "list1", professionSkillLineID = 773, missingProfessionSkillLineID = 2511,         textInfo = "Cata Inscription",         key = "XP04:Prof:Inscription",          locationID = { 84, 85, }, },
  {label = "Cata Jewelcrafting",      frameID = "list1", professionSkillLineID = 755, missingProfessionSkillLineID = 2521,         textInfo = "Cata Jewelcrafting",       key = "XP04:Prof:Jewelcrafting",        locationID = { 84, 85, }, },
  {label = "Cata Leatherworking",     frameID = "list1", professionSkillLineID = 165, missingProfessionSkillLineID = 2529,         textInfo = "Cata Leatherworking",      key = "XP04:Prof:Leatherworking",       locationID = { 84, 85, }, },
  {label = "Cata Mining",             frameID = "list1", professionSkillLineID = 186, missingProfessionSkillLineID = 2569,         textInfo = "Cata Mining",              key = "XP04:Prof:Mining",               locationID = { 84, 85, }, },
  {label = "Cata Skinning",           frameID = "list1", professionSkillLineID = 393, missingProfessionSkillLineID = 2561,         textInfo = "Cata Skinning",            key = "XP04:Prof:Skinning",             locationID = { 84, 85, }, },
  {label = "Cata Tailoring",          frameID = "list1", professionSkillLineID = 197, missingProfessionSkillLineID = 2537,         textInfo = "Cata Tailoring",           key = "XP04:Prof:Tailoring",            locationID = { 84, 85, }, },
  {label = "Cata Cooking",            frameID = "list1", professionSkillLineID = 185, missingProfessionSkillLineID = 2545,         textInfo = "Cata Cooking\n  - Open Prof Book", key = "XP04:Prof:Cooking",      locationID = { 84, 85, }, },
  {label = "Cata Fishing",            frameID = "list1", professionSkillLineID = 356, missingProfessionSkillLineID = 2589,         textInfo = "Cata Fishing",             key = "XP04:Prof:Fishing",              locationID = { 84, 85, }, },

--  01  CLASSIC PROFESSIONS           If Not Clearing, Try Loading a Profession's Book After Learning                      /dump C_Map.GetBestMapForUnit("player")
  {label = "Classic Alchemy",         frameID = "list1", missingPrimaryProfessions = true, missingProfessionSkillLineID = 171, key = "XP01:Prof:Alchemy", },
  {label = "Classic Blacksmithing",   frameID = "list1", missingPrimaryProfessions = true, missingProfessionSkillLineID = 164, key = "XP01:Prof:Blacksmithing", },
  {label = "Classic Enchanting",      frameID = "list1", missingPrimaryProfessions = true, missingProfessionSkillLineID = 333, key = "XP01:Prof:Enchanting", },
  {label = "Classic Engineering",     frameID = "list1", missingPrimaryProfessions = true, missingProfessionSkillLineID = 202, key = "XP01:Prof:Engineering", },
  {label = "Classic Herbalism",       frameID = "list1", missingPrimaryProfessions = true, missingProfessionSkillLineID = 182, key = "XP01:Prof:Herbalism", },
  {label = "Classic Inscription",     frameID = "list1", missingPrimaryProfessions = true, missingProfessionSkillLineID = 773, key = "XP01:Prof:Inscription", },
  {label = "Classic Jewelcrafting",   frameID = "list1", missingPrimaryProfessions = true, missingProfessionSkillLineID = 755, key = "XP01:Prof:Jewelcrafting", },
  {label = "Classic Leatherworking",  frameID = "list1", missingPrimaryProfessions = true, missingProfessionSkillLineID = 165, key = "XP01:Prof:Leatherworking", },
  {label = "Classic Mining",          frameID = "list1", missingPrimaryProfessions = true, missingProfessionSkillLineID = 186, key = "XP01:Prof:Mining", },
  {label = "Classic Skinning",        frameID = "list1", missingPrimaryProfessions = true, missingProfessionSkillLineID = 393, key = "XP01:Prof:Skinning", },
  {label = "Classic Tailoring",       frameID = "list1", missingPrimaryProfessions = true, missingProfessionSkillLineID = 197, key = "XP01:Prof:Tailoring", },
  {label = "Classic Cooking",         frameID = "list1",                                   missingProfessionSkillLineID = 185, key = "XP01:Prof:Cooking", },
  {label = "Classic Fishing",         frameID = "list1",                                   missingProfessionSkillLineID = 356, key = "XP01:Prof:Fishing", },

  {label = "Guild Cloak A1",          frameID = "bar1",  textInfo = "|cff1eff00Guild Cloak|r", faction = "alliance",       locationID = 84, showIf = { factionID = 1168, minStanding = 6 },                                                              complete = { any = { { itemIDs = { 63352 }, includeBank = true }, }, }, key = "rep:guild:alliance:cloak1", },
  {label = "Guild Cloak A2",          frameID = "bar1",  textInfo = "|cff0070ddGuild Cloak|r", faction = "alliance",       locationID = 84, showIf = { all = { { factionID = 1168, minStanding = 7 }, { itemIDs = { 63352 }, includeBank = true }, }, }, complete = { any = { { itemIDs = { 63206 }, includeBank = true }, }, }, key = "rep:guild:alliance:cloak2", },
  {label = "Guild Cloak A3",          frameID = "bar1",  textInfo = "|cffa335eeGuild Cloak|r", faction = "alliance",       locationID = 84, showIf = { all = { { factionID = 1168, minStanding = 8 }, { itemIDs = { 63206 }, includeBank = true }, }, }, complete = { any = { { itemIDs = { 65360 }, includeBank = true }, }, }, key = "rep:guild:alliance:cloak3", },
  {label = "Guild Cloak H1",          frameID = "bar1",  textInfo = "|cff1eff00Guild Cloak|r", faction = "horde",          locationID = 85, showIf = { factionID = 1168, minStanding = 6 },                                                              complete = { any = { { itemIDs = { 63353 }, includeBank = true }, }, }, key = "rep:guild:horde:cloak1",    },
  {label = "Guild Cloak H2",          frameID = "bar1",  textInfo = "|cff0070ddGuild Cloak|r", faction = "horde",          locationID = 85, showIf = { all = { { factionID = 1168, minStanding = 7 }, { itemIDs = { 63353 }, includeBank = true }, }, }, complete = { any = { { itemIDs = { 63207 }, includeBank = true }, }, }, key = "rep:guild:horde:cloak2",    },
  {label = "Guild Cloak H3",          frameID = "bar1",  textInfo = "|cffa335eeGuild Cloak|r", faction = "horde",          locationID = 85, showIf = { all = { { factionID = 1168, minStanding = 8 }, { itemIDs = { 63207 }, includeBank = true }, }, }, complete = { any = { { itemIDs = { 65274 }, includeBank = true }, }, }, key = "rep:guild:horde:cloak3",    },

--  /dump C_Map.GetBestMapForUnit("player") 
--{label = "Phaze Blasted Cata", textInfo = "|cffa335eeCATACLYSM PHAZED|r", locationID = 17, frameID = "list2", questID = 66560, showIf = { completedQuestID = 66560 }, key = "zone:blastedlands:cataclysm", },
{label = "Blasted Phaze WoD",   questInfo = "|cffa335eeWARLORDS PHAZED|r", locationID = 17,         frameID = "bar1", questID = 66560, key = "zone:blastedlands:warlords", },
{label = "Silithus Phaze BFA",  questInfo = "|cffa335eeBATTLE PHAZED|r",   locationID = 81,         frameID = "bar1", questID = 50659, key = "zone:silithus:bfa", },
{label = "Arathi Phaze BFA",    questInfo = "|cffa335eeBATTLE PHAZED|r",   locationID = 14,         frameID = "bar1", questID = 50659, key = "zone:arathi:bfa", },
{label = "Tirisfal Phaze BFA",  questInfo = "|cffa335eeBATTLE PHAZED|r",   locationID = {18, 2070}, frameID = "bar1", questID = 52758, key = "zone:tirisfal:bfa", },
{label = "Darkshore Phaze BFA", questInfo = "|cffa335eeBATTLE PHAZED|r",   locationID = 62,         frameID = "bar1", questID = 52758, key = "zone:darkshore:bfa", },



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
