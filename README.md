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

### Timewalking helpers
- `/fqt twdebug` — debug-print Timewalking detection from the Calendar
- `/fqt twclear` — clear remembered Timewalking weekly kind
- `/fqt evclear` — clear remembered calendar/timewalking event state

## SavedVariables
- Account: `fr0z3nUI_QuestTracker_Acc`
- Character: `fr0z3nUI_QuestTracker_Char`

## Notes
- Rule packs are loaded via the `.toc` and can be disabled by commenting out lines.
