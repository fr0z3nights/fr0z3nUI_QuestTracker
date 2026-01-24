-- Layout Defaults
--
-- This file intentionally contains UI/frame layout defaults (not quest rules).
-- Keeping layout separate makes the XP* rule databases easier to detach/replace.

local _, ns = ...

-- Frames define HOW it should be shown.
-- You can have more than one bar and/or more than one list.
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
    point = "CENTER",
    relPoint = "CENTER",
    x = 0,
    y = 0,
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
    hideFrame = true,
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
