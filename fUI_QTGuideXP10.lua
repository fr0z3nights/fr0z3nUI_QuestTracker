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

{label = "SU  10  Dragon Isles  34 Slot Bag", frameID = "list1", key = "custom:q:65646:list1:XP10084",
questID = 65646, prereq = { 67700, }, hideWhenCompleted = true,
questInfo = "+ 34 Bag in Dragon Isles\n   WS 58,53 %c\n07N", },

{label = "SU  10  Dragon Isles  Q-67700  65445  Horde", frameID = "list1", key = "custom:q:67700:list1:XP10085",
questID = 67700, prereq = { 30515, }, hideWhenCompleted = true,
questInfo = "Dragon Isles  (H)\n + Use Dragon Scale\n    or Cata Portal Area\n + Do Initial Quests\n + Take Portal\n ",
faction = "Horde", },

{label = "SU  10  Dragon Isles  Q-67700  65444  Alliance", frameID = "list1", key = "custom:q:67700:list1:XP10086",
questID = 67700, prereq = { 30515, }, hideWhenCompleted = true,
questInfo = "Dragon Isles\n + Use Dragon Scale\n    or Castle Balcony\n + Do Initial Quests\n + Take Portal\n ",
faction = "Alliance", },

-- PROFESSIONS                                            /dump C_Map.GetBestMapForUnit("player")
{label = "Dragon Alchemy", frameID = "list1", key = "custom:spell:list1:XP10152", notInGroup = false,
professionSkillLineID = 171, missingProfessionSkillLineID = 2823, locationID = "1978", },

{label = "Dragon Blacksmithing", frameID = "list1", key = "custom:spell:list1:XP10154", notInGroup = false,
professionSkillLineID = 164, missingProfessionSkillLineID = 2822, locationID = "1978", },

{label = "Dragon Cooking", frameID = "list1", key = "custom:spell:list1:XP10144", notInGroup = false,
professionSkillLineID = 185, missingProfessionSkillLineID = 2824, locationID = "1978", },

{label = "Dragon Enchanting", frameID = "list1", key = "custom:spell:list1:XP10155", notInGroup = false,
professionSkillLineID = 333, missingProfessionSkillLineID = 2825, locationID = "1978", },

{label = "Dragon Engineering", frameID = "list1", key = "custom:spell:list1:XP10151", notInGroup = false,
professionSkillLineID = 202, missingProfessionSkillLineID = 2827, locationID = "1978", },

{label = "Dragon Fishing", frameID = "list1", key = "custom:spell:list1:XP10146", notInGroup = false,
professionSkillLineID = 356, missingProfessionSkillLineID = 2826, locationID = "1978", },

{label = "Dragon Herbalism", frameID = "list1", key = "custom:spell:list1:XP10150", notInGroup = false,
professionSkillLineID = 182, missingProfessionSkillLineID = 2832, locationID = "1978", },

{label = "Dragon Inscription", frameID = "list1", key = "custom:spell:list1:XP10156", notInGroup = false,
professionSkillLineID = 773, missingProfessionSkillLineID = 2828, locationID = "1978", },

{label = "Dragon Jewelcrafting", frameID = "list1", key = "custom:spell:list1:XP10157", notInGroup = false,
professionSkillLineID = 755, missingProfessionSkillLineID = 2829, locationID = "1978", },

{label = "Dragon Leatherworking", frameID = "list1", key = "custom:spell:list1:XP10158", notInGroup = false,
professionSkillLineID = 165, missingProfessionSkillLineID = 2830, locationID = "1978", },

{label = "Dragon Mining", frameID = "list1", key = "custom:spell:list1:XP10149", notInGroup = false,
professionSkillLineID = 186, missingProfessionSkillLineID = 2833, locationID = "1978", },

{label = "Dragon Skinning", frameID = "list1", key = "custom:spell:list1:XP10148", notInGroup = false,
professionSkillLineID = 393, missingProfessionSkillLineID = 2834, locationID = "1978", },

{label = "Dragon Tailoring", frameID = "list1", key = "custom:spell:list1:XP10147", notInGroup = false,
professionSkillLineID = 197, missingProfessionSkillLineID = 2831, locationID = "1978", },



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
