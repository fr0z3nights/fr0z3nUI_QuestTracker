local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB03 (Wrath of the Lich King)

ns.rules = ns.rules or {}

local EXPANSION_ID = 3
local EXPANSION_NAME = "Wrath of the Lich King"

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

{["label"] = "Kirin Tor Ring", ["frameID"] = "list1", ["key"] = "custom:item:40586:list1:81",
["itemInfo"] = "Kirin Tor Ring\n + 8500 |TInterface\\MoneyFrame\\UI-GoldIcon:16:16:0:0|t", 
["playerLevel"] = { ">", 70, }, ["locationID"] = "125", ["restedOnly"] = true,
["item"] = { ["itemID"] = 40586, ["required"] = { 1, Y, Y, 1 }, }, },

{["label"] = "Argent Crusader's Tabard",
["itemInfo"] = "Argent Crusader's Tabard\n+ WBT $nm $cc / $rq ($wb)", ["frameID"] = "list1", ["key"] = "custom:item:46874:list1:128",
["playerLevel"] = { ">", 70, }, ["locationID"] = "84, 85, 125", ["restedOnly"] = true,
 ["item"] = { ["itemID"] = 46874, ["required"] = { 1, Y, N, 0 }, ["currencyID"] = { 241, 50 }, }, },



-- ["itemInfo"] = "Orgrimmar Tabard", 
-- ["locationID"] = "999999", 













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
