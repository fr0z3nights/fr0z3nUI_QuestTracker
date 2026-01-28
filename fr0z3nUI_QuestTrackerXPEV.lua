local addonName, ns = ...

-- Expansion DBEV (Events)
-- Put event-specific baked rules in this file.

ns.rules = ns.rules or {}

local EXPANSION_ID = -2
local EXPANSION_NAME = "Events"

local Y, N = true, false

local bakedRules = {
  {
    ["frameID"] = "list2",
    key = "event:pvp-brawl:southshore-tarren-mill",
    label = "PvP Brawl: Southshore vs. Tarren Mill",
    questInfo = "PvP: SS vs TM",
    aura = { eventKind = "calendar", keywords = { "PvP Brawl: Southshore vs. Tarren Mill" }, mustHave = true, rememberWeekly = true },
    playerLevel = { ">=", 20 },
    noAutoDisplay = true,
  },

  {
    ["frameID"] = "list2",
    key = "event:pvp-brawl:classic-ashran",
    label = "PvP Brawl: Classic Ashran",
    questInfo = "PvP: Ashran",
    aura = { eventKind = "calendar", keywords = { "PvP Brawl: Classic Ashran" }, mustHave = true, rememberWeekly = true },
    playerLevel = { ">=", 20 },
    noAutoDisplay = true,
  },

  {
    ["frameID"] = "list2",
    key = "event:pvp-brawl:packed-house",
    label = "PvP Brawl: Packed House",
    questInfo = "PvP: Packed House",
    aura = { eventKind = "calendar", keywords = { "PvP Brawl: Packed House" }, mustHave = true, rememberWeekly = true },
    playerLevel = { ">=", 20 },
    noAutoDisplay = true,
  },

  {
    ["frameID"] = "list2",
    key = "event:pvp-brawl:deep-six",
    label = "PvP Brawl: Deep Six",
    questInfo = "PvP: Deep Six",
    aura = { eventKind = "calendar", keywords = { "PvP Brawl: Deep Six" }, mustHave = true, rememberWeekly = true },
    playerLevel = { ">=", 20 },
    noAutoDisplay = true,
  },

  {
    ["frameID"] = "list2",
    key = "event:winds-of-mysterious-fortune",
    label = "Winds of Mysterious Fortune",
    questInfo = "LVL",
    aura = { eventKind = "calendar", keywords = { "Winds of Mysterious Fortune" }, mustHave = true, rememberWeekly = true },
    levelGate = "leveling",
    hideWhenCompleted = false,
  },

  {
    ["frameID"] = "list2",
    key = "event:darkmoon-faire",
    label = "Darkmoon Faire",
    questInfo = "Darkmoon",
    aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, mustHave = true, rememberDaily = true },
    playerLevel = { ">=", 20 },
    hideWhenCompleted = false,
  },

  {
    ["frameID"] = "list2",
    key = "event:love-is-in-the-air",
    label = "Love is in the Air",
    questInfo = "Valentines",
    aura = { eventKind = "calendar", keywords = { "Love is in the Air" }, mustHave = true, rememberDaily = true },
    playerLevel = { ">=", 20 },
    hideWhenCompleted = false,
  },




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
