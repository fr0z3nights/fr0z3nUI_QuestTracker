local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB08 (Battle for Azeroth)

ns.rules = ns.rules or {}

local bakedRules = {

{["label"] = "SU  08  01  A  Q-47189  Tiragarde Sound", ["frameID"] = "list1", ["key"] = "custom:q:47189:list1:25",
["questID"] = 47189, ["prereq"] = { 44184, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth (A1)\n + %n\nTiragarde Sound (Zygor)",
["faction"] = "Alliance", },

{["label"] = "SU  08  01  H  Q-46931  Zuldazar", ["frameID"] = "list1", ["key"] = "custom:q:47514:list1:26",
["questID"] = 47514, ["prereq"] = { 60151, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth\n + Zuldazar (Zygor)\n + Click Map Choose Zuldazar\nNo",
["faction"] = "Horde", },

{["label"] = "SU  08-03  N  Q-49867  AQ-51696  Very Unlucky Rock", ["frameID"] = "list1", ["key"] = "custom:q:49867:list1:27",
["questID"] = 49867, ["prereq"] = { 46931, }, ["hideWhenCompleted"] = true,
["questInfo"] = "- Nazmir - Lucky Horaces Chest\n      (AH - Very Unlucky Rock)",
["locationID"] = 1165862, },

{["label"] = "SU  08-02  A  Q-52450  AQ-47189  The War Campaign 01", ["frameID"] = "list1", ["key"] = "custom:q:52544:list1:28",
["questID"] = 52544, ["prereq"] = { 47189, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth  (A2)\n + %n\nWar Campaign (Zygor)\\n   1: WBT 200 War Resources\\n       Get Resources Chests",
["faction"] = "Alliance", },

{["label"] = "SU  08-02  A  Q-52450  AQ-47189  The War Campaign 02", ["frameID"] = "list1", ["key"] = "custom:q:53332:list1:29",
["questID"] = 53332, ["prereq"] = { 47189, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth  (A2)\n + %n\nWar Campaign (Zygor)\\n   2: Return to Boralus Ship",
["faction"] = "Alliance", },

{["label"] = "SU  08-02  A  Q-52450  AQ-47189  The War Campaign 03", ["frameID"] = "list1", ["key"] = "custom:q:51714:list1:30",
["questID"] = 51714, ["prereq"] = { 47189, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth  (A2)\n + %n\nWar Campaign (Zygor)\\n   3: Start Mission, Skip to 13",
["faction"] = "Alliance", },

{["label"] = "SU  08-02  A  Q-52450  AQ-47189  The War Campaign 04", ["frameID"] = "list1", ["key"] = "custom:q:51359:list1:31",
["questID"] = 51359, ["prereq"] = { 47189, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth  (A2)\n + %n\nWar Campaign (Zygor)\\n   4: Open Zuldazar",
["faction"] = "Alliance", },

{["label"] = "SU  08-02  A  Q-52450  AQ-47189  The War Campaign 05", ["frameID"] = "list1", ["key"] = "custom:q:51177:list1:32",
["questID"] = 51177, ["prereq"] = { 47189, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth  (A2)\n + %n\nWar Campaign (Zygor)\\n   5: Open Nazmir",
["faction"] = "Alliance", },

{["label"] = "SU  08-02  A  Q-52450  AQ-47189  The War Campaign 06", ["frameID"] = "list1", ["key"] = "custom:q:51402:list1:33",
["questID"] = 51402, ["prereq"] = { 47189, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth  (A2)\n + %n\nWar Campaign (Zygor)\\n   6: Open Voldun",
["faction"] = "Alliance", },

{["label"] = "SU  08-02  A  Q-52450  AQ-47189  The War Campaign 07", ["frameID"] = "list1", ["key"] = "custom:q:52428:list1:34",
["questID"] = 52428, ["prereq"] = { 47189, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth  (A2)\n + %n\nWar Campaign (Zygor)\\n   7: Complete A Dying World",
["faction"] = "Alliance", },

{["label"] = "SU  08-02  A  Q-52450  AQ-47189  The War Campaign 08", ["frameID"] = "list1", ["key"] = "custom:q:52450:list1:35",
["questID"] = 52450, ["prereq"] = { 47189, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth  (A2)\n + %n\nWar Campaign (Zygor)\\n   8: Complete Uniting Kul Tiras",
["faction"] = "Alliance", },

{["label"] = "SU  08-02  A  Q-52450  AQ-47189  The War Campaign 09", ["frameID"] = "list1", ["key"] = "custom:q:65669:list1:36",
["questID"] = 65669, ["prereq"] = { 47189, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth  (A2)\n + %n\nReturn to Lordaeron (Zygor)",
["faction"] = "Alliance", },

{["label"] = "SU  08-02  H  Q-52444  AQ-46931  The War Campaign 01", ["frameID"] = "list1", ["key"] = "custom:q:52746:list1:37",
["questID"] = 52746, ["prereq"] = { 46931, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth  (H2)\n + %n\nWar Campaign (Zygor)\\n   1: Take War Campaign Quest\\n Warband Transfer Resources\\n       Then Port to Orgimmar & Back\\n   2: Get Resources Chests/WBT",
["faction"] = "Horde", },

{["label"] = "SU  08-02  H  Q-52444  AQ-46931  The War Campaign 02", ["frameID"] = "list1", ["key"] = "custom:q:53333:list1:38",
["questID"] = 53333, ["prereq"] = { 46931, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth  (H2)\n + %n\nWar Campaign (Zygor)\\n   3: Return to Ship",
["faction"] = "Horde", },

{["label"] = "SU  08-02  H  Q-52444  AQ-46931  The War Campaign 03", ["frameID"] = "list1", ["key"] = "custom:q:51800:list1:39",
["questID"] = 51800, ["prereq"] = { 46931, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth  (H2)\n + %n\nWar Campaign (Zygor)\\n   4: Start Mission, Skip to 10\\n   Table: Tiragarde",
["faction"] = "Horde", },

{["label"] = "SU  08-02  H  Q-52444  AQ-46931  The War Campaign 04", ["frameID"] = "list1", ["key"] = "custom:q:51438:list1:40",
["questID"] = 51438, ["prereq"] = { 46931, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth  (H2)\n + %n\nWar Campaign (Zygor)\\n   5: Open Tiragarde Sound",
["faction"] = "Horde", },

{["label"] = "SU  08-02  H  Q-52444  AQ-46931  The War Campaign 05", ["frameID"] = "list1", ["key"] = "custom:q:51696:list1:41",
["questID"] = 51696, ["prereq"] = { 46931, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth  (H2)\n + %n\nWar Campaign (Zygor)\\n   6: Stormsong Valley",
["faction"] = "Horde", },

{["label"] = "SU  08-02  H  Q-52444  AQ-46931  The War Campaign 06", ["frameID"] = "list1", ["key"] = "custom:q:51234:list1:42",
["questID"] = 51234, ["prereq"] = { 46931, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth  (H2)\n + %n\nWar Campaign (Zygor)\\n   7: Open Drustvar",
["faction"] = "Horde", },

{["label"] = "SU  08-02  H  Q-52444  AQ-46931  The War Campaign 07", ["frameID"] = "list1", ["key"] = "custom:q:52428:list1:43",
["questID"] = 52428, ["prereq"] = { 46931, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth  (H2)\n + %n\nWar Campaign (Zygor)\\n   8: Complete A Dying World",
["faction"] = "Horde", },

{["label"] = "SU  08-02  H  Q-52444  AQ-46931  The War Campaign 08", ["frameID"] = "list1", ["key"] = "custom:q:52451:list1:44",
["questID"] = 52451, ["prereq"] = { 46931, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth  (H2)\n + %n\nWar Campaign (Zygor)\\n   9: Complete Uniting Zuldazar",
["faction"] = "Horde", },

{["label"] = "SU  08-02  H  Q-52444  AQ-46931  The War Campaign 09", ["frameID"] = "list1", ["key"] = "custom:q:65788:list1:45",
["questID"] = 65788, ["prereq"] = { 52451, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth  (H2)\n + %n\nReturn to Lordaeron (Zygor)",
["faction"] = "Horde", },

{["label"] = "Commander's Signet of Battle\n  - Docks Honorbound Vendor", ["frameID"] = "list1", ["key"] = "custom:item:166559:list1:46",
["hideWhenCompleted"] = false,
["playerLevel"] = 80,
["playerLevelOp"] = ">",
["faction"] = "Horde",
["restedOnly"] = true,
["item"] = { ["hideWhenAcquired"] = true, ["itemID"] = 166559, ["required"] = 1, ["currencyRequired"] = 300, ["currencyID"] = 1716, }, },

{["label"] = "SU  08-03  A  Q-54972  AQ-65669  Nazjatar Portal", ["frameID"] = "list1", ["key"] = "custom:q:54972:list1:48",
["questID"] = 54972, ["prereq"] = { 47189, 52450, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth (A4)\n + Nazjatar (Zygor)\n + Quest Until Accepting\n       \"Essential Empowerment\"\n  + Port to Zuldazar",
["faction"] = "Alliance", },

{["label"] = "SU  08-03  A  Q-56162  AQ-54972  Essential Empowerment", ["frameID"] = "list1", ["key"] = "custom:q:56162:list1:48",
["questID"] = 56162, ["prereq"] = { 54972, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth (A5)\n + Nazjatar (Zygor)\n + Equip Heart for Heart parts\n + Quest Until\n      \"Back Out to Sea\"\n  + Pad/Portals to Nazjatar",
["faction"] = "Alliance", },

{["label"] = "SU  08-03  A  Q-56156  AQ-56162  Nazjatar  Needed For Mechagon", ["frameID"] = "list1", ["key"] = "custom:q:56156:list1:49",
["questID"] = 56156, ["prereq"] = { 56162, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth (A6)\n + Nazjatar (Zygor)\n + Use Red Rider Air Rifle\n + If Helper Kills, Remove Buff\n + If Hand in Not There, DeBuff\n + Quest Until A Tempered Blade\n ",
["faction"] = "Alliance", },

{["label"] = "SU  08-03  A  Q-54992  AQ-56156  Nazjatar  Mechagon", ["frameID"] = "list1", ["key"] = "custom:q:54992:list1:50",
["questID"] = 54992, ["prereq"] = { 56156, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth (A7)\n + Mechagon (Zygor)\n + Quest Until Turning In\n      \"Princely Visit\"",
["faction"] = "Alliance", },

{["label"] = "SU  08-03  N  Q-53448  AQ-51696  Wicker Pup & Taptaf Pet  (or 53473) 01", ["frameID"] = "list1", ["key"] = "custom:q:53448:list1:51",
["questID"] = 53448, ["prereq"] = { 51234, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Wicker Pup (Zygor)", },

{["label"] = "SU  08-03  N  Q-53448  AQ-51696  Wicker Pup & Taptaf Pet  (or 53473) 02", ["frameID"] = "list1", ["key"] = "custom:q:52061:list1:52",
["questID"] = 52061, ["prereq"] = { 53448, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Taptaf (Zygor)", },

{["label"] = "SU  08-03  H  Q-55053  AQ-52451  Nazjatar 01", ["frameID"] = "list1", ["key"] = "custom:q:55053:list1:53",
["questID"] = 55053, ["prereq"] = { 52451, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth\nNazjatar (Zygor)\\n  1: Follow Guide Until\\n       \"A Way Home\"",
["faction"] = "Horde", },

{["label"] = "SU  08-03  H  Q-55053  AQ-52451  Nazjatar 02", ["frameID"] = "list1", ["key"] = "custom:q:55851:list1:54",
["questID"] = 55851, ["prereq"] = { 55053, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth\nNazjatar (Zygor)\\n  2: Port to Zuldazar\\n         Then Silithus\\n         Then Chamber of Heart",
["faction"] = "Horde", },

{["label"] = "SU  08-03  H  Q-55053  AQ-52451  Nazjatar 03", ["frameID"] = "list1", ["key"] = "custom:q:55425:list1:55",
["questID"] = 55425, ["prereq"] = { 55851, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth\nNazjatar (Zygor)\\n  3: Follow Guide Until\\n       \"Dominating the Indomitable\"",
["faction"] = "Horde", },

{["label"] = "SU  08-03  H  Q-55053  AQ-52451  Nazjatar 04", ["frameID"] = "list1", ["key"] = "custom:q:55497:list1:56",
["questID"] = 55497, ["prereq"] = { 55425, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth\nNazjatar (Zygor)\\n  4: Hearth Out\\n         Portal to Silithus/Chamber",
["faction"] = "Horde", },

{["label"] = "SU  08-03  H  Q-55053  AQ-52451  Nazjatar 05", ["frameID"] = "list1", ["key"] = "custom:q:57010:list1:57",
["questID"] = 57010, ["prereq"] = { 55497, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth\nNazjatar (Zygor)\\n  5: Follow Guide Until\\n       \"Back Out to Sea\"",
["faction"] = "Horde", },

{["label"] = "SU  08-03  H  Q-55053  AQ-52451  Nazjatar 06", ["frameID"] = "list1", ["key"] = "custom:q:56161:list1:58",
["questID"] = 56161, ["prereq"] = { 57010, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth\nNazjatar (Zygor)\\n  6: Pad to Silithus\\n        Portal to Zuldazar\\n        Portal to Nazjatar",
["faction"] = "Horde", },

{["label"] = "SU  08-03  H  Q-55053  AQ-52451  Nazjatar 07", ["frameID"] = "list1", ["key"] = "custom:q:55500:list1:59",
["questID"] = 55500, ["prereq"] = { 56161, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth\nNazjatar (Zygor)\\n  7: Follow Guide Until\\n        \"Save a Friend\"",
["faction"] = "Horde", },

{["label"] = "SU  08-03  H  Q-55053  AQ-52451  Nazjatar 08", ["frameID"] = "list1", ["key"] = "custom:q:55652:list1:60",
["questID"] = 55652, ["prereq"] = { 55500, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth\nMechagon (Zygor)\\n    1: Follow Guide Until\\n        \"We Come in Peace...\"",
["faction"] = "Horde", },

{["label"] = "SU  08  N  04  Q-58583  AQ-55652  N'Zoth Invasions 01", ["frameID"] = "list1", ["key"] = "custom:q:58506:list1:61",
["questID"] = 58506, ["prereq"] = { 55500, 56156, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth\nMagnis Plan (Zygor)\\n  + PickUp Missive\\n     A  Dockmasters Office\\n     H  On Ship at Dock\\n  + Follow Guide\\n    - Consoles Unnamed?, Relog", },

{["label"] = "SU  08  N  04  Q-58583  AQ-55652  N'Zoth Invasions 02", ["frameID"] = "list1", ["key"] = "custom:q:56209:list1:62",
["questID"] = 56209, ["prereq"] = { 58506, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth\nMagnis Plan (Zygor)\\n  - Leave Chamber, Fly to Uldum\\n  - Talk Magni, Possibly Skip", },

{["label"] = "SU  08  N  04  Q-58583  AQ-55652  N'Zoth Invasions 03", ["frameID"] = "list1", ["key"] = "custom:q:56376:list1:63",
["questID"] = 56376, ["prereq"] = { 56209, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth\nMagnis Plan (Zygor)\\n ULDUM OPEN\\n  - Do Dailies, Clear Mobs\\n  - Fish Gloop (Black Empire)", },

{["label"] = "SU  08  N  04  Q-58583  AQ-55652  N'Zoth Invasions 04", ["frameID"] = "list1", ["key"] = "custom:q:56377:list1:64",
["questID"] = 56377, ["prereq"] = { 56376, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth\nMagnis Plan (Zygor)\\n ULDUM OPEN\\n  - No Forging Onwad, Out & In\\n  - Return to Chamber of Heart", },

{["label"] = "SU  08  N  04  Q-58583  AQ-55652  N'Zoth Invasions 05", ["frameID"] = "list1", ["key"] = "custom:q:56771:list1:65",
["questID"] = 56771, ["prereq"] = { 56376, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth\nMagnis Plan (Zygor)\\n ULDUM OPEN\\n  - Exit Chamber, Go to Pandaria\\n  - Fish Gloop (Black Empire)\\n  - Return to Chamber of Heart", },

{["label"] = "SU  08  N  04  Q-58583  AQ-55652  N'Zoth Invasions 06", ["frameID"] = "list1", ["key"] = "custom:q:56540:list1:66",
["questID"] = 56540, ["prereq"] = { 56771, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth\nMagnis Plan (Zygor)\\n ULDUM/VALE OPEN\\n  - Do Dailies, Clear Mobs\\n  - Kill Boss\\n  - Fish Gloop (Black Empire)\\n BOTH OPEN", },

{["label"] = "SU  08  N  04  Q-58583  AQ-55652  N'Zoth Invasions 07", ["frameID"] = "list1", ["key"] = "custom:q:57220:list1:67",
["questID"] = 57220, ["prereq"] = { 56540, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Battle For Azeroth\nMagnis Plan (Zygor)\\n ULDUM/VALE OPEN\\n  - Skip if Possible\\n  - Follow Guide", },

{["label"] = "+ Lucky Tortollan Charm\n      Near Azj-Kahet Portal", ["frameID"] = "list1", ["key"] = "custom:item:202046:list1:72",
["hideWhenCompleted"] = false,
["playerLevel"] = 70,
["playerLevelOp"] = ">",
["faction"] = "Horde",
["restedOnly"] = true,
["item"] = { ["hideWhenAcquired"] = true, ["itemID"] = 202046, ["required"] = 1, }, },

{["label"] = "Kul Tiran Archaeology", ["frameID"] = "list1", ["key"] = "custom:spell:list1:97",
["hideWhenCompleted"] = false,
["notSpellKnown"] = 278910,
["locationID"] = 6666666,
["notInGroup"] = false, },

{["label"] = "Kul Tiran Blacksmithing", ["frameID"] = "list1", ["key"] = "custom:spell:list1:98",
["hideWhenCompleted"] = false,
["faction"] = "Alliance",
["notInGroup"] = false,
["notSpellKnown"] = 264448,
["spellKnown"] = 2018,
["locationID"] = 6666666, },

{["label"] = "Kul Tiran Cooking", ["frameID"] = "list1", ["key"] = "custom:spell:list1:99",
["hideWhenCompleted"] = false,
["faction"] = "Alliance",
["notInGroup"] = false,
["notSpellKnown"] = 264646,
["spellKnown"] = 264638,
["locationID"] = 6666666, },

{["label"] = "Kul Tiran Enchanting", ["frameID"] = "list1", ["key"] = "custom:spell:list1:100",
["hideWhenCompleted"] = false,
["faction"] = "Alliance",
["notInGroup"] = false,
["notSpellKnown"] = 264473,
["spellKnown"] = 7411,
["locationID"] = 6666666, },

{["label"] = "Kul Tiran Engineering", ["frameID"] = "list1", ["key"] = "custom:spell:list1:101",
["hideWhenCompleted"] = false,
["faction"] = "Alliance",
["notInGroup"] = false,
["notSpellKnown"] = 264492,
["spellKnown"] = 264483,
["locationID"] = 6666666, },

{["label"] = "Kul Tiran Fishing", ["frameID"] = "list1", ["key"] = "custom:spell:list1:102",
["hideWhenCompleted"] = false,
["faction"] = "Alliance",
["notInGroup"] = false,
["notSpellKnown"] = 271675,
["spellKnown"] = 271660,
["locationID"] = 6666666, },

{["label"] = "Kul Tiran Herbalism", ["frameID"] = "list1", ["key"] = "custom:spell:list1:103",
["hideWhenCompleted"] = false,
["faction"] = "Alliance",
["notInGroup"] = false,
["notSpellKnown"] = 265831,
["spellKnown"] = 265825,
["locationID"] = 6666666, },

{["label"] = "Kul Tiran Leatherworking", ["frameID"] = "list1", ["key"] = "custom:spell:list1:104",
["hideWhenCompleted"] = false,
["faction"] = "Alliance",
["notInGroup"] = false,
["notSpellKnown"] = 264592,
["spellKnown"] = 264583,
["locationID"] = 6666666, },

{["label"] = "Kul Tiran Mining", ["frameID"] = "list1", ["key"] = "custom:spell:list1:105",
["hideWhenCompleted"] = false,
["faction"] = "Alliance",
["notInGroup"] = false,
["notSpellKnown"] = 265851,
["spellKnown"] = 265843,
["locationID"] = 6666666, },

{["label"] = "Kul Tiran Skinning", ["frameID"] = "list1", ["key"] = "custom:spell:list1:106",
["hideWhenCompleted"] = false,
["faction"] = "Alliance",
["notInGroup"] = false,
["notSpellKnown"] = 265869,
["spellKnown"] = 265861,
["locationID"] = 6666666, },

{["label"] = "Kul Tiran Tailoring", ["frameID"] = "list1", ["key"] = "custom:spell:list1:107",
["hideWhenCompleted"] = false,
["faction"] = "Alliance",
["notInGroup"] = false,
["notSpellKnown"] = 264630,
["spellKnown"] = 264622,
["locationID"] = 6666666, },

{["label"] = "Zandalari Archaeology", ["frameID"] = "list1", ["key"] = "custom:spell:list1:108",
["hideWhenCompleted"] = false,
["notInGroup"] = false,
["notSpellKnown"] = 278910,
["locationID"] = 6666666,
["faction"] = "Horde", },

{["label"] = "Zandalari Blacksmithing", ["frameID"] = "list1", ["key"] = "custom:spell:list1:109",
["hideWhenCompleted"] = false,
["faction"] = "Horde",
["notInGroup"] = false,
["notSpellKnown"] = 265803,
["spellKnown"] = 2018,
["locationID"] = 6666666, },

{["label"] = "Zandalari Cooking", ["frameID"] = "list1", ["key"] = "custom:spell:list1:110",
["hideWhenCompleted"] = false,
["faction"] = "Horde",
["notInGroup"] = false,
["notSpellKnown"] = 265817,
["spellKnown"] = 264638,
["locationID"] = 6666666, },

{["label"] = "Zandalari Engineering", ["frameID"] = "list1", ["key"] = "custom:spell:list1:111",
["hideWhenCompleted"] = false,
["faction"] = "Horde",
["notInGroup"] = false,
["notSpellKnown"] = 265807,
["spellKnown"] = 264483,
["locationID"] = 6666666, },

{["label"] = "Zandalari Fishing", ["frameID"] = "list1", ["key"] = "custom:spell:list1:112",
["hideWhenCompleted"] = false,
["faction"] = "Horde",
["notInGroup"] = false,
["notSpellKnown"] = 271677,
["spellKnown"] = 271660,
["locationID"] = 6666666, },

{["label"] = "Zandalari Herbalism", ["frameID"] = "list1", ["key"] = "custom:spell:list1:113",
["hideWhenCompleted"] = false,
["faction"] = "Horde",
["notInGroup"] = false,
["notSpellKnown"] = 265835,
["spellKnown"] = 265825,
["locationID"] = 6666666, },

{["label"] = "Zandalari Leatherworking", ["frameID"] = "list1", ["key"] = "custom:spell:list1:114",
["hideWhenCompleted"] = false,
["faction"] = "Horde",
["notInGroup"] = false,
["notSpellKnown"] = 265813,
["spellKnown"] = 264583,
["locationID"] = 6666666, },

{["label"] = "Zandalari Mining", ["frameID"] = "list1", ["key"] = "custom:spell:list1:115",
["hideWhenCompleted"] = false,
["faction"] = "Horde",
["notInGroup"] = false,
["notSpellKnown"] = 265853,
["spellKnown"] = 265843,
["locationID"] = 6666666, },

{["label"] = "Zandalari Skinning", ["frameID"] = "list1", ["key"] = "custom:spell:list1:116",
["hideWhenCompleted"] = false,
["faction"] = "Horde",
["notInGroup"] = false,
["notSpellKnown"] = 265871,
["spellKnown"] = 265861,
["locationID"] = 6666666, },

{["label"] = "Zandalari Tailoring", ["frameID"] = "list1", ["key"] = "custom:spell:list1:117",
["hideWhenCompleted"] = false,
["faction"] = "Horde",
["notInGroup"] = false,
["notSpellKnown"] = 265815,
["spellKnown"] = 264622,
["locationID"] = 6666666, },

}

for i = 1, #bakedRules do
  local r = bakedRules[i]
  if type(r) == "table" then
    if type(r.key) == "string" then
      r.key = r.key:gsub("^custom:", "db:")
    end
    ns.rules[#ns.rules + 1] = r
  end
end
