local _, ns = ...

-- Items (feature)
-- UI is in fUI_QTItemUI.lua

ns.Items = ns.Items or {}
local I = ns.Items

function I.ResolveExpansionNameByID(choices, id)
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

function I.EnsureAutoBuyDebugSetting()
	local acc = rawget(_G, "fr0z3nUI_QuestTracker_Acc")
	if type(acc) ~= "table" then
		_G.fr0z3nUI_QuestTracker_Acc = { settings = {} }
		acc = _G.fr0z3nUI_QuestTracker_Acc
	end
	if type(acc.settings) ~= "table" then
		acc.settings = {}
	end
	if acc.settings.debugAutoBuy == nil then
		acc.settings.debugAutoBuy = false
	end
	acc.settings.debugAutoBuy = (acc.settings.debugAutoBuy == true)
	return acc.settings
end

function I.GetAutoBuyDebugEnabled()
	local s = I.EnsureAutoBuyDebugSetting()
	return s and s.debugAutoBuy == true
end

function I.SetAutoBuyDebugEnabled(v)
	local s = I.EnsureAutoBuyDebugSetting()
	if s then
		s.debugAutoBuy = (v == true)
	end
end
