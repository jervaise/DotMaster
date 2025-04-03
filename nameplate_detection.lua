-- DotMaster nameplate_detection.lua
-- Handles debuff detection on nameplates

local DM = DotMaster

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

    -- Check if we can use the C_UnitAuras API (newer clients)
    if C_UnitAuras and C_UnitAuras.GetAuraDataByUnit then
      DM:NameplateDebug("Using C_UnitAuras API")

      -- Get all auras on the unit and check for our spell
      local auras = C_UnitAuras.GetAuraDataByUnit(unitToken, "HARMFUL")
      if auras then
        for _, auraData in ipairs(auras) do
          if auraData.spellId == spellID and auraData.sourceUnit == "player" then
            DM:NameplateDebug("Found debuff using C_UnitAuras: %d", spellID)
            return spellID, config.color
          end
        end
      end
    elseif AuraUtil and AuraUtil.ForEachAura then
      DM:NameplateDebug("Using AuraUtil.ForEachAura API")

      -- Use AuraUtil.ForEachAura which works on all client versions
      local found = false
      AuraUtil.ForEachAura(unitToken, "HARMFUL", nil, function(name, _, _, _, _, _, caster, _, _, id)
        if id == spellID and caster == "player" then
          found = true
          return true -- Stop iteration
        end
      end)

      if found then
        DM:NameplateDebug("Found debuff using AuraUtil: %d", spellID)
        return spellID, config.color
      end
    else
      -- Fallback to UnitAura for legacy support (this branch should not be needed)
      DM:NameplateDebug("Using legacy UnitAura API")

      -- Use pcall to avoid errors if UnitAura doesn't exist
      local success, result = pcall(function()
        for i = 1, 40 do
          local name, _, _, _, _, _, source, _, _, auraSpellID = UnitAura(unitToken, i, "HARMFUL")
          if not name then break end

          if auraSpellID == spellID and source == "player" then
            return true
          end
        end
        return false
      end)

      if success and result then
        DM:NameplateDebug("Found debuff using legacy UnitAura: %d", spellID)
        return spellID, config.color
      end
    end
  end

  DM:NameplateDebug("No tracked debuffs found")
  return nil
end
