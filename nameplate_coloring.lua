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
        local unitTargetName
        if unitFrame.targetUnitID then
          unitTargetName = UnitName(unitFrame.targetUnitID)
        else
          -- If targetUnitID is not available, try to construct it
          local targetUnit = unitToken .. "target"
          if UnitExists(targetUnit) then
            unitTargetName = UnitName(targetUnit)
          end
        end

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
        local healthBar = unitFrame.healthBar
        if not healthBar or not healthBar.border then
          DM:NameplateDebug("No healthBar or border found")
          return
        end

        -- Store the original color for restoration if we don't have it already
        if not unitFrame.DotMasterOrigBorderColor then
          if healthBar.border.originalColor then
            unitFrame.DotMasterOrigBorderColor = {
              healthBar.border.originalColor[1],
              healthBar.border.originalColor[2],
              healthBar.border.originalColor[3],
              healthBar.border.originalColor[4] or 1
            }
          else
            -- Default to black if we can't find the original
            unitFrame.DotMasterOrigBorderColor = { 0, 0, 0, 1 }

            -- Try to capture current color
            if healthBar.border.GetVertexColor then
              local cr, cg, cb, ca = healthBar.border:GetVertexColor()
              if cr and cg and cb then
                unitFrame.DotMasterOrigBorderColor = { cr, cg, cb, ca or 1 }
                DM:NameplateDebug("Captured current border color: %.2f,%.2f,%.2f", cr, cg, cb)
              end
            end
          end
        end

        -- Apply the color to the border
        if healthBar.border.SetVertexColor then
          -- Make the border color brighter for better contrast
          local r, g, b = color[1], color[2], color[3]
          local brightR = math.min(r * 2.0, 1)
          local brightG = math.min(g * 2.0, 1)
          local brightB = math.min(b * 2.0, 1)

          healthBar.border:SetVertexColor(brightR, brightG, brightB, 1)
          DM:NameplateDebug("Set border color for flash: %.2f,%.2f,%.2f", brightR, brightG, brightB)

          -- Store the current flash color for reference
          unitFrame.DotMasterLastFlashColor = { r, g, b }
          unitFrame.DotMasterBorderFlashColor = { r, g, b, 1 }
        end

        -- Create animation if it doesn't exist - using the animation approach that works
        if not unitFrame.DotMasterFlashAnimation then
          -- Create animation group on the border directly
          unitFrame.DotMasterFlashAnimation = healthBar.border:CreateAnimationGroup()
          unitFrame.DotMasterFlashAnimation:SetLooping("REPEAT")

          -- First animation - dim
          local dimAnim = unitFrame.DotMasterFlashAnimation:CreateAnimation("Alpha")
          dimAnim:SetFromAlpha(1.0)
          dimAnim:SetToAlpha(0.4)
          dimAnim:SetDuration(0.3)
          dimAnim:SetOrder(1)

          -- Second animation - brighten
          local brightenAnim = unitFrame.DotMasterFlashAnimation:CreateAnimation("Alpha")
          brightenAnim:SetFromAlpha(0.4)
          brightenAnim:SetToAlpha(1.0)
          brightenAnim:SetDuration(0.3)
          brightenAnim:SetOrder(2)

          DM:NameplateDebug("Created border flash animation group in CreateNameplateFlash")
        end

        -- Play the animation
        if unitFrame.DotMasterFlashAnimation then
          unitFrame.DotMasterFlashAnimation:Play()
          unitFrame.DotMasterIsFlashing = true
          unitFrame.DotMasterFlashColorChanged = false -- Reset the flag
          DM:NameplateDebug("Started border flash animation")
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
          unitFrame.DotMasterIsFlashing = true
        end
      end
    end,

    Stop = function()
      if not unitFrame then return end

      -- Stop border flash timer (just in case)
      if unitFrame.DotMasterBorderFlashTimer then
        unitFrame.DotMasterBorderFlashTimer:Cancel()
        unitFrame.DotMasterBorderFlashTimer = nil
      end

      -- Stop the animation if it exists
      if unitFrame.DotMasterFlashAnimation then
        unitFrame.DotMasterFlashAnimation:Stop()
        unitFrame.DotMasterFlashAnimation = nil
        DM:NameplateDebug("Stopped flash animation in CreateNameplateFlash.Stop")
      end

      -- Reset flashing status
      unitFrame.DotMasterIsFlashing = nil
      unitFrame.DotMasterFlashColorChanged = nil
      unitFrame.DotMasterLastFlashColor = nil
      unitFrame.DotMasterBorderFlashColor = nil

      -- Restore original border color
      if DM.settings and DM.settings.borderOnly then
        local healthBar = unitFrame.healthBar
        if healthBar and healthBar.border and unitFrame.DotMasterOrigBorderColor then
          local origColor = unitFrame.DotMasterOrigBorderColor
          if healthBar.border.SetVertexColor then
            healthBar.border:SetVertexColor(origColor[1], origColor[2], origColor[3], origColor[4])
            DM:NameplateDebug("Restored original border color in CreateNameplateFlash.Stop")
          end
        end
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

  -- If Force Threat Color is enabled and border-only is disabled, check if threat conditions apply
  -- which would mean we should suppress flashing
  local unitFrame = nameplate.unitFrame
  local suppressFlashing = false

  if DM.settings and DM.settings.forceColor and not DM.settings.borderOnly then
    local Plater = _G["Plater"]
    if Plater then
      -- Check if player is a tank with lost aggro or DPS/healer with aggro
      if Plater.PlayerIsTank then
        -- Player is a tank, check if we lost aggro
        if not unitFrame.namePlateThreatIsTanking then
          -- Check for raid tanks (same logic as ApplyThreatColor)
          if Plater.ZoneInstanceType == "raid" then
            -- Get tanks in the raid
            local tankPlayersInTheRaid = Plater.GetTanks()
            -- Get the target of this unit
            local unitTargetName
            if unitFrame.targetUnitID then
              unitTargetName = UnitName(unitFrame.targetUnitID)
            else
              -- If targetUnitID is not available, try to construct it
              local targetUnit = unitToken .. "target"
              if UnitExists(targetUnit) then
                unitTargetName = UnitName(targetUnit)
              end
            end
            -- If the unit isn't targeting another tank, suppress flashing
            if not tankPlayersInTheRaid[unitTargetName] then
              suppressFlashing = true
              DM:NameplateDebug("Force Threat: Tank lost aggro - suppressing flashing")
            end
          else
            -- Not in raid, just suppress flashing
            suppressFlashing = true
            DM:NameplateDebug("Force Threat: Tank lost aggro - suppressing flashing")
          end
        end
      else
        -- Player is DPS/healer - check if we have aggro
        if unitFrame.namePlateThreatIsTanking then
          suppressFlashing = true
          DM:NameplateDebug("Force Threat: DPS/Healer has aggro - suppressing flashing")
        end
      end
    end
  end

  -- If flashing is suppressed due to force threat mode, stop any current flashing and exit early
  if suppressFlashing then
    -- Stop any flashing
    if unitFrame.DotMasterIsFlashing then
      DM:NameplateDebug("Forced threat color active - stopping flash")

      -- Stop the animation if it exists
      if unitFrame.DotMasterFlashAnimation then
        unitFrame.DotMasterFlashAnimation:Stop()
        DM:NameplateDebug("Stopped border flash animation")
      end

      -- Stop the Flash animation if it exists
      if unitFrame.DotMasterFlash then
        unitFrame.DotMasterFlash:Stop()
        unitFrame.DotMasterFlash = nil
        DM:NameplateDebug("Stopped full nameplate flash")
      end

      -- Restore original border color
      local healthBar = unitFrame.healthBar
      if healthBar and healthBar.border and unitFrame.DotMasterOrigBorderColor then
        local origColor = unitFrame.DotMasterOrigBorderColor
        if healthBar.border.SetVertexColor then
          healthBar.border:SetVertexColor(origColor[1], origColor[2], origColor[3], origColor[4])
          DM:NameplateDebug("Restored original border color due to force threat color")
        end
      end

      unitFrame.DotMasterIsFlashing = nil
    end

    return
  end

  -- Debug API availability
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
        end
      else
        DM:NameplateDebug("Error: No dot info found for spell %d", highestPriorityDot)
      end
    else
      DM:NameplateDebug("No active individual dots found to check for flashing")
    end
  end

  local unitFrame = nameplate.unitFrame

  -- If there's an expiring DoT, flash
  if expiringFound then
    -- Get the DoT color for the flash
    local r, g, b = expiringDoTColor[1], expiringDoTColor[2], expiringDoTColor[3]

    -- Check the flashing mode (border or full)
    if DM.settings.borderOnly then
      -- Border-only mode
      local healthBar = unitFrame.healthBar
      if not healthBar or not healthBar.border then
        DM:NameplateDebug("No healthBar or border found")
        return
      end

      -- Store the original color for restoration if we don't have it already
      if not unitFrame.DotMasterOrigBorderColor then
        if healthBar.border.originalColor then
          unitFrame.DotMasterOrigBorderColor = {
            healthBar.border.originalColor[1],
            healthBar.border.originalColor[2],
            healthBar.border.originalColor[3],
            healthBar.border.originalColor[4] or 1
          }
        else
          -- Default to black if we can't find the original
          unitFrame.DotMasterOrigBorderColor = { 0, 0, 0, 1 }

          -- Try to capture current color
          if healthBar.border.GetVertexColor then
            local cr, cg, cb, ca = healthBar.border:GetVertexColor()
            if cr and cg and cb then
              unitFrame.DotMasterOrigBorderColor = { cr, cg, cb, ca or 1 }
              DM:NameplateDebug("Captured current border color: %.2f,%.2f,%.2f", cr, cg, cb)
            end
          end
        end
      end

      -- Store the actual DoT color for use in animation
      unitFrame.DotMasterBorderFlashColor = { r, g, b, 1 }

      -- Apply the color to the border
      if healthBar.border.SetVertexColor then
        -- Make the border color brighter for better contrast (more pronounced)
        local brightR = math.min(r * 2.0, 1)
        local brightG = math.min(g * 2.0, 1)
        local brightB = math.min(b * 2.0, 1)

        healthBar.border:SetVertexColor(brightR, brightG, brightB, 1)
        DM:NameplateDebug("Set border color for flash: %.2f,%.2f,%.2f", brightR, brightG, brightB)
      end

      -- Create animation if it doesn't exist - using the animation approach that works
      if not unitFrame.DotMasterFlashAnimation then
        -- Create animation group on the border directly
        unitFrame.DotMasterFlashAnimation = healthBar.border:CreateAnimationGroup()
        unitFrame.DotMasterFlashAnimation:SetLooping("REPEAT")

        -- First animation - dim
        local dimAnim = unitFrame.DotMasterFlashAnimation:CreateAnimation("Alpha")
        dimAnim:SetFromAlpha(1.0)
        dimAnim:SetToAlpha(0.4)
        dimAnim:SetDuration(0.3)
        dimAnim:SetOrder(1)

        -- Second animation - brighten
        local brightenAnim = unitFrame.DotMasterFlashAnimation:CreateAnimation("Alpha")
        brightenAnim:SetFromAlpha(0.4)
        brightenAnim:SetToAlpha(1.0)
        brightenAnim:SetDuration(0.3)
        brightenAnim:SetOrder(2)

        DM:NameplateDebug("Created border flash animation group in CheckForExpiringDoTs")
      end

      -- Set up animation for border if not already flashing
      if not unitFrame.DotMasterIsFlashing or unitFrame.DotMasterFlashColorChanged then
        -- Check if the color has changed since last flash
        if unitFrame.DotMasterIsFlashing and unitFrame.DotMasterLastFlashColor then
          local lastColor = unitFrame.DotMasterLastFlashColor
          -- If color changed, we need to update
          if lastColor[1] ~= r or lastColor[2] ~= g or lastColor[3] ~= b then
            unitFrame.DotMasterFlashColorChanged = true
            DM:NameplateDebug("Flash color changed, updating animation")
          end
        end

        DM:NameplateDebug("Starting border flash animation for %s", unitToken)
        unitFrame.DotMasterIsFlashing = true
        unitFrame.DotMasterFlashColorChanged = false    -- Reset the flag
        unitFrame.DotMasterLastFlashColor = { r, g, b } -- Remember current color

        -- Play the animation if exists
        if unitFrame.DotMasterFlashAnimation then
          unitFrame.DotMasterFlashAnimation:Play()
          DM:NameplateDebug("Started border flash animation")
        end
      end
    else
      -- Full nameplate mode
      -- If we don't have an animation yet, create one
      if not unitFrame.DotMasterFlash then
        -- Create flash using Plater's API
        local Plater = _G["Plater"]
        if Plater and Plater.CreateFlash then
          DM:NameplateDebug("Creating full nameplate flash with color: %.2f,%.2f,%.2f", r, g, b)
          unitFrame.DotMasterFlash = Plater.CreateFlash(unitFrame.healthBar, 0.25, 3, r, g, b, 0.6)
          DM:NameplateDebug("Created full nameplate flash animation")
        else
          DM:NameplateDebug("Plater.CreateFlash not found!")
        end
      end

      -- Play the animation if we have it
      if unitFrame.DotMasterFlash then
        unitFrame.DotMasterFlash:Play()
        unitFrame.DotMasterIsFlashing = true
        DM:NameplateDebug("Started full nameplate flash")
      else
        DM:NameplateDebug("No DotMasterFlash animation exists")
      end
    end
  else
    -- No expiring DoT, stop any flashing
    if unitFrame.DotMasterIsFlashing then
      DM:NameplateDebug("No expiring DoTs, stopping flash")

      -- Stop the animation if it exists
      if unitFrame.DotMasterFlashAnimation then
        unitFrame.DotMasterFlashAnimation:Stop()
        DM:NameplateDebug("Stopped border flash animation")
      end

      -- Stop the Flash animation if it exists
      if unitFrame.DotMasterFlash then
        unitFrame.DotMasterFlash:Stop()
        unitFrame.DotMasterFlash = nil
        DM:NameplateDebug("Stopped full nameplate flash")
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

    -- Stop any border flash timer (just in case we have any lingering timers)
    if unitFrame.DotMasterBorderFlashTimer then
      unitFrame.DotMasterBorderFlashTimer:Cancel()
      unitFrame.DotMasterBorderFlashTimer = nil
      DM:NameplateDebug("Stopping border flash timer - no expiring DoTs")
    end
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
          if DM.settings.flashExpiring and not unitFrame.DotMasterCheckTimer then
            self:CheckForExpiringDoTs(unitToken)

            -- Set up a repeating timer to check for expiring DoTs
            unitFrame.DotMasterCheckTimer = C_Timer.NewTicker(0.5, function()
              if nameplate and nameplate:IsShown() and unitFrame and unitFrame.healthBar then
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

          return true
        end
      else
        -- If not using border-only mode, use full nameplate coloring
        Plater.SetNameplateColor(unitFrame, color[1], color[2], color[3], color[4] or 1)

        -- These flags tell Plater not to change this nameplate's color
        unitFrame.UsingCustomColor = true
        unitFrame.DenyColorChange = true

        self.coloredPlates[unitToken] = true

        -- Create flash animation for this nameplate if needed
        if DM.settings.flashExpiring and not unitFrame.DotMasterCheckTimer then
          self:CheckForExpiringDoTs(unitToken)

          -- Set up a repeating timer to check for expiring DoTs
          unitFrame.DotMasterCheckTimer = C_Timer.NewTicker(0.5, function()
            if nameplate and nameplate:IsShown() and unitFrame and unitFrame.healthBar then
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

    -- Stop any border flash timer
    if unitFrame.DotMasterBorderFlashTimer then
      unitFrame.DotMasterBorderFlashTimer:Cancel()
      unitFrame.DotMasterBorderFlashTimer = nil
    end

    -- Stop any FlashAnimation for border flashing
    if unitFrame.DotMasterFlashAnimation then
      unitFrame.DotMasterFlashAnimation:Stop()
      unitFrame.DotMasterFlashAnimation = nil
      DM:NameplateDebug("Stopped DotMasterFlashAnimation in RestoreDefaultColor")
    end

    -- Reset flashing status
    unitFrame.DotMasterIsFlashing = nil
    unitFrame.DotMasterFlashColorChanged = nil
    unitFrame.DotMasterLastFlashColor = nil
    unitFrame.DotMasterBorderFlashColor = nil

    -- Restore original border color
    if healthBar and healthBar.border and unitFrame.DotMasterOrigBorderColor then
      local origColor = unitFrame.DotMasterOrigBorderColor
      if healthBar.border.SetVertexColor then
        healthBar.border:SetVertexColor(origColor[1], origColor[2], origColor[3], origColor[4])
        DM:NameplateDebug("Restored original border color in RestoreDefaultColor")
      end
      unitFrame.DotMasterOrigBorderColor = nil
    end

    -- Stop full nameplate flashing
    if unitFrame.DotMasterFlash then
      unitFrame.DotMasterFlash:Stop()
      unitFrame.DotMasterFlash = nil
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

      -- Reset the healthBar color variables
      healthBar.R, healthBar.G, healthBar.B, healthBar.A = nil, nil, nil, nil
    end

    -- Call Plater's color refresh function
    Plater.RefreshNameplateColor(unitFrame)

    -- Force Plater to update all plates
    if Plater.UpdateAllNameplateColors then
      Plater.UpdateAllNameplateColors()
    end

    -- Force a tick to update threat colors
    if Plater.ForceTickOnAllNameplates then
      Plater.ForceTickOnAllNameplates()
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

    -- Check if this is a nameplate we're tracking
    if DM.enabled and unitFrame and unitFrame.unit then
      local unitToken = unitFrame.unit
      if DM.activePlates[unitToken] then
        C_Timer.After(0, function()
          -- Reapply our colors if needed
          DM:UpdateNameplate(unitToken)
        end)
      end
    end

    return result
  end

  DM:NameplateDebug("Plater function hooks installed successfully")
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
