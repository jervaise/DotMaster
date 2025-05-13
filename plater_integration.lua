-- Plater integration moved from core.lua
local DM = DotMaster

-- Add function to install DotMaster mod into Plater
function DM:InstallPlaterMod()
  print("DotMaster: InstallPlaterMod function called!")
  if DotMasterDB then
    print("DotMaster: Current DotMasterDB.enabled = " .. (DotMasterDB.enabled and "true" or "false"))
  else
    print("DotMaster: ERROR - DotMasterDB not available in InstallPlaterMod")
  end
  print("DotMaster: Current DM.enabled = " .. (DM.enabled and "true" or "false"))

  local Plater = _G["Plater"]
  if not (Plater and Plater.db and Plater.db.profile) then
    DM:PrintMessage("Plater not found or incompatible")
    return
  end

  -- Ensure hook_data table exists
  if not Plater.db.profile.hook_data then
    -- If hook_data doesn't exist, Plater isn't fully ready or has an issue.
    DM:PrintMessage("Error: Plater hook data not found. Cannot update 'bokmaster' mod.")
    return
  end

  -- Get spells and combinations from DotMaster API
  local trackedSpells = DM.API:GetTrackedSpells() or {}
  local combinations = DM.API:GetCombinations() or {}

  -- Get settings with fallback to read directly from DotMasterDB for critical settings
  local settings = DM.API:GetSettings() or {}

  -- DEEP DEBUGGING OF SETTINGS
  print("DotMaster-DEBUG: DETAILED settings analysis in InstallPlaterMod")
  print("DotMaster-DEBUG: settings.enabled raw value:", tostring(settings.enabled))

  local createdWhere = "unknown"
  for i = 2, 10 do
    local info = debugstack(i, 1, 0) or ""
    if info:find("GetSettings") then
      createdWhere = "GetSettings at " .. i
      break
    end
  end

  print("DotMaster-DEBUG: settings created from: " .. createdWhere)
  print("DotMaster-DEBUG: settings table contents:")

  for k, v in pairs(settings) do
    local valueStr = "nil"
    if v ~= nil then
      if type(v) == "table" then
        valueStr = "table"
      elseif type(v) == "boolean" then
        valueStr = v and "true" or "false"
      else
        valueStr = tostring(v)
      end
    end
    print("DotMaster-DEBUG:   - " .. k .. " = " .. valueStr)
  end

  -- Debug the settings we're using
  print("DotMaster: InstallPlaterMod using settings:")
  print("  - Enabled: " .. (settings.enabled and "true" or "false"))
  print("  - Force Threat Color: " .. (settings.forceColor and "true" or "false"))
  print("  - Border Only: " .. (settings.borderOnly and "true" or "false"))

  -- For critical settings, ALWAYS use DotMasterDB as the source of truth
  local enabledState
  if DotMasterDB and DotMasterDB.enabled ~= nil then
    enabledState = DotMasterDB.enabled
    print("DotMaster: Using enabledState directly from DotMasterDB: " .. (enabledState and "ENABLED" or "DISABLED"))

    -- Also ensure settings.enabled is in sync
    if settings.enabled ~= enabledState then
      print("DotMaster: Synchronizing settings.enabled with DotMasterDB.enabled")
      settings.enabled = enabledState
    end
  else
    -- Fallback to settings if DotMasterDB isn't available
    enabledState = settings.enabled
    print("DotMaster: DotMasterDB not available, using settings.enabled: " .. (enabledState and "ENABLED" or "DISABLED"))
  end

  -- For critical settings, double-check with DotMasterDB
  if DotMasterDB then
    if DotMasterDB.settings then
      if DotMasterDB.settings.forceColor ~= nil then
        if settings.forceColor ~= DotMasterDB.settings.forceColor then
          print("DotMaster: WARNING - Force Threat Color mismatch, using DotMasterDB value")
          settings.forceColor = DotMasterDB.settings.forceColor
        end
      end

      if DotMasterDB.settings.borderOnly ~= nil then
        if settings.borderOnly ~= DotMasterDB.settings.borderOnly then
          print("DotMaster: WARNING - Border Only mismatch, using DotMasterDB value")
          settings.borderOnly = DotMasterDB.settings.borderOnly
        end
      end
    end
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
  envTable.DM_ENABLED = true -- Flag to indicate the addon is enabled

  -- Make sure thickness is a valid number with proper conversion
  local borderThickness = tonumber(%s)

  -- Use a clearly identifiable debug message
  print("|cFFFF9900DotMaster-BorderDebug: APPLYING border thickness " .. tostring(borderThickness) .. "|r")

  if not borderThickness or borderThickness < 1 or borderThickness > 10 then
    borderThickness = 2 -- Default to 2px if invalid
    print("|cFFFF9900DotMaster-BorderDebug: WARNING - Invalid thickness, using default 2px|r")
  end

  envTable.DM_BORDER_THICKNESS = borderThickness

  envTable.DM_FLASH_EXPIRING = %s
  envTable.DM_FLASH_THRESHOLD = %s

  -- Store last build time for debugging
  envTable.lastBuildTime = %s

  -- Only control border thickness when Border-only mode is enabled
  if envTable.DM_BORDER_ONLY and Plater.db and Plater.db.profile then
    -- Save previous border thickness in both envTable (for this session) and DotMasterDB (for persistence)
    envTable.previousBorderThickness = Plater.db.profile.border_thickness or 1

    -- Store the original Plater thickness in DotMasterDB for persistence across reloads
    if DotMasterDB and not DotMasterDB.originalPlaterBorderThickness then
      DotMasterDB.originalPlaterBorderThickness = envTable.previousBorderThickness
      print("|cFFFF9900DotMaster-BorderDebug: STORED original Plater border thickness: " .. DotMasterDB.originalPlaterBorderThickness .. "|r")
    end

    -- Set Plater's global border thickness
    Plater.db.profile.border_thickness = envTable.DM_BORDER_THICKNESS

    -- Update all nameplates to use the new border thickness
    if Plater.UpdateAllPlatesBorderThickness then
      Plater.UpdateAllPlatesBorderThickness()
    end

    print("|cFFFF9900DotMaster-BorderDebug: SET PLATER border thickness to " .. envTable.DM_BORDER_THICKNESS .. "|r")
  else
    -- When Border-only mode is disabled, restore Plater's original border thickness
    print("|cFFFF9900DotMaster-BorderDebug: RESTORING Plater's original border thickness|r")

    local originalThickness = 1 -- Default fallback

    -- Try to get the original thickness from envTable first
    if envTable.previousBorderThickness then
      originalThickness = envTable.previousBorderThickness
      print("|cFFFF9900DotMaster-BorderDebug: Using session-stored thickness: " .. originalThickness .. "|r")
    -- Then try DotMasterDB (which persists across reloads)
    elseif DotMasterDB and DotMasterDB.originalPlaterBorderThickness then
      originalThickness = DotMasterDB.originalPlaterBorderThickness
      print("|cFFFF9900DotMaster-BorderDebug: Using saved thickness from DB: " .. originalThickness .. "|r")
    end

    -- Apply the original thickness back to Plater
    if Plater.db and Plater.db.profile then
      Plater.db.profile.border_thickness = originalThickness
      print("|cFFFF9900DotMaster-BorderDebug: RESTORED border thickness to " .. originalThickness .. "|r")

      -- Update all nameplates to use the original border thickness
      if Plater.UpdateAllPlatesBorderThickness then
        Plater.UpdateAllPlatesBorderThickness()
      end
    end
  end

  -- Create flash animation for border
  if not envTable.borderFlash then
    -- Purple color as a default
    local flashColor = {1, 0, 1, 1}
    envTable.borderFlash = Plater.CreateFlash(unitFrame.healthBar, 0.5, 2, flashColor)
  end

  -- Debug info at initialization
  print("DotMaster: Plater mod initialized - Force Threat Color: " .. (envTable.DM_FORCE_THREAT_COLOR and "ENABLED" or "DISABLED"))

  if envTable.DM_BORDER_ONLY then
    print("DotMaster: Border Only Mode: ENABLED (Thickness: " .. envTable.DM_BORDER_THICKNESS .. ")")
    print("DotMaster: DotMaster is controlling border thickness")
  else
    print("DotMaster: Border Only Mode: DISABLED")
    print("DotMaster: Plater is controlling border thickness")
  end

  print("DotMaster: Loaded " .. #envTable.DM_SPELLS .. " spells and " .. #envTable.DM_COMBOS .. " combos")
end]],
    spellsLuaCode, combosLuaCode,
    settings.forceColor and "true" or "false",
    settings.borderOnly and "true" or "false",
    tostring(settings.borderThickness or 2),
    settings.flashExpiring and "true" or "false",
    settings.flashThresholdSeconds or 3.0,
    "GetTime()"
  )

  -- Define OnUpdate code
  local onUpdateCode = [[
-- OnUpdate
function (self, unitId, unitFrame, envTable, modTable)
  -- If the addon is disabled, do nothing
  if not envTable.DM_ENABLED then
    return
  end

  -- Get the threat status for this unit
  local isTanking, status, threatpct, rawthreatpct, threatvalue = UnitDetailedThreatSituation("player", unitId)

  -- Handle Force Threat Color mode (highest priority)
  if envTable.DM_FORCE_THREAT_COLOR and status then
    -- Get the appropriate player role
    local isPlayerTank = GetSpecializationRole(GetSpecialization()) == "TANK"

    -- Set appropriate colors for tanks and non-tanks
    if isPlayerTank then
      -- Player is a tank
      if status == 3 then  -- securely tanking, green border
        if envTable.DM_BORDER_ONLY then
          Plater.SetBorderColor(unitFrame, 0, 1, 0)
        else
          Plater.SetNameplateColor(unitFrame, {0, 1, 0, 1})
        end
        return -- Skip other color logic
      elseif status == 2 then  -- insecurely tanking, yellow border
        if envTable.DM_BORDER_ONLY then
          Plater.SetBorderColor(unitFrame, 1, 1, 0)
        else
          Plater.SetNameplateColor(unitFrame, {1, 1, 0, 1})
        end
        return -- Skip other color logic
      elseif status == 1 or status == 0 then -- not tanking, red border
        if envTable.DM_BORDER_ONLY then
          Plater.SetBorderColor(unitFrame, 1, 0, 0)
        else
          Plater.SetNameplateColor(unitFrame, {1, 0, 0, 1})
        end
        return -- Skip other color logic
      end
    else
      -- Player is not a tank
      if status == 3 or status == 2 or status == 1 then -- If we have aggro in any way, bright red
        if envTable.DM_BORDER_ONLY then
          Plater.SetBorderColor(unitFrame, 1, 0, 0)
        else
          Plater.SetNameplateColor(unitFrame, {1, 0, 0, 1})
        end
        return -- Skip other color logic
      end
    end
  end

  -- SIMPLE DOT FLASHING TEST CODE
  if envTable.DM_FLASH_EXPIRING then
    -- Cache to avoid checking too often
    if not envTable.lastDoTCheck or (GetTime() - envTable.lastDoTCheck) > 0.2 then
      envTable.lastDoTCheck = GetTime()
      envTable.hasDoTsUnder8Seconds = false

      -- Check for any player DoTs on the unit
      for i = 1, 40 do
        local name, icon, count, debuffType, duration, expirationTime, source, _, _, spellId = UnitDebuff(unitId, i)
        if not name then break end

        -- Only check player's DoTs
        if source == "player" then
          local timeRemaining = expirationTime - GetTime()

          -- Debug output
          if timeRemaining <= 8 then
            print("|cFFFF9900DotMaster-DoTDebug: Found DoT " .. name .. " with " .. string.format("%.1f", timeRemaining) .. " seconds remaining|r")
            envTable.hasDoTsUnder8Seconds = true
            break
          end
        end
      end
    end

    -- Flash if DoTs are under 8 seconds
    if envTable.hasDoTsUnder8Seconds then
      if not envTable.isFlashing then
        print("|cFFFF9900DotMaster-DoTDebug: Starting flash for DoT under 8 seconds|r")
        envTable.isFlashing = true
        if envTable.DM_BORDER_ONLY then
          -- Flash border using Plater's built-in function
          Plater.FlashNameplateBorder(unitFrame, 0.5)

          -- Continue flashing with a timer
          if envTable.flashTimer then
            envTable.flashTimer:Cancel()
          end
          envTable.flashTimer = C_Timer.NewTicker(0.7, function()
            if unitFrame:IsShown() then
              Plater.FlashNameplateBorder(unitFrame, 0.5)
            else
              envTable.flashTimer:Cancel()
              envTable.flashTimer = nil
            end
          end)
        else
          -- Flash entire nameplate
          if envTable.borderFlash then
            envTable.borderFlash:Play()
          end
        end
      end
    else
      if envTable.isFlashing then
        print("|cFFFF9900DotMaster-DoTDebug: Stopping flash, no DoTs under 8 seconds|r")
        envTable.isFlashing = false

        -- Stop border flash timer
        if envTable.flashTimer then
          envTable.flashTimer:Cancel()
          envTable.flashTimer = nil
        end

        -- Stop animation
        if envTable.borderFlash then
          envTable.borderFlash:Stop()
        end
      end
    end
  end

  -- Check if any spells are active on the unit
  local activeSpells, activeColor, highestPriority = {}, nil, -1

  -- First check if any combinations are active
  for i, combo in ipairs(envTable.DM_COMBOS) do
    if combo.enabled then
      local allSpellsPresent = true
      local spellsList = {}

      -- Build a list of spells to check and verify all are present
      for _, spellID in ipairs(combo.spells) do
        table.insert(spellsList, spellID)
      end

      -- Check if all required spells are active (simple version - just checks if present)
      if #spellsList > 0 then
        for _, spellID in ipairs(spellsList) do
          local isActive = false

          -- Check if the spell is active using UnitDebuff
          for i = 1, 40 do
            local name, _, _, _, _, _, source, _, _, debuffSpellID = UnitDebuff(unitId, i)
            if not name then break end

            if debuffSpellID == spellID and source == "player" then
              isActive = true
              break
            end
          end

          if not isActive then
            allSpellsPresent = false
            break
          end
        end
      else
        -- If combo has no spells defined, it can't be active
        allSpellsPresent = false
      end

      -- If all spells in the combo are present and its priority is higher
      if allSpellsPresent and combo.priority > highestPriority then
        activeColor = combo.color
        highestPriority = combo.priority
      end
    end
  end

  -- If no combination was active, check individual spells
  if not activeColor then
    for i, spell in ipairs(envTable.DM_SPELLS) do
      if spell.enabled then
        local isActive = false

        -- Check if the spell is active using UnitDebuff
        for i = 1, 40 do
          local name, _, _, _, _, _, source, _, _, debuffSpellID = UnitDebuff(unitId, i)
          if not name then break end

          if debuffSpellID == spell.spellID and source == "player" then
            isActive = true
            break
          end
        end

        -- If the spell is active and its priority is higher than what we've seen so far
        if isActive and spell.priority > highestPriority then
          activeColor = spell.color
          highestPriority = spell.priority
        end
      end
    end
  end

  -- Apply the appropriate color if any active spells were found
  if activeColor then
    -- Apply to border-only or full nameplate based on settings
    if envTable.DM_BORDER_ONLY then
      Plater.SetBorderColor(unitFrame, activeColor[1], activeColor[2], activeColor[3], activeColor[4] or 1)
    else
      Plater.SetNameplateColor(unitFrame, {activeColor[1], activeColor[2], activeColor[3], activeColor[4] or 1})
    end
  else
    -- No active spells, restore normal appearance
    if envTable.DM_BORDER_ONLY then
      -- Reset to Plater's default border color handling
      Plater.SetBorderColor(unitFrame)
    else
      -- Reset to Plater's default nameplate color handling
      Plater.SetNameplateColor(unitFrame)
    end
  end
end]]

  -- Define OnHide code
  local onHideCode = [[
-- OnHide
function (self, unitId, unitFrame, envTable, modTable)
  -- Clean up any flash animations if they exist
  if envTable.flashTimer then
    envTable.flashTimer:Cancel()
    envTable.flashTimer = nil
  end

  if envTable.borderFlash then
    envTable.borderFlash:Stop()
  end

  envTable.isFlashing = false
end]]

  -- Define Nameplate Added code
  local nameplatAddedCode = [[
-- Nameplate Added
function (self, unitId, unitFrame, envTable, modTable)
  -- Create flash animation for border if it doesn't exist yet
  if not envTable.borderFlash then
    -- Purple color as a default
    local flashColor = {1, 0, 1, 1}
    envTable.borderFlash = Plater.CreateFlash(unitFrame.healthBar, 0.5, 2, flashColor)
  end

  -- Initialize variables
  envTable.isFlashing = false
  envTable.lastDoTCheck = 0
  envTable.hasDoTsUnder8Seconds = false
end]]

  local data = Plater.db.profile.hook_data
  local modName = "bokmaster" -- Target the manually added mod
  local foundIndex
  for i, mod in ipairs(data) do
    if mod.Name == modName then
      foundIndex = i
      break
    end
  end

  -- Only proceed if the 'bokmaster' mod was found
  if foundIndex then
    local modEntry = data[foundIndex]
    modEntry.Name = modName                          -- Keep the name as "bokmaster"
    modEntry.Desc = "Managed by DotMaster Addon"     -- Update description
    modEntry.Author = "DotMaster"                    -- Update author
    modEntry.Time = time()
    modEntry.Revision = (modEntry.Revision or 0) + 1 -- Increment revision
    modEntry.PlaterCore = Plater.CoreVersion or 0

    -- CRITICAL: Explicitly set the Enabled state of the mod based on DotMaster settings
    modEntry.Enabled = enabledState
    print("DotMaster: Setting bokmaster mod Enabled state to: " .. (enabledState and "ENABLED" or "DISABLED"))

    -- Inject our hooks
    modEntry.Hooks = {
      ["Constructor"] = constructorCode,
      ["Nameplate Updated"] = onUpdateCode,
      ["Nameplate Added"] = nameplatAddedCode,
      ["OnHide"] = onHideCode
    }
    modEntry.HooksTemp = {
      ["Constructor"] = constructorCode,
      ["Nameplate Updated"] = onUpdateCode,
      ["Nameplate Added"] = nameplatAddedCode,
      ["OnHide"] = onHideCode
    }
    modEntry.LastHookEdited = "Constructor" -- Indicate which hook was last edited

    local forceColorStatus = settings.forceColor and "enabled" or "disabled"
    DM:PrintMessage("Updated 'bokmaster' with " ..
      #trackedSpells .. " spells and " .. #combinations .. " combos. Force Threat Color is " .. forceColorStatus ..
      ". Mod enabled: " .. (enabledState and "yes" or "no") .. ".")
    DM:PrintMessage("|cFFFFFF00Consider using /reload to fully apply these changes.|r")

    -- Recompile hook scripts and refresh plates (needed after changing hooks)
    if Plater.WipeAndRecompileAllScripts then
      Plater.WipeAndRecompileAllScripts("hook")
    end

    -- Force a more aggressive refresh of all Plater plates
    C_Timer.After(0.1, function()
      if Plater.FullRefreshAllPlates then
        print("DotMaster: Forcing full Plater refresh...")
        Plater.FullRefreshAllPlates()
      end
    end)

    -- Double check that the mod settings were properly applied after a slight delay
    C_Timer.After(0.5, function()
      if Plater.db and Plater.db.profile and Plater.db.profile.hook_data and Plater.db.profile.hook_data[foundIndex] then
        local currentState = Plater.db.profile.hook_data[foundIndex].Enabled
        print("DotMaster: Verifying bokmaster mod state - Expected: " ..
          (enabledState and "ENABLED" or "DISABLED") ..
          ", Actual: " .. (currentState and "ENABLED" or "DISABLED"))

        -- If there's a mismatch, try to force it again
        if currentState ~= enabledState then
          print("DotMaster: State mismatch detected, forcing correction...")
          Plater.db.profile.hook_data[foundIndex].Enabled = enabledState
          Plater.WipeAndRecompileAllScripts("hook")
          Plater.FullRefreshAllPlates()
        end
      end
    end)
  else
    -- If the 'bokmaster' mod was NOT found, print an error and do nothing else
    DM:PrintMessage(
      "|cFFFF0000Error: Plater mod 'bokmaster' not found. Please add it manually via Plater options and ensure the name is exactly 'bokmaster'.|r")
  end
end
