-- Plater integration moved from core.lua
local DM = DotMaster

-- Add function to install DotMaster mod into Plater
function DM:InstallPlaterMod()
  -- print("DotMaster: InstallPlaterMod function called!")
  if DotMasterDB then
    -- print("DotMaster: Current DotMasterDB.enabled = " .. (DotMasterDB.enabled and "true" or "false"))
  else
    -- print("DotMaster: ERROR - DotMasterDB not available in InstallPlaterMod")
  end
  -- print("DotMaster: Current DM.enabled = " .. (DM.enabled and "true" or "false"))

  local Plater = _G["Plater"]
  if not (Plater and Plater.db and Plater.db.profile) then
    if not self.platerNotFoundErrorShown then
      DM:PrintMessage("Plater not found or incompatible")
      self.platerNotFoundErrorShown = true
    end
    return
  end

  -- Reset error flag if Plater was found
  self.platerNotFoundErrorShown = nil

  -- Ensure hook_data table exists
  if not Plater.db.profile.hook_data then
    -- If hook_data doesn't exist, Plater isn't fully ready or has an issue.
    if not self.platerHookDataErrorShown then
      DM:PrintMessage("Error: Plater hook data not found. Cannot update 'DotMaster Integration' mod.")
      self.platerHookDataErrorShown = true
    end
    return
  end

  -- Reset error flag if hook_data was found
  self.platerHookDataErrorShown = nil

  -- Get spells and combinations from DotMaster API
  local trackedSpells = DM.API:GetTrackedSpells() or {}
  local combinations = DM.API:GetCombinations() or {}

  -- Get settings with fallback to read directly from DotMasterDB for critical settings
  local settings = DM.API:GetSettings() or {}

  -- Debug the settings we're using
  -- print("DotMaster: InstallPlaterMod using settings:")
  -- print("  - Enabled: " .. (settings.enabled and "true" or "false"))
  -- print("  - Force Threat Color: " .. (settings.forceColor and "true" or "false"))
  -- print("  - Border Only: " .. (settings.borderOnly and "true" or "false"))

  -- For critical settings, ALWAYS use DotMasterDB as the source of truth
  local enabledState
  if DotMasterDB and DotMasterDB.enabled ~= nil then
    enabledState = DotMasterDB.enabled
    -- print("DotMaster: Using enabledState directly from DotMasterDB: " .. (enabledState and "ENABLED" or "DISABLED"))

    -- Also ensure settings.enabled is in sync
    if settings.enabled ~= enabledState then
      -- print("DotMaster: Synchronizing settings.enabled with DotMasterDB.enabled")
      settings.enabled = enabledState
    end
  else
    -- Fallback to settings if DotMasterDB isn't available
    enabledState = settings.enabled
    -- print("DotMaster: DotMasterDB not available, using settings.enabled: " .. (enabledState and "ENABLED" or "DISABLED"))
  end

  -- For critical settings, double-check with DotMasterDB
  if DotMasterDB then
    if DotMasterDB.settings then
      if DotMasterDB.settings.forceColor ~= nil then
        if settings.forceColor ~= DotMasterDB.settings.forceColor then
          -- print("DotMaster: WARNING - Force Threat Color mismatch, using DotMasterDB value")
          settings.forceColor = DotMasterDB.settings.forceColor
        end
      end

      if DotMasterDB.settings.borderOnly ~= nil then
        if settings.borderOnly ~= DotMasterDB.settings.borderOnly then
          -- print("DotMaster: WARNING - Border Only mismatch, using DotMasterDB value")
          settings.borderOnly = DotMasterDB.settings.borderOnly
        end
      end
    end
  end

  -- Ensure flashThresholdSeconds reflects the latest from DB if available just before injection
  if DotMasterDB and DotMasterDB.settings and DotMasterDB.settings.flashThresholdSeconds ~= nil then
    settings.flashThresholdSeconds = DotMasterDB.settings.flashThresholdSeconds
  end

  -- Ensure flashFrequency reflects the latest from DB if available just before injection
  if DotMasterDB and DotMasterDB.settings and DotMasterDB.settings.flashFrequency ~= nil then
    settings.flashFrequency = DotMasterDB.settings.flashFrequency
  end

  -- Ensure flashBrightness reflects the latest from DB if available just before injection
  if DotMasterDB and DotMasterDB.settings and DotMasterDB.settings.flashBrightness ~= nil then
    settings.flashBrightness = DotMasterDB.settings.flashBrightness
  end

  -- Determine effective extendPlaterColors based on borderOnly setting
  local effectiveExtendPlaterColors = settings.extendPlaterColors
  if settings.borderOnly then
    effectiveExtendPlaterColors = false -- If borderOnly is true, extendPlaterColors is treated as false for the script
  end

  -- Format tracked spells for direct embedding
  local spellsLuaCode = "{\n"
  for i, spell in ipairs(trackedSpells) do
    local colorStr = "{"
    if type(spell.color) == "table" then
      if spell.color.r then
        colorStr = string.format("{%s, %s, %s, %s}",
          spell.color.r or 1,
          spell.color.g or 0,
          spell.color.b or 1,
          spell.color.a or 1)
      elseif #spell.color >= 3 then
        colorStr = string.format("{%s, %s, %s, %s}",
          spell.color[1] or 1,
          spell.color[2] or 0,
          spell.color[3] or 1,
          spell.color[4] or 1)
      end
    else
      colorStr = "{1, 0, 1, 1}" -- Default purple
    end

    spellsLuaCode = spellsLuaCode .. string.format(
      "    {spellID = %s, name = %q, color = %s, enabled = true, priority = %s},\n",
      spell.spellID or 0,
      spell.name or ("Spell " .. (spell.spellID or 0)),
      colorStr,
      spell.priority or 50
    )
  end
  spellsLuaCode = spellsLuaCode .. "}"

  -- Format combinations for direct embedding
  local combosLuaCode = "{\n"
  for i, combo in ipairs(combinations) do
    local spellListStr = "{"
    for j, spellID in ipairs(combo.spellList or {}) do
      spellListStr = spellListStr .. spellID
      if j < #combo.spellList then
        spellListStr = spellListStr .. ", "
      end
    end
    spellListStr = spellListStr .. "}"

    local colorStr = "{"
    if type(combo.color) == "table" then
      if combo.color.r then
        colorStr = string.format("{%s, %s, %s, %s}",
          combo.color.r or 1,
          combo.color.g or 0,
          combo.color.b or 1,
          combo.color[4] or 1)
      elseif #combo.color >= 3 then
        colorStr = string.format("{%s, %s, %s, %s}",
          combo.color[1] or 1,
          combo.color[2] or 0,
          combo.color[3] or 1,
          combo.color[4] or 1)
      end
    else
      colorStr = "{1, 0, 1, 1}" -- Default purple
    end

    combosLuaCode = combosLuaCode .. string.format(
      "    {name = %q, spells = %s, color = %s, enabled = true, priority = %s},\n",
      combo.name or "Combo " .. i,
      spellListStr,
      colorStr,
      combo.priority or 10
    )
  end
  combosLuaCode = combosLuaCode .. "}"

  -- Define constructor code with embedded config
  local constructorCode = string.format([[
function(self, unitId, unitFrame, envTable, modTable)
  if not (_G['DotMaster'] and _G['DotMaster'].enabled) then
    return
  end

  -- Configuration and priority order:
  -- 1. Force Threat Color (highest priority)
  -- 2. DoT Combinations
  -- 3. Individual DoT Spells

  -- Directly embed DotMaster configuration
  envTable.DM_SPELLS = %s
  envTable.DM_COMBOS = %s
  envTable.DM_FORCE_THREAT_COLOR = %s
  envTable.DM_BORDER_ONLY = %s
  envTable.DM_EXTEND_PLATER_COLORS = %s

  -- Validate border thickness
  local borderThickness = tonumber(%s)
  if not borderThickness or borderThickness < 1 or borderThickness > 10 then
    borderThickness = 2
  end
  envTable.DM_BORDER_THICKNESS = borderThickness

  envTable.DM_FLASH_EXPIRING = %s
  envTable.DM_FLASH_THRESHOLD = %s

  -- Flash customization settings
  envTable.DM_FLASH_FREQUENCY = %s -- Time in seconds for each flash cycle
  envTable.DM_FLASH_BRIGHTNESS = %s -- Brightness increase (0.2 to 1.0)

  envTable.lastBuildTime = %s

  -- Set border thickness in Plater
  if Plater.db and Plater.db.profile then
    envTable.previousBorderThickness = Plater.db.profile.border_thickness or 1

    if DotMasterDB and not DotMasterDB.originalPlaterBorderThickness then
      DotMasterDB.originalPlaterBorderThickness = envTable.previousBorderThickness
    end

    Plater.db.profile.border_thickness = envTable.DM_BORDER_THICKNESS

    if Plater.UpdateAllPlatesBorderThickness then
      Plater.UpdateAllPlatesBorderThickness()
    end
  end
end]],
    spellsLuaCode, combosLuaCode,
    settings.forceColor and "true" or "false",
    settings.borderOnly and "true" or "false",
    effectiveExtendPlaterColors and "true" or "false",
    settings.borderThickness or 2,
    settings.flashExpiring and "true" or "false",
    settings.flashThresholdSeconds or 3.0,
    settings.flashFrequency or 0.5,
    settings.flashBrightness or 0.3,
    GetTime())

  -- OPTIMIZED: Rewritten update code to fix flashing issues
  local updateCode = [[
function(self, unitId, unitFrame, envTable, modTable)
  if not (_G['DotMaster'] and _G['DotMaster'].enabled) then
    return
  end

  if not unitFrame or not unitFrame.healthBar then
    return
  end

  local unitName = unitFrame.namePlateUnitName or unitId or "Unknown"
  local shouldRefreshColor = false
  local colorApplied = false

  -- Apply color function with integrated flashing logic
  local function applyColor(r, g, b, a, isThreatColor, remainingTimeParam)
    a = a or 1
    colorApplied = true

    local finalR, finalG, finalB, finalA = r, g, b, a
    local actualRemainingTime = remainingTimeParam or 999

    -- Store original color in unitFrame for consistency
    unitFrame.DotMaster_Color = {r = r, g = g, b = b, a = a}

    if envTable.DM_FLASH_EXPIRING and actualRemainingTime < (envTable.DM_FLASH_THRESHOLD or 3.0) then
      -- OPTIMIZATION: Store flash state on unitFrame instead of on script context
      if not unitFrame.DM_colFlash_Timer then
        unitFrame.DM_colFlash_Timer = 0
        unitFrame.DM_colFlash_LastTick = GetTime()
        unitFrame.DM_colFlash_IsLighterPhase = false
      else
        unitFrame.DM_colFlash_Timer = unitFrame.DM_colFlash_Timer + (GetTime() - unitFrame.DM_colFlash_LastTick)
        unitFrame.DM_colFlash_LastTick = GetTime()
      end

      -- Use configurable flash frequency (defaulting to 0.5 if missing)
      local flashFrequency = envTable.DM_FLASH_FREQUENCY or 0.5

      if unitFrame.DM_colFlash_Timer >= flashFrequency then
        unitFrame.DM_colFlash_Timer = 0
        unitFrame.DM_colFlash_IsLighterPhase = not unitFrame.DM_colFlash_IsLighterPhase
      end

      if unitFrame.DM_colFlash_IsLighterPhase then
        -- Use configurable brightness (defaulting to 0.3 if missing)
        local flashBrightness = envTable.DM_FLASH_BRIGHTNESS or 0.3

        finalR = math.min(1, r + flashBrightness)
        finalG = math.min(1, g + flashBrightness)
        finalB = math.min(1, b + flashBrightness)
      end
    else
      -- Clean up flash state when no longer needed
      unitFrame.DM_colFlash_IsLighterPhase = false
    end

    if isThreatColor then
      Plater.SetNameplateColor(unitFrame, finalR, finalG, finalB, finalA)
    elseif envTable.DM_BORDER_ONLY then
      if unitFrame.healthBar.border then
        -- OPTIMIZATION: Only set color if it's actually different
        if not unitFrame.DotMaster_BorderColor or
           unitFrame.DotMaster_BorderColor.r ~= finalR or
           unitFrame.DotMaster_BorderColor.g ~= finalG or
           unitFrame.DotMaster_BorderColor.b ~= finalB or
           unitFrame.DotMaster_BorderColor.a ~= finalA then

          unitFrame.healthBar.border:SetVertexColor(finalR, finalG, finalB, finalA)
          unitFrame.customBorderColor = {finalR, finalG, finalB, finalA}
          unitFrame.DotMaster_BorderColor = {r = finalR, g = finalG, b = finalB, a = finalA}
          shouldRefreshColor = true
        end

        unitFrame.healthBar.border:Show()
      end
    else
      Plater.SetNameplateColor(unitFrame, finalR, finalG, finalB, finalA)
    end
  end

  -- Check for threat coloring (has priority if enabled)
  if envTable.DM_FORCE_THREAT_COLOR then
    local isTanking, status, threatpct = UnitDetailedThreatSituation("player", unitId)
    local isTank = Plater.PlayerIsTank
    if isTank then
      if unitFrame.InCombat and not isTanking then
        local color = Plater.db.profile.tank.colors.noaggro
        applyColor(color[1], color[2], color[3], color[4] or 1, true, 999)
        return
      end
    else
      if unitFrame.InCombat and isTanking then
        local color = Plater.db.profile.dps.colors.aggro
        applyColor(color[1], color[2], color[3], color[4] or 1, true, 999)
        return
      end
    end
  end

  -- Get and sort spells/combos by priority (lower number = higher priority)
  local spells = envTable.DM_SPELLS or {}
  local combos = envTable.DM_COMBOS or {}

  -- Create local copies that we can sort
  local sortedCombos = {}
  for i, combo in ipairs(combos) do
    sortedCombos[i] = combo
  end

  local sortedSpells = {}
  for i, spell in ipairs(spells) do
    sortedSpells[i] = spell
  end

  -- Sort combos by priority (lower number = higher priority)
  table.sort(sortedCombos, function(a, b)
    return (tonumber(a.priority) or 999) < (tonumber(b.priority) or 999)
  end)

  -- Sort spells by priority (lower number = higher priority)
  table.sort(sortedSpells, function(a, b)
    return (tonumber(a.priority) or 999) < (tonumber(b.priority) or 999)
  end)

  -- First check for active DOT combinations
  for i, combo in ipairs(sortedCombos) do
    if combo.enabled and combo.spells then
      local allSpellsPresent = true
      local minRemainingTime = 999

      for _, spellIDToCheck in ipairs(combo.spells) do
        if Plater.NameplateHasAura(unitFrame, spellIDToCheck, true) then
          local sName, _, _, _, sDuration, sExpirationTime = Plater.GetAura(unitFrame.namePlateUnitToken, spellIDToCheck, true)

          if sExpirationTime and sExpirationTime > 0 then
            local thisRemainingTime = math.max(0, sExpirationTime - GetTime())
            minRemainingTime = math.min(minRemainingTime, thisRemainingTime)
          else
            minRemainingTime = 9999
            break
          end
        else
          allSpellsPresent = false
          break
        end
      end

      if allSpellsPresent then
        applyColor(combo.color[1], combo.color[2], combo.color[3], combo.color[4] or 1, false, minRemainingTime)
        if shouldRefreshColor then
          Plater.RefreshNameplateColor(unitFrame)
        end
        return
      end
    end
  end

  -- Process sorted individual spells (higher priority ones first)
  for i, spell in ipairs(sortedSpells) do
    if spell.enabled and spell.spellID and Plater.NameplateHasAura(unitFrame, spell.spellID, true) then
      local spellIDToQuery = spell.spellID
      local sName, _, _, _, sDuration, sExpirationTime = Plater.GetAura(unitFrame.namePlateUnitToken, spellIDToQuery, true)
      local remainingTime = 999
      if sExpirationTime and sExpirationTime > 0 then remainingTime = math.max(0, sExpirationTime - GetTime()) end
      applyColor(spell.color[1], spell.color[2], spell.color[3], spell.color[4] or 1, false, remainingTime)
      if shouldRefreshColor then
        Plater.RefreshNameplateColor(unitFrame)
      end
      return
    end
  end

  -- If we didn't apply any colors this time but previously had colors
  if not colorApplied and unitFrame.DotMaster_Color then
    -- OPTIMIZATION: Clean up after ourselves instead of leaving stale state
    unitFrame.DotMaster_Color = nil
    unitFrame.DotMaster_BorderColor = nil

    -- Reset flash state
    unitFrame.DM_colFlash_Timer = nil
    unitFrame.DM_colFlash_LastTick = nil
    unitFrame.DM_colFlash_IsLighterPhase = nil

    if envTable.DM_BORDER_ONLY then
      if unitFrame.healthBar.border then
        -- Allow Plater to handle the border reset naturally
        unitFrame.customBorderColor = nil
        shouldRefreshColor = true
      end
    else
      shouldRefreshColor = true
    end
  end

  -- Extend Plater Colors to Borders if enabled
  if envTable.DM_EXTEND_PLATER_COLORS and unitFrame.healthBar.border and not colorApplied then
    local r, g, b, a = unitFrame.healthBar:GetStatusBarColor()
    local isCustomColored = unitFrame.UsingCustomColor or unitFrame.PlateFrame.customColor or unitFrame.isForced
    if r and g and b and isCustomColored then
      -- OPTIMIZATION: Only modify border color, don't change Plater profiles
      unitFrame.healthBar.border:SetVertexColor(r, g, b, a or 1)
      unitFrame.customBorderColor = {r, g, b, a or 1}
      unitFrame.healthBar.border:Show()
      shouldRefreshColor = true
    end
  end

  -- OPTIMIZATION: Only refresh the color if something actually changed
  if shouldRefreshColor then
    Plater.RefreshNameplateColor(unitFrame)
  end

  if unitFrame.DM_Text then
    unitFrame.DM_Text:Hide()
  end
end
]]

  -- Add nameplate added hook to run CheckAggro when a nameplate is added
  local nameplatAddedCode = [[
function(self, unitId, unitFrame, envTable, modTable)
  if not (_G['DotMaster'] and _G['DotMaster'].enabled) then
    return
  end

  if envTable.DM_FORCE_THREAT_COLOR and unitFrame and unitId then
    local function applyColor(r, g, b, a, isThreatColor)
      a = a or 1

      if isThreatColor then
        Plater.SetNameplateColor(unitFrame, r, g, b, a)
        return
      end

      if envTable.DM_BORDER_ONLY then
        if unitFrame.healthBar.border then
          unitFrame.healthBar.border:SetVertexColor(r, g, b, a)
          unitFrame.customBorderColor = {r, g, b, a}
          unitFrame.DotMaster_BorderColor = {r = r, g = g, b = b, a = a}
          Plater.RefreshNameplateColor(unitFrame)
          unitFrame.healthBar.border:Show()
        end
      else
        Plater.SetNameplateColor(unitFrame, r, g, b, a)
      end
    end

    local isTanking, status, threatpct = UnitDetailedThreatSituation("player", unitId)
    local isTank = Plater.PlayerIsTank

    if isTank then
      if unitFrame.InCombat and not isTanking then
        local color = Plater.db.profile.tank.colors.noaggro
        applyColor(color[1], color[2], color[3], color[4] or 1, true)
      end
    else
      if unitFrame.InCombat and isTanking then
        local color = Plater.db.profile.dps.colors.aggro
        applyColor(color[1], color[2], color[3], color[4] or 1, true)
      end
    end
  end
end
]]

  local data = Plater.db.profile.hook_data
  local modName = "DotMaster Integration" -- Target the manually added mod
  local foundIndex
  for i, mod in ipairs(data) do
    if mod.Name == modName then
      foundIndex = i
      break
    end
  end

  -- Only proceed if the 'DotMaster Integration' mod was found
  if foundIndex then
    local modEntry = data[foundIndex]
    modEntry.Name = modName                          -- Keep the name as "DotMaster Integration"
    modEntry.Desc = "Managed by DotMaster Addon"     -- Update description
    modEntry.Author = "Jervaise"                     -- Update author
    modEntry.Time = time()
    modEntry.Revision = (modEntry.Revision or 0) + 1 -- Increment revision
    modEntry.PlaterCore = Plater.CoreVersion or 0

    -- CRITICAL: Explicitly set the Enabled state of the mod based on DotMaster settings
    modEntry.Enabled = enabledState
    -- print("DotMaster: Setting DotMaster Integration mod Enabled state to: " .. (enabledState and "ENABLED" or "DISABLED"))

    -- Inject our hooks
    modEntry.Hooks = {
      ["Constructor"] = constructorCode,
      ["Nameplate Updated"] = updateCode,
      ["Nameplate Added"] = nameplatAddedCode
    }
    modEntry.HooksTemp = {
      ["Constructor"] = constructorCode,
      ["Nameplate Updated"] = updateCode,
      ["Nameplate Added"] = nameplatAddedCode
    }
    modEntry.LastHookEdited = "Constructor" -- Indicate which hook was last edited

    local forceColorStatus = settings.forceColor and "enabled" or "disabled"
    -- DM:PrintMessage("Updated 'DotMaster Integration' with " ..
    --   #trackedSpells .. " spells and " .. #combinations .. " combos. Force Threat Color is " .. forceColorStatus ..
    --   ". Mod enabled: " .. (enabledState and "yes" or "no") .. ".")
    -- DM:PrintMessage("|cFFFFFF00Consider using /reload to fully apply these changes.|r")

    -- Recompile hook scripts and refresh plates (needed after changing hooks)
    if Plater.WipeAndRecompileAllScripts then
      Plater.WipeAndRecompileAllScripts("hook")
    end

    -- Force a more aggressive refresh of all Plater plates
    C_Timer.After(0.1, function()
      if Plater.FullRefreshAllPlates then
        -- print("DotMaster: Forcing full Plater refresh...")
        Plater.FullRefreshAllPlates()
      end
    end)

    -- Double check that the mod settings were properly applied after a slight delay
    C_Timer.After(0.5, function()
      if Plater.db and Plater.db.profile and Plater.db.profile.hook_data and Plater.db.profile.hook_data[foundIndex] then
        local currentState = Plater.db.profile.hook_data[foundIndex].Enabled
        -- print("DotMaster: Verifying DotMaster Integration mod state - Expected: " ..
        --  (enabledState and "ENABLED" or "DISABLED") ..
        --  ", Actual: " .. (currentState and "ENABLED" or "DISABLED"))

        -- If there's a mismatch, try to force it again
        if currentState ~= enabledState then
          -- print("DotMaster: State mismatch detected, forcing correction...")
          Plater.db.profile.hook_data[foundIndex].Enabled = enabledState
          Plater.WipeAndRecompileAllScripts("hook")
          Plater.FullRefreshAllPlates()
        end
      end
    end)

    -- Update the mod in the Plater hook DB
  else
    -- If the 'DotMaster Integration' mod was NOT found, print an error and do nothing else
    if not self.dotMasterIntegrationNotFoundErrorShown then
      DM:PrintMessage(
        "|cFFFF0000Plater connection not found. Please click the 'Install Plater Integration' button in the DotMaster window.|r")
      self.dotMasterIntegrationNotFoundErrorShown = true
    end
  end
end
