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

-- Remaining cooldown in seconds for an item; 0 when ready, unknown, or not in bags.
function I.GetItemCooldownRemaining(itemID)
	itemID = tonumber(itemID)
	if not itemID or itemID <= 0 then return 0 end

	local getCooldown = (C_Item and C_Item.GetItemCooldown)
		or (C_Container and C_Container.GetItemCooldown)
		or rawget(_G, "GetItemCooldown")
	if type(getCooldown) ~= "function" then return 0 end

	local ok, startTime, duration, enable = pcall(getCooldown, itemID)
	if not ok then return 0 end

	startTime = tonumber(startTime) or 0
	duration = tonumber(duration) or 0
	if enable == 0 or startTime <= 0 or duration <= 0 then return 0 end

	local now = (type(GetTime) == "function") and GetTime() or 0
	local remaining = (startTime + duration) - now
	return (remaining > 0) and remaining or 0
end

-- "2d 3h" / "3h 12m" / "12m" / "45s"; blank string when the item is off cooldown.
function I.GetItemCooldownText(itemID)
	local remaining = math.floor(I.GetItemCooldownRemaining(itemID) + 0.5)
	if remaining <= 0 then return "" end

	local days = math.floor(remaining / 86400)
	local hours = math.floor((remaining % 86400) / 3600)
	local minutes = math.floor((remaining % 3600) / 60)

	if days > 0 then return string.format("%dd %dh", days, hours) end
	if hours > 0 then return string.format("%dh %dm", hours, minutes) end
	if minutes > 0 then return string.format("%dm", minutes) end
	return string.format("%ds", remaining % 60)
end

ns.GetItemCooldownRemaining = I.GetItemCooldownRemaining
ns.GetItemCooldownText = I.GetItemCooldownText
