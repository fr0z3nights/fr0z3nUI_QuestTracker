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
-- Explicit X/Y/K scope sets.
-- These are used to seed real QuestX/Y/Keep rules into ns.rules so they can be
-- enabled/disabled/edited like other DB-seeded rules.
ns.db.xquest.questXY = ns.db.xquest.questXY or { K = {}, X = {}, Y = {} }

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

local function MarkQuestXY(xy, questID)
	xy = tostring(xy or ""):upper():gsub("%s+", "")
	if xy ~= "K" and xy ~= "X" and xy ~= "Y" then return end
	questID = tonumber(questID)
	if not questID or questID <= 0 then return end

	local sets = ns.db.xquest.questXY
	if type(sets) ~= "table" then
		sets = { K = {}, X = {}, Y = {} }
		ns.db.xquest.questXY = sets
	end
	sets[xy] = sets[xy] or {}
	sets[xy][questID] = true
end

function ns.db.xquest.KeepQuest(questID, questName)
	local entry = ns.db.xquest.Quest(questID, questName)
	MarkQuestXY("K", questID)
	return entry
end

function ns.db.xquest.XQuest(questID, questName, opts)
	local entry = ns.db.xquest.Quest(questID, questName)
	MarkQuestXY("X", questID)

	-- XQuest = RESTED-only (by default).
	-- Optional gating (MAP) and override flags can be provided via opts.
	-- Prefer passing opts inline instead of editing entry.__meta manually.
	if type(entry) == "table" then
		entry.__meta = entry.__meta or {}

		local restedOnly = true
		if type(opts) == "table" then
			if opts.locationID ~= nil and tostring(opts.locationID) ~= "" then
				entry.__meta.locationID = tostring(opts.locationID)
			end
			if opts.restedOnly ~= nil then
				restedOnly = (opts.restedOnly == true)
			end
		end
		entry.__meta.restedOnly = restedOnly
	end

	return entry
end

function ns.db.xquest.LQuest(questID, questName, locationID, restedOnly)
	local entry = ns.db.xquest.Quest(questID, questName)
	MarkQuestXY("X", questID)

	-- LQuest = LOCATION-gated XQuest.
	if type(entry) == "table" then
		entry.__meta = entry.__meta or {}
		if locationID ~= nil and tostring(locationID) ~= "" then
			entry.__meta.locationID = tostring(locationID)
		end
		if restedOnly ~= nil then
			entry.__meta.restedOnly = (restedOnly == true)
		end
	end

	return entry
end

function ns.db.xquest.YQuest(questID, questName)
	local entry = ns.db.xquest.Quest(questID, questName)
	MarkQuestXY("Y", questID)
	return entry
end

-- Put mappings here (optional):
local SetZone = ns.db.xquest.SetZone
local KQuest = ns.db.xquest.KeepQuest
local XQuest = ns.db.xquest.XQuest
local LQuest = ns.db.xquest.LQuest
local YQuest = ns.db.xquest.YQuest

-- Examples (copy/paste patterns):
--
-- Keep List (K): protected from /fqt aaq / /fqt aaqs
--   SetZone("Timewalking, 00 Event")
--   KQuest(86556, "04 A Shattered Journey (Level)")
--
-- XQuest (X): auto-abandon candidate (optionally gated by map/resting)
--   SetZone("Stormwind, 00 Event")
--   XQuest(12345, "Some Quest To Auto-Abandon")			-- restedOnly: true to require resting (inn/city)
--   LQuest(12345, "Some Quest To Auto-Abandon", 84)		-- locationID: mapID (number or string)
--																/dump C_Map.GetBestMapForUnit("player")
-- YQuest (Y): auto-accept candidate
--   SetZone("Weekly, 00 Event")
--   YQuest(99999, "Some Auto-Accept Quest")
--
-- Notes:
-- - zone grouping comes from SetZone() and is used by the XRules browser tree.
-- - XQuest is the only mode that uses map/resting gates; Keep/Y are always global.

SetZone("Weekly, Event")
	KQuest(83366, "World Quest Week")                    			--  Weekly		Player MAX		
	KQuest(83347, "Dungeon Week")                     				--	Weekly		Player MAX		
	KQuest(83345, "PvP Week")                    					--	Weekly		Player MAX			
	KQuest(83357, "Battle Pet Week")    							--	Weekly		Warband		

SetZone("Timewalking, Event")
	--	Timewalking	 01  Classic
		KQuest(85947, "01 Classic LVL")                    			--	Weekly		Player LVL			
		KQuest(86731, "01 Classic MAX")                      		--	Weekly		Player MAX		
		KQuest(83285, "01 Classic TKN")                             --	Token		Player			
	--	Timewalking	 02  Outland
		KQuest(85948, "02 Outland LVL")                   		 	--	Weekly		Player LVL			
		KQuest(83363, "02 Outland MAX")                      		--	Weekly		Player MAX		
		KQuest(40168, "02 Outland TKN")                             --	Token		Player			
	--	Timewalking	 03  Wrath
		KQuest(85949, "03 Wrath LVL")                     			--	Weekly		Player LVL				
		KQuest(83365, "03 Wrath MAX")                       		--	Weekly		Player MAX		
		KQuest(40173, "03 Wrath TKN")                              	--	Token		Player			
	--	Timewalking	 04  Cata
		KQuest(86556, "04 Cata LVL")                  				--	Weekly		Player LVL			
		KQuest(83359, "04 Cata MAX")                    			--	Weekly		Player MAX		
		KQuest(40173, "04 Cata TKN")                            	--	Token		Player			
	--	Timewalking	 05  Pandaria
		KQuest(86560, "05 Mists LVL")                   			--	Weekly		Player LVL			
		KQuest(93612, "05 Mists MAX")                     			--	Weekly		Player MAX		
		KQuest(45563, "05 Mists TKN")                             	--	Token		Player			
	--	Timewalking	 06  Draenor
		KQuest(86563, "06 Draenor LVL")                     		--	Weekly		Player LVL			
		KQuest(93613, "06 Draenor MAX")                       		--	Weekly		Player MAX		
		KQuest(55499, "06 Draenor TKN")                             --	Token		Player			
	--	Timewalking	 07  Legion
		KQuest(86564, "07 Legion LVL")                        		--	Weekly		Player LVL			
		KQuest(93614, "07 Legion MAX")                          	--	Weekly		Player MAX		
		KQuest(64710, "07 Legion TKN")                              --	Token		Player			
	--	Timewalking	 08  Battle for Azeroth
		KQuest(88808, "08 Battle LVL")                    			--	Weekly		Player LVL			
		KQuest(93627, "08 Battle MAX")                     			--	Weekly		Player MAX		
		KQuest(89222, "08 Battle TKN A")                            --	Token A		Player			
		KQuest(89223, "08 Battle TKN H")                            --	Token H		Player			
    --	Timewalking	 09  Shadowlands
		KQuest(92647, "09 Shadowlands LVL")							--  Weekly		Player LVL			
		KQuest(93628, "09 Shadowlands MAX")					    	--  Weekly		Player MAX		
		KQuest(92650, "09 Shadowlands TKN")							--  Token A		Player			
    --	Timewalking	 10  Dragonflight
		KQuest(93495, "10 Dragonflight LVL")						--  Weekly		Player LVL			
		KQuest(93497, "10 Dragonflight MAX")					    --  Weekly		Player MAX		
		KQuest(93852, "10 Dragonflight TKN")						--  Token A		Player			

SetZone("Darkmoon Island, Azeroth")
	KQuest(29509, "Cooking Weekly")                  				--	Monthly		Player		Cooking
	KQuest(29511, "Engineering Weekly")                             --	Monthly		Player		Engineering
	KQuest(29513, "Fishing Weekly")                     			--	Monthly		Player		Fishing
	KQuest(29518, "Mining Weekly")                           		--	Monthly		Player		Mining
	KQuest(29520, "Tailoring Weekly")                    			--	Monthly		Player		Tailoring
	KQuest(29433, "Test Your Strength")                             --	Monthly		Player		
	LQuest(29438, "He Shoots, He Scores!", 407)						--  Monthly		Player						/dump C_Map.GetBestMapForUnit("player")

--  12	Midnight

SetZone("Silvermoon City, Quel'Thalas")
	KQuest(94836, "Late Night Training: Week 1 of 3")          		--	Scheduled	Player		
	KQuest(94386, "Void Assaults: Zul'Aman")	           			--	Scheduled	Player		
	KQuest(94385, "Void Assaults: Eversong Woods")	           		--	Scheduled	Player		
	KQuest(93595, "A Call to Delves")			            		--	Scheduled	Player		
	KQuest(93525, "Nulling Nullaeus")			            		--	Scheduled	Player		

--  11	War Within

SetZone("Starting, Khaz Algar")
	KQuest(81930, "The War Within")				            		--	Alliance	Player		
	KQuest(78713, "The War Within")				            		--	Horde		Player		
SetZone("Meta Quests, Khaz Algar")
	KQuest(91093, "More Than Just a Phase")		            		--	Weekly		Player		
	KQuest(87422, "Worldsoul: Undermine World Quests")	            --	Weekly		Player		
	KQuest(86369, "A Sparkling Fortune")							--	Weekly?		Player		
	KQuest(82452, "Worldsoul: World Quests")						--	Weekly		Player		
	KQuest(82679, "Archives: Seeking History")						--	Weekly		Player		
	KQuest(82678, "Archives: The First Disc")						--	Weekly		Player		
	KQuest(80672, "Hand of the Vizier")								--	Weekly		Player		
	KQuest(80670, "Eyes of the Weaver")								--	Weekly		Player		
SetZone("Dungeon, Khaz Algar")
	KQuest(83469, "City of Threads")			            		--				Player		
	KQuest(83465, "Ara-Kara, City of Echoes")	            		--				Player		
	KQuest(83457, "The Stonevault")			            			--				Player		
SetZone("Delves, Khaz Algar")
	KQuest(91026, "Gathering an Upgrade")		    				--				Player		
	KQuest(87419, "Worldsoul: Delves")			    				--				Player		
	KQuest(85666, "Delver's Call: Spiral Weave")		    		--				Player		
	KQuest(85244, "Defeating the Underpin")		    				--				Player		
	KQuest(83771, "Delver's Call: Tak-Rethan Abyss")	    		--				Player		
	KQuest(83500, "Zekvir, Hand of the Harbinger")	    			--				Player		
	KQuest(82746, "Delves: Breaking Through to Loot Stuff")			--	Weekly		Player		
	KQuest(82706, "Delves: Worldwide Research")						--	Weekly		Player		
	KQuest(91009, "Durable Information Storage Container")			--	Weekly		Player		
SetZone("Isle of Dorn, Khaz Algar")
	KQuest(84365, "Something on the Horizon")		    			--  			Player		
SetZone("Hallowfall, Khaz Algar")
	KQuest(83551, "Hallowfall")				    					--				Player		
	KQuest(85005, "A Radiant Call")									--				Player		
	KQuest(91173, "The Flame Burns Eternal")						--				Player		
SetZone("PvP, Khaz Algar")
	KQuest(80184, "Preserving in Battle")							--	Weekly		Player		
	KQuest(80186, "Preserving in War")								--	Weekly		Player		
	KQuest(83345, "A Call to Battle")								--	Weekly		Player		
--	KQuest(89039, "Turbo-Boost: Powerhouse Challenges")				--	Weekly		Player		

--  10	Dragonflight

SetZone("Weekly, Dragon Isles")
	KQuest(78444, "A Worthy Ally: Dream Wardens")	                --				Player		
	KQuest(75665, "A Worthy Ally: Loamm Niffen")	                --				Player		
	KQuest(65435, "The Dragon Isles Awaits")	                    --	Horde		Player		
SetZone("RAID, Dragon Isles")
	KQuest(65762, "Sepulcher (M)")
	KQuest(65763, "Sepulcher (H)")
	KQuest(65764, "Sepulcher (N)")
	KQuest(71018, "Incarnates (N)")
	KQuest(71019, "Incarnates (H)")
	KQuest(71020, "Incarnates (M)")
	KQuest(76083, "Aberrus (N)")
	KQuest(76085, "Aberrus (H)")
	KQuest(76086, "Aberrus (M)")
	KQuest(78600, "Amirdrassil (N)")
	KQuest(78601, "Amirdrassil (H)")
	KQuest(78602, "Amirdrassil (M)")
	KQuest(78421, "The Power of Dreams, Amirdrasil Quest for Head Enchant")

--  07	Legion

SetZone("Dalaran, Broken Isles")
	KQuest(44100, "Proper Introduction")							--	Startup		Player		Priest
SetZone("Pet Battles, Broken Isles")				
	KQuest(47895, "Bert - Gnomeregan")								--	Legion 		Daily		Warband
	KQuest(45083, "Crysa - Barrens")								--	Northern	Daily		Warband
SetZone("RAID, Broken Isles")
	KQuest(44283, "Emerald (N)")
	KQuest(44284, "Emerald (H)")
	KQuest(44285, "Emerald (M)")
	KQuest(45381, "Nighthold (N)")
	KQuest(45382, "Nighthold (H)")
	KQuest(45383, "Nighthold (M)")
	KQuest(47725, "Tomb (N)")
	KQuest(47726, "Tomb (H)")
	KQuest(47727, "Tomb (M)")
	KQuest(49032, "Antorus: Dark (N)")
	KQuest(49075, "Antorus: Dark (H)")
	KQuest(49076, "Antorus: Dark (M)")
	KQuest(49133, "Antorus: Argus (N)")
	KQuest(49134, "Antorus: Argus (H)")
	KQuest(49135, "Antorus: Argus (M)")
	KQuest(58373, "Ny'alotha (N)")
	KQuest(58374, "Ny'alotha (H)")
	KQuest(58375, "Ny'alotha (M)")
	KQuest(64597, "Sanctum (N)")
	KQuest(64598, "Sanctum (H)")
	KQuest(64599, "Sanctum (M)")

--  06	Draenor

SetZone("Frostfire Ridge, Draenor")
	LQuest(38568, "We Need a Shipwright", 590)						--  Monthly		Player	H					/dump C_Map.GetBestMapForUnit("player")
SetZone("Pet Battles, Draenor")
	KQuest(37208, "Taralune, Talador")								--	Talador				Daily		Warband
	KQuest(37207, "Vesharr, Spires")								--	Spires				Daily		Warband
	KQuest(37205, "Gargra, Frostfire")								--	Frostfire			Daily		Warband
	KQuest(37206, "Tarr the Terrible, Nagrand")						--	Nagrand				Daily		Warband
	KQuest(37203, "Ashlei, Shadowmoon")								--	Shadowmoon			Daily		Warband
	KQuest(37201, "Cymre Brightblade, Gorgrond")					--	Gorgrond			Daily		Warband
SetZone("RAID, Draenor")
	KQuest(37029, "Blackrock (N)")
	KQuest(37030, "Blackrock (H)")
	KQuest(37031, "Blackrock (M)")
	KQuest(39499, "Hellfire: Souls (N)")
	KQuest(39500, "Hellfire: Souls (H)")
	KQuest(39501, "Hellfire: Souls (M)")
	KQuest(39502, "Hellfire: Spire (N)")
	KQuest(39504, "Hellfire: Spire (H)")
	KQuest(39505, "Hellfire: Spire (M)")
SetZone("Startup, Draenor")
	LQuest(34398, "Warlords of Draenor: The Dark Portal", 17)		--  Starting		Player		
SetZone("Shadowmoon Valley, Draenor")
	LQuest(37433, "Proving Grounds", 582)							--  Monthly		Player						/dump C_Map.GetBestMapForUnit("player")
	LQuest(38257, "We Need a Shipwright", 582)						--  Monthly		Player	A					/dump C_Map.GetBestMapForUnit("player")
	LQuest(38567, "Garrison Campaign: War Council", 582)			--  Monthly		Player	A					/dump C_Map.GetBestMapForUnit("player")

-- 05	Pandaria

SetZone("Pet Battles, Pandaria")
	KQuest(63435, "")												--					Daily		Warband		
	KQuest(32441, "Thundering Spirit")								--  Kun-Lai Summit	Daily		Warband
	KQuest(32440, "Whispering Spirit")								--	Jade Forest		Daily		Warband
	KQuest(32439, "Flowing Spirit")									--	Dread Wastes	Daily		Warband
	KQuest(32434, "Burning Spirit")									--	Townlong		Daily		Warband
	KQuest(31991, "Seeker Zusshi")									--	Townlong		Daily		Warband
	KQuest(31958, "Aki, The Chosen")								--	Eternal 		Daily		Warband
	KQuest(31957, "Wastewalker Shu")								--	Dread Wastes	Daily		Warband
	KQuest(31956, "Courageous Yon")									--	Kun-Lai Summit	Daily		Warband
	KQuest(31955, "Farmer Nishi")									--	Four Winds		Daily		Warband
	KQuest(31954, "Mo'ruk")		        							--	Karasang		Daily		Warband
	KQuest(31953, "Hyuna")			    							--	Jade Forest		Daily		Warband

SetZone("Unknown, Northrend")
	KQuest(24756, "Blood Infusion")      							--  DK Legendary Quest from WotLK

	

--	01

-- Seed DB-backed X/Y/K rules so they appear in XRules and can be toggled.
do
	ns.rules = ns.rules or {}
	local sets = ns.db and ns.db.xquest and ns.db.xquest.questXY
	local qdb = ns.db and ns.db.xquest and ns.db.xquest.quests
	if type(sets) == "table" then
		local function Seed(xy)
			local t = sets[xy]
			if type(t) ~= "table" then return end
			for questID in pairs(t) do
				local qid = tonumber(questID)
				if qid and qid > 0 then
					local rule = {
						questID = qid,
						questXY = xy,
						-- Keep entries should remain visible even when completed.
						hideWhenCompleted = (xy == "K") and false or true,
					}

					-- Optional XQuest gating (MAP/RESTING) driven from DB meta.
					if xy == "X" and type(qdb) == "table" then
						local entry = qdb[qid]
						local meta = (type(entry) == "table") and entry.__meta or nil
						if type(meta) == "table" then
							if meta.locationID ~= nil and tostring(meta.locationID) ~= "" then
								rule.locationID = tostring(meta.locationID)
							end
							if meta.restedOnly == true then
								rule.restedOnly = true
							end
						end
					end

					ns.rules[#ns.rules + 1] = rule
				end
			end
		end
		Seed("K")
		Seed("X")
		Seed("Y")
	end
end


