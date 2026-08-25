local _, ns = ...

-- Guide (feature)
-- Non-UI helpers used by the Guide tab UI live here.
-- UI is in fUI_QTGuideUI.lua

ns.Guide = ns.Guide or {}
local G = ns.Guide

G.DMF_GROUP = "event:darkmoon-faire"

function G.IsDarkmoonRule(rule)
	if type(rule) ~= "table" then return false end
	return tostring(rule.group or "") == G.DMF_GROUP or tostring(rule.key or "") == G.DMF_GROUP
end

function G.CategoryFilterLabel(v)
	v = tostring(v or "all")
	if v == "all" then return "Any Category" end
	if v == G.DMF_GROUP then return "Darkmoon Faire" end
	return v
end

function G.RuleKey(rule)
	if ns and ns.RuleKey then
		return ns.RuleKey(rule)
	end
	if type(rule) ~= "table" then return nil end
	if rule.key ~= nil then return tostring(rule.key) end
	if rule.questID then
		local qid = tonumber(rule.questID) or rule.questID
		local xy = (rule.questXY ~= nil) and tostring(rule.questXY):upper() or nil
		if xy == "X" or xy == "Y" then
			return "qxy:" .. xy .. ":" .. tostring(qid)
		end
		return "q:" .. tostring(qid)
	end
	if rule.label then return "label:" .. tostring(rule.label) end
	if rule.group then return "group:" .. tostring(rule.group) .. ":" .. tostring(rule.order or 0) end
	return nil
end

function G.GetEffectiveDefaultRule(baseRule, opts)
	opts = (type(opts) == "table") and opts or {}
	local GetDefaultRuleEdits = opts.GetDefaultRuleEdits
	local edits = (type(GetDefaultRuleEdits) == "function") and (GetDefaultRuleEdits() or {}) or {}
	local key = G.RuleKey(baseRule)
	local r2 = key and edits[key] or nil
	return (type(r2) == "table") and r2 or baseRule
end

function G.IsDefaultRuleEdited(baseRule, opts)
	opts = (type(opts) == "table") and opts or {}
	local GetDefaultRuleEdits = opts.GetDefaultRuleEdits
	local edits = (type(GetDefaultRuleEdits) == "function") and (GetDefaultRuleEdits() or {}) or {}
	local key = G.RuleKey(baseRule)
	return (key and type(edits[key]) == "table") and true or false
end

function G.GetSortedFrameIDs(displayByID, opts)
	opts = (type(opts) == "table") and opts or {}
	local GetEffectiveFrames = opts.GetEffectiveFrames

	local ids = {}
	for _, def in ipairs((type(GetEffectiveFrames) == "function" and GetEffectiveFrames()) or {}) do
		if type(def) == "table" and def.id then
			local id = tostring(def.id)
			if id ~= "" then
				ids[#ids + 1] = id
			end
		end
	end
	table.sort(ids, function(a, b)
		local da = (type(displayByID) == "table" and displayByID[a]) or a
		local db = (type(displayByID) == "table" and displayByID[b]) or b
		return tostring(da) < tostring(db)
	end)
	return ids
end

function G.GetPrimaryFrameID(rule)
	if type(rule) ~= "table" then return nil end
	if rule.frameID ~= nil then return tostring(rule.frameID) end
	if type(rule.targets) == "table" and rule.targets[1] ~= nil then
		return tostring(rule.targets[1])
	end
	return nil
end

function G.SetRulePrimaryFrame(baseRule, displayRule, newID, src, opts)
	newID = tostring(newID or "")
	if newID == "" then return end

	opts = (type(opts) == "table") and opts or {}
	local GetEffectiveFrames = opts.GetEffectiveFrames
	local GetDefaultRuleEdits = opts.GetDefaultRuleEdits
	local DeepCopyValue = opts.DeepCopyValue

	-- QuestX/QuestY entries are list-only (cannot target bar frames).
	do
		local xy = (type(displayRule) == "table") and displayRule.questXY or nil
		if xy ~= nil then
			xy = tostring(xy):upper()
			if xy == "X" or xy == "Y" then
				for _, def in ipairs((type(GetEffectiveFrames) == "function" and GetEffectiveFrames()) or {}) do
					if type(def) == "table" and tostring(def.id or "") == newID then
						local t = tostring(def.type or "list"):lower()
						if t == "bar" then
							return
						end
						break
					end
				end
			end
		end
	end

	if src == "default" then
		local key = G.RuleKey(baseRule)
		if not key or key == "" then return end
		local edits = (type(GetDefaultRuleEdits) == "function") and (GetDefaultRuleEdits() or {}) or {}
		local edited = DeepCopyValue and DeepCopyValue(displayRule) or displayRule
		if type(edited) == "table" then
			edited.frameID = newID
			edited.targets = nil
			edits[key] = edited
		end
		return
	end

	if type(baseRule) ~= "table" then return end
	baseRule.frameID = newID
	baseRule.targets = nil
end

function G.FormatRuleText(r, opts)
	opts = (type(opts) == "table") and opts or {}
	local GetItemNameSafe = opts.GetItemNameSafe
	local GetQuestTitle = opts.GetQuestTitle

	local label = (type(r) == "table" and r.label ~= nil) and tostring(r.label) or ""
	label = label:gsub("\n", " "):gsub("^%s+", ""):gsub("%s+$", "")

	local function LevelSuffix(rr)
		if type(rr) ~= "table" then return "" end

		local function NormalizeOp(op)
			return (op == "<" or op == "<=" or op == "=" or op == ">=" or op == ">" or op == "!=") and op or nil
		end

		local op, lvl
		if type(rr.playerLevel) == "table" then
			op = rr.playerLevel[1]
			lvl = tonumber(rr.playerLevel[2])
		else
			op = rr.playerLevelOp
			lvl = tonumber(rr.playerLevel)
		end

		op = NormalizeOp(op)
		if op and lvl and lvl > 0 then
			return string.format(" [Lvl %s %d]", op, lvl)
		end
		return ""
	end

	if type(r) == "table" and type(r.item) == "table" and r.item.itemID then
		local itemID = tonumber(r.item.itemID) or 0
		local base = (label ~= "") and label or ((type(GetItemNameSafe) == "function" and GetItemNameSafe(itemID)) or ("Item " .. tostring(itemID)))
		return string.format("I: %s%s", base, LevelSuffix(r))
	elseif tonumber(r and r.questID) and tonumber(r.questID) > 0 then
		local q = tonumber(r.questID) or 0
		local base = (label ~= "") and label or ((type(GetQuestTitle) == "function" and GetQuestTitle(q)) or ("Quest " .. tostring(q)))
		local xy = (type(r) == "table" and r.questXY ~= nil) and tostring(r.questXY):upper() or nil
		if xy == "X" or xy == "Y" then
			return string.format("%s: %s%s", xy, tostring(base), LevelSuffix(r))
		end
		return string.format("Q: %s%s", tostring(base), LevelSuffix(r))
	elseif type(r) == "table" and (r.spellKnown or r.notSpellKnown or r.mapID or r.class or r.notInGroup) then
		local function PickSpellID(v)
			if type(v) == "table" then
				for _, x in ipairs(v) do
					local n = tonumber(x)
					if n and n > 0 then return n end
				end
				return nil
			end
			local n = tonumber(v)
			return (n and n > 0) and n or nil
		end

		local spellID = PickSpellID(r.spellKnown) or PickSpellID(r.notSpellKnown)
		local name = nil
		if label == "" and spellID then
			local CS = _G and rawget(_G, "C_Spell")
			if CS and CS.GetSpellName then
				local ok, n = pcall(CS.GetSpellName, spellID)
				if ok and type(n) == "string" and n ~= "" then name = n end
			end
			local GSI = _G and rawget(_G, "GetSpellInfo")
			if not name and GSI then
				local ok, n = pcall(GSI, spellID)
				if ok and type(n) == "string" and n ~= "" then name = n end
			end
		end

		local base = (label ~= "") and label or (name or (spellID and ("Spell " .. tostring(spellID)) or "Spell"))
		return string.format("S: %s%s", base, LevelSuffix(r))
	else
		local base = (label ~= "") and label or "Text"
		return string.format("T: %s%s", base, LevelSuffix(r))
	end
end
