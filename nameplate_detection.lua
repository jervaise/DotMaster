-- DotMaster nameplate_detection.lua
-- Handles debuff detection on nameplates

local DM = DotMaster

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

  -- Get current player class
  local playerClass = DM.GetPlayerClass()

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

  -- Check each spell config in priority order (if available)
  local sortedConfigs = {}
  for spellID, config in pairs(self.dmspellsdb) do
    -- Only include spells that are:
    -- 1. Enabled (for nameplate coloring)
    -- 2. Tracked (for display)
    -- 3. Belong to the player's current class or are unknown class
    if config.enabled == 1 and
        config.tracked == 1 and
        (config.wowclass == playerClass or config.wowclass == "UNKNOWN") then
      table.insert(sortedConfigs, { id = spellID, priority = config.priority or 999, config = config })
      DM:NameplateDebug("Added spell to check list: %d (%s) for class %s",
        spellID, config.spellname or "Unknown", config.wowclass or "Unknown")
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

-- Get all tracked and enabled DoTs on a unit (returns a table of spell IDs)
function DM:GetActiveDots(unitToken)
  if not unitToken or not UnitExists(unitToken) then return {} end

  DM:NameplateDebug("GetActiveDots called for unit: %s", unitToken)

  local activeDots = {}

  -- Get current player class
  local playerClass = DM.GetPlayerClass()
  DM:NameplateDebug("Checking active dots for class: %s", playerClass)

  -- If no spell database is present, early return
  if not self.dmspellsdb or not next(self.dmspellsdb) then
    DM:NameplateDebug("No spell database present")
    return activeDots
  end

  -- First scan all tracked and enabled spells
  for spellID, config in pairs(self.dmspellsdb) do
    -- Convert to numbers for comparison if they are strings
    local tracked = tonumber(config.tracked) or 0
    local enabled = tonumber(config.enabled) or 0

    -- Only check for dots belonging to the player's class
    if tracked == 1 and enabled == 1 and (config.wowclass == playerClass or config.wowclass == "UNKNOWN") then
      if self:HasPlayerDotOnUnit(unitToken, spellID) then
        table.insert(activeDots, spellID)
        DM:NameplateDebug("Found active dot: %d (%s)", spellID, config.spellname or "Unknown")
      end
    end
  end

  DM:NameplateDebug("GetActiveDots found %d active dots for class %s", #activeDots, playerClass)
  return activeDots
end
