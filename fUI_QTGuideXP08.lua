local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB08 (Battle for Azeroth)

ns.rules = ns.rules or {}

local EXPANSION_ID = 8
local EXPANSION_NAME = "Battle for Azeroth"

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

	{key = "XP08:I166559",  item = {itemID = 166559, required = {1,true,N,0}, currencyID = {1716,300},},  label = "Commander's Signet of Battle", faction = "H", frameID = "list1", playerLevel = { "=", 90 }, restedOnly = Y,  mapID = {85,}, itemInfo = "Commander's Signet of Battle\n  - Docks Honorbound Vendor", },

--                                                                                                                                       -- mapIDs: fUI_QTUsage.lua
	{key = "XP08:Q47189A",  questID = 47189, prereq = {44184,}, faction = "A",  label = "08 A Tiragarde Sound",   frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + Tiragarde Sound (Zygor)", },
	{key = "XP08:Q54972A",  questID = 54972, prereq = {52450,}, faction = "A",  label = "08 A Nazjatar 1",        frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + Nazjatar (Zygor)\n - Q2: Essential Empowerment\n + Port to Zuldazar", },
	{key = "XP08:Q56162A",  questID = 56162, prereq = {54972,}, faction = "A",  label = "08 A Nazjatar 2",        frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + Nazjatar (Zygor)\n - Q2: Back Out to Sea\n  + Pad/Portals to Nazjatar", },
	{key = "XP08:Q56156A",  questID = 56156, prereq = {56162,}, faction = "A",  label = "08 A Nazjatar 3",        frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + Nazjatar (Zygor)\n - Use Red Rider Air Rifle\n - Remove Assist Buff\n - Quest Until A Tempered Blade", },
	{key = "XP08:Q54992A",  questID = 54992, prereq = {56156,}, faction = "A",  label = "08 A Mechagon",          frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + Mechagon (Zygor)\n - Q2: Princely Visit", },
	{key = "XP08:Q52544A",  questID = 52544, prereq = {47189,}, faction = "A",  label = "08 A War Campaign 1",    frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n - WBT 200 War Resources", },
	{key = "XP08:Q53332A",  questID = 53332, prereq = {52544,}, faction = "A",  label = "08 A War Campaign 2",    frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n - Return to Boralus Ship", },
	{key = "XP08:Q51714A",  questID = 51714, prereq = {53332,}, faction = "A",  label = "08 A War Campaign 3",    frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n - Start Mission, Skip to 13", },
	{key = "XP08:Q51359A",  questID = 51359, prereq = {51714,}, faction = "A",  label = "08 A War Campaign 4",    frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n - Open Zuldazar", },
	{key = "XP08:Q51177A",  questID = 51177, prereq = {51359,}, faction = "A",  label = "08 A War Campaign 5",    frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n - Open Nazmir", },
	{key = "XP08:Q51402A",  questID = 51402, prereq = {51359,}, faction = "A",  label = "08 A War Campaign 6",    frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n - Open Voldun", },
	{key = "XP08:Q52428A",  questID = 52428, prereq = {51402,}, faction = "A",  label = "08 A War Campaign 7",    frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n - Complete A Dying World", },
	{key = "XP08:Q52450A",  questID = 52450, prereq = {52428,}, faction = "A",  label = "08 A War Campaign 8",    frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n - Complete Uniting Kul Tiras", },
	{key = "XP08:Q65669A",  questID = 65669, prereq = {52450,}, faction = "A",  label = "08 A War Campaign 9",    frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n - Return to Lordaeron", },
	{key = "XP08:Q47514H",  questID = 47514, prereq = {60151,}, faction = "H",  label = "08 H Zuldazar",          frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + Zuldazar (Zygor)\n - Click Map Choose Zuldazar", },
	{key = "XP08:Q55053H",  questID = 55053, prereq = {52451,}, faction = "H",  label = "08 H Nazjatar 1",        frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + Nazjatar (Zygor)\n - Q2: A Way Home", },
	{key = "XP08:Q55851H",  questID = 55851, prereq = {55053,}, faction = "H",  label = "08 H Nazjatar 2",        frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + Nazjatar (Zygor)\n - Port: Zuldazar, Silithus\n         Chamber of Heart", },
	{key = "XP08:Q55425H",  questID = 55425, prereq = {55851,}, faction = "H",  label = "08 H Nazjatar 3",        frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + Nazjatar (Zygor)\n - Q2: Dominating the Indomitable", },
	{key = "XP08:Q55497H",  questID = 55497, prereq = {55425,}, faction = "H",  label = "08 H Nazjatar 4",        frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + Nazjatar (Zygor)\n - Hearth / Silithus / Chamber", },
	{key = "XP08:Q57010H",  questID = 57010, prereq = {55497,}, faction = "H",  label = "08 H Nazjatar 5",        frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + Nazjatar (Zygor)\n - Q2: Back Out to Sea", },
	{key = "XP08:Q56161H",  questID = 56161, prereq = {57010,}, faction = "H",  label = "08 H Nazjatar 6",        frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + Nazjatar (Zygor)\n - Silithus / Zuldazar / Nazjatar", },
	{key = "XP08:Q55500H",  questID = 55500, prereq = {56161,}, faction = "H",  label = "08 H Nazjatar 7",        frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + Nazjatar (Zygor)\n - Q2: Save a Friend", },
	{key = "XP08:Q55652H",  questID = 55652, prereq = {55500,}, faction = "H",  label = "08 H Nazjatar 8",        frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + Mechagon (Zygor)\n - Q2: We Come in Peace...", },
	{key = "XP08:Q52746H",  questID = 52746, prereq = {46931,}, faction = "H",  label = "08 H War Campaign 1",    frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n - War Campaign Quest\n - Warband Trf 200\n - Port: Orgimmar & Back", },
	{key = "XP08:Q53333H",  questID = 53333, prereq = {52746,}, faction = "H",  label = "08 H War Campaign 2",    frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n - Return to Ship", },
	{key = "XP08:Q51800H",  questID = 51800, prereq = {53333,}, faction = "H",  label = "08 H War Campaign 3",    frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n - Start Mission, Skip to 10\n   Table: Tiragarde", },
	{key = "XP08:Q51438H",  questID = 51438, prereq = {51800,}, faction = "H",  label = "08 H War Campaign 4",    frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n - Open Tiragarde Sound", },
	{key = "XP08:Q51696H",  questID = 51696, prereq = {51438,}, faction = "H",  label = "08 H War Campaign 5",    frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n - Open Stormsong Valley", },
	{key = "XP08:Q51234H",  questID = 51234, prereq = {51696,}, faction = "H",  label = "08 H War Campaign 6",    frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n - Open Drustvar", },
	{key = "XP08:Q52428H",  questID = 52428, prereq = {51234,}, faction = "H",  label = "08 H War Campaign 7",    frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n - Complete A Dying World", },
	{key = "XP08:Q52451H",  questID = 52451, prereq = {52428,}, faction = "H",  label = "08 H War Campaign 8",    frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n - Complete Uniting Zuldazar", },
	{key = "XP08:Q65788H",  questID = 65788, prereq = {52451,}, faction = "H",  label = "08 H War Campaign 9",    frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + War Campaign (Zygor)\n - Return to Lordaeron", },
	{key = "XP08:Q58506A",  questID = 58506, prereq = {56156,}, faction = "A",  label = "08 A N'Zoth Invasion 1", frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + Magnis Plan (Zygor)\n  - Dockmasters Office\n - Pickup Missive", },
	{key = "XP08:Q58506H",  questID = 58506, prereq = {55500,}, faction = "H",  label = "08 H N'Zoth Invasion 1", frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + Magnis Plan (Zygor)\n  - On Ship at Docks  \n - PickUp Missive", },
	{key = "XP08:Q56209N",  questID = 56209, prereq = {58506,},                 label = "08 N N'Zoth Invasion 2", frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + Magnis Plan (Zygor)\n  - Leave Chamber, Fly to Uldum\n  - Talk Magni, Possibly Skip", },
	{key = "XP08:Q56376N",  questID = 56376, prereq = {56209,},                 label = "08 N N'Zoth Invasion 3", frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + Magnis Plan (Zygor)\n + ULDUM OPEN\n  - Do Dailies, Clear Mobs\n  - Fish Gloop (Black Empire)", },
	{key = "XP08:Q56377N",  questID = 56377, prereq = {56376,},                 label = "08 N N'Zoth Invasion 4", frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + Magnis Plan (Zygor)\n + ULDUM OPEN\n  - No Forging Onwad, PortOI\n  - Return to Chamber of Heart", },
	{key = "XP08:Q56771N",  questID = 56771, prereq = {56376,},                 label = "08 N N'Zoth Invasion 5", frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + Magnis Plan (Zygor)\n + ULDUM OPEN\n  - Exit Chamber, Go to Pandaria\n  - Fish Gloop (Black Empire)\n  - Return to Chamber of Heart", },
	{key = "XP08:Q56540N",  questID = 56540, prereq = {56771,},                 label = "08 N N'Zoth Invasion 6", frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + Magnis Plan (Zygor)\n + ULDUM / VALE OPEN\n  - Do Dailies, Clear Mobs\n  - Kill Boss\n  - Fish Gloop (Black Empire)", },
	{key = "XP08:Q57220N",  questID = 57220, prereq = {56540,},                 label = "08 N N'Zoth Invasion 7", frameID = "list1", hideDone = true, mapID = {"CAP","BFA",},   questInfo = "Battle For Azeroth\n + Magnis Plan (Zygor)\n + ULDUM / VALE OPEN\n  - Skip if Possible", },
	{key = "XP08:Q53448N",  questID = 53448, prereq = {51234,},                 label = "Pet Wicker Pup",         frameID = "list1", hideDone = true, mapID = {"BFA",},   		questInfo = "Battle For Azeroth\n + Wicker Pup (Zygor)", },
	{key = "XP08:Q52061N",  questID = 52061, prereq = {53448,},                 label = "Pet Taptaf",             frameID = "list1", hideDone = true, mapID = {"BFA",},   		questInfo = "Battle For Azeroth\n + Taptaf (Zygor)", },

}


for i = 1, #bakedRules do
  local r = bakedRules[i]
  if type(r) == "table" then
    ns.GuideHelpers.NormalizeRule(r, EXPANSION_ID, EXPANSION_NAME)
    ns.rules[#ns.rules + 1] = r
  end
end
