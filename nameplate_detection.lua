-- DotMaster nameplate_detection.lua
-- Handles debuff detection on nameplates

local DM = DotMaster

-- Check for tracked debuffs on a unit - supports multiple comma-separated IDs
function DM:CheckForTrackedDebuffs(unitToken)
  DM:SpellDebug("CheckForTrackedDebuffs called: %s", unitToken)

  -- Create a sorted list of spell IDs by priority
  local spellList = {}
  for spellIDString, config in pairs(self.spellConfig) do
    if config.enabled then
      table.insert(spellList, { id = spellIDString, priority = config.priority or 999, config = config })
    end
  end

  -- Sort by priority
  table.sort(spellList, function(a, b)
    return (a.priority or 999) < (b.priority or 999)
  end)

  -- Check user configured spells in priority order
  for _, spellData in ipairs(spellList) do
    local spellIDString = spellData.id
    local config = spellData.config

    DM:SpellDebug("Checking SpellID: %s, Priority: %s", tostring(spellIDString), tostring(config.priority or "none"))

    -- Convert spellIDString to a numeric ID
    local spellID = tonumber(spellIDString)
    if not spellID then
      DM:SpellDebug("Invalid spell ID: %s", tostring(spellIDString))
      return nil, nil
    end

    DM:SpellDebug("Checking spell: %d", spellID)

    -- Check if the debuff is present
    local debuffPresent = false

    -- Check all HARMFUL auras
    AuraUtil.ForEachAura(unitToken, "HARMFUL", nil, function(_, _, _, _, _, _, source, _, _, auraSpellID)
      DM:SpellDebug("Aura found: %d, Source: %s", auraSpellID, tostring(source))

      -- Check spell ID and source - only accept player-sourced spells
      if auraSpellID == spellID and source == "player" then
        debuffPresent = true
        DM:SpellDebug("Aura matched and is from player!")
        return true -- Exit this loop
      end
    end)

    if debuffPresent then
      DM:SpellDebug("Debuff present, returning color: %s", tostring(spellIDString))
      return spellIDString, config.color
    end
  end

  DM:SpellDebug("No tracked debuffs found")
  return nil, nil
end
