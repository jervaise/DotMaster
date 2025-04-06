-- DotMaster spell_utils.lua
-- Spell utility functions

local DM = DotMaster

-- Get spell name from ID
function DM:GetSpellName(spellID)
  if not spellID then return "Unknown" end

  local numericID = tonumber(spellID)
  if not numericID then return "Unknown" end

  -- First check our spell database
  if self.spellDatabase and self.spellDatabase[numericID] and self.spellDatabase[numericID].name then
    return self.spellDatabase[numericID].name
  end

  -- If not in database, try the API
  local name
  if C_Spell and C_Spell.GetSpellInfo then
    local spellInfo = C_Spell.GetSpellInfo(numericID)
    if spellInfo then
      name = spellInfo.name
    end
  end

  if name then
    -- If successful and database exists, add to database
    if self.spellDatabase then
      if not self.spellDatabase[numericID] then
        self.spellDatabase[numericID] = {
          name = name,
          class = "UNKNOWN",
          spec = "General",
          firstSeen = GetServerTime(),
          lastUsed = GetServerTime(),
          useCount = 1
        }
      end
    end
    return name
  end

  -- If all else fails
  return "Spell #" .. numericID
end
