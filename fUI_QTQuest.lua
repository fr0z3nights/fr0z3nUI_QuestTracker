local _, ns = ...

-- Quest (feature)
-- UI is in fUI_QTQuestUI.lua

ns.Quest = ns.Quest or {}
local Q = ns.Quest

function Q.ResolveExpansionNameByID(choices, id)
	id = tonumber(id)
	if not id then return nil end
	choices = (type(choices) == "table") and choices or {}
	for _, e in ipairs(choices) do
		if type(e) == "table" and tonumber(e.id) == id and type(e.name) == "string" and e.name ~= "" then
			return e.name
		end
	end
	return nil
end

function Q.NormalizeFontKey(key)
	key = tostring(key or "inherit")
	if key == "" then key = "inherit" end
	return key
end

function Q.ResolveQuestColor(name)
	if name == "None" then
		return nil, "None"
	elseif name == "Green" then
		return { 0.1, 1.0, 0.1 }, "Green"
	elseif name == "Blue" then
		return { 0.2, 0.6, 1.0 }, "Blue"
	elseif name == "Yellow" then
		return { 1.0, 0.9, 0.2 }, "Yellow"
	elseif name == "Red" then
		return { 1.0, 0.2, 0.2 }, "Red"
	elseif name == "Cyan" then
		return { 0.2, 1.0, 1.0 }, "Cyan"
	end
	return nil, "None"
end

function Q.GetQuestTitle(questID)
	questID = tonumber(questID)
	if not questID or questID <= 0 then return nil end
	if C_QuestLog and C_QuestLog.GetTitleForQuestID then
		local ok, title = pcall(C_QuestLog.GetTitleForQuestID, questID)
		if ok and type(title) == "string" and title ~= "" then
			return title
		end
	end
	return nil
end

function Q.IsQuestCompleted(questID)
	questID = tonumber(questID)
	if not questID or questID <= 0 then return false end
	if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
		local ok, done = pcall(C_QuestLog.IsQuestFlaggedCompleted, questID)
		return (ok and done) and true or false
	end
	return false
end

function Q.IsQuestInLog(questID)
	questID = tonumber(questID)
	if not questID or questID <= 0 then return false end

	if C_QuestLog then
		if C_QuestLog.IsOnQuest then
			local ok, onQuest = pcall(C_QuestLog.IsOnQuest, questID)
			if ok and onQuest then return true end
		end
		if C_QuestLog.GetLogIndexForQuestID then
			local ok, idx = pcall(C_QuestLog.GetLogIndexForQuestID, questID)
			if ok then
				return (type(idx) == "number" and idx > 0) and true or false
			end
		end
	end

	return false
end

-- scope: "char"/"character" requires the current character earned it (wasEarnedByMe); anything else ("acc"/"account"/nil) just checks account-wide completed.
function Q.IsAchievementCompleted(achievementID, scope)
	achievementID = tonumber(achievementID)
	if not achievementID or achievementID <= 0 then return false end
	if type(GetAchievementInfo) ~= "function" then return false end

	local ok, _, _, _, completed, _, _, _, _, _, _, _, _, wasEarnedByMe = pcall(GetAchievementInfo, achievementID)
	if not ok then return false end

	local want = tostring(scope or "acc"):lower()
	if want == "char" or want == "character" then
		return (completed == true) and (wasEarnedByMe == true)
	end
	return completed == true
end

-- 12.1 removed C_TaskQuest.GetQuestsForPlayerByMapID; IsActive is the supported global check.
-- mapID is accepted for future use but not used to gate: POI-pin cross-checks proved unreliable
-- (some zones' world quest pins aren't enumerated by C_AreaPoiInfo), causing false "not active" hides.
function Q.IsWorldQuestActive(questID, mapID)
	questID = tonumber(questID)
	if not questID or questID <= 0 then return false end

	if C_TaskQuest and type(C_TaskQuest.IsActive) == "function" then
		local ok, isActive = pcall(C_TaskQuest.IsActive, questID)
		return (ok and isActive) and true or false
	end

	return false
end

-- Reward money data is only cached client-side once the quest has been previewed (map click or IsActive poll);
-- RequestPreloadRewardData warms that cache. Different client versions expose the money getter under different names.
function Q.GetWorldQuestGoldReward(questID)
	questID = tonumber(questID)
	if not questID or questID <= 0 then return nil end

	if C_TaskQuest and type(C_TaskQuest.RequestPreloadRewardData) == "function" then
		pcall(C_TaskQuest.RequestPreloadRewardData, questID)
	end

	-- The money getters return 0 both for "no money reward" and "not cached yet", so the
	-- cache flag is the only way to tell a confirmed 0 from unresolved data.
	local haveData = false
	if type(HaveQuestRewardData) == "function" then
		local ok, have = pcall(HaveQuestRewardData, questID)
		haveData = (ok and have) and true or false
	end

	local copper
	if C_QuestLog and type(C_QuestLog.GetQuestLogRewardMoney) == "function" then
		local ok, amount = pcall(C_QuestLog.GetQuestLogRewardMoney, questID)
		if ok and type(amount) == "number" and amount > 0 then copper = amount end
	end
	if not copper and type(GetQuestLogRewardMoney) == "function" then
		local ok, amount = pcall(GetQuestLogRewardMoney, questID)
		if ok and type(amount) == "number" and amount > 0 then copper = amount end
	end
	if not copper and type(GetQuestRewardMoney) == "function" then
		local ok, amount = pcall(GetQuestRewardMoney, questID)
		if ok and type(amount) == "number" and amount > 0 then copper = amount end
	end

	if not copper then
		return haveData and 0 or nil
	end
	return copper / 10000
end

function Q.GetQuestObjectiveProgressText(questID, objectiveIndex, opts)
	if not (C_QuestLog and C_QuestLog.GetQuestObjectives) then return nil end
	questID = tonumber(questID)
	if not questID or questID <= 0 then return nil end

	local allowCompletedFallback = (type(opts) == "table" and opts.allowCompletedFallback == true) or false
	local inLog = Q.IsQuestInLog(questID)
	if not inLog then
		if allowCompletedFallback and Q.IsQuestCompleted(questID) then
			return "X"
		end
		return nil
	end

	local idx = tonumber(objectiveIndex) or 1
	local objectives = nil
	do
		local ok, res = pcall(C_QuestLog.GetQuestObjectives, questID)
		if ok then
			objectives = res
		end
	end
	local obj = objectives and objectives[idx]
	local fulfilled = obj and tonumber(obj.numFulfilled)
	local required = obj and tonumber(obj.numRequired)
	if fulfilled and required then
		return string.format("%d/%d", fulfilled, required)
	end

	if allowCompletedFallback and Q.IsQuestCompleted(questID) then
		return "X"
	end
	return nil
end

-- A full refresh evaluates every rule and re-queries the same quest IDs many times over
-- (prereq lists, hideQID, hideIfAnyQuestInLog, quest groups). Quest state cannot change
-- within a single frame, so memoize these lookups and drop the cache when the frame changes.
do
	local cacheCompleted, cacheInLog, cacheTitle = {}, {}, {}
	local cacheWQActive, cacheWQGold = {}, {}
	local cacheStamp = nil

	local function Clear(t)
		if type(wipe) == "function" then
			wipe(t)
			return
		end
		for k in pairs(t) do t[k] = nil end
	end

	function Q.InvalidateQuestStateCache()
		cacheStamp = nil
		Clear(cacheCompleted)
		Clear(cacheInLog)
		Clear(cacheTitle)
		Clear(cacheWQActive)
		Clear(cacheWQGold)
	end

	-- GetTime() is constant for the whole frame, so it doubles as the cache generation.
	local function EnsureCurrentFrame()
		local now = (type(GetTime) == "function") and GetTime() or nil
		if now == nil then
			Q.InvalidateQuestStateCache()
			return
		end
		if now ~= cacheStamp then
			Q.InvalidateQuestStateCache()
			cacheStamp = now
		end
	end

	local function MemoizeBool(cache, raw)
		return function(questID, ...)
			local id = tonumber(questID)
			if not id or id <= 0 then return raw(questID, ...) end
			EnsureCurrentFrame()
			local cached = cache[id]
			if cached == nil then
				cached = raw(id, ...) and true or false
				cache[id] = cached
			end
			return cached
		end
	end

	local function MemoizeValue(cache, raw)
		return function(questID, ...)
			local id = tonumber(questID)
			if not id or id <= 0 then return raw(questID, ...) end
			EnsureCurrentFrame()
			local cached = cache[id]
			if cached ~= nil then
				-- `false` is the stored placeholder for "no value".
				if cached == false then return nil end
				return cached
			end
			local value = raw(id, ...)
			cache[id] = (value == nil) and false or value
			return value
		end
	end

	Q.IsQuestCompleted = MemoizeBool(cacheCompleted, Q.IsQuestCompleted)
	Q.IsQuestInLog = MemoizeBool(cacheInLog, Q.IsQuestInLog)
	Q.IsWorldQuestActive = MemoizeBool(cacheWQActive, Q.IsWorldQuestActive)
	Q.GetQuestTitle = MemoizeValue(cacheTitle, Q.GetQuestTitle)
	Q.GetWorldQuestGoldReward = MemoizeValue(cacheWQGold, Q.GetWorldQuestGoldReward)
end

-- Back-compat exports (main engine and other modules reference these on ns/_G).
ns.GetQuestTitle = Q.GetQuestTitle
ns.IsQuestCompleted = Q.IsQuestCompleted
ns.IsQuestInLog = Q.IsQuestInLog
ns.IsWorldQuestActive = Q.IsWorldQuestActive
ns.GetWorldQuestGoldReward = Q.GetWorldQuestGoldReward
ns.GetQuestObjectiveProgressText = Q.GetQuestObjectiveProgressText
ns.IsAchievementCompleted = Q.IsAchievementCompleted
ns.InvalidateQuestStateCache = Q.InvalidateQuestStateCache

if _G then
	_G.IsQuestCompleted = Q.IsQuestCompleted
	_G.IsQuestInLog = Q.IsQuestInLog
end
