local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB07 (Legion)

ns.rules = ns.rules or {}

local EXPANSION_ID = 7
local EXPANSION_NAME = "Legion"

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

{label = "SU  07  Hearthstone Unlock", faction = "alliance", frameID = "list1", key = "custom:q:44184:list1:XP07011",
questID = 44184, hideWhenCompleted = true, hideIfAnyQuestCompleted = { 44184, 44659, },
questInfo = "Legion\n + Warboard: Broken Shore\n + NPC in Stormwind Harbor\n + Skip Scenario if you can\n + Reach Legion Dalaran\n ", },
--questID = 44659, prereq = { 60151, 60150, 61874, }, 
{label = "SU  07  Hearthstone Unlock", faction = "horde", frameID = "list1", key = "custom:q:44184:list1:XP07011",
questID = 44184, hideWhenCompleted = true, hideIfAnyQuestCompleted = { 44184, 44659, },
questInfo = "Legion\n + Warboard: Broken Shore\n + NPC Outside Front Gate\n + Skip Scenario if you can\n + Reach Legion Dalaran\n ", },

{label = "SU  07  Karazhan 01", frameID = "list1", key = "custom:q:45727:list1:XP07001",
questID = 45727, prereq = { 60151, 60150, 46931, 30515, }, hideWhenCompleted = true,
questInfo = "Legion\n + Unlock Legion World Quests\n   - Khadgar \"Uniting the Isles\"", },

{label = "SU  07  Karazhan 02", frameID = "list1", key = "custom:q:44733:list1:XP07002",
questID = 44733, prereq = { 45727, 30515, }, hideWhenCompleted = true,
questInfo = "Legion\n + Karazhan Attunement (Zygor)\n      Skip to 12\n + Pickup !Waterlogged Journal", },

{label = "SU  07  Karazhan 03", frameID = "list1", key = "custom:q:44735:list1:XP07003",
questID = 44735, prereq = { 44733, }, hideWhenCompleted = true,
questInfo = "Legion\n + Karazhan Attunement (Zygor)\n + Quests: Fragments & Eye\n + Enter HEROIC Dungeon\n    - Turn off Instance Reset\n + Crystals & Full Clear\n ", },

{label = "SU  07  Karazhan 04", frameID = "list1", key = "custom:q:45291:list1:XP07004",
questID = 45291, prereq = { 44735, }, hideWhenCompleted = true,
questInfo = "Legion Return to Karazhan\n + Quest: Book Wyrms\n - Re-Enter HEROIC\n - Clear Library\n - Invite/Leave Group\n ", },

{label = "SU  07  Karazhan 05", frameID = "list1", key = "custom:q:45292:list1:XP07005",
questID = 45292, prereq = { 45291, }, hideWhenCompleted = true,
questInfo = "Legion Return to Karazhan\n + Quest: Rebooting Curator\n + Reset & Enter HEROIC\n + Kill Opera, Moroes, Curator\n - Pickup Item Off Curator\n - Create/Leave Group\n ", },

{label = "SU  07  Karazhan 06", frameID = "list1", key = "custom:q:45293:list1:XP07006",
questID = 45293, prereq = { 45292, }, hideWhenCompleted = true,
questInfo = "Legion Return to Karazhan\n + Quest: New Shoes\n - Pickup Item Off New Shoes\n - Re-Enter HEROIC\n - Deliver & Leave\n ", },

{label = "SU  07  Karazhan 07", frameID = "list1", key = "custom:q:45294:list1:XP07007",
questID = 45294, prereq = { 45293, }, hideWhenCompleted = true,
questInfo = "Legion Return to Karazhan\n + Quest: High Stress Hiatus\n - Re-Enter Kill Shade/Devourer\n - Cape Left Wall Chess Room\n - Create/Leave/Reset/Enter\n + Kill Opera/Trash/Moros\n + Create/Leave Group", },

{label = "SU  07  Karazhan 08", frameID = "list1", key = "custom:q:45295:list1:XP07008",
questID = 45295, prereq = { 45294, }, hideWhenCompleted = true,
questInfo = "Legion Return to Karazhan\n - Front of Karazhan Quests\n + Quest: Clearing Cobwebs\n + Re-Enter HEROIC\n + Kill Spiders\n ", },

{label = "SU  07  Karazhan 09", frameID = "list1", key = "custom:q:45296:list1:XP07009",
questID = 45296, prereq = { 45295, }, hideWhenCompleted = true,
questInfo = "Legion Return to Karazhan\n - Change to MYTHIC & Enter\n - Get 5 CRYSTALS\n Opera, Maiden, Moroes (keys)\n Attuman, Spiders, Curator\n + Back Down Kill Nightbane", },



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
