-- DotMaster nameplate_detection.lua
-- Handles debuff detection on nameplates

local DM = DotMaster

-- Debug function specifically for nameplate operations
function DM:NameplateDebug(message, ...)
  if not DM.DEBUG_CATEGORIES or not DM.DEBUG_CATEGORIES.nameplate then return end

  local prefix = "|cFF88AAFF[NAMEPLATE]|r "
  if select('#', ...) > 0 then
    DM:DebugMsg(prefix .. message, ...)
  else
    DM:DebugMsg(prefix .. message)
  end
end

-- Function to get the player's current class
function DM.GetPlayerClass()
  local _, class = UnitClass("player")
  return class
end

-- Helper function to check if a specific DoT is on a unit
function DM:HasPlayerDotOnUnit(unitToken, spellID)
  if not unitToken or not UnitExists(unitToken) or not spellID then return false end

  DM:NameplateDebug("HasPlayerDotOnUnit called: %s, SpellID: %d", unitToken, spellID)

  local dotFound = false
  local errorMsg = nil

  -- Method 1: Check if we can use the C_UnitAuras API (newer clients)
  if C_UnitAuras then
    DM:NameplateDebug("Trying C_UnitAuras API")

    if C_UnitAuras.GetAuraDataByUnit then
      local success, result = pcall(function()
        local auras = C_UnitAuras.GetAuraDataByUnit(unitToken, "HARMFUL")
        if auras then
          for _, auraData in ipairs(auras) do
            if auraData.spellId == spellID and auraData.sourceUnit == "player" then
              DM:NameplateDebug("Found DoT with C_UnitAuras: %s", auraData.name or "Unknown")
              return true
            end
          end
        end
        return false
      end)

      if success then
        dotFound = result
        if dotFound then return true end
      else
        errorMsg = "Error in C_UnitAuras: " .. tostring(result)
        DM:NameplateDebug(errorMsg)
      end
    else
      DM:NameplateDebug("GetAuraDataByUnit not available, trying GetAuraDataBySpellID")

      -- Try GetAuraDataBySpellID as an alternative
      if C_UnitAuras.GetAuraDataBySpellID then
        local success, result = pcall(function()
          local auraData = C_UnitAuras.GetAuraDataBySpellID(unitToken, spellID)
          if auraData and auraData.sourceUnit == "player" then
            DM:NameplateDebug("Found DoT with GetAuraDataBySpellID: %s", auraData.name or "Unknown")
            return true
          end
          return false
        end)

        if success then
          dotFound = result
          if dotFound then return true end
        else
          errorMsg = "Error in GetAuraDataBySpellID: " .. tostring(result)
          DM:NameplateDebug(errorMsg)
        end
      end
    end
  end

  -- Method 2: Try AuraUtil.ForEachAura which works on most client versions
  if not dotFound and AuraUtil and AuraUtil.ForEachAura then
    DM:NameplateDebug("Trying AuraUtil.ForEachAura")

    local success, result = pcall(function()
      local found = false
      AuraUtil.ForEachAura(unitToken, "HARMFUL", nil, function(name, _, _, _, _, _, caster, _, _, id)
        if id == spellID and caster == "player" then
          DM:NameplateDebug("Found DoT with ForEachAura: %s", name or "Unknown")
          found = true
          return true -- Stop iteration
        end
      end)
      return found
    end)

    if success then
      dotFound = result
      if dotFound then return true end
    else
      errorMsg = "Error in AuraUtil.ForEachAura: " .. tostring(result)
      DM:NameplateDebug(errorMsg)
    end
  end

  -- Method 3: Fallback to AuraUtil only since UnitAura is not available
  if not dotFound then
    DM:NameplateDebug("Trying final AuraUtil fallback")

    local success, result = pcall(function()
      local found = false

      -- Skip UnitAura completely and just use AuraUtil as final fallback
      if AuraUtil and AuraUtil.ForEachAura then
        DM:NameplateDebug("Using AuraUtil.ForEachAura as final fallback")
        AuraUtil.ForEachAura(unitToken, "HARMFUL", nil, function(name, _, _, _, _, _, caster, _, _, id)
          if id == spellID and caster == "player" then
            DM:NameplateDebug("Found DoT with final AuraUtil fallback: %s", name or "Unknown")
            found = true
            return true
          end
        end)
      else
        DM:NameplateDebug("No fallback available - AuraUtil unavailable")
      end

      return found
    end)

    if success then
      dotFound = result
      if dotFound then return true end
    else
      errorMsg = "Error in final fallback: " .. tostring(result)
      DM:NameplateDebug(errorMsg)
    end
  end

  DM:NameplateDebug("DoT not found for SpellID: %d on unit %s", spellID, unitToken)
  return false
end

-- Checks for tracked debuffs on a unit
function DM:CheckForTrackedDebuffs(unitToken)
  if not unitToken or not UnitExists(unitToken) then return nil end

  DM:NameplateDebug("CheckForTrackedDebuffs called: %s", unitToken)

  -- First, check for combinations if the feature is enabled
  if DM.combinations and DM.combinations.settings.enabled then
    local comboID, comboData = self:CheckCombinationsOnUnit(unitToken)

    if comboID and comboData and comboData.color then
      DM:NameplateDebug("Found active combination: %s", comboData.name or comboID)

      -- Format the color to work with the nameplate system
      local comboColor = {
        comboData.color.r or comboData.color[1] or 1,
        comboData.color.g or comboData.color[2] or 0,
        comboData.color.b or comboData.color[3] or 0
      }

      return "combo_" .. comboID, comboColor
    end
  end

  -- If no spell database is present, early return
  if not self.dmspellsdb or not next(self.dmspellsdb) then return nil end

  -- Get current player class
  local playerClass = DM.GetPlayerClass()

  -- Check each spell config in priority order (if available)
  local sortedConfigs = {}
  for spellID, config in pairs(self.dmspellsdb) do
    -- Only include spells that are:
    -- 1. Enabled (for nameplate coloring)
    -- 2. Tracked (for display)
    -- 3. Belong to the player's current class
    if config.enabled == 1 and
        config.tracked == 1 and
        config.wowclass == playerClass then
      table.insert(sortedConfigs, { id = spellID, priority = config.priority or 999, config = config })
      DM:NameplateDebug("Added spell to check list: %d (%s) for class %s",
        spellID, config.spellname or "Unknown", playerClass)
    end
  end

  -- If no applicable spells found, return early
  if #sortedConfigs == 0 then
    DM:NameplateDebug("No matching spells found for player class: %s", playerClass)
    return nil
  end

  -- Sort by priority (lower numbers = higher priority)
  table.sort(sortedConfigs, function(a, b) return (a.priority or 999) < (b.priority or 999) end)

  -- Check each spell in priority order
  for _, entry in ipairs(sortedConfigs) do
    local spellID = entry.id
    local config = entry.config

    DM:NameplateDebug("Checking SpellID: %d, Priority: %s", spellID, tostring(config.priority or "none"))

    -- Check if the spell is active using our helper function
    if self:HasPlayerDotOnUnit(unitToken, spellID) then
      DM:NameplateDebug("Found debuff: %d", spellID)
      return spellID, config.color
    end
  end

  DM:NameplateDebug("No tracked debuffs found")
  return nil
end

-- Gets all active DoTs on a unit with their expiration times and colors
function DM:GetActiveDots(unitToken)
  if not unitToken or not UnitExists(unitToken) then return {} end

  DM:NameplateDebug("GetActiveDots called: %s", unitToken)

  -- If no spell database is present, early return
  if not self.dmspellsdb or not next(self.dmspellsdb) then
    DM:NameplateDebug("No spell database found")
    return {}
  end

  -- Return value: table of active DoTs indexed by spellID
  local activeDots = {}

  -- Get current player class
  local playerClass = DM.GetPlayerClass()
  DM:NameplateDebug("Player class: %s", playerClass)

  -- Debug the spell database entries for this class
  if playerClass == "PRIEST" then
    DM:NameplateDebug("Debugging PRIEST spell database entries:")
    local count = 0
    local enabledCount = 0
    local trackedCount = 0
    for spellID, config in pairs(self.dmspellsdb) do
      if config.wowclass == playerClass then
        count = count + 1
        if config.enabled == 1 then
          enabledCount = enabledCount + 1
        end
        if config.tracked == 1 then
          trackedCount = trackedCount + 1
        end
        DM:NameplateDebug("  SpellID: %d, Name: %s, Enabled: %d, Tracked: %d",
          spellID, config.spellname or "Unknown", config.enabled or 0, config.tracked or 0)
      end
    end
    DM:NameplateDebug("Found %d total PRIEST spells, %d enabled, %d tracked", count, enabledCount, trackedCount)
  end

  -- First identify which spells we need to check
  local spellsToCheck = {}
  local spellCount = 0
  for spellID, config in pairs(self.dmspellsdb) do
    -- Only include spells that are:
    -- 1. Enabled (for nameplate coloring)
    -- 2. Tracked (for display)
    -- 3. Belong to the player's current class
    if config.enabled == 1 and
        config.tracked == 1 and
        config.wowclass == playerClass then
      spellsToCheck[spellID] = config
      spellCount = spellCount + 1
    end
  end

  DM:NameplateDebug("Found %d spells to check for class %s", spellCount, playerClass)
  if spellCount == 0 then return {} end

  -- Now check each spell for presence and gather expiration info
  local apiMethodUsed = "none"
  local errorMsg = nil
  local foundDotsWithMethod = false

  -- Method 1: Try the C_UnitAuras API (newer clients)
  if not foundDotsWithMethod and C_UnitAuras then
    DM:NameplateDebug("Trying C_UnitAuras API")

    if C_UnitAuras.GetAuraDataByUnit then
      local success, result = pcall(function()
        local dotsFound = 0
        -- Get all auras on the unit
        local auras = C_UnitAuras.GetAuraDataByUnit(unitToken, "HARMFUL")
        if auras then
          for _, auraData in ipairs(auras) do
            local spellID = auraData.spellId
            -- Only track if it's a spell we care about and it's cast by the player
            if spellsToCheck[spellID] and auraData.sourceUnit == "player" then
              -- If we get here, we found one of our DoTs
              activeDots[spellID] = {
                name = auraData.name,
                icon = auraData.icon,
                duration = auraData.duration,
                expirationTime = auraData.expirationTime,
                applications = auraData.applications or 1,
                color = spellsToCheck[spellID].color,
                priority = spellsToCheck[spellID].priority or 999
              }
              dotsFound = dotsFound + 1
            end
          end
        end
        return dotsFound
      end)

      if success then
        apiMethodUsed = "C_UnitAuras.GetAuraDataByUnit"
        DM:NameplateDebug("Found %d active DoTs using " .. apiMethodUsed, result)
        -- If we found DoTs, no need to try other methods
        if result > 0 then
          foundDotsWithMethod = true
        end
      else
        errorMsg = "Error in C_UnitAuras: " .. tostring(result)
        DM:NameplateDebug(errorMsg)
      end
    end
  end

  -- Method 2: Try AuraUtil.ForEachAura which works on most client versions
  if not foundDotsWithMethod and AuraUtil and AuraUtil.ForEachAura then
    DM:NameplateDebug("Trying AuraUtil.ForEachAura")

    local success, result = pcall(function()
      local dotsFound = 0
      AuraUtil.ForEachAura(unitToken, "HARMFUL", nil,
        function(name, icon, count, _, duration, expirationTime, caster, _, _, id, _, _, _, _, _)
          if spellsToCheck[id] and caster == "player" then
            -- If we get here, we found one of our DoTs
            activeDots[id] = {
              name = name,
              icon = icon,
              duration = duration,
              expirationTime = expirationTime,
              applications = count or 1,
              color = spellsToCheck[id].color,
              priority = spellsToCheck[id].priority or 999
            }
            dotsFound = dotsFound + 1
          end
        end)
      return dotsFound
    end)

    if success then
      apiMethodUsed = "AuraUtil.ForEachAura"
      DM:NameplateDebug("Found %d active DoTs using " .. apiMethodUsed, result)
      -- If we found DoTs, no need to try other methods
      if result > 0 then
        foundDotsWithMethod = true
      end
    else
      errorMsg = "Error in AuraUtil.ForEachAura: " .. tostring(result)
      DM:NameplateDebug(errorMsg)
    end
  end

  -- Method 3: Fallback to AuraUtil only since UnitAura is not available
  if not foundDotsWithMethod then
    DM:NameplateDebug("Trying final AuraUtil fallback")

    local success, result = pcall(function()
      local dotsFound = 0

      -- Skip UnitAura completely and just use AuraUtil as final fallback
      if AuraUtil and AuraUtil.ForEachAura then
        DM:NameplateDebug("Using AuraUtil.ForEachAura as final fallback")
        AuraUtil.ForEachAura(unitToken, "HARMFUL", nil,
          function(name, icon, count, _, duration, expirationTime, caster, _, _, id, _, _, _, _, _)
            if spellsToCheck[id] and caster == "player" then
              -- If we get here, we found one of our DoTs
              activeDots[id] = {
                name = name,
                icon = icon,
                duration = duration,
                expirationTime = expirationTime,
                applications = count or 1,
                color = spellsToCheck[id].color,
                priority = spellsToCheck[id].priority or 999
              }
              dotsFound = dotsFound + 1
            end
          end)
      else
        DM:NameplateDebug("No fallback available - both UnitAura and AuraUtil unavailable")
      end

      return dotsFound
    end)

    if success then
      apiMethodUsed = "AuraUtil.ForEachAura(final)"
      DM:NameplateDebug("Found %d active DoTs using " .. apiMethodUsed, result)
    else
      errorMsg = "Error in final fallback: " .. tostring(result)
      DM:NameplateDebug(errorMsg)
    end
  end

  -- Count how many we found across all methods
  local totalDotsFound = 0
  for _ in pairs(activeDots) do totalDotsFound = totalDotsFound + 1 end

  DM:NameplateDebug("GetActiveDots returning %d DoTs for unit %s", totalDotsFound, unitToken)

  return activeDots
end
