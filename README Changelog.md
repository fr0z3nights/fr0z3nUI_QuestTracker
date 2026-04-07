# fr0z3nUI_QuestTracker — Changelog

Format: `YYMMDD-###` (sanity stamp) — short summary.

## 260407-002
- Files: `fUI_QTXPEV.lua`, `fr0z3nUI_QuestTracker.toc`.
- Fix Lua syntax error in the Darkmoon Faire weekly profession rules (missing closing `}` in the Jewelcrafting rule) that could prevent the addon from loading.
- Bumped TOC `## Version` to `2026.04.07.03`.

## 260407-001
- Files: `fUI_QTXPEV.lua`, `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- Darkmoon Faire: pet battle dailies now hide when completed (Jeremy `32175`, Christoph `36471`).
- Darkmoon Faire: weekly profession quests gating restored to `spellKnownAny` spell lists.
- Darkmoon Faire: removed engine special-case that forced all DMF entries to never hide when completed.
- Bumped TOC `## Version` to `2026.04.07.02`.

## 260405-001
- Files: `fr0z3nUI_QuestTracker.lua`, `fUI_QTItems.lua`, `fr0z3nUI_QuestTracker.toc`.
- AutoBuy debug: no longer triggers just by holding SHIFT when opening a vendor.
- Items tab: added a bottom-left `Debug` toggle button with tooltip to control AutoBuy debug output.
- Bumped TOC `## Version` to `2026.04.05.01`.

## 260404-001
- Files: `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- Keep List abandon (`/fqt aaq` / `/fqt aaqs`): normalize `questXY` when building the keep set so older/hand-edited rules like `k` (lowercase) correctly protect kept quests.

## 260404-002
- Files: `fUI_QTXRules.lua`, `fr0z3nUI_QuestTracker.toc`.
- XRules browser: only treat rules as X/Y/Keep when `questXY` is explicitly set, so normal tracking rules (like Timewalking quest trackers) don’t show up under XQuest (Auto Abandon).

## 260404-003
- Files: `fUI_QTXRulesDB.lua`, `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- XQuest DB: added explicit X/Y/K scope sets and seed DB-backed QuestX/Y/Keep rules so they show up in XRules and can be toggled/edited.
- Keep List abandon: now ignores disabled Keep rules (so toggling a Keep entry off actually stops protecting that quest).

## 260404-004
- Files: `fUI_QTXRulesDB.lua`, `fr0z3nUI_QuestTracker.toc`.
- XQuest DB: added copy/paste examples for Keep/X/Y; DB-seeded XQuest rules can now optionally carry `locationID`/`restedOnly` gates via `__meta`.

## 260404-005
- Files: `fUI_QTXRulesDB.lua`, `fr0z3nUI_QuestTracker.toc`.
- XQuest DB authoring: renamed Keep helper to `KQuest(...)`; `XQuest(...)` now means Rested-only by default, and `LQuest(...)` is the location-gated helper (optional Rested-only override).

## 260404-006
- Files: `fUI_QTXRules.lua`, `fr0z3nUI_QuestTracker.toc`.
- XRules list: renamed group titles to `Auto Abandon` (XQuest/LQuest), `Auto Accept` (YQuest), and `Abandon All Keep` (KQuest).

## 260404-007
- Files: `fUI_QTXRules.lua`, `fr0z3nUI_QuestTracker.toc`.
- XRules list: removed quest titles from entry rows (show label + questID only).

## 260404-008
- Files: `fUI_QTXRules.lua`, `fr0z3nUI_QuestTracker.toc`.
- XRules list: entry rows now show quest title + questID only (removed per-row mode label like `Abandon All Keep`).

## 260404-009
- Files: `fUI_QTXRules.lua`, `fr0z3nUI_QuestTracker.toc`.
- XRules list: for DB-only entries, prefer the name authored in the addon DB (`__meta.name`); if blank/missing or user-added, fall back to the live quest title/fallback.

## 260404-010
- Files: `fUI_QTXRules.lua`, `fr0z3nUI_QuestTracker.toc`.
- XRules list: sort entries alphabetically (by displayed title) within each zone.

## 260404-011
- Files: `fUI_QTQuestX.lua`, `fr0z3nUI_QuestTracker.toc`.
- QuestX: MAP/RESTING scope button now only shows in Auto Abandon (X) mode.

## 260318-001
- AutoBuy (vendor): fix first-open reliability by retrying when the merchant list reports 0 items (no more needing to reopen the vendor).

## 260319-001
- Files: `fr0z3nUI_QuestTracker.lua`, `fUI_QTXP01.lua`.
- AutoBuy: add optional per-character purchased caching and merchant tooltip “Already known” detection to skip one-time learns.
- Rule (Classic): itemID `253580` (Housing Axe) now caches as purchased/known per character so it won’t be re-bought and will hide even if it’s no longer in bags.

## 260319-002
- AutoBuy purchased cache: add `cachePurchasedFromBag=false` option so rules can avoid treating “had it once in bags” as permanently acquired.
- Added `/fqt cache status <itemID>` and `/fqt cache clear <itemID>` to inspect/clear per-character cached purchases.

## 260307-001
- XQuest tab: restored Trade-style mode/scope button and fixed the QuestID input placeholder overlap (no default "0").
- XQuest tab: moved Character/Account actions into a Trade-style bottom row and shortened labels.
- Keep List abandon: if Keep List is empty, the button now abandons all abandonable quests (with confirmation) instead of doing nothing.

## 260307-002
- XQuest tab: Character/Account buttons now behave like FAO (left-click add/disable, right-click remove custom) with color-coded state and dynamic tooltips.
- Quest disable: added account-scoped `disabledRules` (Account disables apply to all characters; Character disables apply to just that character).

## 260307-003
- XQuest tab: moved the main X/Y/Keep mode button down so it no longer sits over the tabs.
- XQuest tab: moved Character/Account buttons under the quest info display (quest title), matching the expected flow.

## 260307-004
- XQuest tab: moved MAP/RESTING scope button next to Character and kept it visible (tooltip notes it applies to Auto Abandon).
- XQuest tab: added a bottom-left "Completed" toggle (yellow/grey) to skip completed quests when abandoning.
- XQuest tab: renamed/moved "Abandon" to "Abandon All Quests" (bottom-center) and added tooltip; added bottom-right "Reload UI".

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

## 260328-001
- Files: `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`
- Cache debug: call `C_Item.GetItemCount` with the full argument set for better client/stub compatibility.
- Tooltip formatting: suppress LuaLS false-positives for `string.gsub(..., function)` whitespace preservation helpers.
- Bumped TOC `## Version` to `2026.03.28.01`.
