local addonName, ns = ...

-- Rules define WHAT you want tracked.
-- Each rule can appear in a "bar" or a "list" frame (or both by duplicating the rule).
--
-- Fields:
--   questID (number?)          - quest to track; if set, hides when quest completes
--   display ("bar"|"list")     - default routing (used if no explicit frame target)
--   frameID (string?)          - route ONLY to this frame id (e.g. "bar1" or "list1")
--   targets (string[]?)        - route to multiple frame ids
--   label (string?)            - override label (otherwise uses quest title)
--   hideWhenCompleted (boolean?) - default true; set false to keep showing when completed
--   labelComplete (string?)    - optional label override when completed
--   extraComplete (string?)    - optional extra override when completed (e.g. "X")
--   showXWhenComplete (boolean?) - convenience; if true, shows "X" when completed (unless extraComplete is set)
--   prereq (number[]?)         - only show once these quests are completed
--   requireInLog (boolean?)    - if true, only show while the quest is in your quest log
--   group (string?)            - sequential group; only lowest-order active rule shows per frame
--   order (number?)            - used within group; lower shows first
--   levelGate ("max"|"leveling"?) - optionally show only at max level or only while leveling
--   indicators (table[]?)      - append small red/green glyphs after the row (for "done" markers)
--       questID (number?)      - completion source: quest completed
--       questIDs (number[]?)   - completion source: any quest completed in list
--       itemID (number?)       - completion source: have item count
--       count (number?)        - required count for itemID (default 1)
--       aura (table?)          - completion source: aura present
--           spellID (number)
--       shape ("square"|"circle"?) - default "square"
--       faction ("Alliance"|"Horde"?) - optional faction gate for that indicator
--   item (table?)              - item-based tracking gate/progress
--       itemID (number)
--       required (number?)     - display count/required if provided
--       mustHave (boolean?)    - if true, only show when count > 0
--   progress (table?)          - progress display helpers
--       objectiveIndex (number?) - show quest objective progress like "1/5"
--   aura (table?)              - aura gate (Timewalking etc)
--       spellID (number)
--       mustHave (boolean?)    - if true, only show when aura is present
--       rememberWeekly (boolean?) - if true, remembers the aura "active" until weekly reset once seen
--   complete (table?)          - extra completion logic; when satisfied, the rule hides
--       questID (number?)
--       item (table?)
--           itemID (number)
--           count (number?)
--       profession (number|string?) - skillLineID or profession name
--       aura (table?)
--           spellID (number)
--           mustHave (boolean?)
--
-- Examples below are placeholders; replace with your real questIDs/items/auras.

ns.rules = {
  -- Timewalking weekly bar entries.
  -- Goal: show ONLY when that Timewalking aura is active (and once seen, remember until weekly reset).
  -- Keep showing after completion, and show "X" when complete.
  -- Append a red/green marker for the token quest completion.

  -- Classic
  {
    questID = 86731,
    frameID = "bar1",
    label = "TW Classic (Max)",
    levelGate = "max",
    aura = { spellID = 452307, mustHave = true, rememberWeekly = true },
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
    indicators = { { questID = 83285, shape = "square" } },
  },
  {
    questID = 85947,
    frameID = "bar1",
    label = "TW Classic (Leveling)",
    levelGate = "leveling",
    aura = { spellID = 452307, mustHave = true, rememberWeekly = true },
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
    indicators = { { questID = 83285, shape = "square" } },
  },

  -- Outland
  {
    questID = 83363,
    frameID = "bar1",
    label = "TW Outland (Max)",
    levelGate = "max",
    aura = { spellID = 335148, mustHave = true, rememberWeekly = true },
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
    indicators = { { questID = 40168, shape = "square" } },
  },
  {
    questID = 85948,
    frameID = "bar1",
    label = "TW Outland (Leveling)",
    levelGate = "leveling",
    aura = { spellID = 335148, mustHave = true, rememberWeekly = true },
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
    indicators = { { questID = 40168, shape = "square" } },
  },

  -- Wrath
  {
    questID = 83365,
    frameID = "bar1",
    label = "TW Wrath (Max)",
    levelGate = "max",
    aura = { spellID = 335149, mustHave = true, rememberWeekly = true },
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
    indicators = { { questID = 40173, shape = "square" } },
  },
  {
    questID = 85949,
    frameID = "bar1",
    label = "TW Wrath (Leveling)",
    levelGate = "leveling",
    aura = { spellID = 335149, mustHave = true, rememberWeekly = true },
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
    indicators = { { questID = 40173, shape = "square" } },
  },

  -- Cataclysm (token quest differs by faction)
  {
    questID = 83359,
    frameID = "bar1",
    label = "TW Cataclysm (Max)",
    levelGate = "max",
    aura = { spellID = 335150, mustHave = true, rememberWeekly = true },
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
    indicators = { { questIDs = { 40787, 40786 }, shape = "square" } },
  },
  {
    questID = 86556,
    frameID = "bar1",
    label = "TW Cataclysm (Leveling)",
    levelGate = "leveling",
    aura = { spellID = 335150, mustHave = true, rememberWeekly = true },
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
    indicators = { { questIDs = { 40787, 40786 }, shape = "square" } },
  },

  -- Pandaria
  {
    questID = 83362,
    frameID = "bar1",
    label = "TW Pandaria (Max)",
    levelGate = "max",
    aura = { spellID = 335151, mustHave = true, rememberWeekly = true },
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
    indicators = { { questID = 45563, shape = "square" } },
  },
  {
    questID = 86560,
    frameID = "bar1",
    label = "TW Pandaria (Leveling)",
    levelGate = "leveling",
    aura = { spellID = 335151, mustHave = true, rememberWeekly = true },
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
    indicators = { { questID = 45563, shape = "square" } },
  },

  -- Draenor (token reward differs by faction; using item possession as marker)
  {
    questID = 83364,
    frameID = "bar1",
    label = "TW Draenor (Max)",
    levelGate = "max",
    aura = { spellID = 335152, mustHave = true, rememberWeekly = true },
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
    indicators = {
      { itemID = 167921, count = 1, faction = "Alliance", shape = "square" },
      { itemID = 167922, count = 1, faction = "Horde", shape = "square" },
    },
  },
  {
    questID = 86563,
    frameID = "bar1",
    label = "TW Draenor (Leveling)",
    levelGate = "leveling",
    aura = { spellID = 335152, mustHave = true, rememberWeekly = true },
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
    indicators = {
      { itemID = 167921, count = 1, faction = "Alliance", shape = "square" },
      { itemID = 167922, count = 1, faction = "Horde", shape = "square" },
    },
  },

  -- Legion
  {
    questID = 83360,
    frameID = "bar1",
    label = "TW Legion (Max)",
    levelGate = "max",
    aura = { spellID = 359082, mustHave = true, rememberWeekly = true },
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
    indicators = { { questID = 64710, shape = "square" } },
  },
  {
    questID = 86564,
    frameID = "bar1",
    label = "TW Legion (Leveling)",
    levelGate = "leveling",
    aura = { spellID = 359082, mustHave = true, rememberWeekly = true },
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
    indicators = { { questID = 64710, shape = "square" } },
  },

  -- Battle for Azeroth (token quest differs by faction)
  {
    questID = 88805,
    frameID = "bar1",
    label = "TW BFA (Max)",
    levelGate = "max",
    aura = { spellID = 1223878, mustHave = true, rememberWeekly = true },
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
    indicators = { { questIDs = { 89222, 89223 }, shape = "square" } },
  },
  {
    questID = 88808,
    frameID = "bar1",
    label = "TW BFA (Leveling)",
    levelGate = "leveling",
    aura = { spellID = 1223878, mustHave = true, rememberWeekly = true },
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
    indicators = { { questIDs = { 89222, 89223 }, shape = "square" } },
  },

  -- Shadowlands (single weekly listed)
  {
    questID = 92647,
    frameID = "bar1",
    label = "TW Shadowlands (Max)",
    levelGate = "max",
    aura = { spellID = 1256081, mustHave = true, rememberWeekly = true },
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
    indicators = { { questID = 92650, shape = "square" } },
  },
  {
    questID = 92647, -- TODO: replace with the leveling variant questID if different
    frameID = "bar1",
    label = "TW Shadowlands (Leveling)",
    levelGate = "leveling",
    aura = { spellID = 1256081, mustHave = true, rememberWeekly = true },
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
    indicators = { { questID = 92650, shape = "square" } },
  },
}

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
ns.frames = {
  {
    id = "bar1",
    type = "bar",
    point = "TOPLEFT",
    relPoint = "TOPLEFT",
    x = 0,
    y = 0,
    height = 20,
    maxItems = 6,
    bgAlpha = 0,
    stretchWidth = true,
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
    point = "TOPRIGHT",
    relPoint = "TOPRIGHT",
    x = -10,
    y = -120,
    width = 300,
    rowHeight = 16,
    maxItems = 20,
    autoSize = true,
  },
}
