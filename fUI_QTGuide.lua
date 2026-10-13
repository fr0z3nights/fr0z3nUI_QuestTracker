local _, ns = ...

-- Guide (feature)
-- Non-UI helpers used by the Guide tab UI live here.
-- UI is in fUI_QTGuideUI.lua

ns.Guide = ns.Guide or {}
local G = ns.Guide

G.DMF_EVENT = "darkmoon-faire"

function G.GetZygorDetails(rule)
	if type(rule) ~= "table" then return nil, nil, nil, nil end
	if type(rule.zygor) == "table" then
		return rule.zygor[1], rule.zygor[2], rule.zygor[3], rule.zygor[4]
	end
	return rule.zygor, rule.zygorTT, rule.zygorX, rule.zygorStep
end

function G.HasZygorLink(rule)
	if type(rule) ~= "table" then return false end
	local guide = G.GetZygorDetails(rule)
	if type(guide) == "string" and guide ~= "" then return true end
	local questID = type(rule.wqID) == "table" and tonumber(rule.wqID[1])
	local mapID = type(rule.wqID) == "table" and tonumber(rule.wqID[2])
	return questID and questID > 0 and mapID and mapID > 0 or false
end

local function NormalizeZygorTitle(zygor, title)
	title = title:gsub("^%s+", ""):gsub("%s+$", "")
	title = title:gsub("^([^\\]+)", function(category)
		return category:lower():gsub("^%l", string.upper)
	end)
	if type(zygor.SanitizeGuideTitle) == "function" then
		title = zygor:SanitizeGuideTitle(title)
	end
	title = title:lower():gsub("%s+", " ")
	title = title:gsub("%s*\\%s*", "\\")
	title = title:gsub("%f[%a]dailies%f[%A]", "daily")
	title = title:gsub("%f[%a]pets%f[%A]", "pet")
	title = title:gsub("%f[%a]mounts%f[%A]", "mount")
	title = title:gsub("%f[%a]quests%f[%A]", "quest")
	return title
end

function G.ResolveZygorGuide(zygor, title)
	local exact = zygor:GetGuideByTitle(title)
	if exact then return exact end
	local normalized = NormalizeZygorTitle(zygor, title)
	local matches = {}
	for _, guide in ipairs(zygor.registeredguides or {}) do
		if type(guide.title) == "string"
			and NormalizeZygorTitle(zygor, guide.title) == normalized then
			matches[#matches + 1] = guide
		end
	end
	if #matches == 1 then
		print("|cff00ccff[FQT]|r Resolved Zygor guide: " .. title .. " -> " .. matches[1].title)
		return matches[1]
	end
	if #matches > 1 then
		local titles = {}
		for _, guide in ipairs(matches) do titles[#titles + 1] = guide.title end
		table.sort(titles)
		print("|cff00ccff[FQT]|r Ambiguous Zygor guide: " .. title .. " -> " .. table.concat(titles, "; "))
	end
	return nil
end

function G.IsZygorBypassEnabled()
	local account = rawget(_G, "fr0z3nUI_QuestTracker_Acc")
	return not (type(account) == "table" and type(account.settings) == "table"
		and account.settings.zygorBypassEligibility == false)
end

function G.InstallZygorBypass()
	local zygor = rawget(_G, "ZGV")
	local guideFuncs = zygor and zygor.GuideFuncs
	if not (guideFuncs and type(guideFuncs.IsValid) == "function") then return false end
	if G._zygorGuideFuncs == guideFuncs then return true end
	local original = guideFuncs.IsValid
	guideFuncs.IsValid = function(self, guide, ...)
		local resolved = type(guide) == "string" and zygor:GetGuideByTitle(guide) or guide
		local approvals = zygor.db and zygor.db.char and zygor.db.char.goodbadguides
		if not G.IsZygorBypassEnabled() or type(resolved) ~= "table"
			or type(resolved.title) ~= "string" or type(approvals) ~= "table" then
			return original(self, guide, ...)
		end
		local previous = approvals[resolved.title]
		approvals[resolved.title] = true
		local ok, result = pcall(original, self, guide, ...)
		approvals[resolved.title] = previous
		if not ok then error(result, 0) end
		return result
	end
	G._zygorGuideFuncs = guideFuncs
	return true
end

function G.LoadZygorGuide(rule)
	if not G.HasZygorLink(rule) then return false end
	local zygor = rawget(_G, "ZGV")
	if not (zygor and zygor.initialized and type(zygor.GetGuideByTitle) == "function"
		and zygor.Tabs and type(zygor.Tabs.LoadGuideToTab) == "function"
		and type(zygor.SetVisible) == "function") then
		print("|cff00ccff[FQT]|r Zygor is not loaded or ready.")
		return false
	end
	G.InstallZygorBypass()
	local guideTitle, _, closeOnTurnIn, guideStep = G.GetZygorDetails(rule)
	local questSteps
	if type(guideStep) == "table" and type(guideStep[2]) == "table" then
		questSteps = {}
		for index = 2, #guideStep do
			local action = guideStep[index]
			local questID = type(action) == "table" and tonumber(action[1])
			local step = type(action) == "table" and tonumber(action[2])
			if not questID or questID <= 0 or questID ~= math.floor(questID)
				or not step or step <= 0 or step ~= math.floor(step) then
				print("|cff00ccff[FQT]|r Invalid Zygor quest-step action: expected { questID, step }.")
				return false
			end
			questSteps[#questSteps + 1] = { questID = questID, step = step }
		end
		guideStep = guideStep[1]
	end
	local ok, result = pcall(function()
		local viewer = zygor.Frame
		if not (viewer and type(viewer.IsShown) == "function" and viewer:IsShown()) then
			zygor:SetVisible(nil, true)
		end
		if type(guideTitle) == "string" and guideTitle ~= "" then
			local guide = G.ResolveZygorGuide(zygor, guideTitle)
			if not guide or guide.missing then
				print("|cff00ccff[FQT]|r Zygor guide unavailable: " .. guideTitle)
				return false
			end
			local zygorStep = guideStep
			if type(zygorStep) == "table" then
				local faction = UnitFactionGroup and UnitFactionGroup("player")
				local factionIndex = faction == "Alliance" and 1 or faction == "Horde" and 2
				zygorStep = factionIndex and zygorStep[factionIndex] or nil
				if not tonumber(zygorStep) then
					print("|cff00ccff[FQT]|r Could not resolve faction-specific Zygor step.")
					return false
				end
			end
			for _, action in ipairs(questSteps or {}) do
				if C_QuestLog.IsQuestFlaggedCompleted(action.questID) then
					zygorStep = action.step
				end
			end
			zygor.Tabs:LoadGuideToTab(guide, tonumber(zygorStep))
			G._zygorCloseQuest = nil
			local questID = tonumber(rule.questID)
			if (closeOnTurnIn == 1 and questID and questID > 0) or questSteps then
				G._zygorCloseQuest = {
					questID = closeOnTurnIn == 1 and questID or nil,
					title = guide.title,
					questSteps = questSteps,
				}
			end
		else
			local worldQuests = zygor.WorldQuests
			local questID, mapID = tonumber(rule.wqID[1]), tonumber(rule.wqID[2])
			if not (worldQuests and type(worldQuests.SuggestWorldQuestGuide) == "function")
				or not worldQuests:SuggestWorldQuestGuide(nil, questID, true, mapID) then
				print("|cff00ccff[FQT]|r Zygor world quest guide unavailable for quest " .. tostring(questID))
				return false
			end
			G._zygorCloseQuest = nil
			if closeOnTurnIn == 1 then
				local guide = worldQuests.Guides and worldQuests.Guides[mapID]
				if not (guide and type(guide.title) == "string") then
					print("|cff00ccff[FQT]|r Could not track Zygor world quest closure: resolved guide unavailable.")
					return false
				end
				G._zygorCloseQuest = { questID = questID, title = guide.title }
			end
		end
		return true
	end)
	if not ok then
		print("|cff00ccff[FQT]|r Could not load Zygor guide: " .. tostring(result))
	end
	return ok and result == true
end

do
	local listener = CreateFrame("Frame")
	listener:RegisterEvent("ADDON_LOADED")
	listener:RegisterEvent("PLAYER_LOGIN")
	listener:RegisterEvent("QUEST_TURNED_IN")
	listener:RegisterEvent("PLAYER_REGEN_ENABLED")
	local elapsedTotal = 0
	local function TryInstall()
		if G.InstallZygorBypass() then
			listener:SetScript("OnUpdate", nil)
		elseif rawget(_G, "ZGV") then
			listener:SetScript("OnUpdate", function(_, elapsed)
				elapsedTotal = elapsedTotal + elapsed
				if elapsedTotal < 1 then return end
				elapsedTotal = 0
				TryInstall()
			end)
		end
	end
	local function UpdatePendingTab(pending, close, step)
		local zygor = rawget(_G, "ZGV")
		if zygor then
			local pool = zygor.Tabs and zygor.Tabs.Pool
			if type(pool) ~= "table" then
				print("|cff00ccff[FQT]|r Could not update completed Zygor guide: tab list unavailable.")
				return
			end
			for _, tab in ipairs(pool) do
				if tab.title == pending.title then
					local ok, err = pcall(function()
						if close then
							tab:RemoveTab()
						else
							tab:AssignGuide(pending.title, step, false, "guidechange")
							if tab.isActive then tab:ActivateGuide() end
						end
					end)
					if not ok then
						print("|cff00ccff[FQT]|r Could not update completed Zygor guide: " .. tostring(err))
					end
					return
				end
			end
		end
	end
	listener:SetScript("OnEvent", function(_, event, questID)
		if event == "PLAYER_REGEN_ENABLED" then
			local pending = G._zygorCloseQuest
			if pending and pending.closeReady and not InCombatLockdown() then
				G._zygorCloseQuest = nil
				UpdatePendingTab(pending, true)
			end
			return
		end
		if event ~= "QUEST_TURNED_IN" then
			TryInstall()
			return
		end
		local pending = G._zygorCloseQuest
		if not pending then return end
		questID = tonumber(questID)
		local close = pending.questID == questID
		local step
		if close then
			if InCombatLockdown() then
				pending.closeReady = true
				return
			end
			G._zygorCloseQuest = nil
		else
			if pending.closeReady then return end
			for _, action in ipairs(pending.questSteps or {}) do
				if action.questID == questID then step = action.step end
			end
			if not step then return end
		end
		UpdatePendingTab(pending, close, step)
	end)
	TryInstall()
	SLASH_FQTZYGOR1 = "/fqtzygor"
	SlashCmdList.FQTZYGOR = function(message)
		local action = tostring(message or ""):lower():match("^%s*bypass%s+(%a+)%s*$")
		if action ~= "on" and action ~= "off" then
			print("|cff00ccff[FQT]|r /fqtzygor bypass on|off (currently "
				.. (G.IsZygorBypassEnabled() and "ON" or "OFF") .. ")")
			return
		end
		local account = rawget(_G, "fr0z3nUI_QuestTracker_Acc")
		if type(account) ~= "table" then return end
		account.settings = account.settings or {}
		account.settings.zygorBypassEligibility = action == "on"
		TryInstall()
		print("|cff00ccff[FQT]|r Zygor eligibility bypass: " .. action:upper())
	end
end

function G.IsDarkmoonRule(rule)
	if type(rule) ~= "table" then return false end
	return tostring(rule.event or "") == G.DMF_EVENT or tostring(rule.key or "") == "event:" .. G.DMF_EVENT
end

function G.CategoryFilterLabel(v)
	v = tostring(v or "all")
	if v == "all" then return "Any Category" end
	if v == G.DMF_EVENT then return "Darkmoon Faire" end
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
	if rule.event then return "event:" .. tostring(rule.event) .. ":" .. tostring(rule.order or 0) end
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
