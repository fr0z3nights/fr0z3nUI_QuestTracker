local addonName, ns = ...

-- Single DB file used by XRules.
--
-- Keep it simple:
--   A) XQuest zone grouping metadata (drives Continent -> Zone tree in XRules)

-- ============================================================================
-- A) XQuest zone grouping metadata (used by XRules)
-- ============================================================================

ns.db = ns.db or {}
ns.db.xquest = ns.db.xquest or {}
ns.db.xquest.quests = ns.db.xquest.quests or {}

local CURRENT_ZONE = nil

function ns.db.xquest.SetZone(zone)
  CURRENT_ZONE = tostring(zone or "")
end

function ns.db.xquest.Quest(questID, questName)
  questID = tonumber(questID)
  if not questID or questID <= 0 then
    return nil
  end

  local t = ns.db.xquest.quests
  t[questID] = t[questID] or {}
  t[questID].__meta = t[questID].__meta or {}

  if CURRENT_ZONE and CURRENT_ZONE ~= "" then
    t[questID].__meta.zone = t[questID].__meta.zone or CURRENT_ZONE
  end

  if questName and questName ~= "" then
    t[questID].__meta.name = t[questID].__meta.name or tostring(questName)
  end

  return t[questID]
end

-- Put mappings here (optional):
local SetZone = ns.db.xquest.SetZone
local Quest = ns.db.xquest.Quest

SetZone("Weekly, 00 Event")
	Quest(83366, "The World Awaits")                    --  WQuests     Weekly		Player MAX		
	Quest(83347, "Emissary of War")                     --	Dungeon		Weekly		Player MAX		
	Quest(83345, "A Call to Battle")                    --	PvP			Weekly		Player MAX			

SetZone("Timewalking, 00 Event")
	--	Timewalking	 01  Classic
	Quest(85947, "01 A Classic Journey (Level)")                    --	Weekly		Player LVL			
	Quest(86731, "01 A Classic Path	   (Max)")                      --	Weekly		Player MAX		
	Quest(83285, "01 A Classic Token")                              --	Token		Player			
	--	Timewalking	 02  Outland
	Quest(85948, "02 A Burning Journey (Level)")                    --	Weekly		Player LVL			
	Quest(83363, "02 A Burning Path	   (Max)")                      --	Weekly		Player MAX		
	Quest(40168, "02 A Burning Token")                              --	Token		Player			
	--	Timewalking	 03  Wrath
	Quest(85949, "03 A Frozen Journey (Level)")                     --	Weekly		Player LVL				
	Quest(83365, "03 A Frozen Path	  (Max)")                       --	Weekly		Player MAX		
	Quest(40173, "03 A Frozen Token")                               --	Token		Player			
	--	Timewalking	 04  Cata
	Quest(86556, "04 A Shattered Journey (Level)")                  --	Weekly		Player LVL			
	Quest(83359, "04 A Shattered Path	 (Max)")                    --	Weekly		Player MAX		
	Quest(40173, "04 A Shattered Token")                            --	Token		Player			
	--	Timewalking	 05  Pandaria
	Quest(86560, "05 A Shadowed Journey (Level)")                   --	Weekly		Player LVL			
	Quest(83362, "05 A Shadowed Path	(Max)")                     --	Weekly		Player MAX		
	Quest(45563, "05 A Shadowed Token")                             --	Token		Player			
	--	Timewalking	 06  Draenor
	Quest(86563, "06 A Savage Journey (Level)")                     --	Weekly		Player LVL			
	Quest(83364, "06 A Savage Path    (Max)")                       --	Weekly		Player MAX		
	Quest(55499, "06 A Savage Token")                               --	Token		Player			
	--	Timewalking	 07  Legion
	Quest(86564, "07 A Fel Journey (Level)")                        --	Weekly		Player LVL			
	Quest(83364, "07 A Fel Path	   (Max)")                          --	Weekly		Player MAX		
	Quest(64710, "07 A Fel Token")                                  --	Token		Player			
	--	Timewalking	 08  Battle for Azeroth
	Quest(88808, "08 A Scarred Journey (Level)")                    --	Weekly		Player LVL			
	Quest(88805, "08 A Scarred Path	   (Max)")                      --	Weekly		Player MAX		
	Quest(89222, "08 A Scarred Token A")                            --	Token A		Player			
	Quest(89223, "08 A Scarred Token H")                            --	Token H		Player			
    --	Timewalking	 09  Shadowlands
--	Quest(88808, "09 A Scarred Journey (Level)")					--  Weekly		Player LVL			
--	Quest(88805, "09 A Scarred Path (Max)")						    --  Weekly		Player MAX		
--	Quest(89222, "09 A SL TW Token")								--  Token A		Player			
SetZone("Darkmoon Faire, 00 Event")
	Quest(29509, "Putting the Crunch in the Frog")                  --	Monthly		Player		Cooking
	Quest(29511, "Talkin' Tonks")                                   --	Monthly		Player		Engineering
	Quest(29513, "Spoilin' for Salty Sea Dogs")                     --	Monthly		Player		Fishing
	Quest(29518, "Rearm, Reuse, Recycle")                           --	Monthly		Player		Mining
	Quest(29520, "Banners, Banners Everywhere!")                    --	Monthly		Player		Tailoring
	Quest(29433, "Test Your Strength")                              --	Monthly		Player		

--  12	Midnight

SetZone("Starting, 00 Midnight")

--  11	War Within

SetZone("Starting, 11 Khaz Algar")
	Quest(81930, "The War Within")						            --	Alliance	Player		
	Quest(78713, "The War Within")						            --	Horde		Player		
SetZone("Meta Quests, 11 Khaz Algar")
	Quest(91093, "More Than Just a Phase")				            --	Weekly		Player		
	Quest(87422, "Worldsoul: Undermine World Quests")	            --	Weekly		Player		
	Quest(86369, "A Sparkling Fortune")								--	Weekly?		Player		
	Quest(82452, "Worldsoul: World Quests")							--	Weekly		Player		
	Quest(82679, "Archives: Seeking History")						--	Weekly		Player		
	Quest(82678, "Archives: The First Disc")						--	Weekly		Player		
	Quest(80672, "Hand of th Vizier")								--	Weekly		Player		
	Quest(80670, "Eyes of the Weaver")								--	Weekly		Player		
SetZone("Dungeon, 11 Khaz Algar")
	Quest(83469, "City of Threads")						            --				Player		
	Quest(83465, "Ara-Kara, City of Echoes")			            --				Player		
	Quest(83457, "The Stonevault")						            --				Player		
SetZone("Delves, 11 Khaz Algar")
	Quest(91026, "Gathering an Upgrade")						    --				Player		
	Quest(87419, "Worldsoul: Delves")							    --				Player		
	Quest(85666, "Delver's Call: Spiral Weave")					    --				Player		
	Quest(85244, "Defeating the Underpin")						    --				Player		
	Quest(83771, "Delver's Call: Tak-Rethan Abyss")				    --				Player		
	Quest(83500, "Zekvir, Hand of the Harbinger")				    --				Player		
	Quest(82746, "Delves: Breaking Through to Loot Stuff")			--	Weekly		Player		
	Quest(82706, "Delves: Worldwide Research")						--	Weekly		Player		
	Quest(91009, "Durable Information Storage Container")			--	Weekly		Player		
SetZone("Isle of Dorn, 11 Khaz Algar")
	Quest(84365, "Something on the Horizon")					    --  			Player		
SetZone("Hallowfall, 11 Khaz Algar")
	Quest(83551, "Hallowfall")									    --				Player		
	Quest(85005, "A Radiant Call")									--				Player		
	Quest(91173, "The Flame Burns Eternal")							--				Player		
SetZone("PvP, 11 Khaz Algar")
	Quest(80184, "Preserving in Battle")							--	Weekly		Player		
	Quest(80186, "Preserving in War")								--	Weekly		Player		
	Quest(83345, "A Call to Battle")								--	Weekly		Player		
--  SetZone("RAID, 11 Khaz Algar")
--	Quest(89039, "Turbo-Boost: Powerhouse Challenges")				--	Weekly		Player		

--  10	Dragonflight

SetZone("Unknown, 10 Dragon Isles")
	Quest(78444, "A Worthy Ally: Dream Wardens")	                --				Player		
	Quest(75665, "A Worthy Ally: Loamm Niffen")	                    --				Player		
	Quest(65435, "The Dragon Isles Awaits")	                        --	Horde		Player		
SetZone("RAID, 10 Dragon Isles")
	Quest(65762, "Sepulcher (M)")
	Quest(65763, "Sepulcher (H)")
	Quest(65764, "Sepulcher (N)")
	Quest(71018, "Incarnates (N)")
	Quest(71019, "Incarnates (H)")
	Quest(71020, "Incarnates (M)")
	Quest(76083, "Aberrus (N)")
	Quest(76085, "Aberrus (H)")
	Quest(76086, "Aberrus (M)")
	Quest(78600, "Amirdrassil (N)")
	Quest(78601, "Amirdrassil (H)")
	Quest(78602, "Amirdrassil (M)")

--  07	Legion

SetZone("Dalaran, 07 Broken Isles")
	Quest(44100, "Proper Introduction")						--		Startup		Player		Priest
SetZone("Pet Battles, 07 Broken Isles")			--	Pet Battles
	Quest(47895, "Bert - Gnomeregan")				--	Legion Mailemental	Daily		Warband
	Quest(45083, "Crysa - Barrens")				--	Northern Barrens	Daily		Warband
SetZone("RAID, 07 Broken Isles")
	Quest(44283, "Emerald (N)")
	Quest(44284, "Emerald (H)")
	Quest(44285, "Emerald (M)")
	Quest(45381, "Nighthold (N)")
	Quest(45382, "Nighthold (H)")
	Quest(45383, "Nighthold (M)")
	Quest(47725, "Tomb (N)")
	Quest(47726, "Tomb (H)")
	Quest(47727, "Tomb (M)")
	Quest(49032, "Antorus: Dark (N)")
	Quest(49075, "Antorus: Dark (H)")
	Quest(49076, "Antorus: Dark (M)")
	Quest(49133, "Antorus: Argus (N)")
	Quest(49134, "Antorus: Argus (H)")
	Quest(49135, "Antorus: Argus (M)")
	Quest(58373, "Ny'alotha (N)")
	Quest(58374, "Ny'alotha (H)")
	Quest(58375, "Ny'alotha (M)")
	Quest(64597, "Sanctum (N)")
	Quest(64598, "Sanctum (H)")
	Quest(64599, "Sanctum (M)")

--  06	Draenor

SetZone("Pet Battles, 06 Draenor")			--	Pet Battles
    Quest(37208, "Taralune")			--	Talador				Daily		Warband
    Quest(37207, "Vesharr")				--	Spires				Daily		Warband
    Quest(37206, "Tarr the Terrible")	--	Nagrand				Daily		Warband
    Quest(37205, "Gargra")				--	Frostfire			Daily		Warband
    Quest(37203, "Ashlei")				--	Shadowmoon			Daily		Warband
    Quest(37201, "Cymre Brightblade")	--	Gorgrond			Daily		Warband
SetZone("RAID, 06 Draenor")
	Quest(37029, "Blackrock (N)")
	Quest(37030, "Blackrock (H)")
	Quest(37031, "Blackrock (M)")
	Quest(39499, "Hellfire: Souls (N)")
	Quest(39500, "Hellfire: Souls (H)")
	Quest(39501, "Hellfire: Souls (M)")
	Quest(39502, "Hellfire: Spire (N)")
	Quest(39504, "Hellfire: Spire (H)")
	Quest(39505, "Hellfire: Spire (M)")

-- 05	Pandaria

SetZone("Pet Battles, 05 Pandaria")
    Quest(63435, "")	--										Daily		Warband		
    Quest(32441, "Thundering Spirit")	--  Kun-Lai Summit		Daily		Warband
    Quest(32440, "Whispering Spirit")	--	The Jade Forest		Daily		Warband
    Quest(32439, "Flowing Spirit")		--	Dread Wastes		Daily		Warband
    Quest(32434, "Burning Spirit")		--	Townlong Steppes	Daily		Warband
    Quest(31991, "Seeker Zusshi")		--	Townlong Steppes	Daily		Warband
    Quest(31958, "Aki, The Chosen")		--	Eternal Blossoms	Daily		Warband
    Quest(31957, "Wastewalker Shu")		--	Dread Wastes		Daily		Warband
    Quest(31956, "Courageous Yon")		--	Kun-Lai Summit		Daily		Warband
    Quest(31955, "Farmer Nishi")		--	Valley Four Winds	Daily		Warband
    Quest(31954, "Mo'ruk")		        --	Karasang			Daily		Warband
    Quest(31953, "Hyuna")			    --	The Jade Forest		Daily		Warband
--  SetZone("Event, Pet Battles")		--	Pet Battles
    --	Quest(83357, "The Vey Best")    --	Pet PvP		        Weekly		Warband		


    Quest(24756, "Blood Infusion")      --  DK Legendary Quest from WotLK


	Quest(78421, "The Power of Dreams, Amirdrasil Quest for Head Enchant")


