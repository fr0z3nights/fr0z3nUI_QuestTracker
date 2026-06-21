local addonName, ns = ...
ns = ns or {}

-- Profession cache helpers (ported from FGO-style approach).
-- Goal: make profession-gated rules reliable even when profession APIs are temporarily nil
-- during early login/reload frames.

ns.Profs = ns.Profs or {}
local Profs = ns.Profs

-- Legacy/simple profession helpers used by the main engine rules.
-- These live here so the main file doesn't carry profession API wiring.

function Profs.HasProfessionSkillLineID(skillLineID)
  skillLineID = tonumber(skillLineID)
  if not skillLineID or skillLineID <= 0 then return false end
  return (type(Profs.HasSkillLineID) == "function" and Profs.HasSkillLineID(skillLineID) == true) and true or false
end

function Profs.GetProfessionIndices()
  local GP = _G and rawget(_G, "GetProfessions")
  if type(GP) ~= "function" then return nil end
  local ok, p1, p2, arch, fish, cook = pcall(GP)
  if not ok then return nil end
  return p1, p2, arch, fish, cook
end

function Profs.IsPrimaryProfessionSlotMissing(slot)
  local p1, p2 = Profs.GetProfessionIndices()
  slot = tonumber(slot) or 1
  if slot == 2 then
    return p2 == nil
  end
  return p1 == nil
end

function Profs.IsSecondaryProfessionMissing(which)
  local _, _, _, fish, cook = Profs.GetProfessionIndices()
  which = tostring(which or ""):lower()
  if which == "fishing" then
    return fish == nil
  end
  if which == "cooking" then
    return cook == nil
  end
  return false
end

function Profs.GetPrimaryProfessionNames()
  local GP = _G and rawget(_G, "GetProfessions")
  local GPI = _G and rawget(_G, "GetProfessionInfo")
  if type(GP) ~= "function" or type(GPI) ~= "function" then return nil end

  local ok, p1, p2 = pcall(GP)
  if not ok then return nil end

  local out = {}
  local function Add(p)
    if not p then return end
    local ok2, name = pcall(GPI, p)
    if ok2 and name then
      out[#out + 1] = tostring(name)
    end
  end
  Add(p1)
  Add(p2)
  return out
end

function Profs.CanQueryTradeSkillLines()
  return (C_TradeSkillUI and type(C_TradeSkillUI.GetAllProfessionTradeSkillLines) == "function") and true or false
end

local function GetTradeSkillLineNameByID(skillLineID)
  skillLineID = tonumber(skillLineID)
  if not (C_TradeSkillUI and skillLineID and skillLineID > 0) then return nil end
  if C_TradeSkillUI.GetTradeSkillLineInfoByID then
    local ok, info = pcall(C_TradeSkillUI.GetTradeSkillLineInfoByID, skillLineID)
    if ok and type(info) == "table" then
      local n = info["name"]
      if n then return tostring(n) end
    end
  end
  if C_TradeSkillUI.GetProfessionInfoBySkillLineID then
    local ok, info = pcall(C_TradeSkillUI.GetProfessionInfoBySkillLineID, skillLineID)
    if ok and type(info) == "table" then
      local pn = info["professionName"]
      if pn then return tostring(pn) end
      local n = info["name"]
      if n then return tostring(n) end
    end
  end
  return nil
end

function Profs.HasTradeSkillLine(nameOrID)
  if not Profs.CanQueryTradeSkillLines() then return false end
  local wantID = tonumber(nameOrID)
  local wantName = wantID and nil or tostring(nameOrID or ""):lower()
  if wantName == "" and not wantID then return false end

  local ok, lines = pcall(C_TradeSkillUI.GetAllProfessionTradeSkillLines)
  if not ok or type(lines) ~= "table" then return false end

  for _, id in ipairs(lines) do
    if wantID and tonumber(id) == wantID then
      return true
    end
    if wantName then
      local n = GetTradeSkillLineNameByID(id)
      if n and tostring(n):lower() == wantName then
        return true
      end
    end
  end

  return false
end

function Profs.HasProfession(prof)
  if prof == nil then return false end

  -- Preserve legacy behavior: only checks PRIMARY professions (p1/p2).
  local GP = _G and rawget(_G, "GetProfessions")
  local GPI = _G and rawget(_G, "GetProfessionInfo")
  if type(GP) ~= "function" or type(GPI) ~= "function" then return false end

  local wantID = tonumber(prof)
  local wantName = wantID and nil or tostring(prof):lower()

  local ok, p1, p2 = pcall(GP)
  if not ok then return false end

  local function Check(p)
    if not p then return false end
    -- NOTE: pcall prepends a boolean success flag; skillLine is the 7th return from GetProfessionInfo.
    local ok2, name, _, _, _, _, _, skillLineID = pcall(GPI, p)
    if not ok2 then return false end
    if wantID then
      return tonumber(skillLineID) == wantID
    end
    return name and tostring(name):lower() == wantName
  end

  return Check(p1) or Check(p2)
end

if _G then
  _G.HasProfession = Profs.HasProfession
end

Profs._lastRefreshAt = Profs._lastRefreshAt or 0
Profs.CACHE_VERSION = Profs.CACHE_VERSION or 4

-- Stable base skillLineIDs (avoid localized profession names).
Profs.SKILLLINE_TO_PROFKEY = Profs.SKILLLINE_TO_PROFKEY or {
  [164] = "Blacksmithing",
  [165] = "Leatherworking",
  [171] = "Alchemy",
  [182] = "Herbalism",
  [185] = "Cooking",
  [186] = "Mining",
  [197] = "Tailoring",
  [202] = "Engineering",
  [333] = "Enchanting",
  [356] = "Fishing",
  [393] = "Skinning",
  [755] = "Jewelcrafting",
  [773] = "Inscription",
  [794] = "Archaeology",
  -- Modern specialization skillLineIDs that should still satisfy base profession gates.
  -- (e.g., some clients report Cooking/Fishing as "Midnight" skillLineIDs.)
  [2908] = "Cooking", -- Midnight Cooking
  [2911] = "Fishing", -- Midnight Fishing
}

-- Canonical base skillLineID for each profession key.
-- (Avoid deriving this from the tier tables or alias mappings.)
Profs.BASE_SKILLLINE_BY_PROFKEY = Profs.BASE_SKILLLINE_BY_PROFKEY or {
  Alchemy = 171,
  Archaeology = 794,
  Blacksmithing = 164,
  Cooking = 185,
  Enchanting = 333,
  Engineering = 202,
  Fishing = 356,
  Herbalism = 182,
  Inscription = 773,
  Jewelcrafting = 755,
  Leatherworking = 165,
  Mining = 186,
  Skinning = 393,
  Tailoring = 197,
}

-- Expansion-tier profession skillLineIDs (Retail).
-- Keep these in the professions module as the source of truth for rules and debug tooling.
Profs.TIERS_BY_PROFKEY = Profs.TIERS_BY_PROFKEY or {
  -- Note: Not every profession has reminders in every XP pack, but the tier IDs
  -- live here so rules + debug tooling can share a single authoritative table.
  Alchemy = {
    [1] = 2485, -- Alchemy
    [2] = 2484, -- Outland Alchemy
    [3] = 2483, -- Northrend Alchemy
    [4] = 2482, -- Cataclysm Alchemy
    [5] = 2481, -- Pandaria Alchemy
    [6] = 2480, -- Draenor Alchemy
    [7] = 2479, -- Legion Alchemy
    [8] = 2478, -- Battle for Azeroth Alchemy
    [9] = 2750, -- Shadowlands Alchemy
    [10] = 2823, -- Dragon Isles Alchemy
    [11] = 2871, -- Khaz Algar Alchemy
    [12] = 2906, -- Midnight Alchemy
  },
  Blacksmithing = {
    [1] = 2477, -- Blacksmithing
    [2] = 2476, -- Outland Blacksmithing
    [3] = 2475, -- Northrend Blacksmithing
    [4] = 2474, -- Cataclysm Blacksmithing
    [5] = 2473, -- Pandaren Blacksmithing
    [6] = 2472, -- Draenor Blacksmithing
    [7] = 2454, -- Legion Blacksmithing
    [8] = 2437, -- Battle for Azeroth Blacksmithing
    [9] = 2751, -- Shadowlands Blacksmithing
    [10] = 2822, -- Dragon Isles Blacksmithing
    [11] = 2872, -- Khaz Algar Blacksmithing
    [12] = 2907, -- Midnight Blacksmithing
  },
  Cooking = {
    [1] = 2548, -- Cooking
    [2] = 2547, -- Outland Cooking
    [3] = 2546, -- Northrend Cooking
    [4] = 2545, -- Cataclysm Cooking
    [5] = 2544, -- Pandaria Cooking
    [6] = 2543, -- Draenor Cooking
    [7] = 2542, -- Legion Cooking
    [8] = 2541, -- Battle for Azeroth Cooking
    [9] = 2752, -- Shadowlands Cooking
    [10] = 2824, -- Dragon Isles Cooking
    [11] = 2873, -- Khaz Algar Cooking
    [12] = 2908, -- Midnight Cooking
  },
  Enchanting = {
    [1] = 2494, -- Enchanting
    [2] = 2493, -- Outland Enchanting
    [3] = 2492, -- Northrend Enchanting
    [4] = 2491, -- Cataclysm Enchanting
    [5] = 2489, -- Pandaria Enchanting
    [6] = 2488, -- Draenor Enchanting
    [7] = 2487, -- Legion Enchanting
    [8] = 2486, -- Battle for Azeroth Enchanting
    [9] = 2753, -- Shadowlands Enchanting
    [10] = 2825, -- Dragon Isles Enchanting
    [11] = 2874, -- Khaz Algar Enchanting
    [12] = 2909, -- Midnight Enchanting
  },
  Engineering = {
    [1] = 2506, -- Engineering
    [2] = 2505, -- Outland Engineering
    [3] = 2504, -- Northrend Engineering
    [4] = 2503, -- Cataclysm Engineering
    [5] = 2502, -- Pandaria Engineering
    [6] = 2501, -- Draenor Engineering
    [7] = 2500, -- Legion Engineering
    [8] = 2499, -- Battle for Azeroth Engineering
    [9] = 2755, -- Shadowlands Engineering
    [10] = 2827, -- Dragon Isles Engineering
    [11] = 2875, -- Khaz Algar Engineering
    [12] = 2910, -- Midnight Engineering
  },
  Fishing = {
    [1] = 2592, -- Fishing
    [2] = 2591, -- Outland Fishing
    [3] = 2590, -- Northrend Fishing
    [4] = 2589, -- Cataclysm Fishing
    [5] = 2588, -- Pandaria Fishing
    [6] = 2587, -- Draenor Fishing
    [7] = 2586, -- Legion Fishing
    [8] = 2585, -- Battle for Azeroth Fishing
    [9] = 2754, -- Shadowlands Fishing
    [10] = 2826, -- Dragon Isles Fishing
    [11] = 2876, -- Khaz Algar Fishing
    [12] = 2911, -- Midnight Fishing
  },
  Herbalism = {
    [1] = 2556, -- Herbalism
    [2] = 2555, -- Outland Herbalism
    [3] = 2554, -- Northrend Herbalism
    [4] = 2553, -- Cataclysm Herbalism
    [5] = 2552, -- Pandaria Herbalism
    [6] = 2551, -- Draenor Herbalism
    [7] = 2550, -- Legion Herbalism
    [8] = 2549, -- Battle for Azeroth Herbalism
    [9] = 2760, -- Shadowlands Herbalism
    [10] = 2832, -- Dragon Isles Herbalism
    [11] = 2877, -- Khaz Algar Herbalism
    [12] = 2912, -- Midnight Herbalism
  },
  Inscription = {
    [1] = 2514, -- Inscription
    [2] = 2513, -- Outland Inscription
    [3] = 2512, -- Northrend Inscription
    [4] = 2511, -- Cataclysm Inscription
    [5] = 2510, -- Pandaria Inscription
    [6] = 2509, -- Draenor Inscription
    [7] = 2508, -- Legion Inscription
    [8] = 2507, -- Battle for Azeroth Inscription
    [9] = 2756, -- Shadowlands Inscription
    [10] = 2828, -- Dragon Isles Inscription
    [11] = 2878, -- Khaz Algar Inscription
    [12] = 2913, -- Midnight Inscription
  },
  Jewelcrafting = {
    [1] = 2524, -- Jewelcrafting
    [2] = 2523, -- Outland Jewelcrafting
    [3] = 2522, -- Northrend Jewelcrafting
    [4] = 2521, -- Cataclysm Jewelcrafting
    [5] = 2520, -- Pandaria Jewelcrafting
    [6] = 2519, -- Draenor Jewelcrafting
    [7] = 2518, -- Legion Jewelcrafting
    [8] = 2517, -- Battle for Azeroth Jewelcrafting
    [9] = 2757, -- Shadowlands Jewelcrafting
    [10] = 2829, -- Dragon Isles Jewelcrafting
    [11] = 2879, -- Khaz Algar Jewelcrafting
    [12] = 2914, -- Midnight Jewelcrafting
  },
  Leatherworking = {
    [1] = 2532, -- Leatherworking
    [2] = 2531, -- Outland Leatherworking
    [3] = 2530, -- Northrend Leatherworking
    [4] = 2529, -- Cataclysm Leatherworking
    [5] = 2528, -- Pandaria Leatherworking
    [6] = 2527, -- Draenor Leatherworking
    [7] = 2526, -- Legion Leatherworking
    [8] = 2525, -- Battle for Azeroth Leatherworking
    [9] = 2758, -- Shadowlands Leatherworking
    [10] = 2830, -- Dragon Isles Leatherworking
    [11] = 2880, -- Khaz Algar Leatherworking
    [12] = 2915, -- Midnight Leatherworking
  },
  Mining = {
    [1] = 2572, -- Mining
    [2] = 2571, -- Outland Mining
    [3] = 2570, -- Northrend Mining
    [4] = 2569, -- Cataclysm Mining
    [5] = 2568, -- Pandaria Mining
    [6] = 2567, -- Draenor Mining
    [7] = 2566, -- Legion Mining
    [8] = 2565, -- Battle for Azeroth Mining
    [9] = 2761, -- Shadowlands Mining
    [10] = 2833, -- Dragon Isles Mining
    [11] = 2881, -- Khaz Algar Mining
    [12] = 2916, -- Midnight Mining
  },
  Skinning = {
    [1] = 2564, -- Skinning
    [2] = 2563, -- Outland Skinning
    [3] = 2562, -- Northrend Skinning
    [4] = 2561, -- Cataclysm Skinning
    [5] = 2560, -- Pandaria Skinning
    [6] = 2559, -- Draenor Skinning
    [7] = 2558, -- Legion Skinning
    [8] = 2557, -- Battle for Azeroth Skinning
    [9] = 2762, -- Shadowlands Skinning
    [10] = 2834, -- Dragon Isles Skinning
    [11] = 2882, -- Khaz Algar Skinning
    [12] = 2917, -- Midnight Skinning
  },
  Tailoring = {
    [1] = 2540, -- Tailoring
    [2] = 2539, -- Outland Tailoring
    [3] = 2538, -- Northrend Tailoring
    [4] = 2537, -- Cataclysm Tailoring
    [5] = 2536, -- Pandaria Tailoring
    [6] = 2535, -- Draenor Tailoring
    [7] = 2534, -- Legion Tailoring
    [8] = 2533, -- Battle for Azeroth Tailoring
    [9] = 2759, -- Shadowlands Tailoring
    [10] = 2831, -- Dragon Isles Tailoring
    [11] = 2883, -- Khaz Algar Tailoring
    [12] = 2918, -- Midnight Tailoring
  },
}

-- Zygor-derived profession tier info (categoryIDs) for TradeSkillUI.
-- Source doc: Reference/Profession CategoryIDs - Full (from Zygor).md
-- This is kept here (even if unused) so tier/category lookups have a single home.
Profs.ZYGOR_TIER_CATEGORYIDS_BY_PROFKEY = Profs.ZYGOR_TIER_CATEGORYIDS_BY_PROFKEY or {
  Alchemy = {
    { label = "Alchemy", categoryID = 604, zygorSkillLineID = 2485 },
    { label = "Outland Alchemy", categoryID = 602, zygorSkillLineID = 2484 },
    { label = "Northrend Alchemy", categoryID = 600, zygorSkillLineID = 2483 },
    { label = "Cataclysm Alchemy", categoryID = 598, zygorSkillLineID = 2482 },
    { label = "Pandaria Alchemy", categoryID = 596, zygorSkillLineID = 2481 },
    { label = "Draenor Alchemy", categoryID = 332, zygorSkillLineID = 2480 },
    { label = "Legion Alchemy", categoryID = 433, zygorSkillLineID = 2479 },
    { label = "Battle Alchemy", categoryID = 592, zygorSkillLineID = 2478 },
    { label = "Shadowlands Alchemy", categoryID = 1294, zygorSkillLineID = 2750 },
    { label = "Dragon Isles Alchemy", categoryID = 1582, zygorSkillLineID = 2823 },
    { label = "Khaz Algar Alchemy", categoryID = 1898, zygorSkillLineID = 2871 },
    { label = "Midnight Alchemy", categoryID = 2154, zygorSkillLineID = 2906 },
  },
  Blacksmithing = {
    { label = "Blacksmithing", categoryID = 590, zygorSkillLineID = 2477 },
    { label = "Outland Blacksmithing", categoryID = 584, zygorSkillLineID = 2476 },
    { label = "Northrend Blacksmithing", categoryID = 577, zygorSkillLineID = 2475 },
    { label = "Cataclysm Blacksmithing", categoryID = 569, zygorSkillLineID = 2474 },
    { label = "Pandaren Blacksmithing", categoryID = 553, zygorSkillLineID = 2473 },
    { label = "Draenor Blacksmithing", categoryID = 389, zygorSkillLineID = 2472 },
    { label = "Legion Blacksmithing", categoryID = 426, zygorSkillLineID = 2454 },
    { label = "Battle Blacksmithing", categoryID = 542, zygorSkillLineID = 2437 },
    { label = "Shadowlands Blacksmithing", categoryID = 1311, zygorSkillLineID = 2751 },
    { label = "Dragon Isles Blacksmithing", categoryID = 1566, zygorSkillLineID = 2822 },
    { label = "Khaz Algar Blacksmithing", categoryID = 1900, zygorSkillLineID = 2872 },
    { label = "Midnight Blacksmithing", categoryID = 2155, zygorSkillLineID = 2907 },
  },
  Cooking = {
    { label = "Cooking", categoryID = 72, zygorSkillLineID = 2548 },
    { label = "Outland Cooking", categoryID = 73, zygorSkillLineID = 2547 },
    { label = "Northrend Cooking", categoryID = 74, zygorSkillLineID = 2546 },
    { label = "Cataclysm Cooking", categoryID = 75, zygorSkillLineID = 2545 },
    { label = "Pandaria Cooking", categoryID = 90, zygorSkillLineID = 2544 },
    { label = "Way of the Grill", categoryID = 64, zygorSkillLineID = 975 },
    { label = "Way of the Wok", categoryID = 65, zygorSkillLineID = 976 },
    { label = "Way of the Pot", categoryID = 66, zygorSkillLineID = 977 },
    { label = "Way of the Steamer", categoryID = 67, zygorSkillLineID = 978 },
    { label = "Way of the Oven", categoryID = 68, zygorSkillLineID = 979 },
    { label = "Way of the Brew", categoryID = 69, zygorSkillLineID = 980 },
    { label = "Draenor Cooking", categoryID = 342, zygorSkillLineID = 2543 },
    { label = "Legion Cooking", categoryID = 475, zygorSkillLineID = 2542 },
    { label = "Battle Cooking", categoryID = 1118, zygorSkillLineID = 2541 },
    { label = "Shadowlands Cooking", categoryID = 1323, zygorSkillLineID = 2752 },
    { label = "Dragon Isles Cooking", categoryID = 1585, zygorSkillLineID = 2824 },
    { label = "Khaz Algar Cooking", categoryID = 1902, zygorSkillLineID = 2873 },
    { label = "Midnight Cooking", categoryID = 2156, zygorSkillLineID = 2908 },
  },
  Enchanting = {
    { label = "Enchanting", categoryID = 667, zygorSkillLineID = 2494 },
    { label = "Outland Enchanting", categoryID = 665, zygorSkillLineID = 2493 },
    { label = "Northrend Enchanting", categoryID = 663, zygorSkillLineID = 2492 },
    { label = "Cataclysm Enchanting", categoryID = 661, zygorSkillLineID = 2491 },
    { label = "Pandaria Enchanting", categoryID = 656, zygorSkillLineID = 2489 },
    { label = "Draenor Enchanting", categoryID = 348, zygorSkillLineID = 2488 },
    { label = "Legion Enchanting", categoryID = 443, zygorSkillLineID = 2487 },
    { label = "Battle Enchanting", categoryID = 647, zygorSkillLineID = 2486 },
    { label = "Shadowlands Enchanting", categoryID = 1364, zygorSkillLineID = 2753 },
    { label = "Dragon Isles Enchanting", categoryID = 1588, zygorSkillLineID = 2825 },
    { label = "Khaz Algar Enchanting", categoryID = 1904, zygorSkillLineID = 2874 },
    { label = "Midnight Enchanting", categoryID = 2157, zygorSkillLineID = 2909 },
  },
  Engineering = {
    { label = "Engineering", categoryID = 419, zygorSkillLineID = 2506 },
    { label = "Outland Engineering", categoryID = 719, zygorSkillLineID = 2505 },
    { label = "Northrend Engineering", categoryID = 717, zygorSkillLineID = 2504 },
    { label = "Cataclysm Engineering", categoryID = 715, zygorSkillLineID = 2503 },
    { label = "Pandaria Engineering", categoryID = 713, zygorSkillLineID = 2502 },
    { label = "Draenor Engineering", categoryID = 347, zygorSkillLineID = 2501 },
    { label = "Legion Engineering", categoryID = 469, zygorSkillLineID = 2500 },
    { label = "Battle Engineering", categoryID = 709, zygorSkillLineID = 2499 },
    { label = "Shadowlands Engineering", categoryID = 1381, zygorSkillLineID = 2755 },
    { label = "Dragon Isles Engineering", categoryID = 1595, zygorSkillLineID = 2827 },
    { label = "Khaz Algar Engineering", categoryID = 1906, zygorSkillLineID = 2875 },
    { label = "Midnight Engineering", categoryID = 2158, zygorSkillLineID = 2910 },
  },
  Fishing = {
    { label = "Fishing", categoryID = 1100, zygorSkillLineID = 2592 },
    { label = "Outland Fishing", categoryID = 1102, zygorSkillLineID = 2591 },
    { label = "Northrend Fishing", categoryID = 1104, zygorSkillLineID = 2590 },
    { label = "Cataclysm Fishing", categoryID = 1106, zygorSkillLineID = 2589 },
    { label = "Pandaria Fishing", categoryID = 1108, zygorSkillLineID = 2588 },
    { label = "Draenor Fishing", categoryID = 1110, zygorSkillLineID = 2587 },
    { label = "Legion Fishing", categoryID = 1112, zygorSkillLineID = 2586 },
    { label = "Battle Fishing", categoryID = 1114, zygorSkillLineID = 2585 },
    { label = "Shadowlands Fishing", categoryID = 1391, zygorSkillLineID = 2754 },
    { label = "Dragon Isles Fishing", categoryID = 1590, zygorSkillLineID = 2826 },
    { label = "Khaz Algar Fishing", categoryID = 1908, zygorSkillLineID = 2876 },
    { label = "Midnight Fishing", categoryID = 2159, zygorSkillLineID = 2911 },
  },
  Herbalism = {
    { label = "Herbalism", categoryID = 1044, zygorSkillLineID = 2556 },
    { label = "Outland Herbalism", categoryID = 1042, zygorSkillLineID = 2555 },
    { label = "Northrend Herbalism", categoryID = 1040, zygorSkillLineID = 2554 },
    { label = "Cataclysm Herbalism", categoryID = 1038, zygorSkillLineID = 2553 },
    { label = "Pandaria Herbalism", categoryID = 1036, zygorSkillLineID = 2552 },
    { label = "Draenor Herbalism", categoryID = 1034, zygorSkillLineID = 2551 },
    { label = "Legion Herbalism", categoryID = 456, zygorSkillLineID = 2550 },
    { label = "Battle Herbalism", categoryID = 1029, zygorSkillLineID = 2549 },
    { label = "Shadowlands Herbalism", categoryID = 1441, zygorSkillLineID = 2760 },
    { label = "Dragon Isles Herbalism", categoryID = 1594, zygorSkillLineID = 2832 },
    { label = "Khaz Algar Herbalism", categoryID = 1910, zygorSkillLineID = 2877 },
    { label = "Midnight Herbalism", categoryID = 2160, zygorSkillLineID = 2912 },
  },
  Inscription = {
    { label = "Inscription", categoryID = 415, zygorSkillLineID = 2514 },
    { label = "Outland Inscription", categoryID = 769, zygorSkillLineID = 2513 },
    { label = "Northrend Inscription", categoryID = 767, zygorSkillLineID = 2512 },
    { label = "Cataclysm Inscription", categoryID = 765, zygorSkillLineID = 2511 },
    { label = "Pandaria Inscription", categoryID = 763, zygorSkillLineID = 2510 },
    { label = "Draenor Inscription", categoryID = 410, zygorSkillLineID = 2509 },
    { label = "Legion Inscription", categoryID = 450, zygorSkillLineID = 2508 },
    { label = "Battle Inscription", categoryID = 759, zygorSkillLineID = 2507 },
    { label = "Shadowlands Inscription", categoryID = 1406, zygorSkillLineID = 2756 },
    { label = "Dragon Isles Inscription", categoryID = 1592, zygorSkillLineID = 2828 },
    { label = "Khaz Algar Inscription", categoryID = 1912, zygorSkillLineID = 2878 },
    { label = "Midnight Inscription", categoryID = 2161, zygorSkillLineID = 2913 },
  },
  Jewelcrafting = {
    { label = "Jewelcrafting", categoryID = 372, zygorSkillLineID = 2524 },
    { label = "Outland Jewelcrafting", categoryID = 815, zygorSkillLineID = 2523 },
    { label = "Northrend Jewelcrafting", categoryID = 813, zygorSkillLineID = 2522 },
    { label = "Cataclysm Jewelcrafting", categoryID = 811, zygorSkillLineID = 2521 },
    { label = "Pandaria Jewelcrafting", categoryID = 809, zygorSkillLineID = 2520 },
    { label = "Draenor Jewelcrafting", categoryID = 373, zygorSkillLineID = 2519 },
    { label = "Legion Jewelcrafting", categoryID = 464, zygorSkillLineID = 2518 },
    { label = "Battle Jewelcrafting", categoryID = 805, zygorSkillLineID = 2517 },
    { label = "Shadowlands Jewelcrafting", categoryID = 1418, zygorSkillLineID = 2757 },
    { label = "Dragon Isles Jewelcrafting", categoryID = 1593, zygorSkillLineID = 2829 },
    { label = "Khaz Algar Jewelcrafting", categoryID = 1914, zygorSkillLineID = 2879 },
    { label = "Midnight Jewelcrafting", categoryID = 2162, zygorSkillLineID = 2914 },
  },
  Leatherworking = {
    { label = "Leatherworking", categoryID = 379, zygorSkillLineID = 2532 },
    { label = "Outland Leatherworking", categoryID = 882, zygorSkillLineID = 2531 },
    { label = "Northrend Leatherworking", categoryID = 880, zygorSkillLineID = 2530 },
    { label = "Cataclysm Leatherworking", categoryID = 878, zygorSkillLineID = 2529 },
    { label = "Pandaria Leatherworking", categoryID = 876, zygorSkillLineID = 2528 },
    { label = "Draenor Leatherworking", categoryID = 380, zygorSkillLineID = 2527 },
    { label = "Legion Leatherworking", categoryID = 460, zygorSkillLineID = 2526 },
    { label = "Battle Leatherworking", categoryID = 871, zygorSkillLineID = 2525 },
    { label = "Shadowlands Leatherworking", categoryID = 1334, zygorSkillLineID = 2758 },
    { label = "Dragon Isles Leatherworking", categoryID = 1587, zygorSkillLineID = 2830 },
    { label = "Khaz Algar Leatherworking", categoryID = 1916, zygorSkillLineID = 2880 },
    { label = "Midnight Leatherworking", categoryID = 2163, zygorSkillLineID = 2915 },
  },
  Mining = {
    { label = "Mining", categoryID = 1078, zygorSkillLineID = 2572 },
    { label = "Outland Mining", categoryID = 1076, zygorSkillLineID = 2571 },
    { label = "Northrend Mining", categoryID = 1074, zygorSkillLineID = 2570 },
    { label = "Cataclysm Mining", categoryID = 1072, zygorSkillLineID = 2569 },
    { label = "Pandaria Mining", categoryID = 1070, zygorSkillLineID = 2568 },
    { label = "Draenor Mining", categoryID = 1068, zygorSkillLineID = 2567 },
    { label = "Legion Mining", categoryID = 425, zygorSkillLineID = 2566 },
    { label = "Battle Mining", categoryID = 1065, zygorSkillLineID = 2565 },
    { label = "Shadowlands Mining", categoryID = 1320, zygorSkillLineID = 2761 },
    { label = "Dragon Isles Mining", categoryID = 1584, zygorSkillLineID = 2833 },
    { label = "Khaz Algar Mining", categoryID = 1918, zygorSkillLineID = 2881 },
    { label = "Midnight Mining", categoryID = 2164, zygorSkillLineID = 2916 },
  },
  Skinning = {
    { label = "Skinning", categoryID = 1060, zygorSkillLineID = 2564 },
    { label = "Outland Skinning", categoryID = 1058, zygorSkillLineID = 2563 },
    { label = "Northrend Skinning", categoryID = 1056, zygorSkillLineID = 2562 },
    { label = "Cataclysm Skinning", categoryID = 1054, zygorSkillLineID = 2561 },
    { label = "Pandaria Skinning", categoryID = 1052, zygorSkillLineID = 2560 },
    { label = "Draenor Skinning", categoryID = 1050, zygorSkillLineID = 2559 },
    { label = "Legion Skinning", categoryID = 459, zygorSkillLineID = 2558 },
    { label = "Battle Skinning", categoryID = 1046, zygorSkillLineID = 2557 },
    { label = "Shadowlands Skinning", categoryID = 1331, zygorSkillLineID = 2762 },
    { label = "Dragon Isles Skinning", categoryID = 1586, zygorSkillLineID = 2834 },
    { label = "Khaz Algar Skinning", categoryID = 1920, zygorSkillLineID = 2882 },
    { label = "Midnight Skinning", categoryID = 2165, zygorSkillLineID = 2917 },
  },
  Tailoring = {
    { label = "Tailoring", categoryID = 362, zygorSkillLineID = 2540 },
    { label = "Outland Tailoring", categoryID = 956, zygorSkillLineID = 2539 },
    { label = "Northrend Tailoring", categoryID = 954, zygorSkillLineID = 2538 },
    { label = "Cataclysm Tailoring", categoryID = 952, zygorSkillLineID = 2537 },
    { label = "Pandaria Tailoring", categoryID = 950, zygorSkillLineID = 2536 },
    { label = "Draenor Tailoring", categoryID = 369, zygorSkillLineID = 2535 },
    { label = "Legion Tailoring", categoryID = 430, zygorSkillLineID = 2534 },
    { label = "Battle Tailoring", categoryID = 942, zygorSkillLineID = 2533 },
    { label = "Shadowlands Tailoring", categoryID = 1395, zygorSkillLineID = 2759 },
    { label = "Dragon Isles Tailoring", categoryID = 1591, zygorSkillLineID = 2831 },
    { label = "Khaz Algar Tailoring", categoryID = 1922, zygorSkillLineID = 2883 },
    { label = "Midnight Tailoring", categoryID = 2166, zygorSkillLineID = 2918 },
  },
}

local ALIAS_SKILLLINE_TO_BASE = {
  [2908] = 185, -- Cooking
  [2911] = 356, -- Fishing
}

local function GetProfessionKeyBySkillLineID(skillLineID)
  skillLineID = tonumber(skillLineID)
  if not skillLineID or skillLineID <= 0 then
    return nil
  end

  local direct = Profs.SKILLLINE_TO_PROFKEY and Profs.SKILLLINE_TO_PROFKEY[skillLineID]
  if type(direct) == "string" and direct ~= "" then
    return direct
  end

  local tiers = Profs.TIERS_BY_PROFKEY
  if type(tiers) == "table" then
    for profKey, byXP in pairs(tiers) do
      if type(byXP) == "table" then
        for _, sid in pairs(byXP) do
          if tonumber(sid) == skillLineID then
            return tostring(profKey)
          end
        end
      end
    end
  end

  return nil
end

local function SkillLineMatches(wantID, haveID)
  wantID = tonumber(wantID)
  haveID = tonumber(haveID)
  if not wantID or wantID <= 0 or not haveID or haveID <= 0 then
    return false
  end
  if wantID == haveID then
    return true
  end

  local wantKey = GetProfessionKeyBySkillLineID(wantID)
  local haveKey = GetProfessionKeyBySkillLineID(haveID)
  if wantKey and haveKey and wantKey == haveKey then
    return true
  end

  -- Allow a base profession request to match a specialization skill line
  -- such as Midnight Cooking/Fishing when the rule asks for Cooking/Fishing.
  local base = ALIAS_SKILLLINE_TO_BASE[haveID]
  if base and base == wantID then
    return true
  end

  return false
end

local function EnsureCache()
  fr0z3nUI_QuestTracker_Char = fr0z3nUI_QuestTracker_Char or {}
  fr0z3nUI_QuestTracker_Char.cache = fr0z3nUI_QuestTracker_Char.cache or {}

  local c = fr0z3nUI_QuestTracker_Char.cache
  if c.knownProfessionSkillLinesVersion ~= Profs.CACHE_VERSION then
    c.knownProfessionSkillLines = {}
    c.knownProfessionSkillLinesAt = 0
    c.knownProfessionKeys = {}
    c.knownProfessionKeysAt = 0
    c.knownProfessionSkillLinesVersion = Profs.CACHE_VERSION
  end
  c.knownProfessionSkillLines = (type(c.knownProfessionSkillLines) == "table") and c.knownProfessionSkillLines or {}
  c.knownProfessionSkillLinesAt = (type(c.knownProfessionSkillLinesAt) == "number") and c.knownProfessionSkillLinesAt or 0
  c.knownProfessionKeys = (type(c.knownProfessionKeys) == "table") and c.knownProfessionKeys or {}
  c.knownProfessionKeysAt = (type(c.knownProfessionKeysAt) == "number") and c.knownProfessionKeysAt or 0
  return c
end

local function PlayerContextReady()
  if type(IsLoggedIn) == "function" and IsLoggedIn() then
    return true
  end
  if type(UnitName) == "function" then
    local n = UnitName("player")
    if type(n) == "string" and n ~= "" then
      return true
    end
  end
  return false
end

local function MarkSkillLine(outLines, outKeys, skillLineID, name)
  skillLineID = tonumber(skillLineID)
  if not skillLineID or skillLineID <= 0 then return false end
  outLines[skillLineID] = true

  local base = ALIAS_SKILLLINE_TO_BASE[skillLineID]
  if base and base ~= skillLineID then
    outLines[base] = true
  end

  local stable = GetProfessionKeyBySkillLineID(skillLineID)
  local stableBase = stable and Profs.BASE_SKILLLINE_BY_PROFKEY and Profs.BASE_SKILLLINE_BY_PROFKEY[stable] or nil
  stableBase = tonumber(stableBase)
  if stableBase and stableBase > 0 then
    outLines[stableBase] = true
  end

  local key = tostring(stable or name or "")
  if key ~= "" then
    outKeys[key] = true
  end
  return true
end

local function RememberKnownSkillLine(skillLineID, name)
  local c = EnsureCache()
  if type(c.knownProfessionSkillLines) ~= "table" then
    c.knownProfessionSkillLines = {}
  end
  if type(c.knownProfessionKeys) ~= "table" then
    c.knownProfessionKeys = {}
  end

  MarkSkillLine(c.knownProfessionSkillLines, c.knownProfessionKeys, skillLineID, name)

  if type(time) == "function" then
    local t = time()
    c.knownProfessionSkillLinesAt = t
    c.knownProfessionKeysAt = t
  else
    c.knownProfessionSkillLinesAt = c.knownProfessionSkillLinesAt or 0
    c.knownProfessionKeysAt = c.knownProfessionKeysAt or 0
  end
end

-- Refresh the cached *base profession skillLineIDs*.
-- Also attempts to include expansion-tier profession skillLineIDs via C_TradeSkillUI when available.
-- Returns: true if cache was updated, false otherwise.
function Profs.RefreshKnownProfessionSkillLines(force)
  local c = EnsureCache()
  local priorLines = (type(c.knownProfessionSkillLines) == "table") and c.knownProfessionSkillLines or nil

  local now = (type(GetTime) == "function") and GetTime() or nil
  if not force and type(now) == "number" then
    if (now - (Profs._lastRefreshAt or 0)) < 1 then
      return false
    end
  end

  local outLines = {}
  local outKeys = {}
  local sawAny = false

  -- 1) Base professions from GetProfessions()/GetProfessionInfo().
  local GP = _G and rawget(_G, "GetProfessions")
  local GPI = _G and rawget(_G, "GetProfessionInfo")
  local prof1, prof2, archaeology, fishing, cooking
  if type(GP) == "function" and type(GPI) == "function" then
    local ok, p1, p2, a, f, c2 = pcall(GP)
    if ok then
      prof1, prof2, archaeology, fishing, cooking = p1, p2, a, f, c2
      local indices = { prof1, prof2, archaeology, fishing, cooking }
      for i = 1, 5 do
        local idx = indices[i]
        if idx ~= nil then
          -- NOTE: pcall prepends a boolean success flag; skillLine is the 7th return from GetProfessionInfo.
          local ok2, name, _, _, _, _, _, line = pcall(GPI, idx)
          if ok2 then
            if MarkSkillLine(outLines, outKeys, line, name) then
              sawAny = true
            else
              -- If the slot exists but the returned skillLineID is temporarily nil/0,
              -- still mark the stable base profession ids for secondaries.
              if i == 3 then
                if MarkSkillLine(outLines, outKeys, 794, name or "Archaeology") then sawAny = true end
              elseif i == 4 then
                if MarkSkillLine(outLines, outKeys, 356, name or "Fishing") then sawAny = true end
              elseif i == 5 then
                if MarkSkillLine(outLines, outKeys, 185, name or "Cooking") then sawAny = true end
              end
            end
          end
        end
      end
    end
  end

  -- 2) Expansion-tier profession skillLineIDs from TradeSkillUI (when available).
  if C_TradeSkillUI and type(C_TradeSkillUI.GetAllProfessionTradeSkillLines) == "function" then
    local ok3, lines = pcall(C_TradeSkillUI.GetAllProfessionTradeSkillLines)
    if ok3 and type(lines) == "table" then
      for _, lineID in ipairs(lines) do
        -- IMPORTANT: Do NOT assume enumerated TradeSkill lines are learned.
        -- Some builds return a superset of lines. Only treat a line as known when
        -- the profession info reports a real learned skill level/max.
        local info
        if C_TradeSkillUI.GetProfessionInfoBySkillLineID then
          local ok4, v = pcall(C_TradeSkillUI.GetProfessionInfoBySkillLineID, lineID)
          if ok4 and type(v) == "table" then
            info = v
          end
        end

        local isKnown = false
        if type(info) == "table" then
          local maxLvl = tonumber(info.maxSkillLevel)
          local lvl = tonumber(info.skillLevel)
          if (type(maxLvl) == "number" and maxLvl > 0) or (type(lvl) == "number" and lvl > 0) then
            isKnown = true
          end
        end

        if isKnown then
          local name = info and (info.professionName or info.name) or nil
          if MarkSkillLine(outLines, outKeys, lineID, name) then
            sawAny = true
          end
        end
      end
    end
  end

  -- If we didn't observe anything usable, do not clobber prior cache.
  if not sawAny then
    -- If we have a prior cache and the API is returning all-nil while logged in,
    -- treat this as a transient "API not ready" state.
    local hadPrior = (type(c.knownProfessionSkillLinesAt) == "number" and c.knownProfessionSkillLinesAt > 0)
    if hadPrior and PlayerContextReady() and prof1 == nil and prof2 == nil and archaeology == nil and fishing == nil and cooking == nil then
      Profs._lastRefreshAt = (type(now) == "number") and now or (Profs._lastRefreshAt or 0)
      return false
    end
    return false
  end

  -- Preserve prior learned tier line IDs for professions we still know.
  -- Some login states only report stable/base IDs at first, then tier IDs later.
  if type(priorLines) == "table" then
    for priorLineID, had in pairs(priorLines) do
      if had == true and outLines[priorLineID] ~= true then
        local key = GetProfessionKeyBySkillLineID(priorLineID)
        if key and outKeys[key] == true then
          outLines[priorLineID] = true
        end
      end
    end
  end

  c.knownProfessionSkillLines = outLines
  if type(time) == "function" then
    c.knownProfessionSkillLinesAt = time()
  else
    c.knownProfessionSkillLinesAt = c.knownProfessionSkillLinesAt or 0
  end

  c.knownProfessionKeys = outKeys
  if type(time) == "function" then
    c.knownProfessionKeysAt = time()
  else
    c.knownProfessionKeysAt = c.knownProfessionKeysAt or 0
  end

  Profs._lastRefreshAt = (type(now) == "number") and now or (Profs._lastRefreshAt or 0)
  return true
end

function Profs.HasSkillLineID(skillLineID)
  skillLineID = tonumber(skillLineID)
  if not skillLineID or skillLineID <= 0 then return false end

  local c = EnsureCache()

  -- Try live refresh first; if it fails, fall back to cache.
  pcall(Profs.RefreshKnownProfessionSkillLines, false)

  local at = c.knownProfessionSkillLinesAt
  if type(at) == "number" and at > 0 then
    if type(c.knownProfessionSkillLines) == "table" and c.knownProfessionSkillLines[skillLineID] == true then
      return true
    end
  end

  -- Fallback (safe): directly check GetProfessions when cache isn't populated yet.
  -- This avoids the old false-positive bug (never enumerate all TradeSkill lines as "known").
  local GP = _G and rawget(_G, "GetProfessions")
  local GPI = _G and rawget(_G, "GetProfessionInfo")
  if type(GP) == "function" and type(GPI) == "function" then
    local ok, p1, p2, a, f, c2 = pcall(GP)
    if ok then
      local indices = { p1, p2, a, f, c2 }
      for i = 1, 5 do
        local idx = indices[i]
        if idx ~= nil then
          -- NOTE: pcall prepends a boolean success flag; skillLine is the 7th return from GetProfessionInfo.
          local ok2, name, _, _, _, _, _, line = pcall(GPI, idx)
          if ok2 and SkillLineMatches(skillLineID, line) then
            RememberKnownSkillLine(line, name)
            return true
          end
          -- Slot-based fallback for secondaries.
          if i == 3 and skillLineID == 794 then return true end
          if i == 4 and skillLineID == 356 then return true end
          if i == 5 and skillLineID == 185 then return true end
        end
      end
    end
  end

  -- Targeted TradeSkill probe (safe): ask about a specific skillLineID.
  -- This avoids the old bug (enumerating all lines) while still allowing us to
  -- reliably detect primaries on characters where GetProfessions is flaky.
  if C_TradeSkillUI and type(C_TradeSkillUI.GetProfessionInfoBySkillLineID) == "function" then
    local ok, info = pcall(C_TradeSkillUI.GetProfessionInfoBySkillLineID, skillLineID)
    if ok and type(info) == "table" then
      local maxLvl = tonumber(info.maxSkillLevel)
      local lvl = tonumber(info.skillLevel)
      if (type(maxLvl) == "number" and maxLvl > 0) or (type(lvl) == "number" and lvl > 0) then
        RememberKnownSkillLine(skillLineID, info.professionName or info.name)
        return true
      end
    end
  end

  return false
end

function Profs.HasExactSkillLineID(skillLineID)
  skillLineID = tonumber(skillLineID)
  if not skillLineID or skillLineID <= 0 then return false end

  local c = EnsureCache()

  -- Try live refresh first; if it fails, fall back to cache.
  pcall(Profs.RefreshKnownProfessionSkillLines, false)

  local at = c.knownProfessionSkillLinesAt
  if type(at) == "number" and at > 0 then
    if type(c.knownProfessionSkillLines) == "table" and c.knownProfessionSkillLines[skillLineID] == true then
      return true
    end
  end

  -- Exact fallback via GetProfessions/GetProfessionInfo (no base/tier collapsing).
  local GP = _G and rawget(_G, "GetProfessions")
  local GPI = _G and rawget(_G, "GetProfessionInfo")
  if type(GP) == "function" and type(GPI) == "function" then
    local ok, p1, p2, a, f, c2 = pcall(GP)
    if ok then
      local indices = { p1, p2, a, f, c2 }
      for i = 1, 5 do
        local idx = indices[i]
        if idx ~= nil then
          local ok2, name, _, _, _, _, _, line = pcall(GPI, idx)
          line = tonumber(line)
          if ok2 and line and line == skillLineID then
            RememberKnownSkillLine(line, name)
            return true
          end
          if i == 3 and skillLineID == 794 then return true end
          if i == 4 and skillLineID == 356 then return true end
          if i == 5 and skillLineID == 185 then return true end
        end
      end
    end
  end

  -- Exact targeted probe for this specific line ID.
  if C_TradeSkillUI and type(C_TradeSkillUI.GetProfessionInfoBySkillLineID) == "function" then
    local ok, info = pcall(C_TradeSkillUI.GetProfessionInfoBySkillLineID, skillLineID)
    if ok and type(info) == "table" then
      local maxLvl = tonumber(info.maxSkillLevel)
      local lvl = tonumber(info.skillLevel)
      if (type(maxLvl) == "number" and maxLvl > 0) or (type(lvl) == "number" and lvl > 0) then
        RememberKnownSkillLine(skillLineID, info.professionName or info.name)
        return true
      end
    end
  end

  return false
end

Profs.HasExactProfessionSkillLineID = Profs.HasExactSkillLineID

function Profs.HasProfessionKey(professionKey)
  local c = EnsureCache()

  pcall(Profs.RefreshKnownProfessionSkillLines, false)

  local at = c.knownProfessionKeysAt
  if type(at) ~= "number" or at <= 0 then
    return false
  end

  local key = tostring(professionKey or "")
  if key == "" then return false end

  return (type(c.knownProfessionKeys) == "table" and c.knownProfessionKeys[key] == true) and true or false
end
