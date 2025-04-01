-- DotMaster nameplate_detection.lua
-- Handles debuff detection on nameplates

local DM = DotMaster

-- Checks for tracked debuffs on a unit
function DM:CheckForTrackedDebuffs(unitToken)
  if not unitToken or not UnitExists(unitToken) then return nil end

  DM:NameplateDebug("CheckForTrackedDebuffs called: %s", unitToken)

  -- If no spell config is present, early return
  if not self.spellConfig or not next(self.spellConfig) then return nil end

  -- Check each spell config in priority order (if available)
  local sortedConfigs = {}
  for spellIDString, config in pairs(self.spellConfig) do
    if config.enabled then
      table.insert(sortedConfigs, { id = spellIDString, priority = config.priority or 999, config = config })
    end
  end

  -- Sort by priority (lower numbers = higher priority)
  table.sort(sortedConfigs, function(a, b) return (a.priority or 999) < (b.priority or 999) end)

  -- Check each spell in priority order
  for _, entry in ipairs(sortedConfigs) do
    local spellIDString = entry.id
    local config = entry.config

    DM:NameplateDebug("Checking SpellID: %s, Priority: %s", tostring(spellIDString), tostring(config.priority or "none"))

    -- Get the numeric spell ID
    local spellID = tonumber(spellIDString)
    if spellID then
      DM:NameplateDebug("Checking spell: %d", spellID)

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
            DM:NameplateDebug("Debuff present, returning color: %s", tostring(spellIDString))
            return config.color, spellID
          end
        end
      end
    else
      DM:NameplateDebug("Invalid spell ID: %s", tostring(spellIDString))
    end
  end

  DM:NameplateDebug("No tracked debuffs found")
  return nil
end
