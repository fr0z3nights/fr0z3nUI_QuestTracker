local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB08 (Battle for Azeroth)

ns.rules = ns.rules or {}

local EXPANSION_ID = 8
local EXPANSION_NAME = "Battle for Azeroth"

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

-- Alliance
{label = "SU Tiragarde Sound", faction = "Alliance", frameID = "list1", key = "custom:q:47189:list1:XP08025",
questID = 47189, prereq = { 44184, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\n + Tiragarde Sound (Zygor)", },

{label = "SU  The War Campaign 01", faction = "Alliance", frameID = "list1", key = "custom:q:52544:list1:XP08028",
questID = 52544, prereq = { 47189, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n   1: WBT 200 War Resources\n       Get Resources Chests", },

{label = "SU The War Campaign 02", faction = "Alliance", frameID = "list1", key = "custom:q:53332:list1:XP08029",
questID = 53332, prereq = { 52544, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n   2: Return to Boralus Ship", },

{label = "SU The War Campaign 03", faction = "Alliance", frameID = "list1", key = "custom:q:51714:list1:XP08030",
questID = 51714, prereq = { 53332, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n   3: Start Mission, Skip to 13", },

{label = "SU The War Campaign 04", faction = "Alliance", frameID = "list1", key = "custom:q:51359:list1:XP08031",
questID = 51359, prereq = { 51714, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n   4: Open Zuldazar", },

{label = "SU The War Campaign 05", faction = "Alliance", frameID = "list1", key = "custom:q:51177:list1:XP08032",
questID = 51177, prereq = { 51359, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n   5: Open Nazmir", },

{label = "SU The War Campaign 06", faction = "Alliance", frameID = "list1", key = "custom:q:51402:list1:XP08033",
questID = 51402, prereq = { 51359, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n   6: Open Voldun", },

{label = "SU The War Campaign 07", faction = "Alliance", frameID = "list1", key = "custom:q:52428:list1:XP08034",
questID = 52428, prereq = { 51402, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n   7: Complete A Dying World", },

{label = "SU The War Campaign 08", faction = "Alliance", frameID = "list1", key = "custom:q:52450:list1:XP08035",
questID = 52450, prereq = { 52428, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n   8: Complete Uniting Kul Tiras", },

{label = "SU The War Campaign 09", faction = "Alliance", frameID = "list1", key = "custom:q:65669:list1:XP08036",
questID = 65669, prereq = { 52450, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\nReturn to Lordaeron", },

{label = "SU  Nazjatar 01", faction = "Alliance", frameID = "list1", key = "custom:q:54972:list1:XP08048",
questID = 54972, prereq = { 52450, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\n + Nazjatar (Zygor)\n + Quest Until Accepting\n       \"Essential Empowerment\"\n  + Port to Zuldazar", },

{label = "SU  Nazjatar 02", faction = "Alliance", frameID = "list1", key = "custom:q:56162:list1:XP08048",
questID = 56162, prereq = { 54972, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\n + Nazjatar (Zygor)\n + Equip Heart for Heart parts\n + Quest Until\n      \"Back Out to Sea\"\n  + Pad/Portals to Nazjatar", },

{label = "SU  Nazjatar 03", faction = "Alliance", frameID = "list1", key = "custom:q:56156:list1:XP08049",
questID = 56156, prereq = { 56162, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\n + Nazjatar (Zygor)\n + Use Red Rider Air Rifle\n + If Helper Kills, Remove Buff\n + If Hand in Not There, DeBuff\n + Quest Until A Tempered Blade\n ", },

{label = "SU  Mechagon", faction = "Alliance", frameID = "list1", key = "custom:q:54992:list1:XP08050",
questID = 54992, prereq = { 56156, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\n + Mechagon (Zygor)\n + Quest Until Turning In\n      \"Princely Visit\"", },

{label = "SU  N'Zoth Invasions 01", faction = "Alliance", frameID = "list1", key = "custom:q:58506:list1:XP08061A",
questID = 58506, prereq = { 56156, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\nMagnis Plan (Zygor)\n  + PickUp Missive\n     A  Dockmasters Office\n  + Follow Guide\n    - Consoles Unnamed?, Relog", },

-- Horde
{label = "SU  Zuldazar", faction = "Horde", frameID = "list1", key = "custom:q:47514:list1:XP08026",
questID = 47514, prereq = { 60151, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\n + Zuldazar (Zygor)\n + Click Map Choose Zuldazar", },

{label = "SU The War Campaign 01", faction = "Horde", frameID = "list1", key = "custom:q:52746:list1:XP08037",
questID = 52746, prereq = { 46931, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n   1: Take War Campaign Quest\n   Warband Transfer Resources\n   Port to Orgimmar & Back\n   2: Get Resources Chests/WBT", },

{label = "SU The War Campaign 02", faction = "Horde", frameID = "list1", key = "custom:q:53333:list1:XP08038",
questID = 53333, prereq = { 52746, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n   3: Return to Ship", },

{label = "SU The War Campaign 03", faction = "Horde", frameID = "list1", key = "custom:q:51800:list1:XP08039",
questID = 51800, prereq = { 53333, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n   4: Start Mission, Skip to 10\n   Table: Tiragarde", },

{label = "SU The War Campaign 04", faction = "Horde", frameID = "list1", key = "custom:q:51438:list1:XP08040",
questID = 51438, prereq = { 51800, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n   5: Open Tiragarde Sound", },

{label = "SU The War Campaign 05", faction = "Horde", frameID = "list1", key = "custom:q:51696:list1:XP08041",
questID = 51696, prereq = { 51438, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n   6: Stormsong Valley", },

{label = "SU The War Campaign 06", faction = "Horde", frameID = "list1", key = "custom:q:51234:list1:XP08042",
questID = 51234, prereq = { 51696, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n   7: Open Drustvar", },

{label = "SU The War Campaign 07", faction = "Horde", frameID = "list1", key = "custom:q:52428:list1:XP08043",
questID = 52428, prereq = { 51234, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n   8: Complete A Dying World", },

{label = "SU The War Campaign 08", faction = "Horde", frameID = "list1", key = "custom:q:52451:list1:XP08044",
questID = 52451, prereq = { 52428, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n   9: Complete Uniting Zuldazar", },

{label = "SU The War Campaign 09", faction = "Horde", frameID = "list1", key = "custom:q:65788:list1:XP08045",
questID = 65788, prereq = { 52451, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\nReturn to Lordaeron", },

{label = "SU  Nazjatar 01", faction = "Horde",frameID = "list1", key = "custom:q:55053:list1:XP08053",
questID = 55053, prereq = { 52451, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\nNazjatar (Zygor)\n  1: Follow Guide Until\n       \"A Way Home\"", },

{label = "SU  Nazjatar 02", faction = "Horde",frameID = "list1", key = "custom:q:55851:list1:XP08054",
questID = 55851, prereq = { 55053, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\nNazjatar (Zygor)\n  2: Port to Zuldazar\n         Then Silithus\n         Then Chamber of Heart", },

{label = "SU  Nazjatar 03", faction = "Horde",frameID = "list1", key = "custom:q:55425:list1:XP08055",
questID = 55425, prereq = { 55851, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\nNazjatar (Zygor)\n  3: Follow Guide Until\n       \"Dominating the Indomitable\"", },

{label = "SU  Nazjatar 04", faction = "Horde",frameID = "list1", key = "custom:q:55497:list1:XP08056",
questID = 55497, prereq = { 55425, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\nNazjatar (Zygor)\n  4: Hearth Out\n         Portal to Silithus/Chamber", },

{label = "SU  Nazjatar 05", faction = "Horde",frameID = "list1", key = "custom:q:57010:list1:XP08057",
questID = 57010, prereq = { 55497, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\nNazjatar (Zygor)\n  5: Follow Guide Until\n       \"Back Out to Sea\"", },

{label = "SU  Nazjatar 06", faction = "Horde",frameID = "list1", key = "custom:q:56161:list1:XP08058",
questID = 56161, prereq = { 57010, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\nNazjatar (Zygor)\n  6: Pad to Silithus\n        Portal to Zuldazar\n        Portal to Nazjatar", },

{label = "SU  Nazjatar 07", faction = "Horde",frameID = "list1", key = "custom:q:55500:list1:XP08059",
questID = 55500, prereq = { 56161, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\nNazjatar (Zygor)\n  7: Follow Guide Until\n        \"Save a Friend\"", },

{label = "SU  Nazjatar 08", faction = "Horde", frameID = "list1", key = "custom:q:55652:list1:XP08060",
questID = 55652, prereq = { 55500, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\nMechagon (Zygor)\n    1: Follow Guide Until\n        \"We Come in Peace...\"",  },

{label = "SU  N'Zoth Invasions 01", faction = "Horde", frameID = "list1", key = "custom:q:58506:list1:XP08061H",
questID = 58506, prereq = { 55500, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\nMagnis Plan (Zygor)\n  + PickUp Missive\n     On Ship at Dock\n  + Follow Guide\n    - Consoles Unnamed?, Relog", },

{label = "Commander's Signet of Battle", faction = "Horde", frameID = "list1", key = "custom:item:166559:list1:46",
playerLevel = { ">", 80 }, locationID = "999999", restedOnly = Y, 
item = { itemID = 166559, required = { 1, true, N, 0 }, ["currencyID"] = { 1716, 300 }, }, 
itemInfo = "Commander's Signet of Battle\n  - Docks Honorbound Vendor", },

-- Neautral
{label = "AH  Very Unlucky Rock", frameID = "list1", key = "custom:q:49867:list1:XP08027",
questID = 49867, prereq = { 46931, }, hideWhenCompleted = true, locationID = 1165862,
questInfo = "- Nazmir - Lucky Horaces Chest\n      (AH - Very Unlucky Rock)", },

{label = "PET Wicker Pup", frameID = "list1", key = "custom:q:53448:list1:XP08051",
questID = 53448, prereq = { 51234, }, hideWhenCompleted = true,
questInfo = "Wicker Pup (Zygor)", },

{label = "PET Taptaf", frameID = "list1", key = "custom:q:52061:list1:XP08052",
questID = 52061, prereq = { 53448, }, hideWhenCompleted = true,
questInfo = "Taptaf (Zygor)", },

{label = "SU  N'Zoth Invasions 02", frameID = "list1", key = "custom:q:56209:list1:XP08062",
questID = 56209, prereq = { 58506, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\nMagnis Plan (Zygor)\\n  - Leave Chamber, Fly to Uldum\\n  - Talk Magni, Possibly Skip", },

{label = "SU  N'Zoth Invasions 03", frameID = "list1", key = "custom:q:56376:list1:XP08063",
questID = 56376, prereq = { 56209, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\nMagnis Plan (Zygor)\\n ULDUM OPEN\\n  - Do Dailies, Clear Mobs\\n  - Fish Gloop (Black Empire)", },

{label = "SU  N'Zoth Invasions 04", frameID = "list1", key = "custom:q:56377:list1:XP08064",
questID = 56377, prereq = { 56376, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\nMagnis Plan (Zygor)\\n ULDUM OPEN\\n  - No Forging Onwad, Out & In\\n  - Return to Chamber of Heart", },

{label = "SU  N'Zoth Invasions 05", frameID = "list1", key = "custom:q:56771:list1:XP08065",
questID = 56771, prereq = { 56376, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\nMagnis Plan (Zygor)\\n ULDUM OPEN\\n  - Exit Chamber, Go to Pandaria\\n  - Fish Gloop (Black Empire)\\n  - Return to Chamber of Heart", },

{label = "SU  N'Zoth Invasions 06", frameID = "list1", key = "custom:q:56540:list1:XP08066",
questID = 56540, prereq = { 56771, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\nMagnis Plan (Zygor)\\n ULDUM/VALE OPEN\\n  - Do Dailies, Clear Mobs\\n  - Kill Boss\\n  - Fish Gloop (Black Empire)\\n BOTH OPEN", },

{label = "SU  N'Zoth Invasions 07", frameID = "list1", key = "custom:q:57220:list1:XP08067",
questID = 57220, prereq = { 56540, }, hideWhenCompleted = true,
questInfo = "Battle For Azeroth\nMagnis Plan (Zygor)\\n ULDUM/VALE OPEN\\n  - Skip if Possible\\n  - Follow Guide", },




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
