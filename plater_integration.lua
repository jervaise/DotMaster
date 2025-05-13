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

    -- Actually restore Plater's border thickness to the original value
    if Plater.db and Plater.db.profile then
      Plater.db.profile.border_thickness = originalThickness
      print("|cFFFF9900DotMaster-BorderDebug: RESET Plater border thickness to " .. originalThickness .. "|r")

      -- Update all nameplates to refresh border thickness
      if Plater.UpdateAllPlatesBorderThickness then
        Plater.UpdateAllPlatesBorderThickness()
      end
    end
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

  -- Debug information about expiry flash feature
  if envTable.DM_FLASH_EXPIRING then
    print("DotMaster: Expiry Flash: ENABLED (Threshold: " .. envTable.DM_FLASH_THRESHOLD .. "s)")
  else
    print("DotMaster: Expiry Flash: DISABLED")
  end
end]],
    spellsLuaCode, combosLuaCode,
    settings.forceColor and "true" or "false",
    settings.borderOnly and "true" or "false",
    settings.borderThickness,
    settings.flashExpiring and "true" or "false",
    settings.flashThresholdSeconds or 3.0,
    GetTime())

  local updateCode = [[
function(self, unitId, unitFrame, envTable, modTable)
  -- IMPORTANT: This function runs for every nameplate, every frame
  -- So we need to keep it efficient and avoid excessive debug messages

  -- Quick early exit check - if no nameplate or health bar, nothing to color
  if not unitFrame or not unitFrame.healthBar then
    return
  end

  local unitName = unitFrame.namePlateUnitName or unitId or "Unknown"

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
      -- Do not modify the border thickness here - let Plater handle it
      Plater.SetNameplateColor(unitFrame, r, g, b, a)
    end
  end

  -- First, check for threat coloring (has priority if enabled)
  if envTable.DM_FORCE_THREAT_COLOR then
    -- Get threat info directly
    local isTanking, status, threatpct = UnitDetailedThreatSituation("player", unitId)
    local isTank = Plater.PlayerIsTank

    -- For tanks, high threat = good, for DPS/healer, high threat = bad
    local threatIsActive = false

    if isTank then
      -- For tanks: color if NOT tanking and in combat
      if unitFrame.InCombat and not isTanking then
        -- Apply the no-aggro color for tanks
        local color = Plater.db.profile.tank.colors.noaggro
        applyColor(color[1], color[2], color[3], color[4] or 1, true) -- true = threat color

        unitFrame.DM_Text = unitFrame.DM_Text or unitFrame:CreateFontString(nil, "overlay", "GameFontNormal")
        unitFrame.DM_Text:SetPoint("bottom", unitFrame, "top", 0, 5)
        unitFrame.DM_Text:SetText("⚠ NOT TANKING")
        unitFrame.DM_Text:Show()

        -- Stop any expiry flash when threat coloring is active
        if unitFrame.DM_ExpiryFlashAnimation then
          unitFrame.DM_ExpiryFlashAnimation:Stop()
        end
        if unitFrame.DM_ExpiryFlashTimer then
          unitFrame.DM_ExpiryFlashTimer:Cancel()
          unitFrame.DM_ExpiryFlashTimer = nil
        end

        return -- Exit early, don't process DoTs
      end
    else
      -- For DPS/Healers: color if tanking and in combat
      if unitFrame.InCombat and isTanking then
        -- Apply the aggro color for DPS
        local color = Plater.db.profile.dps.colors.aggro
        applyColor(color[1], color[2], color[3], color[4] or 1, true) -- true = threat color

        unitFrame.DM_Text = unitFrame.DM_Text or unitFrame:CreateFontString(nil, "overlay", "GameFontNormal")
        unitFrame.DM_Text:SetPoint("bottom", unitFrame, "top", 0, 5)
        unitFrame.DM_Text:SetText("⚠ AGGRO")
        unitFrame.DM_Text:Show()

        -- Stop any expiry flash when threat coloring is active
        if unitFrame.DM_ExpiryFlashAnimation then
          unitFrame.DM_ExpiryFlashAnimation:Stop()
        end
        if unitFrame.DM_ExpiryFlashTimer then
          unitFrame.DM_ExpiryFlashTimer:Cancel()
          unitFrame.DM_ExpiryFlashTimer = nil
        end

        return -- Exit early, don't process DoTs
      end
    end
  end

  -- Debug text on the nameplate
  unitFrame.DM_Text = unitFrame.DM_Text or unitFrame:CreateFontString(nil, "overlay", "GameFontNormal")
  unitFrame.DM_Text:SetPoint("bottom", unitFrame, "top", 0, 5)

  -- Use the directly embedded configuration
  local spells = envTable.DM_SPELLS or {}
  local combos = envTable.DM_COMBOS or {}

  -- Throttled expiry check by storing last check time
  unitFrame.DM_LastExpiryCheck = unitFrame.DM_LastExpiryCheck or 0
  local now = GetTime()
  local shouldCheckExpiry = envTable.DM_FLASH_EXPIRING and (now - unitFrame.DM_LastExpiryCheck) > 0.2

  -- Variables to track expiring auras
  local expiringFound = false
  local expiringColor = nil
  local shortestTime = 999
  local expiringName = nil

  -- Check for combinations first (higher priority)
  local comboMatch = false

  for i, combo in ipairs(combos) do
    if combo.enabled then
      local allSpellsPresent = true
      local allSpells = {}

      -- First pass: check if all required spells are present
      for _, spellID in ipairs(combo.spells) do
        local hasAura = Plater.NameplateHasAura(unitFrame, spellID)
        if not hasAura then
          allSpellsPresent = false
          break
        end

        -- Get detailed aura info using AuraUtil
        local auraInfo = nil
        if AuraUtil and AuraUtil.ForEachAura then
          AuraUtil.ForEachAura(unitId, "HARMFUL|PLAYER", nil, function(name, icon, count, dispelType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellId)
            if spellId == spellID then
              auraInfo = {
                name = name,
                duration = duration,
                expirationTime = expirationTime
              }

              -- Debug print to track aura detection
              local remainingTime = (expirationTime or 0) - now
              print("DotMaster-Debug: Found aura " .. name .. " (ID: " .. spellId .. ") with " .. string.format("%.1f", remainingTime) .. "s remaining")

              return true  -- Stop iteration
            end
          end, true)  -- includeNameplateOnly = true
        else
          print("DotMaster-Debug: ERROR - AuraUtil or ForEachAura not available!")
        end

        table.insert(allSpells, auraInfo or {name = "Unknown", expirationTime = 0})
      end

      if allSpellsPresent then
        -- We matched a combo - apply the color
        applyColor(combo.color[1], combo.color[2], combo.color[3], combo.color[4] or 1, false) -- false = not threat color
        unitFrame.DM_Text:SetText("◆ " .. combo.name)
        unitFrame.DM_Text:Show()
        comboMatch = true

        -- Check for expiring combo (only when enabled and need to check)
        if shouldCheckExpiry then
          unitFrame.DM_LastExpiryCheck = now
          local threshold = envTable.DM_FLASH_THRESHOLD or 3.0

          -- Find which aura is expiring soonest
          for _, auraInfo in ipairs(allSpells) do
            if auraInfo and auraInfo.expirationTime then
              local remainingTime = (auraInfo.expirationTime or 0) - now
              if remainingTime > 0 and remainingTime < shortestTime then
                shortestTime = remainingTime
                expiringName = auraInfo.name
                expiringColor = combo.color
                print("DotMaster-Debug: Combo aura " .. auraInfo.name .. " is EXPIRING in " .. string.format("%.1f", remainingTime) .. "s (threshold: " .. threshold .. "s)")
              else
                print("DotMaster-Debug: Combo aura " .. auraInfo.name .. " is NOT EXPIRING - " .. string.format("%.1f", remainingTime) .. "s remaining (threshold: " .. threshold .. "s)")
              end
            end
          end

          -- Check if within threshold
          if shortestTime < threshold then
            expiringFound = true
          end
        end

        break -- Exit combo loop, we found a match
      end
    end
  end

  -- If no combo matched, check for individual spells
  if not comboMatch then
    local spellMatch = false

    for i, spell in ipairs(spells) do
      if spell.enabled and spell.spellID then
        local hasAura = Plater.NameplateHasAura(unitFrame, spell.spellID)
        if hasAura then
          -- Apply spell color
          applyColor(spell.color[1], spell.color[2], spell.color[3], spell.color[4] or 1, false) -- false = not threat color
          unitFrame.DM_Text:SetText(spell.name)
          unitFrame.DM_Text:Show()
          spellMatch = true

          -- Check for expiring spell (only when enabled and need to check)
          if shouldCheckExpiry then
            unitFrame.DM_LastExpiryCheck = now
            local threshold = envTable.DM_FLASH_THRESHOLD or 3.0

            -- Get detailed aura info using AuraUtil
            local auraInfo = nil
            if AuraUtil and AuraUtil.ForEachAura then
              AuraUtil.ForEachAura(unitId, "HARMFUL|PLAYER", nil, function(name, icon, count, dispelType, duration, expirationTime, caster, canStealOrPurge, nameplateShowPersonal, spellId)
                if spellId == spell.spellID then
                  auraInfo = {
                    name = name,
                    duration = duration,
                    expirationTime = expirationTime
                  }

                  -- Debug print to track aura detection
                  local remainingTime = (expirationTime or 0) - now
                  print("DotMaster-Debug: Found aura " .. name .. " (ID: " .. spellId .. ") with " .. string.format("%.1f", remainingTime) .. "s remaining")

                  return true  -- Stop iteration
                end
              end, true)  -- includeNameplateOnly = true
            else
              print("DotMaster-Debug: ERROR - AuraUtil or ForEachAura not available!")
            end

            -- Check if aura is expiring
            if auraInfo then
              local remainingTime = (auraInfo.expirationTime or 0) - now
              if remainingTime > 0 and remainingTime < threshold then
                expiringFound = true
                expiringName = auraInfo.name
                expiringColor = spell.color
                print("DotMaster-Debug: Spell aura " .. auraInfo.name .. " is EXPIRING in " .. string.format("%.1f", remainingTime) .. "s (threshold: " .. threshold .. "s)")
              else
                print("DotMaster-Debug: Spell aura " .. auraInfo.name .. " is NOT EXPIRING - " .. string.format("%.1f", remainingTime) .. "s remaining (threshold: " .. threshold .. "s)")
              end
            end
          end

          break -- Exit spell loop, we found a match
        end
      end
    end

    -- No spells or combos detected, reset nameplate
    if not spellMatch then
      if envTable.DM_BORDER_ONLY then
        -- In border-only mode, let Plater manage default border colors
        -- instead of forcing white (1,1,1,1) on all borders
        if unitFrame.healthBar.border then
          unitFrame.customBorderColor = nil  -- Remove any custom border color flag
          Plater.RefreshNameplateColor(unitFrame)  -- Let Plater handle default border coloring
        end
      else
        -- In normal mode, reset the entire nameplate
        -- This will use Plater's default colors and border thickness
        Plater.RefreshNameplateColor(unitFrame)

        -- Make sure we're not interfering with Plater's border thickness
        if unitFrame.healthBar.border then
          -- Let Plater control the border appearance
          unitFrame.customBorderColor = nil
        end
      end

      -- Stop any existing flash animation
      if unitFrame.DM_ExpiryFlashAnimation then
        unitFrame.DM_ExpiryFlashAnimation:Stop()
      end
      if unitFrame.DM_ExpiryFlashTimer then
        unitFrame.DM_ExpiryFlashTimer:Cancel()
        unitFrame.DM_ExpiryFlashTimer = nil
      end

      unitFrame.DM_Text:Hide()
      return
    end
  end

  -- Handle expiry flash if found
  if expiringFound and expiringColor then
    -- Debug print to help troubleshoot
    print("DotMaster-Debug: FLASH TRIGGERED - " .. (expiringName or "Unknown") .. " expiring in " .. string.format("%.1f", shortestTime) .. "s")

    -- Create flash based on settings
    if envTable.DM_BORDER_ONLY then
      -- Border only flash
      if not unitFrame.DM_ExpiryFlashTimer then
        -- Force a more direct approach to flashing the border
        unitFrame.DM_ExpiryFlashTimer = C_Timer.NewTicker(0.4, function()
          if unitFrame and unitFrame.healthBar and unitFrame:IsShown() then
            -- Create flash directly
            local border = unitFrame.healthBar.border
            if border then
              -- Store original color
              if not unitFrame.DM_OriginalBorderColor then
                local r, g, b, a = border:GetVertexColor()
                unitFrame.DM_OriginalBorderColor = {r, g, b, a or 1}
              end

              -- Get the current alpha
              local current = border:GetAlpha()

              -- Toggle between normal and bright
              if current < 0.7 then
                -- Brighten
                border:SetAlpha(1.0)
                border:SetVertexColor(1, 1, 1, 1)
              else
                -- Dim
                border:SetAlpha(0.5)
                -- Use original color values but with reduced alpha
                local color = unitFrame.DM_OriginalBorderColor or {1, 0, 1, 1}
                border:SetVertexColor(color[1], color[2], color[3], 0.5)
              end

              print("DotMaster-Debug: Border flash - Current alpha: " .. current)
            else
              print("DotMaster-Debug: ERROR - Border element not found!")
            end
          else
            -- Cancel timer if nameplate is gone
            if unitFrame.DM_ExpiryFlashTimer then
              unitFrame.DM_ExpiryFlashTimer:Cancel()
              unitFrame.DM_ExpiryFlashTimer = nil

              -- Restore original border color if available
              if unitFrame and unitFrame.healthBar and unitFrame.healthBar.border and unitFrame.DM_OriginalBorderColor then
                local color = unitFrame.DM_OriginalBorderColor
                unitFrame.healthBar.border:SetVertexColor(color[1], color[2], color[3], color[4])
                unitFrame.healthBar.border:SetAlpha(1.0)
              end
            end
          end
        end)
      end
    else
      -- Full nameplate flash
      if not unitFrame.DM_ExpiryFlashTimer then
        -- Create a direct flash effect instead of relying on Plater.CreateFlash
        -- Create a flash overlay if it doesn't exist
        if not unitFrame.DM_FlashOverlay then
          unitFrame.DM_FlashOverlay = unitFrame.healthBar:CreateTexture(nil, "OVERLAY")
          unitFrame.DM_FlashOverlay:SetAllPoints(unitFrame.healthBar)
          unitFrame.DM_FlashOverlay:SetColorTexture(1, 1, 1, 0) -- Start transparent
          unitFrame.DM_FlashOverlay:Show()
        end

        -- Ensure it's attached properly
        unitFrame.DM_FlashOverlay:SetParent(unitFrame.healthBar)
        unitFrame.DM_FlashOverlay:SetAllPoints(unitFrame.healthBar)

        -- Use the color from the expiring effect
        local r, g, b = expiringColor[1], expiringColor[2], expiringColor[3]

        -- Start the flash timer
        unitFrame.DM_ExpiryFlashTimer = C_Timer.NewTicker(0.3, function()
          if unitFrame and unitFrame.healthBar and unitFrame:IsShown() and unitFrame.DM_FlashOverlay then
            local currentAlpha = unitFrame.DM_FlashOverlay:GetAlpha()

            -- Toggle between visible and invisible
            if currentAlpha < 0.1 then
              unitFrame.DM_FlashOverlay:SetColorTexture(r, g, b, 0.3)
              print("DotMaster-Debug: Nameplate flash ON - Alpha: 0.3")
            else
              unitFrame.DM_FlashOverlay:SetColorTexture(r, g, b, 0)
              print("DotMaster-Debug: Nameplate flash OFF - Alpha: 0")
            end

            -- Make sure text stays visible
            if unitFrame.healthBar.unitName then
              unitFrame.healthBar.unitName:SetDrawLayer("OVERLAY", 7)
            end
            if unitFrame.healthBar.lifePercent then
              unitFrame.healthBar.lifePercent:SetDrawLayer("OVERLAY", 7)
            end
          else
            -- Cancel timer if nameplate is gone
            if unitFrame.DM_ExpiryFlashTimer then
              unitFrame.DM_ExpiryFlashTimer:Cancel()
              unitFrame.DM_ExpiryFlashTimer = nil

              -- Clean up overlay
              if unitFrame and unitFrame.DM_FlashOverlay then
                unitFrame.DM_FlashOverlay:SetColorTexture(0, 0, 0, 0)
              end
            end
          end
        end)
      end
    end

    -- Update debug text
    if expiringName then
      unitFrame.DM_Text:SetText(unitFrame.DM_Text:GetText() .. " (!" .. string.format("%.1f", shortestTime) .. "s)")
    end
  else
    -- No expiring aura, stop any flash
    if unitFrame.DM_ExpiryFlashAnimation then
      unitFrame.DM_ExpiryFlashAnimation:Stop()
      unitFrame.DM_ExpiryFlashAnimation = nil
    end
    if unitFrame.DM_ExpiryFlashTimer then
      unitFrame.DM_ExpiryFlashTimer:Cancel()
      unitFrame.DM_ExpiryFlashTimer = nil
    end

    -- Clean up flash overlay
    if unitFrame.DM_FlashOverlay then
      unitFrame.DM_FlashOverlay:SetColorTexture(0, 0, 0, 0)
    end

    -- Restore border color if we were using border-only mode
    if envTable.DM_BORDER_ONLY and unitFrame.healthBar and unitFrame.healthBar.border and unitFrame.DM_OriginalBorderColor then
      local color = unitFrame.DM_OriginalBorderColor
      unitFrame.healthBar.border:SetVertexColor(color[1], color[2], color[3], color[4])
      unitFrame.healthBar.border:SetAlpha(1.0)
    end
  end
end
]]

  -- Add nameplate added hook to run CheckAggro when a nameplate is added
  local nameplatAddedCode = [[
function(self, unitId, unitFrame, envTable, modTable)
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

        unitFrame.DM_Text = unitFrame.DM_Text or unitFrame:CreateFontString(nil, "overlay", "GameFontNormal")
        unitFrame.DM_Text:SetPoint("bottom", unitFrame, "top", 0, 5)
        unitFrame.DM_Text:SetText("⚠ NOT TANKING")
        unitFrame.DM_Text:Show()
      end
    else
      -- For DPS/Healers: color if tanking and in combat
      if unitFrame.InCombat and isTanking then
        -- Apply the aggro color for DPS
        local color = Plater.db.profile.dps.colors.aggro
        applyColor(color[1], color[2], color[3], color[4] or 1, true) -- true = threat color

        unitFrame.DM_Text = unitFrame.DM_Text or unitFrame:CreateFontString(nil, "overlay", "GameFontNormal")
        unitFrame.DM_Text:SetPoint("bottom", unitFrame, "top", 0, 5)
        unitFrame.DM_Text:SetText("⚠ AGGRO")
        unitFrame.DM_Text:Show()
      end
    end
  end
end
]]

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
