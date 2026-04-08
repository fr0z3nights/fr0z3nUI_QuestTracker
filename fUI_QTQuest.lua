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

-- Back-compat exports (main engine and other modules reference these on ns/_G).
ns.GetQuestTitle = Q.GetQuestTitle
ns.IsQuestCompleted = Q.IsQuestCompleted
ns.IsQuestInLog = Q.IsQuestInLog
ns.GetQuestObjectiveProgressText = Q.GetQuestObjectiveProgressText

if _G then
	_G.IsQuestCompleted = Q.IsQuestCompleted
	_G.IsQuestInLog = Q.IsQuestInLog
end
