local addonName, ns = ...

ns.TrackerFrames = ns.TrackerFrames or {}
local TF = ns.TrackerFrames

function TF.ApplyTrackerInteractivity(framesByID, rootFrame)
  if InCombatLockdown and InCombatLockdown() then
    if rootFrame then
      rootFrame._pendingInteractivity = true
    end
    return
  end

  local editMode = (ns and ns.GetEditMode and ns.GetEditMode()) and true or false
  local clickThrough = not editMode
  local wantWheel = (editMode and true) or ((IsShiftKeyDown and IsShiftKeyDown()) and true or false)

  if type(framesByID) ~= "table" then return end
  for _, f in pairs(framesByID) do
    if f then
      -- Keep mouse enabled so wheel can be toggled by Shift.
      if f.EnableMouse then f:EnableMouse(true) end

      if f.SetMouseClickEnabled then
        local clickable = not clickThrough
        local ok = pcall(f.SetMouseClickEnabled, f, clickable)
        if not ok then
          pcall(f.SetMouseClickEnabled, f, "LeftButton", clickable)
          pcall(f.SetMouseClickEnabled, f, "RightButton", clickable)
        end
      elseif f.SetPropagateMouseClicks then
        pcall(f.SetPropagateMouseClicks, f, clickThrough)
      else
        -- Old client fallback: disabling mouse also disables hover (acceptable).
        if f.EnableMouse then f:EnableMouse(not clickThrough) end
      end

      if f.SetPropagateMouseMotion then
        pcall(f.SetPropagateMouseMotion, f, clickThrough)
      end

      if f.EnableMouseWheel then
        if f._wheelEnabled ~= wantWheel then
          f._wheelEnabled = wantWheel
          pcall(f.EnableMouseWheel, f, wantWheel)
        end
      end
    end
  end
end

function TF.OnModifierStateChanged(rootFrame, applyFn)
  if InCombatLockdown and InCombatLockdown() then
    if rootFrame then
      rootFrame._pendingInteractivity = true
    end
    return
  end
  if type(applyFn) == "function" then
    applyFn()
  end
end

function TF.OnPlayerRegenEnabled_Interactivity(rootFrame, applyFn)
  if rootFrame and rootFrame._pendingInteractivity then
    rootFrame._pendingInteractivity = nil
    if type(applyFn) == "function" then
      if C_Timer and C_Timer.After then
        C_Timer.After(0, applyFn)
      else
        applyFn()
      end
    end
  end
end

function TF.GetFramePosStore()
  -- This is called from hot UI paths; NormalizeSV can be very expensive if repeated.
  if not (type(fr0z3nUI_QuestTracker_Acc) == "table" and fr0z3nUI_QuestTracker_Acc._fqtNorm) then
    if ns and ns.NormalizeSV then
      ns.NormalizeSV()
    elseif _G and _G.NormalizeSV then
      _G.NormalizeSV()
    end
  end

  if type(fr0z3nUI_QuestTracker_Acc) ~= "table" then return {} end
  if type(fr0z3nUI_QuestTracker_Char) ~= "table" then return {} end

  fr0z3nUI_QuestTracker_Acc.settings.framePos = fr0z3nUI_QuestTracker_Acc.settings.framePos or {}
  fr0z3nUI_QuestTracker_Char.settings.framePos = fr0z3nUI_QuestTracker_Char.settings.framePos or {}
  return fr0z3nUI_QuestTracker_Acc.settings.framePos
end

function TF.ClearSavedFramePosition(frameID)
  frameID = tostring(frameID or "")
  if frameID == "" then return false end
  local store = TF.GetFramePosStore()
  if type(store) ~= "table" then return false end
  store[frameID] = nil
  return true
end

ns.ClearSavedFramePosition = TF.ClearSavedFramePosition

function TF.NormalizeAnchorCorner(v)
  if type(ns) == "table" and type(ns.Usage) == "table" and type(ns.Usage.NormalizeAnchorCorner) == "function" then
    local ok, corner = pcall(ns.Usage.NormalizeAnchorCorner, v)
    if ok and corner ~= nil then
      return corner
    end
  end
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

local function AnchorCornerToPoint(corner)
  corner = TF.NormalizeAnchorCorner(corner)
  if corner == "tl" then return "TOPLEFT" end
  if corner == "tr" then return "TOPRIGHT" end
  if corner == "tc" then return "TOP" end
  if corner == "bl" then return "BOTTOMLEFT" end
  if corner == "br" then return "BOTTOMRIGHT" end
  if corner == "bc" then return "BOTTOM" end
  return nil
end

function TF.PointToAnchorCorner(point)
  point = tostring(point or ""):upper()
  if point == "TOP" then return "tc" end
  if point == "BOTTOM" then return "bc" end
  local vert = point:find("BOTTOM", 1, true) and "b" or "t"
  local horiz = point:find("RIGHT", 1, true) and "r" or "l"
  return vert .. horiz
end

function TF.SaveFramePosition(f)
  if not (f and f._id and f.GetPoint) then return end

  -- Explicit only: keep the current anchor point; do not auto-pick based on screen position.
  local point, _, relPoint, x, y = f:GetPoint(1)
  if not point then return end

  local store = TF.GetFramePosStore()
  store[tostring(f._id)] = {
    point = tostring(point),
    relPoint = tostring(relPoint or point),
    x = tonumber(x) or 0,
    y = tonumber(y) or 0,
    -- Always store relative to UIParent for consistent behavior across all frames.
    parent = "UIParent",
  }
end

ns.SaveFramePosition = TF.SaveFramePosition

function TF.ApplySavedFramePosition(f, def)
  if not (f and f._id and f.SetPoint and f.ClearAllPoints) then return false end
  local store = TF.GetFramePosStore()
  local pos = store[tostring(f._id)]
  if type(pos) ~= "table" then return false end

  local point = pos.point or (def and def.point)
  local relPoint = pos.relPoint or (def and def.relPoint) or point
  if not point then return false end

  local ref = UIParent

  f:ClearAllPoints()
  f:SetPoint(point, ref or UIParent, relPoint, tonumber(pos.x) or 0, tonumber(pos.y) or 0)
  return true
end

local function ResolveFrameAnchor(def, defaultPoint)
  if type(def) ~= "table" then
    local p = tostring(defaultPoint or "CENTER")
    return p, p, 0, 0
  end

  local point = def.point
  local relPoint = def.relPoint or def.point
  local x = def.x
  local y = def.y

  if not point then
    local ap = AnchorCornerToPoint(def.anchorCorner)
    if ap then
      point = ap
      relPoint = ap
    end
  end

  if not point then
    point = tostring(defaultPoint or "CENTER")
    relPoint = point
    x = x or 0
    y = y or 0
  end

  return tostring(point), tostring(relPoint or point), tonumber(x) or 0, tonumber(y) or 0
end

function TF.ApplyFramePositionFromDef(f, def)
  if not (f and f.ClearAllPoints and f.SetPoint) then return false end
  -- Avoid fighting the user while actively dragging in edit mode.
  if f.IsMoving and f:IsMoving() then return false end
  if f._fqtIsMoving then return false end

  -- Prefer saved offsets (dragged positions) but allow anchorCorner/point changes to take effect.
  local store = TF.GetFramePosStore()
  local pos = store and f._id and store[tostring(f._id)]
  if type(pos) == "table" then
    local point, relPoint = pos.point, pos.relPoint
    if type(def) == "table" and def.anchorCorner then
      local ap = AnchorCornerToPoint(def.anchorCorner)
      if ap then
        -- If the user changes anchorCorner, keep the frame in the same on-screen spot
        -- by converting the saved offsets from the old point to the new point.
        if pos.point and tostring(pos.point) ~= tostring(ap) and f.GetLeft then
          local left, right, top, bottom = f:GetLeft(), f:GetRight(), f:GetTop(), f:GetBottom()
          local pl, pr, pt, pb = UIParent:GetLeft(), UIParent:GetRight(), UIParent:GetTop(), UIParent:GetBottom()
          if left and right and top and bottom and pl and pr and pt and pb then
            local cx, cy = (left + right) / 2, (bottom + top) / 2
            local pcx, pcy = (pl + pr) / 2, (pb + pt) / 2

            local function AnchorXYFromRect(pointStr, l, r, t, b, cX, cY)
              pointStr = tostring(pointStr or "CENTER"):upper()
              local x
              if pointStr:find("LEFT", 1, true) then x = l
              elseif pointStr:find("RIGHT", 1, true) then x = r
              else x = cX end

              local y
              if pointStr:find("TOP", 1, true) then y = t
              elseif pointStr:find("BOTTOM", 1, true) then y = b
              else y = cY end

              return x, y
            end

            local ax, ay = AnchorXYFromRect(ap, left, right, top, bottom, cx, cy)
            local px, py = AnchorXYFromRect(ap, pl, pr, pt, pb, pcx, pcy)
            if ax and ay and px and py then
              pos.x = math.floor(((ax - px) or 0) + 0.5)
              pos.y = math.floor(((ay - py) or 0) + 0.5)
              pos.point = ap
              pos.relPoint = ap
              point = ap
              relPoint = ap
            end
          end
        end
        point = ap
        relPoint = ap
      end
    end
    if not point and type(def) == "table" then point = def.point end
    if not relPoint and type(def) == "table" then relPoint = def.relPoint or def.point end
    if point then
      local ref = UIParent
      f:ClearAllPoints()
      f:SetPoint(tostring(point), ref or UIParent, tostring(relPoint or point), tonumber(pos.x) or 0, tonumber(pos.y) or 0)
      return true
    end
  end

  -- No saved framePos entry: if an anchorCorner is set, keep the frame visually stationary by
  -- computing the offsets for that anchor from the current on-screen rect.
  if type(def) == "table" and def.anchorCorner and f.GetLeft and UIParent and UIParent.GetLeft then
    local ap = AnchorCornerToPoint(def.anchorCorner)
    if ap then
      local left, right, top, bottom = f:GetLeft(), f:GetRight(), f:GetTop(), f:GetBottom()
      local pl, pr, pt, pb = UIParent:GetLeft(), UIParent:GetRight(), UIParent:GetTop(), UIParent:GetBottom()
      if left and right and top and bottom and pl and pr and pt and pb then
        local cx, cy = (left + right) / 2, (bottom + top) / 2
        local pcx, pcy = (pl + pr) / 2, (pb + pt) / 2

        local function AnchorXYFromRect(pointStr, l, r, t, b, cX, cY)
          pointStr = tostring(pointStr or "CENTER"):upper()
          local x
          if pointStr:find("LEFT", 1, true) then x = l
          elseif pointStr:find("RIGHT", 1, true) then x = r
          else x = cX end

          local y
          if pointStr:find("TOP", 1, true) then y = t
          elseif pointStr:find("BOTTOM", 1, true) then y = b
          else y = cY end

          return x, y
        end

        local ax, ay = AnchorXYFromRect(ap, left, right, top, bottom, cx, cy)
        local px, py = AnchorXYFromRect(ap, pl, pr, pt, pb, pcx, pcy)
        if ax and ay and px and py then
          local x = math.floor(((ax - px) or 0) + 0.5)
          local y = math.floor(((ay - py) or 0) + 0.5)
          -- Persist the converted offsets into the def so subsequent refreshes stay consistent.
          def.point = ap
          def.relPoint = ap
          def.x = x
          def.y = y
        end
      end
    end
  end

  local point, relPoint, x, y = ResolveFrameAnchor(def, "CENTER")
  local ref = (f.GetParent and f:GetParent()) or UIParent
  f:ClearAllPoints()
  f:SetPoint(point, ref or UIParent, relPoint, x, y)
  return true
end

function TF.NudgeFrameOnScreen(f, pad)
  if not (f and f.GetLeft and f.GetRight and f.GetTop and f.GetBottom and f.GetPoint and f.SetPoint and f.ClearAllPoints) then return false end
  pad = tonumber(pad)
  if not pad or pad < 0 then pad = 8 end

  local scale = (f.GetEffectiveScale and f:GetEffectiveScale()) or 1
  if not scale or scale <= 0 then scale = 1 end

  local left, right, top, bottom = f:GetLeft(), f:GetRight(), f:GetTop(), f:GetBottom()
  if not (left and right and top and bottom) then return false end

  local sw = (GetScreenWidth and GetScreenWidth()) or (UIParent and UIParent.GetWidth and UIParent:GetWidth()) or 0
  local sh = (GetScreenHeight and GetScreenHeight()) or (UIParent and UIParent.GetHeight and UIParent:GetHeight()) or 0
  if not (sw and sh) or sw <= 0 or sh <= 0 then return false end

  -- Convert into scaled screen space so comparisons stay correct under per-frame scaling.
  left, right, top, bottom = left * scale, right * scale, top * scale, bottom * scale
  local padS = pad * scale

  local frameW = right - left
  local frameH = top - bottom

  local dxS, dyS = 0, 0

  if frameW > (sw - 2 * padS) then
    dxS = (padS - left)
  else
    if left < padS then dxS = (padS - left)
    elseif right > (sw - padS) then dxS = ((sw - padS) - right) end
  end

  if frameH > (sh - 2 * padS) then
    dyS = ((sh - padS) - top)
  else
    if bottom < padS then dyS = (padS - bottom)
    elseif top > (sh - padS) then dyS = ((sh - padS) - top) end
  end

  if dxS == 0 and dyS == 0 then return false end

  -- Convert correction back into unscaled anchor offsets.
  local dx = dxS / scale
  local dy = dyS / scale

  local point, rel, relPoint, x, y = f:GetPoint(1)
  if not point then return false end
  f:ClearAllPoints()
  f:SetPoint(point, rel or UIParent, relPoint or point, (tonumber(x) or 0) + dx, (tonumber(y) or 0) + dy)
  return true
end

function TF.ApplyFAOBackdrop(f, bgAlpha, bgColor)
  f:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    tile = true,
    tileSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })

  local a = tonumber(bgAlpha)
  if a == nil then a = 0 end
  if a < 0 then a = 0 end
  if a > 1 then a = 1 end

  local r, g, b = 0, 0, 0
  if type(bgColor) == "table" then
    r = tonumber(bgColor[1]) or r
    g = tonumber(bgColor[2]) or g
    b = tonumber(bgColor[3]) or b
  end
  if r < 0 then r = 0 end
  if r > 1 then r = 1 end
  if g < 0 then g = 0 end
  if g > 1 then g = 1 end
  if b < 0 then b = 0 end
  if b > 1 then b = 1 end

  f:SetBackdropColor(r, g, b, a)
end

ns.ApplyFAOBackdrop = TF.ApplyFAOBackdrop

local function EnsureAnchorLabel(frame)
  if not frame then return nil end
  if frame._anchorLabel then return frame._anchorLabel end
  local btn = CreateFrame("Button", nil, frame)
  btn:EnableMouse(true)
  btn:SetSize(92, 16)
  btn:RegisterForDrag("LeftButton")
  btn:SetScript("OnDragStart", function(self)
    if not (ns and ns.GetEditMode and ns.GetEditMode()) then return end
    local p = self:GetParent()
    if p and p.StartMoving then p:StartMoving() end
    if p then p._fqtIsMoving = true end
  end)
  btn:SetScript("OnDragStop", function(self)
    local p = self:GetParent()
    if p and p.StopMovingOrSizing then p:StopMovingOrSizing() end
    if p then p._fqtIsMoving = nil end
    if p then
      TF.SaveFramePosition(p)
      TF.UpdateAnchorLabel(p)
    end
  end)
  btn:Hide()

  if not btn.CreateFontString then return nil end
  local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  if fs.SetJustifyH then fs:SetJustifyH("LEFT") end
  if fs.SetJustifyV then fs:SetJustifyV("MIDDLE") end
  fs:SetPoint("LEFT", 6, 0)
  fs:SetPoint("RIGHT", -6, 0)
  fs:SetText("|cff00ccff[FQT]|r")
  fs:Hide()

  frame._anchorLabel = fs
  frame._anchorBtn = btn
  return fs
end

function TF.UpdateAnchorLabel(frame, frameDef)
  local fs = EnsureAnchorLabel(frame)
  if not fs then return end

  local btn = frame and frame._anchorBtn

  if not (ns and ns.GetEditMode and ns.GetEditMode()) then
    fs:Hide()
    if btn then btn:Hide() end
    return
  end

  local id = (type(frameDef) == "table" and frameDef.id) or frame._id
  local text = "|cff00ccff[FQT]|r"
  if id ~= nil and tostring(id) ~= "" then
    text = text .. " " .. tostring(id)
  end
  fs:SetText(text)

  local def = (type(frameDef) == "table") and frameDef or (frame and frame._lastFrameDef)
  local corner = (type(def) == "table") and TF.NormalizeAnchorCorner(def.anchorCorner) or nil
  if not corner and frame and frame.GetPoint then
    local p = frame:GetPoint(1)
    corner = TF.PointToAnchorCorner(p)
  end
  if corner ~= "tl" and corner ~= "tr" and corner ~= "tc" and corner ~= "bl" and corner ~= "br" and corner ~= "bc" then corner = "tl" end

  fs:ClearAllPoints()
  if corner == "tr" then
    if fs.SetJustifyH then fs:SetJustifyH("RIGHT") end
    if btn then
      btn:ClearAllPoints()
      btn:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 0)
    end
  elseif corner == "tc" then
    if fs.SetJustifyH then fs:SetJustifyH("CENTER") end
    if btn then
      btn:ClearAllPoints()
      btn:SetPoint("BOTTOM", frame, "TOP", 0, 0)
    end
  elseif corner == "bl" then
    if fs.SetJustifyH then fs:SetJustifyH("LEFT") end
    if btn then
      btn:ClearAllPoints()
      btn:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, 0)
    end
  elseif corner == "br" then
    if fs.SetJustifyH then fs:SetJustifyH("RIGHT") end
    if btn then
      btn:ClearAllPoints()
      btn:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    end
  elseif corner == "bc" then
    if fs.SetJustifyH then fs:SetJustifyH("CENTER") end
    if btn then
      btn:ClearAllPoints()
      btn:SetPoint("TOP", frame, "BOTTOM", 0, 0)
    end
  else
    if fs.SetJustifyH then fs:SetJustifyH("LEFT") end
    if btn then
      btn:ClearAllPoints()
      btn:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 0)
    end
  end

  if btn then
    fs:ClearAllPoints()
    fs:SetPoint("LEFT", btn, "LEFT", 6, 0)
    fs:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
    btn:SetFrameLevel((frame.GetFrameLevel and frame:GetFrameLevel() or 1) + 20)
    btn:Show()
  end

  fs:Show()

  -- Keep the bar "List" inspect button attached to the bar's actual anchor corner.
  if frame and frame._barInspectBtn then
    -- Map TL/TR/BL/BR to the button side:
    -- TL + down-right => right, TR + down-left => left, BL + up-right => right, BR + up-left => left.
    local c = tostring(corner or "tl")
    local p
    if c == "tc" then
      p = "TOPRIGHT"
    elseif c == "bc" then
      p = "BOTTOMRIGHT"
    else
      if c ~= "tl" and c ~= "tr" and c ~= "bl" and c ~= "br" then c = "tl" end
      local vert = (c:sub(1, 1) == "t") and "TOP" or "BOTTOM"
      local horiz = (c:sub(2, 2) == "l") and "RIGHT" or "LEFT"
      p = vert .. horiz
    end
    frame._barInspectBtn:ClearAllPoints()
    frame._barInspectBtn:SetPoint(p, frame, p, (p:find("LEFT", 1, true) and 6 or -6), (p:find("TOP", 1, true) and -6 or 6))
  end
end

local function CreateContainerFrame(def)
  local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
  f:SetClampedToScreen(true)
  f:SetFrameStrata("MEDIUM")
  f:SetMovable(true)
  f:EnableMouse(true)
  -- Frame moving is handled via the anchor label button in edit mode.
  local bgAlpha = (type(def) == "table") and def.bgAlpha or nil
  local bgColor = (type(def) == "table") and def.bgColor or nil
  TF.ApplyFAOBackdrop(f, bgAlpha, bgColor)

  f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f.title:SetPoint("TOPLEFT", 8, -6)
  f.title:SetJustifyH("LEFT")
  f.title:SetText("")
  f.title:Hide()

  return f
end

local function ResolveNamedFrame(name)
  name = tostring(name or "")
  name = name:gsub("^%s+", ""):gsub("%s+$", "")
  if name == "" then return nil end
  return _G and _G[name] or nil
end

local function NormalizeVisLinkMode(def)
  if type(def) ~= "table" then return "off" end
  local mode
  if type(ns) == "table" and type(ns.Usage) == "table" and type(ns.Usage.NormalizeLinkMode) == "function" then
    local ok, v = pcall(ns.Usage.NormalizeLinkMode, def.visibilityLinkMode)
    if ok and v ~= nil then
      mode = v
    end
  end
  if mode == nil then
    mode = tostring(def.visibilityLinkMode or ""):lower():gsub("%s+", "")
    -- Re-parent mode removed; map any legacy values to hook.
    if mode == "parent" or mode == "reparent" then mode = "hook" end
  end
  if mode ~= "hook" then
    -- Back-compat: old configs could have parentFrame set; treat as hook.
    if type(def.parentFrame) == "string" and def.parentFrame ~= "" then
      mode = "hook"
    else
      mode = "off"
    end
  end
  return mode
end

local function GetVisLinkFrameName(def)
  if type(def) ~= "table" then return "" end
  local nm = def.visibilityLinkFrame
  if (nm == nil or nm == "") and type(def.parentFrame) == "string" then
    nm = def.parentFrame
  end
  nm = tostring(nm or "")
  nm = nm:gsub("^%s+", ""):gsub("%s+$", "")
  return nm
end

function TF.ApplyVisLink(frame, def, baseScale)
  if not frame then return false end

  if ns and ns.GetEditMode and ns.GetEditMode() then
    -- In edit mode, always show and keep frames under UIParent; apply base scale.
    frame._visLinkForceHide = nil
    if frame.GetParent and frame.SetParent and frame:GetParent() ~= UIParent then
      frame:SetParent(UIParent)
    end
    if frame.SetScale then frame:SetScale(tonumber(baseScale) or 1) end
    return false
  end

  local mode = NormalizeVisLinkMode(def)
  local nm = GetVisLinkFrameName(def)
  local target = (nm ~= "") and ResolveNamedFrame(nm) or nil

  -- Re-parent mode removed: always keep frames under UIParent.
  if frame.SetParent and frame.GetParent and frame:GetParent() ~= UIParent then
    frame:SetParent(UIParent)
  end
  if frame.SetScale then frame:SetScale(tonumber(baseScale) or 1) end

  if mode == "hook" and target and target.HookScript and target.IsShown then
    if frame._visLinkHookTarget ~= target then
      frame._visLinkHookTarget = target
      local function Sync()
        if not frame then return end
        -- Force a re-eval of visibility with the new target state.
        if ns and ns.RefreshAll then
          ns.RefreshAll()
        end
      end
      frame._visLinkHookFn = Sync
      target:HookScript("OnShow", Sync)
      target:HookScript("OnHide", Sync)
    end
    frame._visLinkForceHide = (target:IsShown() ~= true) and true or nil
    return frame._visLinkForceHide and true or false
  end

  frame._visLinkForceHide = nil
  return false
end

function TF.CreateBarFrame(def)
  local f = CreateContainerFrame(def)
  f._id = def and def.id or nil
  f:SetSize(def.width or 300, def.height or 20)
  local ref = (f.GetParent and f:GetParent()) or UIParent
  do
    local p, rp, x, y = ResolveFrameAnchor(def, "TOP")
    f:SetPoint(p, ref or UIParent, rp, x, y)
  end
  TF.ApplyFramePositionFromDef(f, def)
  TF.NudgeFrameOnScreen(f, 8)

  f._itemFont = "GameFontHighlightSmall"
  f.items = {}

  f._wheelEnabled = ((ns and ns.GetEditMode and ns.GetEditMode()) and true) or ((IsShiftKeyDown and IsShiftKeyDown()) and true or false)
  f:EnableMouseWheel(f._wheelEnabled)
  f:SetScript("OnMouseWheel", function(self, delta)
    if not ((ns and ns.GetEditMode and ns.GetEditMode()) or (IsShiftKeyDown and IsShiftKeyDown())) then return end
    -- Only allow scrolling when the content actually overflows.
    if self._canScroll ~= true then return end
    local id = tostring(self._id or "")
    if id == "" then return end
    local offset = (_G and _G.GetFrameScrollOffset and _G.GetFrameScrollOffset(id)) or 0
    offset = offset + ((delta and delta < 0) and 1 or -1)
    if offset < 0 then offset = 0 end
    if _G and _G.SetFrameScrollOffset then
      _G.SetFrameScrollOffset(id, offset)
    end
    if ns and ns.RefreshAll then
      ns.RefreshAll()
    end
  end)

  f.prefix = f:CreateFontString(nil, "OVERLAY", f._itemFont)
  f.prefix:SetJustifyH("LEFT")
  f.prefix:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -2)
  f.prefix:SetText("")
  f.prefix:Hide()

  return f
end

function TF.CreateListFrame(def)
  local f = CreateContainerFrame(def)
  f._id = def and def.id or nil
  local rh = (def and def.rowHeight) or 16
  local mi = (def and def.maxItems) or 20
  local h = (rh or 16) * ((mi or 20) + 2)
  if type(def) == "table" and tonumber(def.maxHeight) and tonumber(def.maxHeight) > 0 then
    h = math.min(h, tonumber(def.maxHeight))
  end
  f:SetSize(def.width or 300, h)
  local ref = (f.GetParent and f:GetParent()) or UIParent
  do
    local p, rp, x, y = ResolveFrameAnchor(def, "TOPRIGHT")
    f:SetPoint(p, ref or UIParent, rp, x, y)
  end
  TF.ApplyFramePositionFromDef(f, def)
  TF.NudgeFrameOnScreen(f, 8)

  f._itemFont = "GameFontHighlight"
  f.items = {}
  f.buttons = {}

  f._wheelEnabled = ((ns and ns.GetEditMode and ns.GetEditMode()) and true) or ((IsShiftKeyDown and IsShiftKeyDown()) and true or false)
  f:EnableMouseWheel(f._wheelEnabled)
  f:SetScript("OnMouseWheel", function(self, delta)
    if not ((ns and ns.GetEditMode and ns.GetEditMode()) or (IsShiftKeyDown and IsShiftKeyDown())) then return end
    -- Only allow scrolling when the content actually overflows.
    if self._canScroll ~= true then return end
    local id = tostring(self._id or "")
    if id == "" then return end
    local offset = (_G and _G.GetFrameScrollOffset and _G.GetFrameScrollOffset(id)) or 0
    offset = offset + ((delta and delta < 0) and 1 or -1)
    if offset < 0 then offset = 0 end
    local maxOffset = tonumber(self._maxScrollOffset)
    if maxOffset and maxOffset >= 0 and offset > maxOffset then
      offset = maxOffset
    end
    if _G and _G.SetFrameScrollOffset then
      _G.SetFrameScrollOffset(id, offset)
    end
    if ns and ns.RefreshAll then
      ns.RefreshAll()
    end
  end)

  return f
end
