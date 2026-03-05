# fr0z3nUI_QuestTracker — Changelog

Format: `YYMMDD-###` (sanity stamp) — short summary.

## 260304-001
- Keep List (K): no longer runs automatically; added a manual QuestX tab button to abandon quests using the Keep List.

## 260304-002
- Keep List abandon: added a confirmation prompt for 2+ quests (SHIFT bypass) and steps abandons with a small delay when timers are available.

## 260304-006
- QuestX: consolidated QuestX/Y/K helpers into the QuestX UI module.

## 260304-007
- (removed) QuestX protected-quest list system.

## 260304-008
- (removed) QuestX protected-quest list system.

## 260304-009
- (removed) QuestX protected-quest list system.

## 260304-010
- (removed) QuestX protected-quest list system.

## 260304-003
- Added `fUI_QTXRulesDB.lua` helper module for QuestX/Y/K database helpers (starting with Keep List extraction) and wired it into the Keep List abandon runner.

## 260304-005
- File naming pass: renamed QuestTracker modules to `fUI_QT*.lua`; core file is now `fr0z3nUI_QuestTracker.lua` (removed “Core”).

## 260303-005
- QuestX auto-abandon: select quests by questID (not log index), and skip quests that `C_QuestLog.CanAbandonQuest(questID)` reports as not abandonable.

## 260303-004
- QuestX: mode button now cycles 3 modes with clearer labels: Auto Abandon Quest / Auto Accept Quest / Abandon Quests Keep List.
- Keep List mode: adding QuestIDs creates `questXY = "K"` entries.
- QuestX/Y/K remain automation-only and are never staged into list/bar frames.

## 260303-003
- QuestX tab: removed the List picker UI (QuestX/Y automation rules always target `list1`).
- QuestX/QuestY: rules are now automation-only (no list/bar frame association; no List picker; no `frameID/targets/display`).

## 260303-002
- QuestX tab: rebuilt UI to match original QuestX × FAO style (centered QuestID input + title preview) and fixed the List selector.
- QuestX tab: added MAP/RESTING scope toggle; MAP uses `locationID` (auto-fills current map if blank) and RESTING uses `restedOnly`.

## 260301-003
- Options window: default anchor moved to top-left.

## 260301-002
- Fixed Auto Buy chat output to report actual received quantities and avoid repeated "Bought (Auto)" spam while merchant/bag data settles.
- AutoBuy: treat `BuyMerchantItem` quantity as item count (fixes misleading/spammy bought quantities when vendors update).

## 260301-001
- Added this changelog file (no functional changes).
