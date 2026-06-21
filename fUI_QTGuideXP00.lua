local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB00 (Unknown/Unclassified)

ns.rules = ns.rules or {}

local EXPANSION_ID = 0
local EXPANSION_NAME = "Unclassified"

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
  {label = "Midnight Alchemy",        frameID = "list1", professionSkillLineID = 171, missingProfessionSkillLineID = 2906, locationID = 2393,       textInfo = "Midnight Alchemy",        key = "XP12:Prof:Alchemy", },
  {label = "Midnight Blacksmithing",  frameID = "list1", professionSkillLineID = 164, missingProfessionSkillLineID = 2907, locationID = 2393,       textInfo = "Midnight Blacksmithing",  key = "XP12:Prof:Blacksmithing", },
  {label = "Midnight Enchanting",     frameID = "list1", professionSkillLineID = 333, missingProfessionSkillLineID = 2909, locationID = 2393,       textInfo = "Midnight Enchanting",     key = "XP12:Prof:Enchanting", },
  {label = "Midnight Engineering",    frameID = "list1", professionSkillLineID = 202, missingProfessionSkillLineID = 2910, locationID = 2393,       textInfo = "Midnight Engineering",    key = "XP12:Prof:Engineering", },
  {label = "Midnight Herbalism",      frameID = "list1", professionSkillLineID = 182, missingProfessionSkillLineID = 2912, locationID = 2393,       textInfo = "Midnight Herbalism",      key = "XP12:Prof:Herbalism", },
  {label = "Midnight Inscription",    frameID = "list1", professionSkillLineID = 773, missingProfessionSkillLineID = 2913, locationID = 2393,       textInfo = "Midnight Inscription",    key = "XP12:Prof:Inscription", },
  {label = "Midnight Jewelcrafting",  frameID = "list1", professionSkillLineID = 755, missingProfessionSkillLineID = 2914, locationID = 2393,       textInfo = "Midnight Jewelcrafting",  key = "XP12:Prof:Jewelcrafting", },
  {label = "Midnight Leatherworking", frameID = "list1", professionSkillLineID = 165, missingProfessionSkillLineID = 2915, locationID = 2393,       textInfo = "Midnight Leatherworking", key = "XP12:Prof:Leatherworking", },
  {label = "Midnight Mining",         frameID = "list1", professionSkillLineID = 186, missingProfessionSkillLineID = 2916, locationID = 2393,       textInfo = "Midnight Mining",         key = "XP12:Prof:Mining", },
  {label = "Midnight Skinning",       frameID = "list1", professionSkillLineID = 393, missingProfessionSkillLineID = 2917, locationID = 2393,       textInfo = "Midnight Skinning",       key = "XP12:Prof:Skinning", },
  {label = "Midnight Tailoring",      frameID = "list1", professionSkillLineID = 197, missingProfessionSkillLineID = 2918, locationID = 2393,       textInfo = "Midnight Tailoring",      key = "XP12:Prof:Tailoring", },
  {label = "Midnight Cooking",        frameID = "list1", professionSkillLineID = 185, missingProfessionSkillLineID = 2908, locationID = 2393,       textInfo = "Midnight Cooking\n - Open Profession After", key = "XP12:Prof:Cooking", },
  {label = "Midnight Fishing",        frameID = "list1", professionSkillLineID = 356, missingProfessionSkillLineID = 2911, locationID = 2393,       textInfo = "Midnight Fishing",        key = "XP12:Prof:Fishing", },
  {label = "Midnight Find Fish",      frameID = "list1", professionSkillLineID = 356, missingFindFish = true, showIf = { missingFindFish = true },  textInfo = "Midnight Fish Finder\n - Olirea @ Fountain 45,60\n - Buy Angler's Guide", key = "XP12:Prof:FindFish", },

--  11   KHAZ ALGAR PROFESSIONS       If Not Clearing, Try Loading a Profession's Book After Learning                      /dump C_Map.GetBestMapForUnit("player")
  {label = "Khaz Alchemy",            frameID = "list1", professionSkillLineID = 171, missingProfessionSkillLineID = 2871, locationID = 2339,       textInfo = "Khaz Alchemy",            key = "XP11:Prof:Alchemy", },
  {label = "Khaz Blacksmithing",      frameID = "list1", professionSkillLineID = 164, missingProfessionSkillLineID = 2872, locationID = 2339,       textInfo = "Khaz Blacksmithing",      key = "XP11:Prof:Blacksmithing", },
  {label = "Khaz Enchanting",         frameID = "list1", professionSkillLineID = 333, missingProfessionSkillLineID = 2874, locationID = 2339,       textInfo = "Khaz Enchanting",         key = "XP11:Prof:Enchanting", },
  {label = "Khaz Engineering",        frameID = "list1", professionSkillLineID = 202, missingProfessionSkillLineID = 2875, locationID = 2339,       textInfo = "Khaz Engineering",        key = "XP11:Prof:Engineering", },
  {label = "Khaz Herbalism",          frameID = "list1", professionSkillLineID = 182, missingProfessionSkillLineID = 2877, locationID = 2339,       textInfo = "Khaz Herbalism",          key = "XP11:Prof:Herbalism", },
  {label = "Khaz Inscription",        frameID = "list1", professionSkillLineID = 773, missingProfessionSkillLineID = 2878, locationID = 2339,       textInfo = "Khaz Inscription",        key = "XP11:Prof:Inscription", },
  {label = "Khaz Jewelcrafting",      frameID = "list1", professionSkillLineID = 755, missingProfessionSkillLineID = 2879, locationID = 2339,       textInfo = "Khaz Jewelcrafting",      key = "XP11:Prof:Jewelcrafting", },
  {label = "Khaz Leatherworking",     frameID = "list1", professionSkillLineID = 165, missingProfessionSkillLineID = 2880, locationID = 2339,       textInfo = "Khaz Leatherworking",     key = "XP11:Prof:Leatherworking", },
  {label = "Khaz Mining",             frameID = "list1", professionSkillLineID = 186, missingProfessionSkillLineID = 2881, locationID = 2339,       textInfo = "Khaz Mining",             key = "XP11:Prof:Mining", },
  {label = "Khaz Skinning",           frameID = "list1", professionSkillLineID = 393, missingProfessionSkillLineID = 2882, locationID = 2339,       textInfo = "Khaz Skinning",           key = "XP11:Prof:Skinning", },
  {label = "Khaz Tailoring",          frameID = "list1", professionSkillLineID = 197, missingProfessionSkillLineID = 2883, locationID = 2339,       textInfo = "Khaz Tailoring",          key = "XP11:Prof:Tailoring", },
  {label = "Khaz Cooking",            frameID = "list1", professionSkillLineID = 185, missingProfessionSkillLineID = 2873, locationID = 2339,       textInfo = "Khaz Cooking\n - Open Prof Book After", key = "XP11:Prof:Cooking", },
  {label = "Khaz Fishing",            frameID = "list1", professionSkillLineID = 356, missingProfessionSkillLineID = 2876, locationID = 2339,       textInfo = "Khaz Fishing",            key = "XP11:Prof:Fishing", },

--  10   DRAGONFLIGHT PROFESSIONS     If Not Clearing, Try Loading a Profession's Book After Learning                      /dump C_Map.GetBestMapForUnit("player")
  {label = "Dragon Alchemy",          frameID = "list1", professionSkillLineID = 171, missingProfessionSkillLineID = 2823, locationID = 1978,       textInfo = "Dragon Alchemy",          key = "XP10:Prof:Alchemy", },
  {label = "Dragon Blacksmithing",    frameID = "list1", professionSkillLineID = 164, missingProfessionSkillLineID = 2822, locationID = 1978,       textInfo = "Dragon Blacksmithing",    key = "XP10:Prof:Blacksmithing", },
  {label = "Dragon Enchanting",       frameID = "list1", professionSkillLineID = 333, missingProfessionSkillLineID = 2825, locationID = 1978,       textInfo = "Dragon Enchanting",       key = "XP10:Prof:Enchanting", },
  {label = "Dragon Engineering",      frameID = "list1", professionSkillLineID = 202, missingProfessionSkillLineID = 2827, locationID = 1978,       textInfo = "Dragon Engineering",      key = "XP10:Prof:Engineering", },
  {label = "Dragon Herbalism",        frameID = "list1", professionSkillLineID = 182, missingProfessionSkillLineID = 2832, locationID = 1978,       textInfo = "Dragon Herbalism",        key = "XP10:Prof:Herbalism", },
  {label = "Dragon Inscription",      frameID = "list1", professionSkillLineID = 773, missingProfessionSkillLineID = 2828, locationID = 1978,       textInfo = "Dragon Inscription",      key = "XP10:Prof:Inscription", },
  {label = "Dragon Jewelcrafting",    frameID = "list1", professionSkillLineID = 755, missingProfessionSkillLineID = 2829, locationID = 1978,       textInfo = "Dragon Jewelcrafting",    key = "XP10:Prof:Jewelcrafting", },
  {label = "Dragon Leatherworking",   frameID = "list1", professionSkillLineID = 165, missingProfessionSkillLineID = 2830, locationID = 1978,       textInfo = "Dragon Leatherworking",   key = "XP10:Prof:Leatherworking", },
  {label = "Dragon Mining",           frameID = "list1", professionSkillLineID = 186, missingProfessionSkillLineID = 2833, locationID = 1978,       textInfo = "Dragon Mining",           key = "XP10:Prof:Mining", },
  {label = "Dragon Skinning",         frameID = "list1", professionSkillLineID = 393, missingProfessionSkillLineID = 2834, locationID = 1978,       textInfo = "Dragon Skinning",         key = "XP10:Prof:Skinning", },
  {label = "Dragon Tailoring",        frameID = "list1", professionSkillLineID = 197, missingProfessionSkillLineID = 2831, locationID = 1978,       textInfo = "Dragon Tailoring",        key = "XP10:Prof:Tailoring", },
  {label = "Dragon Cooking",          frameID = "list1", professionSkillLineID = 185, missingProfessionSkillLineID = 2824, locationID = 1978,       textInfo = "Dragon Cooking\n - Open Prof Book After", key = "XP10:Prof:Cooking", },
  {label = "Dragon Fishing",          frameID = "list1", professionSkillLineID = 356, missingProfessionSkillLineID = 2826, locationID = 1978,       textInfo = "Dragon Fishing",          key = "XP10:Prof:Fishing", },

--  09   SHADOWLANDS PROFESSIONS      If Not Clearing, Try Loading a Profession's Book After Learning                      /dump C_Map.GetBestMapForUnit("player")
  {label = "Shadow Alchemy",          frameID = "list1", professionSkillLineID = 171, missingProfessionSkillLineID = 2750, locationID = 1670,       textInfo = "Shadow Alchemy",          key = "XP09:Prof:Alchemy", },
  {label = "Shadow Blacksmithing",    frameID = "list1", professionSkillLineID = 164, missingProfessionSkillLineID = 2751, locationID = 1670,       textInfo = "Shadow Blacksmithing",    key = "XP09:Prof:Blacksmithing", },
  {label = "Shadow Enchanting",       frameID = "list1", professionSkillLineID = 333, missingProfessionSkillLineID = 2753, locationID = 1670,       textInfo = "Shadow Enchanting",       key = "XP09:Prof:Enchanting", },
  {label = "Shadow Engineering",      frameID = "list1", professionSkillLineID = 202, missingProfessionSkillLineID = 2755, locationID = 1670,       textInfo = "Shadow Engineering",      key = "XP09:Prof:Engineering", },
  {label = "Shadow Herbalism",        frameID = "list1", professionSkillLineID = 182, missingProfessionSkillLineID = 2760, locationID = 1670,       textInfo = "Shadow Herbalism",        key = "XP09:Prof:Herbalism", },
  {label = "Shadow Inscription",      frameID = "list1", professionSkillLineID = 773, missingProfessionSkillLineID = 2756, locationID = 1670,       textInfo = "Shadow Inscription",      key = "XP09:Prof:Inscription", },
  {label = "Shadow Jewelcrafting",    frameID = "list1", professionSkillLineID = 755, missingProfessionSkillLineID = 2757, locationID = 1670,       textInfo = "Shadow Jewelcrafting",    key = "XP09:Prof:Jewelcrafting", },
  {label = "Shadow Leatherworking",   frameID = "list1", professionSkillLineID = 165, missingProfessionSkillLineID = 2758, locationID = 1670,       textInfo = "Shadow Leatherworking",   key = "XP09:Prof:Leatherworking", },
  {label = "Shadow Mining",           frameID = "list1", professionSkillLineID = 186, missingProfessionSkillLineID = 2761, locationID = 1670,       textInfo = "Shadow Mining",           key = "XP09:Prof:Mining", },
  {label = "Shadow Skinning",         frameID = "list1", professionSkillLineID = 393, missingProfessionSkillLineID = 2762, locationID = 1670,       textInfo = "Shadow Skinning",         key = "XP09:Prof:Skinning", },
  {label = "Shadow Tailoring",        frameID = "list1", professionSkillLineID = 197, missingProfessionSkillLineID = 2759, locationID = 1670,       textInfo = "Shadow Tailoring",        key = "XP09:Prof:Tailoring", },
  {label = "Shadow Cooking",          frameID = "list1", professionSkillLineID = 185, missingProfessionSkillLineID = 2752, locationID = 1670,       textInfo = "Shadow Cooking\n - Open Prof Book After", key = "XP09:Prof:Cooking", },
  {label = "Shadow Fishing",          frameID = "list1", professionSkillLineID = 356, missingProfessionSkillLineID = 2754, locationID = 1670,       textInfo = "Shadow Fishing",          key = "XP09:Prof:Fishing", },
  {label = "Shadow Fishing Rod",      frameID = "list1", item = { itemID = 180136, required = { 1, true, N, 0 }, },        locationID = 1670,       textInfo = " - Buy Brokers Angle'r",  key = "XP09:Prof:FishingRod", },

--  08   BATTLE PROFESSIONS           If Not Clearing, Try Loading a Profession's Book After Learning                      /dump C_Map.GetBestMapForUnit("player")
  {label = "Battle Archaeology",      frameID = "list1",                              missingProfessionSkillLineID = 794,  locationID = 1163,       textInfo = "Battle Archaeology",      key = "XP08:Prof:Archaeology", },
  {label = "Battle Alchemy",          frameID = "list1", professionSkillLineID = 171, missingProfessionSkillLineID = 2478, locationID = 1163,       textInfo = "Battle Alchemy",          key = "XP08:Prof:Alchemy", },
  {label = "Battle Blacksmithing",    frameID = "list1", professionSkillLineID = 164, missingProfessionSkillLineID = 2437, locationID = 1163,       textInfo = "Battle Blacksmithing",    key = "XP08:Prof:Blacksmithing", },
  {label = "Battle Enchanting",       frameID = "list1", professionSkillLineID = 333, missingProfessionSkillLineID = 2486, locationID = 1163,       textInfo = "Battle Enchanting",       key = "XP08:Prof:Enchanting", },
  {label = "Battle Engineering",      frameID = "list1", professionSkillLineID = 202, missingProfessionSkillLineID = 2499, locationID = 1163,       textInfo = "Battle Engineering",      key = "XP08:Prof:Engineering", },
  {label = "Battle Herbalism",        frameID = "list1", professionSkillLineID = 182, missingProfessionSkillLineID = 2549, locationID = 1163,       textInfo = "Battle Herbalism",        key = "XP08:Prof:Herbalism", },
  {label = "Battle Inscription",      frameID = "list1", professionSkillLineID = 773, missingProfessionSkillLineID = 2508, locationID = 1163,       textInfo = "Battle Inscription",      key = "XP08:Prof:Inscription", },
  {label = "Battle Jewelcrafting",    frameID = "list1", professionSkillLineID = 755, missingProfessionSkillLineID = 2518, locationID = 1163,       textInfo = "Battle Jewelcrafting",    key = "XP08:Prof:Jewelcrafting", },
  {label = "Battle Leatherworking",   frameID = "list1", professionSkillLineID = 165, missingProfessionSkillLineID = 2525, locationID = 1163,       textInfo = "Battle Leatherworking",   key = "XP08:Prof:Leatherworking", },
  {label = "Battle Mining",           frameID = "list1", professionSkillLineID = 186, missingProfessionSkillLineID = 2565, locationID = 1163,       textInfo = "Battle Mining",           key = "XP08:Prof:Mining", },
  {label = "Battle Skinning",         frameID = "list1", professionSkillLineID = 393, missingProfessionSkillLineID = 2557, locationID = 1163,       textInfo = "Battle Skinning",         key = "XP08:Prof:Skinning", },
  {label = "Battle Tailoring",        frameID = "list1", professionSkillLineID = 197, missingProfessionSkillLineID = 2533, locationID = 1163,       textInfo = "Battle Tailoring",        key = "XP08:Prof:Tailoring", },
  {label = "Battle Cooking",          frameID = "list1", professionSkillLineID = 185, missingProfessionSkillLineID = 2541, locationID = 1163,       textInfo = "Battle Cooking\n - Open Profession After", key = "XP08:Prof:Cooking", },
  {label = "Battle Fishing",          frameID = "list1", professionSkillLineID = 356, missingProfessionSkillLineID = 2585, locationID = 1163,       textInfo = "Battle Fishing",          key = "XP08:Prof:Fishing", },

--  07  LEGION PROFESSIONS            If Not Clearing, Try Loading a Profession's Book After Learning                      /dump C_Map.GetBestMapForUnit("player")
  {label = "Legion Alchemy",          frameID = "list1", professionSkillLineID = 171, missingProfessionSkillLineID = 2479, locationID = 6666666,    textInfo = "Legion Alchemy",          key = "XP07:Prof:Alchemy", },
  {label = "Legion Blacksmithing",    frameID = "list1", professionSkillLineID = 164, missingProfessionSkillLineID = 2454, locationID = 6666666,    textInfo = "Legion Blacksmithing",    key = "XP07:Prof:Blacksmithing", },
  {label = "Legion Enchanting",       frameID = "list1", professionSkillLineID = 333, missingProfessionSkillLineID = 2487, locationID = 6666666,    textInfo = "Legion Enchanting",       key = "XP07:Prof:Enchanting", },
  {label = "Legion Engineering",      frameID = "list1", professionSkillLineID = 202, missingProfessionSkillLineID = 2500, locationID = 6666666,    textInfo = "Legion Engineering",      key = "XP07:Prof:Engineering", },
  {label = "Legion Herbalism",        frameID = "list1", professionSkillLineID = 182, missingProfessionSkillLineID = 2550, locationID = 6666666,    textInfo = "Legion Herbalism",        key = "XP07:Prof:Herbalism", },
  {label = "Legion Inscription",      frameID = "list1", professionSkillLineID = 773, missingProfessionSkillLineID = 2508, locationID = 6666666,    textInfo = "Legion Inscription",      key = "XP07:Prof:Inscription", },
  {label = "Legion Jewelcrafting",    frameID = "list1", professionSkillLineID = 755, missingProfessionSkillLineID = 2518, locationID = 6666666,    textInfo = "Legion Jewelcrafting",    key = "XP07:Prof:Jewelcrafting", },
  {label = "Legion Leatherworking",   frameID = "list1", professionSkillLineID = 165, missingProfessionSkillLineID = 2526, locationID = 6666666,    textInfo = "Legion Leatherworking",   key = "XP07:Prof:Leatherworking", },
  {label = "Legion Mining",           frameID = "list1", professionSkillLineID = 186, missingProfessionSkillLineID = 2566, locationID = 6666666,    textInfo = "Legion Mining",           key = "XP07:Prof:Mining", },
  {label = "Legion Skinning",         frameID = "list1", professionSkillLineID = 393, missingProfessionSkillLineID = 2558, locationID = 6666666,    textInfo = "Legion Skinning",         key = "XP07:Prof:Skinning", },
  {label = "Legion Tailoring",        frameID = "list1", professionSkillLineID = 197, missingProfessionSkillLineID = 2534, locationID = 6666666,    textInfo = "Legion Tailoring",        key = "XP07:Prof:Tailoring", },
  {label = "Legion Cooking",          frameID = "list1", professionSkillLineID = 185, missingProfessionSkillLineID = 2542, locationID = 6666666,    textInfo = "Legion Cooking\n - Open Prof Book After", key = "XP07:Prof:Cooking", },
  {label = "Legion Fishing",          frameID = "list1", professionSkillLineID = 356, missingProfessionSkillLineID = 2586, locationID = 6666666,    textInfo = "Legion Fishing",          key = "XP07:Prof:Fishing", },

--  06  WARLORDS PROFESSIONS          If Not Clearing, Try Loading a Profession's Book After Learning                      /dump C_Map.GetBestMapForUnit("player")
  {label = "Draenor Alchemy",         frameID = "list1", professionSkillLineID = 171, missingProfessionSkillLineID = 2480, locationID = 6666666,    textInfo = "Draenor Alchemy",         key = "XP06:Prof:Alchemy", },
  {label = "Draenor Blacksmithing",   frameID = "list1", professionSkillLineID = 164, missingProfessionSkillLineID = 2472, locationID = 6666666,    textInfo = "Draenor Blacksmithing",   key = "XP06:Prof:Blacksmithing", },
  {label = "Draenor Enchanting",      frameID = "list1", professionSkillLineID = 333, missingProfessionSkillLineID = 2488, locationID = 6666666,    textInfo = "Draenor Enchanting",      key = "XP06:Prof:Enchanting", },
  {label = "Draenor Engineering",     frameID = "list1", professionSkillLineID = 202, missingProfessionSkillLineID = 2501, locationID = 6666666,    textInfo = "Draenor Engineering",     key = "XP06:Prof:Engineering", },
  {label = "Draenor Herbalism",       frameID = "list1", professionSkillLineID = 182, missingProfessionSkillLineID = 2551, locationID = 6666666,    textInfo = "Draenor Herbalism",       key = "XP06:Prof:Herbalism", },
  {label = "Draenor Inscription",     frameID = "list1", professionSkillLineID = 773, missingProfessionSkillLineID = 2509, locationID = 6666666,    textInfo = "Draenor Inscription",     key = "XP06:Prof:Inscription", },
  {label = "Draenor Jewelcrafting",   frameID = "list1", professionSkillLineID = 755, missingProfessionSkillLineID = 2519, locationID = 6666666,    textInfo = "Draenor Jewelcrafting",   key = "XP06:Prof:Jewelcrafting", },
  {label = "Draenor Leatherworking",  frameID = "list1", professionSkillLineID = 165, missingProfessionSkillLineID = 2527, locationID = 6666666,    textInfo = "Draenor Leatherworking",  key = "XP06:Prof:Leatherworking", },
  {label = "Draenor Mining",          frameID = "list1", professionSkillLineID = 186, missingProfessionSkillLineID = 2567, locationID = 6666666,    textInfo = "Draenor Mining",          key = "XP06:Prof:Mining", },
  {label = "Draenor Skinning",        frameID = "list1", professionSkillLineID = 393, missingProfessionSkillLineID = 2559, locationID = 6666666,    textInfo = "Draenor Skinning",        key = "XP06:Prof:Skinning", },
  {label = "Draenor Tailoring",       frameID = "list1", professionSkillLineID = 197, missingProfessionSkillLineID = 2535, locationID = 6666666,    textInfo = "Draenor Tailoring",       key = "XP06:Prof:Tailoring", },
  {label = "Draenor Cooking",         frameID = "list1", professionSkillLineID = 185, missingProfessionSkillLineID = 2543, locationID = 6666666,    textInfo = "Draenor Cooking\n - Open Prof Book After", key = "XP06:Prof:Cooking", },
  {label = "Draenor Fishing",         frameID = "list1", professionSkillLineID = 356, missingProfessionSkillLineID = 2587, locationID = 6666666,    textInfo = "Draenor Fishing",         key = "XP06:Prof:Fishing", },

--  05  PANDARIA PROFESSIONS          If Not Clearing, Try Loading a Profession's Book After Learning                      /dump C_Map.GetBestMapForUnit("player")
  {label = "Mists Alchemy",           frameID = "list1", professionSkillLineID = 171, missingProfessionSkillLineID = 2481, locationID = 6666666,    textInfo = "Mists Alchemy",           key = "XP05:Prof:Alchemy", },
  {label = "Mists Blacksmithing",     frameID = "list1", professionSkillLineID = 164, missingProfessionSkillLineID = 2473, locationID = 6666666,    textInfo = "Mists Blacksmithing",     key = "XP05:Prof:Blacksmithing", },
  {label = "Mists Enchanting",        frameID = "list1", professionSkillLineID = 333, missingProfessionSkillLineID = 2489, locationID = 6666666,    textInfo = "Mists Enchanting",        key = "XP05:Prof:Enchanting", },
  {label = "Mists Engineering",       frameID = "list1", professionSkillLineID = 202, missingProfessionSkillLineID = 2502, locationID = 6666666,    textInfo = "Mists Engineering",       key = "XP05:Prof:Engineering", },
  {label = "Mists Herbalism",         frameID = "list1", professionSkillLineID = 182, missingProfessionSkillLineID = 2552, locationID = 6666666,    textInfo = "Mists Herbalism",         key = "XP05:Prof:Herbalism", },
  {label = "Mists Inscription",       frameID = "list1", professionSkillLineID = 773, missingProfessionSkillLineID = 2510, locationID = 6666666,    textInfo = "Mists Inscription",       key = "XP05:Prof:Inscription", },
  {label = "Mists Jewelcrafting",     frameID = "list1", professionSkillLineID = 755, missingProfessionSkillLineID = 2520, locationID = 6666666,    textInfo = "Mists Jewelcrafting",     key = "XP05:Prof:Jewelcrafting", },
  {label = "Mists Leatherworking",    frameID = "list1", professionSkillLineID = 165, missingProfessionSkillLineID = 2528, locationID = 6666666,    textInfo = "Mists Leatherworking",    key = "XP05:Prof:Leatherworking", },
  {label = "Mists Mining",            frameID = "list1", professionSkillLineID = 186, missingProfessionSkillLineID = 2568, locationID = 6666666,    textInfo = "Mists Mining",            key = "XP05:Prof:Mining", },
  {label = "Mists Skinning",          frameID = "list1", professionSkillLineID = 393, missingProfessionSkillLineID = 2560, locationID = 6666666,    textInfo = "Mists Skinning",          key = "XP05:Prof:Skinning", },
  {label = "Mists Tailoring",         frameID = "list1", professionSkillLineID = 197, missingProfessionSkillLineID = 2536, locationID = 6666666,    textInfo = "Mists Tailoring",         key = "XP05:Prof:Tailoring", },
  {label = "Mists Cooking",           frameID = "list1", professionSkillLineID = 185, missingProfessionSkillLineID = 2544, locationID = 6666666,    textInfo = "Mists Cooking\n - Open Prof Book After", key = "XP05:Prof:Cooking", },
  {label = "Mists Fishing",           frameID = "list1", professionSkillLineID = 356, missingProfessionSkillLineID = 2588, locationID = 6666666,    textInfo = "Mists Fishing",           key = "XP05:Prof:Fishing", },

--  04  CATACLYSM PROFESSIONS         If Not Clearing, Try Loading a Profession's Book After Learning                      /dump C_Map.GetBestMapForUnit("player")
  {label = "Cata Alchemy",            frameID = "list1", professionSkillLineID = 171, missingProfessionSkillLineID = 2482, locationID = { 84, 85, }, textInfo = "Cata Alchemy",           key = "XP04:Prof:Alchemy", },
  {label = "Cata Blacksmithing",      frameID = "list1", professionSkillLineID = 164, missingProfessionSkillLineID = 2474, locationID = { 84, 85, }, textInfo = "Cata Blacksmithing",     key = "XP04:Prof:Blacksmithing", },
  {label = "Cata Enchanting",         frameID = "list1", professionSkillLineID = 333, missingProfessionSkillLineID = 2491, locationID = { 84, 85, }, textInfo = "Cata Enchanting",        key = "XP04:Prof:Enchanting", },
  {label = "Cata Engineering",        frameID = "list1", professionSkillLineID = 202, missingProfessionSkillLineID = 2503, locationID = { 84, 85, }, textInfo = "Cata Engineering",       key = "XP04:Prof:Engineering", },
  {label = "Cata Herbalism",          frameID = "list1", professionSkillLineID = 182, missingProfessionSkillLineID = 2553, locationID = { 84, 85, }, textInfo = "Cata Herbalism",         key = "XP04:Prof:Herbalism", },
  {label = "Cata Inscription",        frameID = "list1", professionSkillLineID = 773, missingProfessionSkillLineID = 2511, locationID = { 84, 85, }, textInfo = "Cata Inscription",       key = "XP04:Prof:Inscription", },
  {label = "Cata Jewelcrafting",      frameID = "list1", professionSkillLineID = 755, missingProfessionSkillLineID = 2521, locationID = { 84, 85, }, textInfo = "Cata Jewelcrafting",     key = "XP04:Prof:Jewelcrafting", },
  {label = "Cata Leatherworking",     frameID = "list1", professionSkillLineID = 165, missingProfessionSkillLineID = 2529, locationID = { 84, 85, }, textInfo = "Cata Leatherworking",    key = "XP04:Prof:Leatherworking", },
  {label = "Cata Mining",             frameID = "list1", professionSkillLineID = 186, missingProfessionSkillLineID = 2569, locationID = { 84, 85, }, textInfo = "Cata Mining",            key = "XP04:Prof:Mining", },
  {label = "Cata Skinning",           frameID = "list1", professionSkillLineID = 393, missingProfessionSkillLineID = 2561, locationID = { 84, 85, }, textInfo = "Cata Skinning",          key = "XP04:Prof:Skinning", },
  {label = "Cata Tailoring",          frameID = "list1", professionSkillLineID = 197, missingProfessionSkillLineID = 2537, locationID = { 84, 85, }, textInfo = "Cata Tailoring",         key = "XP04:Prof:Tailoring", },
  {label = "Cata Cooking",            frameID = "list1", professionSkillLineID = 185, missingProfessionSkillLineID = 2545, locationID = { 84, 85, }, textInfo = "Cata Cooking\n - Open Prof Book After", key = "XP04:Prof:Cooking", },
  {label = "Cata Fishing",            frameID = "list1", professionSkillLineID = 356, missingProfessionSkillLineID = 2589, locationID = { 84, 85, }, textInfo = "Cata Fishing",           key = "XP04:Prof:Fishing", },

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
  {label = "Guild Cloak A2",          frameID = "bar1",  textInfo = "|cff1eff00Guild Cloak|r", faction = "alliance",       locationID = 84, showIf = { all = { { factionID = 1168, minStanding = 7 }, { itemIDs = { 63352 }, includeBank = true }, }, }, complete = { any = { { itemIDs = { 63206 }, includeBank = true }, }, }, key = "rep:guild:alliance:cloak2", },
  {label = "Guild Cloak A3",          frameID = "bar1",  textInfo = "|cff1eff00Guild Cloak|r", faction = "alliance",       locationID = 84, showIf = { all = { { factionID = 1168, minStanding = 8 }, { itemIDs = { 63206 }, includeBank = true }, }, }, complete = { any = { { itemIDs = { 65360 }, includeBank = true }, }, }, key = "rep:guild:alliance:cloak3", },
  {label = "Guild Cloak H1",          frameID = "bar1",  textInfo = "|cff1eff00Guild Cloak|r", faction = "horde",          locationID = 85, showIf = { factionID = 1168, minStanding = 6 },                                                              complete = { any = { { itemIDs = { 63353 }, includeBank = true }, }, }, key = "rep:guild:horde:cloak1",    },
  {label = "Guild Cloak H2",          frameID = "bar1",  textInfo = "|cff1eff00Guild Cloak|r", faction = "horde",          locationID = 85, showIf = { all = { { factionID = 1168, minStanding = 7 }, { itemIDs = { 63353 }, includeBank = true }, }, }, complete = { any = { { itemIDs = { 63207 }, includeBank = true }, }, }, key = "rep:guild:horde:cloak2",    },
  {label = "Guild Cloak H3",          frameID = "bar1",  textInfo = "|cff1eff00Guild Cloak|r", faction = "horde",          locationID = 85, showIf = { all = { { factionID = 1168, minStanding = 8 }, { itemIDs = { 63207 }, includeBank = true }, }, }, complete = { any = { { itemIDs = { 65274 }, includeBank = true }, }, }, key = "rep:guild:horde:cloak3",    },

--  /dump C_Map.GetBestMapForUnit("player") 
--{label = "Phaze Blasted Cata", textInfo = "|cffa335eeCATACLYSM PHAZED|r", locationID = 17, frameID = "list2", questID = 66560, showIf = { completedQuestID = 66560 }, key = "zone:blastedlands:cataclysm", },
{label = "Phaze Blasted WoD",  questInfo = "|cffa335eeWARLORDS PHAZED|r",  locationID = 17, frameID = "list2", questID = 66560, key = "zone:blastedlands:warlords", }



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
