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
--       itemIDs (number[]?)    - completion source: have ANY item in list
--       count (number?)        - required count for itemID (default 1)
--       aura (table?)          - completion source: aura present
--           spellID (number)
--       shape ("square"|"circle"?) - default "square"
--       overlay (table?)       - optional overlay drawn on top of the indicator (e.g. a "1")
--           text (string)      - overlay text
--           color (table?)     - overlay text color {r,g,b[,a]}
--           questID/questIDs/itemID/itemIDs/aura/count/required - condition for overlay visibility
--       onlyWhenDone (boolean?) - if true, indicator only renders when condition is met
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
--       rememberDaily (boolean?) - if true, remembers the aura "active" until daily reset once seen
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
  -- Goal: calendar strings can be generic ("Timewalking Dungeon Event"), so we:
  --   1) show a single generic reminder when any Timewalking/Turbulent Timeways event is up
  --   2) show the specific weekly quest row only once you've actually picked it up (requireInLog)
  -- Keep showing after completion, and show "X" when complete.
  -- Append a red/green marker for the token quest completion.

  {
    key = "tw:reminder",
    frameID = "bar1",
    label = "Timewalking Reminder",
    questInfo = "Timewalking",
    aura = { eventKind = "timewalking", mustHave = true, rememberWeekly = true },
    hideIfRememberedTimewalkingKind = true,
    hideIfAnyQuestInLog = {
      86731, 85947, -- Classic
      83363, 85948, -- Outland
      83365, 85949, -- Wrath
      83359, 86556, -- Cata
      83362, 86560, -- Pandaria
      83364, 86563, -- Draenor
      83360, 86564, -- Legion
      88805, 88808, -- BFA
      92647, -- Shadowlands (max/leveling placeholder)
    },
    hideIfAnyQuestCompleted = {
      86731, 85947, -- Classic
      83363, 85948, -- Outland
      83365, 85949, -- Wrath
      83359, 86556, -- Cata
      83362, 86560, -- Pandaria
      83364, 86563, -- Draenor
      83360, 86564, -- Legion
      88805, 88808, -- BFA
      92647, -- Shadowlands (max/leveling placeholder)
    },
    hideWhenCompleted = false,
  },

  {
    questID = 83366,
    frameID = "bar1",
    label = "World Quest Bonus Event",
    aura = { eventKind = "calendar", keywords = { "World Quest Bonus Event" }, mustHave = true, rememberWeekly = true },
    playerLevelOp = ">=",
    playerLevel = 80,
    requireInLog = false,
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
  },

  {
    key = "event:pvp-brawl:southshore-tarren-mill",
    label = "PvP Brawl: Southshore vs. Tarren Mill",
    aura = { eventKind = "calendar", keywords = { "PvP Brawl: Southshore vs. Tarren Mill" }, mustHave = true, rememberWeekly = true },
    playerLevelOp = ">=",
    playerLevel = 20,
    noAutoDisplay = true,
  },

  {
    key = "event:pvp-brawl:classic-ashran",
    label = "PvP Brawl: Classic Ashran",
    aura = { eventKind = "calendar", keywords = { "PvP Brawl: Classic Ashran" }, mustHave = true, rememberWeekly = true },
    playerLevelOp = ">=",
    playerLevel = 20,
    noAutoDisplay = true,
  },

  {
    key = "event:pvp-brawl:packed-house",
    label = "PvP Brawl: Packed House",
    aura = { eventKind = "calendar", keywords = { "PvP Brawl: Packed House" }, mustHave = true, rememberWeekly = true },
    playerLevelOp = ">=",
    playerLevel = 20,
    noAutoDisplay = true,
  },

  {
    key = "event:pvp-brawl:deep-six",
    label = "PvP Brawl: Deep Six",
    aura = { eventKind = "calendar", keywords = { "PvP Brawl: Deep Six" }, mustHave = true, rememberWeekly = true },
    playerLevelOp = ">=",
    playerLevel = 20,
    noAutoDisplay = true,
  },

  {
    key = "event:winds-of-mysterious-fortune",
    frameID = "bar1",
    label = "Winds of Mysterious Fortune",
    questInfo = "Level Boost",
    aura = { eventKind = "calendar", keywords = { "Winds of Mysterious Fortune" }, mustHave = true, rememberWeekly = true },
    levelGate = "leveling",
    hideWhenCompleted = false,
  },

  {
    key = "event:darkmoon-faire",
    frameID = "bar1",
    label = "Darkmoon Faire",
    questInfo = "Darkmoon",
    aura = { eventKind = "calendar", keywords = { "Darkmoon Faire" }, mustHave = true, rememberDaily = true },
    playerLevelOp = ">=",
    playerLevel = 20,
    hideWhenCompleted = false,
  },

  {
    key = "event:love-is-in-the-air",
    frameID = "bar1",
    label = "Love is in the Air",
    questInfo = "Valentines",
    aura = { eventKind = "calendar", keywords = { "Love is in the Air" }, mustHave = true, rememberDaily = true },
    playerLevelOp = ">=",
    playerLevel = 20,
    hideWhenCompleted = false,
  },

  {
    key = "event:pet-battle-bonus-event",
    frameID = "bar1",
    label = "Pet Battle Bonus Event",
    questInfo = "Pets",
    aura = { eventKind = "calendar", keywords = { "Pet Battle Bonus Event" }, mustHave = true, rememberWeekly = true },
    playerLevelOp = ">=",
    playerLevel = 20,
    hideWhenCompleted = false,
  },

  -- Classic
  {
    questID = 86731,
    frameID = "bar1",
    label = "Timewalking Classic Max",
    questInfo = "Classic",
    twKind = "classic",
    levelGate = "max",
    requireInLog = true,
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
  },
  {
    questID = 85947,
    frameID = "bar1",
    label = "Timewalking Classic Level",
    questInfo = "Classic",
    twKind = "classic",
    levelGate = "leveling",
    requireInLog = true,
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
  },
  {
    key = "tw:token:classic",
    frameID = "bar1",
    label = "Timewalking Classic Token",
    questInfo = "\194\160",
    twKind = "classic",
    requireRememberedTimewalkingKind = true,
    fallbackQuestInLog = { 83285 },
    fallbackItemInBags = { 9999999, 9999999 },
    hideWhenCompleted = false,
    indicators = {
      {
        questID = 83285,
        shape = "square",
        overlay = { itemIDs = { 9999999, 9999999 }, text = "1", color = { 1.0, 1.0, 0.1 } },
      },
    },
  },

  -- Outland
  {
    questID = 83363,
    frameID = "bar1",
    label = "Timewalking Outland Max",
    questInfo = "Outland",
    twKind = "outland",
    levelGate = "max",
    requireInLog = true,
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
  },
  {
    questID = 85948,
    frameID = "bar1",
    label = "Timewalking Outland Level",
    questInfo = "Outland",
    twKind = "outland",
    levelGate = "leveling",
    requireInLog = true,
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
  },
  {
    key = "tw:token:outland",
    frameID = "bar1",
    label = "Timewalking Outland Token",
    questInfo = "\194\160",
    twKind = "outland",
    requireRememberedTimewalkingKind = true,
    fallbackQuestInLog = { 40168 },
    fallbackItemInBags = { 9999999, 9999999 },
    hideWhenCompleted = false,
    indicators = {
      {
        questID = 40168,
        shape = "square",
        overlay = { itemIDs = { 9999999, 9999999 }, text = "1", color = { 1.0, 1.0, 0.1 } },
      },
    },
  },

  -- Wrath
  {
    questID = 83365,
    frameID = "bar1",
    label = "Timewalking Wrath Max",
    questInfo = "Wrath",
    twKind = "wrath",
    levelGate = "max",
    requireInLog = true,
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
  },
  {
    questID = 85949,
    frameID = "bar1",
    label = "Timewalking Wrath Level",
    questInfo = "Wrath",
    twKind = "wrath",
    levelGate = "leveling",
    requireInLog = true,
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
  },
  {
    key = "tw:token:wrath",
    frameID = "bar1",
    label = "Timewalking Wrath Token",
    questInfo = "\194\160",
    twKind = "wrath",
    requireRememberedTimewalkingKind = true,
    fallbackQuestInLog = { 40173 },
    fallbackItemInBags = { 9999999, 9999999 },
    hideWhenCompleted = false,
    indicators = {
      {
        questID = 40173,
        shape = "square",
        overlay = { itemIDs = { 9999999, 9999999 }, text = "1", color = { 1.0, 1.0, 0.1 } },
      },
    },
  },

  -- Cataclysm (token quest differs by faction)
  {
    questID = 83359,
    frameID = "bar1",
    label = "Timewalking Cataclysm Max",
    questInfo = "Cataclysm",
    twKind = "cata",
    levelGate = "max",
    requireInLog = true,
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
  },
  {
    questID = 86556,
    frameID = "bar1",
    label = "Timewalking Cataclysm Level",
    questInfo = "Cataclysm",
    twKind = "cata",
    levelGate = "leveling",
    requireInLog = true,
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
  },
  {
    key = "tw:token:cata",
    frameID = "bar1",
    label = "Timewalking Cataclysm Token",
    questInfo = "\194\160",
    twKind = "cata",
    requireRememberedTimewalkingKind = true,
    fallbackQuestInLog = { 40787, 40786 },
    fallbackItemInBags = { 9999999, 9999999 },
    hideWhenCompleted = false,
    indicators = {
      {
        questIDs = { 40787, 40786 },
        shape = "square",
        overlay = { itemIDs = { 9999999, 9999999 }, text = "1", color = { 1.0, 1.0, 0.1 } },
      },
    },
  },

  -- Pandaria
  {
    questID = 83362,
    frameID = "bar1",
    label = "Timewalking Pandaria Max",
    questInfo = "Pandaria",
    twKind = "pandaria",
    levelGate = "max",
    requireInLog = true,
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
  },
  {
    questID = 86560,
    frameID = "bar1",
    label = "Timewalking Pandaria Level",
    questInfo = "Pandaria",
    twKind = "pandaria",
    levelGate = "leveling",
    requireInLog = true,
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
  },
  {
    key = "tw:token:pandaria",
    frameID = "bar1",
    label = "Timewalking Pandaria Token",
    questInfo = "\194\160",
    twKind = "pandaria",
    requireRememberedTimewalkingKind = true,
    fallbackQuestInLog = { 45563 },
    fallbackItemInBags = { 9999999, 9999999 },
    hideWhenCompleted = false,
    indicators = {
      {
        questID = 45563,
        shape = "square",
        overlay = { itemIDs = { 9999999, 9999999 }, text = "1", color = { 1.0, 1.0, 0.1 } },
      },
    },
  },

  -- Draenor (token reward differs by faction; using item possession as marker)
  {
    questID = 83364,
    frameID = "bar1",
    label = "Timewalking Draenor Max",
    questInfo = "Draenor",
    twKind = "draenor",
    levelGate = "max",
    requireInLog = true,
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
  },
  {
    questID = 86563,
    frameID = "bar1",
    label = "Timewalking Draenor Level",
    questInfo = "Draenor",
    twKind = "draenor",
    levelGate = "leveling",
    requireInLog = true,
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
  },
  {
    key = "tw:token:draenor",
    frameID = "bar1",
    label = "Timewalking Draenor Token",
    questInfo = "\194\160",
    twKind = "draenor",
    requireRememberedTimewalkingKind = true,
    fallbackQuestInLog = { 55498, 55499 },
    fallbackItemInBags = { 167921, 167922 },
    hideWhenCompleted = false,
    indicators = {
      {
        questIDs = { 55498, 55499 },
        shape = "square",
        overlay = { itemIDs = { 167921, 167922 }, text = "1", color = { 1.0, 1.0, 0.1 } },
      },
    },
  },

  -- Legion
  {
    questID = 83360,
    frameID = "bar1",
    label = "Timewalking Legion Max",
    questInfo = "Legion",
    twKind = "legion",
    levelGate = "max",
    requireInLog = true,
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
  },
  {
    questID = 86564,
    frameID = "bar1",
    label = "Timewalking Legion Level",
    questInfo = "Legion",
    twKind = "legion",
    levelGate = "leveling",
    requireInLog = true,
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
  },
  {
    key = "tw:token:legion",
    frameID = "bar1",
    label = "Timewalking Legion Token",
    questInfo = "\194\160",
    twKind = "legion",
    requireRememberedTimewalkingKind = true,
    fallbackQuestInLog = { 64710 },
    fallbackItemInBags = { 9999999, 9999999 },
    hideWhenCompleted = false,
    indicators = {
      {
        questID = 64710,
        shape = "square",
        overlay = { itemIDs = { 9999999, 9999999 }, text = "1", color = { 1.0, 1.0, 0.1 } },
      },
    },
  },

  -- Battle for Azeroth (token quest differs by faction)
  {
    questID = 88805,
    frameID = "bar1",
    label = "Timewalking Battle Max",
    questInfo = "Battle",
    twKind = "bfa",
    levelGate = "max",
    requireInLog = true,
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
  },
  {
    questID = 88808,
    frameID = "bar1",
    label = "Timewalking Battle Level",
    questInfo = "Battle",
    twKind = "bfa",
    levelGate = "leveling",
    requireInLog = true,
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
  },
  {
    key = "tw:token:bfa",
    frameID = "bar1",
    label = "Timewalking Battle Token",
    questInfo = "\194\160",
    twKind = "bfa",
    requireRememberedTimewalkingKind = true,
    fallbackQuestInLog = { 89222, 89223 },
    fallbackItemInBags = { 238790, 238791 },
    hideWhenCompleted = false,
    indicators = {
      {
        questIDs = { 89222, 89223 },
        shape = "square",
        overlay = { itemIDs = { 238790, 238791 }, text = "1", color = { 1.0, 1.0, 0.1 } },
      },
    },
  },

  -- Shadowlands (single weekly listed)
  {
    questID = 92647,
    frameID = "bar1",
    label = "Timewalking Shadowlands Max",
    questInfo = "Shadowlands",
    twKind = "shadowlands",
    levelGate = "max",
    requireInLog = true,
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
  },
  {
    questID = 92647,
    frameID = "bar1",
    label = "Timewalking Shadowlands Level",
    questInfo = "Shadowlands",
    twKind = "shadowlands",
    levelGate = "leveling",
    requireInLog = true,
    progress = { objectiveIndex = 1 },
    hideWhenCompleted = false,
    showXWhenComplete = true,
  },
  {
    key = "tw:token:shadowlands",
    frameID = "bar1",
    label = "Timewalking Shadowlands Token",
    questInfo = "\194\160",
    twKind = "shadowlands",
    requireRememberedTimewalkingKind = true,
    fallbackQuestInLog = { 92650 },
    fallbackItemInBags = { 9999999, 9999999 },
    hideWhenCompleted = false,
    indicators = {
      {
        questID = 92650,
        shape = "square",
        overlay = { itemIDs = { 9999999, 9999999 }, text = "1", color = { 1.0, 1.0, 0.1 } },
      },
    },
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
    hideWhenEmpty = false,
  },
}
