local addonName, ns = ...

local Y, N = true, false

local WHITE = "ffffff"
local RED = "ff4040"
local ORANGE = "ff8c1a"
local YELLOW = "ffe633"
local GREEN = "33ff33"
local BLUE = "3399ff"
local PURPLE = "9933ff"
local CYAN = "33ffff"
local GREY = "bfbfbf"

-- Currency gates (optional):
--   item.currencyID = { currencyID, required }
-- Amount sources (Retail):
--   Character amount: C_CurrencyInfo.GetCurrencyInfo(id).quantity
--   Warband total: C_CurrencyInfo.GetAccountCharacterCurrencyData(id)
--     (requires RequestCurrencyDataForAccountCharacters() to be called earlier)
--   Transferability: C_CurrencyInfo.GetCurrencyInfo(id).isAccountTransferable
-- Notes:
--   If isAccountTransferable is true, the tracker gates using the warband total (falls back to a cached
--   account saved-variable snapshot if the live data isn't available yet).
-- Placeholders usable in itemInfo/textInfo/spellInfo:
--   {currency:name} {currency:req} {currency:char} {currency:wb} {currency} (gate amount)
-- Shorthand (DB convenience):
--   %p  -> {progress}
--   $rq -> {currency:req}
--   $nm -> {currency:name}
--   $hv -> {currency} (gate/have amount)
--   $ga -> {currency} (gate/have amount)
--   $cc -> {currency:char}
--   $wb -> {currency:wb}


-- item.required tuple keys:
--   item.required = { count, hideWhenAcquired, autoBuyEnabled, autoBuyMax }
local REQ_COUNT, REQ_HIDE, REQ_BUY_ON, REQ_BUY_MAX = 1, 2, 3, 4
-- Rules define WHAT you want tracked.
-- Each rule can appear in a "bar" or a "list" frame (or both by duplicating the rule).
--
-- Fields:
--   questID (number?)          - quest to track; if set, hides when quest completes
--   display ("bar"|"list")     - default routing (used if no explicit frame target)
--   frameID (string?)          - route ONLY to this frame id (e.g. "bar1" or "list1")
--   targets (string[]?)        - route to multiple frame ids
--   label (string?)            - override label (otherwise uses quest title)
--   hideDone (boolean?) - default true; set false to keep showing when completed
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





  {label = "Event: Pet Battle", frameID = "bar1", playerLevel = { ">=", 20 }, hideDone = false, key = "event:pet-battle-bonus-event",
  questInfo = "Pet XP", aura = { eventKind = "calendar", keywords = { "Pet Battle Bonus Event" }, mustHave = true, rememberWeekly = true }, },

  {label = "Event: Delves", frameID = "bar1", playerLevel = { ">=", 80 }, hideDone = false, key = "event:delves-bonus-event",
  questInfo = "Delves", questID = 93595, progress = { objectiveIndex = 1 },  aura = { eventKind = "calendar", keywords = { "Delves Bonus Event" }, mustHave = true, rememberWeekly = true }, },

  {label = "Event: World Quest", frameID = "bar1", playerLevel = { ">=", 90 }, hideDone = false, requireInLog = false, showXWhenComplete = true,
  questInfo = "WQ", questID = 93605, progress = { objectiveIndex = 1 },  aura = { eventKind = "calendar", keywords = { "World Quest Bonus Event" }, mustHave = true, rememberWeekly = true }, },

  {label = "Event: Battleground", frameID = "bar1", playerLevel = { ">=", 80 }, hideDone = false, requireInLog = false, showXWhenComplete = true,
  questInfo = "BG", questID = 93605, progress = { objectiveIndex = 1 },  aura = { eventKind = "calendar", keywords = { "Battleground Bonus Event" }, mustHave = true, rememberWeekly = true }, },



  -- Timewalking weekly bar entries.
  -- Goal: calendar strings can be generic ("Timewalking Dungeon Event"), so we:
  --   1) show a single generic reminder when any Timewalking/Turbulent Timeways event is up
  --   2) show the specific weekly quest row only once you've actually picked it up (requireInLog)
  -- Keep showing after completion, and show "X" when complete.
  -- Append a red/green marker for the token quest completion.

  {label = "TW Reminder", frameID = "bar1", key = "tw:reminder", 
  questInfo = "Timewalking", preferQuestInfoForTitle = true, hideIfRememberedTimewalkingKind = true,
  aura = { eventKind = "timewalking", mustHave = true, rememberWeekly = true }, hideDone = false,
  --                            CLASSIC        OUTLAND          WRATH         CATACLYSM        PANDARIA        DRAENOR          LEGION          BATTLE       SHADOWLANDS     DRGONFLIGHT
  --                         LVL  01  MAX    LVL  02  MAX    LVL  03  MAX    LVL  04  MAX    LVL  05  MAX    LVL  06  MAX    LVL  07  MAX    LVL  08  MAX    LVL  09  MAX    LVL  10  MAX
  hideIfAnyQuestInLog =     {85947, 93607,   85948, 93608,   85949, 93610,   86556, 83359,   86560, 93612,   86563, 93613,   86564, 93614,   88808, 93627,   92647, 93628,   93495, 93497},
  hideQID =                 {85947, 93607,   85948, 93608,   85949, 93610,   86556, 83359,   86560, 93612,   86563, 93613,   86564, 93614,   88808, 93627,   92647, 93628,   93495, 93497}, },

--  01  Classic              UPDATE REMINDER ABOVE & XRULESDB & GOTALKEV & IN GAME WoW2 FQT ORDER WHEN UPDATING QUESTID

  {label = "TW Classic LVL", frameID = "bar1", key = "XP01:TW:LVL", sortGroup = "XP01:TW", sortOrder = 1, levelGate = "LVL", progress = { objectiveIndex = 1 }, showXWhenComplete = true,
  questID = 85947, questInfo = "Classic", requireInLog = true, twKind = "classic", hideDone = false, showIfRememberedTimewalkingKind = true, },

  {label = "TW Classic MAX", frameID = "bar1", key = "XP01:TW:MAX", sortGroup = "XP01:TW", sortOrder = 2, levelGate = "MAX", progress = { objectiveIndex = 1 }, showXWhenComplete = true,
  questID = 93607, questInfo = "Classic", requireInLog = true, twKind = "classic", hideDone = false, showIfRememberedTimewalkingKind = true, },

  {label = "TW Classic TKN", frameID = "bar1", key = "XP01:TW:TKN", sortGroup = "XP01:TW", sortOrder = 3, requireRememberedTimewalkingKind = true,
  questInfo = "\194\160", fallbackQuestInLog = { 83285 }, preferQuestInfoForTitle = true, twKind = "classic", hideDone = false,
  indicators = { { questID = 83285, shape = "square", overlay = { itemIDs = { 225348 }, text = "1", color = { 1.0, 1.0, 0.1 } }, }, }, },

--  02  Outland             UPDATE REMINDER ABOVE & XRULESDB & GOTALKEV & IN GAME WoW2 FQT ORDER WHEN UPDATING QUESTID

  {label = "TW Outland LVL", frameID = "bar1", key = "XP02:TW:LVL", sortGroup = "XP02:TW", sortOrder = 1, levelGate = "LVL", progress = { objectiveIndex = 1 }, showXWhenComplete = true,
  questID = 85948, questInfo = "Outland", requireInLog = true, twKind = "outland", hideDone = false, showIfRememberedTimewalkingKind = true, },

  {label = "TW Outland MAX", frameID = "bar1", key = "XP02:TW:MAX", sortGroup = "XP02:TW", sortOrder = 2, levelGate = "MAX", progress = { objectiveIndex = 1 }, showXWhenComplete = true,
  questID = 93608, questInfo = "Outland", requireInLog = true, twKind = "outland", hideDone = false, showIfRememberedTimewalkingKind = true, },

  {label = "TW Outland TKN", frameID = "bar1", key = "XP02:TW:TKN", sortGroup = "XP02:TW", sortOrder = 3, requireRememberedTimewalkingKind = true,
  questInfo = "\194\160", fallbackQuestInLog = { 40168 }, preferQuestInfoForTitle = true, twKind = "outland", hideDone = false,
  indicators = { { questID = 40168, shape = "square", overlay = { itemIDs = { 129747 }, text = "1", color = { 1.0, 1.0, 0.1 } }, }, }, },

--  03  Wrath               UPDATE REMINDER ABOVE & XRULESDB & GOTALKEV & IN GAME WoW2 FQT ORDER WHEN UPDATING QUESTID

  {label = "TW Wrath LVL", frameID = "bar1", key = "XP03:TW:LVL", sortGroup = "XP03:TW", sortOrder = 1, levelGate = "LVL", progress = { objectiveIndex = 1 }, showXWhenComplete = true,
  questID = 85949, questInfo = "Wrath", requireInLog = true, twKind = "wrath", hideDone = false, showIfRememberedTimewalkingKind = true, },

  {label = "TW Wrath MAX", frameID = "bar1", key = "XP03:TW:MAX", sortGroup = "XP03:TW", sortOrder = 2, levelGate = "MAX", progress = { objectiveIndex = 1 }, showXWhenComplete = true,
  questID = 93610, questInfo = "Wrath", requireInLog = true, twKind = "wrath", hideDone = false, showIfRememberedTimewalkingKind = true, },

  {label = "TW Wrath TKN", frameID = "bar1", key = "XP03:TW:TKN", sortGroup = "XP03:TW", sortOrder = 3, requireRememberedTimewalkingKind = true,
  questInfo = "\194\160", fallbackQuestInLog = { 40173 }, preferQuestInfoForTitle = true, twKind = "wrath", hideDone = false,
  indicators = { { questID = 40173, shape = "square", overlay = { itemIDs = { 129928 }, text = "1", color = { 1.0, 1.0, 0.1 } }, }, }, },

--  04  Cataclysm           UPDATE REMINDER ABOVE & XRULESDB & GOTALKEV & IN GAME WoW2 FQT ORDER WHEN UPDATING QUESTID

  {label = "TW Cataclysm LVL", frameID = "bar1", key = "XP04:TW:LVL", sortGroup = "XP04:TW", sortOrder = 1, levelGate = "LVL", progress = { objectiveIndex = 1 }, showXWhenComplete = true,
  questID = 86556, questInfo = "Cataclysm", requireInLog = true, twKind = "cata", hideDone = false, showIfRememberedTimewalkingKind = true, },

  {label = "TW Cataclysm MAX", frameID = "bar1", key = "XP04:TW:MAX", sortGroup = "XP04:TW", sortOrder = 2, levelGate = "MAX", progress = { objectiveIndex = 1 }, showXWhenComplete = true,
  questID = 83359, questInfo = "Cataclysm", requireInLog = true, twKind = "cata", hideDone = false, showIfRememberedTimewalkingKind = true, },

  {label = "TW Cataclysm TKN", frameID = "bar1", key = "XP04:TW:TKN", sortGroup = "XP04:TW", sortOrder = 3, requireRememberedTimewalkingKind = true,
  questInfo = "\194\160", fallbackQuestInLog = { 40787, 40786 }, preferQuestInfoForTitle = true, twKind = "cata", hideDone = false,
  indicators = { { questIDs = { 40787, 40786 }, shape = "square", overlay = { itemIDs = { 133377 }, text = "1", color = { 1.0, 1.0, 0.1 } }, }, }, },

--  05  Pandaria           UPDATE REMINDER ABOVE & XRULESDB & GOTALKEV & IN GAME WoW2 FQT ORDER WHEN UPDATING QUESTID

  {label = "TW Pandaria LVL", frameID = "bar1", key = "XP05:TW:LVL", sortGroup = "XP05:TW", sortOrder = 1, levelGate = "LVL", progress = { objectiveIndex = 1 }, showXWhenComplete = true,
  questID = 86560, questInfo = "Pandaria", requireInLog = true, twKind = "pandaria", hideDone = false, showIfRememberedTimewalkingKind = true, },

  {label = "TW Pandaria MAX", frameID = "bar1", key = "XP05:TW:MAX", sortGroup = "XP05:TW", sortOrder = 2, levelGate = "MAX", progress = { objectiveIndex = 1 }, showXWhenComplete = true,
  questID = 93612, questInfo = "Pandaria", requireInLog = true, twKind = "pandaria", hideDone = false, showIfRememberedTimewalkingKind = true, },

  {label = "TW Pandaria TKN", frameID = "bar1", key = "XP05:TW:TKN", sortGroup = "XP05:TW", sortOrder = 3, requireRememberedTimewalkingKind = true,
  questInfo = "\194\160", fallbackQuestInLog = { 45563 }, preferQuestInfoForTitle = true, twKind = "pandaria", hideDone = false,
  indicators = { { questID = 45563, shape = "square", overlay = { itemIDs = { 143776 }, text = "1", color = { 1.0, 1.0, 0.1 } }, }, }, },

--  06  Draenor            UPDATE REMINDER ABOVE & XRULESDB & GOTALKEV & IN GAME WoW2 FQT ORDER WHEN UPDATING QUESTID

  {label = "TW Draenor LVL", frameID = "bar1", key = "XP06:TW:LVL", sortGroup = "XP06:TW", sortOrder = 1, levelGate = "LVL", progress = { objectiveIndex = 1 }, showXWhenComplete = true,
  questID = 86563, questInfo = "Draenor", requireInLog = true, twKind = "draenor", hideDone = false, showIfRememberedTimewalkingKind = true, },

  {label = "TW Draenor MAX", frameID = "bar1", key = "XP06:TW:MAX", sortGroup = "XP06:TW", sortOrder = 2, levelGate = "MAX", progress = { objectiveIndex = 1 }, showXWhenComplete = true,
  questID = 93613, questInfo = "Draenor", requireInLog = true, twKind = "draenor", hideDone = false, showIfRememberedTimewalkingKind = true, },

  {label = "TW Draenor TKN", frameID = "bar1", key = "XP06:TW:TKN", sortGroup = "XP06:TW", sortOrder = 3, requireRememberedTimewalkingKind = true,
  questInfo = "\194\160", fallbackQuestInLog = { 55498, 55499 }, preferQuestInfoForTitle = true, twKind = "draenor", hideDone = false,
  indicators = { { questIDs = { 55498, 55499 }, shape = "square", overlay = { itemIDs = { 167921, 167922 }, text = "1", color = { 1.0, 1.0, 0.1 } }, }, }, },

--  07  Legion            UPDATE REMINDER ABOVE & XRULESDB & GOTALKEV & IN GAME WoW2 FQT ORDER WHEN UPDATING QUESTID

  {label = "TW Legion LVL", frameID = "bar1", key = "XP07:TW:LVL", sortGroup = "XP07:TW", sortOrder = 1, levelGate = "LVL", progress = { objectiveIndex = 1 }, showXWhenComplete = true,
  questID = 86564, questInfo = "Legion", requireInLog = true, twKind = "legion", hideDone = false, showIfRememberedTimewalkingKind = true, },

  {label = "TW Legion MAX", frameID = "bar1", key = "XP07:TW:MAX", sortGroup = "XP07:TW", sortOrder = 2, levelGate = "MAX", progress = { objectiveIndex = 1 }, showXWhenComplete = true,
  questID = 93614, questInfo = "Legion", requireInLog = true, twKind = "legion", hideDone = false, showIfRememberedTimewalkingKind = true, },

  {label = "TW Legion TKN", frameID = "bar1", key = "XP07:TW:TKN", sortGroup = "XP07:TW", sortOrder = 3, requireRememberedTimewalkingKind = true,
  questInfo = "\194\160", fallbackQuestInLog = { 64710 }, preferQuestInfoForTitle = true, twKind = "legion", hideDone = false,
  indicators = { { questID = 64710, shape = "square", overlay = { itemIDs = { 187611 }, text = "1", color = { 1.0, 1.0, 0.1 } }, }, }, },

--  08  Battle             UPDATE REMINDER ABOVE & XRULESDB & GOTALKEV & IN GAME WoW2 FQT ORDER WHEN UPDATING QUESTID

  {label = "TW Battle LVL", frameID = "bar1", key = "XP08:TW:LVL", sortGroup = "XP08:TW", sortOrder = 1, levelGate = "LVL", progress = { objectiveIndex = 1 }, showXWhenComplete = true,
  questID = 88808, questInfo = "Battle", requireInLog = true, twKind = "bfa", hideDone = false, showIfRememberedTimewalkingKind = true, },

  {label = "TW Battle MAX", frameID = "bar1", key = "XP08:TW:MAX", sortGroup = "XP08:TW", sortOrder = 2, levelGate = "MAX", progress = { objectiveIndex = 1 }, showXWhenComplete = true,
  questID = 93627, questInfo = "Battle", requireInLog = true, twKind = "bfa", hideDone = false, showIfRememberedTimewalkingKind = true, },

  {label = "TW Battle TKN", frameID = "bar1", key = "XP08:TW:TKN", sortGroup = "XP08:TW", sortOrder = 3, requireRememberedTimewalkingKind = true,
  questInfo = "\194\160", fallbackQuestInLog = { 89222, 89223 }, preferQuestInfoForTitle = true, twKind = "bfa", hideDone = false,
  indicators = { { questIDs = { 89222, 89223 }, shape = "square", overlay = { itemIDs = { 238790, 238791 }, text = "1", color = { 1.0, 1.0, 0.1 } }, }, }, },

--  09  Shadowlands        UPDATE REMINDER ABOVE & XRULESDB & GOTALKEV & IN GAME WoW2 FQT ORDER WHEN UPDATING LVL/MAX QUESTID

  {label = "TW Shadowlands LVL", frameID = "bar1", key = "XP09:TW:LVL", sortGroup = "XP09:TW", sortOrder = 1, levelGate = "LVL", progress = { objectiveIndex = 1 }, showXWhenComplete = true,
  questID = 92647, questInfo = "Shadowlands", requireInLog = true, twKind = "shadowlands", hideDone = false, showIfRememberedTimewalkingKind = true, },

  {label = "TW Shadowlands MAX", frameID = "bar1", key = "XP09:TW:MAX", sortGroup = "XP09:TW", sortOrder = 2, levelGate = "MAX", progress = { objectiveIndex = 1 }, showXWhenComplete = true,
  questID = 93628, questInfo = "Shadowlands", requireInLog = true, twKind = "shadowlands", hideDone = false, showIfRememberedTimewalkingKind = true, },

  {label = "TW Shadowlands TKN", frameID = "bar1", key = "XP09:TW:TKN", sortGroup = "XP09:TW", sortOrder = 3, requireRememberedTimewalkingKind = true,
  questInfo = "\194\160", fallbackQuestInLog = { 92650 }, preferQuestInfoForTitle = true, twKind = "shadowlands", hideDone = false,
  indicators = { { questID = 92650, shape = "square", overlay = { itemIDs = { 253517 }, text = "1", color = { 1.0, 1.0, 0.1 } }, }, }, },

--  10  Dragonflight        UPDATE REMINDER ABOVE & XRULESDB & GOTALKEV & IN GAME WoW2 FQT ORDER WHEN UPDATING LVL/MAX QUESTID

  {label = "TW Dragonflight LVL", frameID = "bar1", key = "XP10:TW:LVL", sortGroup = "XP10:TW", sortOrder = 1, levelGate = "LVL", progress = { objectiveIndex = 1 }, showXWhenComplete = true,
  questID = 93495, questInfo = "Dragonflight", requireInLog = true, twKind = "dragonflight", hideDone = false, showIfRememberedTimewalkingKind = true, },

  {label = "TW Dragonflight MAX", frameID = "bar1", key = "XP10:TW:MAX", sortGroup = "XP10:TW", sortOrder = 2, levelGate = "MAX", progress = { objectiveIndex = 1 }, showXWhenComplete = true,
  questID = 93497, questInfo = "Dragonflight", requireInLog = true, twKind = "dragonflight", hideDone = false, showIfRememberedTimewalkingKind = true, },

  {label = "TW Dragonflight TKN", frameID = "bar1", key = "XP10:TW:TKN", sortGroup = "XP10:TW", sortOrder = 3, requireRememberedTimewalkingKind = true,
  questInfo = "\194\160", fallbackQuestInLog = { 93852 }, preferQuestInfoForTitle = true, twKind = "dragonflight", hideDone = false,
  indicators = { { questID = 93852, shape = "square", overlay = { itemIDs = { 262918 }, text = "1", color = { 1.0, 1.0, 0.1 } }, }, }, },

--  Update when Dragonflight Timewalking comes out
--  - Update Timewalking in QuestTracker for Dragonflight Timewalking
--  - Update Timewalking in DateTime for Dragonflight Timewalking events
--  - Aura:       1305981
--  - Calendar:   Dragonflight Timewalking
--  - LFD ID:     3305
--  - Not sure what else is needed?


  {label = "Void Strike", frameID = "list2", playerLevel = { "=", 90 }, hideDone = true, requireInLog = false, showXWhenComplete = true,
  questInfo = "Void Strike\n - Rutual Site and Void Incursion (Zygor)", questID = 96080, },

--  {label = "Void Strike", frameID = "list2", playerLevel = { "=", 90 }, hideDone = true, requireInLog = true, showXWhenComplete = true,
--  questInfo = "Void Strike\n - Rutual Site and Void Incursion (Zygor)", questID = 96080, },





}
-- mapIDs: fUI_QTUsage.lua


do
  local EXPANSION_ID = -1
  local EXPANSION_NAME = "Weekly"
  if type(ns.rules) == "table" then
    for i = 1, #ns.rules do
      local r = ns.rules[i]
          if type(r) == "table" then
            r.mapID = ns.ExpandMapIDs(r.mapID)
        if r._expansionID == nil then r._expansionID = EXPANSION_ID end
        if r._expansionName == nil then r._expansionName = EXPANSION_NAME end
        if r.questXY == nil and tonumber(r.questID) and r.qXept == nil then r.qXept = "N" end
      end
    end
  end
end
