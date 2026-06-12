local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB06 (Warlords of Draenor)

ns.rules = ns.rules or {}

local EXPANSION_ID = 6
local EXPANSION_NAME = "Warlords of Draenor"

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

{label = "SU  06  Garrison 01 A", frameID = "list1", key = "custom:q:36941:list1:XP06017",
questID = 36941, prereq = { 47189, }, hideWhenCompleted = true, faction = "Alliance",
questInfo = "Warlords of Draenor\n + Warboard: The Dark Portal\n + Talk to Battlemage\n   - Portal Tower Entrance\n   - After Port Abandom Quest\n + Iron Horde Invasion (Zygor)",},

{label = "SU  06  Garrison 02 A", frameID = "list1", key = "custom:q:34586:list1:XP06018",
questID = 34586, prereq = { 36941, }, hideWhenCompleted = true, faction = "Alliance",
questInfo = "Warlords of Draenor\n + Warboard: The Dark Portal\n + Talk to Battlemage\n   - In Portal Tower Entrance\n   - After Port Abandom Quest\n   - Take Red Portal (Draenor)\n   - Do Initial Quests",},

{label = "SU  06  Garrison 03 A", frameID = "list1", key = "custom:q:34775:list1:XP06019",
questID = 34775, prereq = { 34586, }, hideWhenCompleted = true, faction = "Alliance",
questInfo = "Warlords of Draenor\n + Zygor: Shadowmoon Valley\n    01-31 \"Delegating on Draenor\"",},

{label = "SU  06  Garrison 04 A", faction = "alliance", frameID = "list2", key = "custom:q:36615:list1:XP06021",
questID = 36615, hideWhenCompleted = true, questInfo = "Level Garrison to 3", },             -- /dump C_Map.GetBestMapForUnit("player")        prereq = { 34775, }, locationID = {84, 582},

{label = "SU  06  Garrison 01 H", frameID = "list1", key = "custom:q:36940:list1:XP06022",
questID = 36940, prereq = { 47514, }, hideWhenCompleted = true, faction = "Horde",
questInfo = "Warlords of Draenor\n + Warboard: The Dark Portal\n + Talk to Battlemage\n   - Lower Portal Room\n   - After Port Abandom Quest\n + Iron Horde Invasion (Zygor)",},

{label = "SU  06  Garrison 02 H", frameID = "list1", key = "custom:q:34586:list1:XP06023",
questID = 34586, prereq = { 36940, }, hideWhenCompleted = true, faction = "Horde",
questInfo = "Warlords of Draenor\n + Warboard: The Dark Portal\n + Talk to Battlemage\n   - Lower Portal Room\n   - After Port Abandom Quest\n   - Take Red Portal (Draenor)\n   - Do Initial Quests",},

{label = "SU  06  Garrison 03 H", frameID = "list1", key = "custom:q:34960:list1:XP06024",
questID = 34960, prereq = { 34586, }, hideWhenCompleted = true, faction = "Horde",
questInfo = "Warlords of Draenor\n + Frostfire Ridge (Zygor)\n + Quest Until Step 26\n    'The Land Provides'\n ",},

{label = "SU  06  Garrison 04 H", frameID = "list1", key = "custom:q:36567:list1:XP06025",
questID = 36567, prereq = { 34960, }, hideWhenCompleted = true, faction = "Horde",
questInfo = "Warlords of Draenor\n + Collect 200 Garrison Resources\n + Upgrade Garrison to Level 2\n           (Turn in Quest)",},

{label = "SU  06  Garrison 05 H", faction = "horde", frameID = "list2", key = "custom:q:36615:list1:XP06026",
questID = 36614, hideWhenCompleted = true, questInfo = "Level Garrison to 3", },            -- /dump C_Map.GetBestMapForUnit("player")      prereq = { 36567, }, locationID = {85, 590},

{label = "SU  06  Wiggling Egg (Pet)", frameID = "list1", key = "custom:q:33505:list1:XP06027", locationID = 525,
questID = 33505, prereq = { 34586, }, hideWhenCompleted = true, questInfo = "Frostfire Ridge\n + Wiggling Egg", },



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
