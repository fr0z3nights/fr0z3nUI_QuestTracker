local addonName, ns = ...

-- Rules define WHAT you want tracked.
-- Each rule can appear in a "bar" or a "list" frame (or both by duplicating the rule).
--
-- Fields:
--   questID (number)           - quest to track
--   display ("bar"|"list")     - default routing (used if no explicit frame target)
--   frameID (string?)          - route ONLY to this frame id (e.g. "bar1" or "list1")
--   targets (string[]?)        - route to multiple frame ids
--   label (string?)            - override label (otherwise uses quest title)
--   prereq (number[]?)         - only show once these quests are completed
--   item (table?)              - item-based tracking gate/progress
--       itemID (number)
--       required (number?)     - display count/required if provided
--       mustHave (boolean?)    - if true, only show when count > 0
--   aura (table?)              - aura gate (Timewalking etc)
--       spellID (number)
--       mustHave (boolean?)    - if true, only show when aura is present
--
-- Examples below are placeholders; replace with your real questIDs/items/auras.

ns.rules = {
  -- Example: show a quest on the top-right bar (only after a prereq is done)
  {
    questID = 12345,
    frameID = "bar1",
    label = "Example Bar Quest",
    prereq = { 12344 },
  },

  -- Example: show in list only while a Timewalking aura is up
  {
    questID = 54321,
    frameID = "list1",
    label = "Timewalking Quest",
    aura = { spellID = 335150, mustHave = true },
  },

  -- Example: item-driven tracker (e.g. collect items in bags)
  {
    questID = 99999,
    frameID = "list1",
    label = "Collect Items (Example)",
    item = { itemID = 6948, required = 1, mustHave = true },
  },

  -- Example: one quest shown in BOTH a bar and a list
  {
    questID = 11111,
    targets = { "bar1", "list1" },
    label = "Shown in both (Example)",
  },
}

-- Frames define HOW it should be shown.
-- You can have more than one bar and/or more than one list.
ns.frames = {
  {
    id = "bar1",
    type = "bar",
    point = "TOPRIGHT",
    relPoint = "TOPRIGHT",
    x = -10,
    y = -10,
    width = 300,
    height = 20,
    maxItems = 6,
  },
  {
    id = "list1",
    type = "list",
    point = "TOPRIGHT",
    relPoint = "TOPRIGHT",
    x = -10,
    y = -120,
    width = 300,
    rowHeight = 16,
    maxItems = 20,
  },
}
