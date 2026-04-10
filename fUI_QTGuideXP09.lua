local addonName, ns = ...

-- Auto-generated split from fr0z3nUI_QuestTracker_DB2.lua on 20260121_173032
-- Expansion DB09 (Shadowlands)

ns.rules = ns.rules or {}

local EXPANSION_ID = 9
local EXPANSION_NAME = "Shadowlands"

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

{["label"] = "SU  09  Open", ["frameID"] = "list1", ["key"] = "custom:q:60151:list1:XP09011",
["questID"] = 60150, ["hideWhenCompleted"] = true, ["hideIfAnyQuestCompleted"] = { 60151, 61874, 999999 },
["questInfo"] = "Warboard   (Accept if there)\n    - Chromie\n    - Legion\n    - Warlords\n    - Jade Forest\n\nShadowlands\n + Chromie: Shadowlands\n + Enter Shadowlands\n    - Skip Quests at Broker NPC\n    - Learn Professions\nToDo", },

{["itemName"] = "The Brokers Angle'r", ["frameID"] = "list1", ["key"] = "custom:item:180136:list1:145",
["itemInfo"] = "The Brokers Angle'r",
["locationID"] = "1670", ["restedOnly"] = true, ["item"] = { ["itemID"] = 180136, ["required"] = { 1, true, N, 0 }, }, },







-- PROFESSIONS
  {["label"] = "Shadowlands Alchemy", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP09152", ["notInGroup"] = false,
  ["professionSkillLineID"] = 171, ["missingProfessionSkillLineID"] = 2750, ["locationID"] = "1670", },

  {["label"] = "Shadowlands Blacksmithing", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP09153", ["notInGroup"] = false,
  ["professionSkillLineID"] = 164, ["missingProfessionSkillLineID"] = 2751, ["locationID"] = "1670", },

  {["label"] = "Shadowlands Cooking", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP09144", ["notInGroup"] = false,
  ["professionSkillLineID"] = 185, ["missingProfessionSkillLineID"] = 2752, ["locationID"] = "1670", },

  {["label"] = "Shadowlands Enchanting", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP09154", ["notInGroup"] = false,
  ["professionSkillLineID"] = 333, ["missingProfessionSkillLineID"] = 2753, ["locationID"] = "1670", },

  {["label"] = "Shadowlands Engineering", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP09151", ["notInGroup"] = false,
  ["professionSkillLineID"] = 202, ["missingProfessionSkillLineID"] = 2755, ["locationID"] = "1670", },

  {["label"] = "Shadowlands Fishing", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP09146", ["notInGroup"] = false,
  ["professionSkillLineID"] = 356, ["missingProfessionSkillLineID"] = 2754, ["locationID"] = "1670", },

  {["label"] = "Shadowlands Herbalism", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP09150", ["notInGroup"] = false,
  ["professionSkillLineID"] = 182, ["missingProfessionSkillLineID"] = 2760, ["locationID"] = "1670", },

  {["label"] = "Shadowlands Inscription", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP09155", ["notInGroup"] = false,
  ["professionSkillLineID"] = 773, ["missingProfessionSkillLineID"] = 2756, ["locationID"] = "1670", },

  {["label"] = "Shadowlands Jewelcrafting", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP09156", ["notInGroup"] = false,
  ["professionSkillLineID"] = 755, ["missingProfessionSkillLineID"] = 2757, ["locationID"] = "1670", },

  {["label"] = "Shadowlands Leatherworking", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP09157", ["notInGroup"] = false,
  ["professionSkillLineID"] = 165, ["missingProfessionSkillLineID"] = 2758, ["locationID"] = "1670", },

  {["label"] = "Shadowlands Mining", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP09149", ["notInGroup"] = false,
  ["professionSkillLineID"] = 186, ["missingProfessionSkillLineID"] = 2761, ["locationID"] = "1670", },

  {["label"] = "Shadowlands Skinning", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP09148", ["notInGroup"] = false,
  ["professionSkillLineID"] = 393, ["missingProfessionSkillLineID"] = 2762, ["locationID"] = "1670", },

  {["label"] = "Shadowlands Tailoring", ["frameID"] = "list1", ["key"] = "custom:spell:list1:XP09147", ["notInGroup"] = false,
  ["professionSkillLineID"] = 197, ["missingProfessionSkillLineID"] = 2759, ["locationID"] = "1670", },

--{["label"] = "Warboard   (Accept if there)\n    - Chromie\n    - Legion\n    - Warlords\n    - Jade Forest\n\nShadowlands\n + Chromie: Shadowlands\n + Enter Shadowlands\n    - Skip Quests at Broker NPC\n    - Learn Professions", ["frameID"] = "list1", ["key"] = "custom:spell:list1:152",
--["hideWhenCompleted"] = false,
--["notInGroup"] = false,
--["notSpellKnown"] = 310542, },

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
