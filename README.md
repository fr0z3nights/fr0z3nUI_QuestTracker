# fr0z3nUI QuestTracker

Tracks quest completion with bar/list frames and rule packs (per expansion). Includes an options UI.

## Install
1. Copy the folder `fr0z3nUI_QuestTracker` into:
	- `World of Warcraft/_retail_/Interface/AddOns/`
2. Launch WoW and enable the addon.

## Slash Commands
- `/fqt` — open options
- `/fqt on` — enable frames
- `/fqt off` — disable frames
- `/fqt reset` — reset frame positions to defaults
- `/fqt rgb` — open the RGB helper/picker
- `/fqt zgp` - print the active Zygor guide's full path as a quoted, escaped Lua string ready to use in `zygor = { ... }`; reports when Zygor or an active guide is unavailable.
- `/fqtzygor bypass on` - suppress Zygor guide-eligibility warnings account-wide (default on)
- `/fqtzygor bypass off` - restore Zygor's normal eligibility checks

### Timewalking helpers
- `/fqt twdebug` — debug-print Timewalking detection from the Calendar
- `/fqt twclear` — clear remembered Timewalking weekly kind
- `/fqt evclear` — clear remembered calendar/timewalking event state

## SavedVariables
- Account: `fr0z3nUI_QuestTracker_Acc`
- Character: `fr0z3nUI_QuestTracker_Char`

## Notes
- Rule packs are loaded via the `.toc` and can be disabled by commenting out lines.

### Hourly countdowns
Use `%cdhr` in displayed info text to count down to the next top of the realm-clock
hour, or `%cdtp` to count down to the next ten past the hour:

```lua
questInfo = "Aqir Invasion\n %cdtp",
```

Timers display minutes and seconds (for example `12m 09s`) and refresh every
second while their frame is visible. Both parts use the same server timestamp,
aligned to the realm hour, so minute and second rollovers stay synchronized.
At the target time they roll over to the
next hour. Each token appears only on the first displayed entry containing it
in each frame, following display order and scroll position. Subsequent entries
omit that countdown, removing its line if it contains no other text.

### Item-token auto-buy
For exchanges, set `item.buy.spendItem = { itemID = 269862, count = 2 }`.
With auto-buy enabled in `item.required`, this buys one target item per two
bag-held tokens, regardless of how many target items are already owned.
`autoBuyMax` still limits each purchase pass, and normal stock/gold limits apply.
The Great Vault rule buys item 263934 using this exchange.
Purchases are split to respect the merchant's per-request stack limit, including
one-at-a-time requests for non-stackable items.

To display the tokens owned rather than the purchase item, set
`item.showCount = "amount"` and `item.showCountItemID = 269862`. This displays
just the quantity (for example `8`), without a required-count denominator.
The override affects display only; visibility gates and buying still use their
configured items. It follows `item.includeBank` / `item.inBank` (bags by default).

Token budgets are shared across exchange rules within a merchant session and
reserved immediately after purchase calls so delayed bag updates cannot spend
the same tokens twice. Close and reopen the merchant to refresh the budget
after acquiring more tokens or an unsuccessful purchase. Bank-held tokens do
not count. The configured cost must match the merchant's actual per-item cost.

### World Quest Completion Exceptions
`hideQID` accepts a quest ID or a list of IDs. Set `hideQIDAccount = true` to also
check account-wide completion when the client exposes that API (otherwise only
the character's completion check is available).

For a world-quest row, `uwqGold` sets a minimum reward that applies only after a
`hideQID` is completed. Before that completion, it does not gate visibility:

```lua
wqID = {92123,2437},
hideQID = 92128,
hideQIDAccount = true,
uwqGold = 500,
questInfo = "WB Zul'Aman 1784",
questInfoUwqGold = "WB Zul'Aman {wqGold}",
```

The row shows before the tracking quest is completed. Afterwards, it shows only
with a confirmed reward of at least the `uwqGold` amount. Unresolved reward data
does not satisfy this threshold. When that threshold qualifies, `questInfoUwqGold`
replaces `questInfo`; otherwise the regular `questInfo` is used. Other visibility
gates still apply.

The `%wqg` and `{wqGold}` reward placeholders are right-aligned in a minimum
four-character field, so values such as `975` and `1784` line up.

## Map Event Gates
Rules can use `eventPOI = { areaPoiID, mapID }` to show only while that event
is returned by `C_AreaPoiInfo.GetEventsForMap` and marked `isCurrentEvent`.
This is separate from world-quest activity and does not create a Zygor link.
For Harandar's Herbalism Grotto, use `eventPOI = {8527,2413}` with
`questID = 89507` to track the weekly quest's log, progress, and completion.
Event-marker updates refresh the rows automatically.

## Zygor Guide Links
Any database rule can set `zygor = { guide, zygorTT, zygorX, step }`:

```lua
zygor = { "LEVELING\\Pandaria (10-70)\\Kun-Lai Summit (20-70)", 0, 0, 1 },
```

Left-click the entry outside edit mode to load the guide into Zygor's viewer.
The tooltip flag (`zygorTT`) is `1` to show or `0` to hide (default).
The close flag (`zygorX`) is `1` to close the guide tab when this rule's `questID`
is turned in or becomes flagged completed on a quest-log update, or `0` to keep it
open (default). POI disappearance or the row hiding does not cancel this check.
This only applies after clicking
the rule during the current session, whether its guide tab is active or inactive;
the viewer itself is not hidden. Clicking another rule replaces the pending action.
If turn-in occurs during combat lockdown, tab closure waits until combat ends.
Clicking another rule before then replaces or clears the queued closure too.
The step can be a number or `{ AllianceStep, HordeStep }`.
For explicit guide links, the step can also be
`{ startingStep, { questID, step }, ... }` for quest-driven skips.
`zygorX` remains a numeric close flag, independent of these actions.
For example, a rule with `questID = 30515` can use:

```lua
zygor = { "LEVELING\\Pandaria (10-70)\\Kun-Lai Summit (20-70)", 0, 1, {8,{30506,46}} },
```

Turning in 30506 moves the matching open tab to step 46; turning in 30515
closes it because `zygorX = 1`. With `zygorX = 0`, the skips still work but the
tab remains open. Inactive tabs are updated without switching away from the active guide.
On clicking the row, already-completed action quests select their step immediately
(the last completed action in list order wins). The same current-session and
single-pending-action limits apply.
Without a step, Zygor uses its normal starting-step behavior. Zygor must be
loaded and initialized; unavailable guides produce a chat message.
If exact lookup fails, FQT tries a unique full-path match ignoring case,
extra spaces, category aliases handled by Zygor, and pet/mount/quest or daily
plural variations. Resolved paths are printed in chat; ambiguous paths are
reported rather than guessed. Step numbers are preserved, and unavailable
subscription guides are not replaced with another guide.

Rules with `wqID = {questID, mapID}` are also clickable automatically. FQT calls
Zygor's world-quest loader to resolve the zone guide and its `quest-<ID>` step,
reusing Zygor's world-quest tab. No map click, tracked quest, or `zygor` title is
needed. An explicit `zygor` title takes priority over this automatic lookup.
For automatic world-quest links, set standalone `zygorX = 1` to close the resolved
guide tab when `wqID[1]` is turned in, whether the tab is active or inactive.
As with explicit links, the row must first be clicked during the current session.

The eligibility bypass applies to guides loaded from Zygor itself as well as FQT.
It does not bypass missing guides, subscription restrictions, or unrelated dialogs,
and does not store additional guide approvals in Zygor's SavedVariables. Turning it
off leaves any approvals previously saved by Zygor unchanged. No Zygor source files
are modified; the integration runs while FQT is enabled.
