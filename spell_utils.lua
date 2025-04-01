-- DotMaster spell_utils.lua
-- Spell utility functions

local DM = DotMaster

-- Get spell name from ID
function DM:GetSpellName(spellID)
  if not spellID then return "Unknown" end

  local numericID = tonumber(spellID)
  if not numericID then return "Unknown" end

  -- First check our local database
  if DM.SpellNames[numericID] then
    return DM.SpellNames[numericID]
  end

  -- If not in local database, try the API
  local name
  if C_Spell and C_Spell.GetSpellInfo then
    name = C_Spell.GetSpellInfo(numericID)
  end

  if name then
    -- If successful, add to database
    DM.SpellNames[numericID] = name
    return name
  end

  -- If all else fails
  return "Spell #" .. numericID
end

-- Save spell database (optional)
function DM:SaveSpellDatabase()
  -- This function could be used to persistently store spells added at runtime
  -- Not needed in current design, but could be implemented like this:

  -- DotMasterDB.spellNames = DM.SpellNames
end

-- Load spell database (optional)
function DM:LoadSpellDatabase()
  -- This would load saved spells if SaveSpellDatabase was implemented

  -- if DotMasterDB and DotMasterDB.spellNames then
  --   for id, name in pairs(DotMasterDB.spellNames) do
  --     if not DM.SpellNames[id] then
  --       DM.SpellNames[id] = name
  --     end
  --   end
  -- end
end
