local _, ns = ...

-- Usage (feature)
-- UI is in fUI_QTUsageUI.lua

-- Shared map-group expansion for DB rule packs.
-- Keep this near the top so map aliases are easy to edit in one place.
ns.MAP_GROUPS = ns.MAP_GROUPS or {
	CAP = {84, 85}, STW = {84}, ORG = {85},
	CAT = {84, 85},
	MoP = {371, 376, 379, 388, 390, 391, 393, 418, 422, 554}, TI = {554},
	WoD = {525, 539, 540, 582, 590},
	LGN = {627, 630, 634, 641, 646, 650, 680, 733, 750, 751, 754, 755, 756, 757, 758, 759, 760, 761},
	BFA = {862, 863, 864, 895, 896, 942, 1161, 1163, 1165, 1355, 1462},
	SHD = {1670},
	DRG = {1978},
	TWW = {2339},
	MDN = {2393},
}

function ns.ExpandMapIDs(value)
	if type(value) ~= "table" then return value end
	local expanded = {}
	for _, mapID in ipairs(value) do
		local group = type(mapID) == "string" and ns.MAP_GROUPS[mapID] or nil
		if group then
			for _, groupedMapID in ipairs(group) do
				expanded[#expanded + 1] = groupedMapID
			end
		else
			expanded[#expanded + 1] = mapID
		end
	end
	return expanded
end

ns.Usage = ns.Usage or {}
local U = ns.Usage

-- Layout Defaults
--
-- This table defines the default frame layouts (bars/lists). Keeping it here avoids a
-- standalone layout file while still keeping defaults out of the core engine.
--
-- Frame fields:
--   parentFrame (string?)      - global frame name to parent to (hide/show follows parent)
--   bgAlpha (number?)          - backdrop alpha (bar default can be 0)
--   autoSize (boolean?)        - resize height to shown contents (list)
--   minRows (number?)          - min rows when autoSize is true
--   stretchWidth (boolean?)    - bar: stretch to UIParent width
--   font (table?)              - font style for entries
--       name (string)          - LibSharedMedia font name OR a font path
--       size (number)
--       flags (string?)        - e.g. "OUTLINE"
--       color (string?)        - hex RGB e.g. "ffdf3c"
--       shadow (table?)        - { x, y, "000000" }
ns.frames = ns.frames or {
	{
		id = "bar1",
		type = "bar",
		point = "TOP",
		relPoint = "TOP",
		x = 0,
		y = -10,
		width = 600,
		height = 20,
		maxItems = 6,
		bgAlpha = 0,
		hideWhenEmpty = false,
		stretchWidth = false,
		font = {
			name = "Bazooka",
			size = 15,
			flags = "OUTLINE",
			color = "ffdf3c",
			shadow = { 1, -1, "000000" },
		},
	},
	{
		id = "bar2",
		type = "bar",
		point = "TOP",
		relPoint = "TOP",
		x = 0,
		y = -34,
		width = 600,
		height = 20,
		maxItems = 6,
		bgAlpha = 0,
		hideWhenEmpty = false,
		stretchWidth = false,
		hideFrame = true,
		font = {
			name = "Bazooka",
			size = 15,
			flags = "OUTLINE",
			color = "ffdf3c",
			shadow = { 1, -1, "000000" },
		},
	},
	{
		id = "list1",
		type = "list",
		anchorCorner = "br",
		point = "BOTTOMRIGHT",
		relPoint = "BOTTOMRIGHT",
		x = -10,
		y = 120,
		width = 300,
		rowHeight = 16,
		maxItems = 20,
		autoSize = true,
		hideWhenEmpty = false,
	},
	{
		id = "list2",
		type = "list",
		point = "CENTER",
		relPoint = "CENTER",
		x = 0,
		y = -220,
		width = 300,
		rowHeight = 16,
		maxItems = 20,
		autoSize = true,
		hideWhenEmpty = false,
	},
	{
		id = "list3",
		type = "list",
		point = "CENTER",
		relPoint = "CENTER",
		x = 0,
		y = -440,
		width = 300,
		rowHeight = 16,
		maxItems = 20,
		autoSize = true,
		hideWhenEmpty = false,
		hideFrame = true,
	},
}

function U.NormalizeAnchorCorner(v)
	v = tostring(v or ""):lower():gsub("%s+", "")
	v = v:gsub("_", ""):gsub("-", "")
	if v == "tl" or v == "topleft" then return "tl" end
	if v == "tr" or v == "topright" then return "tr" end
	if v == "tc" or v == "topcenter" or v == "topcentre" then return "tc" end
	if v == "bl" or v == "bottomleft" then return "bl" end
	if v == "br" or v == "bottomright" then return "br" end
	if v == "bc" or v == "bottomcenter" or v == "bottomcentre" then return "bc" end
	return nil
end

function U.NormalizeGrowDir(v)
	v = tostring(v or ""):lower():gsub("%s+", "")
	v = v:gsub("_", "-")
	if v == "upleft" then v = "up-left" end
	if v == "upright" then v = "up-right" end
	if v == "downleft" then v = "down-left" end
	if v == "downright" then v = "down-right" end
	if v == "up-left" or v == "up-right" or v == "down-left" or v == "down-right" then
		return v
	end
	return nil
end

function U.DeriveGrowDirFromCorner(corner)
	corner = U.NormalizeAnchorCorner(corner) or "tl"
	if corner == "tl" then return "down-right" end
	if corner == "tr" then return "down-left" end
	if corner == "tc" then return "down-right" end
	if corner == "bl" then return "up-right" end
	if corner == "br" then return "up-left" end
	if corner == "bc" then return "up-right" end
	return "down-right"
end

function U.DeriveCornerFromGrowDir(dir)
	dir = U.NormalizeGrowDir(dir) or "down-right"
	if dir == "down-right" then return "tl" end
	if dir == "down-left" then return "tr" end
	if dir == "up-right" then return "bl" end
	if dir == "up-left" then return "br" end
	return "tl"
end

function U.AnchorCornerLabel(corner)
	corner = U.NormalizeAnchorCorner(corner) or "tl"
	if corner == "tl" then return "Top Left" end
	if corner == "tr" then return "Top Right" end
	if corner == "tc" then return "Top Center" end
	if corner == "bl" then return "Bottom Left" end
	if corner == "br" then return "Bottom Right" end
	if corner == "bc" then return "Bottom Center" end
	return "Top Left"
end

function U.GrowDirLabel(dir)
	dir = U.NormalizeGrowDir(dir) or "down-right"
	if dir == "up-left" then return "Up-Left" end
	if dir == "up-right" then return "Up-Right" end
	if dir == "down-left" then return "Down-Left" end
	if dir == "down-right" then return "Down-Right" end
	return "Down-Right"
end

function U.AnchorGrowLabel(corner)
	corner = U.NormalizeAnchorCorner(corner) or "tl"
	local dir = U.DeriveGrowDirFromCorner(corner)
	return string.format("%s (%s)", U.AnchorCornerLabel(corner), U.GrowDirLabel(dir))
end

function U.NormalizeLinkMode(v)
	v = tostring(v or ""):lower():gsub("%s+", "")
	if v == "hook" then return "hook" end
	if v == "parent" or v == "reparent" then return "hook" end
	return "off"
end
