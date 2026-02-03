local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB10 (Dragonflight)

ns.rules = ns.rules or {}

local EXPANSION_ID = 10
local EXPANSION_NAME = "Dragonflight"

local Y, N = true, false

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
local bakedRules = {

{["label"] = "SU  10  Dragon Isles  34 Slot Bag", ["frameID"] = "list1", ["key"] = "custom:q:65646:list1:84",
["questID"] = 65646, ["prereq"] = { 67700, }, ["hideWhenCompleted"] = true,
["questInfo"] = "+ 34 Bag in Dragon Isles\n   WS 58,53 %c\n07N", },

{["label"] = "SU  10  Dragon Isles  Q-67700  65445  Horde", ["frameID"] = "list1", ["key"] = "custom:q:67700:list1:85",
["questID"] = 67700, ["prereq"] = { 30515, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Dragon Isles  (H)\n + Use Dragon Scale\n    or Cata Portal Area\n + Do Initial Quests\n + Take Portal\nWiggling Egg",
["faction"] = "Horde", },

{["label"] = "SU  10  Dragon Isles  Q-67700  65444  Alliance", ["frameID"] = "list1", ["key"] = "custom:q:67700:list1:86",
["questID"] = 67700, ["prereq"] = { 30515, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Dragon Isles\n + Use Dragon Scale\n    or Castle Balcony\n + Do Initial Quests\n + Take Portal\nWiggling Egg",
["faction"] = "Alliance", },

{["label"] = "Dragon Cooking", ["frameID"] = "list1", ["key"] = "custom:spell:list1:153",
["spellInfo"] = "Dragon Cooking", ["notSpellKnown"] = 366256, ["spellKnown"] = 264638,
["locationID"] = "1978", ["hideWhenCompleted"] = false, ["notInGroup"] = false, },

{["label"] = "Dragon Cooking", ["frameID"] = "list1", ["key"] = "custom:spell:list1:144",
["spellInfo"] = "Dragon Cooking", ["notSpellKnown"] = 309830, ["spellKnown"] = 264638, 
["locationID"] = "1978", ["hideWhenCompleted"] = false, ["notInGroup"] = false, },

{["label"] = "Dragon Engineering", ["frameID"] = "list1", ["key"] = "custom:spell:list1:151",
["spellInfo"] = "Dragon Engineering", ["notSpellKnown"] = 310542, ["spellKnown"] = 264483,
["locationID"] = "1978", ["notInGroup"] = false, },

{["label"] = "Dragon Fishing", ["frameID"] = "list1", ["key"] = "custom:spell:list1:146",
["spellInfo"] = "Dragon Fishing", ["notSpellKnown"] = 310675, ["spellKnown"] = 271660,
["locationID"] = "1978", ["notInGroup"] = false, },

{["label"] = "Dragon Herbalism", ["frameID"] = "list1", ["key"] = "custom:spell:list1:150",
["spellInfo"] = "Dragon Herbalism", ["notSpellKnown"] = 309780, ["spellKnown"] = 265825,
["locationID"] = "1978", ["notInGroup"] = false, },

{["label"] = "Dragon Mining", ["frameID"] = "list1", ["key"] = "custom:spell:list1:149",
["spellInfo"] = "Dragon Mining", ["notSpellKnown"] = 309835, ["spellKnown"] = 265843,
["locationID"] = "1978", ["notInGroup"] = false, },

{["label"] = "Dragon Skinning", ["frameID"] = "list1", ["key"] = "custom:spell:list1:148",
["spellInfo"] = "Dragon Skinning", ["notSpellKnown"] = 308569, ["spellKnown"] = 265861,
["locationID"] = "1978", ["notInGroup"] = false, },

{["label"] = "Dragon Tailoring", ["frameID"] = "list1", ["key"] = "custom:spell:list1:147",
["spellInfo"] = "Dragon Tailoring", ["notSpellKnown"] = 310949, ["spellKnown"] = 264622,
["locationID"] = "1978", ["notInGroup"] = false, },



}

for i = 1, #bakedRules do
  local r = bakedRules[i]
  if type(r) == "table" then
    if r._expansionID == nil then r._expansionID = EXPANSION_ID end
    if r._expansionName == nil then r._expansionName = EXPANSION_NAME end
    if type(r.key) == "string" then
      r.key = r.key:gsub("^custom:", "db:")
    end
    ns.rules[#ns.rules + 1] = r
  end
end
