local addonName, ns = ...

local rgbPickerFrame

local SaveWindowPosition = ns.SaveWindowPosition
local RestoreWindowPosition = ns.RestoreWindowPosition
local ApplyFAOBackdrop = ns.ApplyFAOBackdrop

local function Clamp01(v)
  v = tonumber(v)
  if v == nil then return 0 end
  if v < 0 then return 0 end
  if v > 1 then return 1 end
  return v
end

local function ColorHex(r, g, b)
  r = tonumber(r) or 0
  g = tonumber(g) or 0
  b = tonumber(b) or 0
  if r < 0 then r = 0 elseif r > 1 then r = 1 end
  if g < 0 then g = 0 elseif g > 1 then g = 1 end
  if b < 0 then b = 0 elseif b > 1 then b = 1 end
  return string.format("%02x%02x%02x", math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

local function FormatLuaRGB(r, g, b)
  return string.format("{ %.3f, %.3f, %.3f }", Clamp01(r), Clamp01(g), Clamp01(b))
end

local function OpenColorPicker(r, g, b, onChanged)
  r, g, b = Clamp01(r), Clamp01(g), Clamp01(b)
  if not ColorPickerFrame then
    if type(onChanged) == "function" then onChanged(r, g, b) end
    return
  end

  -- Dragonflight+ API
  if ColorPickerFrame.SetupColorPickerAndShow then
    local info = {
      swatchFunc = function()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        if type(onChanged) == "function" then onChanged(nr, ng, nb) end
      end,
      cancelFunc = function(prev)
        if type(prev) == "table" and prev.r and prev.g and prev.b then
          if type(onChanged) == "function" then onChanged(prev.r, prev.g, prev.b) end
        end
      end,
      r = r,
      g = g,
      b = b,
      hasOpacity = false,
    }
    ColorPickerFrame:SetupColorPickerAndShow(info)
    return
  end

  -- Legacy API
  ---@diagnostic disable-next-line: duplicate-set-field
  ColorPickerFrame.func = function()
    local nr, ng, nb = ColorPickerFrame:GetColorRGB()
    if type(onChanged) == "function" then onChanged(nr, ng, nb) end
  end
  ---@diagnostic disable-next-line: duplicate-set-field
  ColorPickerFrame.cancelFunc = function(prev)
    if type(prev) == "table" and prev.r and prev.g and prev.b then
      if type(onChanged) == "function" then onChanged(prev.r, prev.g, prev.b) end
    end
  end
  ColorPickerFrame.hasOpacity = false
  ColorPickerFrame.previousValues = { r = r, g = g, b = b }
  ColorPickerFrame:SetColorRGB(r, g, b)
  ColorPickerFrame:Show()
end

local function EnsureRGBPickerFrame()
  if rgbPickerFrame then return rgbPickerFrame end

  local f = CreateFrame("Frame", "FR0Z3NUIFQTRGBPicker", UIParent, "BackdropTemplate")
  f:SetSize(420, 170)
  f:SetPoint("CENTER")
  f:SetFrameStrata("DIALOG")
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:EnableMouse(true)
  if RestoreWindowPosition then
    RestoreWindowPosition("rgbPicker", f, "CENTER", "CENTER", 0, 0)
  end
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", function(self)
    if self.StopMovingOrSizing then self:StopMovingOrSizing() end
    if SaveWindowPosition then
      SaveWindowPosition("rgbPicker", self)
    end
  end)
  if ApplyFAOBackdrop then
    ApplyFAOBackdrop(f, 0.90)
  end

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", 12, -10)
  title:SetText("|cff00ccff[FQT]|r RGB Picker")

  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", f, "TOPRIGHT", 2, 2)

  local swatch = CreateFrame("Button", nil, f, "BackdropTemplate")
  swatch:SetSize(28, 28)
  swatch:SetPoint("TOPLEFT", 14, -36)
  swatch:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
  })
  swatch:SetBackdropColor(1, 1, 1, 1)

  local function CreateSmallBox(parent, labelText)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetText(labelText)
    local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    eb:SetSize(52, 18)
    eb:SetAutoFocus(false)
    eb:SetJustifyH("CENTER")
    return lbl, eb
  end

  local lr, er = CreateSmallBox(f, "R (0-255)")
  local lg, eg = CreateSmallBox(f, "G")
  local lb, eb = CreateSmallBox(f, "B")

  lr:SetPoint("TOPLEFT", swatch, "TOPRIGHT", 14, 6)
  er:SetPoint("TOPLEFT", lr, "BOTTOMLEFT", -6, -2)

  lg:SetPoint("LEFT", lr, "RIGHT", 70, 0)
  eg:SetPoint("TOPLEFT", lg, "BOTTOMLEFT", -6, -2)

  lb:SetPoint("LEFT", lg, "RIGHT", 70, 0)
  eb:SetPoint("TOPLEFT", lb, "BOTTOMLEFT", -6, -2)

  local outLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  outLbl:SetPoint("TOPLEFT", swatch, "BOTTOMLEFT", 0, -16)
  outLbl:SetText("Output (copy into rule):")

  local out = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
  out:SetSize(390, 20)
  out:SetPoint("TOPLEFT", outLbl, "BOTTOMLEFT", -6, -2)
  out:SetAutoFocus(false)
  out:SetJustifyH("LEFT")

  local out2 = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
  out2:SetSize(390, 20)
  out2:SetPoint("TOPLEFT", out, "BOTTOMLEFT", 0, -6)
  out2:SetAutoFocus(false)
  out2:SetJustifyH("LEFT")

  local help = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  help:SetPoint("TOPLEFT", out2, "BOTTOMLEFT", 6, -8)
  help:SetText("Use as: color = { r, g, b }   (or paste hex)")

  local function GetRGB255()
    local r = tonumber(er:GetText() or "") or 255
    local g = tonumber(eg:GetText() or "") or 255
    local b = tonumber(eb:GetText() or "") or 255
    if r < 0 then r = 0 elseif r > 255 then r = 255 end
    if g < 0 then g = 0 elseif g > 255 then g = 255 end
    if b < 0 then b = 0 elseif b > 255 then b = 255 end
    return r, g, b
  end

  local function SetRGB255(r, g, b)
    r = tonumber(r) or 255
    g = tonumber(g) or 255
    b = tonumber(b) or 255
    if r < 0 then r = 0 elseif r > 255 then r = 255 end
    if g < 0 then g = 0 elseif g > 255 then g = 255 end
    if b < 0 then b = 0 elseif b > 255 then b = 255 end
    er:SetText(tostring(math.floor(r + 0.5)))
    eg:SetText(tostring(math.floor(g + 0.5)))
    eb:SetText(tostring(math.floor(b + 0.5)))
  end

  local function RefreshOutput()
    local r, g, b = GetRGB255()
    swatch:SetBackdropColor(r / 255, g / 255, b / 255, 1)
    local rr, gg, bb = r / 255, g / 255, b / 255
    local hex = ColorHex(rr, gg, bb)
    out:SetText("color = " .. FormatLuaRGB(rr, gg, bb))
    out2:SetText("color = \"#" .. hex .. "\"")
  end

  local function OnAnyChanged()
    RefreshOutput()
  end

  er:SetScript("OnTextChanged", OnAnyChanged)
  eg:SetScript("OnTextChanged", OnAnyChanged)
  eb:SetScript("OnTextChanged", OnAnyChanged)

  swatch:SetScript("OnClick", function()
    local r, g, b = GetRGB255()
    OpenColorPicker(r / 255, g / 255, b / 255, function(nr, ng, nb)
      SetRGB255(nr * 255, ng * 255, nb * 255)
      RefreshOutput()
    end)
  end)

  SetRGB255(255, 255, 255)
  RefreshOutput()

  rgbPickerFrame = f
  return f
end

ns.ShowRGBPicker = function()
  local f = EnsureRGBPickerFrame()
  f:Show()
  if f.Raise then f:Raise() end
end
