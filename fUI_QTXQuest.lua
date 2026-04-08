local _, ns = ...

-- XQuest (feature)
-- Non-UI helpers used by the XQuest tab UI live here.
-- UI is in fUI_QTXQuestUI.lua

ns.XQuest = ns.XQuest or {}
local XQ = ns.XQuest

function XQ.NormalizeQuestXY(v)
	v = tostring(v or ""):upper():gsub("%s+", "")
	if v == "QUESTX" then v = "X" end
	if v == "QUESTY" then v = "Y" end
	if v == "X" or v == "Y" or v == "K" then
		return v
	end
	return nil
end

function XQ.BuildQuestIDSet(rules, xy)
	xy = XQ.NormalizeQuestXY(xy)
	if not xy then return {} end
	if type(rules) ~= "table" then return {} end

	local out = {}
	for _, rule in ipairs(rules) do
		if type(rule) == "table" and XQ.NormalizeQuestXY(rule.questXY) == xy then
			local qid = tonumber(rule.questID)
			if qid and qid > 0 then
				out[qid] = true
			end
		end
	end
	return out
end

function XQ.BuildKeepSet(rules)
	return XQ.BuildQuestIDSet(rules, "K")
end

function XQ.GetQuestTitleSafe(qid)
	qid = tonumber(qid)
	if not qid or qid <= 0 then return nil end
	if C_QuestLog and C_QuestLog.GetTitleForQuestID then
		local ok, title = pcall(C_QuestLog.GetTitleForQuestID, qid)
		if ok and type(title) == "string" and title ~= "" then
			return title
		end
	end
	return nil
end

function XQ.GetCurrentMapIDSafe()
	if C_Map and C_Map.GetBestMapForUnit then
		local ok, id = pcall(C_Map.GetBestMapForUnit, "player")
		if ok and type(id) == "number" and id > 0 then
			return id
		end
	end
	return nil
end

function XQ.NormalizeScopeMode(v)
	v = tostring(v or ""):upper():gsub("%s+", "")
	if v ~= "MAP" and v ~= "RESTING" then
		v = "RESTING"
	end
	return v
end
