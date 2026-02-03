local addonName, ns = ...

-- Expansion DB01 (Classic)

ns.rules = ns.rules or {}

local EXPANSION_ID = 1
local EXPANSION_NAME = "Classic"

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

-- Item fields
--   item.required = { count, hideWhenAcquired, autoBuyEnabled, autoBuyMax }
--     REQ_COUNT  = 1
--     REQ_HIDE   = 2
--     REQ_BUY_ON = 3
--     REQ_BUY_MAX= 4
--   item.buy      = { enabled = Y/N, max = number }  -- mirrored to required tuple (default off)

local REQ_COUNT, REQ_HIDE, REQ_BUY_ON, REQ_BUY_MAX = 1, 2, 3, 4

local bakedRules = {

-- ALLIANCE TABARDS     (Stormwind 84 - Darnassus 89)
{["group"] = "classic:tabards:alliance-tabards", ["order"] = 1,
["label"] = "Stormwind Tabard", ["faction"] = "Alliance", ["frameID"] = "list1", ["key"] = "custom:item:45574:list1:0101",
["itemInfo"] = "Stormwind Tabard\n - Trade District, Near FP", ["rep"] = { ["sellWhenExalted"] = Y, ["factionID"] = 72, }, 
["item"] = { ["itemID"] = 45574, ["required"] = { 1, Y, Y, 1 }, }, ["locationID"] = "84, ", ["restedOnly"] = Y,
["complete"] = { ["any"] = { { ["item"] = { ["itemID"] = 45574, ["count"] = 1 } }, { ["rep"] = { ["factionID"] = 72, ["minStanding"] = 8 } }, }, }, },

{["group"] = "classic:tabards:alliance-tabards", ["order"] = 2,
["label"] = "Tushui Tabard", ["faction"] = "Alliance", ["frameID"] = "list1", ["key"] = "custom:item:83079:list1:0102",
["itemInfo"] = "Tushui Tabard\n - Dwarven Dist. Cata Portals", ["rep"] = { ["sellWhenExalted"] = true, ["factionID"] = 1353, }, 
["item"] = { ["itemID"] = 83079, ["required"] = { 1, Y, Y, 1 }, }, ["locationID"] = "84, ", ["restedOnly"] = true,
["complete"] = { ["any"] = { { ["item"] = { ["itemID"] = 83079, ["count"] = 1 } }, { ["rep"] = { ["factionID"] = 1353, ["minStanding"] = 8 } }, }, }, },

{["group"] = "classic:tabards:alliance-tabards", ["order"] = 3,
["label"] = "Darnassus Tabard", ["faction"] = "Alliance", ["frameID"] = "list1", ["key"] = "custom:seq:item:45579:list1:0103",
["itemInfo"] = "Darnassus Tabard\n - Darnassus Portal (Docks)\n - If Burnt, Travel to Past\n - Buy from Tabard Vendor",
["item"] = { ["itemID"] = 45579, ["required"] = { 1, Y, Y, 1 }, }, ["rep"] = { ["sellWhenExalted"] = Y, ["factionID"] = 69, },
["locationID"] = "84, 62, 57, 89", ["restedOnly"] = N,
["complete"] = { ["any"] = { { ["item"] = { ["itemID"] = 45579, ["count"] = 1 } }, { ["rep"] = { ["factionID"] = 69, ["minStanding"] = 8 } }, }, }, },

{["group"] = "classic:tabards:alliance-tabards", ["order"] = 4,
 ["label"] = "Gilneas Tabard", ["faction"] = "Alliance", ["frameID"] = "list1", ["key"] = "custom:seq:item:64882:list1:0104",
["itemInfo"] = "Gilneas Tabard\n - Darnassus Portal (Docks)\n - If Burnt, Travel to Past\n - Buy from Tabard Vendor",
["item"] = { ["itemID"] = 64882, ["required"] = { 1, Y, Y, 1 }, }, ["rep"] = { ["sellWhenExalted"] = Y, ["factionID"] = 1134, },
["locationID"] = "84, 62, 57, 89", ["restedOnly"] = N,
["complete"] = { ["any"] = { { ["item"] = { ["itemID"] = 64882, ["count"] = 1 } }, { ["rep"] = { ["factionID"] = 1134, ["minStanding"] = 8 } }, }, }, },

{["group"] = "classic:tabards:alliance-tabards", ["order"] = 5,
["label"] = "Exodar Tabard", ["faction"] = "Alliance", ["frameID"] = "list1", ["key"] = "custom:seq:item:45580:list1:0105",
["itemInfo"] = "Exodar Tabard\n - Darnassus Portal (Docks)\n - If Burnt, Travel to Past\n - Exodar Portal Dock/Temple\n - Buy from Tabard Vendor",
["item"] = { ["itemID"] = 45580, ["required"] = { 1, Y, Y, 1 }, }, ["rep"] = { ["sellWhenExalted"] = Y, ["factionID"] = 930, },
["locationID"] = "84, 62, 57, 89, 103", ["restedOnly"] = N,
["complete"] = { ["any"] = { { ["item"] = { ["itemID"] = 45580, ["count"] = 1 } }, { ["rep"] = { ["factionID"] = 930, ["minStanding"] = 8 } }, }, }, },

{["group"] = "classic:tabards:alliance-tabards", ["order"] = 6,
["label"] = "Ironforge Tabard", ["faction"] = "Alliance", ["frameID"] = "list1", ["key"] = "custom:item:45577:list1:0107",
["itemInfo"] = "Ironforge Tabard\n - Ironforge Near FP", ["rep"] = { ["sellWhenExalted"] = Y, ["factionID"] = 47, },
["item"] = { ["itemID"] = 45577, ["required"] = { 1, Y, Y, 1 }, }, ["locationID"] = "84, ", ["restedOnly"] = Y,
["complete"] = { ["any"] = { { ["item"] = { ["itemID"] = 45577, ["count"] = 1 } }, { ["rep"] = { ["factionID"] = 47, ["minStanding"] = 8 } }, }, }, },

{["group"] = "classic:tabards:alliance-tabards", ["order"] = 7,
["label"] = "Gnomeregan Tabard", ["faction"] = "Alliance", ["frameID"] = "list1", ["key"] = "custom:item:45578:list1:0106",
["itemInfo"] = "Gnomeregan Tabard\n Ironforge Near FP", ["rep"] = { ["sellWhenExalted"] = Y, ["factionID"] = 54, },
["item"] = { ["itemID"] = 45578, ["required"] = { 1, Y, Y, 1 }, }, ["locationID"] = "84, ", ["restedOnly"] = Y,
["complete"] = { ["any"] = { { ["item"] = { ["itemID"] = 45578, ["count"] = 1 } }, { ["rep"] = { ["factionID"] = 54, ["minStanding"] = 8 } }, }, }, },


-- HORDE TABARDS     (Orgrimmar 85)
{["group"] = "classic:tabards:horde-tabards", ["order"] = 1,
["label"] = "Orgrimmar Tabard", ["faction"] = "Horde", ["frameID"] = "list1", ["key"] = "custom:item:45581:list1:0108",
["itemInfo"] = "Orgrimmar Tabard", ["rep"] = { ["sellWhenExalted"] = Y, ["factionID"] = 76, },
["item"] = { ["itemID"] = 45581, ["required"] = { 1, Y, Y, 1 }, }, ["locationID"] = "85, 85", ["restedOnly"] = Y,
["complete"] = { ["any"] = { { ["item"] = { ["itemID"] = 45581, ["count"] = 1 } }, { ["rep"] = { ["factionID"] = 76, ["minStanding"] = 8 } }, }, }, },

{["group"] = "classic:tabards:horde-tabards", ["order"] = 2,
["label"] = "Darkspear Tabard", ["faction"] = "Horde", ["frameID"] = "list1", ["key"] = "custom:item:45582:list1:0109",
["itemInfo"] = "Darkspear Tabard", ["rep"] = { ["sellWhenExalted"] = Y, ["factionID"] = 530, },
["item"] = { ["itemID"] = 45582, ["required"] = { 1, Y, Y, 1 }, }, ["locationID"] = "85, 85", ["restedOnly"] = Y,
["complete"] = { ["any"] = { { ["item"] = { ["itemID"] = 45582, ["count"] = 1 } }, { ["rep"] = { ["factionID"] = 530, ["minStanding"] = 8 } }, }, }, },

{["group"] = "classic:tabards:horde-tabards", ["order"] = 3,
["label"] = "Bilgewater Tabard", ["faction"] = "Horde", ["frameID"] = "list1", ["key"] = "custom:item:64884:list1:0110",
["itemInfo"] = "Bilgewater Tabard", ["rep"] = { ["sellWhenExalted"] = Y, ["factionID"] = 1133, },
["item"] = { ["itemID"] = 64884, ["required"] = { 1, Y, Y, 1 }, }, ["locationID"] = "85, 85, ", ["restedOnly"] = true,
["complete"] = { ["any"] = { { ["item"] = { ["itemID"] = 64884, ["count"] = 1 } }, { ["rep"] = { ["factionID"] = 1133, ["minStanding"] = 8 } }, }, }, },

{["group"] = "classic:tabards:horde-tabards", ["order"] = 4,
["label"] = "Huojin Tabard", ["faction"] = "Horde", ["frameID"] = "list1", ["key"] = "custom:item:83080:list1:0112",
["itemInfo"] = "Huojin Tabard", ["rep"] = { ["sellWhenExalted"] = Y, ["factionID"] = 1352, },
["item"] = { ["itemID"] = 83080, ["required"] = { 1, Y, Y, 1 }, }, ["locationID"] = "85, 85,", ["restedOnly"] = true,
["complete"] = { ["any"] = { { ["item"] = { ["itemID"] = 83080, ["count"] = 1 } }, { ["rep"] = { ["factionID"] = 1352, ["minStanding"] = 8 } }, }, }, },

{["group"] = "classic:tabards:horde-tabards", ["order"] = 5,
["label"] = "Undercity Tabard", ["faction"] = "Horde", ["frameID"] = "list1", ["key"] = "custom:item:45583:list1:0111",
["itemInfo"] = "Undercity Tabard", ["rep"] = { ["sellWhenExalted"] = Y, ["factionID"] = 68, },
["item"] = { ["itemID"] = 45583, ["required"] = { 1, Y, Y, 1 }, }, ["locationID"] = "85, 85", ["restedOnly"] = Y,
["complete"] = { ["any"] = { { ["item"] = { ["itemID"] = 45583, ["count"] = 1 } }, { ["rep"] = { ["factionID"] = 68, ["minStanding"] = 8 } }, }, }, },

{["group"] = "classic:tabards:horde-tabards", ["order"] = 6,
["label"] = "Silvermoon Tabard", ["faction"] = "Horde", ["frameID"] = "list1", ["key"] = "custom:item:45585:list1:013",
["itemInfo"] = "Silvermoon Tabard", ["rep"] = { ["sellWhenExalted"] = Y, ["factionID"] = 911, },
["item"] = { ["itemID"] = 45585, ["required"] = { 1, Y, Y, 1 }, }, ["locationID"] = "85, ", ["restedOnly"] = Y,
["complete"] = { ["any"] = { { ["item"] = { ["itemID"] = 45585, ["count"] = 1 } }, { ["rep"] = { ["factionID"] = 911, ["minStanding"] = 8 } }, }, }, },

{["group"] = "classic:tabards:horde-tabards", ["order"] = 7,
["label"] = "Thunder Bluff Tabard", ["faction"] = "Horde", ["frameID"] = "list1", ["key"] = "custom:item:45584:list1:0114",
["itemInfo"] = "Thunder Bluff Tabard", ["rep"] = { ["sellWhenExalted"] = Y, ["factionID"] = 81, },
["item"] = { ["itemID"] = 45584, ["required"] = { 1, Y, Y, 1 }, }, ["locationID"] = "85, ", ["restedOnly"] = Y,
["complete"] = { ["any"] = { { ["item"] = { ["itemID"] = 45584, ["count"] = 1 } }, { ["rep"] = { ["factionID"] = 81, ["minStanding"] = 8 } }, }, }, },


-- NEUTRAL ITEMS
{["group"] = "classic:vendor:red-rider", ["order"] = 1,
["label"]   = "Red Rider Air RIfle", ["frameID"] = "list1", ["key"] = "custom:item:46725:list1:0116",
["itemInfo"] = "Red Rider Air RIfle", ["locationID"] = "84, 85", ["restedOnly"] = Y,
["item"] = { ["itemID"] = 46725, ["required"] = { 1, Y, Y, 1 }, },
["complete"] = { ["any"] = { { ["item"] = { ["itemID"] = 46725, ["count"] = 1 } }, }, }, },

{["group"] = "classic:vendor:red-rider", ["order"] = 2,
["label"]   = "Red Rider Air Ammo", ["frameID"] = "list1", ["key"] = "custom:item:48601:list1:01117",
["itemInfo"] = "Red Rider Air Ammo", ["locationID"] = "84, 85", ["restedOnly"] = Y,
["item"] = { ["itemID"] = 48601, ["required"] = { 1, Y, Y, 1 }, },
["complete"] = { ["any"] = { { ["item"] = { ["itemID"] = 48601, ["count"] = 1 } }, }, }, },

{["label"]   = "Goblin Gliders", ["frameID"] = "list1", ["key"] = "custom:item:109076:list1:0118",
["itemInfo"] = "Goblin Gliders", ["hideWhenCompleted"] = N, ["restedOnly"] = Y,
["item"] = { ["itemID"] = 109076, ["required"] = { 5, Y, N, 0 }, }, },

}

for i = 1, #bakedRules do
  local r = bakedRules[i]
  if type(r) == "table" then
    if r._expansionID == nil then r._expansionID = EXPANSION_ID end
    if r._expansionName == nil then r._expansionName = EXPANSION_NAME end
    if type(r.key) == "string" then
      r.key = r.key:gsub("^custom:", "db:")
    end

    -- Ensure new fields exist on older baked rules.
    -- item.buy is derived from item.required (keeps the DB visible without duplicating values in every rule).
    if type(r.item) == "table" and r.item.itemID then
      local req = r.item.required
      local buyOn, buyMax = nil, nil
      if type(req) == "table" then
        buyOn = (req[REQ_BUY_ON] == Y) and Y or N
        buyMax = tonumber(req[REQ_BUY_MAX]) or 0
        if buyMax < 0 then buyMax = 0 end
      end

      if type(r.item.buy) ~= "table" then
        r.item.buy = { enabled = N, max = 0 }
      end

      if buyOn ~= nil then
        r.item.buy.enabled = buyOn
        r.item.buy.max = buyMax or 0
      else
        if r.item.buy.enabled ~= Y then r.item.buy.enabled = N end
        local m = tonumber(r.item.buy.max) or 0
        if m < 0 then m = 0 end
        r.item.buy.max = m
      end
    end

    ns.rules[#ns.rules + 1] = r
  end
end
