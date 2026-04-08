local _, ns = ...

-- Spells (feature)
-- UI is in fUI_QTSpellsUI.lua

ns.Spells = ns.Spells or {}
local S = ns.Spells

S.SPELL_CLASS_TOKENS = S.SPELL_CLASS_TOKENS or {
	"DEATHKNIGHT","DEMONHUNTER","DRUID","EVOKER","HUNTER","MAGE","MONK","PALADIN","PRIEST","ROGUE","SHAMAN","WARLOCK","WARRIOR",
}

function S.WipeTable(t)
	if type(t) ~= "table" then return end
	for k in pairs(t) do
		t[k] = nil
	end
end

function S.GetSelectedSpellClasses(classesSet)
	local out = {}
	classesSet = (type(classesSet) == "table") and classesSet or {}
	for _, tok in ipairs(S.SPELL_CLASS_TOKENS) do
		if classesSet[tok] then
			out[#out + 1] = tok
		end
	end
	return out
end

function S.ApplySelectedSpellClassesFromRule(classesSet, value)
	classesSet = (type(classesSet) == "table") and classesSet or {}
	S.WipeTable(classesSet)

	if type(value) == "string" then
		local tok = tostring(value):upper()
		if tok ~= "" and tok ~= "NONE" then
			classesSet[tok] = true
		end
	elseif type(value) == "table" then
		for _, v in ipairs(value) do
			local tok = tostring(v or ""):upper()
			if tok ~= "" and tok ~= "NONE" then
				classesSet[tok] = true
			end
		end
	end

	local sel = S.GetSelectedSpellClasses(classesSet)
	local single = (#sel == 1) and sel[1] or nil
	return sel, single
end

function S.ColorsMatch(tbl, r, g, b)
	if type(tbl) ~= "table" then return false end
	return (tonumber(tbl[1]) == r) and (tonumber(tbl[2]) == g) and (tonumber(tbl[3]) == b)
end

function S.ResolveExpansionNameByID(choices, id)
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

function S.GetSpellNameSafe(spellID)
	spellID = tonumber(spellID)
	if not spellID or spellID <= 0 then return nil end
	local CS = _G and rawget(_G, "C_Spell")
	if CS and CS.GetSpellName then
		local ok, n = pcall(CS.GetSpellName, spellID)
		if ok and type(n) == "string" and n ~= "" then return n end
	end
	local GSI = _G and rawget(_G, "GetSpellInfo")
	if GSI then
		local ok, n = pcall(GSI, spellID)
		if ok and type(n) == "string" and n ~= "" then return n end
	end
	return nil
end
