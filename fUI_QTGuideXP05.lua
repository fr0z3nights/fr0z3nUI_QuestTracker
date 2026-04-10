local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB05 (Mists of Pandaria)

ns.rules = ns.rules or {}

local EXPANSION_ID = 5
local EXPANSION_NAME = "Mists of Pandaria"

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

{["label"] = "SU  05  Jade Forest  A", ["frameID"] = "list1", ["key"] = "custom:q:29562:list1:XP05013",
["questID"] = 29562, ["prereq"] = { 34775, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Mists of Pandaria\n + Warboard: Jade Forest\n + Jade Forest (Zygor)\n      Until 'Jail Break'\n07N",
["faction"] = "Alliance", },

{["label"] = "SU  05  Jade Forest  H", ["frameID"] = "list1", ["key"] = "custom:q:29822:list1:XP05014",
["questID"] = 29822, ["prereq"] = { 34960, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Mists of Pandaria\n + Warboard: Jade Forest\n + Jade Forest (Zygor)\n       Until \"Lay of the Land\"\n07N",
["faction"] = "Horde", },

{["label"] = "SU  05  Kun-Lai  A", ["frameID"] = "list1", ["key"] = "custom:q:30515:list1:XP05015",
["questID"] = 30515, ["prereq"] = { 29562, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Mists of Pandaria  Level 20\n + Kun-Lai Summit (Zygor)\n      9  Do Village Quests\n    47  Complete\n      \"Challenge Accepted\"\n05A",
["faction"] = "Alliance", },

{["label"] = "SU  05  Kun-Lai  H", ["frameID"] = "list1", ["key"] = "custom:q:30515:list1:XP05016",
["questID"] = 30515, ["prereq"] = { 29822, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Mists of Pandaria  Level 20\n + Kun-Lai Summit (Zygor)\n      Until \"Challenge Accepted\" \n07N",
["faction"] = "Horde", },

{["label"] = "SU  05  Kun-Lai  Sprite's Cloth Chest", ["frameID"] = "list1", ["key"] = "custom:q:31412:list1:XP05017",
["questID"] = 31412, ["prereq"] = { 29562, }, ["hideWhenCompleted"] = true,
["questInfo"] = "+ Sprites Cloth Chest\n  - Need Steadfast\n  - Tried:\n       DK BL/UH - Strong\n07N", },



{["label"] = "Pandaria Alchemy", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP05097", ["notInGroup"] = false, 
["professionSkillLineID"] = 171, ["missingProfessionSkillLineID"] = 2481, ["locationID"] = 6666666, },

{["label"] = "Pandaria Blacksmithing", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP05098", ["notInGroup"] = false,
["professionSkillLineID"] = 164, ["missingProfessionSkillLineID"] = 2473, ["locationID"] = 6666666, },

{["label"] = "Pandaria Cooking", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP05105", ["notInGroup"] = false,
["professionSkillLineID"] = 185, ["missingProfessionSkillLineID"] = 2544, ["locationID"] = 6666666, },

{["label"] = "Pandaria Enchanting", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP05099", ["notInGroup"] = false,
["professionSkillLineID"] = 333, ["missingProfessionSkillLineID"] = 2489, ["locationID"] = 6666666, },

{["label"] = "Pandaria Engineering", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP05100", ["notInGroup"] = false,
["professionSkillLineID"] = 202, ["missingProfessionSkillLineID"] = 2502, ["locationID"] = 6666666, },

{["label"] = "Pandaria Fishing", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP05106", ["notInGroup"] = false,
["professionSkillLineID"] = 356, ["missingProfessionSkillLineID"] = 2588, ["locationID"] = 6666666, },

{["label"] = "Pandaria Herbalism", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP05094", ["notInGroup"] = false,
["professionSkillLineID"] = 182, ["missingProfessionSkillLineID"] = 2552, ["locationID"] = 6666666, },

{["label"] = "Pandaria Inscription", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP05101", ["notInGroup"] = false,
["professionSkillLineID"] = 773, ["missingProfessionSkillLineID"] = 2510, ["locationID"] = 6666666, },

{["label"] = "Pandaria Jewelcrafting", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP05102", ["notInGroup"] = false,
["professionSkillLineID"] = 755, ["missingProfessionSkillLineID"] = 2520, ["locationID"] = 6666666, },

{["label"] = "Pandaria Leatherworking", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP05103", ["notInGroup"] = false,
["professionSkillLineID"] = 165, ["missingProfessionSkillLineID"] = 2528, ["locationID"] = 6666666, },

{["label"] = "Pandaria Mining", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP05095", ["notInGroup"] = false,
["professionSkillLineID"] = 186, ["missingProfessionSkillLineID"] = 2568, ["locationID"] = 6666666, },

{["label"] = "Pandaria Skinning", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP05096", ["notInGroup"] = false,
["professionSkillLineID"] = 393, ["missingProfessionSkillLineID"] = 2560, ["locationID"] = 6666666, },

{["label"] = "Pandaria Tailoring", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP05104", ["notInGroup"] = false,
["professionSkillLineID"] = 197, ["missingProfessionSkillLineID"] = 2536, ["locationID"] = 6666666, },

}


for i = 1, #bakedRules do
  local r = bakedRules[i]
  if type(r) == "table" then
    if r._expansionID == nil then r._expansionID = EXPANSION_ID end
    if r._expansionName == nil then r._expansionName = EXPANSION_NAME end
    if r.questXY == nil and tonumber(r.questID) and r.qXept == nil then r.qXept = "N" end
    if type(r.key) == "string" then
      r.key = r.key:gsub("^custom:", "db:")
    end
    ns.rules[#ns.rules + 1] = r
  end
end
