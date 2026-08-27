local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB07 (Legion)

ns.rules = ns.rules or {}

local EXPANSION_ID = 7
local EXPANSION_NAME = "Legion"

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

  --questID = 44659, prereq = { 60151, 60150, 61874, }, requireInLog = true,  
--                                                                                                                                       -- mapIDs: fUI_QTUsage.lua
	{key = "XP07:Q44184A",  questID = 44184, qilID = 40519,      faction = "A",   label = "07 A Legion HS", frameID = "list1", hideQID = {44184,44659,}, mapID = {84,85,},    questInfo = "Legion\n + Warboard: Broken Shore\n + NPC in Stormwind Harbor\n + Skip Scenario if you can\n + Reach Legion Dalaran", },
	{key = "XP07:Q44184H",  questID = 44184, qilID = 43926,      faction = "H",   label = "07 H Legion HS", frameID = "list1", hideQID = {44184,44659,}, mapID = {84,85,1,},  questInfo = "Legion\n + Warboard: Broken Shore\n + NPC Outside Front Gate\n + Skip Scenario if you can\n + Reach Legion Dalaran", },
	{key = "XP07:Q45727",   questID = 45727, prereq = {60151,60150,46931,30515,}, label = "07 Karazhan 1",  frameID = "list1", hideDone = true,          mapID = {84,85,},    questInfo = "Legion\n + Unlock Legion World Quests\n   - Khadgar \"Uniting the Isles\"", },
	{key = "XP07:Q44733",   questID = 44733, prereq = {45727,30515,},             label = "07 Karazhan 2",  frameID = "list1", hideDone = true,          mapID = {84,85,},    questInfo = "Legion\n + Karazhan Attunement (Zygor)\n  - Skip to 12\n  - Pickup !Waterlogged Journal", },
	{key = "XP07:Q44735",   questID = 44735, prereq = {44733,},                   label = "07 Karazhan 3",  frameID = "list1", hideDone = true,          mapID = {84,85,},    questInfo = "Legion\n + Karazhan Attunement (Zygor)\n + Quest: Fragments & Eye\n   - Enter HEROIC Dungeon\n   - Turn off Instance Reset\n   - Crystals & Full Clear", },
	{key = "XP07:Q45291",   questID = 45291, prereq = {44735,},                   label = "07 Karazhan 4",  frameID = "list1", hideDone = true,          mapID = {84,85,},    questInfo = "Legion Return to Karazhan\n + Quest: Book Wyrms\n   - Re-Enter HEROIC\n   - Clear Library\n   - Invite/Leave Group", },
	{key = "XP07:Q45292",   questID = 45292, prereq = {45291,},                   label = "07 Karazhan 5",  frameID = "list1", hideDone = true,          mapID = {84,85,},    questInfo = "Legion Return to Karazhan\n + Quest: Rebooting Curator\n   - Reset/Enter HEROIC\n   - Opera/Moroes/Curator\n   - Pickup Item Off Curator\n   - Create/Leave Group", },
	{key = "XP07:Q45293",   questID = 45293, prereq = {45292,},                   label = "07 Karazhan 6",  frameID = "list1", hideDone = true,          mapID = {84,85,},    questInfo = "Legion Return to Karazhan\n + Quest: New Shoes\n   - Pickup New Shoes\n   - Re-Enter HEROIC\n   - Deliver & Exit Door", },
	{key = "XP07:Q45294",   questID = 45294, prereq = {45293,},                   label = "07 Karazhan 7",  frameID = "list1", hideDone = true,          mapID = {84,85,},    questInfo = "Legion Return to Karazhan\n + Quest: High Stress Hiatus\n   - Kill Shade/Devourer\n   - Cape Chess Room\n   - Create/Leave Reset/Enter\n   - Opera/Trash/Moros\n + Create/Leave Group", },
	{key = "XP07:Q45295",   questID = 45295, prereq = {45294,},                   label = "07 Karazhan 8",  frameID = "list1", hideDone = true,          mapID = {84,85,},    questInfo = "Legion Return to Karazhan\n + Quest: Clearing Cobwebs\n   - Re-Enter HEROIC\n   - Kill Spiders", },
	{key = "XP07:Q45296",   questID = 45296, prereq = {45295,},                   label = "07 Karazhan 9",  frameID = "list1", hideDone = true,          mapID = {84,85,},    questInfo = "Legion Return to Karazhan\n - Change to MYTHIC\n   - Get 5 CRYSTALS\n   - Opera/Maiden/Moroes (keys)\n   -Attuman/Spiders/Curator\n   - Balcony, Kill Nightbane", },



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
    r.mapID = ns.ExpandMapIDs(r.mapID)
    ns.rules[#ns.rules + 1] = r
  end
end
