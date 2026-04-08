local _, ns = ...

-- Text (feature)
-- UI is in fUI_QTTextUI.lua

ns.Text = ns.Text or {}
local T = ns.Text

function T.ResolveExpansionNameByID(choices, id)
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

function T.ColorsMatch(tbl, r, g, b)
	if type(tbl) ~= "table" then return false end
	return (tonumber(tbl[1]) == r) and (tonumber(tbl[2]) == g) and (tonumber(tbl[3]) == b)
end

function T.NormalizeFontKey(key)
	key = tostring(key or "inherit")
	if key == "" then key = "inherit" end
	return key
end
