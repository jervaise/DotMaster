-- DotMaster nameplate_coloring.lua
-- Handles nameplate coloring functionality

local DM = DotMaster

-- Helper function to apply threat coloring based on Plater settings
function DM:ApplyThreatColor(unitFrame, unitToken)
  local Plater = _G["Plater"]
  if not Plater then return false end

  -- Check if player is a tank
  if Plater.PlayerIsTank then
    -- Player is a tank, check if we lost aggro
    if not unitFrame.namePlateThreatIsTanking then
      -- Check for raid tanks (same logic as the mod example)
      if Plater.ZoneInstanceType == "raid" then
        -- Get tanks in the raid
        local tankPlayersInTheRaid = Plater.GetTanks()

        -- Get the target of this unit
        local unitTargetName = UnitName(unitFrame.targetUnitID)

        -- If the unit isn't targeting another tank, show the noaggro color
        if not tankPlayersInTheRaid[unitTargetName] then
          DM:NameplateDebug("Tank lost aggro - applying no-aggro color")
          Plater.SetNameplateColor(unitFrame, Plater.db.profile.tank.colors.noaggro)
          return true
        end
      else
        -- Not in raid, just apply no-aggro color
        DM:NameplateDebug("Tank lost aggro - applying no-aggro color")
        Plater.SetNameplateColor(unitFrame, Plater.db.profile.tank.colors.noaggro)
        return true
      end
    end
  else
    -- Player is DPS/healer - check if we have aggro
    if unitFrame.namePlateThreatIsTanking then
      DM:NameplateDebug("DPS/Healer has aggro - applying aggro color")
      Plater.SetNameplateColor(unitFrame, Plater.db.profile.dps.colors.aggro)
      return true
    end
  end

  return false
end

-- Apply a color to a nameplate border only
function DM:SetNameplateBorderColor(unitFrame, color)
  if not unitFrame or not unitFrame.healthBar or not color then return false end

  local Plater = _G["Plater"]
  if not Plater then return false end

  local border = unitFrame.healthBar.border
  if not border then
    DM:NameplateDebug("Border not found on healthBar")
    return false
  end

  -- Store original border thickness if we haven't already
  local unitToken = unitFrame.unit
  if unitToken and not DM.originalBorderThickness then
    DM.originalBorderThickness = {}
  end

  if unitToken and not DM.originalBorderThickness[unitToken] then
    -- Try to get current thickness from Plater DB or use 1 as default
    local currentThickness = Plater.db and Plater.db.profile and Plater.db.profile.border_thickness or 1
    DM.originalBorderThickness[unitToken] = currentThickness
    DM:NameplateDebug("Stored original border thickness for %s: %d", unitToken, currentThickness)
  end

  -- Set the border color
  border:SetVertexColor(color[1], color[2], color[3], color[4] or 1)

  -- Set the border size if specified in settings
  if DM.settings and DM.settings.borderThickness then
    border:SetBorderSizes(DM.settings.borderThickness, DM.settings.borderThickness,
      DM.settings.borderThickness, DM.settings.borderThickness)
    border:UpdateSizes()
  end

  -- Set custom border color flag so Plater knows we're handling this
  unitFrame.customBorderColor = { color[1], color[2], color[3], color[4] or 1 }

  DM:NameplateDebug("Border color set to: %d/%d/%d, thickness: %d",
    color[1] * 255, color[2] * 255, color[3] * 255,
    DM.settings.borderThickness or 1)

  return true
end

-- Create a flash animation for a nameplate
function DM:CreateNameplateFlash(unitFrame, color)
  local Plater = _G["Plater"]
  if not Plater then return nil end

  -- Create a direct flash wrapper using Plater's built-in functionality
  return {
    Play = function()
      if not unitFrame or not unitFrame.healthBar then return end

      -- For border only mode
      if DM.settings.borderOnly then
        -- Cancel any existing flash timer
        if unitFrame.DotMasterBorderFlashTimer then
          unitFrame.DotMasterBorderFlashTimer:Cancel()
          unitFrame.DotMasterBorderFlashTimer = nil
        end

        -- Create new flash
        if unitFrame.healthBar.canHealthFlash then
          -- Use direct Plater API for border flash
          Plater.FlashNameplateBorder(unitFrame, 0.25)

          -- Set up ongoing flash
          unitFrame.DotMasterBorderFlashTimer = C_Timer.NewTicker(0.35, function()
            if unitFrame and unitFrame.healthBar and unitFrame:IsShown() then
              Plater.FlashNameplateBorder(unitFrame, 0.25)
            else
              -- If the unitFrame is gone or hidden, cancel the timer
              if unitFrame.DotMasterBorderFlashTimer then
                unitFrame.DotMasterBorderFlashTimer:Cancel()
                unitFrame.DotMasterBorderFlashTimer = nil
              end
            end
          end)
        end
      else
        -- For full nameplate mode
        -- Cancel any existing animation
        if unitFrame.DotMasterFlashAnimation then
          unitFrame.DotMasterFlashAnimation:Stop()
        end

        -- Get brightened color
        local r, g, b = color[1], color[2], color[3]
        local maxChannel = math.max(r, g, b)
        if maxChannel > 0 then
          r, g, b = r / maxChannel, g / maxChannel, b / maxChannel
        end

        -- Use Plater's built-in flash animation
        unitFrame.DotMasterFlashAnimation = Plater.CreateFlash(unitFrame.healthBar, 0.25, 3, r, g, b, 0.6)

        -- Hook into the OnPlay to ensure text stays visible
        if unitFrame.DotMasterFlashAnimation then
          -- Store original OnPlay function
          local originalOnPlay = unitFrame.DotMasterFlashAnimation.Anim_OnPlay

          -- Override with our own that preserves text elements
          unitFrame.DotMasterFlashAnimation.Anim_OnPlay = function(...)
            -- Call original first
            if originalOnPlay then
              originalOnPlay(...)
            end

            -- Then protect text elements
            if unitFrame.healthBar.unitName then
              unitFrame.healthBar.unitName:SetDrawLayer("OVERLAY", 7)
            end
            if unitFrame.healthBar.lifePercent then
              unitFrame.healthBar.lifePercent:SetDrawLayer("OVERLAY", 7)
            end
          end

          -- Start the animation
          unitFrame.DotMasterFlashAnimation:Play()
        end
      end
    end,

    Stop = function()
      if not unitFrame then return end

      -- Stop border flash timer
      if unitFrame.DotMasterBorderFlashTimer then
        unitFrame.DotMasterBorderFlashTimer:Cancel()
        unitFrame.DotMasterBorderFlashTimer = nil
      end

      -- Stop nameplate flash animation
      if unitFrame.DotMasterFlashAnimation then
        unitFrame.DotMasterFlashAnimation:Stop()
        unitFrame.DotMasterFlashAnimation = nil
      end

      -- Restore any text layers
      if unitFrame.healthBar and unitFrame.healthBar.unitName then
        unitFrame.healthBar.unitName:SetDrawLayer("OVERLAY", 6)
      end
      if unitFrame.healthBar and unitFrame.healthBar.lifePercent then
        unitFrame.healthBar.lifePercent:SetDrawLayer("OVERLAY", 6)
      end
    end
  }
end

-- Check for expiring DoTs and trigger flashes
function DM:CheckForExpiringDoTs(unitToken)
  if not unitToken or not DM.settings.flashExpiring then return end

  local nameplate = C_NamePlate.GetNamePlateForUnit(unitToken)
  if not nameplate or not nameplate.unitFrame then return end

  -- Debug API availability
  DM:NameplateDebug("CheckForExpiringDoTs called for unit: %s", unitToken)
  DM:NameplateDebug("API Check - C_UnitAuras: %s, AuraUtil: %s",
    C_UnitAuras and "Available" or "Not Available",
    AuraUtil and "Available" or "Not Available")

  if C_UnitAuras then
    DM:NameplateDebug("C_UnitAuras functions: GetAuraDataByUnit: %s, GetAuraDataBySpellID: %s",
      C_UnitAuras.GetAuraDataByUnit and "Available" or "Not Available",
      C_UnitAuras.GetAuraDataBySpellID and "Available" or "Not Available")
  end

  -- Variables to track
  local expiringFound = false
  local expiringDoTName = nil
  local expiringDoTColor = nil
  local leastRemainingTime = nil
  local now = GetTime()
  local threshold = DM.settings.flashThresholdSeconds or 3.0

  -- First check if we have an active combination - combinations have priority over individual dots
  local comboID, comboData = nil, nil

  -- Check for active combinations if the feature is enabled
  if DM.combinations and DM.combinations.settings and DM.combinations.settings.enabled then
    comboID, comboData = self:CheckCombinationsOnUnit(unitToken)
  end

  -- If we have an active combination, process it
  if comboID and comboData then
    DM:NameplateDebug("Found active high-priority combination: %s for expiring check", comboData.name or comboID)

    -- Process combination's expiring DoTs directly using direct API calls for each spell
    if comboData.spells and #comboData.spells > 0 then
      -- First, count active dots and collect their remaining times
      local activeSpellsCount = 0
      local remainingTimes = {}

      DM:NameplateDebug("Combination %s has %d spells defined", comboData.name or comboID, #comboData.spells)

      -- For combinations, we need to check each spell directly
      for _, spellID in ipairs(comboData.spells) do
        DM:NameplateDebug("Checking combination spell: %d", spellID)

        local dotInfo = nil
        local hasDoT = self:HasPlayerDotOnUnit(unitToken, spellID)

        if hasDoT then
          -- Get aura info directly using AuraUtil
          if AuraUtil and AuraUtil.ForEachAura then
            AuraUtil.ForEachAura(unitToken, "HARMFUL", nil,
              function(name, icon, count, _, duration, expirationTime, caster, _, _, id)
                if id == spellID and caster == "player" then
                  DM:NameplateDebug("Found aura info: %s, duration: %.1f, expires: %.1f",
                    name or "Unknown", duration or 0, expirationTime or 0)

                  dotInfo = {
                    name = name,
                    icon = icon,
                    duration = duration or 0,
                    expirationTime = expirationTime or 0,
                    applications = count or 1
                  }
                  return true -- Stop iteration
                end
              end)
          end
        end

        if dotInfo then
          activeSpellsCount = activeSpellsCount + 1
          local remainingTime = dotInfo.expirationTime - now

          if remainingTime > 0 then
            table.insert(remainingTimes, {
              time = remainingTime,
              name = dotInfo.name or "Unknown",
              spellID = spellID
            })

            DM:NameplateDebug("Combo spell %s (%d) has %.1f seconds remaining",
              dotInfo.name or "Unknown", spellID, remainingTime)
          else
            DM:NameplateDebug("Combo spell %s (%d) has invalid remaining time: %.1f",
              dotInfo.name or "Unknown", spellID, remainingTime)
          end
        else
          DM:NameplateDebug("No active aura found for spell %d", spellID)
        end
      end

      -- Sort by remaining time, ascending (shortest time first)
      table.sort(remainingTimes, function(a, b) return a.time < b.time end)

      -- Get threshold requirement (how many spells needed for combo to be active)
      local requiredSpells = tonumber(comboData.threshold) or
          (comboData.threshold == "all" and #comboData.spells) or
          #comboData.spells

      DM:NameplateDebug("Combination requires %d spells to be active, currently has %d active dots",
        requiredSpells, activeSpellsCount)

      -- Detailed debugging for remaining times
      if #remainingTimes > 0 then
        DM:NameplateDebug("Sorted dot expiration times:")
        for i, dotInfo in ipairs(remainingTimes) do
          DM:NameplateDebug("  %d. %s (%.1f seconds remaining)",
            i, dotInfo.name, dotInfo.time)
        end
      else
        DM:NameplateDebug("No active dots with valid expiration times were found")
      end

      -- Determine when the combination will break
      -- This happens when dropping below the required number of spells
      if #remainingTimes > 0 and activeSpellsCount >= requiredSpells then
        -- Find which dot expiring will break the combination
        local criticalIndex = activeSpellsCount - requiredSpells + 1

        DM:NameplateDebug("Critical dot index is %d (combo breaks when this many dots expire)", criticalIndex)

        -- If criticalIndex is 1, it means the combo breaks when the first spell expires
        if criticalIndex <= #remainingTimes then
          local criticalDot = remainingTimes[criticalIndex]
          leastRemainingTime = criticalDot.time
          expiringDoTName = criticalDot.name

          -- Use the combination color for the flash
          expiringDoTColor = {
            comboData.color.r or comboData.color[1] or 1,
            comboData.color.g or comboData.color[2] or 0,
            comboData.color.b or comboData.color[3] or 0
          }

          DM:NameplateDebug("Combination will break when %s expires in %.1f seconds (dot %d of %d active)",
            expiringDoTName, leastRemainingTime, criticalIndex, activeSpellsCount)

          -- Check if this critical dot is within the threshold
          if leastRemainingTime <= threshold then
            expiringFound = true
            DM:NameplateDebug("Threshold check: %.1f <= %.1f, will flash nameplates",
              leastRemainingTime, threshold)
          else
            DM:NameplateDebug("Threshold check: %.1f > %.1f, won't flash nameplates yet",
              leastRemainingTime, threshold)
            expiringFound = false -- Explicitly set false if threshold not met
          end
        else
          DM:NameplateDebug("Critical index %d is outside the range of remaining times (1-%d)",
            criticalIndex, #remainingTimes)
        end
      else
        -- Detailed reason why no flashing will occur
        if activeSpellsCount < requiredSpells then
          DM:NameplateDebug("Not enough active dots (%d) to meet requirement (%d) - combination is already broken",
            activeSpellsCount, requiredSpells)
        elseif #remainingTimes == 0 then
          DM:NameplateDebug("No dots with valid remaining times found in the combination")
        end
      end
    end
  else
    -- No active combination, try to get active DoTs from GetActiveDots
    DM:NameplateDebug("No active combination found, checking individual dots")

    -- Get all active dots on this unit
    local activeDots = self:GetActiveDots(unitToken)

    -- If no dots found via GetActiveDots and the issue is spells being tracked but not enabled,
    -- directly check for any PRIEST DoTs using HasPlayerDotOnUnit
    if (not activeDots or not next(activeDots)) and self.dmspellsdb then
      DM:NameplateDebug("No dots found via GetActiveDots, checking individual spells directly")

      -- Get current player class
      local playerClass = DM.GetPlayerClass()
      activeDots = {}

      -- Check each spell in the database for this class, regardless of enabled state
      for spellID, config in pairs(self.dmspellsdb) do
        if config.wowclass == playerClass and config.tracked == 1 then
          DM:NameplateDebug("Directly checking spell %d (%s)", spellID, config.spellname or "Unknown")

          if self:HasPlayerDotOnUnit(unitToken, spellID) then
            DM:NameplateDebug("Found active dot: %s", config.spellname or "Unknown")

            -- Get aura info directly using AuraUtil
            if AuraUtil and AuraUtil.ForEachAura then
              AuraUtil.ForEachAura(unitToken, "HARMFUL", nil,
                function(name, icon, count, _, duration, expirationTime, caster, _, _, id)
                  if id == spellID and caster == "player" then
                    DM:NameplateDebug("Got expiration data for %s: %.1f seconds remaining",
                      name, expirationTime - now)

                    activeDots[spellID] = {
                      name = name,
                      icon = icon,
                      duration = duration or 0,
                      expirationTime = expirationTime or 0,
                      applications = count or 1,
                      color = config.color,
                      priority = config.priority or 999
                    }
                    return true -- Stop iteration
                  end
                end)
            end
          end
        end
      end
    end

    if not activeDots or not next(activeDots) then
      -- If no dots found, stop any existing flash
      local unitFrame = nameplate.unitFrame
      if unitFrame.DotMasterBorderFlashTimer then
        unitFrame.DotMasterBorderFlashTimer:Cancel()
        unitFrame.DotMasterBorderFlashTimer = nil
        unitFrame.DotMasterIsFlashing = nil

        -- Restore original border color
        local healthBar = unitFrame.healthBar
        if healthBar and healthBar.border and unitFrame.DotMasterOrigBorderColor then
          local origColor = unitFrame.DotMasterOrigBorderColor
          if healthBar.border.SetVertexColor then
            healthBar.border:SetVertexColor(origColor[1], origColor[2], origColor[3], origColor[4])
            DM:NameplateDebug("Restored original border color")
          end
        end

        DM:NameplateDebug("Stopping border flash timer - no DoTs found")
      end

      if unitFrame.DotMasterFlash then
        unitFrame.DotMasterFlash:Stop()
        unitFrame.DotMasterFlash = nil
        DM:NameplateDebug("Stopping full nameplate flash - no DoTs found")
      end
      return
    end

    -- Find the highest priority dot (this logic should match what's used for coloring)
    local highestPriorityDot = nil
    local highestPriorityConfig = nil

    -- Sort by priority
    local sortedDots = {}
    for spellID, dotInfo in pairs(activeDots) do
      table.insert(sortedDots, { id = spellID, priority = dotInfo.priority or 999, info = dotInfo })
    end

    -- Report how many active dots we found
    DM:NameplateDebug("Found %d active individual dots for priority checking", #sortedDots)

    -- Sort by priority (lower numbers = higher priority)
    table.sort(sortedDots, function(a, b) return (a.priority or 999) < (b.priority or 999) end)

    -- Debug info for priorities
    if #sortedDots > 0 then
      DM:NameplateDebug("Sorted individual dots by priority:")
      for i, entry in ipairs(sortedDots) do
        local dotInfo = entry.info
        DM:NameplateDebug("  %d. %s (ID: %d, Priority: %d, Expires: %.1f)",
          i, dotInfo.name or "Unknown", entry.id, entry.priority or 999,
          dotInfo.expirationTime - now)
      end
    end

    -- Get the highest priority dot (first one after sorting)
    if #sortedDots > 0 then
      local entry = sortedDots[1]
      highestPriorityDot = entry.id
      local dotInfo = entry.info

      DM:NameplateDebug("Selected highest priority dot: %s (ID: %d, Priority: %d)",
        dotInfo.name or "Unknown", highestPriorityDot, entry.priority or 999)

      -- Get remaining time for this dot
      if dotInfo then
        leastRemainingTime = dotInfo.expirationTime - now
        expiringDoTName = dotInfo.name
        expiringDoTColor = dotInfo.color

        DM:NameplateDebug("Highest priority DoT: %s - %.1f seconds remaining",
          expiringDoTName or "Unknown", leastRemainingTime)

        -- Check if it's expiring
        if leastRemainingTime <= threshold then
          expiringFound = true
          DM:NameplateDebug("Threshold check: %.1f <= %.1f, will flash nameplates",
            leastRemainingTime, threshold)
        else
          DM:NameplateDebug("Threshold check: %.1f > %.1f, won't flash nameplates yet",
            leastRemainingTime, threshold)
          expiringFound = false -- Explicitly set false if threshold not met
        end
      else
        DM:NameplateDebug("Error: No dot info found for spell %d", highestPriorityDot)
        expiringFound = false -- Explicitly set false on error
      end
    else
      DM:NameplateDebug("No active individual dots found to check for flashing")
      expiringFound = false -- Explicitly set false if no dots
    end
  end

  local unitFrame = nameplate.unitFrame

  -- <<< Add Debugging >>>
  DM:NameplateDebug("Final check for %s: expiringFound = %s", unitToken, tostring(expiringFound))

  -- If there's an expiring DoT, flash
  if expiringFound then
    -- Return flash state
    return true, expiringDoTColor
  else
    -- No expiring DoT, stop any flashing
    DM:NameplateDebug("Condition NOT met (expiringFound=false), checking if flash needs stopping for %s", unitToken)

    if unitFrame.DotMasterIsFlashing then
      DM:NameplateDebug("No expiring DoTs, stopping BORDER flash")

      -- Stop the animation if it exists
      if unitFrame.DotMasterFlashAnimation then
        unitFrame.DotMasterFlashAnimation:Stop()
        DM:NameplateDebug("Stopped border flash animation")
      end

      -- Restore original border color
      local healthBar = unitFrame.healthBar
      if healthBar and healthBar.border and unitFrame.DotMasterOrigBorderColor then
        local origColor = unitFrame.DotMasterOrigBorderColor
        if healthBar.border.SetVertexColor then
          healthBar.border:SetVertexColor(origColor[1], origColor[2], origColor[3], origColor[4])
          DM:NameplateDebug("Restored original border color: %.2f,%.2f,%.2f,%.2f",
            origColor[1], origColor[2], origColor[3], origColor[4])
        end
      end

      unitFrame.DotMasterIsFlashing = nil
    end

    if unitFrame.DotMasterBorderFlashTimer then
      unitFrame.DotMasterBorderFlashTimer:Cancel()
      unitFrame.DotMasterBorderFlashTimer = nil
      DM:NameplateDebug("Stopping border flash timer - no expiring DoTs")
    end

    if unitFrame.DotMasterFlash then
      unitFrame.DotMasterFlash:Stop()
      unitFrame.DotMasterFlash = nil
      DM:NameplateDebug("Stopping full nameplate flash - no expiring DoTs")
    end

    -- If the flag is set (meaning flash *was* active or *tried* to activate), reset it and restore color
    if unitFrame.DotMasterIsFlashingFill then
      DM:NameplateDebug("Resetting DotMasterIsFlashingFill flag for %s and restoring color.", unitToken)
      unitFrame.DotMasterIsFlashingFill = false

      -- Restore color immediately
      local texture = unitFrame.healthBar and unitFrame.healthBar:GetStatusBarTexture()
      if texture then
        local _, currentDotColor = self:GetHighestPriorityDotColor(unitToken)
        if currentDotColor then
          DM:NameplateDebug("Restoring dot color: %.2f, %.2f, %.2f", currentDotColor[1], currentDotColor[2],
            currentDotColor[3])
          unitFrame.DotMasterAllowChange = true
          texture:SetVertexColor(currentDotColor[1], currentDotColor[2], currentDotColor[3], currentDotColor[4] or 1)
          unitFrame.DotMasterAllowChange = nil
        else
          DM:NameplateDebug("No active DoT found, attempting reset via RestoreDefaultColor")
          local nameplate = C_NamePlate.GetNamePlateForUnit(unitToken)
          self:RestoreDefaultColor(nameplate, unitToken) -- Try full reset
        end
      else
        DM:NameplateDebug("No texture found while restoring color for %s.", unitToken)
        -- Attempt broader reset just in case
        local nameplate = C_NamePlate.GetNamePlateForUnit(unitToken)
        self:RestoreDefaultColor(nameplate, unitToken)
      end
    end

    -- Return non-flash state
    return false, nil
  end
end

-- Apply a color to a nameplate
function DM:ApplyColorToNameplate(nameplate, unitToken, color)
  if not nameplate or not color then return false end

  -- Check if Plater is available and handle it specially
  if _G["Plater"] then
    local Plater = _G["Plater"]
    local unitFrame = nameplate.unitFrame
    if unitFrame and unitFrame.healthBar then
      -- Store the original color on first application if not already stored
      if not DM.originalColors[unitToken] then
        local r, g, b, a
        local healthBar = unitFrame.healthBar

        -- Try to get the current color values
        if healthBar.GetStatusBarColor then
          r, g, b, a = healthBar:GetStatusBarColor()
        end

        -- If we couldn't get values, use fallbacks based on unit reaction
        if not r then
          if UnitCanAttack("player", unitToken) then
            r, g, b, a = 1, 0, 0, 1 -- hostile default (red)
          else
            r, g, b, a = 0, 1, 0, 1 -- friendly default (green)
          end
        end

        DM.originalColors[unitToken] = { r, g, b, a or 1 }
        DM:NameplateDebug("Stored original color for %s: %.2f, %.2f, %.2f",
          unitToken, r, g, b)
      end

      -- If Force Threat Color is enabled, check threat conditions
      if DM.settings and DM.settings.forceColor then
        -- Apply threat-based color if applicable
        if self:ApplyThreatColor(unitFrame, unitToken) then
          -- Tell DotMaster we're handling this nameplate
          self.coloredPlates[unitToken] = true
          return true
        end
      end

      -- Check for border-only mode
      if DM.settings and DM.settings.borderOnly then
        -- Apply color only to the border
        if self:SetNameplateBorderColor(unitFrame, color) then
          self.coloredPlates[unitToken] = true

          -- Create flash animation for this nameplate if needed
          if DM.settings.flashExpiring then
            -- Call check immediately to set initial state
            self:CheckForExpiringDoTs(unitToken)

            -- Set up a repeating timer to check for expiring DoTs AND APPLY FLASH
            if not unitFrame.DotMasterCheckTimer then
              DM:NameplateDebug("Creating DotMasterCheckTimer for border mode: %s", unitToken)
              unitFrame.DotMasterCheckTimer = C_Timer.NewTicker(0.25, function() -- Increased frequency
                if nameplate and nameplate:IsShown() and unitFrame and unitFrame.healthBar then
                  -- In border mode, just call the check (it handles its own animation)
                  self:CheckForExpiringDoTs(unitToken)
                else
                  -- Clean up timer if the nameplate is gone
                  if unitFrame.DotMasterCheckTimer then
                    unitFrame.DotMasterCheckTimer:Cancel()
                    unitFrame.DotMasterCheckTimer = nil
                  end
                end
              end)
            end
          end

          return true
        end
      else
        -- DIRECT APPROACH: Bypass Plater's color system entirely and set the color directly
        DM:NameplateDebug("Directly setting color for %s: %.2f, %.2f, %.2f", unitToken, color[1], color[2], color[3])

        -- Store our color in the DotMaster system
        DM.dotColors = DM.dotColors or {}
        DM.dotColors[unitToken] = { color[1], color[2], color[3], color[4] or 1 }

        -- Apply directly to the StatusBar texture
        local healthBar = unitFrame.healthBar

        -- <<< ADD CHECK: Don't apply normal color if flash is active >>>
        if unitFrame.DotMasterIsFlashingFill then
          DM:NameplateDebug("Flash active, skipping normal color application for %s", unitToken)
          return true -- Indicate success even though we didn't change color now
        end

        if healthBar.SetStatusBarColor then
          healthBar:SetStatusBarColor(color[1], color[2], color[3], color[4] or 1)
        end

        -- Set internal Plater variables to prevent overrides
        healthBar.R = color[1]
        healthBar.G = color[2]
        healthBar.B = color[3]
        healthBar.A = color[4] or 1

        -- Create a stronger protection by hooking the statusbar's SetVertexColor
        if not healthBar.DotMasterColorProtected then
          healthBar.DotMasterColorProtected = true

          -- Get the texture and protect it
          local texture = healthBar:GetStatusBarTexture()
          if texture and texture.SetVertexColor then
            -- Store original functions
            if not texture.OrigSetVertexColor then
              texture.OrigSetVertexColor = texture.SetVertexColor
            end

            -- Override the SetVertexColor function
            texture.SetVertexColor = function(self, r, g, b, a)
              -- Only allow our color through if not flashing
              if unitFrame.DotMasterAllowChange or unitFrame.DotMasterIsFlashingFill then -- ADD CHECK HERE
                texture:OrigSetVertexColor(r, g, b, a)
              else
                local dotColor = DM.dotColors[unitToken]
                if dotColor then
                  texture:OrigSetVertexColor(dotColor[1], dotColor[2], dotColor[3], dotColor[4] or 1)
                  DM:NameplateDebug("Protected color from change for %s", unitToken)
                else
                  texture:OrigSetVertexColor(r, g, b, a)
                end
              end
            end
          end
        end

        -- These flags tell Plater not to change this nameplate's color
        unitFrame.UsingCustomColor = true
        unitFrame.DenyColorChange = true
        unitFrame.DotMasterControlled = true

        -- Use the CanHide flag to stop Plater from hiding the nameplate
        unitFrame.PriorityShowState = true

        -- Make NPC colors completely ineffective for this nameplate
        if unitFrame.namePlateNpcId then
          unitFrame.DotMasterStoredNpcId = unitFrame.namePlateNpcId
          unitFrame.namePlateNpcId = nil
        end

        self.coloredPlates[unitToken] = true

        -- Create flash animation for this nameplate if needed
        if DM.settings.flashExpiring then
          -- Call check immediately to set initial state (it will handle flag reset)
          self:CheckForExpiringDoTs(unitToken)

          -- Set up a repeating timer to check AND APPLY flash
          if not unitFrame.DotMasterCheckTimer then
            DM:NameplateDebug("Creating DotMasterCheckTimer for fill mode: %s", unitToken)
            unitFrame.DotMasterCheckTimer = C_Timer.NewTicker(0.25, function() -- Increased frequency
              if not nameplate or not nameplate:IsShown() or not unitFrame or not unitFrame.healthBar then
                -- Clean up timer if the nameplate is gone
                if unitFrame.DotMasterCheckTimer then
                  unitFrame.DotMasterCheckTimer:Cancel()
                  unitFrame.DotMasterCheckTimer = nil
                end
                -- Ensure flag is reset on cleanup
                if unitFrame.DotMasterIsFlashingFill then
                  unitFrame.DotMasterIsFlashingFill = false
                end
                return
              end

              -- Get expiration state from the function
              local shouldFlash, flashColor = self:CheckForExpiringDoTs(unitToken)
              local texture = unitFrame.healthBar:GetStatusBarTexture()

              if texture then
                if shouldFlash and flashColor then
                  -- Flash is needed
                  unitFrame.DotMasterIsFlashingFill = true

                  -- Determine alpha based on time (simple toggle for now)
                  local alpha = (math.floor(GetTime() * 4) % 2 == 0) and 1.0 or 0.5 -- ~0.25s cycle
                  local r, g, b = flashColor[1], flashColor[2], flashColor[3]

                  -- Apply flash color/alpha
                  unitFrame.DotMasterAllowChange = true
                  texture:SetVertexColor(r, g, b, alpha)
                  unitFrame.DotMasterAllowChange = nil
                  DM:NameplateDebug("Timer applying fill flash for %s, Alpha: %.1f", unitToken, alpha)
                else
                  -- Flash is NOT needed, ensure state is restored
                  if unitFrame.DotMasterIsFlashingFill then
                    DM:NameplateDebug("Timer ending flash for %s", unitToken)
                    unitFrame.DotMasterIsFlashingFill = false

                    -- Restore correct color immediately
                    local _, currentDotColor = self:GetHighestPriorityDotColor(unitToken)
                    if currentDotColor then
                      unitFrame.DotMasterAllowChange = true
                      texture:SetVertexColor(currentDotColor[1], currentDotColor[2], currentDotColor[3],
                        currentDotColor[4] or 1)
                      unitFrame.DotMasterAllowChange = nil
                    else
                      self:RestoreDefaultColor(nameplate, unitToken)
                    end
                  end
                  -- If not previously flashing, do nothing (normal color is handled elsewhere)
                end
              else
                -- If texture somehow disappears, try to clean up
                if unitFrame.DotMasterCheckTimer then
                  unitFrame.DotMasterCheckTimer:Cancel()
                  unitFrame.DotMasterCheckTimer = nil
                end
                unitFrame.DotMasterIsFlashingFill = false
              end
            end)
          end
        end

        -- Setup periodic reapplication of color
        if not unitFrame.DotMasterForceColorTimer then
          unitFrame.DotMasterForceColorTimer = C_Timer.NewTicker(0.1, function()
            if not nameplate:IsShown() or not unitFrame:IsShown() then
              unitFrame.DotMasterForceColorTimer:Cancel()
              unitFrame.DotMasterForceColorTimer = nil
              return
            end

            -- <<< ADD CHECK: Don't run if flashing >>>
            if unitFrame.DotMasterIsFlashingFill then
              DM:NameplateDebug("ForceColorTimer: Skipping reapplication, flash active for %s", unitToken)
              return
            end

            if DM.coloredPlates[unitToken] and DM.dotColors[unitToken] then
              local dotColor = DM.dotColors[unitToken]
              local texture = healthBar:GetStatusBarTexture()

              -- Re-apply directly to the texture
              if texture then
                unitFrame.DotMasterAllowChange = true
                texture:SetVertexColor(dotColor[1], dotColor[2], dotColor[3], dotColor[4] or 1)
                unitFrame.DotMasterAllowChange = nil
              end

              -- Re-apply to the statusbar
              healthBar:SetStatusBarColor(dotColor[1], dotColor[2], dotColor[3], dotColor[4] or 1)
            end
          end)
        end

        return true
      end
    else
      return false
    end
  else
    -- Standard nameplate (same as before)
    local healthBar = nameplate.UnitFrame and nameplate.UnitFrame.healthBar
    if not healthBar then
      return false
    end

    -- Store original color first time if not already stored
    local unitToken = nameplate.namePlateUnitToken
    if unitToken and not DM.originalColors[unitToken] then
      local r, g, b = healthBar:GetStatusBarColor()
      DM.originalColors[unitToken] = { r, g, b }
    end

    -- Apply the new color
    DM.coloredPlates[unitToken] = true
    healthBar:SetStatusBarColor(unpack(color))
    return true
  end
end

-- Restore a nameplate's original color
function DM:RestoreDefaultColor(nameplate, unitToken)
  if not self.coloredPlates[unitToken] then return end

  local healthBar
  local unitFrame

  if _G["Plater"] then
    local Plater = _G["Plater"]
    unitFrame = nameplate.unitFrame
    if not unitFrame or not unitFrame.healthBar then return end
    healthBar = unitFrame.healthBar

    -- Cancel any timers
    if unitFrame.DotMasterCheckTimer then
      unitFrame.DotMasterCheckTimer:Cancel()
      unitFrame.DotMasterCheckTimer = nil
    end

    -- Cancel color protection timer
    if unitFrame.DotMasterForceColorTimer then
      unitFrame.DotMasterForceColorTimer:Cancel()
      unitFrame.DotMasterForceColorTimer = nil
    end

    -- Stop any border flash timer
    if unitFrame.DotMasterBorderFlashTimer then
      unitFrame.DotMasterBorderFlashTimer:Cancel()
      unitFrame.DotMasterBorderFlashTimer = nil
      unitFrame.DotMasterIsFlashing = nil

      -- Restore original border color
      if healthBar and healthBar.border and unitFrame.DotMasterOrigBorderColor then
        local origColor = unitFrame.DotMasterOrigBorderColor
        if healthBar.border.SetVertexColor then
          healthBar.border:SetVertexColor(origColor[1], origColor[2], origColor[3], origColor[4])
        end
      end
    end

    -- Stop full nameplate flashing
    if unitFrame.DotMasterFillFlashTimer then -- Check if the timer exists
      DM:NameplateDebug("RestoreDefaultColor: Stopping FILL flash timer for %s", unitToken)
      unitFrame.DotMasterFillFlashTimer:Cancel()
      unitFrame.DotMasterFillFlashTimer = nil
      -- <<< ADD FLAG RESET HERE >>>
      if unitFrame.DotMasterIsFlashingFill then
        DM:NameplateDebug("RestoreDefaultColor: Resetting DotMasterIsFlashingFill flag for %s", unitToken)
        unitFrame.DotMasterIsFlashingFill = false
      end
    end
    -- Ensure flag is false even if timer didn't exist (belt-and-suspenders)
    if unitFrame.DotMasterIsFlashingFill then
      DM:NameplateDebug("RestoreDefaultColor: Found lingering flash flag for %s, resetting.", unitToken)
      unitFrame.DotMasterIsFlashingFill = false
    end

    -- Restore original NPC ID if we saved it
    if unitFrame.DotMasterStoredNpcId then
      unitFrame.namePlateNpcId = unitFrame.DotMasterStoredNpcId
      unitFrame.DotMasterStoredNpcId = nil
    end

    -- Remove texture protection
    if healthBar.DotMasterColorProtected then
      local texture = healthBar:GetStatusBarTexture()
      if texture and texture.OrigSetVertexColor then
        texture.SetVertexColor = texture.OrigSetVertexColor
        texture.OrigSetVertexColor = nil
      end
      healthBar.DotMasterColorProtected = nil
    end

    -- Remove our stored color for this unit
    if DM.dotColors then
      DM.dotColors[unitToken] = nil
    end

    -- If we were in border-only mode, restore default Plater border settings
    if DM.settings and DM.settings.borderOnly then
      -- Reset custom border color flag
      unitFrame.customBorderColor = nil

      -- Get the original border thickness if we stored it
      local borderThickness = 1 -- Fallback default
      if DM.originalBorderThickness and DM.originalBorderThickness[unitToken] then
        borderThickness = DM.originalBorderThickness[unitToken]
        -- Clear the stored value
        DM.originalBorderThickness[unitToken] = nil
      else
        -- Fallback to Plater's default border thickness from its DB
        borderThickness = Plater.db and Plater.db.profile and Plater.db.profile.border_thickness or 1
      end

      -- Reset border thickness to original
      if healthBar.border then
        healthBar.border:SetBorderSizes(borderThickness, borderThickness, borderThickness, borderThickness)
        healthBar.border:UpdateSizes()
      end

      -- Restore default border color
      Plater.UpdateBorderColor(unitFrame)
    else
      -- Reset Plater's color control flags
      unitFrame.UsingCustomColor = nil
      unitFrame.DenyColorChange = nil
      unitFrame.PriorityShowState = nil
      unitFrame.DotMasterControlled = nil

      -- Reset the healthBar color variables
      healthBar.R, healthBar.G, healthBar.B, healthBar.A = nil, nil, nil, nil

      -- Allow Plater to manage color again
      unitFrame.DotMasterAllowChange = true

      -- Apply original color directly if we have it
      if self.originalColors[unitToken] then
        local origColor = self.originalColors[unitToken]
        healthBar:SetStatusBarColor(origColor[1], origColor[2], origColor[3], origColor[4] or 1)
      end
    end
  else
    -- Standard nameplate handling (non-Plater)
    healthBar = self:GetHealthBar(nameplate)
    if not healthBar then return end

    if self.originalColors[unitToken] then
      healthBar:SetStatusBarColor(unpack(self.originalColors[unitToken]))
    else
      healthBar:SetStatusBarColor(UnitCanAttack("player", unitToken) and 1 or 0,
        UnitCanAttack("player", unitToken) and 0 or 1, 0)
    end
  end

  self.coloredPlates[unitToken] = nil
end

-- Function to reapply DoT colors after leaving combat
-- This is needed because Plater resets all nameplate colors when combat ends
function DM:HookPlaterFunctions()
  local Plater = _G["Plater"]
  if not Plater then
    DM:NameplateDebug("Plater not found, cannot hook color functions")
    return
  end

  -- Prevent double hooking
  if DM.platerFunctionsHooked then
    DM:NameplateDebug("Plater functions already hooked, skipping")
    return
  end

  DM:NameplateDebug("Setting up Plater function hooks to prevent color flicker")

  -- Store the original function
  local originalUpdateAllNameplateColors = Plater.UpdateAllNameplateColors

  -- Hook the function that updates all nameplate colors (called when leaving combat)
  Plater.UpdateAllNameplateColors = function(...)
    -- First let Plater do its work
    local result = originalUpdateAllNameplateColors(...)

    -- Then immediately reapply our colors to prevent flicker
    if DM.enabled then
      C_Timer.After(0, function() -- Use immediate timer to ensure we run after Plater's function completes
        DM:NameplateDebug("Plater attempted to reset colors - immediately reapplying DoT colors")
        DM:UpdateAllNameplates()
      end)
    end

    return result
  end

  -- Store the original refresh function
  local originalRefreshNameplateColor = Plater.RefreshNameplateColor

  -- Hook the function that refreshes individual nameplate colors
  Plater.RefreshNameplateColor = function(unitFrame, ...)
    -- Let Plater do its work
    local result = originalRefreshNameplateColor(unitFrame, ...)

    -- Check if this is a nameplate we're tracking with DoTs
    if unitFrame and unitFrame.unit and DM.coloredPlates and DM.coloredPlates[unitFrame.unit] then
      -- Reapply our DoT coloring immediately
      C_Timer.After(0, function()
        if unitFrame and unitFrame:IsShown() and unitFrame.unit and DM.coloredPlates[unitFrame.unit] then
          DM:NameplateDebug("Reapplying DoT color after standard refresh for unit: " .. unitFrame.unit)
          DM:UpdateNameplate(unitFrame.unit)
        end
      end)
    end

    return result
  end

  -- Mark as hooked
  DM.platerFunctionsHooked = true
end

-- Function to specifically handle the NPC Colors and Names conflict
function DM:HookPlaterNpcColors()
  local Plater = _G["Plater"]
  if not Plater then
    DM:NameplateDebug("Plater not found, cannot hook NPC colors functions")
    return
  end

  -- Prevent double hooking
  if DM.platerNpcColorsHooked then
    DM:NameplateDebug("Plater NPC colors already hooked, skipping")
    return
  end

  DM:NameplateDebug("Setting up DIRECT SetNameplateColor hook")

  -- Hook Plater.SetNameplateColor - this is the key function that all color changes go through
  local originalSetNameplateColor = Plater.SetNameplateColor
  Plater.SetNameplateColor = function(unitFrame, r, g, b, a)
    -- First check if this is one of our nameplates
    if unitFrame and unitFrame.unit and DM.coloredPlates and DM.coloredPlates[unitFrame.unit] then
      -- We control this nameplate
      if not unitFrame.DotMasterStopped then
        DM:NameplateDebug("SetNameplateColor BLOCKED for: %s", unitFrame.unit)

        -- Here's the important part: if we're blocking the color change, we need to apply our own
        -- color immediately so Plater's change doesn't win
        if DM.originalColors[unitFrame.unit] then
          local color = DM.originalColors[unitFrame.unit]

          -- Set a flag to prevent infinite recursion
          unitFrame.DotMasterStopped = true

          -- Call original with our color
          originalSetNameplateColor(unitFrame, color[1], color[2], color[3], color[4] or 1)

          -- Remove flag
          unitFrame.DotMasterStopped = nil

          -- Set unit frame flags to prevent other changes
          unitFrame.UsingCustomColor = true
          unitFrame.DenyColorChange = true

          -- Add our tracking flag
          unitFrame.DotMasterControlled = true
        end

        -- Return early to block the original color change
        return
      else
        -- This is our own call, let it proceed
        unitFrame.DotMasterStopped = nil
      end
    end

    -- Not our nameplate or it's our own call, proceed normally
    return originalSetNameplateColor(unitFrame, r, g, b, a)
  end

  -- Setup periodic refresh to ensure our colors stay applied
  if not DM.dotColorRefreshTimer then
    DM.dotColorRefreshTimer = C_Timer.NewTicker(0.2, function()
      if not DM.enabled then return end

      -- Check if we have any nameplates to update
      local hasPlates = false
      for unit in pairs(DM.coloredPlates or {}) do
        if unit then
          hasPlates = true; break
        end
      end

      if not hasPlates then return end

      -- For each nameplate we control, force-reapply our color
      for unitToken in pairs(DM.coloredPlates) do
        local nameplate = C_NamePlate.GetNamePlateForUnit(unitToken)
        if nameplate and nameplate.unitFrame and nameplate.unitFrame:IsShown() then
          local unitFrame = nameplate.unitFrame
          local color = DM.originalColors[unitToken]

          if color then
            -- Apply directly
            unitFrame.DotMasterStopped = true
            Plater.SetNameplateColor(unitFrame, color[1], color[2], color[3], color[4] or 1)
            unitFrame.DotMasterStopped = nil

            -- Set flags to prevent other changes
            unitFrame.UsingCustomColor = true
            unitFrame.DenyColorChange = true
            unitFrame.DotMasterControlled = true

            -- This is key: also scrub any NPC ID data from the nameplate while we control it
            if unitFrame.namePlateNpcId then
              -- Store the NPC ID but remove it from the frame to prevent Plater from reapplying its color
              if not unitFrame.DotMasterOriginalNpcId then
                unitFrame.DotMasterOriginalNpcId = unitFrame.namePlateNpcId
              end

              -- Erase it from the frame
              unitFrame.namePlateNpcId = nil
            end
          end
        end
      end
    end)
  end

  -- Mark as hooked
  DM.platerNpcColorsHooked = true
  DM:NameplateDebug("Successfully hooked Plater SetNameplateColor")
end

-- Initialize the hook when this file loads
do
  C_Timer.After(1, function()
    if _G["Plater"] then
      DM:HookPlaterFunctions()
    else
      DM:NameplateDebug("Delaying Plater hook until Plater is loaded")
      C_Timer.After(2, function()
        if _G["Plater"] then
          DM:HookPlaterFunctions()
        else
          DM:NameplateDebug("Plater not found after delay, cannot hook functions")
        end
      end)
    end
  end)
end

-- We'll still keep the event registration as a backup
local combatEventFrame = CreateFrame("Frame")
combatEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatEventFrame:SetScript("OnEvent", function(self, event)
  if event == "PLAYER_REGEN_ENABLED" then
    -- Use a very short delay to ensure we run after Plater's handlers
    C_Timer.After(0.01, function()
      if DM.enabled then
        DM:NameplateDebug("Combat ended - immediate reapplication of DoT colors")
        DM:UpdateAllNameplates()
      end
    end)
  end
end)
