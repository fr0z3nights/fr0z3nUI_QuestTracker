local addonName, ns = ...

-- Expansion DB12 (Midnight)

ns.rules = ns.rules or {}

local EXPANSION_ID = 12
local EXPANSION_NAME = "Midnight"

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

-- PROFESSIONS
  {["label"] = "Midnight Alchemy", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP12152", ["notInGroup"] = false,
  ["professionSkillLineID"] = 171, ["missingProfessionSkillLineID"] = 2906, ["locationID"] = 6666666, },

  {["label"] = "Midnight Blacksmithing", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP12153", ["notInGroup"] = false,
  ["professionSkillLineID"] = 164, ["missingProfessionSkillLineID"] = 2907, ["locationID"] = 6666666, },

  {["label"] = "Midnight Cooking", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP12144", ["notInGroup"] = false,
  ["professionSkillLineID"] = 185, ["missingProfessionSkillLineID"] = 2908, ["locationID"] = 6666666, },

  {["label"] = "Midnight Enchanting", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP12154", ["notInGroup"] = false,
  ["professionSkillLineID"] = 333, ["missingProfessionSkillLineID"] = 2909, ["locationID"] = 6666666, },

  {["label"] = "Midnight Engineering", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP12151", ["notInGroup"] = false,
  ["professionSkillLineID"] = 202, ["missingProfessionSkillLineID"] = 2910, ["locationID"] = 6666666, },

  {["label"] = "Midnight Fishing", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP12146", ["notInGroup"] = false,
  ["professionSkillLineID"] = 356, ["missingProfessionSkillLineID"] = 2911, ["locationID"] = 6666666, },

  {["label"] = "Midnight Herbalism", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP12150", ["notInGroup"] = false,
  ["professionSkillLineID"] = 182, ["missingProfessionSkillLineID"] = 2912, ["locationID"] = 6666666, },

  {["label"] = "Midnight Inscription", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP12155", ["notInGroup"] = false,
  ["professionSkillLineID"] = 773, ["missingProfessionSkillLineID"] = 2913, ["locationID"] = 6666666, },

  {["label"] = "Midnight Jewelcrafting", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP12156", ["notInGroup"] = false,
  ["professionSkillLineID"] = 755, ["missingProfessionSkillLineID"] = 2914, ["locationID"] = 6666666, },

  {["label"] = "Midnight Leatherworking", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP12157", ["notInGroup"] = false,
  ["professionSkillLineID"] = 165, ["missingProfessionSkillLineID"] = 2915, ["locationID"] = 6666666, },

  {["label"] = "Midnight Mining", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP12149", ["notInGroup"] = false,
  ["professionSkillLineID"] = 186, ["missingProfessionSkillLineID"] = 2916, ["locationID"] = 6666666, },

  {["label"] = "Midnight Skinning", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP12148", ["notInGroup"] = false,
  ["professionSkillLineID"] = 393, ["missingProfessionSkillLineID"] = 2917, ["locationID"] = 6666666, },

  {["label"] = "Midnight Tailoring", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP12147", ["notInGroup"] = false,
  ["professionSkillLineID"] = 197, ["missingProfessionSkillLineID"] = 2918, ["locationID"] = 6666666, },

--{["label"] = "Cultist", ["frameID"] = "bar1", ["key"] = "12pxp:cultist:rare",
--["questID"] = 91795, ["requireInLog"] = false, ["hideWhenCompleted"] = false, ["showXWhenComplete"] = true,
--["questInfo"] = "Cultist %p", ["playerLevel"] = { ">=", 20, },
--["progress"] = { ["merge"] = { { ["questID"] = 91795, ["objectiveIndex"] = 1 }, { ["questID"] = 87308, ["objectiveIndex"] = 1 }, }, ["sep"] = " | ", ["requireAll"] = true, },
--["complete"] = { ["all"] = { { ["questID"] = 91795 }, { ["questID"] = 87308 }, }, }, ["completeMode"] = "replace",},



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
