-- DotMaster nameplate_detection.lua
-- Handles debuff detection on nameplates

local DM = DotMaster

-- TEMPORARY: Message to show when nameplate functions are called
local DISABLED_MESSAGE = "Nameplate features are temporarily disabled during development."

-- Checks for tracked debuffs on a unit
function DM:CheckForTrackedDebuffs(unitToken)
  if not unitToken or not UnitExists(unitToken) then return nil end

  DM:NameplateDebug("CheckForTrackedDebuffs called: %s", unitToken)

  -- If no spell database is present, early return
  if not self.dmspellsdb or not next(self.dmspellsdb) then return nil end

  -- Check each spell config in priority order (if available)
  local sortedConfigs = {}
  for spellID, config in pairs(self.dmspellsdb) do
    -- Check if spell is enabled (1 = enabled, 0 = disabled) and tracked (1 = tracked, 0 = not tracked)
    if config.enabled == 1 and config.tracked == 1 then
      table.insert(sortedConfigs, { id = spellID, priority = config.priority or 999, config = config })
    end
  end

  -- Sort by priority (lower numbers = higher priority)
  table.sort(sortedConfigs, function(a, b) return (a.priority or 999) < (b.priority or 999) end)

  -- Check each spell in priority order
  for _, entry in ipairs(sortedConfigs) do
    local spellID = entry.id
    local config = entry.config

    DM:NameplateDebug("Checking SpellID: %d, Priority: %s", spellID, tostring(config.priority or "none"))

    -- Get aura information using the WoW API
    for i = 1, 40 do
      local name, _, _, _, _, _, source, _, _, auraSpellID = UnitAura(unitToken, i, "HARMFUL")
      if not name then break end

      DM:NameplateDebug("Aura found: %d, Source: %s", auraSpellID, tostring(source))

      -- Check if this is our spell and it's cast by the player
      if auraSpellID == spellID and source == "player" then
        DM:NameplateDebug("Aura matched and is from player!")

        -- Return this spell's color (if it has one)
        if config.color then
          DM:NameplateDebug("Debuff present, returning color: %d", spellID)
          return spellID, config.color
        end
      end
    end
  end

  DM:NameplateDebug("No tracked debuffs found")
  return nil
end
