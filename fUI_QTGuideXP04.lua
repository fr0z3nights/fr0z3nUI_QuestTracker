local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB04 (Cataclysm)

ns.rules = ns.rules or {}

local EXPANSION_ID = 4
local EXPANSION_NAME = "Cataclysm"

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

{["label"] = "SU  04  H1  Q-25929  Vashj'ir  Unlock Portal", ["frameID"] = "list1", ["key"] = "custom:q:25929:list1:XP04001",
["questID"] = 25929, ["prereq"] = { 46931, 51341, 61874, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Cataclysm\n+ Vashj'ir (Zygor)\n+ Complete Quest\n      \"Sea Legs\"",
["faction"] = "Horde", },

{["label"] = "SU  04  A1  Q-24432  Vashj'ir  Unlock Portal", ["frameID"] = "list1", ["key"] = "custom:q:24432:list1:XP04002",
["questID"] = 24432, ["prereq"] = { 46931, 51341, 61874, }, ["hideWhenCompleted"] = true,
["questInfo"] = "Cataclysm\n+ Vashj'ir (Zygor)\n+ Complete Quest\n      \"Sea Legs\"",
["faction"] = "Alliance", },

{["label"] = "Capital Cooking", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP04003", ["notInGroup"] = false,
["missingProfessionSkillLineID"] = 185, },

{["label"] = "Capital Fishing", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP04004", ["notInGroup"] = false,
["missingProfessionSkillLineID"] = 356, },

{["label"] = "Capital Alchemy", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP04005", ["notInGroup"] = false,
["missingPrimaryProfessions"] = true, ["missingProfessionSkillLineID"] = 171, },

{["label"] = "Capital Blacksmithing", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP04006", ["notInGroup"] = false,
["missingPrimaryProfessions"] = true, ["missingProfessionSkillLineID"] = 164, },

{["label"] = "Capital Enchanting", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP04007", ["notInGroup"] = false,
["missingPrimaryProfessions"] = true, ["missingProfessionSkillLineID"] = 333, },

{["label"] = "Capital Engineering", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP04008", ["notInGroup"] = false,
["missingPrimaryProfessions"] = true, ["missingProfessionSkillLineID"] = 202, },

{["label"] = "Capital Herbalism", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP04009", ["notInGroup"] = false,
["missingPrimaryProfessions"] = true, ["missingProfessionSkillLineID"] = 182, },
 
{["label"] = "Capital Inscription", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP04010", ["notInGroup"] = false,
["missingPrimaryProfessions"] = true, ["missingProfessionSkillLineID"] = 773, },

{["label"] = "Capital Jewelcrafting", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP04011", ["notInGroup"] = false,
["missingPrimaryProfessions"] = true, ["missingProfessionSkillLineID"] = 755, },

{["label"] = "Leatherworking", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP04012", ["notInGroup"] = false,
["missingPrimaryProfessions"] = true, ["missingProfessionSkillLineID"] = 165, },

{["label"] = "Mining", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP04013", ["notInGroup"] = false,
["missingPrimaryProfessions"] = true, ["missingProfessionSkillLineID"] = 186, },

{["label"] = "Skinning", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP04014", ["notInGroup"] = false,
["missingPrimaryProfessions"] = true, ["missingProfessionSkillLineID"] = 393, },

{["label"] = "Tailoring", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP04015", ["notInGroup"] = false,
["missingPrimaryProfessions"] = true, ["missingProfessionSkillLineID"] = 197, },

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
