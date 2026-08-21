local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB11 (The War Within)

ns.rules = ns.rules or {}

local EXPANSION_ID = 11
local EXPANSION_NAME = "The War Within"

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


  {key = "XP11:I230728",  item = {itemID = 230728, required = { 5, true, N, 0 },},  label = "Experimental Go-Pack",   hideWhenCompleted = false,  locationID = "2369",                          frameID = "list1",  itemInfo = "Experimental Go-Pack", },
  {key = "XP11:I202046",  item = {itemID = 202046, required = { 1, true, N, 0 },},  label = "Lucky Tortollan Charm",  restedOnly = true,          locationID = {84,85,},                        frameID = "list1",  itemInfo = "Lucky Tortollan Charm\n - Near Azj-Kahet Portal", },
  {key = "XP11:Q78713",   questID = 78713, prereq = { 67700, },                     label = "Isle of Dorn 01",        hideWhenCompleted = true,   locationID = {84,85,},                        frameID = "list1",  questInfo = "The War Within\nUse Teleportation Scroll", },
  {key = "XP11:Q81966",   questID = 81966, prereq = { 78713, },                     label = "Isle of Dorn 02",        hideWhenCompleted = true,   locationID = {84,85,},                        frameID = "list1",  questInfo = "The War Within\n + Intro & Isle of Dorn (Zygor)", },
  {key = "XP11:Q81972",   questID = 81972, prereq = {65646,82819,},                 label = "11  34 Slot Bag 2",      hideWhenCompleted = true,   rested = true ,                               frameID = "list1",  questInfo = "War Within Bag  \n - Priory, Hallowfall  30,38", },
--{key = "XP11:Q82356",   questID = 82356, prereq = { 46931, 51341, 61874, },       label = "Coffer Key 82356",       hideWhenCompleted = true,                                                 frameID = "list1",  questInfo = " + Key - Dornogal Hall", },
--{key = "XP11:Q82375",   questID = 82375, prereq = { 46931, 51341, 61874, },       label = "Coffer Key 82375",       hideWhenCompleted = true,                                                 frameID = "list1",  questInfo = " + Key - Dornogal Hall", },
--{key = "XP11:Q82398",   questID = 82398, prereq = { 46931, 51341, 61874, },       label = "Coffer Key 82398",       hideWhenCompleted = true,                                                 frameID = "list1",  questInfo = " + Key - Mereldar Hallowfall", },
--{key = "XP11:Q82434",   questID = 82434, prereq = { 46931, 51341, 61874, },       label = "Coffer Key 82434",       hideWhenCompleted = true,                                                 frameID = "list1",  questInfo = " + Key - Spiders (Portal)", },
  {key = "XP11:Q82520",   questID = 82520, prereq = { 46957, 51341, 61874, },       label = "Pet Mind Slurp",         hideWhenCompleted = true,   locationID = {84,85,},                        frameID = "list1",  questInfo = " + Mind Slurp (Memory Cache)\n - Azj-Kahet 30.23, 38.75", },
  {key = "XP11:Q82678",   questID = 82678,                                          label = "Archives: First Disc",   hideWhenCompleted = true,                       playerLevel = {"=",80,},  frameID = "bar1",   questInfo = "First Disc", },
  {key = "XP11:Q82679",   questID = 82679, prereq = {82678,},                       label = "Archives",               hideWhenCompleted = true,                       playerLevel = {"=",80,},  frameID = "bar1",   questInfo = "Archive", progress = { objectiveIndex = 1 }, },
  {key = "XP11:Q82706",   questID = 82706,                                          label = "Delve 11",               hideWhenCompleted = true,                       playerLevel = {"=",80,},  frameID = "bar1",   questInfo = "Delve 11", progress = { objectiveIndex = 1 }, },
  {key = "XP11:Q82819",   questID = 82819, prereq = {65646,},                       label = "11  34 Slot Bag 1",      hideWhenCompleted = true,   rested = true ,                               frameID = "list1",  questInfo = "War Within Bag  \n - Murroch, Ringing Deep 3412", },
  {key = "XP11:Q84260",   questID = 84260, prereq = { 46957, 51341, 61874, },       label = "Crafting Order",         hideWhenCompleted = true,   locationID = {84,85,},                        frameID = "list1",  questInfo = "+ Dornogal Crafting Order Reward", },
--{key = "XP11:Q85573",   questID = 85573, prereq = { 45727, },                     label = "Isle of Dorn 03",        hideWhenCompleted = true,                                                 frameID = "list1",  questInfo = "The War Within\n + Siren Isle (Zygor)", },
--{key = "XP11:Q90557",   questID = 90557, prereq = { 46931, 51341, 61874, },       label = "11 Coffer Key 90557",    hideWhenCompleted = true,                                                 frameID = "list1",  questInfo = "+ Key - Undermine", },
  {key = "XP11:Q90938",   questID = 90938,                                          label = "Reshii Wraps",           hideIfAnyQuestCompleted = {90938,84856,84910,}, playerLevel = {">",79,},  frameID = "bar1",   questInfo = "Reshii", color = { 0.2, 0.6, 1, }, },
  {key = "XP11:Q91009",   questID = 91009,                                          label = "Belt 1",                 hideWhenCompleted = true,                       playerLevel = {"=",80,},  frameID = "bar1",   questInfo = "Belt 1", color = { 0.2, 0.6, 1, }, },
  {key = "XP11:Q91026",   questID = 91026, prereq = {91009,},                       label = "Belt 2",                 hideWhenCompleted = true,                       playerLevel = {"=",80,},  frameID = "bar1",   questInfo = "Belt 2", color = { 0.2, 0.6, 1, }, },
  {key = "XP11:Q91030",   questID = 91030, prereq = {91026,},                       label = "Belt 3",                 hideWhenCompleted = true,                       playerLevel = {"=",80,},  frameID = "bar1",   questInfo = "Belt 3", color = { 0.2, 0.6, 1, }, },
  {key = "XP11:Q91031",   questID = 91031, prereq = {91030,},                       label = "Belt 4",                 hideWhenCompleted = true,                       playerLevel = {"=",80,},  frameID = "bar1",   questInfo = "Belt 4", color = { 0.2, 0.6, 1, }, },




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
