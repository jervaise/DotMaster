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

  -- For border only mode, directly use Plater's border flash functionality
  if DM.settings.borderOnly then
    -- Create a wrapper for the border flash
    return {
      Play = function()
        -- Use Plater's built-in border flash function
        if unitFrame and unitFrame.healthBar and unitFrame.healthBar.canHealthFlash then
          -- Single immediate flash
          unitFrame.healthBar.PlayHealthFlash(0.15)

          -- Set up timer for continuous flashing
          -- First cancel any existing timer
          if unitFrame.DotMasterBorderFlashTimer then
            unitFrame.DotMasterBorderFlashTimer:Cancel()
            unitFrame.DotMasterBorderFlashTimer = nil
          end

          -- Create new timer for repeated flashes
          unitFrame.DotMasterBorderFlashTimer = C_Timer.NewTicker(0.35, function()
            if unitFrame and unitFrame.healthBar and unitFrame.healthBar.canHealthFlash then
              unitFrame.healthBar.PlayHealthFlash(0.15)
            end
          end)
        end
      end,

      Stop = function()
        -- Cancel the timer if it exists
        if unitFrame and unitFrame.DotMasterBorderFlashTimer then
          unitFrame.DotMasterBorderFlashTimer:Cancel()
          unitFrame.DotMasterBorderFlashTimer = nil
        end
      end
    }
  else
    -- For full nameplate mode, create a custom flash overlay
    -- that doesn't affect text or health value display

    -- Get the healthbar
    local healthBar = unitFrame.healthBar
    if not healthBar then return nil end

    -- Create a parent frame for our flash effect
    local parentFrame = CreateFrame("Frame", nil, healthBar)
    parentFrame:SetFrameLevel(healthBar:GetFrameLevel() + 2)
    parentFrame:SetAllPoints(healthBar)
    parentFrame:Hide()

    -- This mask will make our flash respect the current health value
    local maskFrame = CreateFrame("Frame", nil, parentFrame)
    maskFrame:SetFrameLevel(parentFrame:GetFrameLevel())
    maskFrame:SetPoint("TOPLEFT", healthBar, "TOPLEFT", 0, 0)
    maskFrame:SetPoint("BOTTOMLEFT", healthBar, "BOTTOMLEFT", 0, 0)
    maskFrame:Hide()

    -- Create the flash texture (this goes over the health bar portion only)
    local flashTexture = maskFrame:CreateTexture(nil, "OVERLAY")
    flashTexture:SetAllPoints()

    -- Maximize color brightness for better visibility
    local r, g, b = color[1], color[2], color[3]
    local maxComponent = math.max(r, g, b)
    if maxComponent > 0 then
      r, g, b = r / maxComponent, g / maxComponent, b / maxComponent
    end

    flashTexture:SetColorTexture(r, g, b, 0.7)
    flashTexture:SetBlendMode("ADD")

    -- Create the animation group
    local animGroup = flashTexture:CreateAnimationGroup()
    animGroup:SetLooping("REPEAT")

    -- Alpha animations (fade in/out)
    local fadeIn = animGroup:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0.1)
    fadeIn:SetToAlpha(0.8)
    fadeIn:SetDuration(0.3)
    fadeIn:SetOrder(1)

    local fadeOut = animGroup:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(0.8)
    fadeOut:SetToAlpha(0.1)
    fadeOut:SetDuration(0.3)
    fadeOut:SetOrder(2)

    -- Function to update the flash width based on current health
    local function UpdateMaskWidth()
      if healthBar and healthBar:IsVisible() then
        local min, max = healthBar:GetMinMaxValues()
        if max and max > 0 then
          local value = healthBar:GetValue() or 0
          local width = healthBar:GetWidth() * (value / max)
          maskFrame:SetWidth(width)
        end
      end
    end

    -- Set up update handler
    maskFrame:SetScript("OnUpdate", UpdateMaskWidth)

    -- Set animation callbacks
    animGroup:SetScript("OnPlay", function()
      parentFrame:Show()
      maskFrame:Show()
      UpdateMaskWidth()

      -- Store any nameplate text elements that need protection
      parentFrame.textElements = {}

      -- Find and protect text elements from the flash
      if unitFrame.healthBar.unitName then
        table.insert(parentFrame.textElements, unitFrame.healthBar.unitName)
      end

      if unitFrame.healthBar.lifePercent then
        table.insert(parentFrame.textElements, unitFrame.healthBar.lifePercent)
      end

      -- Add any other text elements you find
      if unitFrame.NameplateThreatValue then
        table.insert(parentFrame.textElements, unitFrame.NameplateThreatValue)
      end

      -- Bring text elements above the flash
      for _, textElement in ipairs(parentFrame.textElements) do
        if textElement:GetObjectType() == "FontString" then
          local currentDrawLayer = textElement:GetDrawLayer()
          if currentDrawLayer ~= "OVERLAY" then
            textElement._oldDrawLayer = currentDrawLayer
            textElement:SetDrawLayer("OVERLAY", 7)
          end
        end
      end
    end)

    animGroup:SetScript("OnStop", function()
      parentFrame:Hide()
      maskFrame:Hide()

      -- Restore text elements
      if parentFrame.textElements then
        for _, textElement in ipairs(parentFrame.textElements) do
          if textElement:GetObjectType() == "FontString" and textElement._oldDrawLayer then
            textElement:SetDrawLayer(textElement._oldDrawLayer)
            textElement._oldDrawLayer = nil
          end
        end
        wipe(parentFrame.textElements)
      end
    end)

    -- Return the animation controller
    return {
      Play = function()
        UpdateMaskWidth()
        animGroup:Play()
      end,
      Stop = function()
        animGroup:Stop()
      end
    }
  end
end

-- Check for expiring DoTs and trigger flashes
function DM:CheckForExpiringDoTs(unitToken)
  if not unitToken or not DM.settings.flashExpiring then return end

  local nameplate = C_NamePlate.GetNamePlateForUnit(unitToken)
  if not nameplate then return end

  local unitFrame = nameplate.unitFrame
  if not unitFrame then return end

  -- Get all active dots on this unit
  local activeDots = self:GetActiveDots(unitToken)
  if not activeDots or not next(activeDots) then
    -- No dots, stop any existing flash
    if self.flashAnimations and self.flashAnimations[unitToken] then
      DM:NameplateDebug("Stopping flash - no DoTs found")
      self.flashAnimations[unitToken]:Stop()
      self.flashAnimations[unitToken] = nil
    end
    return
  end

  -- Initialize flash animations table if needed
  if not self.flashAnimations then self.flashAnimations = {} end

  -- Find if any DoT is about to expire based on user threshold
  local expiringFound = false
  local expiringDoTName = nil
  local expiringDoTTime = nil
  local expiringDoTColor = nil
  local now = GetTime()
  local threshold = DM.settings.flashThresholdSeconds or 3.0

  -- Debug info
  DM:NameplateDebug("Checking DoTs for expiration with threshold: %s seconds", threshold)

  for spellID, dotInfo in pairs(activeDots) do
    local remainingTime = dotInfo.expirationTime - now
    DM:NameplateDebug("DoT %s has %s seconds remaining", dotInfo.name, remainingTime)

    if remainingTime > 0 and remainingTime <= threshold then
      expiringFound = true
      expiringDoTName = dotInfo.name
      expiringDoTTime = remainingTime
      expiringDoTColor = dotInfo.color
      break
    end
  end

  -- Track whether we're flashing this nameplate or not
  local currentlyFlashing = self.flashAnimations[unitToken] ~= nil

  -- Play or stop the flash animation based on DoT state
  if expiringFound then
    -- Only create a new flash or restart if we don't already have one
    if not currentlyFlashing then
      DM:NameplateDebug("Starting new flash for %s (%.1f seconds left)", expiringDoTName, expiringDoTTime)
      local flash = self:CreateNameplateFlash(unitFrame, expiringDoTColor)
      if flash then
        self.flashAnimations[unitToken] = flash
        flash:Play()
      end
    else
      DM:NameplateDebug("Already flashing for DoT on %s", unitToken)
    end
  else
    -- Stop flashing if we were flashing but no DoTs are expiring now
    if currentlyFlashing then
      DM:NameplateDebug("Stopping flash - no expiring DoTs")
      self.flashAnimations[unitToken]:Stop()
      self.flashAnimations[unitToken] = nil
    end
  end
end

-- Apply a color to a nameplate
function DM:ApplyColorToNameplate(nameplate, unitToken, color)
  if not nameplate or not color then return false end

  DM:NameplateDebug("ApplyColorToNameplate called: %s, Color: %d/%d/%d",
    nameplate:GetName() or "unnamed",
    color[1] * 255, color[2] * 255, color[3] * 255)

  -- Check if Plater is available and handle it specially
  if _G["Plater"] then
    local Plater = _G["Plater"]
    DM:NameplateDebug("Plater detected")
    local unitFrame = nameplate.unitFrame
    if unitFrame and unitFrame.healthBar then
      -- If Force Threat Color is enabled, check threat conditions
      if DM.settings and DM.settings.forceColor then
        DM:NameplateDebug("Force Threat Color is enabled - checking threat state")

        -- Apply threat-based color if applicable
        if self:ApplyThreatColor(unitFrame, unitToken) then
          -- Tell DotMaster we're handling this nameplate
          self.coloredPlates[unitToken] = true
          return true
        end
      end

      -- Check for border-only mode
      if DM.settings and DM.settings.borderOnly then
        DM:NameplateDebug("Border-only mode is enabled")

        -- Apply color only to the border
        if self:SetNameplateBorderColor(unitFrame, color) then
          self.coloredPlates[unitToken] = true

          -- Create flash animation for this nameplate if needed
          if DM.settings.flashExpiring then
            C_Timer.After(0.1, function()
              if nameplate and nameplate.unitFrame and nameplate:IsShown() then
                self:CheckForExpiringDoTs(unitToken)
              end
            end)
          end

          return true
        end
      else
        -- If not using border-only mode, use full nameplate coloring
        DM:NameplateDebug("Applying regular DoT color to full nameplate")
        Plater.SetNameplateColor(unitFrame, color[1], color[2], color[3], color[4] or 1)

        -- These flags tell Plater not to change this nameplate's color
        unitFrame.UsingCustomColor = true
        unitFrame.DenyColorChange = true

        self.coloredPlates[unitToken] = true

        -- Create flash animation for this nameplate if needed
        if DM.settings.flashExpiring then
          C_Timer.After(0.1, function()
            if nameplate and nameplate.unitFrame and nameplate:IsShown() then
              self:CheckForExpiringDoTs(unitToken)
            end
          end)
        end

        return true
      end
    else
      DM:NameplateDebug("Plater unitFrame or healthBar not found")
      return false
    end
  else
    DM:NameplateDebug("Using standard nameplate")
    -- Standard nameplate
    local healthBar = nameplate.UnitFrame and nameplate.UnitFrame.healthBar
    if not healthBar then
      DM:NameplateDebug("HealthBar not found")
      return false
    end

    -- Store original color first time if not already stored
    local unitToken = nameplate.namePlateUnitToken
    if unitToken and not DM.originalColors[unitToken] then
      local r, g, b = healthBar:GetStatusBarColor()
      DM.originalColors[unitToken] = { r, g, b }
      DM:NameplateDebug("Saving original color: %d/%d/%d", r * 255, g * 255, b * 255)
    end

    -- Apply the new color
    DM.coloredPlates[unitToken] = true
    DM:NameplateDebug("Applying new color: %d/%d/%d", color[1] * 255, color[2] * 255, color[3] * 255)
    healthBar:SetStatusBarColor(unpack(color))
    DM:NameplateDebug("Nameplate color successfully changed")
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

    -- Log for debugging
    DM:NameplateDebug("RestoreDefaultColor for Plater nameplate: %s", nameplate:GetName() or "unnamed")

    -- Stop any flash animations first
    if self.flashAnimations and self.flashAnimations[unitToken] then
      DM:NameplateDebug("Stopping flash animation during color restore")
      self.flashAnimations[unitToken]:Stop()
      self.flashAnimations[unitToken] = nil
    end

    -- If we were in border-only mode, restore default Plater border settings
    if DM.settings and DM.settings.borderOnly then
      -- Reset custom border color flag
      unitFrame.customBorderColor = nil

      -- Get the original border thickness if we stored it
      local borderThickness = 1 -- Fallback default
      if DM.originalBorderThickness and DM.originalBorderThickness[unitToken] then
        borderThickness = DM.originalBorderThickness[unitToken]
        DM:NameplateDebug("Using stored original border thickness: %d", borderThickness)
        -- Clear the stored value
        DM.originalBorderThickness[unitToken] = nil
      else
        -- Fallback to Plater's default border thickness from its DB
        borderThickness = Plater.db and Plater.db.profile and Plater.db.profile.border_thickness or 1
        DM:NameplateDebug("No stored thickness found, using Plater default: %d", borderThickness)
      end

      -- Reset border thickness to original
      if healthBar.border then
        healthBar.border:SetBorderSizes(borderThickness, borderThickness, borderThickness, borderThickness)
        healthBar.border:UpdateSizes()
        DM:NameplateDebug("Reset border thickness to: %d", borderThickness)
      end

      -- Restore default border color
      Plater.UpdateBorderColor(unitFrame)
      DM:NameplateDebug("Reset border color to Plater default")
    else
      -- Reset Plater's color control flags - this is critical
      unitFrame.UsingCustomColor = nil
      unitFrame.DenyColorChange = nil

      -- Reset the healthBar color variables to ensure Plater recalculates them
      healthBar.R, healthBar.G, healthBar.B, healthBar.A = nil, nil, nil, nil
    end

    -- Call Plater's color refresh function - this is the core method in the mod example
    Plater.RefreshNameplateColor(unitFrame)

    -- This will force Plater to immediately update nameplate colors based on threat/reaction
    if Plater.UpdateAllNameplateColors then
      Plater.UpdateAllNameplateColors()
    end

    -- Force a tick to ensure threat colors are updated - key part of Plater's color system
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

    -- Stop any flash animations
    if self.flashAnimations and self.flashAnimations[unitToken] then
      self.flashAnimations[unitToken]:Stop()
      self.flashAnimations[unitToken] = nil
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
