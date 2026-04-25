local _, ns = ...

-- XRules (feature)
-- Non-UI helpers used by the XRules tab UI live here.
-- UI is in fUI_QTXRulesUI.lua

ns.XRules = ns.XRules or {}
local XR = ns.XRules

function XR.NormalizeQuestXY(v)
	if v == nil then return nil end
	v = tostring(v):upper():gsub("%s+", "")
	if v == "" then return nil end
	if v == "QUESTX" then v = "X" end
	if v ~= "X" and v ~= "Y" and v ~= "K" then return nil end
	return v
end

function XR.IsXQuestRule(rule)
	if type(rule) ~= "table" then return false end
	local xy = XR.NormalizeQuestXY(rule.questXY)
	return xy == "X" or xy == "Y" or xy == "K"
end

function XR.EntryKey(xy, questID)
	xy = XR.NormalizeQuestXY(xy)
	if not xy then return nil end
	return tostring(xy) .. ":" .. tostring(tonumber(questID) or 0)
end

function XR.Trim(s)
	s = tostring(s or "")
	s = s:gsub("^%s+", ""):gsub("%s+$", "")
	return s
end

function XR.ParseZoneMeta(zoneText)
	zoneText = XR.Trim(zoneText)
	if zoneText == "" then return nil end

	local a, b = zoneText:match("^(.-),%s*(.-)$")
	a = XR.Trim(a)
	b = XR.Trim(b)
	if a ~= "" and b ~= "" then
		return { zone = a, continent = b }
	end
	return { zone = zoneText, continent = nil }
end

function XR.GetMapInfoSafe(mapID)
	mapID = tonumber(mapID)
	if not mapID or mapID <= 0 then return nil end
	if not (C_Map and C_Map.GetMapInfo) then return nil end
	local ok, info = pcall(C_Map.GetMapInfo, mapID)
	if not ok or type(info) ~= "table" then return nil end
	return info
end

function XR.ExtractFirstMapID(rule)
	if type(rule) ~= "table" or rule.locationID == nil then return nil end
	local s = tostring(rule.locationID or "")
	local n = tonumber((s:match("%d+")))
	return (n and n > 0) and n or nil
end

function XR.ResolveZoneAndContinent(mapID)
	mapID = tonumber(mapID)
	if not mapID or mapID <= 0 then return nil end

	local UIMapType = (Enum and Enum.UIMapType) or nil
	local zoneID, zoneName = nil, nil
	local contID, contName = nil, nil

	local visited = {}
	local curID = mapID
	local cur = XR.GetMapInfoSafe(curID)
	while cur and not visited[curID] do
		visited[curID] = true

		if not zoneID then
			if UIMapType and cur.mapType == UIMapType.Zone then
				zoneID, zoneName = curID, tostring(cur.name or "")
			elseif not UIMapType then
				zoneID, zoneName = curID, tostring(cur.name or "")
			end
		end

		if UIMapType and cur.mapType == UIMapType.Continent then
			contID, contName = curID, tostring(cur.name or "")
		end

		local parentID = tonumber(cur.parentMapID or 0) or 0
		if parentID <= 0 then break end
		curID = parentID
		cur = XR.GetMapInfoSafe(curID)
	end

	if not zoneID then
		local mi = XR.GetMapInfoSafe(mapID)
		if mi and mi.name then
			zoneID, zoneName = mapID, tostring(mi.name)
		end
	end

	if not contID then
		local mi = XR.GetMapInfoSafe(mapID)
		local parentID = mi and tonumber(mi.parentMapID or 0) or 0
		local parent = (parentID and parentID > 0) and XR.GetMapInfoSafe(parentID) or nil
		if parent and parent.name then
			contID, contName = parentID, tostring(parent.name)
		end
	end

	if zoneName == "" then zoneName = nil end
	if contName == "" then contName = nil end

	return {
		zoneID = zoneID,
		zoneName = zoneName,
		continentID = contID,
		continentName = contName,
	}
end

function XR.GetDbZoneMetaForQuest(qid)
	qid = tonumber(qid)
	if not qid or qid <= 0 then return nil end
	local qdb = ns and ns.db and ns.db.xquest and ns.db.xquest.quests
	if type(qdb) ~= "table" then return nil end
	local entry = qdb[qid]
	if type(entry) ~= "table" then return nil end
	local meta = entry.__meta
	if type(meta) ~= "table" then return nil end

	if meta.zone then
		local parsed = XR.ParseZoneMeta(meta.zone)
		if parsed then
			return {
				zoneName = parsed.zone,
				continentName = parsed.continent,
			}
		end
	end

	local zn = meta.zoneName or meta.zone
	local cn = meta.continentName or meta.continent
	zn = XR.Trim(zn)
	cn = XR.Trim(cn)
	if zn ~= "" or cn ~= "" then
		return {
			zoneName = (zn ~= "") and zn or nil,
			continentName = (cn ~= "") and cn or nil,
		}
	end

	return nil
end

function XR.GetDbQuestName(qid)
	qid = tonumber(qid)
	if not qid or qid <= 0 then return nil end
	local qdb = ns and ns.db and ns.db.xquest and ns.db.xquest.quests
	if type(qdb) ~= "table" then return nil end
	local entry = qdb[qid]
	if type(entry) ~= "table" then return nil end
	local meta = entry.__meta
	if type(meta) ~= "table" then return nil end
	local nm = XR.Trim(meta.name)
	if nm ~= "" then
		return nm
	end
	return nil
end

function XR.CollectByKey(opts)
	if type(opts) ~= "table" then return {} end

	local GetCustomRules = opts.GetCustomRules
	local GetCharCustomRules = opts.GetCharCustomRules
	local GetEffectiveDefaultRules = opts.GetEffectiveDefaultRules

	local byKey = {}

	local function ensure(xy, questID)
		local key = XR.EntryKey(xy, questID)
		if not key then return nil end
		local e = byKey[key]
		if not e then
			e = { key = key, questID = tonumber(questID) or 0, questXY = XR.NormalizeQuestXY(xy) }
			byKey[key] = e
		end
		return e
	end

	local function add(scope, idx, rule)
		if not XR.IsXQuestRule(rule) then return end
		local questID = tonumber(rule.questID) or 0
		local xy = XR.NormalizeQuestXY(rule.questXY)
		local e = ensure(xy, questID)
		if not e then return end

		if scope == "default" then
			if not e.defRule then e.defRule = rule end
		elseif scope == "acc" then
			e.accIndex = idx
			e.accRule = rule
		elseif scope == "char" then
			e.charIndex = idx
			e.charRule = rule
		end
	end

	local defs = (type(GetEffectiveDefaultRules) == "function") and GetEffectiveDefaultRules() or nil
	if type(defs) == "table" then
		for i = 1, #defs do
			add("default", i, defs[i])
		end
	end

	local acc = (type(GetCustomRules) == "function") and GetCustomRules() or nil
	if type(acc) == "table" then
		for i = 1, #acc do
			add("acc", i, acc[i])
		end
	end

	local chr = (type(GetCharCustomRules) == "function") and GetCharCustomRules() or nil
	if type(chr) == "table" then
		for i = 1, #chr do
			add("char", i, chr[i])
		end
	end

	return byKey
end

function XR.TreeKey(kind, a, b, c)
	local parts = { tostring(kind or "") }
	if a ~= nil then parts[#parts + 1] = tostring(a) end
	if b ~= nil then parts[#parts + 1] = tostring(b) end
	if c ~= nil then parts[#parts + 1] = tostring(c) end
	return table.concat(parts, ":")
end

function XR.BuildNodes(byKey, opts)
	if type(byKey) ~= "table" then return {} end
	opts = (type(opts) == "table") and opts or {}
	local GetQuestTitle = opts.GetQuestTitle
	local IsExpanded = opts.IsExpanded
	if type(IsExpanded) ~= "function" then
		IsExpanded = function(_, defaultVal) return defaultVal and true or false end
	end

	local titleCache = {}
	local function SortTitleForEntry(e)
		local qid = tonumber(e and e.questID) or 0
		local hasDef = e and (e.defRule ~= nil) or false
		local hasAcc = e and (e.accRule ~= nil) or false
		local hasChar = e and (e.charRule ~= nil) or false
		local dbOnly = hasDef and (not hasAcc) and (not hasChar)

		local cacheKey = tostring(qid) .. ":" .. (dbOnly and "db" or "live")
		if titleCache[cacheKey] ~= nil then
			return titleCache[cacheKey]
		end

		local t
		if dbOnly then
			t = XR.GetDbQuestName(qid)
		end
		if (type(t) ~= "string" or t == "") and type(GetQuestTitle) == "function" and qid > 0 then
			t = GetQuestTitle(qid)
		end
		if type(t) ~= "string" or t == "" then
			t = (qid > 0) and ("Quest " .. tostring(qid)) or ""
		end

		titleCache[cacheKey] = t
		return t
	end

	local groups = {}

	for _, e in pairs(byKey) do
		local xy = XR.NormalizeQuestXY(e.questXY)
		if xy then
			local mapID = XR.ExtractFirstMapID(e.accRule) or XR.ExtractFirstMapID(e.charRule) or XR.ExtractFirstMapID(e.defRule)
			local continentLabel, zoneLabel = nil, nil
			local continentKey, zoneKey = nil, nil

			if mapID then
				local resolved = XR.ResolveZoneAndContinent(mapID)
				continentLabel = (resolved and resolved.continentName) or "Global/Unknown"
				zoneLabel = (resolved and resolved.zoneName) or "Global/Unknown"
				continentKey = tostring((resolved and resolved.continentID) or "global")
				zoneKey = tostring((resolved and resolved.zoneID) or "global")
			else
				local dbm = XR.GetDbZoneMetaForQuest(e.questID)
				continentLabel = (dbm and dbm.continentName) or "Global/Unknown"
				zoneLabel = (dbm and dbm.zoneName) or "Global/Unknown"
				continentKey = tostring(continentLabel)
				zoneKey = tostring(zoneLabel)
			end

			local cont = groups[continentKey]
			if not cont then
				cont = { key = continentKey, label = continentLabel, zones = {} }
				groups[continentKey] = cont
			end

			local zn = cont.zones[zoneKey]
			if not zn then
				zn = { key = zoneKey, label = zoneLabel, entries = {} }
				cont.zones[zoneKey] = zn
			end

			zn.entries[#zn.entries + 1] = e
		end
	end

	local function SortedKeys(t)
		local keys = {}
		for k in pairs(t or {}) do keys[#keys + 1] = k end
		table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
		return keys
	end

	local nodes = {}

	local contKeys = SortedKeys(groups)
	table.sort(contKeys, function(a, b)
		local la = tostring((groups[a] and groups[a].label) or "")
		local lb = tostring((groups[b] and groups[b].label) or "")
		if la ~= lb then return la < lb end
		return tostring(a) < tostring(b)
	end)

	for _, ck in ipairs(contKeys) do
		local cont = groups[ck]
		local contNodeKey = XR.TreeKey("cont", cont.label)
		local contExpanded = IsExpanded(contNodeKey, true)
		nodes[#nodes + 1] = { kind = "continent", key = contNodeKey, label = cont.label, level = 0, expanded = contExpanded }

		if contExpanded then
			local zoneKeys = SortedKeys(cont.zones)
			table.sort(zoneKeys, function(a, b)
				local la = tostring((cont.zones[a] and cont.zones[a].label) or "")
				local lb = tostring((cont.zones[b] and cont.zones[b].label) or "")
				if la ~= lb then return la < lb end
				return tostring(a) < tostring(b)
			end)

			for _, zk in ipairs(zoneKeys) do
				local zn = cont.zones[zk]
				local zoneNodeKey = XR.TreeKey("zone", cont.label, zn.label)
				local zoneExpanded = IsExpanded(zoneNodeKey, true)
				nodes[#nodes + 1] = { kind = "zone", key = zoneNodeKey, label = zn.label, level = 1, expanded = zoneExpanded }

				if zoneExpanded then
					table.sort(zn.entries, function(a, b)
						local ta = SortTitleForEntry(a)
						local tb = SortTitleForEntry(b)
						local sa = tostring(ta):lower()
						local sb = tostring(tb):lower()
						if sa ~= sb then return sa < sb end
						if tostring(ta) ~= tostring(tb) then return tostring(ta) < tostring(tb) end
						if (a.questID or 0) ~= (b.questID or 0) then return (a.questID or 0) < (b.questID or 0) end
						local ax = XR.NormalizeQuestXY(a.questXY) or ""
						local bx = XR.NormalizeQuestXY(b.questXY) or ""
						if ax ~= bx then return ax < bx end
						return tostring(a.key) < tostring(b.key)
					end)

					for _, e in ipairs(zn.entries) do
						nodes[#nodes + 1] = { kind = "rule", key = e.key, entry = e, level = 2 }
					end
				end
			end
		end
	end

	return nodes
end
