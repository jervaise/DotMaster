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
  if not (_G['DotMaster'] and _G['DotMaster'].enabled) then --print('DotMaster Integration: DotMaster not found or disabled, skipping constructor.');
    return
  end
  -- PRIORITY ORDER:
  -- 1. Force Threat Color (if enabled - overrides all other coloring)
  -- 2. DoT Combinations (if no combinations match)
  -- 3. Individual DoT Spells (if no combinations match)
  -- When no DoTs are present:
  --   If border-only mode is enabled: let Plater handle default border colors
  --   Otherwise: let Plater handle default nameplate colors

  -- Directly embed DotMaster configuration
  envTable.DM_SPELLS = %s
  envTable.DM_COMBOS = %s
  envTable.DM_FORCE_THREAT_COLOR = %s
  envTable.DM_BORDER_ONLY = %s
  envTable.DM_EXTEND_PLATER_COLORS = %s

  -- Make sure thickness is a valid number with proper conversion
  local borderThickness = tonumber(%s)

  if not borderThickness or borderThickness < 1 or borderThickness > 10 then
    borderThickness = 2 -- Default to 2px if invalid
  end

  envTable.DM_BORDER_THICKNESS = borderThickness

  envTable.DM_FLASH_EXPIRING = %s
  envTable.DM_FLASH_THRESHOLD = %s

  -- Store last build time for debugging
  envTable.lastBuildTime = %s

  -- Always set border thickness regardless of mode
  if Plater.db and Plater.db.profile then
    -- Save previous border thickness in both envTable (for this session) and DotMasterDB (for persistence)
    envTable.previousBorderThickness = Plater.db.profile.border_thickness or 1

    -- Store the original Plater thickness in DotMasterDB for persistence across reloads
    if DotMasterDB and not DotMasterDB.originalPlaterBorderThickness then
      DotMasterDB.originalPlaterBorderThickness = envTable.previousBorderThickness
    end

    -- Set Plater's global border thickness
    Plater.db.profile.border_thickness = envTable.DM_BORDER_THICKNESS

    -- Update all nameplates to use the new border thickness
    if Plater.UpdateAllPlatesBorderThickness then
      Plater.UpdateAllPlatesBorderThickness()
    end
  end

  -- Debug info at initialization
  -- print("DotMaster: Plater mod initialized - Force Threat Color: " .. (envTable.DM_FORCE_THREAT_COLOR and "ENABLED" or "DISABLED"))

  -- if envTable.DM_BORDER_ONLY then
  --   print("DotMaster: Border Only Mode: ENABLED (Thickness: " .. envTable.DM_BORDER_THICKNESS .. ")")
  --   print("DotMaster: DotMaster is controlling border thickness")
  -- else
  --   print("DotMaster: Border Only Mode: DISABLED")
  --   print("DotMaster: Plater is controlling border thickness")
  -- end

  -- print("DotMaster: Loaded " .. #envTable.DM_SPELLS .. " spells and " .. #envTable.DM_COMBOS .. " combos")
end]],
    spellsLuaCode, combosLuaCode,
    settings.forceColor and "true" or "false",
    settings.borderOnly and "true" or "false",
    effectiveExtendPlaterColors and "true" or "false",
    settings.borderThickness or 2,
    settings.flashExpiring and "true" or "false",
    settings.flashThresholdSeconds or 3.0,
    GetTime())

  local updateCode = [[
function(self, unitId, unitFrame, envTable, modTable)
  if not (_G['DotMaster'] and _G['DotMaster'].enabled) then --print('DotMaster Integration: DotMaster not found or disabled, skipping update.');
    return
  end
  -- IMPORTANT: This function runs for every nameplate, every frame
  -- So we need to keep it efficient and avoid excessive debug messages

  -- Quick early exit check - if no nameplate or health bar, nothing to color
  if not unitFrame or not unitFrame.healthBar then
    return
  end

  local unitName = unitFrame.namePlateUnitName or unitId or "Unknown"

  -- MODIFIED applyColor function with integrated flashing logic
  local function applyColor(r, g, b, a, isThreatColor, remainingTimeParam) -- Added remainingTimeParam
    a = a or 1 -- Default alpha if not provided

    self.dm_has_been_custom_colored = true -- Mark that DotMaster is actively coloring

    local finalR, finalG, finalB, finalA = r, g, b, a -- Default to original DM color
    local actualRemainingTime = remainingTimeParam or 999 -- Use passed time, default to high if nil

    -- Only run flashing logic if DM_FLASH_EXPIRING is true AND actualRemainingTime is less than the configured threshold
    if envTable.DM_FLASH_EXPIRING and actualRemainingTime < (envTable.DM_FLASH_THRESHOLD or 3.0) then
      self.dm_colFlash_Timer = (self.dm_colFlash_Timer or 0) + (GetTime() - (self.dm_colFlash_LastTick or GetTime()))
      self.dm_colFlash_LastTick = GetTime()

      if self.dm_colFlash_Timer >= 0.5 then
        self.dm_colFlash_Timer = 0
        self.dm_colFlash_IsLighterPhase = not self.dm_colFlash_IsLighterPhase -- Toggle state for lighter/original
      end

      if self.dm_colFlash_IsLighterPhase then -- If it's the "lighter" phase of the flash
        finalR = math.min(1, r + 0.3) -- Calculate lighter Red component
        finalG = math.min(1, g + 0.3) -- Calculate lighter Green component
        finalB = math.min(1, b + 0.3) -- Calculate lighter Blue component
      end
    else
      self.dm_colFlash_IsLighterPhase = false -- Ensure flash state is definitely off if conditions not met
    end

    -- Apply the determined color (DotMaster's original or its lighter version if flashing is enabled and in lighter phase)
    if isThreatColor then -- Threat color always applies to the full nameplate
      Plater.SetNameplateColor(unitFrame, finalR, finalG, finalB, finalA)
    elseif envTable.DM_BORDER_ONLY then -- Border-only mode for non-threat
      if unitFrame.healthBar.border then
        -- Apply the (potentially flashed) DotMaster color to the border
        unitFrame.healthBar.border:SetVertexColor(finalR, finalG, finalB, finalA)
        unitFrame.customBorderColor = {finalR, finalG, finalB, finalA} -- Let Plater know we set it

        -- If extend Plater colors is enabled, update Plater's border color variables
        if envTable.DM_EXTEND_PLATER_COLORS then
          -- Update Plater's internal border color variables if they exist
          if Plater.db and Plater.db.profile then
            Plater.db.profile.border_color_r = finalR
            Plater.db.profile.border_color_g = finalG
            Plater.db.profile.border_color_b = finalB
            Plater.db.profile.border_color_a = finalA
          end
        end

        -- Refresh the main nameplate color to Plater's default, as we only control the border here
        Plater.RefreshNameplateColor(unitFrame)
        unitFrame.healthBar.border:Show()
      end
    else -- Normal mode (full nameplate color for non-threat)
      Plater.SetNameplateColor(unitFrame, finalR, finalG, finalB, finalA)
    end
  end

  -- First, check for threat coloring (has priority if enabled)
  if envTable.DM_FORCE_THREAT_COLOR then
    local isTanking, status, threatpct = UnitDetailedThreatSituation("player", unitId)
    local isTank = Plater.PlayerIsTank
    if isTank then
      if unitFrame.InCombat and not isTanking then
        local color = Plater.db.profile.tank.colors.noaggro
        applyColor(color[1], color[2], color[3], color[4] or 1, true, 999) -- Threat doesn't have specific spell time
        return
      end
    else
      if unitFrame.InCombat and isTanking then
        local color = Plater.db.profile.dps.colors.aggro
        applyColor(color[1], color[2], color[3], color[4] or 1, true, 999) -- Threat doesn't have specific spell time
        return
      end
    end
  end

  local spells = envTable.DM_SPELLS or {}; local combos = envTable.DM_COMBOS or {}

  for i, combo in ipairs(combos) do
    if combo.enabled then
      local allSpellsPresent = true
      local minRemainingTime = 9999 -- Initialize with a very high number

      -- First, check if all spells are present and find the minimum remaining time
      for _, spellID in ipairs(combo.spells) do
        if Plater.NameplateHasAura(unitFrame, spellID, true) then
          local sName, _, _, _, sDuration, sExpirationTime = Plater.GetAura(unitFrame.namePlateUnitToken, spellID, true)
          if sExpirationTime and sExpirationTime > 0 then
            local remaining = math.max(0, sExpirationTime - GetTime())
            if remaining < minRemainingTime then
              minRemainingTime = remaining
            end
          else
            -- If any spell in the combo has no expiration (e.g., some passive auras if misconfigured),
            -- we can't determine a reliable combo expiry. Treat as not expiring for flash purposes.
            minRemainingTime = 9999
            break -- Exit inner loop, this spell makes combo expiry indefinite for flashing
          end
        else
          allSpellsPresent = false
          break -- Exit inner loop, not all spells are present
        end
      end

      if allSpellsPresent then
        -- Pass the calculated minimum remaining time of the spells in the combination
        applyColor(combo.color[1], combo.color[2], combo.color[3], combo.color[4] or 1, false, minRemainingTime)
        return
      end
    end
  end

  for i, spell in ipairs(spells) do
    if spell.enabled and spell.spellID and Plater.NameplateHasAura(unitFrame, spell.spellID, true) then
      local spellIDToQuery = spell.spellID
      local sName, _, _, _, sDuration, sExpirationTime = Plater.GetAura(unitFrame.namePlateUnitToken, spellIDToQuery, true)
      local remainingTime = 999 -- Default high if no specific expiration
      if sExpirationTime and sExpirationTime > 0 then remainingTime = math.max(0, sExpirationTime - GetTime()) end
      applyColor(spell.color[1], spell.color[2], spell.color[3], spell.color[4] or 1, false, remainingTime)
      return
    end
  end

  if self.dm_has_been_custom_colored then
      Plater.RefreshNameplateColor(unitFrame)
      if envTable.DM_FLASH_EXPIRING then self.dm_colFlash_IsLighterPhase = false end
  end
  self.dm_has_been_custom_colored = false

  -- Simple implementation of Extend Plater Colors to Borders
  if envTable.DM_EXTEND_PLATER_COLORS and unitFrame.healthBar.border then
    -- Get the current color of the nameplate
    local r, g, b, a = unitFrame.healthBar:GetStatusBarColor()
    -- Check if nameplate has a non-default color
    local isCustomColored = unitFrame.UsingCustomColor or unitFrame.PlateFrame.customColor or unitFrame.isForced
    if r and g and b and isCustomColored then
      -- Apply the nameplate color to the border
      unitFrame.healthBar.border:SetVertexColor(r, g, b, a or 1)
      unitFrame.customBorderColor = {r, g, b, a or 1}
      unitFrame.healthBar.border:Show()
    end
  end

  if envTable.DM_BORDER_ONLY then
    if unitFrame.healthBar.border then
        -- We are in border-only mode, and no DotMaster spell/combo is currently active for this plate.
        -- We need to ensure Plater takes back control of the border.
        -- By setting customBorderColor to nil, we signal to Plater that DotMaster is no longer
        -- explicitly overriding the border. Plater.RefreshNameplateColor should then apply Plater's
        -- own logic for border visibility and color based on its settings for the current unit state.
        unitFrame.customBorderColor = nil
        -- Attempt to explicitly clear/reset vertex color to OPAQUE black before Plater's refresh.
        unitFrame.healthBar.border:SetVertexColor(0,0,0,1)
        Plater.RefreshNameplateColor(unitFrame)
    end
  else
    -- Not in border-only mode. Plater should be controlling the border entirely based on its settings,
    -- or how it interprets the nameplate color DotMaster might have set via Plater.SetNameplateColor().
    -- DotMaster simply ensures customBorderColor is nil so Plater doesn't think DotMaster is still
    -- trying to explicitly control the border.
    Plater.RefreshNameplateColor(unitFrame)
    if unitFrame.healthBar.border then unitFrame.customBorderColor = nil end
  end

  -- Any leftover DM_Text should be hidden and we should consider removing it entirely
  if unitFrame.DM_Text then
    unitFrame.DM_Text:Hide()
    -- Optionally, completely remove the text element
    -- unitFrame.DM_Text:SetParent(nil)
    -- unitFrame.DM_Text = nil
  end
end
]]

  -- Add nameplate added hook to run CheckAggro when a nameplate is added
  local nameplatAddedCode = [[
function(self, unitId, unitFrame, envTable, modTable)
  if not (_G['DotMaster'] and _G['DotMaster'].enabled) then --print('DotMaster Integration: DotMaster not found or disabled, skipping nameplate added.');
    return
  end
  -- When a nameplate is first added, check threat if enabled
  if envTable.DM_FORCE_THREAT_COLOR and unitFrame and unitId then
    -- Function to apply color based on border-only setting
    local function applyColor(r, g, b, a, isThreatColor)
      a = a or 1

      -- Force threat color should always color the entire nameplate, regardless of border-only setting
      if isThreatColor then
        Plater.SetNameplateColor(unitFrame, r, g, b, a)
        return
      end

      if envTable.DM_BORDER_ONLY then
        -- Border-only mode: Set only the border color
        if unitFrame.healthBar.border then
          -- Set border color
          unitFrame.healthBar.border:SetVertexColor(r, g, b, a)

          -- Set custom border color flag
          unitFrame.customBorderColor = {r, g, b, a}

          -- Reset nameplate color to default (since we're only changing border)
          Plater.RefreshNameplateColor(unitFrame)

          -- Ensure border is visible - sometimes needed due to Plater updates
          unitFrame.healthBar.border:Show()
        end
      else
        -- Normal mode: Set the entire nameplate color
        Plater.SetNameplateColor(unitFrame, r, g, b, a)
      end
    end

    -- Get threat info directly
    local isTanking, status, threatpct = UnitDetailedThreatSituation("player", unitId)
    local isTank = Plater.PlayerIsTank

    -- For tanks, high threat = good, for DPS/healer, high threat = bad
    if isTank then
      -- For tanks: color if NOT tanking and in combat
      if unitFrame.InCombat and not isTanking then
        -- Apply the no-aggro color for tanks
        local color = Plater.db.profile.tank.colors.noaggro
        applyColor(color[1], color[2], color[3], color[4] or 1, true) -- true = threat color

        -- Remove text display for tank warning in nameplate added hook
      end
    else
      -- For DPS/Healers: color if tanking and in combat
      if unitFrame.InCombat and isTanking then
        -- Apply the aggro color for DPS
        local color = Plater.db.profile.dps.colors.aggro
        applyColor(color[1], color[2], color[3], color[4] or 1, true) -- true = threat color

        -- Remove text display for DPS warning in nameplate added hook
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
        "|cFFFF0000Error: Plater mod 'DotMaster Integration' not found. Please add it manually via Plater options and ensure the name is exactly 'DotMaster Integration'.|r")
      self.dotMasterIntegrationNotFoundErrorShown = true
    end
  end
end
