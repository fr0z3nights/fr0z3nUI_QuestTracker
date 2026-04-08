# fr0z3nUI_QuestTracker — Changelog

Format: `YYYY.MM.DD.NN` (TOC `## Version`) — short summary. Newest at the top.

Discipline: bump TOC `## Version` on every behavior/UI change (sanity check stays meaningful).

## 2026.04.09.31
- Files: `fUI_QTCore.lua`, `fr0z3nUI_QuestTracker.toc`.
- UI: move the XQuest tab before the XRules tab.

## 2026.04.09.30
- Files: `fUI_QTUsageUIR.lua`, `fr0z3nUI_QuestTracker.toc`.
- Rename: `fUI_QTRenderUI.lua` → `fUI_QTUsageUIR.lua` (load order updated; behavior unchanged).

## 2026.04.09.29
- Files: `fUI_QTItem.lua`, `fUI_QTItemUI.lua`, `fr0z3nUI_QuestTracker.toc`.
- Rename: module filenames `...Items...` → `...Item...` (load order updated; behavior unchanged).

## 2026.04.09.28
- Files: `fUI_QTUsageUX.lua`, `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- Refactor: move the tracker frame system (frame create/position/vis-link/interactivity helpers) into `fUI_QTUsageUX.lua`; core now delegates via `ns.TrackerFrames.*`.

## 2026.04.09.27
- Files: `fUI_QTRenderUI.lua`, `fr0z3nUI_QuestTracker.toc`.
- Fix: edit mode list rows are now explicitly shown when populated (regression after renderer split where rows 4+ could stay hidden even with text).

## 2026.04.09.26
- Files: `fUI_QTRenderUI.lua`, `fUI_QTCommands.lua`, `fr0z3nUI_QuestTracker.toc`.
- Debug: extend `/fqt framedebug` with list layout diagnostics (count/visibleRows/offset/maxOffset/range + frame size/wheel state) to pinpoint edit-mode list clipping/scroll issues.

## 2026.04.09.25
- Files: `fUI_QTRenderUI.lua`, `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- Fix: restore pre-split edit-mode list sizing/ordering: lists respect `maxHeight` again in edit mode (prevents clipped/partially visible lists) and render top-to-bottom within the frame.

## 2026.04.09.22
- Files: `fUI_QTRenderUI.lua`, `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- Refactor: move heavy list/bar rendering (and bar "List" inspector) out of the core file into the Render UI module; core delegates via `ns.Render.*` and exposes a small deps shim.

## 2026.04.09.23
- Files: `fUI_QTRenderUI.lua`, `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- Fix: in edit mode, lists no longer respect `maxHeight` (so the full list is visible while editing); out of edit mode behavior unchanged.

## 2026.04.09.24
- Files: `fUI_QTRenderUI.lua`, `fr0z3nUI_QuestTracker.toc`.
- Fix: in edit mode, bottom-anchored lists now render upward from the bottom (so the list isn't stuck at the top of a tall frame).

## 2026.04.09.21
- Files: `fUI_QTCommands.lua`, `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`, `README Changelog.md`.
- Refactor: move the heavy debug command dispatcher (`twdebug/evdebug/framedebug/ruledebug/cache/*clear/debug`) out of the core file into the slash command module; core now exposes small deps hooks for the debug paths (no behavior change).

## 2026.04.09.17
- Files: `fUI_QTGuideProfs.lua`, `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- Professions: move main-file profession helpers (skill-line checks, missing primary/secondary slots, TradeSkill-line probe, primary-profession name checks) into the Professions module.

## 2026.04.09.18
- Files: `fUI_QTGuideEvent.lua`, `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- Calendar: move remembered event state (weekly/daily aura remembers, timewalking-kind remember/clear, and once-per-day auto-reset) into the Calendar module; core now calls via `ns.Calendar.*`.

## 2026.04.09.19
- Files: `fUI_QTGuideXP*.lua`, `fUI_QTGuideXPEV.lua`, `fUI_QTGuideXPWK.lua`, `fr0z3nUI_QuestTracker.toc`.
- Guide DB: rename rule pack files to include `Guide` in the filename (was `fUI_QTXP*.lua` / `fUI_QTXPEV.lua` / `fUI_QTXPWK.lua`).

## 2026.04.09.16
- Files: `fUI_QTQuest.lua`, `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- Quest: move quest API wrapper helpers (title/completion/in-log/objective progress) into the Quest feature module; TOC now loads Quest before the main engine.

## 2026.04.09.13
- Files: `fUI_QTUsage.lua`, `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- Usage: unify anchor/grow/link normalization between core and `ns.Usage` (adds `tc/bc` support to `ns.Usage` and makes core prefer the feature module helpers).

## 2026.04.09.14
- Files: `fUI_QTUsageUI.lua`, `fr0z3nUI_QuestTracker.toc`.
- Usage UI: update local fallback helpers to match `ns.Usage`/core normalization (supports `tc/bc` + same input sanitization).

## 2026.04.09.15
- Files: `fUI_QTUsage.lua`, `fr0z3nUI_QuestTracker.toc`.
- Layout: merge `ns.frames` defaults into Usage (removes standalone layout file; TOC now loads `fUI_QTUsage.lua` in the “Layout defaults” slot).

## 2026.04.09.12
- Files: `fUI_QTUsage.lua`, `fUI_QTUsageUI.lua`, `fr0z3nUI_QuestTracker.toc`.
- Usage: move non-UI helpers into the feature module (`ns.Usage`) and keep UI in `...UI.lua` (FGO-style).

## 2026.04.09.11
- Files: `fUI_QTText.lua`, `fUI_QTTextUI.lua`, `fr0z3nUI_QuestTracker.toc`.
- Text: move non-UI helpers into the feature module (`ns.Text`) and keep UI in `...UI.lua` (FGO-style).

## 2026.04.09.10
- Files: `fUI_QTQuest.lua`, `fUI_QTQuestUI.lua`, `fr0z3nUI_QuestTracker.toc`.
- Quest: move non-UI helpers into the feature module (`ns.Quest`) and keep UI in `...UI.lua` (FGO-style).

## 2026.04.09.09
- Files: `fUI_QTSpells.lua`, `fUI_QTSpellsUI.lua`, `fr0z3nUI_QuestTracker.toc`.
- Spells: move non-UI helpers into the feature module (`ns.Spells`) and keep UI in `...UI.lua` (FGO-style).

## 2026.04.09.06
- Files: `fUI_QTXRules.lua`, `fUI_QTXRulesUI.lua`, `fr0z3nUI_QuestTracker.toc`.
- XRules: move non-UI helpers into the feature module (`ns.XRules`) and keep UI in `...UI.lua` (FGO-style).

## 2026.04.09.20
- Files: `fUI_QTGuideGold.lua`, `fUI_QTItemBuy.lua`, `fUI_QTGuideEvent.lua`, `fUI_QTTextColor.lua`, `fUI_QTGuideProfs.lua`, `fr0z3nUI_QuestTracker.toc`.
- Rename: Currency → GuideGold, Merchant → ItemBuy, Calendar → GuideEvent, RGBPicker → TextColor, Professions → GuideProfs (TOC updated; exports stay under the same `ns.*` tables/functions).

## 2026.04.09.07
- Files: `fUI_QTGuide.lua`, `fUI_QTGuideUI.lua`, `fr0z3nUI_QuestTracker.toc`.
- Guide: move more non-UI helpers into the feature module (`ns.Guide`) and keep UI in `...UI.lua` (FGO-style).

## 2026.04.09.08
- Files: `fUI_QTItem.lua`, `fUI_QTItemUI.lua`, `fr0z3nUI_QuestTracker.toc`.
- Items: move non-UI helpers into the feature module (`ns.Items`) and keep UI in `...UI.lua` (FGO-style).

## 2026.04.08.45
- Hotfix: restore additional core helper functions that were present in the backup but missing after the split/consolidation pass (UI settings, window position save/restore, frame scroll offsets, item/location/player-level gates, quest completion/objectives)
- Files: `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`


# 2026.04.08.46
- Files: `fUI_QTXQuest.lua` (was `fUI_QTQuestX.lua`), `fUI_QTTracker.lua` (was `fUI_QTRules.lua`), `fr0z3nUI_QuestTracker.toc`.
- Rename files to match canonical naming: QuestX → XQuest, Rules → Tracker.

# 2026.04.08.47
- Files: `fUI_QTCodex.lua` (was `fUI_QTTracker.lua`), `fUI_QTOptions.lua`, `fUI_QTXRules.lua`, `fr0z3nUI_QuestTracker.toc`.
- Rename Tracking/Tracker to Codex (file + tab label + related UI hints).

# 2026.04.09.01
- Files: `fUI_QTUsage.lua` (was `fUI_QTFrames.lua`), `fUI_QTOptions.lua`, `fr0z3nUI_QuestTracker.toc`.
- Rename UI/Frames to Usage (file + tab label).

# 2026.04.09.02
- Files: `fUI_QTGuide.lua` (was `fUI_QTCodex.lua`), `fUI_QTOptions.lua`, `fUI_QTXRules.lua`, `fr0z3nUI_QuestTracker.toc`.
- Rename Codex to Guide (file + tab label + related UI hints).

# 2026.04.09.03
- Files: `fr0z3nUI_QuestTracker.toc`, `fUI_QT*UI.lua`, and the corresponding `fUI_QT*.lua` feature files.
- Split tabs into Feature + UI files (FGO-style `...UI.lua` naming). No behavior change intended.

# 2026.04.09.04
- Files: `fUI_QTCore.lua` (was `fUI_QTOptions.lua`), `fr0z3nUI_QuestTracker.toc`.
- Rename options shell to Core.

# 2026.04.09.05
- Files: `fUI_QTXQuest.lua`, `fUI_QTXQuestUI.lua`, `fr0z3nUI_QuestTracker.toc`.
- XQuest: move non-UI helpers into the feature module (`ns.XQuest`) and keep UI in `...UI.lua` (FGO-style).
## 2026.04.08.44
- Hotfix: restore missing `IsQuestInLog()` quest-log helper used by in-log gating (prevents nil-call during refresh)
- Files: `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`

## 2026.04.08.43
- Hotfix: restore missing `RuleKey()` implementation used for disable/toggle and stable rule identification (prevents nil-call in rule rendering)
- Files: `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`

## 2026.04.08.42
- Hotfix: restore missing rule-disable helpers (`IsRuleDisabled`, `ToggleRuleDisabled`, and scope helpers) to prevent nil-call errors during refresh/render
- Files: `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`

## 2026.04.08.41
- Hotfix: restore missing core accessors (`GetCustomRules/GetCustomFrames` + `GetEffectiveRules/GetEffectiveFrames`) to prevent nil-call errors after the split/consolidation pass
- Exports: re-exposed via `ns.*` and added global aliases for legacy module call sites
- Files: `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`

# 2026.04.08.35
- Files: `fr0z3nUI_QuestTracker.lua`, `fUI_QTQuestEvents.lua`, `fr0z3nUI_QuestTracker.toc`.
- Refactor: QUEST_DETAIL auto-accept and quest-log-driven QuestX abandon triggers moved into `fUI_QTQuestEvents.lua`; core `ns._OnEvent` delegates.
- Bumped TOC version to 2026.04.08.35.


## 2026.04.08.36
- Refactor: delegate CURRENCY_DISPLAY_UPDATE into fUI_QTGuideGold.lua (ns.Currency.OnCurrencyDisplayUpdate)
- Core: expose warband currency wrappers on ns (RequestWarbandCurrencyData / RefreshWarbandCurrencyCacheForAllKnownCurrencies / WarbandCurrencyInvalidate)

## 2026.04.08.37
- Refactor: move interactivity/combat-lockdown handling into fUI_QTInteractivity.lua
- Events: delegate MODIFIER_STATE_CHANGED and pending PLAYER_REGEN_ENABLED apply into ns.Interactivity

## 2026.04.08.38
- Refactor: move full warband-currency cache/request/refresh helpers into fUI_QTGuideGold.lua (core now calls ns exports)

## 2026.04.08.39
- Refactor: consolidate tiny shim modules (events/quest-events/interactivity) back into core to match the split style used in other fr0z3nUI addons

## 2026.04.08.40
- Hotfix: restore missing NormalizeSV initializer to prevent nil-call errors during login/refresh
# 2026.04.08.34
- Files: `fr0z3nUI_QuestTracker.lua`, `fUI_QTGuideEvent.lua`, `fr0z3nUI_QuestTracker.toc`.
- Refactor: CALENDAR_UPDATE_* event debounce moved into the calendar module (`ns.Calendar.OnCalendarUpdate`); core `ns._OnEvent` delegates.
- Bumped TOC version to 2026.04.08.34.

# 2026.04.08.33
- Files: `fr0z3nUI_QuestTracker.lua`, `fUI_QTItemBuy.lua`, `fr0z3nUI_QuestTracker.toc`.
- Refactor: MERCHANT_* event handling moved into the merchant module (`ns.Merchant.OnMerchantShow/OnMerchantUpdate/OnMerchantClosed`); core `ns._OnEvent` delegates.
- Bumped TOC version to 2026.04.08.33.

# 2026.04.08.32
- Files: `fr0z3nUI_QuestTracker.lua`, `fUI_QTCommands.lua`, `fUI_QTEvents.lua`, `fr0z3nUI_QuestTracker.toc`.
- Refactor: `/fqt` slash registration is now module-owned (`fUI_QTCommands.lua`). Core exposes a deps shim + `DispatchDebugCommand` for the remaining heavy debug subcommands.
- Refactor: event wiring (RegisterEvent list + SetScript hookup) moved into `fUI_QTEvents.lua`; core keeps the actual handler as `ns._OnEvent`.
- Bumped TOC version to 2026.04.08.32.

# 2026.04.08.31
- Files: `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- Commands: `/fqt evdebug` and `/fqt twdebug` no longer report `TW_MATCH` for day-events that are `ENDED` / `activeNow=false` (still listed for visibility, but not counted as matches).
- Bumped TOC version to 2026.04.08.31.

# 2026.04.08.30
- Files: `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- Timewalking (aura gate): don’t let `rememberWeekly` override a definitive live calendar `false` (only fall back to remembered weekly state when the calendar is unavailable/unknown).
- Bumped TOC version to 2026.04.08.30.

# 2026.04.08.29
- Files: `fUI_QTGuideEvent.lua`, `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- Calendar (weekly/bonus events): treat a calendar day-event as active only when `startTime/endTime` bounds (when provided by the API) indicate it’s active *now*; avoids matching next week’s instance and avoids stale post-reset matches.
- Commands: `/fqt evdebug` now prints `startEpoch`, `endEpoch`, and `activeNow`.
- Bumped TOC version to 2026.04.08.29.

# 2026.04.08.28
- Files: `fUI_QTGuideEvent.lua`, `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- Calendar (weekly/bonus events): skip calendar day-events that have an explicit `endTime` in the past (prevents stale Timewalking matches after reset even when the title doesn’t include `End/Ends`).
- Commands: `/fqt evdebug` now shows `endEpoch` + `ENDED` for day-events.
- Bumped TOC version to 2026.04.08.28.

# 2026.04.08.27
- Files: `fUI_QTGuideEvent.lua`, `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- Calendar (weekly/bonus events): Wednesday stale-event suppression now applies to the holiday name too (not just the title), so `"Timewalking Dungeon Event"` + holiday name `"... Ends"` won’t match.
- Commands: `/fqt evdebug` and `/fqt twdebug` now indicate when suppression came from title vs holiday name.
- Bumped TOC version to 2026.04.08.27.

# 2026.04.08.26
- Files: `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- Commands: `/fqt evdebug` and `/fqt twdebug` now print match flags (title vs holidayText) and `End/Ends` suppression status instead of the long holiday descriptions.
- Bumped TOC version to 2026.04.08.26.

# 2026.04.08.25
- Files: `fUI_QTGuideEvent.lua`, `fr0z3nUI_QuestTracker.toc`.
- Calendar (weekly/bonus events): on local Wednesday, ignore stale entries whose titles end with `End` or `Ends`.
- Bumped TOC version to 2026.04.08.25.

# 2026.04.08.24
- Files: `fr0z3nUI_QuestTracker.lua`, `fUI_QTGuideEvent.lua`, `fr0z3nUI_QuestTracker.toc`.
- Refactor: complete the calendar/timewalking split by removing the legacy in-file calendar subsystem (main file now relies on the calendar module exports).
- Commands: `/fqt twdebug` and `/fqt evdebug` now use `ns.Calendar.*` and `ns.GetCalendarDebugEvents`.
- Bumped TOC version to 2026.04.08.24.

# 2026.04.08.23
- Files: `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- Calendar (weekly/bonus events): ignore stale Wednesday entries with titles ending in `Ends` (e.g. `Timewalking Dungeon Event Ends`) so they don’t keep weekly events “active” past the Tuesday reset due to timezone drift.
- Bumped TOC version to 2026.04.08.23.

# 2026.04.08.22
- Files: `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- Commands: `/fqt prof <profession>##` messaging now reflects double-digit tier range `01-12`.
- Bumped TOC version to 2026.04.08.22.

# 2026.04.08.21
- Files: `fUI_QTGuideProfs.lua`, `fr0z3nUI_QuestTracker.toc`.
- Professions: embed Zygor-derived tier categoryIDs + Zygor tier skillLineIDs as module-owned reference data (`ZYGOR_TIER_CATEGORYIDS_BY_PROFKEY`), and fill missing Battle tier skillLineIDs for Alchemy/Inscription/Jewelcrafting.
- Bumped TOC version to 2026.04.08.21.

# 2026.04.08.20
- Files: `fUI_QTGuideProfs.lua`, `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- Professions: expand `TIERS_BY_PROFKEY` beyond Mining (XP05-08 where known) and add `BASE_SKILLLINE_BY_PROFKEY` so the professions module owns tier/base IDs.
- Commands: generalize `/fqt prof <profession>` and `/fqt prof <profession>##` to use the module table (keeps debug tooling and rule data in one place).
- Bumped TOC version to 2026.04.08.20.

# 2026.04.08.19
- Files: `fr0z3nUI_QuestTracker.lua`, `fUI_QTGuideProfs.lua`, `fr0z3nUI_QuestTracker.toc`.
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
- Files: `fUI_QTGuideProfs.lua`, `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
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
- Files: `fUI_QTGuideProfs.lua`, `fr0z3nUI_QuestTracker.toc`.
- Professions: harden Cooking/Fishing detection during early/odd API states by aliasing + slot-based fallback when `GetProfessionInfo` returns nil/0 skillLineIDs, and add a safe `GetProfessions` fallback in `HasSkillLineID` when the cache isn't populated yet.
- Bumped TOC version to 2026.04.08.13.

# 2026.04.08.12
- Files: `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- Commands: add `/fqt status` (FGO-style) to print version/enabled state plus a short professions-cache summary (including Cooking/Fishing sanity IDs).
- Bumped TOC version to 2026.04.08.12.

# 2026.04.08.11
- Files: `fUI_QTGuideProfs.lua`, `fr0z3nUI_QuestTracker.toc`.
- Professions: fix Cooking/Fishing detection when the client reports modern specialization skillLineIDs (e.g. `2908`/`2911`) by aliasing them to the base profession IDs used by rules (`185`/`356`).
- Bumped TOC version to 2026.04.08.11.

# 2026.04.08.10
- Files: `fUI_QTGuideProfs.lua`, `fr0z3nUI_QuestTracker.toc`.
- Professions: fix cache false-positives by not treating all TradeSkillUI lines as known (only mark a line as known when `GetProfessionInfoBySkillLineID` reports a real learned skill/max level) and invalidate the prior saved cache version.
- Bumped TOC version to 2026.04.08.10.

# 2026.04.08.09
- Files: `fUI_QTGuideXP08.lua`, `fr0z3nUI_QuestTracker.toc`.
- Battle for Azeroth reminders (XP08): moved Horde profession tier reminders next to the Alliance ones and sorted the combined set alphabetically by profession.
- Bumped TOC version to 2026.04.08.09.

# 2026.04.08.08
- Files: `fUI_QTGuideXP08.lua`, `fr0z3nUI_QuestTracker.toc`.
- Battle for Azeroth reminders (XP08): Archaeology now uses `missingProfessionSkillLineID = 794` (missing profession) instead of the current tier spell check.
- Bumped TOC version to 2026.04.08.08.

# 2026.04.08.07
- Files: `fUI_QTGuideXP08.lua`, `fr0z3nUI_QuestTracker.toc`.
- Battle for Azeroth reminders (XP08): convert Kul Tiran/Zandalari profession tier checks to `professionSkillLineID` + tier `missingProfessionSkillLineID` (faction-split), leaving Archaeology as a spell-based missing-tier check gated by `professionSkillLineID`.
- Bumped TOC version to 2026.04.08.07.

# 2026.04.08.04
- Files: `fUI_QTGuideXP05.lua`, `fr0z3nUI_QuestTracker.toc`.
- Pandaria reminders (XP05): add tier reminders for the remaining professions (crafting + cooking/fishing) using base `professionSkillLineID` plus tier `missingProfessionSkillLineID`.

# 2026.04.08.06
- Added XP07 (Legion) profession tier reminders using `professionSkillLineID` + `missingProfessionSkillLineID`.
- Bumped TOC version to 2026.04.08.06.

# 2026.04.08.05
- Added XP06 (Draenor) profession tier reminders using `professionSkillLineID` + `missingProfessionSkillLineID`.
- Bumped TOC version to 2026.04.08.05.

# 2026.04.08.04
- Files: `fUI_QTGuideProfs.lua`, `fUI_QTGuideXP05.lua`, `fr0z3nUI_QuestTracker.toc`.
- Professions: expand cached skillLine detection to include TradeSkillUI skillLineIDs (covers expansion tiers when available).
- Pandaria reminders (XP05): tier gating now uses `missingProfessionSkillLineID` (Zygor skillLine IDs) instead of spell-based `notSpellKnown` checks.

# 2026.04.08.02
- Files: `fr0z3nUI_QuestTracker.lua`, `fUI_QTGuideXP04.lua`, `fUI_QTGuideXP05.lua`, `fr0z3nUI_QuestTracker.toc`.
- Profession reminders: add `missingProfessionSkillLineID` gate and use it for XP04 “missing profession” entries.
- Pandaria reminders (XP05): base-profession checks now use `professionSkillLineID` (cache-backed), while keeping the Pandaria-specific `notSpellKnown` checks.

# 2026.04.08.01
- Files: `fUI_QTGuideProfs.lua`, `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`, `fUI_QTGuideXPEV.lua`.
- Professions: add a lightweight “known professions” cache (FGO-style) and prefer it for `professionSkillLineID` gating.
- Darkmoon Faire: weekly profession quests now gate by `professionSkillLineID` instead of `spellKnownAny` spell lists (more reliable across expansions and profession spell variants).

# 2026.04.07.03
- Files: `fUI_QTGuideXPEV.lua`, `fr0z3nUI_QuestTracker.toc`.
- Fix Lua syntax error in the Darkmoon Faire weekly profession rules (missing closing `}` in the Jewelcrafting rule) that could prevent the addon from loading.

# 2026.04.07.02
- Files: `fUI_QTGuideXPEV.lua`, `fr0z3nUI_QuestTracker.lua`, `fr0z3nUI_QuestTracker.toc`.
- Darkmoon Faire: pet battle dailies now hide when completed (Jeremy `32175`, Christoph `36471`).
- Darkmoon Faire: weekly profession quests gating restored to `spellKnownAny` spell lists.
- Darkmoon Faire: removed engine special-case that forced all DMF entries to never hide when completed.

# 2026.04.05.01
- Files: `fr0z3nUI_QuestTracker.lua`, `fUI_QTItem.lua`, `fr0z3nUI_QuestTracker.toc`.
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
- Files: `fr0z3nUI_QuestTracker.lua`, `fUI_QTGuideXP01.lua`.
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
