# fr0z3nUI_QuestTracker — Changelog

Format: `YYYY.MM.DD.NN` (TOC `## Version`) — short summary. Newest at the top.

Discipline: bump TOC `## Version` on every behavior/UI change (sanity check stays meaningful).

# 2026.04.08.23
- Files: `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- Calendar (weekly/bonus events): ignore stale Wednesday entries with titles ending in `Ends` (e.g. `Timewalking Dungeon Event Ends`) so they don’t keep weekly events “active” past the Tuesday reset due to timezone drift.
- Bumped TOC version to 2026.04.08.23.

# 2026.04.08.22
- Files: `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- Commands: `/fqt prof <profession>##` messaging now reflects double-digit tier range `01-12`.
- Bumped TOC version to 2026.04.08.22.

# 2026.04.08.21
- Files: `fUI_QTProfessions.lua`, `fr0z3nUI_QuestTracker.toc`.
- Professions: embed Zygor-derived tier categoryIDs + Zygor tier skillLineIDs as module-owned reference data (`ZYGOR_TIER_CATEGORYIDS_BY_PROFKEY`), and fill missing Battle tier skillLineIDs for Alchemy/Inscription/Jewelcrafting.
- Bumped TOC version to 2026.04.08.21.

# 2026.04.08.20
- Files: `fUI_QTProfessions.lua`, `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- Professions: expand `TIERS_BY_PROFKEY` beyond Mining (XP05-08 where known) and add `BASE_SKILLLINE_BY_PROFKEY` so the professions module owns tier/base IDs.
- Commands: generalize `/fqt prof <profession>` and `/fqt prof <profession>##` to use the module table (keeps debug tooling and rule data in one place).
- Bumped TOC version to 2026.04.08.20.

# 2026.04.08.19
- Files: `fr0z3nUI_QuestTracker.lua`, `fUI_QTProfessions.lua`, `fr0z3nUI_QuestTracker.toc`.
- Professions: fix `GetProfessionInfo()` skillLineID reads when called via `pcall` (the `pcall` success flag shifts return positions). This restores correct `professionSkillLineID` detection for primaries like Mining/Tailoring when `GetProfessions()` shows them.
- Bumped TOC version to 2026.04.08.19.

# 2026.04.08.18
- Files: `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- Professions: fix `professionSkillLineID` gating so a transient cache-backed `false` no longer blocks the authoritative `GetProfessions()` fallback (also avoids nil-hole truncation when scanning indices).
- Bumped TOC version to 2026.04.08.18.

# 2026.04.08.17
- Files: `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- Commands: add `/fqt prof dmf` to debug DMF profession weeklies (prints profession gate + quest completed/in-log so it’s obvious when entries are hidden due to completion).
- Bumped TOC version to 2026.04.08.17.

# 2026.04.08.16
- Files: `fUI_QTProfessions.lua`, `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- Professions: add safe targeted `C_TradeSkillUI.GetProfessionInfoBySkillLineID(<id>)` probing to improve primary profession detection without reintroducing the old “enumerate everything” false-positive bug.
- Commands: add `/fqt prof api` to print live `GetProfessions()`/`GetProfessionInfo()` returns plus targeted TradeSkill probes (helps debug per-character detection issues like Mining/Tailoring).
- Bumped TOC version to 2026.04.08.16.

# 2026.04.08.15
- Files: `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- Commands: add `/fqt prof mining` (base Mining) and `/fqt prof mining##` (XP05-08 tier checks) using the same tier IDs as the rule packs.
- Bumped TOC version to 2026.04.08.15.

# 2026.04.08.14
- Files: `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- Commands: add `/fqt prof ...` for profession debugging: `status`, `refresh` (force cache update), `has <skillLineID...>`, and `dump` (cached profession keys).
- Bumped TOC version to 2026.04.08.14.

# 2026.04.08.13
- Files: `fUI_QTProfessions.lua`, `fr0z3nUI_QuestTracker.toc`.
- Professions: harden Cooking/Fishing detection during early/odd API states by aliasing + slot-based fallback when `GetProfessionInfo` returns nil/0 skillLineIDs, and add a safe `GetProfessions` fallback in `HasSkillLineID` when the cache isn't populated yet.
- Bumped TOC version to 2026.04.08.13.

# 2026.04.08.12
- Files: `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- Commands: add `/fqt status` (FGO-style) to print version/enabled state plus a short professions-cache summary (including Cooking/Fishing sanity IDs).
- Bumped TOC version to 2026.04.08.12.

# 2026.04.08.11
- Files: `fUI_QTProfessions.lua`, `fr0z3nUI_QuestTracker.toc`.
- Professions: fix Cooking/Fishing detection when the client reports modern specialization skillLineIDs (e.g. `2908`/`2911`) by aliasing them to the base profession IDs used by rules (`185`/`356`).
- Bumped TOC version to 2026.04.08.11.

# 2026.04.08.10
- Files: `fUI_QTProfessions.lua`, `fr0z3nUI_QuestTracker.toc`.
- Professions: fix cache false-positives by not treating all TradeSkillUI lines as known (only mark a line as known when `GetProfessionInfoBySkillLineID` reports a real learned skill/max level) and invalidate the prior saved cache version.
- Bumped TOC version to 2026.04.08.10.

# 2026.04.08.09
- Files: `fUI_QTXP08.lua`, `fr0z3nUI_QuestTracker.toc`.
- Battle for Azeroth reminders (XP08): moved Horde profession tier reminders next to the Alliance ones and sorted the combined set alphabetically by profession.
- Bumped TOC version to 2026.04.08.09.

# 2026.04.08.08
- Files: `fUI_QTXP08.lua`, `fr0z3nUI_QuestTracker.toc`.
- Battle for Azeroth reminders (XP08): Archaeology now uses `missingProfessionSkillLineID = 794` (missing profession) instead of the current tier spell check.
- Bumped TOC version to 2026.04.08.08.

# 2026.04.08.07
- Files: `fUI_QTXP08.lua`, `fr0z3nUI_QuestTracker.toc`.
- Battle for Azeroth reminders (XP08): convert Kul Tiran/Zandalari profession tier checks to `professionSkillLineID` + tier `missingProfessionSkillLineID` (faction-split), leaving Archaeology as a spell-based missing-tier check gated by `professionSkillLineID`.
- Bumped TOC version to 2026.04.08.07.

# 2026.04.08.04
- Files: `fUI_QTXP05.lua`, `fr0z3nUI_QuestTracker.toc`.
- Pandaria reminders (XP05): add tier reminders for the remaining professions (crafting + cooking/fishing) using base `professionSkillLineID` plus tier `missingProfessionSkillLineID`.

# 2026.04.08.06
- Added XP07 (Legion) profession tier reminders using `professionSkillLineID` + `missingProfessionSkillLineID`.
- Bumped TOC version to 2026.04.08.06.

# 2026.04.08.05
- Added XP06 (Draenor) profession tier reminders using `professionSkillLineID` + `missingProfessionSkillLineID`.
- Bumped TOC version to 2026.04.08.05.

# 2026.04.08.04
- Files: `fUI_QTProfessions.lua`, `fUI_QTXP05.lua`, `fr0z3nUI_QuestTracker.toc`.
- Professions: expand cached skillLine detection to include TradeSkillUI skillLineIDs (covers expansion tiers when available).
- Pandaria reminders (XP05): tier gating now uses `missingProfessionSkillLineID` (Zygor skillLine IDs) instead of spell-based `notSpellKnown` checks.

# 2026.04.08.02
- Files: `fr0z3nUI_QuestTracker.lua`, `fUI_QTXP04.lua`, `fUI_QTXP05.lua`, `fr0z3nUI_QuestTracker.toc`.
- Profession reminders: add `missingProfessionSkillLineID` gate and use it for XP04 “missing profession” entries.
- Pandaria reminders (XP05): base-profession checks now use `professionSkillLineID` (cache-backed), while keeping the Pandaria-specific `notSpellKnown` checks.

# 2026.04.08.01
- Files: `fUI_QTProfessions.lua`, `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`, `fUI_QTXPEV.lua`.
- Professions: add a lightweight “known professions” cache (FGO-style) and prefer it for `professionSkillLineID` gating.
- Darkmoon Faire: weekly profession quests now gate by `professionSkillLineID` instead of `spellKnownAny` spell lists (more reliable across expansions and profession spell variants).

# 2026.04.07.03
- Files: `fUI_QTXPEV.lua`, `fr0z3nUI_QuestTracker.toc`.
- Fix Lua syntax error in the Darkmoon Faire weekly profession rules (missing closing `}` in the Jewelcrafting rule) that could prevent the addon from loading.

# 2026.04.07.02
- Files: `fUI_QTXPEV.lua`, `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- Darkmoon Faire: pet battle dailies now hide when completed (Jeremy `32175`, Christoph `36471`).
- Darkmoon Faire: weekly profession quests gating restored to `spellKnownAny` spell lists.
- Darkmoon Faire: removed engine special-case that forced all DMF entries to never hide when completed.

# 2026.04.05.01
- Files: `fr0z3nUI_QuestTracker.lua`, `fUI_QTItems.lua`, `fr0z3nUI_QuestTracker.toc`.
- AutoBuy debug: no longer triggers just by holding SHIFT when opening a vendor.
- Items tab: added a bottom-left `Debug` toggle button with tooltip to control AutoBuy debug output.

# 2026.04.04.11
- Files: `fUI_QTQuestX.lua`, `fr0z3nUI_QuestTracker.toc`.
- QuestX: MAP/RESTING scope button now only shows in Auto Abandon (X) mode.

# 2026.04.04.10
- Files: `fUI_QTXRules.lua`, `fr0z3nUI_QuestTracker.toc`.
- XRules list: sort entries alphabetically (by displayed title) within each zone.

# 2026.04.04.09
- Files: `fUI_QTXRules.lua`, `fr0z3nUI_QuestTracker.toc`.
- XRules list: for DB-only entries, prefer the name authored in the addon DB (`__meta.name`); if blank/missing or user-added, fall back to the live quest title/fallback.

# 2026.04.04.08
- Files: `fUI_QTXRules.lua`, `fr0z3nUI_QuestTracker.toc`.
- XRules list: entry rows now show quest title + questID only (removed per-row mode label like `Abandon All Keep`).

# 2026.04.04.07
- Files: `fUI_QTXRules.lua`, `fr0z3nUI_QuestTracker.toc`.
- XRules list: removed quest titles from entry rows (show label + questID only).

# 2026.04.04.06
- Files: `fUI_QTXRules.lua`, `fr0z3nUI_QuestTracker.toc`.
- XRules list: renamed group titles to `Auto Abandon` (XQuest/LQuest), `Auto Accept` (YQuest), and `Abandon All Keep` (KQuest).

# 2026.04.04.05
- Files: `fUI_QTXRulesDB.lua`, `fr0z3nUI_QuestTracker.toc`.
- XQuest DB authoring: renamed Keep helper to `KQuest(...)`; `XQuest(...)` now means Rested-only by default, and `LQuest(...)` is the location-gated helper (optional Rested-only override).

# 2026.04.04.04
- Files: `fUI_QTXRulesDB.lua`, `fr0z3nUI_QuestTracker.toc`.
- XQuest DB: added copy/paste examples for Keep/X/Y; DB-seeded XQuest rules can now optionally carry `locationID`/`restedOnly` gates via `__meta`.

# 2026.04.04.03
- Files: `fUI_QTXRulesDB.lua`, `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- XQuest DB: added explicit X/Y/K scope sets and seed DB-backed QuestX/Y/Keep rules so they show up in XRules and can be toggled/edited.
- Keep List abandon: now ignores disabled Keep rules (so toggling a Keep entry off actually stops protecting that quest).

# 2026.04.04.02
- Files: `fUI_QTXRules.lua`, `fr0z3nUI_QuestTracker.toc`.
- XRules browser: only treat rules as X/Y/Keep when `questXY` is explicitly set, so normal tracking rules (like Timewalking quest trackers) don’t show up under XQuest (Auto Abandon).

# 2026.04.04.01
- Files: `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- Keep List abandon (`/fqt aaq` / `/fqt aaqs`): normalize `questXY` when building the keep set so older/hand-edited rules like `k` (lowercase) correctly protect kept quests.

# 2026.03.28.01
- Files: `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`
- Cache debug: call `C_Item.GetItemCount` with the full argument set for better client/stub compatibility.
- Tooltip formatting: suppress LuaLS false-positives for `string.gsub(..., function)` whitespace preservation helpers.

# 2026.03.19.02
- AutoBuy purchased cache: add `cachePurchasedFromBag=false` option so rules can avoid treating “had it once in bags” as permanently acquired.
- Added `/fqt cache status <itemID>` and `/fqt cache clear <itemID>` to inspect/clear per-character cached purchases.

# 2026.03.19.01
- Files: `fr0z3nUI_QuestTracker.lua`, `fUI_QTXP01.lua`.
- AutoBuy: add optional per-character purchased caching and merchant tooltip “Already known” detection to skip one-time learns.
- Rule (Classic): itemID `253580` (Housing Axe) now caches as purchased/known per character so it won’t be re-bought and will hide even if it’s no longer in bags.

# 2026.03.18.01
- AutoBuy (vendor): fix first-open reliability by retrying when the merchant list reports 0 items (no more needing to reopen the vendor).

# 2026.03.07.04
- XQuest tab: moved MAP/RESTING scope button next to Character and kept it visible (tooltip notes it applies to Auto Abandon).
- XQuest tab: added a bottom-left "Completed" toggle (yellow/grey) to skip completed quests when abandoning.
- XQuest tab: renamed/moved "Abandon" to "Abandon All Quests" (bottom-center) and added tooltip; added bottom-right "Reload UI".

# 2026.03.07.03
- XQuest tab: moved the main X/Y/Keep mode button down so it no longer sits over the tabs.
- XQuest tab: moved Character/Account buttons under the quest info display (quest title), matching the expected flow.

# 2026.03.07.02
- XQuest tab: Character/Account buttons now behave like FAO (left-click add/disable, right-click remove custom) with color-coded state and dynamic tooltips.
- Quest disable: added account-scoped `disabledRules` (Account disables apply to all characters; Character disables apply to just that character).

# 2026.03.07.01
- XQuest tab: restored Trade-style mode/scope button and fixed the QuestID input placeholder overlap (no default "0").
- XQuest tab: moved Character/Account actions into a Trade-style bottom row and shortened labels.
- Keep List abandon: if Keep List is empty, the button now abandons all abandonable quests (with confirmation) instead of doing nothing.

# 2026.03.04.10
- (removed) QuestX protected-quest list system.

# 2026.03.04.09
- (removed) QuestX protected-quest list system.

# 2026.03.04.08
- (removed) QuestX protected-quest list system.

# 2026.03.04.07
- (removed) QuestX protected-quest list system.

# 2026.03.04.06
- QuestX: consolidated QuestX/Y/K helpers into the QuestX UI module.

# 2026.03.04.05
- File naming pass: renamed QuestTracker modules to `fUI_QT*.lua`; core file is now `fr0z3nUI_QuestTracker.lua` (removed “Core”).

# 2026.03.04.03
- Added `fUI_QTXRulesDB.lua` helper module for QuestX/Y/K database helpers (starting with Keep List extraction) and wired it into the Keep List abandon runner.

# 2026.03.04.02
- Keep List abandon: added a confirmation prompt for 2+ quests (SHIFT bypass) and steps abandons with a small delay when timers are available.

# 2026.03.04.01
- Keep List (K): no longer runs automatically; added a manual QuestX tab button to abandon quests using the Keep List.

# 2026.03.03.05
- QuestX auto-abandon: select quests by questID (not log index), and skip quests that `C_QuestLog.CanAbandonQuest(questID)` reports as not abandonable.

# 2026.03.03.04
- QuestX: mode button now cycles 3 modes with clearer labels: Auto Abandon Quest / Auto Accept Quest / Abandon Quests Keep List.
- Keep List mode: adding QuestIDs creates `questXY = "K"` entries.
- QuestX/Y/K remain automation-only and are never staged into list/bar frames.

# 2026.03.03.03
- QuestX tab: removed the List picker UI (QuestX/Y automation rules always target `list1`).
- QuestX/QuestY: rules are now automation-only (no list/bar frame association; no List picker; no `frameID/targets/display`).

# 2026.03.03.02
- QuestX tab: rebuilt UI to match original QuestX × FAO style (centered QuestID input + title preview) and fixed the List selector.
- QuestX tab: added MAP/RESTING scope toggle; MAP uses `locationID` (auto-fills current map if blank) and RESTING uses `restedOnly`.

# 2026.03.01.03
- Options window: default anchor moved to top-left.

# 2026.03.01.02
- Fixed Auto Buy chat output to report actual received quantities and avoid repeated "Bought (Auto)" spam while merchant/bag data settles.
- AutoBuy: treat `BuyMerchantItem` quantity as item count (fixes misleading/spammy bought quantities when vendors update).

# 2026.03.01.01
- Added this changelog file (no functional changes).
